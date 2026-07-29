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
    N, T     = Y.shape # number of individuals and time periods
    xK       = X.shape[1] # dimensions of individuals and characteristics
    beta     = b[:xK] # coefficients for the covariates
    gamma    = b[xK] # coefficient for Zdist
    delta    = b[xK+1] # coefficient for diff in log-odds
    logit_pi = b[xK+2] # log-odds for pi2

    pi2 = expit(logit_pi) # convert log-odds to probability
    pi1 = 1 - pi2 # probability for pi1

    v1 = X@beta + gamma*Z.squeeze() # linear predictor for pi1
    v2 = v1 + delta # linear predictor for pi2 with delta shift

    p1 = expit(v1) # convert linear predictor to probability for pi1
    p2 = expit(v2) # convert linear predictor to probability for pi2

    p1 = np.clip(p1, 1e-10, 1-1e-10) # avoid log(0) by clipping probabilities
    p2 = np.clip(p2, 1e-10, 1-1e-10) # avoid log(0) by clipping probabilities

    sumY = Y.sum(axis=1) # sum of successes for each individual across time periods

    ll1 = sumY * np.log(p1) + (T - sumY) * np.log(1 - p1) # log-likelihood for pi1
    ll2 = sumY * np.log(p2) + (T - sumY) * np.log(1 - p2) # log-likelihood for pi2

    # Combine log-likelihoods for both groups using logsumexp
    ll = logsumexp(
        np.column_stack([
            np.log(pi1) + ll1,
            np.log(pi2) + ll2
        ]), axis=1
    )

    return -ll.sum() # return negative log-likelihood for minimization


def panel_opt(X, Z, Y):
    xK = X.shape[1] # number of covariates

    b0 = np.zeros(xK + 3) # initial parameter vector
    b0[xK+1] = 1.0 # set initial value for delta to 1.0

    res = minimize(panel_log, b0, args=(X, Z, Y), method='BFGS') # optimization protocol

    b_hat = res.x # estimated parameters
    se = np.sqrt(np.diag(res.hess_inv)) # standard errors from the inverse Hessian

    pi2 = expit(b_hat[xK+2]) # standard error for pi2 using the delta method
    se_pi2 = se[xK+2] * pi2 * (1 - pi2) # standard error for pi2 using the delta method

    return b_hat, se, res, pi2, se_pi2 # return estimated values 
