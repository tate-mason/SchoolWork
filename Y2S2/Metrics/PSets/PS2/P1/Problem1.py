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
        - AME_1b.py: computes avg. marginal effects
        - Delta_1c.py: performs delta method to get s.e. of ame
        - Boot_1d.py: bootstrap
        - Probit_1e.py: estimation of probit
        - Probit_AME_1f.py: ame for probit estimates
    Functions:
"""

#==========================================================#
# (a) Logit Model of College Choice                        #
#==========================================================#

# Load in data from .csv provided

data = pd.read_csv(
    "HW2_P1.csv",
    header=None,
    names=["attend4yr", "v2", "parentBA", "GPA", "dist4yr_minus_dist2yr"]
)
data = data.drop(columns=["v2"], errors="ignore") # drop column 2
print(data.columns) # check 

Xcols = ["parentBA", "GPA", "dist4yr_minus_dist2yr"] # covariate vector
W = data[Xcols].to_numpy()
W = np.column_stack([np.ones(W.shape[0]), W]) # compile into covariate matrix
Y = data["attend4yr"].to_numpy() # numpy outcome vector (usable for numeric operation)


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

beta_hat = res["β_hat"] # def beta_hat

se_delta = delta(beta_hat, W, Y)

res["Std. Error (Delta)"] = se_delta # save results to table
print(res) # print table

#==========================================================#
# (d) Delta Method Bootstrap S.E.                          #
#==========================================================#

from Boot_1d import *

# optimize
def fit_beta(W, Y):
    b0 = np.zeros(W.shape[1])
    beta_hat, _, res = fit_logit_mle(W, Y, b0)
    return beta_hat

# bootstrap procedure
k_parent = 1 # variable of interest

boot_se_delta, draws = boot_se_AME(W, Y, fit_beta, k_parent, 500, 219) # calling function
res["Bootstrap S.E."] = boot_se_delta # saving result
print(res) # print results

#==========================================================#
# (e) Probit Estimation                                    #
#==========================================================#

from Probit_1e import *

# starting value
b0 = np.zeros(W.shape[1])

# minimize probit
res_prob = op.minimize(
    probit_est,
    b0,
    args = (W,Y),
    jac = grad_probit
)
# recover estimates
beta_hat_p = res_prob.x
hess = res_prob.hess_inv
se_p = np.sqrt(np.diag(hess))

# save to results table
res["β_hat Probit"] = beta_hat_p
res["S.E. Probit"]  = se_p

# view results
print(res)

#==========================================================#
# (f) Probit Estimation: AME                               #
#==========================================================#

from Probit_AME_1f import *

# parameter of interest
k_parent = 1

# call ame function
ame_probit = ame_probit(W, beta_hat_p, k_parent, 1.0, 0.0)

# save and view results
res["AME (Probit Model)"] = ame_probit
print(res)
