# Exfoil Benchmark Reports

This directory contains comprehensive benchmark results for the Exfoil library, comparing performance against native ETS and Map implementations.

## Benchmark Files

### ETS Performance
- **`ets_comprehensive.txt`** - Detailed ETS vs Exfoil comparison across multiple dataset sizes
- **`ets_simple.txt`** - Quick ETS performance test
- **`ets_table_types.txt`** - Performance analysis across different ETS table types

### Maps Performance
- **`maps_comprehensive.txt`** - Detailed Maps vs Exfoil.Maps comparison
- **`maps_simple.txt`** - Quick Maps performance test
- **`maps_large.txt`** - Large-scale Maps performance analysis

### Performance Optimizations
- **`performance_optimizations.txt`** - Analysis of recent performance improvements

## System Specifications

**Platform**: macOS (Darwin 24.6.0)
**CPU**: Apple M1 Pro (10 cores)
**Memory**: 32 GB
**Elixir**: 1.17.2
**Erlang**: 27.0 (JIT enabled)

## Summary Results

### ETS Performance
- **Speed Improvement**: 1.7x to 3.4x faster than native ETS
- **Memory Efficiency**: 194x to 22,446x less memory usage
- **Best Case**: Small datasets (3.36x speedup)
- **Consistent Performance**: Maintains 1.7x+ improvement even at large scale

### Maps Performance
- **Small Maps (10-100)**: Comparable to Map.get/2 (~1.1-1.2x)
- **Medium Maps (1000)**: Equivalent performance to Map.get/2
- **Large Maps (5000+)**: 1.8x to 1.9x faster than Map.get/2
- **Extra Large (10k)**: Competitive with native maps (1.02x to 1.77x depending on access pattern)

### Table Type Performance
- **:set**: 1.14x faster, excellent consistency
- **:ordered_set**: 1.99x faster, best improvement
- **:bag**: 1.17x faster, handles duplicates well
- **:duplicate_bag**: 1.19x faster, maintains performance with true duplicates

### Performance Optimizations
- **Module Generation**: 30-50% faster overall
- **Key Optimizations**:
  - String.at/2 vs regex: 15-20% improvement
  - Code.compile_quoted: 15-30% faster compilation
  - Single-pass processing: 10-20% improvement
  - Direct phash2 hashing: 5-10% improvement

## Key Insights

1. **Scaling Advantage**: Performance improvements increase with dataset size
2. **Memory Efficiency**: Zero runtime memory allocations vs native implementations
3. **Consistent O(1)**: Predictable performance regardless of data size
4. **Table Type Agnostic**: Works well across all ETS table types
5. **Optimization Impact**: Recent improvements significantly reduced conversion time

## Best Use Cases

- Read-heavy workloads
- Static configuration data
- Lookup tables and caches
- API response caching
- Any scenario requiring predictable O(1) performance

---

*Generated on: 2026-03-11*
*Exfoil Version: 1.0.0*
