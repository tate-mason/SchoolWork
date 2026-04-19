import numpy as np
import scipy as sp

"""
This file uses SMM to estimate the parameters of a logit discrete choice model. Contains:
    log_smm_moments: moment function for logit model using SMM
"""

from Prob2b import sim_moments
from Prob2a import gmm_moments

def log_smm_moments(b, m, W, k, y, w):
    beta  = b[0]
    gamma = b[1]

    delta_raw = b[2:6]
    delta = np.exp(delta_raw) / np.sum(np.exp(delta_raw))

    Sigma_raw = b[6:].reshape(5, 4)
    Sigma = np.zeros((5, 5))
    for i in range(5):
        row = np.append(Sigma_raw[i], 0.0)
        Sigma[i] = np.exp(row) / np.sum(np.exp(row))

    # simulate at candidate parameters
    w_sim, k_sim, y_sim = sim_moments(b, k, y, w)
    m_sim = gmm_moments(b, k_sim, y_sim, w_sim)

    diff = m - m_sim
    return diff @ W @ diff
