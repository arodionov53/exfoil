# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Exfoil is an Elixir library that converts ETS (Erlang Term Storage) tables, DETS (disk-based) tables, and Elixir maps into dynamically generated modules with function calls. This provides compile-time optimized access to key-value data through direct function calls instead of hash table lookups.

**Inspiration**: Exfoil is inspired by the original [foil](https://github.com/lpgauth/foil) library for Erlang by Luis Gonzalez, extending the concept with native Elixir features, Maps support, DETS integration, and enhanced performance optimizations.

The library consists of four main modules:
- `Exfoil` - Core ETS table conversion
- `Exfoil.Maps` - Map-to-module conversion
- `Exfoil.Dets` - DETS table conversion
- `Exfoil.Utils` - Shared utilities for module generation

## Development Commands

### Testing
```bash
mix test                                     # Run all tests (84 total tests)
mix test test/exfoil_test.exs               # Run core Exfoil tests
mix test test/exfoil/maps_test.exs          # Run Maps module tests
mix test test/exfoil/dets_test.exs          # Run DETS module tests
mix test test/exfoil/utils_test.exs         # Run Utils module tests
mix test test/ets_table_types_test.exs      # Run ETS table types tests
mix test test/unnamed_tables_test.exs       # Run unnamed tables tests
```

### Benchmarking
```bash
# ETS benchmarks (all working correctly)
mix run benchmark/benchmark.exs              # Comprehensive ETS benchmark
mix run benchmark/simple_benchmark.exs       # Quick ETS benchmark

# Maps benchmarks
mix run benchmark/benchmark_maps.exs         # Comprehensive maps benchmark
mix run benchmark/simple_benchmark_maps.exs  # Quick maps benchmark
mix run benchmark/large_map_benchmark.exs    # Large-scale maps testing

# Table type and performance benchmarks
mix run benchmark/ets_table_types_benchmark.exs
mix run benchmark/detailed_table_types_benchmark.exs
mix run benchmark/performance_comparison.exs  # Optimization impact analysis
```

### Benchmark Reports
Updated benchmark reports are available in `benchmark_reports/`:
- `PERFORMANCE_SUMMARY.md` - Comprehensive performance analysis
- `QUICK_COMPARISON.md` - At-a-glance performance metrics
- Individual `.txt` files with detailed benchmark data

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
4. **Module Generation** - Use `Exfoil.Utils.create_module/4` to dynamically create module with AST

### Dynamic Module Generation

The heart of Exfoil is in `Exfoil.Utils.create_module/4` which:

- Generates function clauses for each key-value pair using optimized single-pass processing
- Creates Map API compatible functions (`fetch/1`, `fetch!/1`, `get/2`)
- Adds helper functions (`keys/0`, `all/0`, `count/0`)
- Compiles and loads the module at runtime using `Code.compile_quoted/2` (optimized)

### Generated Module API

Each generated module provides **Map API compatible functions**:
- `fetch(key)` - Returns `{:ok, value}` or `:error` (Map API compatible)
- `fetch!(key)` - Returns value directly or raises `KeyError` (Map API compatible)
- `get(key, default \\ nil)` - Returns value or default (Map API compatible)
- `keys()` - Lists all available keys
- `all()` - Returns all key-value pairs
- `count()` - Returns number of entries

Map-generated modules additionally provide:
- `to_map()` - Returns original map
- `has_key?(key)` - Checks if key exists
- `values()` - Returns all values

### Name Normalization

`Exfoil.Utils` handles automatic name normalization:

**Module Names** (via `normalize_module_name/1`):
- `:person` → `:Person`
- `:user_profile` → `:UserProfile`
- `:UserData` → `:UserData` (preserved)

## Key Implementation Details

### ETS Table Support
- Supports both named tables (atoms) and unnamed tables (references)
- Works with all ETS table types (`:set`, `:ordered_set`, `:bag`, `:duplicate_bag`)
- For bag/duplicate_bag tables, `fetch/1` and `get/2` only return first value; use `all/0` for complete data

### DETS Integration
- Reads all DETS data into memory during conversion
- Generated modules work entirely in memory with no disk I/O
- Provides `convert_file/3` convenience function for file handling

### Performance Characteristics (Updated)
- **ETS**: 1.7x to 3.5x faster than ETS lookups
- **Maps**: 1.0x to 2.0x faster than Map.get/2 for large maps
- **Memory**: Up to 22,435x less memory usage during runtime
- **Single Key Performance**: 27.5M ops/sec (fetch!/1) vs 17.4M ops/sec (ETS)
- **Zero runtime hash table lookups** (compile-time optimized function calls)

### Recent Performance Optimizations
- String.at/2 instead of regex for 15-20% faster name normalization
- Code.compile_quoted instead of Code.eval_quoted for 15-30% faster compilation
- Single-pass entry processing for 10-20% faster clause generation
- Direct phash2 hashing for 5-10% faster map name generation
- **Overall**: 30-50% faster module generation

## API Evolution and Breaking Changes

### Version 1.0.0 Breaking Changes
- **Removed**: Custom `function_name` option (was never properly implemented)
- **Standardized**: All modules now use consistent Map API
- **Added**: Proper `fetch!/1` function (previously some benchmarks incorrectly used `get!/1`)

### Current API Functions
The correct generated module functions are:
- `fetch/1` - Returns `{:ok, value}` or `:error`
- `fetch!/1` - Returns value or raises `KeyError`
- `get/2` - Returns value or default with optional default argument

**Note**: There is no `get!/1` function. Use `fetch!/1` for bang-style access.

## Testing Strategy

The test suite covers:
- Basic conversion functionality for all data types (84 tests total)
- Name normalization edge cases
- ETS table type compatibility (set, ordered_set, bag, duplicate_bag)
- Unnamed table handling
- DETS file operations
- Error handling for missing tables/files
- Module function API correctness
- All tests are passing ✅

## Benchmark Status

All benchmarks have been **fixed and updated**:
- ✅ **Fixed**: Replaced incorrect `get!/1` calls with `fetch!/1`
- ✅ **Updated**: All benchmark reports with corrected performance data
- ✅ **Verified**: All benchmarks run without errors
- ✅ **Enhanced**: Added comprehensive performance analysis

## File Organization

### Core Library
- `lib/exfoil.ex` - Core ETS conversion logic
- `lib/exfoil/maps.ex` - Map conversion functionality
- `lib/exfoil/dets.ex` - DETS conversion functionality
- `lib/exfoil/utils.ex` - Shared utilities and module generation

### Testing and Validation
- `test/` - Comprehensive test suite organized by module (84 tests)
- `demo/` - Interactive demonstration scripts
- `benchmark/` - Performance testing scripts (all working)
- `benchmark_reports/` - Updated performance reports and analysis

### Documentation
- `README.md` - Comprehensive usage guide with foil comparison
- `CLAUDE.md` - This development guide
- `mix.exs` - Project configuration (version 1.0.0)

## Development Notes

### Implementation Details
- All modules use the same underlying `Utils.create_module/4` for consistency
- AST generation happens at runtime using Elixir's `quote` and `unquote` macros
- Module compilation uses `Code.compile_quoted/2` for optimal performance
- The library preserves all Elixir data types through `Macro.escape/1`
- Generated modules are true Elixir modules with proper documentation

### Code Quality
- Follows Elixir conventions and best practices
- Comprehensive test coverage (84 tests)
- Performance optimized with single-pass processing
- Memory efficient with zero runtime allocations
- Map API compatibility for familiar developer experience

### Known Limitations
- Large datasets (>10k entries) show warnings but work correctly
- Multi-value tables (`:bag`, `:duplicate_bag`) only return first value via accessors
- Generated modules are loaded at runtime (not compile-time available)

## Comparison with Original Foil

Exfoil extends the original Erlang foil concept with:
- **Multi-format Support**: ETS + DETS + Maps (vs ETS only)
- **Elixir Integration**: Map API compatibility, idiomatic error handling
- **Enhanced Performance**: 30-50% faster module generation, better memory efficiency
- **Extended Features**: Unnamed tables, automatic naming, persistence support
- **Better Developer Experience**: Comprehensive documentation, demos, benchmarks

## Current Status

- **Version**: 1.0.0
- **Tests**: ✅ 84/84 passing
- **Benchmarks**: ✅ All working and updated
- **Documentation**: ✅ Complete with performance data
- **API**: ✅ Stable and Map-compatible
- **Performance**: ✅ Optimized and verified