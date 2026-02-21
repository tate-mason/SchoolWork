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

b_hat_nl, se_nl, res_nl = nl_fit(X_filter, Zdist, Zprice, Y, 4)

res_frame_nl = pd.DataFrame({
    "β, γ, λ Estimates:": b_hat_nl,
    "Std. Errors:": se_nl
})

print(res_frame_nl)


# ============================================= #
# (c) Delta Method for λ                        #
# ============================================= #

from Problem1c import *

cov = np.asarray(res_nl.hess_inv)

lam_hat, se_lam = delta_lambda(
    b_hat_nl,
    cov
)

print(lam_hat, se_lam)

# ============================================= #
# (c) Multinomial Logit w/ X_3                  #
# ============================================= #

b_hat_c, se_c, res = fit_mnl(X, Zdist, Zprice, Y, 4)
res_frame_c = pd.DataFrame({
    "β and γ Estimates:": b_hat_c,
    "Std. Errors": se_c
})

print(res_frame_c)

# ============================================= #
# (d) Nested Logit w/ X_3                       #
# ============================================= #

b_hat_d, se_d, res_d = nl_fit(X, Zdist, Zprice, Y, 4)
res_frame_d = pd.DataFrame({
    "β, γ, λ Estimates:": b_hat_d,
    "Std. Errors": se_d
})

print(res_frame_d)

