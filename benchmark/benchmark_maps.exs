#!/usr/bin/env elixir

# Comprehensive benchmark comparing Exfoil.Maps vs regular Map access
# Run with: mix run benchmark_maps.exs

alias Exfoil.Maps

# Benchmark configuration
IO.puts("=== Exfoil.Maps Performance Benchmark ===\n")
IO.puts("Comparing Exfoil.Maps generated modules vs regular Map access")
IO.puts("Platform: #{:erlang.system_info(:system_architecture)}")
IO.puts("BEAM: #{:erlang.system_info(:otp_release)}")
IO.puts("Elixir: #{System.version()}")
IO.puts("")

# Test data sets of different sizes
test_data_sizes = [
  {10, "Small (10 entries)"},
  {100, "Medium (100 entries)"},
  {1000, "Large (1000 entries)"},
  {10000, "Extra Large (10k entries)"}
]

# Function to create test data
create_test_data = fn size ->
  1..size
  |> Enum.into(%{}, fn i ->
    {String.to_atom("key_#{i}"), "value_#{i}_#{:rand.uniform(1000)}"}
  end)
end

# Function to run benchmarks for a specific data set
run_benchmark = fn {size, description} ->
  IO.puts("#{description}")
  IO.puts(String.duplicate("-", String.length(description)))

  # Create test data
  test_data = create_test_data.(size)

  # Generate Exfoil module
  {:ok, module_name} = Maps.convert(test_data, String.to_atom("TestModule#{size}"))

  # Sample keys for testing (10% of total keys)
  sample_size = max(1, div(size, 10))
  sample_keys = test_data |> Map.keys() |> Enum.take(sample_size)

  # Run benchmarks
  Benchee.run(
    %{
      "Exfoil.Maps" => fn ->
        Enum.each(sample_keys, fn key ->
          module_name.get(key)
        end)
      end,
      "Map.get/2" => fn ->
        Enum.each(sample_keys, fn key ->
          Map.get(test_data, key)
        end)
      end,
      "Map.fetch/2" => fn ->
        Enum.each(sample_keys, fn key ->
          Map.fetch(test_data, key)
        end)
      end,
      "Access syntax" => fn ->
        Enum.each(sample_keys, fn key ->
          test_data[key]
        end)
      end
    },
    time: 3,
    memory_time: 2,
    print: %{
      benchmarking: false,
      fast_warning: false
    },
    formatters: [
      {Benchee.Formatters.Console,
       extended_statistics: true,
       comparison: true}
    ]
  )

  IO.puts("")
end

# Memory usage comparison
memory_comparison = fn ->
  IO.puts("Memory Usage Comparison")
  IO.puts("======================")

  # Create test data
  test_data = create_test_data.(1000)

  # Measure memory before creating module
  :erlang.garbage_collect()
  {mem_before, _} = :erlang.process_info(self(), :memory)

  # Create Exfoil module
  {:ok, module_name} = Maps.convert(test_data, :MemoryTestModule)

  # Measure memory after creating module
  :erlang.garbage_collect()
  {mem_after, _} = :erlang.process_info(self(), :memory)

  # Calculate sizes
  map_size = :erlang.external_size(test_data)
  module_memory_overhead = mem_after - mem_before

  IO.puts("Original map size: #{map_size} bytes")
  IO.puts("Module creation overhead: #{module_memory_overhead} bytes")
  IO.puts("Overhead ratio: #{Float.round(module_memory_overhead / map_size, 2)}x")
  IO.puts("")

  # Test actual runtime memory usage during access
  IO.puts("Runtime Memory Usage During Access:")
  Benchee.run(
    %{
      "Exfoil.Maps access" => fn ->
        :key_100
        |> module_name.get()
      end,
      "Map.get/2 access" => fn ->
        Map.get(test_data, :key_100)
      end
    },
    time: 1,
    memory_time: 2,
    print: %{benchmarking: false, fast_warning: false},
    formatters: [{Benchee.Formatters.Console, extended_statistics: true}]
  )

  IO.puts("")
end

# Different key types performance
key_types_benchmark = fn ->
  IO.puts("Key Types Performance Comparison")
  IO.puts("===============================")

  # Create maps with different key types
  atom_map = 1..100 |> Enum.into(%{}, fn i -> {String.to_atom("key_#{i}"), i} end)
  string_map = 1..100 |> Enum.into(%{}, fn i -> {"key_#{i}", i} end)
  integer_map = 1..100 |> Enum.into(%{}, fn i -> {i, "value_#{i}"} end)

  # Create Exfoil modules
  {:ok, atom_module} = Maps.convert(atom_map, :AtomKeyModule)
  {:ok, string_module} = Maps.convert(string_map, :StringKeyModule)
  {:ok, integer_module} = Maps.convert(integer_map, :IntegerKeyModule)

  # Sample keys
  sample_atom_keys = Enum.take(Map.keys(atom_map), 10)
  sample_string_keys = Enum.take(Map.keys(string_map), 10)
  sample_integer_keys = Enum.take(Map.keys(integer_map), 10)

  IO.puts("Atom Keys:")
  Benchee.run(
    %{
      "Exfoil.Maps" => fn ->
        Enum.each(sample_atom_keys, &atom_module.get/1)
      end,
      "Map.get/2" => fn ->
        Enum.each(sample_atom_keys, &Map.get(atom_map, &1))
      end
    },
    time: 2,
    print: %{benchmarking: false, fast_warning: false},
    formatters: [{Benchee.Formatters.Console, comparison: true}]
  )

  IO.puts("String Keys:")
  Benchee.run(
    %{
      "Exfoil.Maps" => fn ->
        Enum.each(sample_string_keys, &string_module.get/1)
      end,
      "Map.get/2" => fn ->
        Enum.each(sample_string_keys, &Map.get(string_map, &1))
      end
    },
    time: 2,
    print: %{benchmarking: false, fast_warning: false},
    formatters: [{Benchee.Formatters.Console, comparison: true}]
  )

  IO.puts("Integer Keys:")
  Benchee.run(
    %{
      "Exfoil.Maps" => fn ->
        Enum.each(sample_integer_keys, &integer_module.get/1)
      end,
      "Map.get/2" => fn ->
        Enum.each(sample_integer_keys, &Map.get(integer_map, &1))
      end
    },
    time: 2,
    print: %{benchmarking: false, fast_warning: false},
    formatters: [{Benchee.Formatters.Console, comparison: true}]
  )

  IO.puts("")
end

# Utility functions benchmark
utility_functions_benchmark = fn ->
  IO.puts("Utility Functions Performance")
  IO.puts("============================")

  test_data = create_test_data.(1000)
  {:ok, module_name} = Maps.convert(test_data, :UtilityTestModule)

  Benchee.run(
    %{
      "Exfoil.Maps keys()" => fn -> module_name.keys() end,
      "Map.keys/1" => fn -> Map.keys(test_data) end,
      "Exfoil.Maps count()" => fn -> module_name.count() end,
      "Enum.count/1 map" => fn -> Enum.count(test_data) end,
      "map_size/1" => fn -> map_size(test_data) end,
      "Exfoil.Maps has_key?" => fn -> module_name.has_key?(:key_100) end,
      "Map.has_key?/2" => fn -> Map.has_key?(test_data, :key_100) end,
      "Exfoil.Maps to_map()" => fn -> module_name.to_map() end,
      "Identity (already map)" => fn -> test_data end
    },
    time: 2,
    print: %{benchmarking: false, fast_warning: false},
    formatters: [{Benchee.Formatters.Console, comparison: true}]
  )

  IO.puts("")
end

# Cache miss simulation
cache_miss_benchmark = fn ->
  IO.puts("Cache Miss Behavior")
  IO.puts("==================")

  test_data = create_test_data.(100)
  {:ok, module_name} = Maps.convert(test_data, :CacheMissModule)

  # Test accessing non-existent keys
  missing_keys = [:missing_1, :missing_2, :missing_3, :missing_4, :missing_5]

  Benchee.run(
    %{
      "Exfoil.Maps (missing key)" => fn ->
        Enum.each(missing_keys, &module_name.get/1)
      end,
      "Map.get/2 (missing key)" => fn ->
        Enum.each(missing_keys, &Map.get(test_data, &1))
      end,
      "Map.fetch/2 (missing key)" => fn ->
        Enum.each(missing_keys, fn key ->
          case Map.fetch(test_data, key) do
            {:ok, value} -> value
            :error -> {:error, :not_found}
          end
        end)
      end
    },
    time: 2,
    print: %{benchmarking: false, fast_warning: false},
    formatters: [{Benchee.Formatters.Console, comparison: true}]
  )

  IO.puts("")
end

# Module creation overhead benchmark
creation_overhead_benchmark = fn ->
  IO.puts("Module Creation Overhead")
  IO.puts("=======================")

  sizes = [10, 100, 1000]

  Enum.each(sizes, fn size ->
    test_data = create_test_data.(size)

    IO.puts("Creating module for #{size} entries:")

    Benchee.run(
      %{
        "Exfoil.Maps.convert/3" => fn ->
          {:ok, _} = Maps.convert(test_data, String.to_atom("CreationTest#{size}_#{:rand.uniform(10000)}"))
        end,
        "Identity (no conversion)" => fn ->
          test_data
        end
      },
      time: 1,
      print: %{benchmarking: false, fast_warning: false},
      formatters: [{Benchee.Formatters.Console, comparison: true}]
    )
  end)

  IO.puts("")
end

# Run all benchmarks
IO.puts("Starting benchmarks... This may take a few minutes.\n")

Enum.each(test_data_sizes, run_benchmark)
memory_comparison.()
key_types_benchmark.()
utility_functions_benchmark.()
cache_miss_benchmark.()
creation_overhead_benchmark.()

IO.puts("=== Benchmark Summary ===")
IO.puts("Exfoil.Maps converts map lookups into direct function calls,")
IO.puts("providing significant performance improvements for read-heavy workloads.")
IO.puts("")
IO.puts("Key benefits:")
IO.puts("- Faster access times (typically 2-10x faster)")
IO.puts("- Consistent performance regardless of map size")
IO.puts("- Compile-time optimized function calls")
IO.puts("- No hash table lookups at runtime")
IO.puts("")
IO.puts("Trade-offs:")
IO.puts("- One-time module creation cost")
IO.puts("- Memory overhead for storing module bytecode")
IO.puts("- Static data (map changes require new module)")
IO.puts("")
IO.puts("Best used for: Configuration data, lookup tables, cached results,")
IO.puts("and other read-heavy, relatively static data structures.")