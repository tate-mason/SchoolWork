import scipy as sp
import numpy as np

"""
This file uses MoM to estimate the parameters of a logit discrete choice model. Contains:
    log_moments: moment function for logit model
"""

def log_moments(b, X, Y, Z):
    N, Kx = X.shape
    Kz = Z.shape[1]
    J = 3

    B = b[:Kx*(J-1)].reshape(Kx, J-1, order="F")
    gamma = b[Kx*(J-1):]

    V = np.zeros((N, J))
    for j in range(1, J):
        V[:, j] = X@B[:,j-1] + Z[:,j-1]*gamma[j-1]

    P = sp.special.softmax(V, axis=1)
    r = Y - P
    m = np.vstack((X.T @ r, Z.T @ r)).ravel()

    return m@m.T


