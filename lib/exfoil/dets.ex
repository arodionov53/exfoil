defmodule Exfoil.Dets do
  alias Exfoil.Utils

  @moduledoc """
  Exfoil.Dets converts DETS (Disk-based Erlang Term Storage) table entries into
  dynamically generated modules with function calls.

  DETS is similar to ETS but stores data on disk, providing persistence across
  application restarts. Like ETS conversion, this provides a fast, compile-time
  optimized way to access key-value data.

  ## Examples

      # Open a DETS table and populate it
      {:ok, table} = :dets.open_file(:my_dets, [type: :set])
      :dets.insert(table, {:a, 1})
      :dets.insert(table, {:b, 2})
      :dets.insert(table, {:c, "hello"})

      # Convert to module
      {:ok, MyDets} = Exfoil.Dets.convert(:my_dets)

      # Now you can use the generated module
      MyDets.get(:a)   # => {:ok, 1}
      MyDets.get(:b)   # => {:ok, 2}
      MyDets.get(:c)   # => {:ok, "hello"}
      MyDets.get(:d)   # => nil

      MyDets.get!(:a)  # => 1
      MyDets.get!(:b)  # => 2
      MyDets.get!(:c)  # => "hello"
      MyDets.get!(:d)  # => raises KeyError

      # Don't forget to close the DETS table when done
      :dets.close(table)

  ## Important Notes

  - DETS tables must be opened before conversion
  - The conversion reads all data from disk into memory
  - The generated module works entirely in memory (no disk I/O)
  - Remember to close DETS tables after conversion to free resources
  """

  @doc """
  Converts a DETS table into a dynamically generated module with getter functions.

  ## Parameters

  - `table_name` - The name of the DETS table (atom)
  - `opts` - Optional keyword list with configuration options
    - `:module_name` - Custom module name (defaults to capitalized table name)
    - `:function_name` - Custom function name (defaults to `:get`)

  ## Examples

      {:ok, table} = :dets.open_file(:config_dets, [type: :set])
      :dets.insert(table, {:host, "localhost"})
      :dets.insert(table, {:port, 5432})

      {:ok, ConfigDets} = Exfoil.Dets.convert(:config_dets)

      ConfigDets.get(:host)   # => {:ok, "localhost"}
      ConfigDets.get(:port)   # => {:ok, 5432}

      :dets.close(table)

  """
  def convert(table_name, opts \\ []) do
    # Check if DETS table exists and is open
    case :dets.info(table_name) do
      :undefined ->
        {:error, :table_not_found}

      info when is_list(info) ->
        module_name = if opts[:module_name] do
          Utils.normalize_module_name(opts[:module_name])
        else
          default_module_name(table_name)
        end
        function_name = Utils.normalize_function_name(opts[:function_name] || :get)

        # Get all entries from the DETS table
        entries = :dets.match_object(table_name, :_)

        # Generate the module
        module_alias = create_module(module_name, function_name, entries)

        {:ok, module_alias}
    end
  end

  @doc """
  Converts a DETS table and returns the module directly.
  Raises an exception if the table doesn't exist or isn't open.

  ## Examples

      {:ok, table} = :dets.open_file(:my_dets, [type: :set])
      :dets.insert(table, {:key, "value"})

      module = Exfoil.Dets.convert!(:my_dets)
      module.get(:key)   # => {:ok, "value"}
      module.get!(:key)  # => "value"

      :dets.close(table)

  """
  def convert!(table_name, opts \\ []) do
    case convert(table_name, opts) do
      {:ok, module_name} -> module_name
      {:error, reason} -> raise "Failed to convert DETS table #{table_name}: #{reason}"
    end
  end

  @doc """
  Opens a DETS file, converts it to a module, and optionally closes the file.

  This is a convenience function that handles the full lifecycle of DETS conversion.

  ## Parameters

  - `file_path` - Path to the DETS file
  - `table_name` - Name for the DETS table
  - `opts` - Options including:
    - `:module_name` - Custom module name
    - `:function_name` - Custom function name
    - `:close_after` - Whether to close the DETS table after conversion (default: false)
    - `:dets_opts` - Options to pass to :dets.open_file

  ## Examples

      {:ok, module} = Exfoil.Dets.convert_file("data/config.dets", :config,
                                                module_name: :Config,
                                                close_after: true)

      Config.get(:setting)  # => {:ok, "value"}

  """
  def convert_file(file_path, table_name, opts \\ []) do
    dets_opts = Keyword.get(opts, :dets_opts, [])
    close_after = Keyword.get(opts, :close_after, false)

    case :dets.open_file(table_name, [{:file, String.to_charlist(file_path)} | dets_opts]) do
      {:ok, _table} ->
        result = convert(table_name, opts)

        if close_after do
          :dets.close(table_name)
        end

        result

      {:error, reason} ->
        {:error, {:cannot_open_file, reason}}
    end
  end

  # Private functions

  defp default_module_name(table_name) do
    Utils.normalize_module_name(table_name)
  end

  defp create_module(module_name, function_name, entries) do
    # Generate function clauses for each entry
    function_clauses = generate_function_clauses(function_name, entries)

    # Convert atom module name to proper module alias
    module_alias = Module.concat([module_name])

    # Create the module AST
    module_ast = quote do
      defmodule unquote(module_alias) do
        @moduledoc """
        Dynamically generated module from DETS table.
        Contains #{unquote(length(entries))} entries.
        """

        unquote_splicing(function_clauses)

        @doc """
        Returns all available keys in this module.
        """
        def keys do
          unquote(Macro.escape(Enum.map(entries, fn {key, _value} -> key end)))
        end

        @doc """
        Returns all key-value pairs in this module.
        """
        def all do
          unquote(Macro.escape(entries))
        end

        @doc """
        Returns the number of entries in this module.
        """
        def count do
          unquote(length(entries))
        end
      end
    end

    # Compile and load the module
    Code.eval_quoted(module_ast)

    module_alias
  end

  defp generate_function_clauses(function_name, entries) do
    # Generate header clause with default argument
    safe_header = quote do
      def unquote(function_name)(key, default \\ nil)
    end

    # Generate function clauses for the safe version (without default declaration)
    safe_function_clauses = Enum.map(entries, fn {key, value} ->
      quote do
        def unquote(function_name)(unquote(key), _default) do
          {:ok, unquote(Macro.escape(value))}
        end
      end
    end)

    # Generate function clauses for the bang version (returns value or raises)
    bang_function_name = String.to_atom("#{function_name}!")
    bang_function_clauses = Enum.map(entries, fn {key, value} ->
      quote do
        def unquote(bang_function_name)(unquote(key)) do
          unquote(Macro.escape(value))
        end
      end
    end)

    # Add catch-all clauses
    safe_catch_all = quote do
      def unquote(function_name)(_key, default) do
        default
      end
    end

    bang_catch_all = quote do
      def unquote(bang_function_name)(key) do
        raise KeyError, key: key, term: __MODULE__
      end
    end

    [safe_header] ++ safe_function_clauses ++ bang_function_clauses ++ [safe_catch_all, bang_catch_all]
  end
end