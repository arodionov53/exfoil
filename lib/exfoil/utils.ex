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

    # If it's already in PascalCase (starts with uppercase), keep it as is
    if String.match?(str, ~r/^[A-Z]/) do
      String.to_atom(str)
    else
      # Otherwise, split on underscores and capitalize each part
      str
      |> String.split("_")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join("")
      |> String.to_atom()
    end
  end

  @doc """
  Normalizes a function name to valid Elixir format (lowercase).

  Function names must start with a lowercase letter or underscore.

  ## Examples

      iex> Exfoil.Utils.normalize_function_name(:Lookup)
      :lookup

      iex> Exfoil.Utils.normalize_function_name(:GetData)
      :getdata

      iex> Exfoil.Utils.normalize_function_name(:_PrivateGet)
      :_privateget

      iex> Exfoil.Utils.normalize_function_name(:fetch)
      :fetch
  """
  def normalize_function_name(function_name) do
    str = to_string(function_name)

    # Function names must start with lowercase letter or underscore
    cond do
      # If it starts with underscore followed by uppercase, preserve underscore but lowercase the rest
      String.match?(str, ~r/^_[A-Z]/) ->
        "_" <> rest = str
        String.to_atom("_" <> String.downcase(rest))

      # If it starts with uppercase, convert to lowercase
      String.match?(str, ~r/^[A-Z]/) ->
        str
        |> String.downcase()
        |> String.to_atom()

      # Otherwise keep as is
      true ->
        String.to_atom(str)
    end
  end

  @doc """
  Creates a dynamic module with the given name, function name, and entries.

  ## Parameters
    - module_name: The name for the generated module
    - function_name: The name of the lookup function to generate
    - entries: List of {key, value} tuples to include in the module
    - source_type: Optional description of the data source (default: "data source")
    - extra_functions: Optional list of additional function ASTs to include

  ## Returns
    The module alias of the created module
  """
  def create_module(module_name, function_name, entries, source_type \\ "data source", extra_functions \\ []) do
    # Generate function clauses for each entry
    function_clauses = generate_function_clauses(function_name, entries)

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

        # Include any additional functions
        unquote_splicing(extra_functions)
      end
    end

    # Compile and load the module
    Code.eval_quoted(module_ast)

    module_alias
  end

  @doc """
  Generates function clauses for the lookup function based on the provided entries.
  Creates both safe and bang versions of the function.

  ## Parameters
    - function_name: The name of the function to generate
    - entries: List of {key, value} tuples

  ## Returns
    List of AST nodes representing function clauses
  """
  def generate_function_clauses(function_name, entries) do
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