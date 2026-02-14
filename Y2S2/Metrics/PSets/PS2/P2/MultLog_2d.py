import numpy as np
import scipy as sp



def predict_prob(b, X, Zdist, Zprice, J):
    N, Kx = X.shape
    Jm1 = J-1

    b = np.asarray(b).ravel()

    B = b[:Kx*(Jm1)].reshape((Kx, Jm1), order="F")
    gamma_d = b[-2]
    gamma_p = b[-1]

    V = np.zeros((N, J))

    for j in range(1, J):
        jj = j-1
        V[:, j] = X @ B[:, jj] + gamma_d * Zdist[:,j] + gamma_p * Zprice[:,j]

    denom = sp.special.logsumexp(V, axis=1, keepdims=True)
    P = np.exp(V - denom)
    return P


def ame_mnl(b, X, Zdist, Zprice, Y, J, k, x1=1.0, x0=0.0):
    for j in range(2,J):
        X1 = X.copy()
        X0 = X.copy()

        X1[:, k] = x1
        X0[:, k] = x0


        P1 = predict_prob(b, X1, Zdist, Zprice, J)
        P0 = predict_prob(b, X0, Zdist, Zprice, J)

        return (P1[np.arange(Y.size), Y] - P0[np.arange(Y.size), Y]).mean()
