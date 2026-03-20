"""
Python translation of MigCalibration.jl

Dynamic discrete-choice migration model with workers and retirees.
Ages 40-80, Z discrete locations (U.S. states).

Conventions (matching Julia source):
  - age index t = 0 .. T-1  (age = 40 + t)
  - location index z = 0 .. Z-1
  - Utility shocks are i.i.d. Type-1 Extreme Value  =>  logit choice probs
  - Implied value function: V = log-sum-exp of choice utilities  (Rust 1987)
"""

import numpy as np
from dataclasses import dataclass


# ========================
# 1. Environment Container
# ========================

@dataclass
class DataEnv:
    """
    Holds all exogenous objects for the model.

    Arrays use 0-based indexing:
      wage[z, t]  : pre-tax labor income for location z at age-index t
      tax[z, t]   : average tax rate in [0, 1]
      rent[z, t]  : rental housing cost
      hc_cost[z, t]: healthcare cost (retirees only)
    """
    Z:            int
    ages:         list            # e.g. list(range(40, 81))
    beta:         float           # discount factor
    sigma:        float           # CRRA coefficient
    prob_retire:  float           # annual probability of retiring
    prob_death:   float           # annual probability of dying
    pension_rate: float           # pension as fraction of wage
    amenW_base:   np.ndarray      # shape (Z,) worker amenity by state
    amenR_base:   np.ndarray      # shape (Z,) retiree amenity by state
    wage:         np.ndarray      # shape (Z, T)
    tax:          np.ndarray      # shape (Z, T)
    rent:         np.ndarray      # shape (Z, T)
    hc_cost:      np.ndarray      # shape (Z, T)
    init_dist_40: np.ndarray      # shape (Z,), sums to 1


def check_env(env):
    T = len(env.ages)
    assert env.wage.shape    == (env.Z, T)
    assert env.tax.shape     == (env.Z, T)
    assert env.rent.shape    == (env.Z, T)
    assert env.hc_cost.shape == (env.Z, T)
    assert len(env.amenW_base)    == env.Z
    assert len(env.amenR_base)    == env.Z
    assert len(env.init_dist_40)  == env.Z
    assert abs(env.init_dist_40.sum() - 1.0) < 1e-8


# =========================
# 2. Utility Functions
# =========================

def u_crra(c, sigma):
    """CRRA utility. Returns -1e10 if c <= 0."""
    if c <= 0:
        return -1e10
    elif sigma == 1.0:
        return np.log(c)
    else:
        return (c ** (1.0 - sigma)) / (1.0 - sigma)


def worker_flow_utility(env, z, t, alpha_W):
    """Per-period flow utility for a worker in location z at age-index t."""
    y = env.wage[z, t] * (1.0 - env.tax[z, t])
    c = y - env.rent[z, t]
    return u_crra(c, env.sigma) + alpha_W * env.amenW_base[z]


def retiree_flow_utility(env, z, t, alpha_R):
    """Per-period flow utility for a retiree in location z at age-index t."""
    pension = env.pension_rate * env.wage[z, t]
    y = pension * (1.0 - env.tax[z, t])
    c = y - env.hc_cost[z, t]
    return u_crra(c, env.sigma) + alpha_R * env.amenR_base[z]


# =============================
# 3. Value Function Iteration
# =============================

def solve_model(env, gamma_W, gamma_R, alpha_W, alpha_R):
    """
    Solve the model by backward induction.

    Parameters to estimate:
      gamma_W : moving cost for workers
      gamma_R : moving cost for retirees
      alpha_W : amenity weight for workers
      alpha_R : amenity weight for retirees

    Returns:
      Vw[t, z]       : worker value at age-index t in location z
      Vr[t, z]       : retiree value at age-index t in location z
      Pw[t, z, zp]   : worker Pr(move to zp | at z, age-index t)
      Pr_arr[t, z, zp]: retiree Pr(move to zp | at z, age-index t)
    """
    check_env(env)
    Z    = env.Z
    T    = len(env.ages)
    beta = env.beta
    pr   = env.prob_retire
    pd   = env.prob_death

    Vw     = np.zeros((T, Z))
    Vr     = np.zeros((T, Z))
    Pw     = np.zeros((T, Z, Z))
    Pr_arr = np.zeros((T, Z, Z))

    for t in range(T - 1, -1, -1):   # backward induction from T-1 to 0
        for z in range(Z):

            # ---- Retiree ----
            u_stay_r     = retiree_flow_utility(env, z, t, alpha_R)
            cont_r_stay  = beta * (1.0 - pd) * Vr[t + 1, z] if t < T - 1 else 0.0
            util_r_stay  = u_stay_r + cont_r_stay

            util_r = np.empty(Z)
            for zp in range(Z):
                if zp == z:
                    util_r[zp] = util_r_stay
                else:
                    u_move_r    = retiree_flow_utility(env, zp, t, alpha_R) - gamma_R
                    cont_r_move = beta * (1.0 - pd) * Vr[t + 1, zp] if t < T - 1 else 0.0
                    util_r[zp]  = u_move_r + cont_r_move

            # log-sum-exp for numerical stability
            util_r_max     = util_r.max()
            exp_r          = np.exp(util_r - util_r_max)
            denom_r        = exp_r.sum()
            Vr[t, z]       = util_r_max + np.log(denom_r)
            Pr_arr[t, z, :] = exp_r / denom_r

            # ---- Worker ----
            u_stay_w = worker_flow_utility(env, z, t, alpha_W)
            if t < T - 1:
                cont_w_stay = beta * ((1.0 - pr) * Vw[t + 1, z] + pr * Vr[t + 1, z])
            else:
                cont_w_stay = 0.0
            util_w_stay = u_stay_w + cont_w_stay

            util_w = np.empty(Z)
            for zp in range(Z):
                if zp == z:
                    util_w[zp] = util_w_stay
                else:
                    u_move_w   = worker_flow_utility(env, zp, t, alpha_W) - gamma_W
                    if t < T - 1:
                        cont_w_move = beta * ((1.0 - pr) * Vw[t + 1, zp] + pr * Vr[t + 1, zp])
                    else:
                        cont_w_move = 0.0
                    util_w[zp] = u_move_w + cont_w_move

            util_w_max  = util_w.max()
            exp_w       = np.exp(util_w - util_w_max)
            denom_w     = exp_w.sum()
            Vw[t, z]    = util_w_max + np.log(denom_w)
            Pw[t, z, :] = exp_w / denom_w

    return Vw, Vr, Pw, Pr_arr


# ============================
# 4. Simulate Agents
# ============================

def simulate_model_moments(theta, env, n_agents=100_000, rng=None):
    """
    Simulate a panel of agents from age 40 to 80.

    Inputs:
      theta     = (gamma_W, gamma_R, alpha_W, alpha_R)
      env       : DataEnv
      n_agents  : number of agents to simulate
      rng       : numpy Generator (optional)

    Returns a dict with:
      p_move_40_50  : fraction of agent-years with a move, ages 40-50
      p_move_65p    : fraction of agent-years with a move, age 65+
      P_40_50       : (Z, Z) migration matrix, ages 40-50
      P_65p         : (Z, Z) migration matrix, age 65+
      p_move_pairs  : list of move probs by 2-year age bands
      agepair_starts: list of starting ages for each band
      exp_pair, mov_pair: raw exposure/move counts by age band
    """
    if rng is None:
        rng = np.random.default_rng()

    gamma_W, gamma_R, alpha_W, alpha_R = theta
    check_env(env)

    Z    = env.Z
    ages = env.ages
    T    = len(ages)
    amin = ages[0]
    amax = ages[-1]

    Vw, Vr, Pw, Pr_arr = solve_model(env, gamma_W, gamma_R, alpha_W, alpha_R)

    move_40_50  = 0
    obs_40_50   = 0
    move_65p    = 0
    obs_65p     = 0
    flows_40_50 = np.zeros((Z, Z))
    flows_65p   = np.zeros((Z, Z))

    n_pairs  = (amax - amin) // 2 + 1
    exp_pair = np.zeros(n_pairs)
    mov_pair = np.zeros(n_pairs)

    def agepair_index(age):
        if age < amin or age > amax:
            return -1
        return (age - amin) // 2

    init_z = rng.choice(Z, size=n_agents, p=env.init_dist_40)

    for n in range(n_agents):
        z          = init_z[n]
        is_retired = False

        for t in range(T):
            age = ages[t]
            k   = agepair_index(age)

            # Accumulate exposure counts
            if 40 <= age <= 50:
                obs_40_50 += 1
            if age >= 65:
                obs_65p += 1
            if k >= 0:
                exp_pair[k] += 1.0

            # Draw next location from choice probabilities
            probs = Pr_arr[t, z, :].copy() if is_retired else Pw[t, z, :].copy()
            s = probs.sum()
            if not (s > 0) or not np.isfinite(s):
                probs    = np.zeros(Z)
                probs[z] = 1.0
            else:
                probs /= s

            zp    = rng.choice(Z, p=probs)
            moved = (zp != z)

            if 40 <= age <= 50 and moved:
                move_40_50       += 1
                flows_40_50[z, zp] += 1.0
            if age >= 65 and moved:
                move_65p         += 1
                flows_65p[z, zp] += 1.0
            if k >= 0 and moved:
                mov_pair[k] += 1.0

            # Death shock
            if rng.random() < env.prob_death:
                break

            # Retirement shock (age 65 triggers mandatory retirement)
            if not is_retired and rng.random() < env.prob_retire:
                is_retired = True
            elif age >= 65:
                is_retired = True

            z = zp

    # Compute summary moments
    p_move_40_50 = move_40_50 / obs_40_50 if obs_40_50 > 0 else float('nan')
    p_move_65p   = move_65p   / obs_65p   if obs_65p   > 0 else float('nan')

    p_move_pairs  = [
        mov_pair[k] / exp_pair[k] if exp_pair[k] > 0 else float('nan')
        for k in range(n_pairs)
    ]
    agepair_starts = [amin + 2 * k for k in range(n_pairs)]

    def normalize_flows(F):
        P        = F.copy()
        row_sums = P.sum(axis=1, keepdims=True)
        row_sums[row_sums == 0] = 1.0
        return P / row_sums

    return {
        'p_move_40_50':   p_move_40_50,
        'p_move_65p':     p_move_65p,
        'P_40_50':        normalize_flows(flows_40_50),
        'P_65p':          normalize_flows(flows_65p),
        'agepair_starts': agepair_starts,
        'p_move_pairs':   p_move_pairs,
        'exp_pair':       exp_pair,
        'mov_pair':       mov_pair,
    }


# ============================
# 5. Setup  (from MigCalibration.jl example)
# ============================

Z    = 49               # 48 contiguous states + DC
ages = list(range(40, 81))
T    = len(ages)

beta         = 0.96
sigma        = 3.0
prob_retire  = 0.08
prob_death   = 0.04
pension_rate = 0.3

amenW_base = np.linspace(-0.5,  0.5, Z)
amenR_base = np.linspace( 0.5, -0.5, Z)

wage    = np.zeros((Z, T))
tax     = np.zeros((Z, T))
rent    = np.zeros((Z, T))
hc_cost = np.zeros((Z, T))

for ti, age in enumerate(ages):
    age_factor = 1.0 + 0.02 * (age - 40)
    for zi in range(Z):
        base_w          = 40_000.0 + 60_000.0 * zi   # matches Julia: 40k + 60k*(zi-1), 1-based
        wage[zi, ti]    = base_w * age_factor
        tax[zi, ti]     = 0.05 + 0.17 * zi / (Z - 1)
        rent[zi, ti]    = 8_000.0 + 16_000.0 * (Z - 1 - zi) / (Z - 1)
        hc_cost[zi, ti] = 10_000.0 + 2_000.0 * zi / (Z - 1)

# Gaussian initial distribution centered near the middle state
weights      = np.array([np.exp(-((zi - Z / 2) ** 2) / (2 * (Z / 6) ** 2)) for zi in range(Z)])
init_dist_40 = weights / weights.sum()

env = DataEnv(
    Z=Z, ages=ages, beta=beta, sigma=sigma,
    prob_retire=prob_retire, prob_death=prob_death,
    pension_rate=pension_rate,
    amenW_base=amenW_base, amenR_base=amenR_base,
    wage=wage, tax=tax, rent=rent, hc_cost=hc_cost,
    init_dist_40=init_dist_40,
)
check_env(env)


# ============================
# 6. Example Run
# ============================

if __name__ == '__main__':
    import matplotlib.pyplot as plt

    theta_test = (5.5, 5.0, 0.5, 0.5)
    rng        = np.random.default_rng(42)

    print("Solving model and simulating 100,000 agents...")
    moms = simulate_model_moments(theta_test, env, n_agents=100_000, rng=rng)

    print("Prob. of moving, age 40-50:", round(moms['p_move_40_50'], 4))
    print("Prob. of moving, age 65+:  ", round(moms['p_move_65p'],   4))
    print("Move probs by age pairs (first 5):", [round(x, 4) for x in moms['p_move_pairs'][:5]])

    fig, ax = plt.subplots(figsize=(8, 4))
    ax.plot(moms['agepair_starts'], moms['p_move_pairs'], marker='o')
    ax.set_xlabel("Starting age of 2-year pair")
    ax.set_ylabel("Move probability")
    ax.set_title("Move Probabilities by 2-Year Age Pairs")
    ax.set_xlim(min(moms['agepair_starts']) - 1, 70)
    plt.tight_layout()
    plt.savefig("move_probs_by_age_pairs.pdf")
    plt.show()
