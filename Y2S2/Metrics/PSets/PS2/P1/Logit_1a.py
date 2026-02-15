import numpy as np
import scipy.optimize as op

# loglikelihood function
def nll(beta, W, Y):
    z = W @ beta
    ll = Y*z - np.log1p(np.exp(z)) # log likelihood of logistic
    return -np.sum(ll) # minimize -sum
