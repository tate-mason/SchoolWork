import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import logsumexp

"""
Helper file to calculate nested logit when X_3 is not present.

Functions:
    - _unpack_b: function to unpack the parameter vector into B, gamma_p, gamma_d, and lambda
    - nl_util: function to calculate the utility for each choice
    - nl_prob: function to calculate the choice probabilities using the nested logit formula
    - nl_nll: function to calculate the negative log likelihood for the nested logit model
    - nl_fit: function to minimize the negative log likelihood and return parameter estimates and standard errors
"""

def _unpack_b(b, X, J):
    # unpacking the parameter vector into B, gamma_p, gamma_d, and lambda
    b = np.asarray(b).ravel() # ensure b is a 1D array

    N, K = X.shape # dimensions definition
    Jm1 = J-1 # use only 3 choices

    nB = K*Jm1 # number of parameters for B

    B = b[:nB].reshape((K,Jm1), order="F") # reshape B to be K x (J-1)
    gamma_p = b[nB] # gamma on price
    gamma_d = b[nB+1] # gamma on distance
    lam_raw = b[nB+2] # lambda raw parameter (unbounded)

    lam_nest = 1 / (1+np.exp(-lam_raw)) # transform lambda to be in (0,1) using logistic function
    return B, gamma_p, gamma_d, lam_nest # return unpacked parameters

def nl_util(B, gamma_p, gamma_d, X, Zdist, Zprice, J):
    # calculate the utility for each choice
    N, K = X.shape # dimensions definition

    V = np.zeros((N,J)) # utility starts at 0 for all choices

    for j in range(1, J):
        V[:, j] = X@B[:,j-1] + gamma_d*Zdist[:,j] + gamma_p*Zprice[:,j] # calculate utility for choices 1 to J-1 (choice 0 is the base and has utility 0)
    return V

def nl_prob(V, lam_nest, nest_id=None):
    # calculate the choice probabilities using the nested logit formula

    if nest_id is None:
        nest_id = np.array([0,1,2,2], dtype=int) # default nesting structure: choice 0 in nest 0, choice 1 in nest 1, choices 2 and 3 in nest 2
    else:
        nest_id = np.asarray(nest_id, dtype=int) # ensure nest_id is an integer array

    N, J = V.shape # dimensions definition
    G = int(nest_id.max()+1) # number of nests is max nest_id + 1 (since nest_id starts at 0)

    lam = np.ones(G) # initialize lambda for each nest to 1 (no nesting)
    lam[2] = lam_nest # set lambda for nest 2 to the estimated lambda (nest 2 contains choices 2 and 3)
    lam_nest = np.clip(lam_nest, 0.0, 1.0) # ensure lambda is between 0 and 1

    IV = np.zeros((N,G)) # inclusive value
    for g in range(G):
        idx = np.where(nest_id==g)[0] # indices of choices in nest g
        IV[:,g] = logsumexp(V[:,idx] / lam[g], axis=1) # calculate inclusive value for each nest

    nest_num = IV * lam[None, :] # numerator of the nested logit probability for each nest
    nest_den = logsumexp(nest_num, axis=1, keepdims=True) # denominator of the nested logit probability (sum over nests)
    P_nest = np.exp(nest_num - nest_den) # probability of choosing each nest

    P = np.zeros((N,J)) # calculate choice probabilities for each alternative
    for g in range(G):
        idx = np.where(nest_id==g)[0] # indices of choices in nest g
        log_cond = (V[:,idx] / lam[g]) - logsumexp(V[:, idx] / lam[g], axis=1, keepdims=True) # log probability of choosing each alternative conditional on choosing nest g
        P[:,idx] = P_nest[:,[g]]*np.exp(log_cond) # multiply by probability of choosing nest g to get unconditional probability of choosing each alternative

    return np.clip(P, 0.0, 1.0) # ensure probabilities are between 0 and 1


def nl_nll(b, X, Zdist, Zprice, Y, J=4, nest_id=None):
    # calculate the negative log likelihood for the nested logit model
    Y = np.asarray(Y).astype(int).ravel() # ensure Y is a 1D integer array
    B, gamma_p, gamma_d, lam_nest = _unpack_b(b, X, J) # unpack parameters
    V = nl_util(B, gamma_p, gamma_d, X, Zdist, Zprice, J) # calculate utilities
    P = nl_prob(V, lam_nest, nest_id=nest_id) # calculate choice probabilities
    return -np.log(P[np.arange(Y.size), Y]).sum() # return negative log likelihood

def nl_fit(X, Zdist, Zprice, Y, J=4, nest_id=None):
    # minimize the negative log likelihood and return parameter estimates and standard errors
    N, K = X.shape # dimensions definition

    p = (J-1)*K + 3 # number of parameters: (J-1)*K for B, 1 for gamma_p, 1 for gamma_d, 1 for lambda
    x0 = np.zeros(p) # starting values for optimization (can be zeros or small random values)

    # minimize the negative log likelihood function defined above, using BFGS method
    res = minimize(
        nl_nll,
        x0,
        (X, Zdist, Zprice, Y, J, nest_id),
        "BFGS"
    )
    b_hat = res.x # parameter estimates
    se = np.sqrt(np.diag(res.hess_inv)) # standard errors from the inverse of the hessian

    # print optimization results
    return b_hat, se, res



