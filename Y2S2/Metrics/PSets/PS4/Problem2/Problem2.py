import numpy as np
import scipy as sp
import pandas as pd

"""
Problem 2: Panel Logit estimation 
    This file will be used to execute all assigned operations for Problem 1. Each question will have a dedicated file, and this file will be used to run all of those files in sequence.
    Helper Files:
        - Prob2a.py: Runs panel logit estimation using MLE, recovering both type parameter and estimates of characteristics
        - Prob2b.py: Uses EM algorithm to estimate the same model, comparing results to (a)

    Libraries Used:
        - numpy: for numerical operations and array handling
        - scipy: for optimization and statistical functions
        - pandas: for data manipulation and presentation
"""

# ============================ #
# Data Loading and Formatting  #
# ============================ #

df = sp.io.loadmat("dataHW4_Problem2.mat") # calling data

# Defining all variables for numpy as arrays
X = np.asarray(df["Xi"])  # NxK
Y = np.asarray(df["Y"])
Z = np.asarray(df["Z1"]) # NxJ

# ============================ #
# (A) Panel Logit Estimation    #
# ============================ #

from Prob2a import *

b_hat, se, res, pi2, se_pi2 = panel_opt(X, Z, Y) # calling the minimization function

# creating results table
xK = X.shape[1]

estimates = np.append(b_hat[:xK], [b_hat[xK], b_hat[xK+1], pi2])
ses = np.append(se[:xK], [se[xK], se[xK+1], se_pi2])

names = [f"beta_{i}" for i in range(xK)] + ["gamma","delta","pi2"]

res_frame = pd.DataFrame({
    "Parameter": names,
    "Estimate": estimates,
    "Std. Error": ses
})
print(res_frame) # outputting table

# ============================ #
# (B) EM Algorithm Estimation  #
# ============================ #

from Prob2b import *

b0 = estimates[:xK]
g0 = estimates[xK]
d0 = estimates[xK+1]
pi20 = pi2

beta_em, gamma_em, delta_em, pi2_em, ll_iter = em_algorithm(X, Z, Y, b0, g0, d0, pi20)

# creating results table
names_em = [f"beta_{i}" for i in range(xK)] + ["gamma","delta","pi2"]
estimates_em = np.append(beta_em, [gamma_em, delta_em, pi2_em])
res_frame_em = pd.DataFrame({
    "Parameter": names_em,
    "EM Estimate": estimates_em
})
print(res_frame_em) # outputting table
