import numpy as np
import scipy as sp
import statsmodels.api as sm
import pandas as pd

"""
    Problem Set 2 - Probit Regressions
"""

#=== Part A ===#

# Firm Entry Probit - no competitive effects

def probit_reg(lhs_var, rhs_vars):
    model = sm.Probit(XMat[lhs_var], sm.add_constant(XMat[rhs_vars]))
    results = model.fit()
    return results.summary()

#=== Part B ===#

# Firm Entry Probit - with competitive effects
def probit_reg_comp(lhs_var, rhs_vars):
    model = sm.Probit(XMat[lhs_var], sm.add_constant(XMat[rhs_vars]))
    results = model.fit()
    print(results.summary())

#=== Part C ===#

# Firm Entry Probit - instrumenting strategy 

def probit_reg_iv(lhs_var, rhs_vars, instrument):
    # First stage regression
    first_stage = sm.OLS(XMat[rhs_vars], sm.add_constant(XMat[instrument])).fit()
    XMat['predicted_' + rhs_vars] = first_stage.predict(sm.add_constant(XMat[instrument]))
    
    # Second stage regression
    model = sm.Probit(XMat[lhs_var], sm.add_constant(XMat['predicted_' + rhs_vars]))
    results = model.fit()
    print(results.summary())
