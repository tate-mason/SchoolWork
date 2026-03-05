import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import logsumexp

"""
Estimate mixed logit with five-point Gauss-Hermite quadrature to approx the integral over choice probabilities
"""

def GH_mle(b, X, Zprice, Y, J, nodes, weights, nu):
    N, xK = X.shape # dimensions of individuals and characteristics
    Jm1 = J-1

    Q = nu.size

    b = np.array(b).ravel()

    B = b[:xK*Jm1].reshape((xK, Jm1), order="F")

    mu_gamma = b[xK*Jm1]
    sigma_gamma = np.exp(b[xK*Jm1+1])

    gamma = mu_gamma + sigma_gamma * nu
    gamma = np.tile(gamma, (N,1))

    V = np.zeros((N,J,Q))

    for j in range(1,J):
        V_random = Zprice[:,j][:, None]*gamma[None,:]
        V_obs = X@B[:,j-1]
        V[:,j,:] = V_obs[:,None] + V_random


        Vmax = V.max(axis=1, keepdims=True)
        expV = np.exp(V - Vmax)
        denom = expV.sum(axis=1, keepdims=True)
        prob = expV / denom

        P = np.sum(prob * weights[None,None,:], axis=2)
        P_chosen = P[np.arange(N), Y]
        P_chosen = np.maximum(P_chosen, 1e-10)

        loglik = np.log(P_chosen).sum()

    return -loglik

def GH_mix(X, Z, Y, J):
    N, xK = X.shape # dimensions of individuals and characteristics
    Jm1 = J-1

    """
    For Q=5, the points and weights are:
    points:
        -0.202
        -0.958
        0
        0.202
        0.958
    weights:
        0.019953242
        0.393619323
        0.945308720
        0.393619323
        0.019953242
    """

    nodes, weights = np.polynomial.hermite.hermgauss(5)

    nu = np.sqrt(2) * nodes
    norm_weights = weights / np.sqrt(np.pi)

    b0 = np.zeros(xK*Jm1 + 2)
    b0[xK*Jm1] = -0.1
    b0[xK*Jm1+1] = np.log(0.1)

    res = minimize(
        GH_mle,
        b0,
        (X, Z, Y, J, nodes, norm_weights, nu),
        "BFGS",
        options={'gtol':1e-10, 'disp': True}
    )

    se = np.sqrt(np.diag(res.hess_inv))
    params = res.x

    return params, se, res

