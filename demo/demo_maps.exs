# Exfoil Maps Demo
# This demonstrates how to convert Elixir maps into dynamically generated modules

alias Exfoil.Maps

IO.puts("=== Exfoil Maps Demo ===\n")

# Example 1: Simple map conversion
IO.puts("1. Simple map conversion:")
simple_data = %{name: "Alice", age: 30, city: "San Francisco"}

{:ok, _module} = Maps.convert(simple_data, :Person)

IO.puts("   :Person.get(:name) => #{inspect :Person.get(:name)}")
IO.puts("   :Person.get(:age) => #{inspect :Person.get(:age)}")
IO.puts("   :Person.get(:city) => #{inspect :Person.get(:city)}")
IO.puts("   :Person.get(:nonexistent) => #{inspect :Person.get(:nonexistent)}")
IO.puts("   :Person.count() => #{inspect :Person.count()}")
IO.puts("   :Person.keys() => #{inspect :Person.keys()}")
IO.puts("")

# Example 2: Complex data types
IO.puts("2. Complex data types:")
complex_data = %{
  config: %{database: "postgres", port: 5432},
  features: [:auth, :logging, :metrics],
  metadata: {:version, "1.2.3"},
  stats: [requests: 1000, errors: 5]
}

{:ok, _module} = Maps.convert(complex_data, :AppSettings)

IO.puts("   :AppSettings.get(:config) => #{inspect :AppSettings.get(:config)}")
IO.puts("   :AppSettings.get(:features) => #{inspect :AppSettings.get(:features)}")
IO.puts("   :AppSettings.get(:metadata) => #{inspect :AppSettings.get(:metadata)}")
IO.puts("   :AppSettings.get(:stats) => #{inspect :AppSettings.get(:stats)}")
IO.puts("")

# Example 3: Custom function name
IO.puts("3. Custom function name:")
user_data = %{username: "bob", role: :admin, active: true}

{:ok, _module} = Maps.convert(user_data, :User, function_name: :lookup)

IO.puts("   :User.lookup(:username) => #{inspect :User.lookup(:username)}")
IO.puts("   :User.lookup(:role) => #{inspect :User.lookup(:role)}")
IO.puts("   :User.lookup(:active) => #{inspect :User.lookup(:active)}")
IO.puts("")

# Example 4: Auto-generated module names
IO.puts("4. Auto-generated module names:")
config1 = %{env: :dev, debug: true}
config2 = %{env: :prod, debug: false}

{:ok, module1} = Maps.convert_with_auto_name(config1)
{:ok, module2} = Maps.convert_with_auto_name(config2)

IO.puts("   First config module: #{inspect module1}")
IO.puts("   #{module1}.get(:env) => #{inspect module1.get(:env)}")
IO.puts("   Second config module: #{inspect module2}")
IO.puts("   #{module2}.get(:env) => #{inspect module2.get(:env)}")
IO.puts("")

# Example 5: String and mixed keys
IO.puts("5. String and mixed keys:")
mixed_data = %{
  :atom_key => "atom value",
  "string_key" => "string value",
  1 => "number key value"
}

{:ok, _module} = Maps.convert(mixed_data, :MixedKeys)

IO.puts("   :MixedKeys.get(:atom_key) => #{inspect :MixedKeys.get(:atom_key)}")
IO.puts("   :MixedKeys.get(\"string_key\") => #{inspect :MixedKeys.get("string_key")}")
IO.puts("   :MixedKeys.get(1) => #{inspect :MixedKeys.get(1)}")
IO.puts("")

# Example 6: Utility functions
IO.puts("6. Utility functions:")
sample_data = %{a: 1, b: 2, c: 3, d: 4}

{:ok, _module} = Maps.convert(sample_data, :Sample)

IO.puts("   :Sample.count() => #{inspect :Sample.count()}")
IO.puts("   :Sample.keys() => #{inspect :Sample.keys()}")
IO.puts("   :Sample.all() => #{inspect :Sample.all()}")
IO.puts("   :Sample.to_map() => #{inspect :Sample.to_map()}")
IO.puts("   :Sample.has_key?(:a) => #{inspect :Sample.has_key?(:a)}")
IO.puts("   :Sample.has_key?(:z) => #{inspect :Sample.has_key?(:z)}")
IO.puts("")

# Example 7: Empty map
IO.puts("7. Empty map:")
empty_data = %{}

{:ok, _module} = Maps.convert(empty_data, :EmptyModule)

IO.puts("   :EmptyModule.count() => #{inspect :EmptyModule.count()}")
IO.puts("   :EmptyModule.keys() => #{inspect :EmptyModule.keys()}")
IO.puts("   :EmptyModule.all() => #{inspect :EmptyModule.all()}")
IO.puts("   :EmptyModule.to_map() => #{inspect :EmptyModule.to_map()}")
IO.puts("")

# Example 8: Large map performance demo
IO.puts("8. Large map (100 entries):")
large_data = 1..100 |> Enum.into(%{}, fn i -> {String.to_atom("item_#{i}"), i * i} end)

{:ok, _module} = Maps.convert(large_data, :LargeData)

IO.puts("   :LargeData.count() => #{inspect :LargeData.count()}")
IO.puts("   :LargeData.get(:item_10) => #{inspect :LargeData.get(:item_10)}")
IO.puts("   :LargeData.get(:item_50) => #{inspect :LargeData.get(:item_50)}")
IO.puts("   :LargeData.has_key?(:item_99) => #{inspect :LargeData.has_key?(:item_99)}")

IO.puts("\n=== Demo Complete ===")
IO.puts("All generated modules are now available for use!")
IO.puts("Try calling functions like :Person.get(:name) or :AppSettings.get(:config)")