#!/usr/bin/env elixir

# Quick benchmark comparing Exfoil.Maps vs Map access
# Run with: mix run simple_benchmark_maps.exs

alias Exfoil.Maps

IO.puts("=== Quick Exfoil.Maps vs Map Benchmark ===\n")

# Create test data (100 entries)
test_data = 1..100
  |> Enum.into(%{}, fn i ->
    {String.to_atom("key_#{i}"), "value_#{i}"}
  end)

# Convert to Exfoil module
{:ok, module_name} = Maps.convert(test_data, :QuickTestModule)

# Sample keys for testing
sample_keys = [:key_1, :key_25, :key_50, :key_75, :key_100]

IO.puts("Test data: 100 entries")
IO.puts("Sample keys: #{inspect sample_keys}")
IO.puts("Platform: #{:erlang.system_info(:system_architecture)}")
IO.puts("")

# Quick benchmark
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
    "Access syntax map[key]" => fn ->
      Enum.each(sample_keys, fn key ->
        test_data[key]
      end)
    end
  },
  time: 3,
  memory_time: 2,
  formatters: [
    {Benchee.Formatters.Console,
     comparison: true,
     extended_statistics: true}
  ]
)

# Test single key access for cleaner results
IO.puts("\n=== Single Key Access Comparison ===")

Benchee.run(
  %{
    "Exfoil.Maps single access" => fn ->
      module_name.get(:key_50)
    end,
    "Map.get/2 single access" => fn ->
      Map.get(test_data, :key_50)
    end
  },
  time: 3,
  memory_time: 2,
  formatters: [
    {Benchee.Formatters.Console,
     comparison: true,
     extended_statistics: true}
  ]
)

# Memory usage comparison
IO.puts("\n=== Memory Usage ===")

# Check module memory overhead
:erlang.garbage_collect()
mem_before = :erlang.process_info(self(), :memory) |> elem(1)

{:ok, _temp_module} = Maps.convert(test_data, :TempMemTestModule)

:erlang.garbage_collect()
mem_after = :erlang.process_info(self(), :memory) |> elem(1)

map_size = :erlang.external_size(test_data)
module_overhead = mem_after - mem_before

IO.puts("Original map size: #{map_size} bytes")
IO.puts("Module creation overhead: #{module_overhead} bytes")
IO.puts("Overhead ratio: #{Float.round(module_overhead / map_size, 2)}x")

IO.puts("\n=== Summary ===")
IO.puts("Exfoil.Maps provides faster access by converting hash table lookups")
IO.puts("into direct function calls at compile time. Best for read-heavy,")
IO.puts("relatively static data where the performance gain outweighs the")
IO.puts("one-time creation cost and memory overhead.")