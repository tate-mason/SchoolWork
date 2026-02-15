import numpy as np
import scipy as sp

"""
Helper function for multinomial logit, but with different starting values for optimization:
    - mnl_mle_b: calculates the -ll for the multinomial logit, give parameter vector b, data X, Zdist, Zprice, Y, and choices J
    - mnl_fit_b: uses the minimize function within Scipy to find the parameter estimates that minimize the negative ll, given the same inputs as above. Returns estimates, se, and results.
"""

def mnl_mle_b(b, X, Zdist, Zprice, Y, J):

    # define dimensions and reshape b (parameter vector) into B, gamma_d, and gamma_p
    N, Kx = X.shape
    Jm1 = J-1

    b = np.asarray(b).ravel()
    p_exp = Kx * Jm1 + 2 # parameter dimensions

    B = b[:Kx*(Jm1)].reshape((Kx, Jm1), order="F")
    gamma_d = b[-2]
    gamma_p = b[-1]

    # calculate V for each j, start at j=1 since the first column of B is normalized to zero (the outside option)
    V = np.zeros((N, J))

    for j in range(1, J):
        jj = j-1
        V[:, j] = X @ B[:, jj] + gamma_d * Zdist[:,j] + gamma_p * Zprice[:,j]

    denom = sp.special.logsumexp(V, axis=1)
    Vchosen = V[np.arange(N), Y]

    # calculate the log-likelihood using the formula LL = sum(Vchosen - log(sum(exp(V))))
    return -np.sum(Vchosen - denom)

def mnl_fit_b(X, Zdist, Zprice, Y, J=4):
    # same function as mnl_fit, but with different starting values for optimization. Instead of starting at zeros, we start at ones. This is to see if the optimization process converges to the same solution, or if it gets stuck in a local minimum.
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

