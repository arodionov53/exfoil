# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Exfoil is an Elixir library that converts ETS (Erlang Term Storage) tables, DETS (disk-based) tables, and Elixir maps into dynamically generated modules with function calls. This provides compile-time optimized access to key-value data through direct function calls instead of hash table lookups.

The library consists of three main modules:
- `Exfoil` - Core ETS table conversion
- `Exfoil.Maps` - Map-to-module conversion
- `Exfoil.Dets` - DETS table conversion
- `Exfoil.Utils` - Shared utilities for module generation

## Development Commands

### Testing
```bash
mix test                    # Run all tests
mix test test/exfoil_test.exs               # Run core Exfoil tests
mix test test/exfoil/maps_test.exs          # Run Maps module tests
mix test test/exfoil/dets_test.exs          # Run DETS module tests
mix test test/exfoil/utils_test.exs         # Run Utils module tests
mix test test/ets_table_types_test.exs      # Run ETS table types tests
mix test test/unnamed_tables_test.exs       # Run unnamed tables tests
```

### Benchmarking
```bash
# ETS benchmarks
mix run benchmark/benchmark.exs              # Comprehensive ETS benchmark
mix run benchmark/simple_benchmark.exs       # Quick ETS benchmark

# Maps benchmarks
mix run benchmark/benchmark_maps.exs         # Comprehensive maps benchmark
mix run benchmark/simple_benchmark_maps.exs  # Quick maps benchmark
mix run benchmark/large_map_benchmark.exs    # Large-scale maps testing

# Table type benchmarks
mix run benchmark/ets_table_types_benchmark.exs
mix run benchmark/detailed_table_types_benchmark.exs
```

### Interactive Demos
```bash
mix run demo/demo.exs                   # ETS table conversion demo
mix run demo/demo_maps.exs              # Maps functionality demo
mix run demo/demo_dets.exs              # DETS table demo
mix run demo/real_world_example.exs     # Real-world API caching example
```

## Architecture

### Core Conversion Flow

All three modules (`Exfoil`, `Exfoil.Maps`, `Exfoil.Dets`) follow the same pattern:

1. **Input Validation** - Check if table/map exists and is accessible
2. **Name Normalization** - Convert module and function names to proper Elixir format using `Exfoil.Utils`
3. **Data Extraction** - Convert data source to list of `{key, value}` tuples
4. **Module Generation** - Use `Exfoil.Utils.create_module/5` to dynamically create module with AST

### Dynamic Module Generation

The heart of Exfoil is in `Exfoil.Utils.create_module/5` which:

- Generates function clauses for each key-value pair
- Creates both safe (`get/2`) and bang (`get!/1`) versions of lookup functions
- Adds helper functions (`keys/0`, `all/0`, `count/0`)
- Compiles and loads the module at runtime using `Code.eval_quoted/2`

### Generated Module API

Each generated module provides:
- `get(key, default \\ nil)` - Returns `{:ok, value}` or default value
- `get!(key)` - Returns value directly or raises `KeyError`
- `keys()` - Lists all available keys
- `all()` - Returns all key-value pairs
- `count()` - Returns number of entries

Map-generated modules additionally provide:
- `to_map()` - Returns original map
- `has_key?(key)` - Checks if key exists

### Name Normalization

`Exfoil.Utils` handles automatic name normalization:

**Module Names** (via `normalize_module_name/1`):
- `:person` → `:Person`
- `:user_profile` → `:UserProfile`
- `:UserData` → `:UserData` (preserved)

**Function Names** (via `normalize_function_name/1`):
- `:Lookup` → `:lookup`
- `:GetData` → `:getdata`
- `:_PrivateGet` → `:_privateget`

## Key Implementation Details

### ETS Table Support
- Supports both named tables (atoms) and unnamed tables (references)
- Works with all ETS table types (`:set`, `:ordered_set`, `:bag`, `:duplicate_bag`)
- For bag/duplicate_bag tables, `get/2` only returns first value; use `all/0` for complete data

### DETS Integration
- Reads all DETS data into memory during conversion
- Generated modules work entirely in memory with no disk I/O
- Provides `convert_file/3` convenience function for file handling

### Performance Characteristics
- 1.7x to 3.5x faster than ETS lookups
- 200x to 22,000x less memory usage during runtime
- 1.15x to 2.16x faster than Map.get/2 for medium/large maps
- Zero runtime hash table lookups (compile-time optimized function calls)

## Testing Strategy

The test suite covers:
- Basic conversion functionality for all data types
- Name normalization edge cases
- ETS table type compatibility (set, ordered_set, bag, duplicate_bag)
- Unnamed table handling
- DETS file operations
- Error handling for missing tables/files
- Module function API correctness

## File Organization

- `lib/exfoil.ex` - Core ETS conversion logic
- `lib/exfoil/maps.ex` - Map conversion functionality
- `lib/exfoil/dets.ex` - DETS conversion functionality
- `lib/exfoil/utils.ex` - Shared utilities and module generation
- `test/` - Comprehensive test suite organized by module
- `demo/` - Interactive demonstration scripts
- `benchmark/` - Performance testing scripts

## Development Notes

- All modules use the same underlying `Utils.create_module/5` for consistency
- AST generation happens at runtime using Elixir's `quote` and `unquote` macros
- Module compilation uses `Code.eval_quoted/2` to load generated modules
- The library preserves all Elixir data types through `Macro.escape/1`
- Generated modules are true Elixir modules with proper documentation
