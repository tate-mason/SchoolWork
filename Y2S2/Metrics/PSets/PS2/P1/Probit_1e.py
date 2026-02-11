import numpy as np
from scipy.stats import norm

def probit_est(beta, W, Y):
    z = W @ beta # define z
    ll = Y * norm.logcdf(z) + (1-Y)*norm.logsf(z) # log likelihood function for probit
    return -np.sum(ll) # minimize negative sum

def grad_probit(beta, W, Y):
    z = W @ beta # define z
    p = norm.cdf(z) # normal cdf
    pdf = norm.pdf(z) # normal pdf

    score = ((Y-p) * pdf / (p*(1-p)))[:,None]*W # score function
    return -score.sum(axis=0) # return negative sum of scores
