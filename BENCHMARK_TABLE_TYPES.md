# Exfoil Benchmark Results: ETS Table Types

## Overview

This document presents comprehensive benchmark results comparing Exfoil performance across different ETS table types: `:set`, `:ordered_set`, `:bag`, and `:duplicate_bag`.

## Test Environment

- **Platform**: macOS Darwin
- **Test Data**: 5,000-10,000 entries per table
- **Iterations**: 50,000-100,000 lookups per test
- **Key Types**: Atoms (`:key_1`, `:key_2`, etc.)
- **Value Types**: Maps with nested data

## Performance Results

### 1. Table Type Comparison

Testing with 5,000 entries and 50,000 lookups:

| Table Type | ETS Time | Exfoil Time | Speed Improvement | Memory Usage |
|------------|----------|-------------|-------------------|--------------|
| `:set` | 11.7 ms | 10.4 ms | **1.13x faster** | 325.9 KB |
| `:ordered_set` | 19.5 ms | 10.3 ms | **1.91x faster** | 313.6 KB |
| `:bag` | 12.6 ms | 10.5 ms | **1.19x faster** | 331.4 KB |
| `:duplicate_bag` | 13.1 ms | 10.9 ms | **1.20x faster** | 331.4 KB |

**Key Finding**: Exfoil provides consistent ~10ms lookup time regardless of table type, while ETS performance varies significantly.

### 2. Ordered Set Performance

`:ordered_set` tables show the best improvement with Exfoil:

- **ETS ordered_set**: Slower due to tree-based structure (19.5 ms)
- **Exfoil**: Converts to flat function clauses (10.3 ms)
- **Result**: Nearly 2x performance improvement

### 3. Duplicate Values Impact

Testing `:bag` and `:duplicate_bag` with varying duplicate ratios:

| Duplicates | Bag Performance | Duplicate Bag Performance |
|------------|-----------------|---------------------------|
| 0% | 1.19x faster | 1.18x faster |
| 10% | 1.23x faster | 1.20x faster |
| 50% | 1.24x faster | 1.13x faster |
| 100% | 1.19x faster | 1.24x faster |

**Key Finding**: Duplicate values have minimal impact on Exfoil performance.

### 4. Scaling with Table Size

Performance improvement across different table sizes (`:set` tables):

| Table Size | ETS Time | Exfoil Time | Improvement |
|------------|----------|-------------|-------------|
| 10 entries | 1.25 ms | 0.69 ms | 1.81x |
| 100 entries | 2.54 ms | 2.02 ms | 1.26x |
| 1,000 entries | 2.94 ms | 2.04 ms | 1.44x |
| 10,000 entries | 2.69 ms | 2.12 ms | 1.27x |

### 5. Memory Usage

Memory footprint comparison (with complex map values):

| Entries | :set | :ordered_set | :bag | :duplicate_bag |
|---------|------|--------------|------|----------------|
| 100 | 16.5 KB | 16.0 KB | 16.5 KB | 16.5 KB |
| 1,000 | 168.1 KB | 156.6 KB | 168.1 KB | 168.1 KB |
| 10,000 | 1.5 MB | 1.5 MB | 1.5 MB | 1.5 MB |

**Key Finding**: All table types use similar memory for the same data.

### 6. Edge Cases

#### Empty Tables
- All table types: ~0.15 ms for 10,000 failed lookups
- Exfoil's catch-all clause is highly optimized

#### Single Entry Tables
- Hit performance: ~0.15 ms for 10,000 lookups
- Miss performance: ~0.12 ms for 10,000 lookups
- Excellent discrimination between hits and misses

### 7. Named vs Unnamed Tables

| Table Type | Named Table | Unnamed Table (Reference) |
|------------|-------------|---------------------------|
| `:set` | 1.24x faster | 1.49x faster |
| `:ordered_set` | 2.22x faster | 3.07x faster |
| `:bag` | 1.29x faster | 1.62x faster |
| `:duplicate_bag` | 1.25x faster | 1.63x faster |

**Interesting**: Unnamed tables show even better improvement, possibly due to reference-based access patterns in ETS.

## Conclusions

### Performance Summary
- ✅ **Consistent Performance**: Exfoil provides ~10ms lookup time regardless of table type
- ✅ **Best Improvement**: `:ordered_set` tables benefit most (up to 3x faster)
- ✅ **Reliable Speedup**: All table types show 1.1x to 3x improvement
- ✅ **Duplicate Handling**: Performance remains stable even with duplicate values

### Memory Efficiency
- ✅ **Low Overhead**: Exfoil modules add minimal memory overhead
- ✅ **Similar Footprint**: All table types use comparable memory
- ✅ **Scalable**: Memory usage scales linearly with entries

### Use Case Recommendations

| Use Case | Recommended Table Type | Expected Improvement |
|----------|------------------------|---------------------|
| General purpose | `:set` | 1.2-1.5x |
| Ordered data | `:ordered_set` | 2-3x |
| Multi-value keys* | `:bag` | 1.2-1.6x |
| Duplicate entries* | `:duplicate_bag` | 1.2-1.6x |

*Note: Only first value accessible via Exfoil for multi-value keys

## Running the Benchmarks

To reproduce these results:

```bash
# Basic benchmark
mix run benchmark/ets_table_types_benchmark.exs

# Detailed benchmark with memory analysis
mix run benchmark/detailed_table_types_benchmark.exs

# All benchmarks
mix run benchmark/benchmark.exs
mix run benchmark/benchmark_maps.exs
```

## Technical Notes

1. **Function Clause Matching**: Exfoil generates one function clause per key-value pair
2. **Compile-time Optimization**: The BEAM VM optimizes pattern matching for function clauses
3. **O(1) Complexity**: Both ETS and Exfoil provide O(1) average case lookup
4. **Multi-value Limitation**: For `:bag` and `:duplicate_bag`, only the first value is returned due to Elixir's function clause matching behavior
5. **Memory Trade-off**: Exfoil trades memory (compiled module) for CPU performance

## See Also

- [Main Benchmark Results](BENCHMARK_RESULTS.md) - General Exfoil vs ETS comparison
- [Maps Benchmark Results](BENCHMARK_RESULTS_MAPS.md) - Exfoil.Maps performance analysis
- [README](README.md) - Usage and examples