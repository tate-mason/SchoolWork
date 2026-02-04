import numpy as np
import scipy as sp

"""
    Helper file for bootstrapping standard errors. Basically repeat minimize procedure at random draws 500 times.
"""

def boot_se_NLS(Res_NLS, X, Y, b_hat, B=500, seed=219):
    X = np.asarray(X) # call X as a numpy array
    Y = np.asarray(Y) # call Y as a numpy array
    b_hat = np.asarray(b_hat) # def beta_hat

    N, K = X.shape[0], b_hat.size # Def param and count space
    rng = np.random.default_rng(seed) # define randomness procedure

    draws = np.empty((B,K)) # create empty array to store draws

    for b in range(B):
        idx = rng.integers(0, N, size=N) # random draws of X, Y
        res = sp.optimize.minimize(
            Res_NLS,
            x0     = b_hat, # use estimated beta's
            args   =(X[idx,:], Y[idx]), # use X, Y
            method = "BFGS" # use BFGS
        )

        draws[b,:] = res.x # store each b_hat in an array

    return draws.std(axis=0, ddof=1) # return the standard deviation with 1 dof
