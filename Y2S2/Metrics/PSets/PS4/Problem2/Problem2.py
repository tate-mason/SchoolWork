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
Y = np.asarray(df["Y"]).astype(int).ravel() # Nx1
Z = np.asarray(df["Zprice"]) # NxJ

# ============================ #
# (A) Panel Logit Estimation    #
# ============================ #

from Prob2a import *

b_hat, se, res = panel_log(X, Z, Y)
