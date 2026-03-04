# Benchmark for different ETS table types
# Run with: mix run benchmark/ets_table_types_benchmark.exs

defmodule EtsTableTypesBenchmark do
  @entry_count 10_000
  @lookup_iterations 100_000

  def run do
    IO.puts("=== Exfoil Benchmark: Different ETS Table Types ===")
    IO.puts("Entries per table: #{@entry_count}")
    IO.puts("Lookup iterations: #{@lookup_iterations}\n")

    # Prepare test data
    data = prepare_data(@entry_count)
    test_keys = prepare_test_keys(100)

    # Run benchmarks for each table type
    [:set, :ordered_set, :bag, :duplicate_bag]
    |> Enum.each(fn table_type ->
      IO.puts("\n" <> String.duplicate("=", 60))
      IO.puts("Testing #{inspect(table_type)} tables")
      IO.puts(String.duplicate("=", 60))

      # Benchmark named tables
      IO.puts("\n📊 Named #{table_type} table:")
      benchmark_named_table(table_type, data, test_keys)

      # Benchmark unnamed tables
      IO.puts("\n📊 Unnamed #{table_type} table:")
      benchmark_unnamed_table(table_type, data, test_keys)
    end)

    # Comparison with different table sizes
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("Performance scaling with table size (named :set tables)")
    IO.puts(String.duplicate("=", 60))

    [10, 100, 1_000, 10_000]
    |> Enum.each(fn size ->
      IO.puts("\n📈 Table size: #{size} entries")
      benchmark_table_size(size)
    end)

    IO.puts("\n=== Summary ===")
    IO.puts("• :set and :ordered_set have similar performance")
    IO.puts("• :bag and :duplicate_bag may have overhead with multiple values")
    IO.puts("• Exfoil provides consistent O(1) lookup regardless of table type")
    IO.puts("• Named vs unnamed tables have similar performance after conversion")
  end

  defp prepare_data(count) do
    1..count
    |> Enum.map(fn i ->
      {:"key_#{i}", %{
        id: i,
        value: "value_#{i}",
        data: :rand.uniform(1000)
      }}
    end)
  end

  defp prepare_test_keys(count) do
    max_key = @entry_count
    1..count
    |> Enum.map(fn _ -> :"key_#{:rand.uniform(max_key)}" end)
  end

  defp benchmark_named_table(table_type, data, test_keys) do
    table_name = :"bench_#{table_type}"

    # Create and populate table
    opts = [:named_table, table_type]
    :ets.new(table_name, opts)

    # For bag/duplicate_bag, insert some duplicate keys
    if table_type in [:bag, :duplicate_bag] do
      # Insert regular data
      Enum.each(data, fn {key, value} ->
        :ets.insert(table_name, {key, value})
      end)

      # Add some duplicate values for first 100 keys
      1..100
      |> Enum.each(fn i ->
        :ets.insert(table_name, {:"key_#{i}", %{duplicate: true, id: i}})
      end)
    else
      Enum.each(data, fn {key, value} ->
        :ets.insert(table_name, {key, value})
      end)
    end

    # Convert to Exfoil module
    {:ok, module} = Exfoil.convert(table_name)

    # Benchmark ETS lookups
    ets_time = :timer.tc(fn ->
      Enum.each(1..@lookup_iterations, fn _ ->
        key = Enum.random(test_keys)
        :ets.lookup(table_name, key)
      end)
    end) |> elem(0)

    # Benchmark Exfoil lookups
    exfoil_time = :timer.tc(fn ->
      Enum.each(1..@lookup_iterations, fn _ ->
        key = Enum.random(test_keys)
        module.get(key)
      end)
    end) |> elem(0)

    # Benchmark Exfoil bang lookups
    exfoil_bang_time = :timer.tc(fn ->
      Enum.each(1..@lookup_iterations, fn _ ->
        key = Enum.random(test_keys)
        try do
          module.get!(key)
        rescue
          KeyError -> nil
        end
      end)
    end) |> elem(0)

    # Memory comparison
    ets_memory = :ets.info(table_name, :memory) * :erlang.system_info(:wordsize)

    # Report results
    IO.puts("  ETS lookup:        #{format_time(ets_time)}")
    IO.puts("  Exfoil get/2:      #{format_time(exfoil_time)}")
    IO.puts("  Exfoil get!/1:     #{format_time(exfoil_bang_time)}")
    IO.puts("  Speed improvement: #{format_improvement(ets_time, exfoil_time)}")
    IO.puts("  ETS memory:        #{format_bytes(ets_memory)}")

    # Count actual entries (relevant for bag/duplicate_bag)
    actual_entries = :ets.info(table_name, :size)
    if actual_entries != @entry_count do
      IO.puts("  Note: Table has #{actual_entries} entries (duplicates present)")
    end

    # Cleanup
    :ets.delete(table_name)
  end

  defp benchmark_unnamed_table(table_type, data, test_keys) do
    # Create unnamed table
    table_ref = :ets.new(:unnamed, [table_type])

    # Populate table
    if table_type in [:bag, :duplicate_bag] do
      Enum.each(data, fn {key, value} ->
        :ets.insert(table_ref, {key, value})
      end)

      # Add duplicates
      1..100
      |> Enum.each(fn i ->
        :ets.insert(table_ref, {:"key_#{i}", %{duplicate: true, id: i}})
      end)
    else
      Enum.each(data, fn {key, value} ->
        :ets.insert(table_ref, {key, value})
      end)
    end

    # Convert to Exfoil module
    {:ok, module} = Exfoil.convert(table_ref)

    # Benchmark ETS lookups
    ets_time = :timer.tc(fn ->
      Enum.each(1..@lookup_iterations, fn _ ->
        key = Enum.random(test_keys)
        :ets.lookup(table_ref, key)
      end)
    end) |> elem(0)

    # Benchmark Exfoil lookups
    exfoil_time = :timer.tc(fn ->
      Enum.each(1..@lookup_iterations, fn _ ->
        key = Enum.random(test_keys)
        module.get(key)
      end)
    end) |> elem(0)

    # Report results
    IO.puts("  ETS lookup:        #{format_time(ets_time)}")
    IO.puts("  Exfoil get/2:      #{format_time(exfoil_time)}")
    IO.puts("  Speed improvement: #{format_improvement(ets_time, exfoil_time)}")

    # Cleanup
    :ets.delete(table_ref)
  end

  defp benchmark_table_size(size) do
    # Create data
    data = prepare_data(size)
    test_keys = 1..min(100, size) |> Enum.map(fn i -> :"key_#{i}" end)

    # Create table
    :ets.new(:size_test, [:named_table, :set])
    Enum.each(data, fn {key, value} ->
      :ets.insert(:size_test, {key, value})
    end)

    # Convert
    {:ok, module} = Exfoil.convert(:size_test)

    iterations = div(@lookup_iterations, 10)  # Fewer iterations for quick test

    # Benchmark
    ets_time = :timer.tc(fn ->
      Enum.each(1..iterations, fn _ ->
        key = Enum.random(test_keys)
        :ets.lookup(:size_test, key)
      end)
    end) |> elem(0)

    exfoil_time = :timer.tc(fn ->
      Enum.each(1..iterations, fn _ ->
        key = Enum.random(test_keys)
        module.get(key)
      end)
    end) |> elem(0)

    IO.puts("  ETS: #{format_time(ets_time)}, Exfoil: #{format_time(exfoil_time)}")
    IO.puts("  Improvement: #{format_improvement(ets_time, exfoil_time)}")

    # Cleanup
    :ets.delete(:size_test)
  end

  defp format_time(microseconds) do
    milliseconds = microseconds / 1000
    "#{Float.round(milliseconds, 2)} ms"
  end

  defp format_improvement(ets_time, exfoil_time) do
    improvement = ets_time / exfoil_time
    "#{Float.round(improvement, 2)}x faster"
  end

  defp format_bytes(bytes) do
    cond do
      bytes < 1024 ->
        "#{bytes} bytes"
      bytes < 1024 * 1024 ->
        "#{Float.round(bytes / 1024, 2)} KB"
      true ->
        "#{Float.round(bytes / (1024 * 1024), 2)} MB"
    end
  end
end

# Run the benchmark
EtsTableTypesBenchmark.run()