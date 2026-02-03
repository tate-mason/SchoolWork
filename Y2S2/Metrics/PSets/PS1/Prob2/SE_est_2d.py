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
    g = 2*X*mu[:, None] # gradient of function
    u = Y - mu
    s = (g.T@((u**2)[:,None]*g))
    bhat = (s.T@s) # def middle term sum of scores
    A = hess
    avar = (A@bhat@A) # def avar
    return avar # return value
