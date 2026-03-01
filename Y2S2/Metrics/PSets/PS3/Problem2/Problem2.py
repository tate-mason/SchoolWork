import numpy as np
from scipy.io import loadmat
import scipy as sp
import pandas as pd

"""
Main file for Problem 2 of PS3. Estimating multinomial probit + related std. errors.

    Helper files:
    - Problem2a.py: Multinomial probit estimation

    Libraries used:
    - pandas: for data manipulation and results table
    - numpy: for array manipulation and calculations
    - scipy: for loading .mat files and optimization in the helper

    Functions:
    - mnp_opt: function to estimate multinomial probit model (in Problem2a.py)
"""

df = loadmat("dataHW3_Problem2.mat") # loading data

X = np.asarray(df["Xi"]) # defining X as the array of characteristics (size N x K)
Z = np.asarray(df["Zdist"]) # defining Z as the array of distance (size N x J)
Y = np.asarray(df["Y"]).ravel() # defining Y as the array of choices (size N, with values in {0,1,2})

# ==================================== #
# (a) Multinomial Probit               #
# ==================================== #

from Problem2a import * # importing the helper function

beta_hat, se, rho_hat, res = mnp_opt(X, Z, Y, 3, 300, 0.1, 219) # calling the minimization function

rho_hat= 1/ (1+np.exp(-rho_hat)) # transform rho to be in (0,1) using logistic function

param_full = np.append(beta_hat, rho_hat) # append rho to the beta estimates for easier table creation
se_full = np.append(se, np.nan)

# creating results table
res_frame = pd.DataFrame({
    "β, γ, ρ Estimates": param_full,
    "Std. Errors": se_full # standard error for rho is not calculated here - set to NaN
})

print(res_frame) # outputting table (note: 8 is rho)
