import numpy as np
import scipy as sp
import pandas as pd
import datetime as dt

"""
Problem 1: Multinomial Choice Model with Y = {0, 1, 2} , X_i = (cons, BA, GPA), Z = price

    This file will be used to execute all assigned operations for Problem 1. Each question will have a dedicated file, and this file will be used to run all of those files in sequence.
    Helper Files:
        - Prob1a.py: Runs mixed logit estimtation
        - Prob1b.py: Calculates AME of having a parent with a BA on the Pr(Y=2)
        - Prob1c.py: Calculates S.E. of AME using parametric bootstrap, taking a draw from the joint distribution of the estimates
        - Prob1d.py: Redo (a) using Gauss-Hermite quadrature to approximate the integral in the likelihood function, and compare results to (a)

    Libraries Used:
        - numpy: for numerical operations and array handling
        - scipy: for optimization and statistical functions
        - pandas: for data manipulation and presentation
"""

# ============================ #
# Data Loading and Formatting  #
# ============================ #

df = sp.io.loadmat("dataHW4_Problem1.mat") # calling data

# Defining all variables for numpy as arrays
X = np.asarray(df["Xi"])  # NxK
Y = np.asarray(df["Y"]).astype(int).ravel() # Nx1
Z = np.asarray(df["Zprice"]) # NxJ


# ============================ #
# (A) Mixed Logit Estimation   #
# ============================ #

from Prob1a import *

b_hat, se, res = mix_opt(X, Z, Y, 3, 50) # calling the minimization function

b_hat[7] = np.exp(b_hat[7])

# creating results table
res_frame = pd.DataFrame({
    "β and γ Estimates": b_hat,
    "Std. Errors": se
})
print(res_frame) # outputting table (note: 6-7 are gamma_1, gamma_2)

# ============================ #
# (B) AME Calculation          #
# ============================ #

from Prob1b import *

AME = ame_mix(b_hat, X, Z, Y, 100, 3)
print(AME)

# ============================ #
# (C) S.E. of AME              #
# ============================ #

from Prob1c import *

cov_hat = res.hess_inv # covariance matrix from optimization results
se_boot, AME_boot = boot_ame(b_hat, cov_hat, X, Z, Y, R=100, J=3, seed=219) # calling bootstrap function
print(se_boot) # outputting standard error of AME from bootstrap

# ============================ #
# (D) Gauss-Hermite Quadrature #
# ============================ #

from Prob1d import *

b_hat_gh, se_gh, res_gh = GH_mix(X, Z, Y, 3, 5) # calling the GH protocol

# creating results table
res_frame_gh = pd.DataFrame({
    "β and γ Estimates (GH)": b_hat_gh,
    "Std. Errors (GH)": se_gh
})
print(res_frame_gh) # outputting table

