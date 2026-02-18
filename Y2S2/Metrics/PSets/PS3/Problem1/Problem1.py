import pandas as pd
import numpy as np
import scipy as sp

"""
Main file for Problem 1 of PS3. Estimating multinomial and nested logit + related std. errors.

Helper files:

Libraries used:

Functions:
"""

# ============================================= #
# Data Loading and Formatting                   #
# ============================================= #

df = sp.io.loadmat("dataHW3_Problem1.mat")
print(df.keys())

# Defining variables for Numpy (as arrays)

X = np.asarray(df["Xi"])
Y = np.asarray(df["Y"]).astype(int).ravel()
Zdist = np.asarray(df["Zdist"])
Zprice = np.asarray(df["Zprice"])

# ============================================= #
# (a) Multinomial Logit w/o X_3                 #
# ============================================= #

# Dropping X_3

X_filter = np.delete(X, 2, axis=1)

from Problem1a import * # importing the helper function

b_hat, se, res = fit_mnl(X_filter, Zdist, Zprice, Y, 4) # calling the minimization function

# creating results table
res_frame = pd.DataFrame({
    "β and γ Estimates": b_hat,
    "Std. Errors": se
})

# outputting table (note: 6-7 are gamma_1, gamma_2)
print(res_frame)

# ============================================= #
# (b) Nested Logit w/o X_3                      #
# ============================================= #

from Problem1b import * # importing the helper function

