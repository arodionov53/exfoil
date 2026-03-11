# Benchmark script to compare ETS vs Exfoil performance

IO.puts("=== Exfoil vs ETS Performance Benchmark ===\n")

# Helper functions for generating test data
defmodule BenchmarkHelpers do
  def generate_data(size) do
    1..size
    |> Enum.map(fn i ->
      {String.to_atom("key_#{i}"), "value_#{i}"}
    end)
  end

  def generate_complex_data(size) do
    1..size
    |> Enum.map(fn i ->
      case rem(i, 4) do
        0 -> {String.to_atom("key_#{i}"), "string_value_#{i}"}
        1 -> {String.to_atom("key_#{i}"), [i, i*2, i*3]}
        2 -> {String.to_atom("key_#{i}"), %{id: i, name: "item_#{i}"}}
        3 -> {String.to_atom("key_#{i}"), {:ok, i}}
      end
    end)
  end

  def setup_ets_table(name, data) do
    # Clean up existing table if it exists
    if :ets.info(name) != :undefined do
      :ets.delete(name)
    end

    :ets.new(name, [:named_table, :set, {:read_concurrency, true}])
    :ets.insert(name, data)
    name
  end

  def setup_exfoil_module(table_name) do
    {:ok, module_name} = Exfoil.convert(table_name)
    module_name
  end

  def random_keys(data, count) do
    keys = Enum.map(data, fn {key, _} -> key end)
    Enum.take_random(keys, count)
  end

  def cleanup_table(name) do
    if :ets.info(name) != :undefined do
      :ets.delete(name)
    end
  end
end

# Benchmark configurations
benchmark_configs = [
  %{
    name: "Small Dataset (100 entries)",
    size: 100,
    lookup_count: 1000,
    data_generator: &BenchmarkHelpers.generate_data/1
  },
  %{
    name: "Medium Dataset (1,000 entries)",
    size: 1000,
    lookup_count: 10000,
    data_generator: &BenchmarkHelpers.generate_data/1
  },
  %{
    name: "Large Dataset (10,000 entries)",
    size: 10000,
    lookup_count: 50000,
    data_generator: &BenchmarkHelpers.generate_data/1
  },
  %{
    name: "Complex Data Types (1,000 entries)",
    size: 1000,
    lookup_count: 10000,
    data_generator: &BenchmarkHelpers.generate_complex_data/1
  }
]

# Run benchmarks for each configuration
Enum.each(benchmark_configs, fn config ->
  IO.puts("Running benchmark: #{config.name}")
  IO.puts("Dataset size: #{config.size}, Lookups: #{config.lookup_count}")

  # Generate test data
  data = config.data_generator.(config.size)

  # Setup ETS table
  table_name = :benchmark_table
  BenchmarkHelpers.setup_ets_table(table_name, data)

  # Setup Exfoil module
  module_name = BenchmarkHelpers.setup_exfoil_module(table_name)

  # Generate random keys for lookup tests
  lookup_keys = BenchmarkHelpers.random_keys(data, config.lookup_count)

  # Run the benchmark
  Benchee.run(
    %{
      "ETS lookup" => fn ->
        Enum.each(lookup_keys, fn key ->
          :ets.lookup(table_name, key)
        end)
      end,
      "Exfoil function call" => fn ->
        Enum.each(lookup_keys, fn key ->
          apply(module_name, :get, [key])
        end)
      end
    },
    time: 5,
    memory_time: 2,
    formatters: [Benchee.Formatters.Console]
  )

  # Cleanup
  BenchmarkHelpers.cleanup_table(table_name)

  IO.puts("\n" <> String.duplicate("=", 60) <> "\n")
end)

# Single key lookup benchmark for more focused comparison
IO.puts("=== Single Key Lookup Comparison ===\n")

# Setup for single key benchmarks
single_key_data = BenchmarkHelpers.generate_data(1000)
single_table = :single_benchmark_table
BenchmarkHelpers.setup_ets_table(single_table, single_key_data)
single_module = BenchmarkHelpers.setup_exfoil_module(single_table)

# Pick a key that exists
test_key = :key_500

IO.puts("Testing single key lookup: #{test_key}")
IO.puts("Comparing 1,000,000 lookups of the same key\n")

Benchee.run(
  %{
    "ETS single lookup" => fn ->
      :ets.lookup(single_table, test_key)
    end,
    "Exfoil single call" => fn ->
      apply(single_module, :get, [test_key])
    end,
    "ETS lookup (safe format)" => fn ->
      case :ets.lookup(single_table, test_key) do
        [{^test_key, value}] -> {:ok, value}
        [] -> {:error, :not_found}
      end
    end,
    "Exfoil bang call" => fn ->
      apply(single_module, :fetch!, [test_key])
    end
  },
  time: 5,
  memory_time: 2,
  formatters: [Benchee.Formatters.Console]
)

# Cleanup
BenchmarkHelpers.cleanup_table(single_table)

IO.puts("\n=== Key Findings Summary ===")
IO.puts("1. Exfoil uses direct function calls (compile-time optimized)")
IO.puts("2. ETS uses runtime hash table lookups")
IO.puts("3. Exfoil should be faster for frequently accessed static data")
IO.puts("4. ETS is better for dynamic data that changes frequently")
IO.puts("5. Memory usage: Exfoil stores data in module bytecode")
IO.puts("6. Memory usage: ETS stores data in separate memory space")

# Memory usage comparison
IO.puts("\n=== Memory Usage Analysis ===")

# Create test data for memory analysis
memory_test_data = BenchmarkHelpers.generate_data(5000)
memory_table = :memory_test_table

IO.puts("Creating ETS table with 5,000 entries...")
BenchmarkHelpers.setup_ets_table(memory_table, memory_test_data)

ets_memory_words = :ets.info(memory_table, :memory)
ets_memory_bytes = ets_memory_words * :erlang.system_info(:wordsize)

IO.puts("ETS table memory: #{ets_memory_bytes} bytes (#{Float.round(ets_memory_bytes / 1024, 2)} KB)")

IO.puts("Creating Exfoil module with same data...")
memory_module = BenchmarkHelpers.setup_exfoil_module(memory_table)

# Get module info (this is an approximation since module memory is harder to measure)
module_info = apply(memory_module, :module_info, [])
IO.puts("Exfoil module created: #{memory_module}")
IO.puts("Module functions: #{length(module_info[:exports])}")

BenchmarkHelpers.cleanup_table(memory_table)

IO.puts("\n=== Benchmark Complete ===")