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

# Average Marginal Effect of Parent with a 4-yr College Degree (ξ_2)

logit_model = sm.Logit(Y, W) # Using canned estiamtion procedure, results match
logit_result  = logit_model.fit() # Reulsts

# Printing estimation results - match results from last part
print("\nModel Summary:") 
print(logit_result.summary())

# Printing marginal effect of whole sample
margeff = logit_result.get_margeff() # getting marginal effects
print("\nMarginal Effects Summary")
print(margeff.summary())

# Refining the Sample Space

mask = W[:,1] > 0
W_f = W[mask,:]
Y_f = Y[mask]

logit_1b = sm.Logit(Y_f, W_f)
logit_1b_results = logit_1b.fit()

print("\nModel Summary (1b):")
print(logit_1b_results.summary())

margeff_b = logit_1b_results.get_margeff()
print("\nMarginal Effects Summary")
print(margeff_b.summary())
