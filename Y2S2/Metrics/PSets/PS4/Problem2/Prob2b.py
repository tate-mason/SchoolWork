import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import expit

"""
Using the EM algorithm to estimate the same model, comparing results to (a)
    Libraries used:
        - numpy for numerical manipulation
        - scipy for optimization and some statistical functions
    Functions:
        - em_step: performs one iteration of the EM algorithm, updating the parameter estimates based on the current estimates of the latent class probabilities
        - em_algorithm: runs the EM algorithm until convergence, returning the final parameter estimates and standard errors
"""

def em_step(X, Z, Y, b, g, d, pi2):
    N, T = Y.shape # number of individuals and time periods

    v1 = X @ b + g * Z.squeeze() # linear predictor for pi1
    v2 = v1 + d # linear predictor for pi2 with delta shift

    p1 = expit(v1) # convert linear predictor to probability for pi1
    p2 = expit(v2) # convert linear predictor to probability for pi2

    p1 = np.clip(p1, 1e-10, 1-1e-10) # avoid log(0) by clipping probabilities
    p2 = np.clip(p2, 1e-10, 1-1e-10) # avoid log(0) by clipping probabilities

    sumY = Y.sum(axis=1) # sum of successes for each individual across time periods

    ll1 = sumY * np.log(p1) + (T - sumY) * np.log(1 - p1) # log-likelihood for pi1
    ll2 = sumY * np.log(p2) + (T - sumY) * np.log(1 - p2) # log-likelihood for pi2

    pi1 = 1 - pi2 # probability for pi1

    a1 = np.log(pi1) + ll1 # log of the joint probability for class 1
    a2 = np.log(pi2) + ll2 # log of the joint probability for class 2
 
    m = np.maximum(a1, a2) # subtract the maximum
    denom = np.exp(a1-m) + np.exp(a2-m) # denominator for normalization

    q = np.exp(a2 - m) / denom # probability of being in class 2

    ll_obs = np.sum(m + np.log(denom)) # log-likelihood

    return q, ll_obs # return probabilities and log-likelihood for the observed data

def m_obj(b, X, Z, Y, q):
    N, T = Y.shape # number of individuals and time periods
    xK = X.shape[1]  # number of covariates
 
    beta = b[:xK] # coefficients for the covariates
    gamma = b[xK] # coefficient for Zdist
    delta = b[xK+1] # coefficient for diff in log-odds

    v1 = X @ beta + gamma * Z.squeeze() # linear predictor for pi1
    v2 = v1 + delta # linear predictor for pi2 with delta shift

    p1 = expit(v1) # convert linear predictor to probability for pi1
    p2 = expit(v2) # convert linear predictor to probability for pi2

    p1 = np.clip(p1, 1e-10, 1-1e-10) # avoid log(0) by clipping probabilities
    p2 = np.clip(p2, 1e-10, 1-1e-10) # avoid log(0) by clipping probabilities

    sumY = Y.sum(axis=1) # sum of successes for each individual across time periods

    ll1 = sumY * np.log(p1) + (T - sumY) * np.log(1 - p1) # log-likelihood for pi1
    ll2 = sumY * np.log(p2) + (T - sumY) * np.log(1 - p2) # log-likelihood for pi2

    Q = np.sum((1-q)*ll1 + q*ll2) # return negative Q for minimization
    return -Q

def em_algorithm(X, Z, Y, b0, g0, d0, pi20, tol=1e-10, max_iter=1000):
    b = b0.copy() # initialize parameters
    g, d, pi2 = g0, d0, pi20 # initialize parameters

    ll_iter = [] # list to store log-likelihood values for each iteration

    q, ll_obs = em_step(X, Z, Y, b, g, d, pi2) # initial E-step to compute initial log-likelihood
    ll_iter.append(ll_obs) # store initial log-likelihood

    # EM algorithm loop
    for i in range(max_iter):
        b0 = np.append(b, [g, d])  # create parameter vector for optimization
        res = minimize(m_obj, b0, args=(X, Z, Y, q), method='BFGS') # M step protocol

        xK = X.shape[1]  # number of covariates

        b = res.x[:xK]  # update beta coefficients
        g = res.x[xK]  # update gamma coefficient
        d = res.x[xK+1] # update delta coefficient
        pi2 = np.clip(q.mean(), 1e-10, 1-1e-10) # update pi2 with average of q

        q, ll_obs = em_step(X, Z, Y, b, g, d, pi2) # E step to compute log-likelihood with updated parameters
        ll_iter.append(ll_obs)  # store log-likelihood for this iteration

        # Check for convergence
        if abs(ll_iter[-1] - ll_iter[-2]) < tol:
            break
    return b, g, d, pi2, np.array(ll_iter)  # return final estimates and log-likelihood history 

