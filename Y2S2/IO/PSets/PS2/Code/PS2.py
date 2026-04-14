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
    - PS2a.py
    - PS2b.py
    - PS2c.py

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

print(sm.Probit(lhs_wm, sm.add_constant(rhs_wm)).fit().summary())

lhs_km = XMat['kmart']
rhs_km = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'n_small_stores', 'south']]

print(sm.Probit(lhs_km, sm.add_constant(rhs_km)).fit().summary())

#=== Part B ===#

print("=== Part B ===")

lhs_wm_comp = XMat['walmart']
rhs_wm_comp = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'log_dist_benton', 'n_small_stores', 'south', 'kmart']]

print(sm.Probit(lhs_wm_comp, sm.add_constant(rhs_wm_comp)).fit().summary())

lhs_km_comp = XMat['kmart']
rhs_km_comp = XMat[['log_pop', 'log_retail_sales_pc', 'pct_urban', 'midwest', 'n_small_stores', 'south', 'walmart']]

print(sm.Probit(lhs_km_comp, sm.add_constant(rhs_km_comp)).fit().summary())

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

# Spec 2: LHS = number of players (large + small), RHS = market controls

XMat['n_total'] = XMat['n_large'] + XMat['n_small_stores']

res_spec2 = OrderedModel(
    XMat['n_total'], XMat[controls], distr='probit'
).fit(method='BFGS')

print(res_spec2.summary())
