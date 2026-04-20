import numpy as np
import scipy as sp
import statsmodels.api as sm
import pandas as pd
from prettytable import PrettyTable
from statsmodels.miscmodels.ordinal_model import OrderedModel


"""
Problem Set 2:

Author: Tate Mason
Due: 04-23-2026
Class: IO 2


  * Helper files:
    - PS2c.py: Contains the implementation of the Seim approach for estimating entry decisions in a duopoly setting.

  * Libraries used:
    - numpy
    - scipy
    - statsmodels
    - pandas
    - prettytable
"""

# Read Data

xmat_cols = [
    'county_id', 'log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'log_dist_benton', 'south',
    'kmart', 'walmart', 'n_small_stores', 'dw_kmart_out', 'dw_walmart_out', 'col13', 'col14', 'col15'
]

XMat = pd.read_csv('../Data/XMat.out', sep=r'\s+', header=None, names=xmat_cols)
print(XMat.head())

# Helper function to save LaTeX tables
import os
os.makedirs('../Tables', exist_ok=True)
def save_tex_table(latex_str, filename):
    with open(f'../Tables/{filename}.tex', 'w') as f:
        f.write(latex_str)

#=== Problem 2a ===#

"""
Here we will use a simple probit under different specifications to estimate the entry decision of a firm

- Data:
    - XMat.out: County level data on various store level controls.
"""

from PS2a import *

#=== Part A ===#

print("=== Part A ===")

lhs_wm = XMat['walmart']
rhs_wm = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'log_dist_benton', 'n_small_stores', 'south']]

wm_probit = sm.Probit(lhs_wm, sm.add_constant(rhs_wm)).fit()
save_tex_table(wm_probit.summary().as_latex(), 'wm_probit_spec1')

lhs_km = XMat['kmart']
rhs_km = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'n_small_stores', 'south']]

km_probit = sm.Probit(lhs_km, sm.add_constant(rhs_km)).fit()
save_tex_table(km_probit.summary().as_latex(), 'km_probit_spec1')

#=== Part B ===#

print("=== Part B ===")

lhs_wm_comp = XMat['walmart']
rhs_wm_comp = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'log_dist_benton', 'n_small_stores', 'south', 'kmart']]

wm_comp_probit = sm.Probit(lhs_wm_comp, sm.add_constant(rhs_wm_comp)).fit()
save_tex_table(wm_comp_probit.summary().as_latex(), 'wm_probit_spec2')

lhs_km_comp = XMat['kmart']
rhs_km_comp = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'n_small_stores', 'south', 'walmart']]

km_comp_probit = sm.Probit(lhs_km_comp, sm.add_constant(rhs_km_comp)).fit()
save_tex_table(km_comp_probit.summary().as_latex(), 'km_probit_spec2')

# The biggest weakness of using the number of competitor stores as a regressor is the almost assured endogeneity. The presence of a competitor store is likely correlated with unobserved factors that also affect the entry decision, such as local market conditions, consumer preferences, or the strategic behavior of firms.
# For example, if a county has favorable market conditions for retail entry (e.g., high population density, strong consumer demand), both Walmart and Kmart may be more likely to enter, leading to a positive correlation between the presence of one firm and the other. This endogeneity can bias the estimated coefficients and lead to incorrect inferences about the competitive effects on entry decisions.

#=== Part C ===#
print("=== Part C ===")

lhs_km_iv = XMat['kmart']
rhs_km_iv = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'n_small_stores', 'south', 'walmart']]
instrument_km_iv = 'log_dist_benton'

# First stage regression
first_stage_km_iv = sm.OLS(XMat['walmart'], sm.add_constant(XMat[instrument_km_iv])).fit()
XMat['predicted_walmart'] = first_stage_km_iv.predict(sm.add_constant(XMat[instrument_km_iv]))

# Second stage regression

rhs_km_iv2 = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'south', 'n_small_stores', 'predicted_walmart']]
model_km_iv = sm.Probit(lhs_km_iv, sm.add_constant(rhs_km_iv2))
results_km_iv = model_km_iv.fit()
print(results_km_iv.summary())
save_tex_table(results_km_iv.summary().as_latex(), 'km_iv_probit')

lhs_wm_iv = XMat['walmart']
rhs_wm_iv = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'n_small_stores', 'log_dist_benton', 'south', 'kmart']]
instrument_wm_iv = 'n_small_stores'

# First stage regression
first_stage_wm_iv = sm.OLS(XMat['kmart'], sm.add_constant(XMat[instrument_wm_iv])).fit()
XMat['predicted_kmart'] = first_stage_wm_iv.predict(sm.add_constant(XMat[instrument_wm_iv]))

# Second stage regression
rhs_wm_iv2 = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'n_small_stores', 'log_dist_benton', 'south', 'predicted_kmart']]
model_wm_iv = sm.Probit(lhs_wm_iv, sm.add_constant(rhs_wm_iv2))
results_wm_iv = model_wm_iv.fit()
print(results_wm_iv.summary())  
save_tex_table(results_wm_iv.summary().as_latex(), 'wm_iv_probit')

# Kmart IV results suggest that coeff on pred. WM is significant and negative. This implies that as distance from benton co. increases, the probability of Walmart entry increases, which in turn reduces the probability of Kmart entry.
# This makes sense, as WM would be more likely to enter as they stray from their home county. The exclusion restriction seems plausible, as distance from Benton Co. should not directly affect Kmart entry decisions, except through its effect on Walmart's entry.
# Relevance condition is satisfied as distance from Benton Co. is likely correlated with Walmart's entry decision, given that Benton Co. is Walmart's home county and a central location for their operations.
#
# WM IV coef on pred. KM is significant and negative, suggesting that as the number of small stores increases, the probability of Kmart entry increases, which in turn reduces the probability of Walmart entry. This also makes sense, as a higher number of small stores may indicate a more competitive retail environment, making it less attractive for Walmart to enter.
# The exclusion restriction seems implausible, as the number of small stores could directly affect Walmart's entry decision, independent of Kmart's entry. For example, a high number of small stores could indicate a saturated market, which would deter Walmart from entering regardless of Kmart's presence. 
# The relevance condition is satisfied as the number of small stores is likely correlated with Kmart's entry decision, as Kmart may be more likely to enter markets with fewer small stores where they can capture more market share.

#=== Bresnahan-Reiss Approach ===#

# Ordered Probit

# Spec 1: LHS = number of large players, RHS = market controls

controls = ['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'log_dist_benton', 'n_small_stores', 'south']

XMat['n_large'] = XMat['kmart'].astype(int) + XMat['walmart'].astype(int)

res_spec1 = OrderedModel(
    XMat['n_large'], XMat[controls], distr='probit'
).fit(method='BFGS')

print(res_spec1.summary())
save_tex_table(res_spec1.summary().as_latex(), 'ordered_probit_spec1')

# Spec 2: LHS = number of players (large + small), RHS = market controls

XMat['n_total'] = XMat['n_large'] + XMat['n_small_stores']

res_spec2 = OrderedModel(
    XMat['n_total'], XMat[controls], distr='probit'
).fit(method='BFGS')

print(res_spec2.summary())
save_tex_table(res_spec2.summary().as_latex(), 'ordered_probit_spec2')

#=== Seim Approach ===#

from PS2c import *


XW = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'log_dist_benton', 'n_small_stores', 'south']].values
XK = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'n_small_stores', 'log_dist_benton', 'south']].values

yW = XMat['walmart'].values
yK = XMat['kmart'].values

K = XW.shape[1]

theta0 = np.zeros(2*K + 2)

res_seim = minimize(log_lik, theta0, args=(XW, XK, yW, yK), method='BFGS')

theta_hat = res_seim.x
betaW_hat = theta_hat[:K]
deltaW_hat = theta_hat[K]
betaK_hat = theta_hat[K+1:2*K+1]
deltaK_hat = theta_hat[-1]

res_table = PrettyTable()
res_table.field_names = ["Parameter", "Estimate"]
for i in range(K):
    res_table.add_row([f"betaW_{i}", betaW_hat[i]])
res_table.add_row(["deltaW", deltaW_hat])
for i in range(K):
    res_table.add_row([f"betaK_{i}", betaK_hat[i]])
res_table.add_row(["deltaK", deltaK_hat])
print(res_table)
param_names = [f'betaW_{i}' for i in range(K)] + ['deltaW'] + \
              [f'betaK_{i}' for i in range(K)] + ['deltaK']

seim_df = pd.DataFrame({
    'Parameter': param_names,
    'Estimate': theta_hat
})

save_tex_table(
    seim_df.to_latex(index=False, float_format='%.4f', caption='Seim NFP Estimates', label='tab:seim'),
    'seim_results'
)

