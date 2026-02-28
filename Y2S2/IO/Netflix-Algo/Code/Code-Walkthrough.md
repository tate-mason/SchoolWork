# Code Walkthrough: `consumer_simulation.py`

This document explains what every section of the simulation does, the specific Python/NumPy syntax used, and links to relevant documentation.

---

## Imports

```python
import numpy as np
import pandas as pd
```

- `numpy` ([docs](https://numpy.org/doc/stable/)) is the core numerical library. Almost every array operation — drawing random numbers, matrix math, boolean indexing — comes from here.
- `pandas` ([docs](https://pandas.pydata.org/docs/)) is used only at the end to package results into a tidy table and save to CSV.

---

## Section 0 — Random Seed

```python
np.random.seed(42)
```

[`np.random.seed`](https://numpy.org/doc/stable/reference/random/generated/numpy.random.seed.html) fixes the random number generator so the simulation produces identical results every time you run it. Change the number to get a different but reproducible draw. Remove it entirely to get fresh randomness each run.

---

## Section 1 — Parameters

```python
J = 20
I = 1000
T = 100
alpha    = -2.15
beta_bar =  0.8
...
```

Plain Python integers and floats. Nothing special syntactically — this section just exists so all tunable numbers live in one place rather than being scattered through the code. The uppercase names like `EXIT_THRESHOLD` and `K_MAX` follow the Python convention ([PEP 8](https://peps.python.org/pep-0008/#constants)) of writing module-level constants in `ALL_CAPS`.

---

## Section 2 — Fixed Consumer Heterogeneity

```python
beta_i = np.random.normal(loc=beta_bar, scale=sigma_beta, size=I)
```

[`np.random.normal`](https://numpy.org/doc/stable/reference/random/generated/numpy.random.normal.html) draws `I=1000` values from a Normal distribution with mean `beta_bar` and standard deviation `sigma_beta`. The result is a 1D array of shape `(1000,)` — one taste parameter per consumer. This is drawn **once** and never changes: `beta_i[i]` is consumer `i`'s personal preference for quality for the entire simulation.

The `print` uses an **f-string** ([docs](https://docs.python.org/3/tutorial/inputoutput.html#formatted-string-literals)):
```python
print(f"beta_i: mean={beta_i.mean():.3f}, std={beta_i.std():.3f}")
```
The `:.3f` format specifier means "show 3 decimal places as a float". `.mean()` and `.std()` are NumPy array methods ([docs](https://numpy.org/doc/stable/reference/generated/numpy.ndarray.mean.html)).

---

## Section 3 — Fixed Product Qualities

```python
x_j = np.random.normal(loc=mu_x, scale=sigma_x, size=J)
```

Same draw as above but shape `(20,)` — one quality value per product. Crucially this is drawn **once** and never touched again. Products live at fixed points in quality space for all 100 periods.

```python
print(f"Products sorted by quality: {np.sort(x_j).round(2)}")
```

[`np.sort`](https://numpy.org/doc/stable/reference/generated/numpy.sort.html) returns a sorted copy (does not modify `x_j`). `.round(2)` ([docs](https://numpy.org/doc/stable/reference/generated/numpy.ndarray.round.html)) rounds each element to 2 decimal places for cleaner printing.

---

## Section 4 — Mean Utility

```python
delta_j = alpha + beta_bar * x_j
```

Pure NumPy **broadcasting** ([docs](https://numpy.org/doc/stable/user/basics.broadcasting.html)): `alpha` and `beta_bar` are scalars, `x_j` is shape `(20,)`. NumPy applies the scalar operations element-wise across the array, producing `delta_j` of shape `(20,)`. This is the mean utility of each product — the same every period since `x_j` is fixed.

---

## Section 5 — Initialise State Variables

This section sets up all the arrays that track what happens over time.

```python
choices = np.full((I, T), fill_value=-1, dtype=int)
```

[`np.full`](https://numpy.org/doc/stable/reference/generated/numpy.full.html) creates a 2D array of shape `(1000, 100)` pre-filled with `-1`. We use `-1` as a sentinel meaning "this consumer was exited this period". `dtype=int` ensures integer storage.

```python
shares = np.zeros((T, J + 1))
```

[`np.zeros`](https://numpy.org/doc/stable/reference/generated/numpy.zeros.html) creates a `(100, 21)` array of floats initialised to zero. Column 0 will hold the outside option share; columns 1–20 hold product shares.

```python
is_exited = np.zeros(I, dtype=bool)
```

A boolean array of shape `(1000,)` — one `True/False` per consumer. `dtype=bool` ([docs](https://numpy.org/doc/stable/reference/arrays.scalars.html#numpy.bool_)) means each element is a boolean rather than a float. This is used as a **boolean mask** throughout the loop.

```python
history_buffer = np.full((I, CLUSTER_WINDOW), fill_value=np.nan)
```

A `(1000, 10)` float array initialised with `np.nan` ([docs](https://numpy.org/doc/stable/reference/constants.html#numpy.nan)). This is the **circular buffer** storing each consumer's last 10 chosen quality values. `nan` marks slots that haven't been written yet.

---

## Section 6 — Main Simulation Loop

```python
for t in range(T):
```

A standard Python `for` loop ([docs](https://docs.python.org/3/tutorial/controlflow.html#for-statements)) running from `t=0` to `t=99`. Everything inside runs once per period.

### 6a — Re-entry Check

```python
exited_mask = is_exited.copy()
```

[`.copy()`](https://numpy.org/doc/stable/reference/generated/numpy.ndarray.copy.html) makes a snapshot of `is_exited` at the start of the period. We work from the snapshot so that consumers who re-enter this period don't immediately participate in the same period's choice — they come back next period.

```python
if exited_mask.any():
    exited_idx = np.where(exited_mask)[0]
```

[`.any()`](https://numpy.org/doc/stable/reference/generated/numpy.ndarray.any.html) returns `True` if at least one element is `True` — skips the block if nobody is exited. [`np.where(condition)`](https://numpy.org/doc/stable/reference/generated/numpy.where.html) with a single argument returns a tuple of arrays of indices where the condition is `True`. The `[0]` extracts the first (and only) element of that tuple, giving us a 1D array of indices.

```python
p_reentry = 1 - np.exp(-lambda_reentry * k)
```

[`np.exp`](https://numpy.org/doc/stable/reference/generated/numpy.exp.html) applies the exponential function element-wise to the array `k`. This computes the re-entry probability for each exited consumer: a value between 0 and 1 that increases the longer they've been out.

```python
did_reenter = np.random.uniform(size=len(exited_idx)) < p_reentry
```

[`np.random.uniform`](https://numpy.org/doc/stable/reference/random/generated/numpy.random.uniform.html) draws one uniform random number per exited consumer. Comparing with `<` produces a boolean array — `True` where the draw fell below the re-entry probability. This is the standard way to simulate a Bernoulli trial in NumPy.

```python
reentry_idx = exited_idx[did_reenter]
```

**Boolean indexing** ([docs](https://numpy.org/doc/stable/user/basics.indexing.html#boolean-array-indexing)): using a boolean array `did_reenter` to select only the elements of `exited_idx` where the condition is `True`. Returns a new array containing just the indices of consumers who re-enter.

```python
periods_exited[still_out] += 1
```

**Fancy indexing** ([docs](https://numpy.org/doc/stable/user/basics.indexing.html#advanced-indexing)): using an integer array `still_out` as an index to increment only those specific elements of `periods_exited` by 1.

### 6b — Who Is Active?

```python
active_mask = ~is_exited
active_idx  = np.where(active_mask)[0]
```

The `~` operator ([docs](https://numpy.org/doc/stable/reference/generated/numpy.invert.html)) is bitwise NOT on a boolean array — it flips every `True` to `False` and vice versa. So `active_mask` is `True` for consumers who are **not** exited. `np.where` then gives us their indices.

```python
if n_active == 0:
    continue
```

`continue` ([docs](https://docs.python.org/3/reference/simple_stmts.html#continue)) skips the rest of the current loop iteration and jumps to the next value of `t`. Used as a safety guard if somehow all consumers have exited.

### 6c — Compute K_t

```python
K_t = max(K_MIN, K_MAX - t // K_DECAY_EVERY)
```

`//` is Python's **floor division** ([docs](https://docs.python.org/3/reference/expressions.html#binary-arithmetic-operations)) — it divides and rounds down to the nearest integer. So `t // 10` gives 0 for t=0–9, 1 for t=10–19, etc. The built-in `max` keeps `K_t` from falling below `K_MIN`.

### 6d — Cluster Consumers

```python
for pos, i in enumerate(active_idx):
    if history_count[i] > 0:
        valid = history_buffer[i, :history_count[i]]
        rolling_avg[pos] = valid.mean()
```

[`enumerate`](https://docs.python.org/3/library/functions.html#enumerate) gives both the position `pos` (0, 1, 2, …) within `active_idx` and the actual consumer index `i`. The slice `history_buffer[i, :history_count[i]]` ([docs](https://numpy.org/doc/stable/user/basics.indexing.html#slicing-and-striding)) takes only the valid (non-nan) entries from that consumer's circular buffer.

```python
order   = np.argsort(signals)
buckets = np.array_split(order, N_CLUSTERS)
```

[`np.argsort`](https://numpy.org/doc/stable/reference/generated/numpy.argsort.html) returns the **indices** that would sort the array — so `signals[order]` would be sorted ascending. [`np.array_split`](https://numpy.org/doc/stable/reference/generated/numpy.array_split.html) divides an array into N roughly equal sub-arrays. Together these implement 1D quantile bucketing: sort consumers by taste signal, split into equal groups.

```python
centroids = np.array([signals[b].mean() for b in buckets])
```

A **list comprehension** ([docs](https://docs.python.org/3/tutorial/datastructures.html#list-comprehensions)) that loops over each bucket `b`, computes the mean of the taste signals in that bucket, and collects results into a list. `np.array(...)` converts the list to a NumPy array.

### 6e — Build Visible Product Sets

```python
visible_mask = np.ones((n_active, J), dtype=bool)
```

[`np.ones`](https://numpy.org/doc/stable/reference/generated/numpy.ones.html) with `dtype=bool` creates a 2D boolean array of all `True` — everyone can see all products by default. We then selectively set rows to `False` for the filtered products.

```python
dist = np.abs(x_j[np.newaxis, :] - centroids[:, np.newaxis])
```

This is the key broadcasting line for computing distances. `x_j` has shape `(J,)` and `centroids` has shape `(N_CLUSTERS,)`. Adding axes with [`np.newaxis`](https://numpy.org/doc/stable/reference/constants.html#numpy.newaxis) (equivalent to `None`) reshapes them:
- `x_j[np.newaxis, :]` → shape `(1, J)`
- `centroids[:, np.newaxis]` → shape `(N_CLUSTERS, 1)`

NumPy broadcasts these to `(N_CLUSTERS, J)`, computing every pairwise distance in one line. [`np.abs`](https://numpy.org/doc/stable/reference/generated/numpy.absolute.html) takes the absolute value element-wise.

```python
closest_K = np.argsort(dist[c])[:K_t]
```

`np.argsort(dist[c])` sorts product indices by distance from centroid `c`. `[:K_t]` slices the first `K_t` — the closest products. This is standard NumPy **slice indexing** ([docs](https://numpy.org/doc/stable/user/basics.indexing.html#slicing-and-striding)).

```python
in_cluster = cluster_labels == c
visible_mask[in_cluster] = cluster_visible
```

`cluster_labels == c` creates a boolean array, `True` for consumers in cluster `c`. Using it to index `visible_mask` sets all those rows at once to `cluster_visible` — this is broadcasting assignment via boolean indexing.

### 6f — Draw Time-Varying Shocks

```python
nu_it = -np.log(-np.log(np.random.uniform(size=n_active).reshape(-1)))
```

The **inverse CDF transform** for Type I Extreme Value (Gumbel) distribution ([Wikipedia](https://en.wikipedia.org/wiki/Gumbel_distribution#Quantile_function_and_generating_gumbel_variates)): if `U ~ Uniform(0,1)` then `-log(-log(U))` is T1EV distributed. [`np.log`](https://numpy.org/doc/stable/reference/generated/numpy.log.html) applies natural log element-wise.

`.reshape(-1)` ([docs](https://numpy.org/doc/stable/reference/generated/numpy.reshape.html)) forces the result to be a 1D array of shape `(n_active,)`. The `-1` means "infer this dimension from the total size". This prevents a NumPy edge case where a 1-element array collapses to a 0-dimensional scalar, which would break the `[:, np.newaxis]` operations later.

### 6g — Variety Term

```python
avg_past = np.where(
    has_full,
    np.divide(sum_past_x[active_idx], count_past[active_idx],
              where=has_full, out=np.zeros(n_active)),
    0.0
)
```

[`np.where(condition, x, y)`](https://numpy.org/doc/stable/reference/generated/numpy.where.html) with three arguments works element-wise: returns `x[i]` where `condition[i]` is `True`, else `y[i]`. [`np.divide`](https://numpy.org/doc/stable/reference/generated/numpy.divide.html) with `where=` and `out=` computes division only where the condition is `True`, leaving the `out` array's value (zero) elsewhere — this safely avoids divide-by-zero for consumers with no history.

```python
variety_term = x_j[np.newaxis, :] - avg_past[:, np.newaxis]
```

Another broadcasting operation. `x_j[np.newaxis, :]` is `(1, J)`, `avg_past[:, np.newaxis]` is `(n_active, 1)`. Broadcasting produces `(n_active, J)` where entry `[i, j]` = `x_j[j] - avg_past[i]`.

### 6h — Compute Utility

```python
mu_ijt = (beta_i[active_idx].reshape(-1)[:, np.newaxis] * x_j[np.newaxis, :]
          + gamma_it[:, np.newaxis] * variety_term
          - nu_it[:, np.newaxis])
```

All terms broadcast to shape `(n_active, J)`:
- `beta_i[active_idx].reshape(-1)[:, np.newaxis]` → `(n_active, 1)` × `(1, J)` = `(n_active, J)`
- `gamma_it[:, np.newaxis]` → `(n_active, 1)` × `(n_active, J)` = `(n_active, J)`
- `nu_it[:, np.newaxis]` → `(n_active, 1)` subtracted from each of the J columns

### 6i — Apply Hard Filter

```python
U_ijt[~visible_mask] = -np.inf
```

**Boolean mask assignment**: sets all elements of `U_ijt` where `visible_mask` is `False` to negative infinity. When we take `argmax` later, `-inf` entries can never win — effectively removing those products from the choice set. [`np.inf`](https://numpy.org/doc/stable/reference/constants.html#numpy.inf) is NumPy's infinity constant.

### 6j — Add Outside Option and Choose

```python
U_full = np.hstack([np.zeros((n_active, 1)), U_ijt])
```

[`np.hstack`](https://numpy.org/doc/stable/reference/generated/numpy.hstack.html) (horizontal stack) concatenates arrays along columns. We prepend a column of zeros — the outside option's utility — so the final matrix has shape `(n_active, J+1)`.

```python
chosen = np.argmax(U_full, axis=1)
```

[`np.argmax`](https://numpy.org/doc/stable/reference/generated/numpy.argmax.html) returns the index of the maximum value. `axis=1` means "find the max across columns for each row" — giving one chosen product index per consumer. Result shape: `(n_active,)`.

### 6k — Market Shares

```python
for j in range(J + 1):
    shares[t, j] = np.mean(chosen == j)
```

`chosen == j` creates a boolean array, `True` where consumer chose product `j`. [`np.mean`](https://numpy.org/doc/stable/reference/generated/numpy.mean.html) on a boolean array returns the fraction of `True` values — which is exactly the market share.

### 6l — Update Outside Counter

```python
consecutive_outside[active_idx[chose_outside]] += 1
consecutive_outside[active_idx[chose_product]]  = 0
```

`chose_outside` and `chose_product` are boolean arrays indexing into `active_idx`, which then indexes into `consecutive_outside`. The first line increments the counter for consumers who chose outside; the second resets it to zero for consumers who chose a product. Both use fancy indexing to update only the relevant subset.

### 6m — New Exits

```python
hit_thresh       = consecutive_outside[active_idx].reshape(-1) >= EXIT_THRESHOLD
new_exit_indices = active_idx[hit_thresh]
```

`>= EXIT_THRESHOLD` ([docs](https://numpy.org/doc/stable/reference/generated/numpy.greater_equal.html)) is a comparison operator applied element-wise, returning a boolean array. `.reshape(-1)` again guards against the scalar edge case when `n_active=1`.

### 6n — Update History

```python
for pos, i in enumerate(product_choosers):
    ptr = history_ptr[i]
    history_buffer[i, ptr] = quality_chosen[pos]
    history_ptr[i]         = (ptr + 1) % CLUSTER_WINDOW
    history_count[i]       = min(history_count[i] + 1, CLUSTER_WINDOW)
```

This is the **circular buffer** update. `ptr` is the next write position. After writing, `(ptr + 1) % CLUSTER_WINDOW` ([docs](https://docs.python.org/3/reference/expressions.html#binary-arithmetic-operations)) wraps back to 0 when it reaches the end — so old entries get overwritten by new ones. `min(..., CLUSTER_WINDOW)` caps `history_count` at the window size.

### 6o — Print Summary

```python
if t % 10 == 0:
```

`%` is the **modulo operator** ([docs](https://docs.python.org/3/reference/expressions.html#binary-arithmetic-operations)) — returns the remainder after division. `t % 10 == 0` is `True` when `t` is a multiple of 10, so this prints every 10 periods.

---

## Section 7 — Condensation Diagnostics

```python
row_sums = product_shares.sum(axis=1, keepdims=True)
ps_norm  = product_shares / row_sums
```

[`.sum(axis=1)`](https://numpy.org/doc/stable/reference/generated/numpy.sum.html) sums across columns (products) for each row (period). `keepdims=True` preserves the 2D shape `(T, 1)` instead of collapsing to `(T,)` — this is necessary so the division broadcasts correctly against `(T, J)`.

```python
HHI = (ps_norm ** 2).sum(axis=1)
```

`** 2` squares every element ([docs](https://numpy.org/doc/stable/reference/generated/numpy.power.html)). `.sum(axis=1)` sums across products. The result is the [Herfindahl-Hirschman Index](https://en.wikipedia.org/wiki/Herfindahl%E2%80%93Hirschman_index) per period — a standard measure of market concentration.

```python
top3 = np.sort(ps_norm, axis=1)[:, -3:].sum(axis=1)
```

[`np.sort(..., axis=1)`](https://numpy.org/doc/stable/reference/generated/numpy.sort.html) sorts each row ascending. `[:, -3:]` slices the last 3 columns — the 3 highest shares. `.sum(axis=1)` adds them up.

---

## Section 8 — Package Results

```python
records = []
for t in range(T):
    for j in range(J):
        records.append({...})
df = pd.DataFrame(records)
```

A nested loop builds a list of dictionaries — one per (period, product) combination. [`pd.DataFrame`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.html) converts this list of dicts into a tidy table where each key becomes a column. This is the standard "long format" used in econometrics.

```python
df = df.merge(period_stats, on="period")
```

[`pd.DataFrame.merge`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.merge.html) is a SQL-style join. `on="period"` means rows are matched by the `period` column. This attaches the period-level stats (active counts, exit counts, etc.) to every row for that period.

---

## Section 9 — Save

```python
df.to_csv("/mnt/user-data/outputs/simulated_data.csv", index=False)
```

[`pd.DataFrame.to_csv`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.to_csv.html) writes the dataframe to a CSV file. `index=False` suppresses the row number column that pandas adds by default.

---

## Key NumPy Concepts Used Throughout

| Concept | What it does | Docs |
|---|---|---|
| Broadcasting | Arithmetic between arrays of different shapes | [link](https://numpy.org/doc/stable/user/basics.broadcasting.html) |
| Boolean indexing | Select/assign array elements using a True/False mask | [link](https://numpy.org/doc/stable/user/basics.indexing.html#boolean-array-indexing) |
| Fancy indexing | Select/assign elements using an integer array of indices | [link](https://numpy.org/doc/stable/user/basics.indexing.html#advanced-indexing) |
| `np.newaxis` | Insert a new axis to enable broadcasting | [link](https://numpy.org/doc/stable/reference/constants.html#numpy.newaxis) |
| `.reshape(-1)` | Force array to 1D, infer size automatically | [link](https://numpy.org/doc/stable/reference/generated/numpy.reshape.html) |
| `np.where` | Element-wise conditional selection | [link](https://numpy.org/doc/stable/reference/generated/numpy.where.html) |
| `np.argmax` | Index of maximum value along an axis | [link](https://numpy.org/doc/stable/reference/generated/numpy.argmax.html) |
| `np.argsort` | Indices that would sort an array | [link](https://numpy.org/doc/stable/reference/generated/numpy.argsort.html) |
