import numpy as np
import scipy as sp

"""
Helper function for multinomial logit:
    - mnl_mle: calculates the -ll for the multinomial logit, give parameter vector b, data X, Zdist, Zprice, Y, and choices J
    - mnl_fit: uses the minimize function within Scipy to find the parameter estimates that minimize the negative ll, given the same inputs as above. Returns estimates, se, and results.
"""

def mnl_mle(b, X, Zdist, Zprice, Y, J):

    # define dimensions and reshape b (parameter vector) into B, gamma_d, and gamma_p
    N, Kx = X.shape
    Jm1 = J-1

    b = np.asarray(b).ravel()
    p_exp = Kx * Jm1 + 2 # parameter dimensions

    B = b[:Kx*(Jm1)].reshape((Kx, Jm1), order="F")
    gamma_d = b[-2]
    gamma_p = b[-1]

    # calculate V for each j, using the formula V_ij = X_i * B_j + gamma_d * Zdist_ij + gamma_p * Zprice_ij. note, we start j at 1 since the first column of B is normalized to zero (the outside option)
    V = np.zeros((N, J))

    for j in range(1, J):
        jj = j-1
        V[:, j] = X @ B[:, jj] + gamma_d * Zdist[:,j] + gamma_p * Zprice[:,j]

    denom = sp.special.logsumexp(V, axis=1)
    Vchosen = V[np.arange(N), Y]

    # calculate the log-likelihood using the formula LL = sum(Vchosen - log(sum(exp(V))))
    return -np.sum(Vchosen - denom)

def mnl_fit(X, Zdist, Zprice, Y, J=4):
    Jm1 = J-1 # number of non-outside options
    N, Kx = X.shape # dimensions of X
    x0 = np.zeros(Kx*(Jm1) + 2) # starting values for optimization

    # optimization process, using BFGS to minimize the negative ll function
    res = sp.optimize.minimize(
        mnl_mle,
        x0,
        args = (X, Zdist, Zprice, Y, J),
        method = "BFGS"
    )

    # recover parameter estimates and standard errors from optimization results
    b_hat = res.x
    se = np.sqrt(np.diag(res.hess_inv))

    # return parameter estimates, standard errors, and optimization results
    return b_hat, se, res

