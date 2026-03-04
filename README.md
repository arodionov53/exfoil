# Exfoil

Exfoil is an Elixir library that converts ETS (Erlang Term Storage) table entries and Elixir maps into dynamically generated modules with function calls. This provides a fast, compile-time optimized way to access key-value data.

## Features

- **ETS to Module Conversion**: Convert any ETS table into a dynamically generated Elixir module
- **Map to Module Conversion**: Convert any Elixir map into a dynamically generated module
- **Fast Function Calls**: Access data through direct function calls instead of hash table lookups
- **Type Safety**: All data types are preserved (strings, lists, maps, tuples, etc.)
- **Flexible Configuration**: Custom module names and function names
- **Helper Functions**: Built-in functions to list keys, get all entries, and count items
- **Error Handling**: Graceful handling of missing keys and non-existent tables

## Examples

### ETS Table Conversion

**Note**: Only named ETS tables (created with `:named_table` option) can be converted. Table IDs from unnamed tables are not supported.

**Module Naming**: Exfoil automatically normalizes module names to proper PascalCase format. For example, `:person` becomes `Person`, `:user_profile` becomes `UserProfile`, etc.

```elixir
# Create and populate an ETS table
:ets.new(:tab1, [:named_table])
:ets.insert(:tab1, {:a, 1})
:ets.insert(:tab1, {:b, 2})

# Convert to a dynamic module
{:ok, module_name} = Exfoil.convert(:tab1)
# => {:ok, Tab1}

# Now you can call functions directly!
Tab1.get(:a)  # => {:ok, 1}
Tab1.get(:b)  # => {:ok, 2}
Tab1.get(:nonexistent)  # => nil
Tab1.get(:nonexistent, :default)  # => :default

# Or use the bang version for direct access
Tab1.get!(:a)  # => 1
Tab1.get!(:b)  # => 2
Tab1.get!(:nonexistent)  # => raises KeyError

# Helper functions
Tab1.keys()   # => [:a, :b]
Tab1.all()    # => [a: 1, b: 2]
Tab1.count()  # => 2
```

### Map Conversion

**Module Naming**: Module names are automatically normalized to PascalCase (e.g., `:person` → `Person`, `:user_data` → `UserData`).

```elixir
alias Exfoil.Maps

# Create a map
data = %{name: "Alice", age: 30, city: "San Francisco"}

# Convert to a dynamic module
{:ok, module_name} = Maps.convert(data, :Person)
# => {:ok, Person}

# Access data through function calls
Person.get(:name)  # => {:ok, "Alice"}
Person.get(:age)   # => {:ok, 30}
Person.get(:nonexistent)  # => nil
Person.get(:nonexistent, "not found")  # => "not found"

# Or use the bang version for direct access
Person.get!(:name)  # => "Alice"
Person.get!(:age)   # => 30
Person.get!(:nonexistent)  # => raises KeyError

# Helper functions
Person.keys()    # => [:name, :age, :city]
Person.count()   # => 3
Person.to_map()  # => %{name: "Alice", age: 30, city: "San Francisco"}
Person.has_key?(:name)  # => true
```

## Advanced Usage

### Different Data Types

Exfoil handles all Elixir data types:

```elixir
:ets.new(:complex_table, [:named_table])
:ets.insert(:complex_table, {:string, "hello"})
:ets.insert(:complex_table, {:list, [1, 2, 3]})
:ets.insert(:complex_table, {:map, %{key: "value"}})
:ets.insert(:complex_table, {:tuple, {:nested, :tuple}})

{:ok, ComplexTable} = Exfoil.convert(:complex_table)

ComplexTable.get(:string)  # => {:ok, "hello"}
ComplexTable.get(:map)     # => {:ok, %{key: "value"}}

# Bang versions for direct access
ComplexTable.get!(:string)  # => "hello"
ComplexTable.get!(:map)     # => %{key: "value"}
```

### Custom Configuration

You can customize the generated module name and function name:

```elixir
:ets.new(:config, [:named_table])
:ets.insert(:config, {:api_key, "secret"})

# Custom module and function names
{:ok, MyConfig} = Exfoil.convert(:config,
                                  module_name: :MyConfig,
                                  function_name: :lookup)

MyConfig.lookup(:api_key)   # => {:ok, "secret"}
MyConfig.lookup!(:api_key)  # => "secret"
```

### Error Handling

```elixir
# Non-existent table
{:error, :table_not_found} = Exfoil.convert(:missing_table)

# Unnamed table (without :named_table option)
table_id = :ets.new(:my_table, [:set])  # Creates table but not named
{:error, :table_not_found} = Exfoil.convert(:my_table)  # Fails - table not named

# Using convert! for exceptions
Exfoil.convert!(:missing_table)  # => raises RuntimeError
```

## Map Functionality

Exfoil also provides the same functionality for Elixir maps through the `Exfoil.Maps` module.

### Basic Map Conversion

```elixir
alias Exfoil.Maps

# Convert a simple map
user_data = %{username: "bob", role: :admin, active: true}
{:ok, UserModule} = Maps.convert(user_data, :UserModule)

UserModule.get(:username)  # => {:ok, "bob"}
UserModule.get(:role)      # => {:ok, :admin}

# Bang versions for direct access
UserModule.get!(:username)  # => "bob"
UserModule.get!(:role)      # => :admin
```

### Auto-Generated Module Names

```elixir
# Let Exfoil generate a unique module name
config = %{env: :dev, debug: true}
{:ok, module_name} = Exfoil.Maps.convert_with_auto_name(config)

module_name.get(:env)   # => {:ok, :dev}
module_name.get!(:env)  # => :dev
```

### Complex Data Types in Maps

```elixir
complex_data = %{
  config: %{database: "postgres", port: 5432},
  features: [:auth, :logging, :metrics],
  metadata: {:version, "1.2.3"}
}

{:ok, AppConfig} = Exfoil.Maps.convert(complex_data, :AppConfig)

AppConfig.get(:config)    # => {:ok, %{database: "postgres", port: 5432}}
AppConfig.get(:features)  # => {:ok, [:auth, :logging, :metrics]}

# Bang versions for direct access
AppConfig.get!(:config)    # => %{database: "postgres", port: 5432}
AppConfig.get!(:features)  # => [:auth, :logging, :metrics]
```

### Mixed Key Types

Maps support any key type that Elixir maps support:

```elixir
mixed_keys = %{
  :atom_key => "atom value",
  "string_key" => "string value",
  1 => "number key"
}

{:ok, MixedKeys} = Exfoil.Maps.convert(mixed_keys, :MixedKeys)

MixedKeys.get(:atom_key)     # => {:ok, "atom value"}
MixedKeys.get("string_key")  # => {:ok, "string value"}
MixedKeys.get(1)             # => {:ok, "number key"}

# Bang versions for direct access
MixedKeys.get!(:atom_key)     # => "atom value"
MixedKeys.get!("string_key")  # => "string value"
MixedKeys.get!(1)             # => "number key"
```

### Map-Specific Helper Functions

In addition to the standard helpers (`keys/0`, `all/0`, `count/0`), map-generated modules include:

```elixir
MyModule.to_map()          # Returns the original map
MyModule.has_key?(:key)    # Checks if key exists
```

## Module and Function Name Normalization

### Module Names

Exfoil automatically normalizes all module names to proper PascalCase format, regardless of how you specify them:

```elixir
# All of these create modules with proper PascalCase names

# ETS Examples
Exfoil.convert(:my_table, module_name: :person)        # => {:ok, Person}
Exfoil.convert(:my_table, module_name: :user_profile)  # => {:ok, UserProfile}
Exfoil.convert(:my_table, module_name: :UserData)      # => {:ok, UserData} (preserved)

# Maps Examples
Exfoil.Maps.convert(%{}, :person)        # => {:ok, Person}
Exfoil.Maps.convert(%{}, :user_profile)  # => {:ok, UserProfile}
Exfoil.Maps.convert(%{}, :UserData)      # => {:ok, UserData} (preserved)
```

**Module Normalization Rules:**
- Lowercase atoms (`:person`) are capitalized to PascalCase (`Person`)
- Underscore-separated atoms (`:user_profile`) are converted to PascalCase (`UserProfile`)
- Already proper PascalCase atoms (`:UserData`) are preserved as-is
- This ensures consistent module naming regardless of input format

### Function Names

Exfoil also automatically normalizes function names to follow Elixir's naming rules (must start with lowercase letter or underscore):

```elixir
# Function names are automatically normalized to lowercase

# ETS Examples
Exfoil.convert(:my_table, function_name: :Lookup)        # Function becomes `lookup`
Exfoil.convert(:my_table, function_name: :GetData)       # Function becomes `getdata`
Exfoil.convert(:my_table, function_name: :_PrivateGet)   # Function becomes `_privateget`

# Maps Examples
Exfoil.Maps.convert(%{}, :data, function_name: :Fetch)   # Function becomes `fetch`
Exfoil.Maps.convert(%{}, :data, function_name: :fetch)   # Function stays `fetch`
```

**Function Normalization Rules:**
- Uppercase starting letters are converted to lowercase (`:Lookup` → `:lookup`)
- Mixed case names are fully lowercased (`:GetData` → `:getdata`)
- Underscore prefixes are preserved (`:_PrivateGet` → `:_privateget`)
- Already valid function names are kept as-is (`:fetch` → `:fetch`)
- This prevents syntax errors when calling generated functions

## API Reference

### `Exfoil.convert/2`

Converts an ETS table to a dynamic module.

**Parameters:**
- `table_name` (atom) - Name of the ETS table (must be a named table created with `:named_table` option)
- `opts` (keyword list) - Optional configuration
  - `:module_name` - Custom module name (defaults to capitalized table name)
  - `:function_name` - Custom function name (defaults to `:get`)

**Returns:**
- `{:ok, module_name}` on success
- `{:error, :table_not_found}` if table doesn't exist

### `Exfoil.convert!/2`

Same as `convert/2` but raises an exception on error. Requires named ETS tables only.

### Generated Module Functions

Each generated module includes:

- `get/2` (or custom function name) - Retrieve value by key with optional default. Returns `{:ok, value}` for existing keys or the default value (defaults to `nil`) for missing keys. Similar to `Map.get/3`
- `get!/1` (or custom function name with `!`) - Retrieve value by key directly, returns `value` or raises `KeyError`
- `keys/0` - List all available keys
- `all/0` - Get all key-value pairs
- `count/0` - Count of entries

### Maps API

#### `Exfoil.Maps.convert/3`

Converts a map to a dynamic module.

**Parameters:**
- `map` (map) - The map to convert
- `module_name` (atom) - Name for the generated module
- `opts` (keyword list) - Optional configuration
  - `:function_name` - Custom function name (defaults to `:get`)

**Returns:**
- `{:ok, module_name}` on success

#### `Exfoil.Maps.convert!/3`

Same as `convert/3` but raises an exception on error.

#### `Exfoil.Maps.convert_with_auto_name/2`

Converts a map with an automatically generated unique module name.

**Parameters:**
- `map` (map) - The map to convert
- `opts` (keyword list) - Optional configuration

**Returns:**
- `{:ok, module_name}` with auto-generated module name

### Map-Generated Module Functions

Each map-generated module includes all the standard functions plus:

- `to_map/0` - Returns the original map
- `has_key?/1` - Checks if a key exists

## Installation

Add `exfoil` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exfoil, "~> 0.1.0"}
  ]
end
```

## Quick Start

After installation, try the interactive demos to see Exfoil in action:

```bash
# Get dependencies
mix deps.get

# Try the maps demo (easiest to start with)
mix run demo/demo_maps.exs

# See a real-world API caching example
mix run demo/real_world_example.exs

# Run performance benchmarks
mix run benchmark/simple_benchmark_maps.exs
```

## Use Cases

- **Configuration Management**: Convert config tables or maps to modules for fast access
- **Lookup Tables**: Transform static data into optimized function calls
- **Caching**: Convert cached data to modules for improved performance
- **Data Migration**: Move from ETS-based or map-based to function-based data access
- **Static Data**: Convert compile-time known maps into optimized function calls
- **API Responses**: Transform structured API responses into queryable modules

## Performance

Exfoil provides significant performance advantages over ETS for read-heavy workloads:

- **1.7x to 3.5x faster** than ETS lookups
- **200x to 22,000x less memory usage** during runtime
- **Compile-time optimized** function calls
- **Zero runtime hash table lookups**

Exfoil.Maps provides similar benefits for map-based data:

- **1.15x to 2.16x faster** than regular map access for medium/large maps
- **Zero memory allocation** during access operations
- **Consistent O(1) performance** regardless of map size

### Running Benchmarks

Run the included benchmarks to see the performance differences:

```bash
# ETS Benchmarks
mix run benchmark/benchmark.exs        # Comprehensive ETS benchmark
mix run benchmark/simple_benchmark.exs # Quick ETS benchmark

# Maps Benchmarks
mix run benchmark/benchmark_maps.exs         # Comprehensive maps benchmark
mix run benchmark/simple_benchmark_maps.exs  # Quick maps benchmark
mix run benchmark/large_map_benchmark.exs    # Large-scale maps testing
```

**Sample Results** (1,000 entries, Apple M1 Pro):
- **ETS**: Exfoil 3.04x faster than ETS lookups
- **Maps**: Exfoil.Maps 1.15x-2.16x faster than Map.get/2

See `BENCHMARK_RESULTS.md` and `BENCHMARK_RESULTS_MAPS.md` for detailed performance analysis.

## Demos and Examples

### Running Interactive Demos

Explore Exfoil functionality with the included demos:

```bash
# ETS Table Demos
mix run demo/demo.exs                   # Original ETS table conversion demo

# Maps Demos
mix run demo/demo_maps.exs              # Interactive maps functionality demo
mix run demo/real_world_example.exs     # Real-world API caching example
```

### Demo Features

The demos showcase:

- **Basic conversion** - Simple ETS tables and maps to modules
- **Complex data types** - Nested structures, mixed types
- **Custom configurations** - Module names, function names
- **Utility functions** - keys(), count(), all(), etc.
- **Performance comparisons** - Live benchmarking
- **Real-world scenarios** - API response caching, user data

### Quick Start

```bash
# Try the maps demo - no ETS setup required
mix run demo/demo_maps.exs

# See a practical use case with 2000 user records
mix run demo/real_world_example.exs
```

## License

This project is licensed under the same license as Elixir.

