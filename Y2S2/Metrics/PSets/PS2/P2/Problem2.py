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

X = np.asarray(df["Xi"])
Zdist = np.asarray(df["Zdist"])
Zprice = np.asarray(df["Zprice"])
Y = np.asarray(df["Y"]).astype(int)

#============================================================#
# (a) Multinomial Logit Regression                           #
#============================================================#

from MultLog_2a import *

b_hat, se, res, meta = mnl_mle(X, Zdist, Zprice, Y)
print(meta)


