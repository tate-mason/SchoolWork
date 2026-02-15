import numpy as np
import scipy as sp

"""
Helper file for calculating average predicted probabilities
    - avg_predict_prob: calculates the average predicted probabilities for each choice, given parameter vector b, data X, Zdist, Zprice, and choices J. Returns the average predicted probabilities across all individuals.
"""

def avg_predict_prob(b, X, Zdist, Zprice, Y, J):
    # define dimensions and reshape b (parameter vector) into B, gamma_d, and gamma_p
    N, Kx = X.shape
    Jm1 = J-1

    b = np.asarray(b).ravel()

    B = b[:Kx*(Jm1)].reshape((Kx, Jm1), order="F")
    gamma_d = b[-2]
    gamma_p = b[-1]

    # calculate V for each j, start at j=1
    V = np.zeros((N, J))

    for j in range(1, J):
        jj = j-1
        V[:, j] = X @ B[:, jj] + gamma_d * Zdist[:,j] + gamma_p * Zprice[:,j]

    denom = sp.special.logsumexp(V, axis=1, keepdims=True)
    P = np.exp(V - denom)
    # average predicted probabilities across all individuals for each choice
    return P.mean(axis=0)
