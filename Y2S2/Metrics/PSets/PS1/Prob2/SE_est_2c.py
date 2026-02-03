import numpy as np
import scipy as sp
"""
    Helper file to estimate the heteroskedastic-robust variance matrix for NLS as
    outlined in Wooldridge pg. 359.
"""
def rob_var_mat(b, X, Y):
    N = 5000
    mu = np.exp(X@b) # defining mu as given
    grad = X*mu[:,None] # defining gradient
    u = Y - X@b
    a0 = (grad.T@grad) # definition of A_0
    b0 = (grad.T@((u**2)[:,None]*grad)) # defining B_0
    a_inv = np.linalg.inv(a0) # inverse of A_0
    avar = (a_inv@b0@a_inv) # defining avar
    """
        avar = (A_0)^-1 * B_0 * (A_0)^-1
    """

    se = np.sqrt(np.diag(avar)) # computing s.e. from sqrt of diagonal of avar
    return se


