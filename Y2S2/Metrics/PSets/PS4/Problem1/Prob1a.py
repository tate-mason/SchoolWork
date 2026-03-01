import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import logsumexp


"""
Problem 1a:
    This file estimates a mixed logit model using MLE. R=500 draws, 
    gamma ~ N(mu_gamma, sigma_gamma^2) for price coeff. Only random coefficient is on price. Y=0 is normalized to 0

    Functions:
"""

