# Exfoil DETS Demo
# This demonstrates how to convert DETS (Disk-based ETS) tables into Elixir modules

alias Exfoil.Dets

IO.puts("=== Exfoil DETS Demo ===\n")

# 1. Simple DETS conversion
IO.puts("1. Simple DETS conversion:")

# Open a DETS table
{:ok, table} = :dets.open_file(:config_dets, [type: :set])

# Insert some configuration data
:dets.insert(table, {:database_host, "localhost"})
:dets.insert(table, {:database_port, 5432})
:dets.insert(table, {:cache_ttl, 3600})
:dets.insert(table, {:debug_mode, false})

# Convert to a module
{:ok, ConfigDets} = Dets.convert(:config_dets)

IO.puts("   ConfigDets.get(:database_host) => #{inspect ConfigDets.get(:database_host)}")
IO.puts("   ConfigDets.get(:database_port) => #{inspect ConfigDets.get(:database_port)}")
IO.puts("   ConfigDets.get(:cache_ttl) => #{inspect ConfigDets.get(:cache_ttl)}")
IO.puts("   ConfigDets.get(:debug_mode) => #{inspect ConfigDets.get(:debug_mode)}")
IO.puts("   ConfigDets.fetch!(:database_port) => #{inspect ConfigDets.fetch!(:database_port)}")

# Close the DETS table
:dets.close(table)

# 2. Complex data types
IO.puts("\n2. Complex data types in DETS:")

{:ok, table2} = :dets.open_file(:app_data, [type: :set])

:dets.insert(table2, {:users, ["alice", "bob", "charlie"]})
:dets.insert(table2, {:settings, %{theme: "dark", language: "en"}})
:dets.insert(table2, {:stats, %{requests: 1000, errors: 5, uptime: 99.9}})

{:ok, AppData} = Dets.convert(:app_data)

IO.puts("   AppData.get(:users) => #{inspect AppData.get(:users)}")
IO.puts("   AppData.get(:settings) => #{inspect AppData.get(:settings)}")
IO.puts("   AppData.get(:stats) => #{inspect AppData.get(:stats)}")
IO.puts("   AppData.count() => #{inspect AppData.count()}")
IO.puts("   AppData.keys() => #{inspect AppData.keys()}")

:dets.close(table2)

# 3. Persistence demonstration
IO.puts("\n3. Persistence demonstration:")

file_path = "demo_persist.dets"

# Create and populate a DETS file
IO.puts("   Creating DETS file: #{file_path}")
{:ok, table3} = :dets.open_file(:persist_demo, [{:file, String.to_charlist(file_path)}, {:type, :set}])
:dets.insert(table3, {:created_at, DateTime.utc_now()})
:dets.insert(table3, {:counter, 42})
:dets.close(table3)

# Reopen and convert - data persists!
IO.puts("   Reopening DETS file...")
{:ok, _table3} = :dets.open_file(:persist_demo, [{:file, String.to_charlist(file_path)}])
{:ok, PersistDemo} = Dets.convert(:persist_demo)

IO.puts("   PersistDemo.get(:created_at) => #{inspect PersistDemo.get(:created_at)}")
IO.puts("   PersistDemo.get(:counter) => #{inspect PersistDemo.get(:counter)}")

:dets.close(:persist_demo)

# Clean up the file
File.rm(file_path)

# 4. Using convert_file for convenience
IO.puts("\n4. Using convert_file for convenience:")

file_path2 = "demo_file.dets"

# First create a DETS file
{:ok, table4} = :dets.open_file(:prep, [{:file, String.to_charlist(file_path2)}, {:type, :set}])
:dets.insert(table4, {:api_key, "secret123"})
:dets.insert(table4, {:endpoint, "https://api.example.com"})
:dets.close(table4)

# Use convert_file to open, convert, and close in one step
{:ok, ApiConfig} = Dets.convert_file(file_path2, :api_config,
                                      module_name: :ApiConfig,
                                      close_after: true)

IO.puts("   ApiConfig.get(:api_key) => #{inspect ApiConfig.get(:api_key)}")
IO.puts("   ApiConfig.get(:endpoint) => #{inspect ApiConfig.get(:endpoint)}")

# Clean up
File.rm(file_path2)

# 5. DETS with bag type (multiple values per key)
IO.puts("\n5. DETS with bag type:")

{:ok, table5} = :dets.open_file(:bag_demo, [type: :bag])
:dets.insert(table5, {:tags, "elixir"})
:dets.insert(table5, {:tags, "erlang"})
:dets.insert(table5, {:tags, "otp"})
:dets.insert(table5, {:author, "developer"})

{:ok, BagDemo} = Dets.convert(:bag_demo)

IO.puts("   BagDemo.get(:tags) => #{inspect BagDemo.get(:tags)} (only first value)")
IO.puts("   BagDemo.all() => #{inspect BagDemo.all()} (all entries)")

:dets.close(table5)

# 6. Default values
IO.puts("\n6. Default values:")

{:ok, table6} = :dets.open_file(:defaults_demo, [type: :set])
:dets.insert(table6, {:exists, "I exist!"})

{:ok, DefaultsDemo} = Dets.convert(:defaults_demo)

IO.puts("   DefaultsDemo.get(:exists) => #{inspect DefaultsDemo.get(:exists)}")
IO.puts("   DefaultsDemo.get(:missing) => #{inspect DefaultsDemo.get(:missing)}")
IO.puts("   DefaultsDemo.get(:missing, \"default\") => #{inspect DefaultsDemo.get(:missing, "default")}")

:dets.close(table6)

IO.puts("\n=== Demo Complete ===")
IO.puts("Key benefits of DETS support:")
IO.puts("• Persistent storage - data survives application restarts")
IO.puts("• Same API as ETS/Maps conversion")
IO.puts("• Fast in-memory access after conversion")
IO.puts("• Useful for configuration, caching, and persistent lookups")