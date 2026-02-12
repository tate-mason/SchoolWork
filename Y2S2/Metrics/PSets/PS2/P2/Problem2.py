import pandas as pd
import numpy as np
import scipy as sp
import scipy.optimize as op
import statsmodels.api as sm

"""
File for problem 2 of HW2 - Multinomial Logit
    Libraries:
        - Pandas: data work
        - Numpy: numerical operations
        - Scipy: optimization routines
        - Statsmodels.api: regression package
"""

# Loading in data
df = sp.io.loadmat('dataHW2_Problem2.mat')
print(df.keys())

# Making data workable
Xi = df["Xi"].squeeze()
Y = df["Y"].squeeze()
Zdist = df["Zdist"].squeeze()
Zprice = df["Zprice"].squeeze()

# Covariate matrix
W = np.column_stack((Xi, Zdist, Zprice))
W = np.column_stack([np.ones(W.shape[0]), W])

# Drop constant from xi
W = np.delete(W, 1, axis = 1)

#============================================================#
# (a) Multinomial Logit Regression                           #
#============================================================#

N, K = W.shape
J = int(Y.max() + 1)


