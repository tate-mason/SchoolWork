import numpy as np
import scipy as sp
from scipy.special import logsumexp

#=====================================================#
# This file contains the function for part (c) of     #
# problem 2. It will discretize X1t into 10 bins      #
# based on the transition grid of X. Calculating flow # 
# utility still needs continuous X1t.                 #
#=====================================================#

def discretize_X1t(X1t, x_grid):
    bins = np.clip(np.digitize(X1t, x_grid) - 1, 0, len(x_grid) - 1) # crete bins from the data and grid created in part b
    return x_grid[bins]  # shape (N, T)
