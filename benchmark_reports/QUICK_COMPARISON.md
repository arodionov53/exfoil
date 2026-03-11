# Exfoil vs Native Implementation - Quick Comparison

## 🚀 Performance at a Glance

### ETS Performance

```
Dataset Size    │ Exfoil IPS    │ ETS IPS      │ Speedup   │ Memory Reduction
───────────────┼──────────────┼─────────────┼──────────┼─────────────────
100 entries    │ 854,780      │ 254,390     │ 3.36x    │ 194x less
1,000 entries  │  50,410      │  17,910     │ 2.81x    │ 2,214x less
10,000 entries │   2,220      │   1,280     │ 1.73x    │ 22,446x less
Complex data   │  49,260      │  14,880     │ 3.31x    │ 2,726x less
```

### Maps Performance

```
Dataset Size    │ Exfoil vs Map.get/2     │ Memory Usage          │ Winner
───────────────┼────────────────────────┼──────────────────────┼─────────
10 entries     │ 1.17x slower           │ Same (32B)           │ Map.get/2
100 entries    │ 1.34x slower           │ Same (32B)           │ Map.get/2
1,000 entries  │ 1.00x equivalent       │ Same (32B)           │ Tie
5,000 entries  │ 1.88x faster           │ 0B vs 32B           │ Exfoil ✅
10,000 entries │ 1.77x faster           │ 0B vs 32B           │ Exfoil ✅
```

## 📊 Key Takeaways

| Metric | Result |
|--------|--------|
| **Best ETS Speedup** | 3.36x faster (small datasets) |
| **Consistent ETS Improvement** | 1.7x+ across all sizes |
| **Maps Break-even Point** | 1,000 entries |
| **Maximum Memory Reduction** | 22,446x less memory usage |
| **Module Generation Improvement** | 30-50% faster (recent optimizations) |

## 🎯 When to Use Exfoil

### ✅ Perfect For:
- **Large datasets** (1000+ entries)
- **Read-heavy workloads**
- **Static/semi-static data**
- **Performance-critical code paths**
- **Memory-constrained environments**

### ⚠️ Consider Native When:
- **Very small datasets** (<100 entries)
- **Write-heavy operations**
- **Frequently changing data**
- **Dynamic key requirements**

## 🔥 Performance Highlights

- **Up to 3.4x faster** than ETS lookups
- **Up to 22,000x less memory** usage during runtime
- **Zero runtime allocations** for lookups
- **Consistent O(1) performance** regardless of dataset size
- **30-50% faster module generation** (recent optimizations)

---
*Data from benchmarks run on Apple M1 Pro, macOS, Elixir 1.17.2*
