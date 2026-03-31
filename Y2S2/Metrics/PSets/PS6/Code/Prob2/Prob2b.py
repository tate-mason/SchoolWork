import numpy as np
import scipy as sp
from scipy.special import logsumexp

#=======================================================================#
# This file will use the results from part (a) to set up the transition #
# matrix, dimensions 10x10x3. Dim 1: future values of X. Dim 2: current #
# values of X. Dim 3: possible work choices. X is approx. N(0, 1)       #
#=======================================================================#

def compute_transition_matrix(alpha, sigma):
    # Define the grid for X
    p_grid = np.linspace(0.05, 0.95, 10)
    x_grid = sp.stats.norm.ppf(p_grid, loc=0, scale=1) # compute the corresponding X values for the grid points using the inverse CDF of the normal distribution

    # Initialize the transition matrix
    transition_matrix = np.zeros((10, 10, 3)) # dimensions: future X, current X, work choice

    # Compute the transition probabilities for each work choice
    for j in range(3): # loop over work choices
        for i in range(10): # loop over current X values
            mean = alpha[0] + alpha[1] * x_grid[i] + alpha[2] * (j == 2) + alpha[3] * (j == 3) # compute the mean of the normal distribution for future X given current X and work choice
            transition_matrix[:, i, j] = sp.stats.norm.pdf(x_grid, loc=mean, scale=sigma) # compute the probability density of future X given current X and work choice

        # Normalize the transition probabilities so they sum to 1 for each current X and work choice
        transition_matrix[:, :, j] /= transition_matrix[:, :, j].sum(axis=0)

    return transition_matrix, x_grid # return the computed transition matrix
