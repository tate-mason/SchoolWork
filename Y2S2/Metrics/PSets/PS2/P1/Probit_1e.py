import numpy as np
from scipy.stats import norm

def probit_est(beta, W, Y):
    z = W @ beta
    p = norm.cdf(z)
    ll = Y*p - np.log1p(np.exp(p))
    return -np.sum(ll)

def grad_probit(beta, W, Y):
    z = W @ beta
    p = norm.cdf(z)
    pdf = norm.pdf(z)

    score = ((Y-p) * pdf / (p*(1-p)))[:,None]*W
    return -score.sum(axis=0)
