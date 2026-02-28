import numpy as np
import pandas as pd

"""
File serves to simulate baseline data for netflix algo model:

    Consumer:
    U_ijt = delta_jt + mu_ijt + epsilon_ijt

    where:
        delta_jt  = alpha + beta_bar * x_jt          (mean utility, same for all consumers)
        mu_ijt    = beta_i * x_jt
                    + gamma_it * (x_jt - avg_past_x_it)  (kicks in t >= 2)
                    - nu_it                           (T1EV shock to choice set)
        epsilon_ijt ~ T1EV(0,1)                       (standard logit shock)

    Outside option: U_i0t = 0 (normalized)

    Params:
        J = 20 products
        I = 1000 consumers
        T = 100 periods
    Random Coefs:
        beta_i ~ N(beta_bar, sigma_beta) draw once - fixed
        gamma_it ~ N(0, sigma_gamma)
        nu_it ~ T1EV(0,1)
        x_jt ~ N(mu_x, sigma_x)
        epsilon_ijt ~ T1EV(0,1)
"""

# ========================== #
# Seed Setting               #
# ========================== #

np.random.seed(219)

# ========================== #
# Parameter Definitions      #
# ========================== #

# Dimensions
J = 20 # product space
I = 1000 # consumer space
T = 100 # periods

# mean utility
alpha = -2.15 # coef in delta
beta_bar = 0.8 # mean taste for characteristics

# random coefficients
sigma_beta = 0.5 # spread of characteristic taste
sigma_gamma = 0.3 # spread of variety taste

# exit, re-entry thresholds
exit_threshold = 4
prob_reentry = 0.3

# taste clustering
n_clusters = 5 # number of distinct taste groups
cluster_window = 10 # store last 10 chosen values of x

# algorithmic sorting
K_max = J
K_min = 5
K_decay_every = 10

# Product quality
mu_x = 0.0
sigma_x = 1.0

# ============================= #
# Draw Consumer Heterogeneity   #
#   One time per consumer       #
# ============================= #

beta_i = np.random.normal(beta_bar, sigma_beta, I)
print(f"beta_i: mean={beta_i.mean():.3f}, std={beta_i.std():.3f}")

# ============================= #
# Simulate x_jt characteristics #
# ============================= #

x = np.random.normal(mu_x, sigma_x, J)
print(f"x_jt: mean={x.mean():.3f}, std={x.std():.3f}")

# ============================= #
# Compute delta_jt              #
# ============================= #

delta = alpha + beta_bar*x

# ============================= #
# Main Sim Loop over Time       #
# ============================= #

choices = np.full((I,T), fill_value=-1, dtype=int) # vector of choices which consumer i makes over t periods

share = np.zeros((T, J+1)) # vector for "market share" with storage for outside option

consecutive_out = np.zeros(I, dtype=int)
is_exit = np.zeros(I, dtype=bool)
periods_exit = np.zeros(I, dtype=int)

history_buffer = np.full((I, cluster_window), fill_value=np.nan)
history_ptr = np.zeros(I, dtype=int)
history_count = np.zeros(I, dtype=int)

sum_past_x = np.zeros(I) # running sum of past choices
count_past = np.zeros(I) # number of past choices

n_active_per_period = np.zeros(T, int)
n_exited_per_period = np.zeros(T, int)
n_reentry_per_period = np.zeros(T, int)
n_newexit_per_period = np.zeros(T, int)
K_per_period = np.zeros(T, int)

for t in range(T):
    exited_mask = is_exit.copy()
    if exited_mask.any():
        exited_idx = np.where(exited_mask)[0]
        k = periods_exit[exited_idx]
        p_reentry = 1 - np.exp(-prob_reentry*k)
        did_reenter = np.random.uniform(size=len(exited_idx)) < p_reentry

        reentry_idx = exited_idx[did_reenter]
        still_out = exited_idx[~did_reenter]

        is_exit[reentry_idx] = False
        periods_exit[reentry_idx] = 0
        consecutive_out[reentry_idx] = 0
        n_reentry_per_period[t] = len(reentry_idx)
        periods_exit[still_out] += 1

    active_mask = ~is_exit
    active_idx = np.where(active_mask)[0]
    n_active = len(active_idx)
    n_active_per_period[t] = n_active
    n_exited_per_period[t] = I - n_active

    if n_active == 0:
        print(f"Period {t:3d} | WARNING: all consumers exited!")
        continue

    K_t = max(K_min, K_max-t // K_decay_every)
    K_per_period[t] = K_t

    has_history = history_count[active_idx]>0

    rolling_avg = np.zeros(n_active)
    for pos, i in enumerate(active_idx):
        if history_count[i] > 0:
            valid = history_buffer[i, :history_count[i]]
            rolling_avg[pos] = valid.mean()

    cluster_labels = np.full(n_active, fill_value=-1, dtype=int)
    has_hist_pos = np.where(has_history)[0]

    if len(has_hist_pos) >= n_clusters:
        signal = rolling_avg[has_hist_pos]
        order = np.argsort(signal)
        buckets = np.array_split(order,n_clusters)

        for c, bucket in enumerate(buckets):
            cluster_labels[has_hist_pos[bucket]] = c
        centroids = np.array([signal[b].mean() for b in buckets])
    else:
        centroids = np.linspace(x.min(), x.max(), n_clusters)


    visible_mask = np.ones((n_active, J), bool)
    if len(has_hist_pos) >= n_clusters:
        dist = np.abs(x[np.newaxis, :] - centroids[:,np.newaxis])

        for c in range(n_clusters):
            closest_K = np.argsort(dist[c])[:K_t]
            cluster_visible = np.zeros(J, bool)
            cluster_visible[closest_K] = True

            in_cluster = cluster_labels == c
            visible_mask[in_cluster] = cluster_visible

    gamma_it    = np.random.normal(loc=0, scale=sigma_gamma, size=n_active).reshape(-1)
    nu_it       = -np.log(-np.log(np.random.uniform(size=n_active).reshape(-1)))
    epsilon_ijt = -np.log(-np.log(np.random.uniform(size=(n_active, J)).reshape(n_active, J)))

    if t == 0:
        variety = np.zeros((n_active, J))
    else:
        has_full = count_past[active_idx] > 0
        avg_past = np.where(
            has_full,
            np.divide(sum_past_x[active_idx], count_past[active_idx],
                      where=has_full, out=np.zeros(n_active)),
            0.0
        )

        variety = x[np.newaxis,:] - avg_past[:,np.newaxis]

    mu_ijt = (beta_i[active_idx][:,np.newaxis]*x[np.newaxis, :]
              + gamma_it[:,np.newaxis]*variety - nu_it[:,np.newaxis])

    U_ijt = delta[np.newaxis,:] + mu_ijt + epsilon_ijt
    U_ijt[~visible_mask] = -np.inf

    U_full = np.hstack([np.zeros((n_active, 1)), U_ijt])
    chosen = np.argmax(U_full, 1)

    choices[active_idx,t] = chosen

    for j in range(J+1):
        share[t,j] = np.mean(chosen == J)

    chose_outside = chosen == 0
    chose_product = chosen > 0
    consecutive_out[active_idx[chose_outside]] += 1
    consecutive_out[active_idx[chose_product]] = 0

    hit_thresh = consecutive_out[active_idx].reshape(-1) >= exit_threshold
    new_exit_index = active_idx[hit_thresh]
    is_exit[new_exit_index]= True
    periods_exit[new_exit_index] = 0
    n_newexit_per_period[t] = len(new_exit_index)

    product_choosers = active_idx[chose_product]
    product_chosen = chosen[chose_product] - 1
    char_chosen = x[product_chosen]

    sum_past_x[product_choosers] += char_chosen
    count_past[product_choosers] += 1

    for pos, i in enumerate(product_choosers):
        ptr = history_ptr[i]
        history_buffer[i, ptr] = char_chosen[pos]
        history_ptr[i] = (ptr+1) % cluster_window
        history_count[i] = min(history_count[i] + 1, cluster_window)

    if t % 10 == 0:
        print(f"Period {t:3d} | K = {K_t:2d} | Active: {n_active:4d} | "
            f"Exited: {I-n_active:3d} | New Exits: {n_newexit_per_period[t]:3d} " 
            f"Re-Entries: {n_reentry_per_period[t]:3d} | " 
            f"Outside Share: {share[t,0]:.3f}")

product_shares = share[:, 1:]   # (T, J)

# Renormalise across products (exclude outside option) for HHI
row_sums = product_shares.sum(axis=1, keepdims=True)
row_sums = np.where(row_sums == 0, 1, row_sums)
ps_norm  = product_shares / row_sums

HHI     = (ps_norm ** 2).sum(axis=1)          # (T,) — higher = more concentrated
top3    = np.sort(ps_norm, axis=1)[:, -3:].sum(axis=1)  # top-3 share each period

print("\n--- Condensation over time ---")
print(f"{'Period':<12} {'K_t':<6} {'HHI':<8} {'Top-3 share'}")
for decade in range(0, T, 10):
    sl  = slice(decade, decade + 10)
    k   = K_per_period[sl].mean()
    h   = HHI[sl].mean()
    t3  = top3[sl].mean()
    print(f"t={decade:02d}-{decade+9:<4}  K={k:<4.0f}  {h:.4f}   {t3:.3f}")

print(f"\nTotal exits:    {n_newexit_per_period.sum()}")
print(f"Total re-entries: {n_reentry_per_period.sum()}")

# ---------------------------------------------------------------
# 8.  PACKAGE RESULTS
# ---------------------------------------------------------------

records = []
for t in range(T):
    for j in range(J):
        records.append({
            "period":   t,
            "product":  j + 1,
            "x_j":      x[j],          # fixed quality
            "delta_j":  delta[j],       # fixed mean utility
            "share_jt": share[t, j + 1],
            "K_t":      K_per_period[t],
            "HHI":      HHI[t],
        })

df = pd.DataFrame(records)

period_stats = pd.DataFrame({
    "period":        range(T),
    "outside_share": share[:, 0],
    "n_active":      n_active_per_period,
    "n_exited":      n_exited_per_period,
    "n_reentries":   n_reentry_per_period,
    "n_new_exits":   n_newexit_per_period,
})
df = df.merge(period_stats, on="period")

print("\n--- Sample rows ---")
print(df.head(8).to_string(index=False))
print(f"\nDataframe shape: {df.shape}")


