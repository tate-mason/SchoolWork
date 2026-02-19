import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import logsumexp

"""
Helper file to calculate nested logit when X_3 is not present.

Functions:
"""

def _unpack_b(b, X, J):
    b = np.asarray(b).ravel()

    N, K = X.shape
    Jm1 = J-1

    nB = K*Jm1

    B = b[:nB].reshape((K,Jm1), order="F")
    gamma_p = b[nB]
    gamma_d = b[nB+1]
    lam_raw = b[nB+2]

    lam_nest = 1 / (1+np.exp(-lam_raw))
    return B, gamma_p, gamma_d, lam_nest

def nl_util(B, gamma_p, gamma_d, X, Zdist, Zprice, J):
    N, K = X.shape

    V = np.zeros((N,J))

    for j in range(1, J):
        V[:, j] = X@B[:,j-1] + gamma_d*Zdist[:,j] + gamma_p*Zprice[:,j]
    return V

def nl_prob(V, lam_nest, nest_id=None):

    if nest_id is None:
        nest_id = np.array([0,1,2,2], dtype=int)
    else:
        nest_id = np.asarray(nest_id, dtype=int)

    N, J = V.shape
    G = int(nest_id.max()+1)

    lam = np.ones(G)
    lam[2] = lam_nest

    IV = np.zeros((N,G)) # inclusive value
    for g in range(G):
        idx = np.where(nest_id==g)[0]
        IV[:,g] = logsumexp(V[:,idx] / lam[g], axis=1)

    nest_num = IV * lam[None, :]
    nest_den = logsumexp(nest_num, axis=1, keepdims=True)
    P_nest = np.exp(nest_num - nest_den)

    P = np.zeros((N,J))
    for g in range(G):
        idx = np.where(nest_id==g)[0]
        log_cond = (V[:,idx] / lam[g]) - logsumexp(V[:, idx] / lam[g], axis=1, keepdims=True)
        P[:,idx] = P_nest[:,[g]]*np.exp(log_cond)

    return np.clip(P, 0.0, 1.0)


def nl_nll(b, X, Zdist, Zprice, Y, J=4, nest_id=None):
    Y = np.asarray(Y).astype(int).ravel()
    B, gamma_p, gamma_d, lam_nest = _unpack_b(b, X, J)
    V = nl_util(B, gamma_p, gamma_d, X, Zdist, Zprice, J)
    P = nl_prob(V, lam_nest, nest_id=nest_id)
    return -np.log(P[np.arange(Y.size), Y]).sum()

def nl_fit(X, Zdist, Zprice, Y, J=4, nest_id=None):
    N, K = X.shape

    p = (J-1)*K + 3
    x0 = np.zeros(p)

    res = minimize(
        nl_nll,
        x0,
        (X, Zdist, Zprice, Y, J, nest_id),
        "BFGS"
    )
    b_hat = res.x
    se = np.sqrt(np.diag(res.hess_inv))

    return b_hat, se, res



