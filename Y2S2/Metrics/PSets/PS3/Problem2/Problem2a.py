import numpy as np
import scipy as sp
from scipy.special import logsumexp
from scipy.optimize import minimize
from numpy.random import default_rng

def mnp_nll(theta, X, Zdist, Y, J, R=300, lam=0.1, seed=219):
    # Multinomial Probit Negative Log Likelihood function
    N, K = X.shape # dimensions definition

    # unpacking parameters
    idx = 0 # index to keep track of position in theta
    beta1 = theta[idx:idx+K]; idx+=K # beta for choice 1 - from 0 - K
    beta2 = theta[idx:idx+K]; idx+=K # beta for choice 2 - from K - 2K
    gamma = float(theta[idx]); idx+=1 # gamma on distance - position 2K
    rho_raw = float(theta[idx]) # rho raw parameter - position 2K+1 (final parameter)

    rho= 1/ (1+np.exp(-rho_raw)) # transform rho to be in (0,1) using logistic function

    V = np.zeros((N,J)) # utility starts at 0 for all choices
    beta = {1:beta1, 2:beta2} # create a beta dictionary for easier access
    for j in range(1,J):
        V[:,j] = X@beta[j] + gamma * Zdist[:,j] # calculate utility for choices 1 to J-1 (choice 0 is the base and has utility 0)

    R = 300 # number of simulations
    rng = default_rng(219) # random number generator with seed for reproducibility

    z = rng.standard_normal(size=(R,N,2)) # simulate standard normal random variables for the error terms (size R x N x 2, where 2 corresponds to the two choices with random utility components)

    z1 = z[:,:,0] # error term for choice 1
    z2 = z[:,:,1] # error term for choice 2

    eta1 = z1 # error term for choice 1 is just z1
    eta2 = rho*z1 + np.sqrt(1-rho**2) * z2 # error term for choice 2 is a combination of z1 and z2, with correlation rho

    eta = np.stack([eta1, eta2], axis=2) # "stack" eta1 and eta2 to get array of error terms (R x N x 2)

    P = np.zeros((N,J)) # probability
    U = np.zeros((R,N,J)) # Utility

    for j in range(1,J):
        U[:,:,j] = V[:,j][None,:] + eta[:,:,j-1] # calculate utility for each choice and simulation (R x N x J)

    # AR method to calculate choice probabilities
    U_ar = U/lam # scale utility by lambda to control the variance of the error terms (R x N x J)
    w = np.exp(U_ar) # calculate the exponentiated utility (R x N x J)
    w = w / w.sum(axis=2, keepdims=True) # normalize to get probabilities for each choice and simulation (R x N x J)

    P = w.mean(axis=0) # average over simulations to get choice probabilities (N x J)

    P_chosen = P[np.arange(N),Y] # probability of the chosen alternatives (size N, correspond to Y)
    return -np.log(P_chosen).sum() # return negative log likelihood

def mnp_opt(X, Zdist, Y, J, R=300, lam=0.1, seed=219):
    # Optimization function to estimate parameters of the multinomial probit model
    N, K = X.shape # dimensions definition
    theta0 = np.zeros(2*K+2) # starting values for optimization (2*K for beta parameters, 1 for gamma, 1 for rho_raw)

    res = minimize(
        mnp_nll,
        theta0,
        args=(X,Zdist,Y,3,R,lam,seed),
        method="BFGS"
    )
    
    se = np.sqrt(np.diag(res.hess_inv)) # standard errors from the inverse of the hessian

    theta_hat = res.x # parameter estimates

    rho_raw_hat = theta_hat[2*K+1] # extract the estimated rho_raw parameter
    rho_hat = np.tanh(rho_raw_hat) # transform rho_raw to get the estimated rho (correlation between error terms)

    return theta_hat, se, rho_hat, res # return parameter estimates, standard errors, estimated rho, and optimization results

