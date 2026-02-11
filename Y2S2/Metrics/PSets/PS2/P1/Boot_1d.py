import numpy as np
import scipy as sp

def logistic(z):
    return 1 / (1+np.exp(-z))

def ame_dummy(beta, W, k, x1=1.0, x0=0.0):
    W1 = W.copy()
    W0 = W.copy()

    W1[:, k] = x1
    W0[:, k] = x0

    p1 = logistic(W1@beta)
    p0 = logistic(W0@beta)

    return float((p1-p0).mean())

def boot_se_AME(W, Y, fit_beta, k, B=500, seed=219):
    rng = np.random.default_rng(seed)
    N = W.shape[0]
    t_boot = np.empty(B)

    for b in range(B):
        idx = rng.integers(0, N, size=N)
        Wb = W[idx,:]
        Yb = Y[idx]

        beta_b = fit_beta(Wb, Yb)
        t_boot[b] = ame_dummy(beta_b, Wb, Yb)
    se_boot = t_boot.std(ddof=1)
    return se_boot, t_boot
