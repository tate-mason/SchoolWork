import numpy as np
import scipy as sp
from scipy.special import logsumexp

#=====================================================#
# This file contains the function for part (c) of     #
# problem 2. It will discretize X1t into 10 bins      #
# based on the transition grid of X. Calculating flow # 
# utility still needs continuous X1t.                 #
#=====================================================#

def discretize_X1t(X1t, transition_matrix, x_grid):
    bins = np.digitize(X1t, x_grid) # discretize X1t into bins based on the grid, subtract 1 to get 0-based indices
    bins = np.clip(bins-1, 0, 9) # ensure that the bin indices are within the valid range of 0 to 9
    X1t_discrete = x_grid[bins] # map the bin indices back to the corresponding grid values to get the discretized X1t
    return X1t_discrete # return the discretized X1t

