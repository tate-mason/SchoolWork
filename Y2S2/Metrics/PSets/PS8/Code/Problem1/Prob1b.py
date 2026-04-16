import numpy as np
import scipy as sp

"""
File for MLE estimation of logit model. Contains:
    - log_NLLS: negative log-likelihood function for logistic regression
"""

def log_NLLS(b, X, Y, Z):
    z = X @ b[:-2] + Z @ b[-2:] # linear predictor
    ll = Y*z - np.log1p(np.exp(z)) # log likelihood of logistic
    return -np.sum(ll) # minimize -sum
