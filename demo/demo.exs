# Demo script for Exfoil library

IO.puts("=== Exfoil Demo: ETS to Module Converter ===\n")

# Create and populate an ETS table as described in the requirements
IO.puts("1. Creating ETS table 'tab1' with entries {:a, 1} and {:b, 2}")
:ets.new(:tab1, [:named_table])
:ets.insert(:tab1, {:a, 1})
:ets.insert(:tab1, {:b, 2})

IO.puts("   ETS table contents: #{inspect(:ets.tab2list(:tab1))}")

# Convert to module
IO.puts("\n2. Converting ETS table to module using Exfoil.convert(:tab1)")
{:ok, module_name} = Exfoil.convert(:tab1)
IO.puts("   Generated module: #{inspect(module_name)}")

# Test the generated functions
IO.puts("\n3. Testing the generated Tab1 module:")
IO.puts("   Tab1.get(:a) = #{inspect(Tab1.get(:a))}")
IO.puts("   Tab1.get(:b) = #{inspect(Tab1.get(:b))}")
IO.puts("   Tab1.get(:nonexistent) = #{inspect(Tab1.get(:nonexistent))}")

IO.puts("\n3b. Testing the bang version functions:")
IO.puts("   Tab1.get!(:a) = #{inspect(Tab1.get!(:a))}")
IO.puts("   Tab1.get!(:b) = #{inspect(Tab1.get!(:b))}")
IO.write("   Tab1.get!(:nonexistent) = ")
try do
  IO.puts("#{inspect(Tab1.get!(:nonexistent))}")
rescue
  e in KeyError ->
    IO.puts("KeyError: #{Exception.message(e)}")
end

# Test helper functions
IO.puts("\n4. Testing helper functions:")
IO.puts("   Tab1.keys() = #{inspect(Tab1.keys())}")
IO.puts("   Tab1.all() = #{inspect(Tab1.all())}")
IO.puts("   Tab1.count() = #{inspect(Tab1.count())}")

# Demo with more complex data
IO.puts("\n=== Advanced Example ===")

IO.puts("\n5. Creating complex ETS table with various data types")
:ets.new(:complex_data, [:named_table])
:ets.insert(:complex_data, {:string, "Hello World"})
:ets.insert(:complex_data, {:list, [1, 2, 3, 4, 5]})
:ets.insert(:complex_data, {:map, %{name: "John", age: 30}})
:ets.insert(:complex_data, {:tuple, {:ok, :success}})

{:ok, complex_module} = Exfoil.convert(:complex_data)
IO.puts("   Generated module: #{inspect(complex_module)}")

IO.puts("\n6. Testing complex data retrieval:")
IO.puts("   ComplexData.get(:string) = #{inspect(ComplexData.get(:string))}")
IO.puts("   ComplexData.get(:list) = #{inspect(ComplexData.get(:list))}")
IO.puts("   ComplexData.get(:map) = #{inspect(ComplexData.get(:map))}")
IO.puts("   ComplexData.get(:tuple) = #{inspect(ComplexData.get(:tuple))}")

IO.puts("\n6b. Testing bang versions for direct access:")
IO.puts("   ComplexData.get!(:string) = #{inspect(ComplexData.get!(:string))}")
IO.puts("   ComplexData.get!(:list) = #{inspect(ComplexData.get!(:list))}")
IO.puts("   ComplexData.get!(:map) = #{inspect(ComplexData.get!(:map))}")
IO.puts("   ComplexData.get!(:tuple) = #{inspect(ComplexData.get!(:tuple))}")

# Demo with custom options
IO.puts("\n=== Custom Options Demo ===")

IO.puts("\n7. Creating table with custom module name and function name")
:ets.new(:custom_table, [:named_table])
:ets.insert(:custom_table, {:setting1, "value1"})
:ets.insert(:custom_table, {:setting2, "value2"})

{:ok, custom_module} = Exfoil.convert(:custom_table,
                                      module_name: :MyConfig,
                                      function_name: :lookup)

IO.puts("   Generated module: #{inspect(custom_module)}")
IO.puts("   MyConfig.lookup(:setting1) = #{inspect(MyConfig.lookup(:setting1))}")
IO.puts("   MyConfig.lookup(:setting2) = #{inspect(MyConfig.lookup(:setting2))}")

IO.puts("\n7b. Testing custom bang functions:")
IO.puts("   MyConfig.lookup!(:setting1) = #{inspect(MyConfig.lookup!(:setting1))}")
IO.puts("   MyConfig.lookup!(:setting2) = #{inspect(MyConfig.lookup!(:setting2))}")

IO.puts("\n=== Demo Complete ===")

# Clean up
:ets.delete(:tab1)
:ets.delete(:complex_data)
:ets.delete(:custom_table)