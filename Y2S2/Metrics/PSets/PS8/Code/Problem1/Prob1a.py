import numpy as np
import scipy as sp

"""
Helper file to estimate logit via MLE. Contains:
    - log_MLE: log-likelihood function for multinomial logit model
"""

def log_MLE(beta, X, Y, Z):
    N, Kx = X.shape # dimensions definition
    Kz = Z.shape[1]
    J = 3 # number of choices (2Y, 4Y, no college)
    
    beta = np.array(beta).ravel() # parameter vector
    
    B = beta[:Kx*(J-1)].reshape((Kx, J-1), order="F") # defining shape of parameter vector for beta
    gamma = beta[-Kz:] # gamma on distance and price
    
    V = np.zeros((N, J)) # starting V's = 0
    
    # looping over available choices
    for j in range(1, J):
        jj = j-1
        # utility
        V[:, j] = X@B[:,jj] + Z[:,jj]*gamma[jj]
    
    denom = sp.special.logsumexp(V, axis=1) # define denominator of likelihood
    Vchosen = V[np.arange(N), Y] # chosen values (size N, correspond to Y)
    
    ll = -np.sum(Vchosen - denom) # likelihood 
    return ll # return calculated log likelihood
