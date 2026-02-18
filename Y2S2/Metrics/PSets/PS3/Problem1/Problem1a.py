import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import logsumexp

"""
Helper file to estimate the multinomial logit without GPA as a characteristic.

Functions:
    - mnl_mle: Calculates maximum likelihood estimation for multinomial logit
    - mnl_fit: Minimizes the log likelihood estimated in the function above, returning parameters, s.e.
"""

def mnl_mle(b, X, Zdist, Zprice, Y, J):
    N, xK = X.shape # dimensions definition
    Jm1 = J-1 # use only 3 choices

    b = np.array(b).ravel() # parameter vector

    B = b[:xK*(Jm1)].reshape((xK, Jm1), order = "F") # defining shape of parameter vector for beta
    gamma_d = b[-1] # gamma on distance
    gamma_p = b[-2] # gamma on price

    V = np.zeros((N, J)) # starting V's = 0

    # looping over available choices
    for j in range(1, J):
        jj = j-1
        # utility
        V[:, j] = X@B[:,jj] + gamma_d*Zdist[:,j] + gamma_p*Zprice[:,j]
    denom = logsumexp(V, axis=1) # define denominator of likelihood
    Vchosen = V[np.arange(N), Y] # chosen values (size N, correspond to Y)
    ll = -np.sum(Vchosen-denom) # likelihood 
    return ll # return calculated log likelihood
 
def fit_mnl(X, Zdist, Zprice, Y, J):
    Jm1 = J-1
    N, Kx = X.shape
    x0 = np.zeros(Kx*(Jm1) + 2) # new starting values - from zeros to ones

    res = minimize(
        mnl_mle,
        x0,
        args = (X, Zdist, Zprice, Y, J),
        method = "BFGS"
    )

    b_hat = res.x
    se = np.sqrt(np.diag(res.hess_inv))

    return b_hat, se, res









    



