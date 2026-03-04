defmodule Exfoil.Maps do
  @moduledoc """
  Exfoil.Maps converts Elixir maps into dynamically generated modules with function calls.

  For example, a map `%{a: 1, b: 2}` will be converted to a dynamically created module
  with functions:
  - `YourModule.get(:a)` which returns `{:ok, 1}`
  - `YourModule.get(:b)` which returns `{:ok, 2}`
  - `YourModule.get(:missing)` which returns `{:error, :not_found}`
  - `YourModule.get!(:a)` which returns `1`
  - `YourModule.get!(:missing)` which raises a `KeyError`
  """

  @doc """
  Converts a map into a dynamically generated module with getter functions.

  ## Parameters

  - `map` - The map to convert
  - `module_name` - The name for the generated module (atom)
  - `opts` - Optional keyword list with configuration options
    - `:function_name` - Custom function name (defaults to `:get`)

  ## Examples

      # Create a map
      data = %{a: 1, b: 2, c: "hello"}

      # Convert to module
      Exfoil.Maps.convert(data, :MyData)

      # Now you can use the generated module
      MyData.get(:a)   # => {:ok, 1}
      MyData.get(:b)   # => {:ok, 2}
      MyData.get(:c)   # => {:ok, "hello"}
      MyData.get(:d)   # => {:error, :not_found}

      MyData.get!(:a)  # => 1
      MyData.get!(:b)  # => 2
      MyData.get!(:c)  # => "hello"
      MyData.get!(:d)  # => raises KeyError

  """
  def convert(map, module_name, opts \\ []) when is_map(map) and is_atom(module_name) do
    function_name = normalize_function_name(opts[:function_name] || :get)

    # Convert map to list of key-value tuples for consistency with ETS format
    entries = Map.to_list(map)

    # Normalize the module name to ensure proper capitalization
    normalized_module_name = normalize_module_name(module_name)

    # Generate the module
    module_alias = create_module(normalized_module_name, function_name, entries)

    {:ok, module_alias}
  end

  @doc """
  Converts a map and returns the module directly.
  Raises an exception if conversion fails.

  ## Examples

      data = %{key: "value"}

      module = Exfoil.Maps.convert!(data, :MyModule)
      module.get(:key)   # => {:ok, "value"}
      module.get!(:key)  # => "value"

  """
  def convert!(map, module_name, opts \\ []) do
    case convert(map, module_name, opts) do
      {:ok, module_name} -> module_name
      {:error, reason} -> raise "Failed to convert map to module #{module_name}: #{reason}"
    end
  end

  @doc """
  Converts a map into a dynamically generated module with an auto-generated name.

  The module name is generated based on a hash of the map contents to ensure uniqueness.

  ## Examples

      data = %{a: 1, b: 2}
      {:ok, module_name} = Exfoil.Maps.convert_with_auto_name(data)

      # Use the returned module name
      module_name.get(:a)   # => {:ok, 1}
      module_name.get!(:a)  # => 1

  """
  def convert_with_auto_name(map, opts \\ []) when is_map(map) do
    module_name = generate_module_name(map)
    convert(map, module_name, opts)
  end

  # Private functions

  defp normalize_module_name(module_name) do
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

  defp normalize_function_name(function_name) do
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

  defp generate_module_name(map) do
    # Create a unique module name based on map hash
    hash =
      map
      |> :erlang.term_to_binary()
      |> :erlang.phash2()
      |> Integer.to_string(16)

    String.to_atom("ExfoilMap#{hash}")
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
        Dynamically generated module from map.
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

        @doc """
        Returns the original data as a map.
        """
        def to_map do
          unquote(Macro.escape(Map.new(entries)))
        end

        @doc """
        Checks if a key exists in this module.
        """
        def has_key?(key) do
          key in unquote(Macro.escape(Enum.map(entries, fn {key, _value} -> key end)))
        end
      end
    end

    # Compile and load the module
    Code.eval_quoted(module_ast)

    module_alias
  end

  defp generate_function_clauses(function_name, entries) do
    # Generate function clauses for the safe version (returns {:ok, value} or {:error, reason})
    safe_function_clauses = Enum.map(entries, fn {key, value} ->
      quote do
        def unquote(function_name)(unquote(key)) do
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
      def unquote(function_name)(_key) do
        {:error, :not_found}
      end
    end

    bang_catch_all = quote do
      def unquote(bang_function_name)(key) do
        raise KeyError, key: key, term: __MODULE__
      end
    end

    safe_function_clauses ++ bang_function_clauses ++ [safe_catch_all, bang_catch_all]
  end
end