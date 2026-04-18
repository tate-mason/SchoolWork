import numpy as np
import scipy as sp

"""
This file creates moments to be used in GMM in future parts. Contains:
    - gmm_moments: moment function for forward looking discrete choice model
"""

def gmm_moments(b, k, y, w):
    m = []

    # Assets
    m.append(np.mean(k[:, 0])) # mean assets today
    m.append(np.mean(k[:, 1])) # mean assets tomorrow
    m.append(np.std(k[:, 1])) # asset dispersion tomorrow
    m.append(np.mean(k[:,1] == 0)) # fraction of agents with zero assets tomorrow

    # Savings
    m.append(np.mean(k[:, 1] - k[:, 0])) # mean savings

    # Labor supply
    l = y.reshape(-1, 2)
    m.append(np.mean(l[:, 0])) # mean labor supply today
    m.append(np.mean(l[:, 1])) # mean labor supply tomorrow

    # Wages
    #m.append(np.mean(w[:, 0])) # mean wage today
    #m.append(np.mean(w[:, 1])) # mean wage tomorrow
    #m.append(np.std(w[:, 0])) # wage dispersion today 
    #m.append(np.corrcoef(w[:,0], w[:,1])[0,1]) # correlation of wages today and tomorrow

    # Cross-Moments
    m.append(np.corrcoef([k[:,0], w[:,0]])[0,1]) # correlation of assets and wages today
    m.append(np.mean(l[:,1][w[:,0] > np.median(w[:,0])])) # LFP for high earners tomorrow

    return np.array(m)




