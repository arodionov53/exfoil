defmodule Exfoil do
  alias Exfoil.Utils

  @moduledoc """
  Exfoil converts ETS table entries into dynamically generated modules with function calls.

  For example, an ETS table named `tab1` containing key-value pairs `{:a, 1}` and `{:b, 2}`
  will be converted to a dynamically created module `Tab1` with functions:
  - `Tab1.get(:a)` which returns `{:ok, 1}`
  - `Tab1.get(:b)` which returns `{:ok, 2}`
  - `Tab1.get(:missing)` which returns `nil`
  - `Tab1.get(:missing, :default)` which returns `:default`
  - `Tab1.get!(:a)` which returns `1`
  - `Tab1.get!(:missing)` which raises a `KeyError`

  ## Additional Functionality

  - `Exfoil.Maps` - Convert Elixir maps into dynamically generated modules
  """

  @doc """
  Converts an ETS table into a dynamically generated module with getter functions.

  ## Parameters

  - `table_name_or_ref` - The name of a named ETS table (atom) or a reference to an unnamed table
  - `opts` - Optional keyword list with configuration options
    - `:module_name` - Custom module name (defaults to capitalized table name for named tables or auto-generated for unnamed)
    - `:function_name` - Custom function name (defaults to `:get`)

  ## Examples

      # Create an ETS table and populate it
      :ets.new(:tab1, [:named_table])
      :ets.insert(:tab1, {:a, 1})
      :ets.insert(:tab1, {:b, 2})
      :ets.insert(:tab1, {:c, "hello"})

      # Convert to module
      Exfoil.convert(:tab1)

      # Now you can use the generated module
      Tab1.get(:a)   # => {:ok, 1}
      Tab1.get(:b)   # => {:ok, 2}
      Tab1.get(:c)   # => {:ok, "hello"}
      Tab1.get(:d)   # => nil
      Tab1.get(:d, :default)   # => :default

      Tab1.get!(:a)  # => 1
      Tab1.get!(:b)  # => 2
      Tab1.get!(:c)  # => "hello"
      Tab1.get!(:d)  # => raises KeyError

  """
  def convert(table_name_or_ref, opts \\ []) do
    # Validate that the ETS table exists
    case :ets.info(table_name_or_ref) do
      :undefined ->
        {:error, :table_not_found}

      info ->
        module_name = if opts[:module_name] do
          Utils.normalize_module_name(opts[:module_name])
        else
          default_module_name_for_table(table_name_or_ref, info)
        end
        function_name = Utils.normalize_function_name(opts[:function_name] || :get)

        # Get all entries from the ETS table
        entries = :ets.tab2list(table_name_or_ref)

        # Generate the module
        module_alias = create_module(module_name, function_name, entries)

        {:ok, module_alias}
    end
  end

  @doc """
  Converts an ETS table and returns the module directly.
  Raises an exception if the table doesn't exist.

  ## Examples

      :ets.new(:tab1, [:named_table])
      :ets.insert(:tab1, {:key, "value"})

      module = Exfoil.convert!(:tab1)
      module.get(:key)   # => {:ok, "value"}
      module.get!(:key)  # => "value"

  """
  def convert!(table_name, opts \\ []) do
    case convert(table_name, opts) do
      {:ok, module_name} -> module_name
      {:error, reason} -> raise "Failed to convert ETS table #{table_name}: #{reason}"
    end
  end

  # Private functions

  defp default_module_name_for_table(table_name_or_ref, info) do
    cond do
      # If it's an atom (named table), use the table name
      is_atom(table_name_or_ref) ->
        Utils.normalize_module_name(table_name_or_ref)

      # If it's a reference (unnamed table), generate a name based on table info
      is_reference(table_name_or_ref) ->
        # Get the table ID from the info
        table_id = Keyword.get(info, :id, table_name_or_ref)
        # Generate a unique module name based on the reference
        ref_hash = :erlang.phash2(table_id)
        String.to_atom("ExfoilTable#{Integer.to_string(ref_hash, 16)}")

      true ->
        # Fallback to a generic name
        :ExfoilTable
    end
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
        Dynamically generated module from ETS table.
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
