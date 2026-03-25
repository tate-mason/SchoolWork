import numpy as np
import scipy as sp
import statsmodels.api as sm
from statsmodels.regression.linear_model import OLS

#=====================================================#
# This file contains the function for part (a) of     #
# problem 2. It will perform a regression of X' on X  #
# and return the α and residuals.                     #
#                                                     #
# Libraries used in this file:                        #
# - numpy                                             #
# - scipy                                             #
# - statsmodels                                       #
#                                                     #
# Functions:                                          #
# - reg_X1_on_Xchoice(X1, Y): This function takes in  #
# the variables X1 and Y, performs a regression of X' # 
# on X, and returns the coefficients (α) and the      #
# standard error of the regression (σ).               #
#=====================================================#

def reg_X1_on_Xchoice(X1, Y):

    X1 = X1.ravel() # flatten the array to ensure it's 1D
    Y = Y.ravel() # flatten the array to ensure it's 1D

    part_time = (Y == 2) # create the binary for part-time workers
    full_time = (Y == 3) # create the binary for full-time workers

    lag_X1 = np.concatenate(([np.nan], X1[:-1])) # create X_t-1
    X_reg = np.column_stack((lag_X1, part_time, full_time)) # create the regression matrix with the lagged X and the binary variables
    X_reg = sm.add_constant(X_reg) # add a constant term to the regression matrix

    transition_model = OLS(X1, X_reg, missing='drop') # fit the OLS regression, dropping any rows with NaN values (the first row due to the lag)
    transition_results = transition_model.fit() # fit the model to obtain the regression results

    alpha = transition_results.params # extract the coefficients from the regression results
    sigma = np.sqrt(transition_results.scale)  # extract the standard error of the regression (the square root of the residual variance)

    return alpha, sigma # return the coefficients and the standard error of the regression

