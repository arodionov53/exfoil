# Exfoil vs ETS Performance Benchmark Results

Based on comprehensive benchmarking performed on macOS with Apple M1 Pro, here are the key performance comparisons between Exfoil function calls and ETS lookups.

## Test Environment

- **OS**: macOS
- **CPU**: Apple M1 Pro (10 cores)
- **Memory**: 32 GB
- **Elixir**: 1.17.2
- **Erlang**: 27.0
- **JIT**: Enabled

## Performance Results Summary

### Speed Comparison

| Dataset Size | Lookups | Exfoil Speed | ETS Speed | Exfoil Advantage |
|-------------|---------|-------------|-----------|------------------|
| 100 entries | 1,000 | 879.17K ips | 249.63K ips | **3.52x faster** |
| 1,000 entries | 10,000 | 45.08K ips | 17.12K ips | **2.63x faster** |
| 10,000 entries | 50,000 | 2.08K ips | 1.21K ips | **1.72x faster** |
| 1,000 complex | 10,000 | 42.79K ips | 13.16K ips | **3.25x faster** |

### Memory Usage Comparison

| Dataset | Exfoil Memory | ETS Memory | ETS Memory Usage |
|---------|---------------|------------|------------------|
| Small (100) | 0.0313 KB | 6.07 KB | **194x more memory** |
| Medium (1K) | 0.0313 KB | 69.12 KB | **2,212x more memory** |
| Large (10K) | 0.0313 KB | 701.44 KB | **22,446x more memory** |
| Complex (1K) | 0.0313 KB | 85.29 KB | **2,729x more memory** |

### Single Key Lookup Performance

For individual key lookups (1M operations):

| Method | Speed | Memory | Relative Performance |
|--------|-------|--------|---------------------|
| **Exfoil single call** | 26.72M ips | 0 B | **Best** |
| ETS single lookup | 16.37M ips | 72 B | 1.63x slower |
| ETS (value extraction) | 13.49M ips | 72 B | 1.98x slower |

## Key Findings

### ⚡ Speed Advantages of Exfoil

1. **Compile-time Optimization**: Exfoil generates direct function calls that are optimized at compile time
2. **No Hash Lookups**: Unlike ETS, no runtime hash table traversal is needed
3. **JIT Benefits**: Direct function calls benefit more from Erlang's JIT compilation
4. **Consistent Performance**: 1.7x to 3.5x faster across all dataset sizes

### 🧠 Memory Advantages of Exfoil

1. **Minimal Runtime Memory**: Exfoil uses almost no runtime memory (0.0313 KB)
2. **Data in Bytecode**: Data is stored as part of the compiled module
3. **No ETS Overhead**: Eliminates ETS table metadata and indexing structures
4. **Massive Memory Savings**: 194x to 22,446x less memory usage

### 📊 Performance Scaling

- **Small datasets (100 entries)**: Exfoil is 3.52x faster
- **Medium datasets (1,000 entries)**: Exfoil is 2.63x faster
- **Large datasets (10,000 entries)**: Exfoil is 1.72x faster
- **Complex data types**: Exfoil maintains 3.25x speed advantage

## When to Use Each Approach

### Use Exfoil When:
✅ **Static Data**: Configuration, lookup tables, constants
✅ **High Read Frequency**: Data accessed very frequently
✅ **Memory Constraints**: Need to minimize memory usage
✅ **Performance Critical**: Maximum speed is essential
✅ **Immutable Data**: Data doesn't change after initialization

### Use ETS When:
✅ **Dynamic Data**: Frequent insertions, updates, deletions
✅ **Large Datasets**: Very large datasets that would create huge modules
✅ **Concurrent Writes**: Multiple processes need write access
✅ **Process Isolation**: Need data to survive process crashes
✅ **Runtime Flexibility**: Schema or structure changes at runtime

## Architecture Trade-offs

### Exfoil Trade-offs
**Pros:**
- Significantly faster data access
- Minimal memory usage during runtime
- Compile-time optimizations
- Type-safe function calls

**Cons:**
- Data embedded in module bytecode (increases code size)
- Requires recompilation for data changes
- Not suitable for frequently changing data
- Limited to reasonable dataset sizes

### ETS Trade-offs
**Pros:**
- Dynamic insert/update/delete operations
- Handles very large datasets efficiently
- Process-independent data storage
- Built-in concurrency support

**Cons:**
- Higher memory usage due to indexing overhead
- Runtime hash table lookup costs
- Less cache-friendly memory access patterns
- Additional process coordination overhead

## Conclusion

**Exfoil provides 1.7x to 3.5x better performance and 200x to 22,000x better memory efficiency compared to ETS for read-heavy workloads with static data.**

The performance advantage comes from:
1. Compile-time function call optimization
2. Elimination of runtime hash table lookups
3. Better CPU cache utilization
4. JIT compilation benefits for direct function calls

Exfoil is ideal for configuration data, lookup tables, constants, and any frequently-accessed static data where maximum performance is desired.