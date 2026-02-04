import numpy as np
import scipy as sp

"""
    Helper file to compute standard errors as in 12.48 of Wooldridge.
    - Calculate score analytically
    - Use minimize Hessian
"""

def calc_v_hat(b, hess, X, Y):
    N = X.shape[0] # dimension of N
    mu = np.exp(X@b) # def mu as given
    g = X*mu[:, None] # gradient of function
    u = Y - mu # def u
    s = (g.T@((u**2)[:,None]*g))
    A = hess # A = Hessian from NLS procedure
    avar = (A@s@A) # def avar
    return avar # return value
