import numpy as np
import scipy as sp

"""
Helper function, recalculating when choices are Y_i = {0, 1, 2}
"""

def new_predict_prob(b, X, Zdist, Zprice, Y, J):
    N, Kx = X.shape
    Jm1 = J-1

    b = np.asarray(b).ravel()

    B = b[:Kx*(Jm1)].reshape((Kx, Jm1), order="F")
    gamma_d = b[-2]
    gamma_p = b[-1]

    V = np.zeros((N, J))

    for j in range(1, J):
        jj = j-1
        V[:, j] = X @ B[:, jj] + gamma_d * Zdist[:,j] + gamma_p * Zprice[:,j]

    denom = sp.special.logsumexp(V, axis=1, keepdims=True)
    P = np.exp(V - denom)

    P_old = P.copy()
    den = P_old[:,0] + P_old[:,1] + P_old[:,2]
    P_new = P_old[:,:3] / den[:,None]

    pct_change = (P_new -P_old[:,:3]) / P_old[:,:3]

    avg_pct_change = pct_change.mean(axis=0)

    return pct_change, avg_pct_change
