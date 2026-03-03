import numpy as np
import scipy as sp
from scipy.optimize import minimize
from scipy.special import logsumexp

"""
1b: Average Marginal Effect of having a parent with a BA on probability of attending a 4-yr college (Y=2).
    Libraries used:
        - numpy for numerical manipulation
        - scipy for optimization and logsumexp
    Functions:
"""

def ame_mix(b, X, Zprice, Y, R, J):
    N, xK = X.shape
    Jm1 = J-1


    B = b[:xK*Jm1].reshape((xK,Jm1), order="F") # beta on characteristics

    mu_gamma = b[xK*Jm1]
    sigma_gamma = np.log(np.exp(b[xK*Jm1+1]))

    rng = np.random.default_rng(seed=219)
    eta = rng.standard_normal((N,R))

    gamma_p = mu_gamma + sigma_gamma*eta

    # starting values (20000x500x3)
    V_BA = np.zeros((N,R,J))
    V_no = np.zeros((N,R,J))
    X_BA1 = X.copy()
    X_BA1[:,1] = 1
    X_BA0 = X.copy()
    X_BA0[:,1] = 0

    for j in range(1, J):
        # split into observed and random components
        V_obs_BA = X_BA1@B[:,j-1] # X*Beta
        V_obs_no = X_BA0@B[:,j-1]
        V_random = gamma_p*Zprice[:,j:j+1] # gamma * Zprice
        V_BA[:,:,j] = V_obs_BA[:,None] + V_random
        V_no[:,:,j] = V_obs_no[:,None] + V_random # value function

    denom_BA = logsumexp(V_BA, axis=2, keepdims=True)
    denom_no = logsumexp(V_no, axis=2, keepdims=True)

    P_BA = np.exp(V_BA - denom_BA)
    P_no = np.exp(V_no - denom_no)

    AME = (P_BA[:,:,2] - P_no[:,:,2]).mean()

    return AME
