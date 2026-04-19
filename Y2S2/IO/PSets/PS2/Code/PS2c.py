import numpy as np
import scipy as sp
from scipy.special import expit
from scipy.optimize import minimize

def solve_eq(xW, xK, theta, eps=1e-6, max_iter=1000):
    betaW = theta[:xW.shape[0]]
    deltaW = theta[xW.shape[0]]

    betaK = theta[xW.shape[0]+1 : xW.shape[0] + 1 + xK.shape[0]]
    deltaK = theta[-1]

    PW, PK = 0.5, 0.5

    for _ in range(max_iter):
        PW_new = expit(xW@betaW + deltaW*PK)
        PK_new = expit(xK@betaK + deltaK*PW)

        if max(abs(np.log(PW_new / PW)), abs(np.log(PK_new / PK))) <= eps:
            return PW_new, PK_new
        PW, PK = PW_new, PK_new

    return PW, PK

def log_lik(theta, XW, XK, yW, yK):
    M = XW.shape[0]
    ll = 0.0

    for m in range(M):
        PW, PK = solve_eq(XW[m], XK[m], theta)

        PW = np.clip(PW, 1e-10, 1 - 1e-10) # to avoid log(0)
        PK = np.clip(PK, 1e-10, 1 - 1e-10) # to avoid log(0)

        ll += yW[m]*np.log(PW) + (1 - yW[m])*np.log(1 - PW)
        ll += yK[m]*np.log(PK) + (1 - yK[m])*np.log(1 - PK)
    return -ll



