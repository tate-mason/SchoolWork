import numpy as np
import pandas as pd
import scipy as sp
import statsmodels.api as sm
from scipy.stats import norm
from scipy.optimize import minimize
from prettytable import PrettyTable

# ============================================================
# Load Data
# ============================================================
df  = sp.io.loadmat('../Data/dataHW7_problem1.mat')

X   = df['X1']    # (N, 2): constant, gender
Xt  = df['X1t']   # (N, T): time-varying health
Y   = df['Y']     # (N, T): choices {0,1,2,3}
Y_0 = df['LY1']   # (N, 1): initial period choice

N, T = Y.shape

# ============================================================
# Part A: Transition Parameters
# ============================================================

# Build long-format data for OLS
Xt_next  = Xt[:, 1:].ravel()                  # (N*(T-1),)
Xt_curr  = Xt[:, :-1].ravel()                 # (N*(T-1),)
Y_curr   = Y[:, :-1].ravel()                  # (N*(T-1),)

active_A = Y_curr > 0                         # only active workers

X_trans  = sm.add_constant(np.column_stack([
    Xt_curr[active_A],
    (Y_curr[active_A] == 2).astype(int),       # part-time dummy
    (Y_curr[active_A] == 3).astype(int),       # full-time dummy
]))

trans_res = sm.OLS(Xt_next[active_A], X_trans).fit()
alpha     = trans_res.params                   # [a0, a1, a2, a3]
sigma     = np.sqrt(trans_res.scale)

print("=== Part A: Transition Parameters ===")
tbl = PrettyTable(["Parameter", "Estimate", "Truth"])
tbl.add_row(["alpha_0 (const)",    f"{alpha[0]:.4f}", "0.00"])
tbl.add_row(["alpha_1 (lag X)",    f"{alpha[1]:.4f}", "-0.75"])
tbl.add_row(["alpha_2 (part-time)",f"{alpha[2]:.4f}", "0.05"])
tbl.add_row(["alpha_3 (full-time)",f"{alpha[3]:.4f}", "-0.25"])
tbl.add_row(["sigma",              f"{sigma:.4f}",    "1.00"])
print(tbl)

# ============================================================
# Part A cont: Transition Matrix  shape (10, 10, 3)
# ptrans[k', k, j] = P(X_{t+1}=k' | X_t=k, Y_t=j)
# ============================================================
quantiles = (np.arange(10) + 0.5) / 10        # [0.05, ..., 0.95]
Xgrid     = norm.ppf(quantiles)               # (10,) grid midpoints
Xgrid2    = norm.ppf(np.arange(1, 10) / 10)  # (9,)  bin cutoffs
cutoffs   = np.concatenate([[-np.inf], Xgrid2, [np.inf]])  # (11,)

pt_ind = np.array([0, 1, 0])   # part-time indicator per j
ft_ind = np.array([0, 0, 1])   # full-time indicator per j

mu = (alpha[0]
      + alpha[1] * Xgrid[:, None]      # (10, 1)
      + alpha[2] * pt_ind[None, :]     # (1,  3)
      + alpha[3] * ft_ind[None, :])    # (10, 3)

# ptrans[k', k, j]
upper  = norm.cdf(cutoffs[1:, None, None],  loc=mu[None, :, :], scale=sigma)  # (10,10,3)
lower  = norm.cdf(cutoffs[:-1, None, None], loc=mu[None, :, :], scale=sigma)  # (10,10,3)
ptrans = upper - lower                                                          # (10,10,3)

# ============================================================
# Part B: Estimate CCPs via Logit
# P(retire | X1, X1t, lag_Y, t)
# ============================================================
Xt_flat = Xt.ravel()
Y_lag   = np.concatenate([np.full((N, 1), np.nan), Y[:, :-1]], axis=1)  # (N,T)
t_idx   = np.tile(np.arange(T), (N, 1))                                  # (N,T)

ccps_df = pd.DataFrame({
    'X_1':   np.tile(X[:, 0], (T, 1)).T.ravel(),
    'X_2':   np.tile(X[:, 1], (T, 1)).T.ravel(),
    'X_t':   Xt_flat,
    'Y_0':   np.tile(Y_0.ravel(), T),
    'Y':     Y.ravel(),
    'lag_Y': Y_lag.ravel(),
    't':     t_idx.ravel(),
})

# Keep only active individuals
ccps_df = ccps_df[ccps_df['lag_Y'].notna() & (ccps_df['lag_Y'] != 0)].copy()

ccps_df['retired']  = (ccps_df['Y'] == 0).astype(int)
ccps_df['lag_Y_pt'] = (ccps_df['lag_Y'] == 2).astype(int)   # part-time lag dummy
ccps_df['lag_Y_ft'] = (ccps_df['lag_Y'] == 3).astype(int)   # full-time lag dummy

period_dummies = pd.get_dummies(ccps_df['t'], prefix='t', drop_first=True).astype(int) # (T-1) dummies for periods 1..T-1, period 0 as base

X_ccps   = pd.concat([ccps_df[['X_1', 'X_2', 'X_t', 'Y_0', 'lag_Y_pt', 'lag_Y_ft']], # main regressors
                       period_dummies], axis=1)
ccps_res = sm.Logit(ccps_df['retired'], X_ccps).fit(disp=False) # logit regression

print("\n=== Part B: CCP Logit Summary ===")
print(ccps_res.summary())  # return summary to check coefficients

# ============================================================
# Part C: Future Value Terms  shape (3, 10, T)
# ============================================================
euler = 0.57722

# Build prediction df: 10 grid points repeated for each of T periods
grid_rep   = np.tile(Xgrid, T)              # (10*T,)
period_rep = np.repeat(np.arange(T), 10)   # (10*T,)

pred_df = pd.DataFrame({
    'X_1':      ccps_df['X_1'].mean(),
    'X_2':      ccps_df['X_2'].mean(),
    'X_t':      grid_rep,
    'Y_0':      ccps_df['Y_0'].mean(),
    'lag_Y_pt': 0,                          # flex-time as base
    'lag_Y_ft': 0,
})

for col in period_dummies.columns:
    pred_df[col] = (period_rep == int(col.split('_')[1])).astype(int)

P0_flat = ccps_res.predict(pred_df)         # (10*T,)
P0_grid = P0_flat.values.reshape(T, 10).T  # (10, T)

Emax_grid = -np.log(P0_grid) + euler        # (10, T)

# einsum: ptrans is (k', k, j), Emax_next is (k', t) -> result (j, k, t)
Emax_next  = Emax_grid[:, 1:]               # (10, T-1): periods 2..T

fv_raw             = np.zeros((3, 10, T))
fv_raw[:, :, :-1]  = np.einsum('pkj,pt->jkt', ptrans, Emax_next)
# for each (choice, current_state, period): sum over k' of ptrans * emax_next

print("\n=== Part C: Future Values Constructed ===")
print(f"fv_raw shape: {fv_raw.shape}  (3 choices, 10 health bins, {T} periods)") # check dimensions

# ============================================================
# Part D: Static Multinomial Logit with FV as offset
# ============================================================

# Discretize observed X1t into state bins 0..9
State = np.zeros((N, T), dtype=int)
for i, cutoff in enumerate(Xgrid2):
    State += (Xt.reshape(N, T) > cutoff).astype(int)

partD_df = pd.DataFrame({
    'X_1':     np.tile(X[:, 0], (T, 1)).T.ravel(),
    'X_2':     np.tile(X[:, 1], (T, 1)).T.ravel(),
    'X_t':     Xt_flat,
    'Y_0':     np.tile(Y_0.ravel(), T),
    'Y':       Y.ravel(),
    'lag_Y':   Y_lag.ravel(),
    'state_k': State.ravel(),
    't_idx':   t_idx.ravel(),
})

# Filter: active only
partD_df = partD_df[partD_df['lag_Y'].notna() & (partD_df['lag_Y'] != 0)].copy()
partD_df['j']     = (partD_df['lag_Y'] - 1).astype(int)   # lag choice -> 0,1,2
partD_df['k']     = partD_df['state_k'].astype(int)
partD_df['t_idx'] = partD_df['t_idx'].astype(int)

# Attach raw future value for each observation's (j, k, t)
partD_df['fv_raw'] = fv_raw[
    partD_df['j'].values,
    partD_df['k'].values,
    partD_df['t_idx'].values,
]

def log_likelihood(params):
    b1    = params[0:3]   # flex-time parameters
    b2    = params[3:6]   # part-time parameters
    b3    = params[6:9]   # full-time parameters
    scost = params[9]     # switching cost
    beta  = 1 / (1 + np.exp(-params[10]))  # discount factor, constrained (0,1)

    X1_  = partD_df['X_1'].values # constant
    X2_  = partD_df['X_2'].values # gender
    Xt_  = partD_df['X_t'].values # health
    fv_  = beta * partD_df['fv_raw'].values # discounted future value
    lag  = partD_df['lag_Y'].values         # in {1, 2, 3}
    Y_   = partD_df['Y'].values             # in {0, 1, 2, 3}

    def v(b, j_choice):
        # switching cost if lagged choice != current choice j
        sw = scost * (lag != j_choice).astype(float)
        return b[0]*X1_ + b[1]*X2_ + b[2]*Xt_ - sw + fv_

    v1 = v(b1, 1)   # flex-time
    v2 = v(b2, 2)   # part-time
    v3 = v(b3, 3)   # full-time
    # v0 = 0 (retirement, normalized outside option)

    log_denom = sp.special.logsumexp(
        np.column_stack([np.zeros(len(Y_)), v1, v2, v3]), axis=1 # stack v0=0 with v1,v2,v3 for log-sum-exp denominator
    )

    # log probability of observed choice Y_ given utilities v0=0, v1, v2, v3
    log_prob = (
        (Y_ == 0) * (            - log_denom) +
        (Y_ == 1) * (v1          - log_denom) +
        (Y_ == 2) * (v2          - log_denom) +
        (Y_ == 3) * (v3          - log_denom)
    )

    return -np.sum(log_prob) # negative log-likelihood for minimization
 
# Starting values: zeros for coefficients, logit(0.8) for beta
b0       = np.zeros(12)

result   = minimize(log_likelihood, x0=b0, method='BFGS',
                    options={'maxiter': 10000, 'gtol': 1e-8})

params_hat = result.x
beta_hat   = 1 / (1 + np.exp(-params_hat[10])) # transform back to (0,1) scale

print("\n=== Part D: Estimation Results ===")
labels    = ['b1_const', 'b1_gender', 'b1_health',
             'b2_const', 'b2_gender', 'b2_health',
             'b3_const', 'b3_gender', 'b3_health',
             'scost',    'beta']
true_vals = [-0.75, 0.25, 0.25,
             -0.25, 0.50, 0.50,
             -0.85, 0.75, 0.75,
              0.40, 0.80]

res_tbl = PrettyTable(["Parameter", "Estimate", "Truth"])
for i, lab in enumerate(labels):
    est = beta_hat if lab == 'beta' else params_hat[i]
    res_tbl.add_row([lab, f"{est:.4f}", true_vals[i]])
print(res_tbl)
