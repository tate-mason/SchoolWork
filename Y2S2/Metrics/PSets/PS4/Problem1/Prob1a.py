import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import logsumexp
import pandas as pd


"""
Problem 1a:
    This file estimates a mixed logit model using MLE. R=500 draws, 
    gamma ~ N(mu_gamma, sigma_gamma^2) for price coeff. Only random coefficient is on price. Y=0 is normalized to 0

    Functions:
"""

def mix_mle(b, X, Zprice, Y, J, R, eta):
    N, xK = X.shape # (25000x1)
    Jm1 = J-1 # 2

    b = np.array(b).ravel() # initializing the parameter vector

    B = b[:xK*Jm1].reshape((xK,Jm1), order="F") # beta on characteristics

    mu_gamma = b[xK*Jm1]
    sigma_gamma = np.log(np.exp(b[xK*Jm1 + 1]))

    gamma_p = mu_gamma + sigma_gamma*eta

    V = np.zeros((N,R,J))
    for j in range(1, J):
        V_obs = X@B[:,j-1]
        V_random = gamma_p*Zprice[:,j:j+1]
        V[:,:,j] = V_obs[:,None] + V_random
    denom = logsumexp(V, axis=2, keepdims=True)
    prob = V - denom
    P_chosen = prob[np.arange(N), :, Y]
    P_avg = logsumexp(P_chosen, axis=1) - np.log(R)

    return -P_avg.sum()


def mix_opt(X, Zprice, Y, J, R):
    N, xK = X.shape
    Jm1 = J-1
    b = np.zeros(Jm1*xK+2)

    rng = np.random.default_rng(219)
    eta = rng.standard_normal(size=(N,R))

    res = minimize(
        mix_mle,
        b,
        (X,Zprice,Y,J,R,eta),
        "BFGS"
    )

    se = np.sqrt(np.diag(res.hess_inv))

    params = res.x

    return params, se, res











