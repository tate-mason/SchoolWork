import numpy as np
import scipy as sp

"""
Parametric Bootstrap for S.E. of AME in Mixed Logit Model

    This file implements a parametric bootstrap, drawn from the joint dist N(mean of the estimates, hess_inv)
    and use Cholesky decomposition to make the draws. With said draw, re-estimate AME. 100 draws.

    Functions:
        - boot_ame: performs the parametric bootstrap to estimate the standard error of the AME by drawing from the joint distribution of the estimates and re-estimating the AME for each draw.
"""

from Prob1b import ame_mix

def boot_ame(b_hat, cov_hat, X, Zprice, Y, R=100, J=3, seed=219):
    rng = np.random.default_rng(seed) # set seed placeholder
    N, xK = X.shape # dimensions of individuals and characteristics
    Jm1 = J-1 # number of choices minus outside option

    L = np.linalg.cholesky(cov_hat) # Cholesky decomp to get lower triangular
    Sigma = L @ L.T # covariance matrix for multivariate normal distribution

    AME_boot = np.empty(R) # initialize array to store BS AME estimates
    for r in range(R):
        b_draw = rng.multivariate_normal(b_hat, Sigma) # draw from the joint dist. N(mu_est, Sigma)
        AME_boot[r] = ame_mix(b_draw, X, Zprice, Y, R=100, J=3) # re-estimate AME with parameters drawn from b_draw
    se_boot = AME_boot.std(ddof=1) # calculate S.E. of AME
    return se_boot, AME_boot # return values
