import numpy as np
import scipy as sp

# define a logistic distribution
def logistic(z):
    return 1 / (1+np.exp(-z))

# average marginal effect
def ame_dummy(beta, W, k, x1=1.0, x0=0.0):
    # those with and without parent with BA
    W1 = W.copy()
    W0 = W.copy()
    W1[:, k] = x1
    W0[:, k] = x0

    # probability for each group
    p1 = logistic(W1@beta)
    p0 = logistic(W0@beta)

    # difference group
    return float((p1-p0).mean())

# bootstrap standard errors for AME
def boot_se_AME(W, Y, fit_beta, k, B=500, seed=219):
    # set seed
    rng = np.random.default_rng(seed)
    # dimensions
    N = W.shape[0]
    t_boot = np.empty(B)

    # bootstrapping function
    for b in range(B):
        idx = rng.integers(0, N, size=N)
        Wb = W[idx,:]
        Yb = Y[idx]

        # parameter
        beta_b = fit_beta(Wb, Yb)
        # ame
        t_boot[b] = ame_dummy(beta_b, W, k)
    # recover std. dev.
    se_boot = t_boot.std(ddof=1)
    return se_boot, t_boot
