# Simple benchmark comparing ETS vs Exfoil for quick testing

IO.puts("=== Quick Exfoil vs ETS Benchmark ===\n")

# Create test data
data_size = 1000
data = Enum.map(1..data_size, fn i ->
  {String.to_atom("key_#{i}"), "value_#{i}"}
end)

# Setup ETS table
:ets.new(:quick_test, [:named_table])
:ets.insert(:quick_test, data)

# Setup Exfoil module
{:ok, module_name} = Exfoil.convert(:quick_test)
IO.puts("Generated module: #{inspect(module_name)}")

# Test key for benchmarking
test_key = :key_500

IO.puts("Testing key retrieval: #{test_key}")
IO.puts("Dataset size: #{data_size} entries\n")

# Simple timing function
defmodule SimpleBench do
  def time_function(name, func, iterations \\ 100_000) do
    start_time = :os.timestamp()

    Enum.each(1..iterations, fn _ ->
      func.()
    end)

    end_time = :os.timestamp()
    diff_microseconds = :timer.now_diff(end_time, start_time)
    avg_nanoseconds = (diff_microseconds * 1000) / iterations

    IO.puts("#{name}: #{Float.round(avg_nanoseconds, 2)} ns per operation")
    avg_nanoseconds
  end
end

# Run benchmarks
ets_time = SimpleBench.time_function("ETS lookup", fn ->
  :ets.lookup(:quick_test, test_key)
end)

exfoil_time = SimpleBench.time_function("Exfoil call", fn ->
  apply(module_name, :get, [test_key])
end)

# Calculate improvement
improvement = ets_time / exfoil_time
IO.puts("\nResult: Exfoil is #{Float.round(improvement, 2)}x faster than ETS")

# Memory comparison
ets_memory = :ets.info(:quick_test, :memory) * :erlang.system_info(:wordsize)
IO.puts("\nMemory usage:")
IO.puts("ETS table: #{ets_memory} bytes (#{Float.round(ets_memory / 1024, 2)} KB)")
IO.puts("Exfoil module: Stored in bytecode (minimal runtime memory)")

# Test correctness
ets_result = case :ets.lookup(:quick_test, test_key) do
  [{^test_key, value}] -> value
  [] -> {:error, :not_found}
end

exfoil_result = apply(module_name, :get, [test_key])

IO.puts("\nCorrectness check:")
IO.puts("ETS result: #{inspect(ets_result)}")
IO.puts("Exfoil result: #{inspect(exfoil_result)}")
IO.puts("Results match: #{inspect(ets_result == exfoil_result)}")

# Cleanup
:ets.delete(:quick_test)

IO.puts("\n✅ Benchmark complete!")