defmodule Exfoil.Utils do
  @moduledoc """
  Utility functions shared across Exfoil modules.
  """

  @doc """
  Normalizes a module name to PascalCase format.

  ## Examples

      iex> Exfoil.Utils.normalize_module_name(:person)
      :Person

      iex> Exfoil.Utils.normalize_module_name(:user_profile)
      :UserProfile

      iex> Exfoil.Utils.normalize_module_name(:UserData)
      :UserData
  """
  def normalize_module_name(module_name) do
    str = to_string(module_name)

    # Use String.at/2 for better performance instead of regex
    case String.at(str, 0) do
      <<c::utf8>> when c >= ?A and c <= ?Z ->
        # Already in PascalCase, keep as is
        String.to_atom(str)
      _ ->
        # Otherwise, split on underscores and capitalize each part
        str
        |> String.split("_")
        |> Enum.map(&String.capitalize/1)
        |> Enum.join("")
        |> String.to_atom()
    end
  end


  @doc """
  Creates a dynamic module with the given name and entries.

  ## Parameters
    - module_name: The name for the generated module
    - entries: List of {key, value} tuples to include in the module
    - source_type: Optional description of the data source (default: "data source")
    - extra_functions: Optional list of additional function ASTs to include

  ## Returns
    The module alias of the created module
  """
  def create_module(module_name, entries, source_type \\ "data source", extra_functions \\ []) do
    # Input validation for performance and security
    validate_input(entries, source_type)
    # Optimize by pre-computing escaped values and keys in a single pass
    {function_clauses, escaped_keys, escaped_entries} = generate_optimized_clauses(entries)

    # Convert atom module name to proper module alias
    module_alias = Module.concat([module_name])

    # Create the module AST
    module_ast = quote do
      defmodule unquote(module_alias) do
        @moduledoc """
        Dynamically generated module from #{unquote(source_type)}.
        Contains #{unquote(length(entries))} entries.
        """

        unquote_splicing(function_clauses)

        @doc """
        Returns all available keys in this module.
        """
        def keys do
          unquote(escaped_keys)
        end

        @doc """
        Returns all key-value pairs in this module.
        """
        def all do
          unquote(escaped_entries)
        end

        @doc """
        Returns the number of entries in this module.
        """
        def count do
          unquote(length(entries))
        end

        # Include any additional functions
        unquote_splicing(extra_functions)
      end
    end

    # Use Code.compile_quoted for better performance than Code.eval_quoted
    [{^module_alias, _binary}] = Code.compile_quoted(module_ast)

    module_alias
  end

  @doc """
  Optimized function clause generation that processes entries in a single pass.
  Creates fetch/1, fetch!/1, and get/2 functions following the Elixir Map API.

  ## Parameters
    - entries: List of {key, value} tuples

  ## Returns
    {function_clauses, escaped_keys, escaped_entries}
  """
  def generate_optimized_clauses(entries) do
    # Single pass through entries to build all necessary data structures
    {fetch_clauses, fetch_bang_clauses, get_clauses, keys, escaped_entries} =
      Enum.reduce(entries, {[], [], [], [], []}, fn {key, value}, {fetch_acc, fetch_bang_acc, get_acc, keys_acc, entries_acc} ->
        escaped_value = Macro.escape(value)

        # fetch/1 returns {:ok, value} or :error
        fetch_clause = quote do
          def fetch(unquote(key)) do
            {:ok, unquote(escaped_value)}
          end
        end

        # fetch!/1 returns value or raises
        fetch_bang_clause = quote do
          def fetch!(unquote(key)) do
            unquote(escaped_value)
          end
        end

        # get/2 returns value or default
        get_clause = quote do
          def get(unquote(key), _default) do
            unquote(escaped_value)
          end
        end

        {
          [fetch_clause | fetch_acc],
          [fetch_bang_clause | fetch_bang_acc],
          [get_clause | get_acc],
          [key | keys_acc],
          [{key, value} | entries_acc]
        }
      end)

    # Generate header clause with default argument for get/2
    get_header = quote do
      def get(key, default \\ nil)
    end

    # Add catch-all clauses
    fetch_catch_all = quote do
      def fetch(_key) do
        :error
      end
    end

    fetch_bang_catch_all = quote do
      def fetch!(key) do
        raise KeyError, key: key, term: __MODULE__
      end
    end

    get_catch_all = quote do
      def get(_key, default) do
        default
      end
    end

    # Combine all clauses efficiently (reverse to maintain order)
    all_clauses = Enum.reverse(fetch_clauses) ++
                  Enum.reverse(fetch_bang_clauses) ++
                  [get_header | Enum.reverse(get_clauses)] ++
                  [fetch_catch_all, fetch_bang_catch_all, get_catch_all]

    {all_clauses, Macro.escape(Enum.reverse(keys)), Macro.escape(Enum.reverse(escaped_entries))}
  end

  # Private helper functions

  defp validate_input(entries, source_type) do
    entry_count = length(entries)

    # Warn about large datasets that may cause performance issues
    cond do
      entry_count > 50_000 ->
        IO.warn("""
        Exfoil: Creating module with #{entry_count} entries from #{source_type}.
        This may result in very large bytecode and long compilation times.
        Consider using ETS directly or splitting into multiple modules for datasets this large.
        """)

      entry_count > 10_000 ->
        IO.warn("""
        Exfoil: Creating module with #{entry_count} entries from #{source_type}.
        Compilation may take longer for datasets this large.
        """)

      true ->
        :ok
    end

    # Additional validation could be added here:
    # - Check for duplicate keys
    # - Validate key types
    # - Check for reasonable value sizes
    :ok
  end
end