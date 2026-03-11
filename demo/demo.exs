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
IO.puts("   Tab1.fetch(:a) = #{inspect(Tab1.fetch(:a))}")
IO.puts("   Tab1.fetch(:b) = #{inspect(Tab1.fetch(:b))}")
IO.puts("   Tab1.fetch(:nonexistent) = #{inspect(Tab1.fetch(:nonexistent))}")

IO.puts("\n3b. Testing the bang version functions:")
IO.puts("   Tab1.fetch!(:a) = #{inspect(Tab1.fetch!(:a))}")
IO.puts("   Tab1.fetch!(:b) = #{inspect(Tab1.fetch!(:b))}")
IO.write("   Tab1.fetch!(:nonexistent) = ")
try do
  IO.puts("#{inspect(Tab1.fetch!(:nonexistent))}")
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
IO.puts("   ComplexData.fetch(:string) = #{inspect(ComplexData.fetch(:string))}")
IO.puts("   ComplexData.fetch(:list) = #{inspect(ComplexData.fetch(:list))}")
IO.puts("   ComplexData.fetch(:map) = #{inspect(ComplexData.fetch(:map))}")
IO.puts("   ComplexData.fetch(:tuple) = #{inspect(ComplexData.fetch(:tuple))}")

IO.puts("\n6b. Testing bang versions for direct access:")
IO.puts("   ComplexData.fetch!(:string) = #{inspect(ComplexData.fetch!(:string))}")
IO.puts("   ComplexData.fetch!(:list) = #{inspect(ComplexData.fetch!(:list))}")
IO.puts("   ComplexData.fetch!(:map) = #{inspect(ComplexData.fetch!(:map))}")
IO.puts("   ComplexData.fetch!(:tuple) = #{inspect(ComplexData.fetch!(:tuple))}")

# Demo with custom options
IO.puts("\n=== Custom Options Demo ===")

IO.puts("\n7. Creating table with custom module name")
:ets.new(:custom_table, [:named_table])
:ets.insert(:custom_table, {:setting1, "value1"})
:ets.insert(:custom_table, {:setting2, "value2"})

{:ok, custom_module} = Exfoil.convert(:custom_table,
                                      module_name: :MyConfig)

IO.puts("   Generated module: #{inspect(custom_module)}")
IO.puts("   MyConfig.fetch(:setting1) = #{inspect(MyConfig.fetch(:setting1))}")
IO.puts("   MyConfig.fetch(:setting2) = #{inspect(MyConfig.fetch(:setting2))}")

IO.puts("\n7b. Testing custom bang functions:")
IO.puts("   MyConfig.fetch!(:setting1) = #{inspect(MyConfig.fetch!(:setting1))}")
IO.puts("   MyConfig.fetch!(:setting2) = #{inspect(MyConfig.fetch!(:setting2))}")

IO.puts("\n=== Demo Complete ===")

# Clean up
:ets.delete(:tab1)
:ets.delete(:complex_data)
:ets.delete(:custom_table)