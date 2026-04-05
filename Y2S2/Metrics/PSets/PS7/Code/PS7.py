import pandas as pd
import scipy as sp
import numpy as np
import statsmodels.api as sm
from prettytable import PrettyTable

#======================================#
# PS7: DDC Problem                     #
#  - Libraries used:                   #
#    * Pandas: Data tables for results #
#    * Scipy: optimization routines    #
#    * Numpy: Linear algebra and       #
#             other numeric operations #
#    * Statsmodels: Regression analysis#
#======================================#

df = sp.io.loadmat('../Data/dataHW7_problem1.mat') # load data

print(df.keys()) # check column names
# Extract variables from the loaded data
X = df['X1'] 
Xt = df['X1t']

Y_0 = df['LY1']
Y = df['Y']

print(Y.shape, X.shape, Xt.shape, Y_0.shape)
#=== Part A ===#

# Estimate transition probabilites and construct transition matrices

N = Xt.shape[0] # number of observations after filtering

lag_Xt = np.concatenate([np.full((N,1), np.nan), Xt[:,:-1]], axis=1).ravel() # create the lagged X1 variable, adding a column of NaN values at the beginning to account for the lag, and flatten the array to ensure it's 1D
lag_Y = np.concatenate([np.full((N,1), np.nan), Y[:,:-1]], axis=1).ravel() # create the lagged Y variable, adding a column of NaN values at the beginning to account for the lag, and flatten the array to ensure it's 1D

Xt = Xt.ravel() # flatten the array to ensure it's 1D

active  = (lag_Y!=0)

part_time = (lag_Y[active] == 2) # create the binary for part-time workers
full_time = (lag_Y[active] == 3) # create the binary for full-time workers

X_reg = np.column_stack((lag_Xt[active], part_time, full_time)) # create the regression matrix with the lagged X and the binary variables
X_reg = sm.add_constant(X_reg) # add a constant term to the regression matrix

transition_model = sm.OLS(Xt[active], X_reg, missing='drop') # fit the OLS regression, dropping any rows with NaN values (the first row due to the lag)
transition_results = transition_model.fit() # fit the model to obtain the regression results

alpha = transition_results.params # extract the coefficients from the regression results
sigma = np.sqrt(transition_results.scale)  # extract the standard error of the regression (the square root of the residual variance)

pretty_table = PrettyTable()
pretty_table.field_names = ["Coefficient", "Value"]
pretty_table.add_row(["Constant", alpha[0]])
pretty_table.add_row(["Lagged X", alpha[1]])
pretty_table.add_row(["Part-time", alpha[2]])
pretty_table.add_row(["Full-time", alpha[3]])
pretty_table.add_row(["Sigma", sigma])

print(pretty_table)

transition_matrix = np.zeros((3,3))
transition_matrix[0,0] = 1 - (alpha[1] + alpha[2] + alpha[3]) # probability of transitioning from retirement to retirement
transition_matrix[0,1] = alpha[2] # probability of transitioning from retirement to part-time
transition_matrix[0,2] = alpha[3] # probability of transitioning from retirement to full-time

#=== Part B ===#

"""
Estimate CCPS. Estimate a single logit model of retirement based on (X, Xt, Y_0) and a set of period dummies. Once someone retires they do not contribute to likelihood.
"""

N, T = Y.shape # define individual and time space

Y_lag = np.concatenate([np.full((N,1), np.nan), Y[:,:-1]], axis=1) # (N,T) lag Y
t_dummy = np.tile(np.arange(T), (N,1)) # (N,T) time dummies

ccps_dat = pd.DataFrame({
    'X_1': np.tile(X[:,0], (T,1)).T.ravel(), # constant
    'X_2': np.tile(X[:,1], (T,1)).T.ravel(), # gender 
    'X_t': Xt.ravel(), # health
    'Y_0': np.tile(Y_0.ravel(), T), # initial state 
    'Y'  : Y.ravel(), # current state
    'lag_Y': Y_lag.ravel(), # lagged state
    't': t_dummy.ravel() # time dummies
})

ccps_data = ccps_dat[ccps_dat['lag_Y'].notna() & (ccps_dat['lag_Y'] != 0)].copy() # filter out rows where lag_Y is NaN or 0 (retired)
period_dummies = pd.get_dummies(ccps_data['t'], prefix='t', drop_first=True).astype(int) # create period dummies, dropping the first period to avoid multicollinearity
ccps_data['retired'] = (ccps_data['Y'] == 0).astype(int) # create a binary variable for retirement

X_ccps = pd.concat([ccps_data[['X_1', 'X_2', 'X_t', 'Y_0']], period_dummies], axis=1) # create the regression matrix with the covariates and period dummies

ccps_res = sm.Logit(ccps_data['retired'], X_ccps).fit() # fit the logit model
print(ccps_res.summary())

ccps_data['predicted_prob'] = ccps_res.predict(X_ccps) # add predicted probabilities to the data frame

print("\nPredicted probabilities of retirement for the first 10 observations:")
print(ccps_data[['predicted_prob']].head(10))

ccps_table = PrettyTable()
ccps_table.field_names = ["Variable", "Coefficient", "Std. Error", "z-Value", "P>|z|"]
for var in ccps_res.params.index:
    ccps_table.add_row([var, ccps_res.params[var], ccps_res.bse[var], ccps_res.tvalues[var], ccps_res.pvalues[var]])
print(ccps_table)
