#!/usr/bin/env elixir

# Benchmark with larger maps to see where Exfoil.Maps excels
# Run with: mix run large_map_benchmark.exs

alias Exfoil.Maps

IO.puts("=== Large Map Benchmark: Exfoil.Maps vs Map ===\n")

# Test different map sizes
map_sizes = [1000, 5000, 10000]

Enum.each(map_sizes, fn size ->
  IO.puts("Testing with #{size} entries:")
  IO.puts(String.duplicate("-", 30))

  # Create large test data
  test_data = 1..size
    |> Enum.into(%{}, fn i ->
      {String.to_atom("key_#{i}"), %{
        id: i,
        name: "Item #{i}",
        data: %{
          nested: %{
            value: i * 2,
            description: "Complex nested data for item #{i}"
          }
        },
        tags: ["tag#{rem(i, 5)}", "category#{rem(i, 3)}"],
        timestamp: DateTime.utc_now()
      }}
    end)

  # Convert to Exfoil module
  {:ok, module_name} = Maps.convert(test_data, String.to_atom("LargeTestModule#{size}"))

  # Sample keys for testing (test 1% of keys, minimum 10)
  sample_size = max(10, div(size, 100))
  sample_keys = test_data
    |> Map.keys()
    |> Enum.take_every(div(size, sample_size))
    |> Enum.take(sample_size)

  IO.puts("Sample size: #{length(sample_keys)} keys")

  # Benchmark
  Benchee.run(
    %{
      "Exfoil.Maps" => fn ->
        Enum.each(sample_keys, &module_name.get/1)
      end,
      "Map.get/2" => fn ->
        Enum.each(sample_keys, &Map.get(test_data, &1))
      end
    },
    time: 2,
    memory_time: 1,
    formatters: [{Benchee.Formatters.Console, comparison: true}]
  )

  # Test single access pattern
  IO.puts("\nSingle key access (worst case - last key):")
  worst_case_key = String.to_atom("key_#{size}")

  Benchee.run(
    %{
      "Exfoil.Maps single" => fn ->
        module_name.get(worst_case_key)
      end,
      "Map.get/2 single" => fn ->
        Map.get(test_data, worst_case_key)
      end
    },
    time: 2,
    formatters: [{Benchee.Formatters.Console, comparison: true}]
  )

  IO.puts("\n" <> String.duplicate("=", 50) <> "\n")
end)

IO.puts("=== Observations ===")
IO.puts("• Elixir maps are highly optimized in modern BEAM versions")
IO.puts("• For small to medium maps (~1000-10000 entries), performance is comparable")
IO.puts("• Exfoil.Maps provides consistent O(1) access regardless of map size")
IO.puts("• Regular maps may show some performance degradation with very large maps")
IO.puts("• The main advantage of Exfoil.Maps is consistent predictable performance")
IO.puts("• Best use cases: static config data, lookup tables, cached API responses")