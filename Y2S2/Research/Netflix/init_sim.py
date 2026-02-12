import numpy as np
import pandas as pd

def logistic(z):
    return 1.0 / (1.0 + np.exp(-z))

def simulate_one_consumer(
    K=50, J=20, T=30,
    beta=1.0, sigma=3.0, gamma=5.0,
    x0_mean=0.0, x0_sd=1.0, x_shock_sd=0.2,
    seed=123,
    penalty="linear",
):
    rng = np.random.default_rng(seed)

    # x[t, j]
    x = np.zeros((T, K))
    x[0, :] = rng.normal(x0_mean, x0_sd, size=K)
    for t in range(1, T):
        x[t, :] = x[t-1, :] + rng.normal(0.0, x_shock_sd, size=K)

    chosen_j = np.empty(T, dtype=int)
    chosen_x = np.empty(T, dtype=float)
    hist_mean = np.empty(T, dtype=float)
    J_sets = []

    def det_utility(x_vec, hmean):
        if penalty == "linear":
            return beta * x_vec - sigma * (x_vec - hmean)
        elif penalty == "quadratic":
            return beta * x_vec - sigma * (x_vec - hmean) ** 2
        else:
            raise ValueError("penalty must be 'linear' or 'quadratic'")

    # t=1: random set
    J_t = rng.choice(K, size=J, replace=False)
    J_sets.append(J_t)
    hist_mean[0] = 0.0

    eps = rng.gumbel(size=J)
    u = det_utility(x[0, J_t], hist_mean[0]) + eps
    pick_idx = np.argmax(u)
    chosen_j[0] = J_t[pick_idx]
    chosen_x[0] = x[0, chosen_j[0]]

    # t=2..T
    for t in range(1, T):
        hist_mean[t] = chosen_x[:t].mean()

        prev_set = J_sets[t-1]
        prev_set_mean = x[t-1, prev_set].mean()

        weights = logistic(gamma * (x[t, :] - prev_set_mean))
        weights = weights / weights.sum()

        J_t = rng.choice(K, size=J, replace=False, p=weights)
        J_sets.append(J_t)

        eps = rng.gumbel(size=J)
        u = det_utility(x[t, J_t], hist_mean[t]) + eps
        pick_idx = np.argmax(u)
        chosen_j[t] = J_t[pick_idx]
        chosen_x[t] = x[t, chosen_j[t]]

    df_path = pd.DataFrame({
        "t": np.arange(1, T + 1),
        "chosen_j": chosen_j,
        "chosen_x": chosen_x,
        "history_mean_x": hist_mean,
    })

    return df_path, J_sets, x


def choice_sets_long(J_sets):
    """One row per (t, position in set, product id)."""
    rows = []
    for t, J_t in enumerate(J_sets, start=1):
        for pos, j in enumerate(J_t, start=1):
            rows.append((t, pos, int(j)))
    return pd.DataFrame(rows, columns=["t", "pos_in_set", "j"])


def shares_from_one_path(df_path, J_sets, K):
    """
    With one consumer, 'shares' can mean:
      (1) choice share over time: fraction of periods product j is chosen
      (2) appearance share: fraction of periods product j appears in the choice set
    """
    T = df_path.shape[0]

    # (1) chosen shares
    chosen_counts = df_path["chosen_j"].value_counts().reindex(range(K), fill_value=0).sort_index()
    chosen_share = chosen_counts / T

    # (2) appears-in-set shares
    appear_counts = np.zeros(K, dtype=int)
    for J_t in J_sets:
        appear_counts[J_t] += 1
    appear_share = appear_counts / T

    return pd.DataFrame({
        "j": np.arange(K),
        "chosen_count": chosen_counts.values,
        "chosen_share": chosen_share.values,
        "appear_count": appear_counts,
        "appear_share": appear_share,
    })


def simulate_many_consumers_shares(
    N=1000,  # number of consumers
    K=50, J=20, T=30,
    beta_mean=1.0, beta_sd=0.5,
    sigma_mean=3.0, sigma_sd=0.5,
    gamma=5.0,
    seed=123,
    penalty="linear",
):
    """
    Market shares: simulate N independent consumers and compute
    (a) overall shares across all periods and consumers
    (b) period-by-period shares
    """
    rng = np.random.default_rng(seed)

    # store counts
    total_counts = np.zeros(K, dtype=int)
    period_counts = np.zeros((T, K), dtype=int)

    for i in range(N):
        beta_i = rng.normal(beta_mean, beta_sd)
        sigma_i = max(1e-6, rng.normal(sigma_mean, sigma_sd))

        df_path, J_sets, x = simulate_one_consumer(
            K=K, J=J, T=T,
            beta=beta_i, sigma=sigma_i, gamma=gamma,
            seed=int(rng.integers(0, 2**31 - 1)),
            penalty=penalty,
        )

        # tally choices
        for t_idx, j in enumerate(df_path["chosen_j"].to_numpy()):
            period_counts[t_idx, j] += 1
            total_counts[j] += 1

    overall_share = total_counts / (N * T)
    shares_overall = pd.DataFrame({"j": np.arange(K), "share": overall_share}).sort_values("share", ascending=False)

    shares_by_t = pd.DataFrame(period_counts, columns=[f"j{j}" for j in range(K)])
    shares_by_t.insert(0, "t", np.arange(1, T + 1))
    # convert counts to shares
    for j in range(K):
        shares_by_t[f"j{j}"] = shares_by_t[f"j{j}"] / N

    return shares_overall, shares_by_t


# -------------------------
# What you asked for
# -------------------------
df_path, J_sets, x_panel = simulate_one_consumer(K=50, J=20, T=30, beta=1.0, sigma=3.0, gamma=5.0, seed=1)

# 1) Choice sets for ALL periods (long format)
df_sets = choice_sets_long(J_sets)
print(df_sets.head(60))      # first 3 periods (20 rows each)
print(df_sets.tail(60))      # last 3 periods

# 2) Shares from THIS one consumer path
df_shares_one = shares_from_one_path(df_path, J_sets, K=50)
print(df_shares_one.sort_values("chosen_share", ascending=False).head(10))   # most chosen products
print(df_shares_one.sort_values("appear_share", ascending=False).head(10))   # most frequently appearing products

# 3) If you meant market shares: many consumers
shares_overall, shares_by_t = simulate_many_consumers_shares(
    N=2000, K=50, J=20, T=30,
    beta_mean=1.0, beta_sd=0.5,
    sigma_mean=3.0, sigma_sd=0.5,
    gamma=5.0,
    seed=1,
    penalty="linear",
)
print(shares_overall.head(10))   # top-10 market shares overall
print(shares_by_t.head(5))       # first 5 periods: shares for all products
