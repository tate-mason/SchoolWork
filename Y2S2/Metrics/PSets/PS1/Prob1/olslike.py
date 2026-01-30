import numpy as np

"""
    This file serves to translate ```olslike.m``` to Python. We will define the function olslike
    which takes inputs b, Y, X.
"""

def olslike(b, Y, X):
    K = X.shape[1] # equivalent to size
    beta = b[:K]
    s = b[K]

    e = Y - X@beta

    log_likelihood = -0.5*np.log(2*np.pi) - 0.5*np.log(s) - 0.5*(e**2)/s

    like = -np.sum(log_likelihood)

    return like
