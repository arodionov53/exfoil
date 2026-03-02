defmodule Exfoil do
  @moduledoc """
  Exfoil converts ETS table entries into dynamically generated modules with function calls.

  For example, an ETS table named `tab1` containing key-value pairs `{:a, 1}` and `{:b, 2}`
  will be converted to a dynamically created module `Tab1` with functions:
  - `Tab1.get(:a)` which returns `1`
  - `Tab1.get(:b)` which returns `2`

  ## Additional Functionality

  - `Exfoil.Maps` - Convert Elixir maps into dynamically generated modules
  """

  @doc """
  Converts an ETS table into a dynamically generated module with getter functions.

  ## Parameters

  - `table_name` - The name of the ETS table (atom)
  - `opts` - Optional keyword list with configuration options
    - `:module_name` - Custom module name (defaults to capitalized table name)
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
      Tab1.get(:a)  # => 1
      Tab1.get(:b)  # => 2
      Tab1.get(:c)  # => "hello"

  """
  def convert(table_name, opts \\ []) when is_atom(table_name) do
    # Validate that the ETS table exists
    case :ets.info(table_name) do
      :undefined ->
        {:error, :table_not_found}

      _info ->
        module_name = opts[:module_name] || default_module_name(table_name)
        function_name = opts[:function_name] || :get

        # Get all entries from the ETS table
        entries = :ets.tab2list(table_name)

        # Generate the module
        create_module(module_name, function_name, entries)

        {:ok, module_name}
    end
  end

  @doc """
  Converts an ETS table and returns the module directly.
  Raises an exception if the table doesn't exist.

  ## Examples

      :ets.new(:tab1, [:named_table])
      :ets.insert(:tab1, {:key, "value"})

      module = Exfoil.convert!(:tab1)
      module.get(:key)  # => "value"

  """
  def convert!(table_name, opts \\ []) do
    case convert(table_name, opts) do
      {:ok, module_name} -> module_name
      {:error, reason} -> raise "Failed to convert ETS table #{table_name}: #{reason}"
    end
  end

  # Private functions

  defp default_module_name(table_name) do
    table_name
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join("")
    |> String.to_atom()
  end

  defp create_module(module_name, function_name, entries) do
    # Generate function clauses for each entry
    function_clauses = generate_function_clauses(function_name, entries)

    # Create the module AST
    module_ast = quote do
      defmodule unquote(module_name) do
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

    module_name
  end

  defp generate_function_clauses(function_name, entries) do
    # Generate a function clause for each entry
    function_clauses = Enum.map(entries, fn {key, value} ->
      quote do
        def unquote(function_name)(unquote(key)) do
          unquote(Macro.escape(value))
        end
      end
    end)

    # Add a catch-all clause that returns {:error, :not_found}
    catch_all_clause = quote do
      def unquote(function_name)(_key) do
        {:error, :not_found}
      end
    end

    function_clauses ++ [catch_all_clause]
  end
end
