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

    Q = len(nodes)

    b = np.array(b).ravel()

    B = b[:xK*Jm1].reshape((xK, Jm1), order="F")

    mu_gamma = b[xK*Jm1]
    sigma_gamma = np.exp(b[xK*Jm1+1])

    gamma_nodes = mu_gamma + sigma_gamma * nu.flatten()
    gamma = np.tile(gamma_nodes, (N,1))

    V = np.zeros((N,J,Q))

    for j in range(1,J):
        V_random = gamma*Zprice[:,j:j+1]
        V_obs = X@B[:,j-1]
        V[:,j,:] = V_obs[:,None] + V_random


    Vmax = V.max(axis=2, keepdims=True)
    expV = np.exp(V - Vmax)
    denom = expV.sum(axis=2, keepdims=True)
    prob = expV / denom
    prob = prob * weights[None, None, :]

    P_chosen = prob.sum(axis=2)
    P_chosen = P_chosen[np.arange(N), Y]
    P_y = np.maximum(P_chosen, 1e-12)

    loglik = np.sum(np.log(P_y))

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
    nodes = np.array([-2.020182870456085, -0.958572464613819, 0, 0.958572464613819, 2.020182870456085])
    weights = np.array([0.019953242, 0.393619323, 0.945308720, 0.393619323, 0.019953242])

    nu = np.sqrt(2) * nodes
    norm_weights = weights / np.sqrt(np.pi)

    b0 = np.zeros(xK*Jm1 + 2)

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

