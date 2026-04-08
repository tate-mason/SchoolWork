from PS7_load import *

def run():
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

# Part A cont: Transition Matrix  shape (10, 10, 3)
# ptrans[k', k, j] = P(X_{t+1}=k' | X_t=k, Y_t=j)
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
    
    return alpha, sigma, Xgrid, Xgrid2, ptrans

if __name__ == '__main__':
    alpha, sigma, Xgrid, Xgrid2, ptrans = run()
    tbl = PrettyTable(["Parameter", "Estimate", "Truth"])
    tbl.add_row(["alpha_0", f"{alpha[0]:.4f}", "0.00"])
    tbl.add_row(["alpha_1", f"{alpha[1]:.4f}", "-0.75"])
    tbl.add_row(["alpha_2", f"{alpha[2]:.4f}", "0.05"])
    tbl.add_row(["alpha_3", f"{alpha[3]:.4f}", "-0.25"])
    tbl.add_row(["sigma",   f"{sigma:.4f}",    "1.00"])
    print(tbl)
