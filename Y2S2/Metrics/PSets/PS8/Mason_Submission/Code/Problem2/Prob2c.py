import numpy as np

"""
This file defines the SMM objective function. Contains:
    - smm_obj: simulates moments at candidate params and returns weighted distance to data moments
"""

from Prob2b import sim_moments
from Prob2a import gmm_moments

def smm_obj(b_params, m_data, W):

    # simulate at candidate parameters
    w_sim, k_sim, y_sim = sim_moments(b_params) # simulates (w_sim, k_sim, y_sim) at candidate parameters
    m_sim = gmm_moments(k_sim, y_sim, w_sim) # computes moments from simulated data

    diff = m_data - m_sim # difference between data and simulated moments
    return diff @ W @ diff # quadratic form with weighting matrix W
