import numpy as np
import scipy as sp
import math

"""
Helper Function for MLE estimation - Problem 2A
    log-likelihood of Poisson distributed outcomes
"""

def MLE(beta, X, Y):
    mu = np.exp(X@beta) # poisson mean

    # log likelihood for Poisson
    ll = Y * np.log(mu) - mu - sp.special.gammaln(Y + 1)
    like = -np.sum(ll) # minimize negative sum

    return like # return likelihood
