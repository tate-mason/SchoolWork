import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import logsumexp

"""
Helper file to calculate nested logit when X_3 is not present.

Functions:
"""

def nl_prob(b, l, X, Zdist, Zprice, Y, J):
    N, xK = X.shape
    b = np.array(b.ravel()) # parameter vector

    nest_id = np.array([0, 1, 2, 2])
    G = nest_id.max() + 1

    Jm1 = J-1

    B = b[:xK*(Jm1)].reshape((xK, Jm1), order="F")
    gamma_d = b[-1]
    gamma_p = b[-2]

    l0 = b[xK:(xK + G)]
    l = 1 / (1 + np.exp(-l0))
    l = np.clip(l, 0.0, 1.0)

    V = np.zeros((N, J))

    for g in range(G):
        idx = np.where(nest_id == g)[0] # iterations
        IV[:, g] = np.where(np.exp(V[:,idx] / l[g]).sum(axis=1)) # calculate inclusive value

    nest = np.exp(l * IV)
    P_nest = nest / nest.sum(axis=1, keepdims=True) # calculate probability of being in nest

    for g in range(G):
        idx = np.where(nest_id == g)[0]
        cond = np.exp(V[:,idx] / l[g])
        cond = cond / cond.sum(axis=1, keepdims=True)
        P[:, idx] = P_nest[:,[g]] * cond # Probability of being in a nest times condition of choosing option


def nl_mle(b, X, Zdist, Zprice, Y, nest_id):
    N, xK = X.shape
    b = np.array(b.ravel()) # parameter vector

    nest_id = np.array([0, 1, 2, 2])
    G = nest_id.max() + 1

    B = b[:xK*(Jm1)].reshape((xK, Jm1), order="F")
    gamma_d = b[-1]
    gamma_p = b[-2]

    l0 = b[xK:(xK + G)]
    l = 1 / (1 + np.exp(-l0))

    V = np.einsum('njk, k-> nj', X, B)
    P = nl_prob(V, l, nest_id)
    return -np.log(P[np.arange(len(Y)), Y]).sum()

def nl_opt(X, Zdist, Zprice, Y, J):
    nest_id = np.array([0,1,2,2])
    G = len(np.unique(nest_id))
    xK = X.shape

    b0 = np.zeros(xK*())

    res = minimize(
        nl_mle,
        b0,
        args = (X, Y, nest_id),
        method = "BFGS"
    )

    beta = res.x
    hess = res.hess_inv
    se = np.sqrt(np.diag(hess))

    return beta, se, res
