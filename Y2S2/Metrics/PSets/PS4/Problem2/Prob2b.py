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
    N, T = Y.shape

    v1 = X @ b + g * Z.squeeze()
    v2 = v1 + d

    p1 = expit(v1)
    p2 = expit(v2)

    p1 = np.clip(p1, 1e-10, 1-1e-10)
    p2 = np.clip(p2, 1e-10, 1-1e-10)

    sumY = Y.sum(axis=1)

    ll1 = sumY * np.log(p1) + (T - sumY) * np.log(1 - p1)
    ll2 = sumY * np.log(p2) + (T - sumY) * np.log(1 - p2)

    pi1 = 1 - pi2

    a1 = np.log(pi1) + ll1
    a2 = np.log(pi2) + ll2

    m = np.maximum(a1, a2)
    denom = np.exp(a1-m) + np.exp(a2-m)

    q = np.exp(a2 - m) / denom

    ll_obs = np.sum(m + np.log(denom))

    return q, ll_obs

def m_obj(b, X, Z, Y, q):
    N, T = Y.shape
    xK = X.shape[1]

    beta = b[:xK]
    gamma = b[xK]
    delta = b[xK+1]

    v1 = X @ beta + gamma * Z.squeeze()
    v2 = v1 + delta

    p1 = expit(v1)
    p2 = expit(v2)

    p1 = np.clip(p1, 1e-10, 1-1e-10)
    p2 = np.clip(p2, 1e-10, 1-1e-10)

    sumY = Y.sum(axis=1)

    ll1 = sumY * np.log(p1) + (T - sumY) * np.log(1 - p1)
    ll2 = sumY * np.log(p2) + (T - sumY) * np.log(1 - p2)

    Q = np.sum((1-q)*ll1 + q*ll2)
    return -Q

def em_algorithm(X, Z, Y, b0, g0, d0, pi20, tol=1e-10, max_iter=1000):
    b = b0.copy()
    g, d, pi2 = g0, d0, pi20

    ll_iter = []

    q, ll_obs = em_step(X, Z, Y, b, g, d, pi2)
    ll_iter.append(ll_obs)

    for i in range(max_iter):
        b0 = np.append(b, [g, d])
        res = minimize(m_obj, b0, args=(X, Z, Y, q), method='BFGS')

        xK = X.shape[1]

        b = res.x[:xK]
        g = res.x[xK]
        d = res.x[xK+1]
        pi2 = np.clip(q.mean(), 1e-10, 1-1e-10)

        q, ll_obs = em_step(X, Z, Y, b, g, d, pi2)
        ll_iter.append(ll_obs)

        if abs(ll_iter[-1] - ll_iter[-2]) < tol:
            break
    return b, g, d, pi2, np.array(ll_iter)

