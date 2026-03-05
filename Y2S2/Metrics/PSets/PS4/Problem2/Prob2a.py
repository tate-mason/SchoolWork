import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import logsumexp, expit

"""
Panel logit estimation using MLE

    Libraries used:
        - numpy for numerical manipulation
        - scipy for optimization and some statistical functions
    Functions:
        - panel_log: computes the negative log-likelihood for the panel logit model
        - panel_opt: optimizes the parameters using BFGS and returns the estimated parameters, standard errors, and pi2_hat
"""

def panel_log(b, X, Z, Y):
    N, T =  Y.shape
    xK = X.shape[1] # dimensions of individuals and characteristics
    beta = b[:xK]
    gamma = b[xK]
    delta = b[xK+1]
    logit_pi = b[xK+2]

    pi2 = expit(logit_pi)
    pi1 = 1 - pi2

    v1 = X@beta + gamma*Z.squeeze()
    v2 = v1 + delta

    p1 = expit(v1)
    p2 = expit(v2)

    p1 = np.clip(p1, 1e-10, 1-1e-10)
    p2 = np.clip(p2, 1e-10, 1-1e-10)

    sumY = Y.sum(axis=1)

    ll1 = sumY * np.log(p1) + (T - sumY) * np.log(1 - p1)
    ll2 = sumY * np.log(p2) + (T - sumY) * np.log(1 - p2)

    ll = logsumexp(
        np.column_stack([
            np.log(pi1) + ll1,
            np.log(pi2) + ll2
        ]), axis=1
    )

    return -ll.sum()


def panel_opt(X, Z, Y):
    xK = X.shape[1]

    b0 = np.zeros(xK + 3)
    b0[xK+1] = 1.0

    res = minimize(panel_log, b0, args=(X, Z, Y), method='BFGS')

    b_hat = res.x
    se = np.sqrt(np.diag(res.hess_inv))

    pi2 = expit(b_hat[xK+2])
    se_pi2 = se[xK+2] * pi2 * (1 - pi2)

    return b_hat, se, res, pi2, se_pi2
