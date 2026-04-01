import pandas as pd
from tabulate import tabulate
import numpy as np
import scipy as sp
from scipy.io import loadmat

#=====================================================#
# This file serves as a main file to run the code for #
# problem 2. It will load the data and call the       #
# functions contained in helper files labeled for the #
# part they are meant to be used for.                 #
#                                                     #
# Libraries used in this file:                        #
# - pandas                                            #
# - numpy                                             #
# - scipy                                             #
#=====================================================#

#=====================================================#
# Load the data from the .mat file and extract the    #
# relevant variables.                                 #
#=====================================================#

df = loadmat('../../Data/Prob2/dataHW6_problem2.mat')

X = np.asarray(df['X1']).squeeze()
Y = np.asarray(df['Y']).squeeze()

X1 = np.asarray(df['X1t']).squeeze()
Y_0 = np.asarray(df['LY1']).squeeze()

#=====================================================#
# Calling the function for part (a) to regress X' on  #
# X and obtain the α and residuals.                   #
#=====================================================#

from Prob2a import *

alpha, sigma = reg_X1_on_Xchoice(X1, Y) # calling the function to perform the regression and obtain the coefficients and standard error

rows = list(zip(["Constant", "Lagged X1t", "Part-Time", "Full Time"], alpha)) # create a list of rows for the table corresponding to the estimated values
rows.append(("Standard Error", sigma)) # add a row for the standard error of the regression to the table
print(tabulate(rows, headers=["Coefficient", "Value"], floatfmt=".4f")) # print the results in a tabular format

#=====================================================#
# Calling the function for part (b) to set up the     #
# transition probabilities and compute the transition #
# matrix.                                             #
#=====================================================#

from Prob2b import *

transition_matrix, x_grid = compute_transition_matrix(alpha, sigma) # calling the function to compute the transition matrix using the estimated coefficients and standard error from part (a)

#===========================================================#
# Calling the function for part (c) to create a discretized #
# X1t from the bins from the X values. Discretized states   #
# will only be used to calculate E[V'] in part (d).         #
#===========================================================#

from Prob2c import *

X1t_discrete = discretize_X1t(X1, x_grid) # calling the discretization function

#===========================================================#
# Calling the function for part (d) to estimate the DDC     #
# model. Future exp. utility depends on current choice and  #
# current state. Transition matrix will be used to make     #
# E[V'] to integrate over the distribution of X             #
#===========================================================#

from Prob2d import *

theta_est = estimate_params(X, X1, Y, Y_0, transition_matrix, x_grid, X1t_discrete) # calling the function to estimate the parameters of the DDC model using the data and the transition matrix

res = pd.DataFrame({
    "Parameter": ["β_s (Flex-Time, X1)", "β_s (Flex-Time, X2)", "β_s (Part-Time, X1)", "β_s (Part-Time, X2)", "β_s (Full-Time, X1)", "β_s (Full-Time, X2)", "β_d (Flex-Time)", "β_d (Part-Time)", "β_d (Full-Time)", "δ", "β"],
    "Estimate": theta_est
})

print(tabulate(res, headers="keys", tablefmt="pretty", floatfmt=".4f")) # print the estimated parameters in a tabular format

