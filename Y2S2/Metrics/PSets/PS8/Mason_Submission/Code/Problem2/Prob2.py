import numpy as np
import scipy as sp
from scipy.optimize import minimize
from prettytable import PrettyTable

"""
This file estimates a two-period labor supply model with savings using SMM.
    Libraries used:
        - numpy: for numerical operations
        - scipy: for optimization and special functions
        - prettytable: for displaying results in a nice format
"""

# data loading and setup
df = sp.io.loadmat('../../Data/Problem2/dataHW8_Problem2.mat')
print(df.keys())

k = np.maximum(np.asarray(df['K_data']), 0.0) # assets (non-negative)
y = np.asarray(df['L_data']) # labor supply (0/1)
w = np.maximum(np.asarray(df['Wobs_data']), 0.0) # observed wage (0 if not working)

# true parameters (unconstrained)
b_true = np.array([
    0.0, 0.0, 0.0, 0.0,
    np.log(0.4), np.log(0.2), np.log(0.1),
    np.log(2.0), np.log(0.5)
])

# latex table saving function
import os
os.makedirs('../../Writeup/Tables', exist_ok=True)
def save_tex_table(latex_str, filename):
    with open(f'../../Writeup/Tables/{filename}.tex', 'w') as f:
        f.write(latex_str)

#============================#
# Problem 2a: Moment Creation#
#============================#

from Prob2a import gmm_moments

# compute data moments
m_data = gmm_moments(k, y, w)

# create table of data moments
moment_names = [
    "Mean Assets Period 1",
    "Mean Assets Period 2",
    "Std Assets Period 2",
    "Mean Savings (k2 - k1)",
    "LFP Period 1",
    "LFP Period 2",
    "Share w=0.50 Period 1",
    "Share w=0.75 Period 1",
    "Share w=1.00 Period 1",
    "Share w=1.50 Period 1",
    "Share w=2.00 Period 1",
    "Share w=0.50 Period 2",
    "Share w=0.75 Period 2",
    "Share w=1.00 Period 2",
    "Share w=1.50 Period 2",
    "Share w=2.00 Period 2",
    "LFP Period 2 | High Wage Period 1",
    "LFP Period 2 | Low Wage Period 1",
    "LFP Period 2 | Worked Period 1",
    "LFP Period 2 | Did Not Work Period 1",
    "Corr(k1, l1)",
]

# print data moments in table and save latex version
moment_table = PrettyTable()
moment_table.field_names = ["Moment", "Value"]
for i in range(len(m_data)):
    moment_table.add_row([moment_names[i], round(m_data[i], 4)])
print(moment_table)
save_tex_table(moment_table.get_latex_string(), "data_moments")

#========================================#
# Problem 2b: Simulate at true params    #
# and check simulated vs data moments    #
#========================================#

from Prob2b import sim_moments, unpack_params

# verify transforms recover true parameters before running anything
delta_c, rho1_c, rho2_c, rho3_c, beta_c, gamma_c, _ = unpack_params(b_true)
print(f"\nTransform check:")
print(f"  delta:            {np.round(delta_c, 4)}")
print(f"  rho1,rho2,rho3:   {rho1_c:.4f}, {rho2_c:.4f}, {rho3_c:.4f}")
print(f"  rho1+2rho2+2rho3: {rho1_c+2*rho2_c+2*rho3_c:.4f}  (should = 1)")
print(f"  beta, gamma:      {beta_c:.4f}, {gamma_c:.4f}")

# simulate moments at true parameters
w_sim, k_sim, y_sim = sim_moments(b_true)
# compute moments from simulated data
m_sim = gmm_moments(k_sim, y_sim, w_sim)

# create table comparing data vs simulated moments
diff_table = PrettyTable()
diff_table.field_names = ["Moment", "Data", "Simulated", "Difference"]
for i in range(len(m_data)):
    diff_table.add_row([moment_names[i], round(m_data[i], 4), round(m_sim[i], 4), round(m_data[i] - m_sim[i], 4)])
print(diff_table)
save_tex_table(diff_table.get_latex_string(), "data_vs_sim_moments")

#===========================================#
# Problem 2c: SMM estimation               #
#===========================================#

from Prob2c import smm_obj

# bootstrap W matrix using S=50 simulations around the true params
S = 50
m_boot = np.zeros((S, len(m_data)))
for s in range(S):
    rng_s     = np.random.default_rng(seed=s)
    b_perturb = b_true + rng_s.normal(0, 0.01, size=len(b_true))
    w_b, k_b, y_b = sim_moments(b_perturb)
    m_boot[s] = gmm_moments(k_b, y_b, w_b)

W = np.linalg.inv(np.cov(m_boot.T) + 1e-6 * np.eye(len(m_data)))

# run SMM estimation
res_SMM = minimize(
    smm_obj,
    b_true.copy(),
    args=(m_data, W),
    method='Nelder-Mead',
    options={'maxiter': 10000, 'xatol': 1e-4, 'fatol': 1e-4, 'disp': True}
)

# print results
print(res_SMM.success)
print(res_SMM.message)
print(f"Objective:  {res_SMM.fun:.6f}")
print(f"Iterations: {res_SMM.nit}")

# unpack and print parameter estimates
b_smm = res_SMM.x
delta_hat, rho1_hat, rho2_hat, rho3_hat, beta_hat, gamma_hat, _ = unpack_params(b_smm)

# create table of parameter estimates
smm_table = PrettyTable()
smm_table.field_names = ["Parameter", "True", "Estimate"]
smm_table.add_row(["beta",  2.0, round(beta_hat,  4)])
smm_table.add_row(["gamma", 0.5, round(gamma_hat, 4)])
smm_table.add_row(["rho1",  0.4, round(rho1_hat,  4)])
smm_table.add_row(["rho2",  0.2, round(rho2_hat,  4)])
smm_table.add_row(["rho3",  0.1, round(rho3_hat,  4)])
print(smm_table)

# save latex version of parameter estimates table
save_tex_table(smm_table.get_latex_string(), "smm_estimates") 

# create table of delta estimates
delta_table = PrettyTable()
delta_table.field_names = ["Wage", "True Delta", "Estimated Delta"]
w_grid = [0.5, 0.75, 1.0, 1.5, 2.0]
for j in range(5):
    delta_table.add_row([w_grid[j], 0.2, round(delta_hat[j], 4)])
print(delta_table)
save_tex_table(delta_table.get_latex_string(), "delta_estimates")

print(f"\nrho1+2*rho2+2*rho3 = {rho1_hat+2*rho2_hat+2*rho3_hat:.4f}  (should = 1)")
print(f"sum(delta)         = {np.sum(delta_hat):.4f}  (should = 1)")
