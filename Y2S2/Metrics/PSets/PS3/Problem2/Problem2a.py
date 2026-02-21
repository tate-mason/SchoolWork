import numpy as np
import scipy as sp
from scipy.special import logsumexp
from scipy.optimize import minimize
from numpy.random import default_rng

def mnp_nll(theta, X, Zdist, Y, J, R=300, lam=0.1, seed=219):
    N, K = X.shape

    # unpacking parameters
    idx = 0
    beta1 = theta[idx:idx+K]; idx+=K
    beta2 = theta[idx:idx+K]; idx+=K
    gamma = float(theta[idx]); idx+=1
    rho_raw = float(theta[idx])

    rho= 1/ (1+np.exp(-rho_raw))

    V = np.zeros((N,J))
    beta = {1:beta1, 2:beta2}
    for j in range(1,J):
        V[:,j] = X@beta[j] + gamma * Zdist[:,j]


    R = 300
    rng = default_rng(219)

    z = rng.standard_normal(size=(R,N,2))

    z1 = z[:,:,0]
    z2 = z[:,:,1]

    eta1 = z1
    eta2 = rho*z1 + np.sqrt(1-rho**2) * z2

    eta = np.stack([eta1, eta2], axis=2)

    P = np.zeros((N,J)) # probability
    U = np.zeros((R,N,J)) # Utility

    for j in range(1,J):
        U[:,:,j] = V[:,j][None,:] + eta[:,:,j-1]

    U_ar = U/lam
    w = np.exp(U_ar)
    w = w / w.sum(axis=2, keepdims=True)

    P = w.mean(axis=0)

    P_chosen = P[np.arange(N),Y]
    return -np.log(P_chosen).sum()

def mnp_opt(X, Zdist, Y, J, R=300, lam=0.1, seed=219):
    N, K = X.shape
    theta0 = np.zeros(2*K+2)

    res = minimize(
        mnp_nll,
        theta0,
        args=(X,Zdist,Y,3,R,lam,seed),
        method="BFGS"
    )
    
    se = np.sqrt(np.diag(res.hess_inv))

    theta_hat = res.x

    rho_raw_hat = theta_hat[2*K+1]
    rho_hat = np.tanh(rho_raw_hat)


    return theta_hat, se, rho_hat, res

