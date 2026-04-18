import numpy as np
import scipy as sp
import pandas as pd
from scipy.special import logsumexp
from prettytable import PrettyTable

"""
This problem is concerned with using 3 methods to estimate a logit model:
    1. MLE
    2. NLLS
    3. MoM

Each method will have its own file and functions. The main file (this one) will call the functions from each method and compare results.

Libraries used:
    - numpy: for numerical operations
    - scipy: for optimization and special functions
    - pandas: for data manipulation
    - prettytable: for displaying results in a nice format
"""

df = sp.io.loadmat('../../Data/Problem1/dataHW8_Problem1.mat')

print(df.keys())

df["X"] = np.asarray(df["Xi"]) # (constant, parent graduated, GPA)
df["Y"] = np.asarray(df["Y"]).ravel() # (attend college (4 year) or not) ravel to make it 1D
df["Z"] = np.asarray(df["Z"]) # (dist to nearest 2Y college, dist to nearest 4Y college)

#============================#
# Problem 1a: MLE            #
#============================#

from Prob1a import *

Kx = df["X"].shape[1]
Kz = df["Z"].shape[1]

b0 = np.zeros(Kx*(3-1) + Kz) # starting values for optimization

res_MLE = sp.optimize.minimize(
    log_MLE,
    b0,
    args=(df["X"], df["Y"], df["Z"]),
    method="BFGS"
)
b_mle = res_MLE.x
se_mle = np.sqrt(np.diag(res_MLE.hess_inv))

res_table = PrettyTable()
res_table.field_names = ["Method", "β_hat", "Std. Error"]
for i in range(len(b_mle)):
    res_table.add_row(["MLE", round(b_mle[i], 4), round(se_mle[i], 4)])

print(res_table)

#============================#
# Problem 1b: NLLS           #
#============================#

from Prob1b import *

b0 = np.zeros(Kx + Kz) # starting values for optimization
res_NLLS = sp.optimize.minimize(
    log_NLLS,
    b0,
    args=(df["X"], df["Y"], df["Z"]),
    method="BFGS"
)
b_NLLS = res_NLLS.x
se_NLLS = np.sqrt(np.diag(res_NLLS.hess_inv))

res_table = PrettyTable()
res_table.field_names = ["Method", "β_hat", "Std. Error"]
for i in range(len(b_mle)):
    res_table.add_row(["NLLS", round(b_mle[i], 4), round(se_mle[i], 4)])

print(res_table)

#============================#
# Problem 1c: MoM            #
#============================#

from Prob1c import *

Kx = df["X"].shape[1]
Kz = df["Z"].shape[1]
J = 3

Y_encoded = np.eye(J)[df["Y"].astype(int)] 

b0 = np.zeros(Kx*(J-1) + Kz) # starting values for optimization

res_MoM = sp.optimize.minimize(
    log_moments,
    b0,
    args=(df["X"], Y_encoded, df["Z"]),
    method="BFGS"
)
b_MoM = res_MoM.x
se_MoM = np.sqrt(np.diag(res_MoM.hess_inv))

res_table = PrettyTable()
res_table.field_names = ["Method", "β_hat", "Std. Error"]
for i in range(len(b_mle)):
    res_table.add_row(["MoM", round(b_mle[i], 4), round(se_mle[i], 4)])

print(res_table)
