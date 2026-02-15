import numpy as np
import scipy as sp

"""
Helper function for multinomial logit:
    - predict_prob: calculates the predicted probabilities for each choice, given parameter vector b, data X, Zdist, Zprice, and choices J
    - ame_mnl: calculates the average marginal effect of changing a variable in X, parentBA, from x0 to x1, given the same inputs as above, and the index k of parentBA. Returns the average marginal effect across all individuals.
"""


def predict_prob(b, X, Zdist, Zprice, J):
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
    # calculate predicted probabilities using the formula P_ij = exp(V_ij) / sum(exp(V_i))
    P = np.exp(V - denom)
    return P


def ame_mnl(b, X, Zdist, Zprice, Y, J, k, x1=1.0, x0=0.0):
    # calculate AME of changing parentBA from x0 to x1. Create two copies of X, calculate predicted probs for each copy, and take differences in predicted probabilities for the chosen alternative. Then average across individuals.
    # create copies of X for x1 and x0
    X1 = X.copy()
    X0 = X.copy()

    # change the k-th column of X1 to x1, and the k-th column of X0 to x0
    X1[:, k] = x1
    X0[:, k] = x0

    # calculate predicted probabilities for each copy of X, and take differences in predicted probabilities for the chosen alternative (Y_2 + Y_3). Then average across individuals.
    P1 = predict_prob(b, X1, Zdist, Zprice, J)
    P0 = predict_prob(b, X0, Zdist, Zprice, J)
    return ((P1[:,2] + P1[:, 3]) - (P0[:,2] + P0[:,3])).mean()

