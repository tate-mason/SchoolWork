import pandas as pd
import numpy as np
import statsmodels.api as sm
import scipy as sp
from scipy.io import loadmat

"""
    This script serves to answer Problem 2 of PS1. Below, we will replicate the code found in ```dataHW1_Problem2.mat``` using Python. The goal is to perform the specified operations and transcribe what is done in MATLAB to Python.
    Functions:
    Libraries:
    - pandas: for data manipulation and analysis
    - numpy: for numerical operations
    - statsmodels: for statistical modeling
    - scipy: for scientific computing
    - scipy.io: for loading MATLAB files
    Helper Files:
    - MaxLik.py: contains the MLE function for maximum likelihood estimation
"""

# Loading in dataHW1_Problem2.mat
df = pd.read_csv("dataHW1_Problem2.csv") # reading in csv file created in DataCreate.py

Y = df['Y'].to_numpy() #naming Y
X = df[['X1', 'X2', 'X3', 'X4']].to_numpy() #naming X

print(Y.shape, X.shape)

N = Y.shape[0] # number of observations
K = X.shape[1] # number of predictors

# Part A: MLE Estimation using custom function
from MaxLik import * # import MLE function

# Defining initial guess "b_start"
b_start = np.zeros(K) # K betas

# Calling optimizer minimize from scipy
res = sp.optimize.minimize(
    MLE,
    b_start,
    args = (X, Y),
    method = "BFGS"
)

# Calling results and printing in DataFrame

beta_hat_MLE = res.x # recovering parameter estimates
vcov_MLE = res.hess_inv # recovering variance covariance matrix
se_MLE = np.sqrt(np.diag(vcov_MLE)) # standard errors

MLE_Results = pd.DataFrame({
    'β_hat_MLE': beta_hat_MLE,
    'se_MLE': se_MLE
})

print(MLE_Results)

########################################################################################################################################################

# Part B: NLS Estimation

from NLS_est import *

b_start_nls = np.zeros(K) # initial guess

res_NLS = sp.optimize.minimize(
    Res_NLS,
    b_start_nls,
    args = (X, Y),
    method = "BFGS"
)

beta_hat_NLS = res_NLS.x # recovering parameter estimates
hess_NLS = res.hess_inv # recovering the Hessian for later


print("NLS Estimates:")
NLS_Results = pd.DataFrame({
    'β_hat_NLS': beta_hat_NLS
}) # creating DataFrame of parameter estimates
print(NLS_Results)

########################################################################################################################################################

# Part C: Estimating Standard Errors via Wooldridge eq. 12.52

from SE_est_2c import *

# Call robust variance matrix function "rob_var_mat" from helper file:
se_2c = rob_var_mat(beta_hat_NLS, X, Y)

# Append result to NLS DataFrame from part (b)
NLS_Results['s.e. NLS (2c)'] = se_2c
print(NLS_Results)

########################################################################################################################################################

# Part D: Calculate Standard Errors via Wooldridge eq. 12.48
from SE_est_2d import*

# Call SE_est_2d.py function "calc_v_hat"

avar = calc_v_hat(beta_hat_NLS, hess_NLS, X, Y)
se_2d = np.sqrt(np.diag(avar)) # calculating standard errors

NLS_Results['s.e. NLS (2d)'] = se_2d # appending result to DataFrame
print(NLS_Results)

########################################################################################################################################################

# Part E: Calculate SE for NLS using 500 bootstrap iterations

from SE_est_2e import * # importing statistic function

se_boot = boot_se_NLS(Res_NLS, X, Y, beta_hat_NLS, B=500, seed=219) # call function from helper file with specified options

NLS_Results['s.e. NLS (2e)'] = se_boot # store results in our DataFrame
print(NLS_Results)

