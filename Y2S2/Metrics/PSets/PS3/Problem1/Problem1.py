import pandas as pd
import numpy as np
import scipy as sp

"""
Main file for Problem 1 of PS3. Estimating multinomial and nested logit + related std. errors.

Helper files:
    - Problem1a.py: Multinomial logit estimation without X_3
    - Problem1b.py: Nested logit estimation without X_3
    - Problem1c.py: Delta method function for lambda
    - Problem1d.py: Multinomial logit estimation with X_3
    - Problem1e.py: Nested logit estimation with X_3 and delta method for lambda

Libraries used:
    - pandas: for data manipulation and results tables
    - numpy: for array manipulation and calculations
    - scipy: for loading .mat files and optimization in the helper

Functions:
    - fit_mnl: function to estimate multinomial logit model (in Problem1a.py and Problem1d.py)
    - nl_fit: function to estimate nested logit model (in Problem1b.py and Problem1e.py)
    - delta_lambda: function to calculate lambda and its standard error using the delta method (in Problem1c.py)
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

b_hat_nl, se_nl, res_nl = nl_fit(X_filter, Zdist, Zprice, Y, 4) # calling the minimization function

# creating results table
res_frame_nl = pd.DataFrame({
    "β, γ, λ Estimates:": b_hat_nl,
    "Std. Errors:": se_nl
})

print(res_frame_nl) # outputting table (note: 6-7 are gamma_1, gamma_2, 8 is lambda)


# ============================================= #
# (c) Delta Method for λ                        #
# ============================================= #

from Problem1c import * # importing the delta method function

cov = np.asarray(res_nl.hess_inv) # covariance of the estimates from the nested logit model

# calculating lambda and its standard error using the delta method
lam_hat, se_lam = delta_lambda( 
    b_hat_nl,
    cov
)

print(lam_hat, se_lam) # outputting lambda and its standard error

# ============================================= #
# (d) Multinomial Logit w/ X_3                  #
# ============================================= #

b_hat_d, se_d, res = fit_mnl(X, Zdist, Zprice, Y, 4) # calling the minimization function with X_3 included

# creating results table
res_frame_d = pd.DataFrame({ 
    "β and γ Estimates:": b_hat_d,
    "Std. Errors": se_d
})

print(res_frame_d) # outputting table (note: 6-7 are gamma_1, gamma_2)

# ============================================= #
# (e) Nested Logit w/ X_3                       #
# ============================================= #

b_hat_e, se_e, res_e = nl_fit(X, Zdist, Zprice, Y, 4) # calling the minimization function with X_3 included

# creating results table
res_frame_e = pd.DataFrame({
    "β, γ, λ Estimates:": b_hat_e,
    "Std. Errors": se_e
})

print(res_frame_e) # outputting table (note: 6-7 are gamma_1, gamma_2, 8 is lambda)

# Delta method for lambda with X_3 included
cov_e = np.asarray(res_e.hess_inv)
lam_hat_e, se_lam_e = delta_lambda(
    b_hat_e,
    cov_e
)

print(lam_hat_e, se_lam_e) # outputting lambda and its standard error with X_3 included

