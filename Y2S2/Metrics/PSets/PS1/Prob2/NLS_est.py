import numpy as np

"""
    helper function for getting residuals from given function
"""

# Defining residuals function
def Res_NLS(beta, X, Y):
    mu = np.exp(X@beta)
    r = Y - mu
    r2 = r.T@r
    return r2
