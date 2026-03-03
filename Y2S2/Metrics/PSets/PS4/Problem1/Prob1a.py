import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import logsumexp
import pandas as pd


"""
Problem 1a:
    This file estimates a mixed logit model using MLE. R=500 draws, 
    gamma ~ N(mu_gamma, sigma_gamma^2) for price coeff. Only random coefficient is on price. Y=0 is normalized to 0

    Libraries used:
        - numpy for numerical manipulation
        - scipy for optimization and logsumexp
        - pandas for data manipulation

    Functions:
        - mix_mle: computes the negative log-likelihood for the mixed logit model
        - mix_opt: optimizes the parameters using BFGS and returns the estimated parameters, standard errors, and optimization results
"""

def mix_mle(b, X, Zprice, Y, J, R, eta):
    N, xK = X.shape # (25000x1)
    Jm1 = J-1 # 2

    b = np.array(b).ravel() # initializing the parameter vector

    B = b[:xK*Jm1].reshape((xK,Jm1), order="F") # beta on characteristics

    mu_gamma = b[xK*Jm1]
    sigma_gamma = np.exp(b[xK*Jm1 + 1])

    gamma_p = mu_gamma + sigma_gamma*eta

    # starting values (20000x500x3)
    V = np.zeros((N,R,J))
    for j in range(1, J):
        # split into observed and random components
        V_obs = X@B[:,j-1] # X*Beta
        V_random = gamma_p*Zprice[:,j:j+1] # gamma * Zprice
        V[:,:,j] = V_obs[:,None] + V_random # value function
    denom = logsumexp(V, axis=2, keepdims=True)
    prob = V - denom # V - \sum(exp(V))
    P_chosen = prob[np.arange(N), :, Y] # probability of choosing Y
    P_avg = logsumexp(P_chosen, axis=1) - np.log(R) # averaging over iterations

    return -P_avg.sum()


def mix_opt(X, Zprice, Y, J, R):
    N, xK = X.shape # dimensions
    Jm1 = J-1 # choices
    b = np.zeros(Jm1*xK+2) # parameter guesses

    rng = np.random.default_rng(219) # seed
    eta = rng.standard_normal(size=(N,R)) # randomness in gamma

    # minimization procedure
    res = minimize(
        mix_mle,
        b,
        (X,Zprice,Y,J,R,eta),
        "BFGS"
    )

    se = np.sqrt(np.diag(res.hess_inv)) # standard error calculation

    params = res.x # calling parameter estimates

    return params, se, res
