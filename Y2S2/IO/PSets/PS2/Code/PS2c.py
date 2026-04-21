import numpy as np
import scipy as sp
from scipy.special import expit
from scipy.optimize import minimize

def solve_eq(xW, xK, theta, eps=1e-6, max_iter=1000):

    betaW = theta[:xW.shape[1]] # Walmart coefficients
    deltaW = theta[xW.shape[0]] # Walmart's influence on KMart

    betaK = theta[xW.shape[0]+1 : xW.shape[0] + 1 + xK.shape[0]] # KMart coefficients
    deltaK = theta[-1] # KMart's influence on Walmart

    PW, PK = 0.5, 0.5 # initial guess

    for _ in range(max_iter):
        PW_new = expit(xW@betaW + deltaW*PK) # update PW based on current PK
        PK_new = expit(xK@betaK + deltaK*PW) # update PK based on current PW

        if max(abs(np.log(PW_new / PW)), abs(np.log(PK_new / PK))) <= eps:
            return PW_new, PK_new # convergence achieved
        PW, PK = PW_new, PK_new # update for next iteration

    return PW, PK # return last estimates if max iterations reached without convergence

def log_lik(theta, XW, XK, yW, yK):
    M = XW.shape[0] # number of markets
    ll = 0.0 # log-likelihood initialization

    for m in range(M):
        PW, PK = solve_eq(XW[m], XK[m], theta) # call above function to get PW and PK for market m
 
        PW = np.clip(PW, 1e-10, 1 - 1e-10) # to avoid log(0)
        PK = np.clip(PK, 1e-10, 1 - 1e-10) # to avoid log(0)

        ll += yW[m]*np.log(PW) + (1 - yW[m])*np.log(1 - PW) # log-likelihood contribution from Walmart
        ll += yK[m]*np.log(PK) + (1 - yK[m])*np.log(1 - PK) # log-likelihood contribution from KMart
    return -ll # return negative log-likelihood for minimization



