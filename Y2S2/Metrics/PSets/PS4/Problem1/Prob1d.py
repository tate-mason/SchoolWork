import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import logsumexp

"""
Estimate mixed logit with five-point Gauss-Hermite quadrature to approx the integral over choice probabilities
"""

def GH_mle(b, X, Zprice, Y, J, nodes, weights):
    N, xK = X.shape # dimensions of individuals and characteristics
    Jm1 = J-1

    Q = len(nodes)

    b = np.array(b).ravel()

    B = b[:xK*Jm1].reshape((xK, Jm1), order="F")

    mu_gamma = b[xK*Jm1]
    sigma_gamma = np.exp(b[xK*Jm1+1])

    gamma_nodes = mu_gamma + sigma_gamma * nodes * np.sqrt(2)


    V = np.zeros((N,J,Q))

    for j in range(J):
        V_random = gamma_nodes[None,:]*Zprice[:,j:j+1]
        if j == 0:
            V[:,j,:] = V_random
        else:
            V_obs = X@B[:,j-1]
            V[:,j,:] = V_obs[:,None] + V_random
    denom = logsumexp(V, axis=1, keepdims=True)

    prob = V - denom

    chosen = np.exp(prob[np.arange(N), Y])
    integrated = chosen @ norm_weights
    loglik = np.log(integrated).sum()

    return -loglik

def GH_mix(X, Z, Y, J, Q=5):
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
    nodes, weights = np.polynomial.hermite.hermgauss(Q) # use quadrature function to get points and weights for 5pGH
    norm_weights = weights / np.sqrt(np.pi)

    b0 = np.zeros(xK*Jm1 + 2)

    res = minimize(
        GH_mle,
        b0,
        (X, Z, Y, J, nodes, norm_weights),
        "BFGS",
        options={'gtol':1e-10, 'disp': True}
    )

    se = np.sqrt(np.diag(res.hess_inv))
    params = res.x

    return params, se, res

