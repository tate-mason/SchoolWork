import numpy as np
import scipy as sp

"""
File for MLE estimation of logit model. Contains:
    - log_NLLS: negative log-likelihood function for logistic regression
"""

def log_NLLS(b, X, Y, Z):
    mu = 1/(1 + np.exp(-X@b[:X.shape[1]] - Z@b[X.shape[1]:]))
    resid = Y - mu
    nlls = resid.T@resid
    return nlls


