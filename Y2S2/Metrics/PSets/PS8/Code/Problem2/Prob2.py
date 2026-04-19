import numpy as np
import scipy as sp
import pandas as pd
from scipy.special import logsumexp
from scipy.optimize import minimize
from prettytable import PrettyTable

"""
This file will estimate a forward looking discrete choice model using GMM. 
    Libraries used:
        - numpy: for numerical operations
        - scipy: for optimization and special functions
        - pandas: for data manipulation
        - prettytable: for displaying results in a nice format
"""

df = sp.io.loadmat('../../Data/Problem2/dataHW8_Problem2.mat')
print(df.keys())

df['k'] = np.asarray(df['K_data'])
df['y'] = np.asarray(df['L_data']).ravel()
df['w'] = np.asarray(df['Wobs_data'])

k = np.maximum(df['k'], 0)
y = df['y']
w = np.maximum(df['w'], 0)

b = np.concatenate([
    [2.0, 0.5],
    np.zeros(4),
    np.zeros(5*4)
])
#============================#
# Problem 2a: Moment Creation#
#============================#

from Prob2a import *

m = gmm_moments(np.zeros(5), k, y, w)

moment_table = PrettyTable()
moment_table.field_names = ["Moment", "Value"]
moment_names = [
    "Mean Assets Today",
    "Mean Assets Tomorrow",
    "Asset Dispersion Tomorrow",
    "Fraction with Zero Assets Tomorrow",
    "Mean Savings",
    "Mean Labor Supply Today",
    "Mean Labor Supply Tomorrow",
    # "Mean Wage Today",        # commented out
    # "Mean Wage Tomorrow",     # commented out
    # "Wage Dispersion Today",  # commented out
    # "Correlation of Wages Today and Tomorrow",  # commented out
    "Correlation of Assets and Wages Today",
    "LFP for High Earners Tomorrow"
]
for i in range(len(m)):
    moment_table.add_row([moment_names[i], round(m[i], 4)])
print(moment_table)

#========================================#
# Problem 2b: Simulate data              #
# using actual values and see            #
# if simulated moments match data moments#
#========================================#

from Prob2b import *

w_sim, k_sim, y_sim = sim_moments(b, k, y, w)

m_sim = gmm_moments(np.zeros(5), k_sim, y_sim, w_sim)

diff_table = PrettyTable()
diff_table.field_names = ["Moment", "Data Moment", "Simulated Moment", "Difference"]
for i in range(len(m)):
    diff_table.add_row([moment_names[i], round(m[i], 4), round(m_sim[i], 4), round(m[i] - m_sim[i], 4)])
print(diff_table)   

#===========================================#
# Problem 2c: Estimate parameters using SMM #
#===========================================#

from Prob2c import *

# Bootstrapping IW Matrix
N_b = 50
m_b = np.zeros((N_b, len(m)))

for i in range(N_b):
    w_b, k_b, y_b = sim_moments(b, k, y, w)
    m_b[i] = gmm_moments(b, k_b, y_b, w_b)

W = np.linalg.inv(np.cov(m_b.T) + 1e-6*np.eye(len(m)))


print(W.shape, m.shape)

res_SMM = minimize(
    log_smm_moments,
    b,
    args=(m, W, k, y, w),   # no m_sim
    method="Nelder-Mead"
)

print(res_SMM.success)
print(res_SMM.message)
print(res_SMM.fun)      # objective value at solution
print(res_SMM.nit)      # number of iterations — if 0 or 1, it didn't really run
b_smm = res_SMM.x

smm_table = PrettyTable()
smm_table.field_names = ["Parameter", "Estimate"]

param_names = ["b", "g"] + [f"delta_{i}" for i in range(4)] + [f"Sigma_{i}" for i in range(5*4)]
for i in range(len(b_smm)):
    smm_table.add_row([param_names[i], round(b_smm[i], 4)])
print(smm_table)


