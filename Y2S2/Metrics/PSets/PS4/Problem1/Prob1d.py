import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import logsumexp

"""
Estimate mixed logit with five-point Gauss-Hermite quadrature to approx the integral over choice probabilities
"""

def GH_mle(b, X, Zprice, Y, J, nodes, weights, nu):
    N, xK = X.shape # dimensions of individuals and characteristics
    Jm1 = J-1 # number of choices minus outside option

    Q = nu.size # number of quadrature points

    b = np.array(b).ravel() # initializing the parameter vector

    B = b[:xK*Jm1].reshape((xK, Jm1), order="F") # beta on characteristics

    mu_gamma = b[xK*Jm1] # mean of gamma
    sigma_gamma = np.exp(b[xK*Jm1+1]) # standard deviation of gamma

    gamma = mu_gamma + sigma_gamma * nu # compute gamma for each quadrature point
    gamma = np.tile(gamma, (N,1)) # compute gamma for each individual and quadrature point

    V = np.zeros((N,J,Q)) # initialize value function array for each individual, choice, and quadrature point

    for j in range(1,J):
        V_random = Zprice[:,j][:, None]*gamma[None,:] # random component
        V_obs = X@B[:,j-1] # observed component
        V[:,j,:] = V_obs[:,None] + V_random # total value function


        Vmax = V.max(axis=1, keepdims=True)
        expV = np.exp(V - Vmax) # subtract max for numerical stability
        denom = expV.sum(axis=1, keepdims=True) # denominator for choice probabilities
        prob = expV / denom # choice probabilities for each choice and quadrature point

        P = np.sum(prob * weights[None,None,:], axis=2) # average over quadrature points using weights
        P_chosen = P[np.arange(N), Y] # probability of chosen option
        P_chosen = np.maximum(P_chosen, 1e-10) # avoid log(0) by clipping probabilities

        loglik = np.log(P_chosen).sum() # log-likelihood for the observed choices

    return -loglik

def GH_mix(X, Z, Y, J):
    N, xK = X.shape # dimensions of individuals and characteristics
    Jm1 = J-1 # number of choices minus outside option

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

    # Get the nodes and weights for 5-point Gauss-Hermite quadrature
    nodes, weights = np.polynomial.hermite.hermgauss(5) 

    nu = np.sqrt(2) * nodes  # scale the nodes for standard normal distribution
    norm_weights = weights / np.sqrt(np.pi) # normalize weights for standard normal distribution

    # initial parameter vector
    b0 = np.zeros(xK*Jm1 + 2)
    b0[xK*Jm1] = -0.1
    b0[xK*Jm1+1] = np.log(0.1)

    # minimization procedure
    res = minimize(
        GH_mle,
        b0,
        (X, Z, Y, J, nodes, norm_weights, nu),
        "BFGS",
        options={'gtol':1e-10, 'disp': True}
    )

    se = np.sqrt(np.diag(res.hess_inv)) # standard error calculation from inverse Hessian
    params = res.x  # estimated parameters from optimization

    return params, se, res

