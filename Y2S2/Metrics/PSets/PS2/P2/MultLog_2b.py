import numpy as np
import scipy as sp

def mnl_mle_b(b, X, Zdist, Zprice, Y, J):

    N, Kx = X.shape
    Jm1 = J-1

    b = np.asarray(b).ravel()
    p_exp = Kx * Jm1 + 2 # parameter dimensions

    B = b[:Kx*(Jm1)].reshape((Kx, Jm1), order="F")
    gamma_d = b[-2]
    gamma_p = b[-1]

    V = np.zeros((N, J))

    for j in range(1, J):
        jj = j-1
        V[:, j] = X @ B[:, jj] + gamma_d * Zdist[:,j] + gamma_p * Zprice[:,j]

    denom = sp.special.logsumexp(V, axis=1)
    Vchosen = V[np.arange(N), Y]

    return -np.sum(Vchosen - denom)

def mnl_fit_b(X, Zdist, Zprice, Y, J=4):
    Jm1 = J-1
    N, Kx = X.shape
    x0 = np.ones(Kx*(Jm1) + 2) # new starting values - from zeros to ones

    res = sp.optimize.minimize(
        mnl_mle_b,
        x0,
        args = (X, Zdist, Zprice, Y, J),
        method = "BFGS"
    )

    b_hat = res.x
    se = np.sqrt(np.diag(res.hess_inv))

    return b_hat, se, res

