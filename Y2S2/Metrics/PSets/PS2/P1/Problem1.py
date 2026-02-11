import pandas as pd
import numpy as np
import scipy as sp
import scipy.optimize as op
import statsmodels.api as sm

"""
Master file for Problem 1 of Homework 2. In this problem, we will use work with a binary discrete choice framework to answer questions.
    Libraries:
        - Pandas: used for data manipulation
        - Numpy: used for numeric operations
        - Scipy: used for optimization methods
        - Statsmodels.api: Used for estimation methods
    Helper Files:
        - Logit_1a.py: defines logistic and log-likelihood
    Functions:
"""

#==========================================================#
# (a) Logit Model of College Choice                        #
#==========================================================#

# Load in data from .mat

data = sp.io.loadmat('dataHW2_Problem1.mat')
print(data.keys())

# Make data better to work with

Xi = data["Xi"].squeeze() 
Y  = data["Y"].squeeze()
Z  = data["Z"].squeeze()

W = np.column_stack((Xi,Z)) # Harmonizng x and z into one matrix
Y = np.asarray(Y).squeeze() # Making Y easier to work with


# Call Logit_1a functions
from Logit_1a import *

# Define starting values
b0 = np.zeros(W.shape[1])

# Optimization Routine

res = op.minimize(
    nll,
    b0,
    args = (W,Y)
)

beta_hat = res.x # Getting coefficients for xi
hess = res.hess_inv # Hessian for calculating SE
se_hat = np.sqrt(np.diag(hess)) # Calculating SE

# Save results to DataFrame
P1_res = pd.DataFrame({
    "β_hat": beta_hat,
    "Std. Error": se_hat
})

print(P1_res) # Display results

#==========================================================#
# (b) Calculate Avg. Marginal Effects                      #
#==========================================================#

k_x = Xi.shape[1] # Number of covariates + constant
k_z = Z.shape[1] # Number of choice attributes

x_names = ["const", "parent_college", "gpa"] + [f"x{i}" for j in range(3, k_x)] # name columns in data matrix
z_names = ["dist_2yr", "dist_4yr"] + [f"z{i}" for j in range(2, k_z)] # name columns in data matrix
colnames = x_names[:k_x] + z_names[:k_z] # Column names for results

W_df = pd.DataFrame(W, columns=colnames) # DataFrame for estimation results

from AME_1b import * # call helper

b0 = np.zeros(W.shape[1]) # vector of zeros for starting value

beta_hat, se_hat, res = fit_logit_mle(W, Y, b0) # call minimization routine from helper file

# create results table
res = pd.DataFrame({
    "Converged": res.success,
    "β_hat": beta_hat,
    "Std. Error": se_hat
})
# Average Marginal Effect of Parent with a 4-yr College Degree (β_2)

k_parent = 1 #define column of variable of interest 

ame_full = ame_dummy_discrete(beta_hat, W, k=k_parent, x1=1.0, x0=0.0) # call ame function from helper file
res["AME Parent College: Full"] = float(ame_full) # save to results table

# Subsample
mask = W[:, k_parent] == 1 # subset to k_parent
W_sub = W[mask,:]

ame_sub = ame_dummy_discrete(beta_hat, W_sub, k=k_parent, x1=1.0, x0=0.0) # call ame from helper
res["AME Parent College: Subsample"] = float(ame_sub) # add to results table

print(res) # print results

#==========================================================#
# (c) Delta Method to Get S.E. of AME                      #
#==========================================================#

from Delta_1c import *

beta_hat = res["β_hat"]

se_delta = delta_se(beta_hat, W, Y)

res["Std. Error (Delta)"] = se_delta
print(res)

#==========================================================#
# (d) Delta Method Bootstrap S.E.                          #
#==========================================================#

from Boot_1d import *

def fit_beta(W, Y):
    b0 = np.zeros(W.shape[1])
    beta_hat, _, res = fit_logit_mle(W, Y, b0)
    return beta_hat

k_parent = 1

boot_se_delta, draws = boot_se_AME(W, Y, fit_beta, k_parent, 500, 219)
res["Bootstrap S.E."] = boot_se_delta
print(res)

#==========================================================#
# (e) Probit Estimation                                    #
#==========================================================#

from Probit_1e import *

b0 = np.zeros(W.shape[1])

res_prob = op.minimize(
    probit_est,
    b0,
    args = (W,Y),
    jac = grad_probit
)
beta_hat_p = res_prob.x
hess = res_prob.hess_inv
se_p = np.sqrt(np.diag(hess))

res["β_hat Probit"] = beta_hat_p
res["S.E. Probit"]  = se_p

print(res)

#==========================================================#
# (f) Probit Estimation: AME                               #
#==========================================================#

from Probit_AME_1f import *

k_parent = 1

ame_probit = ame_probit(W, beta_hat_p, k_parent, 1.0, 0.0)

res["AME (Probit Model)"] = ame_probit
print(res)
