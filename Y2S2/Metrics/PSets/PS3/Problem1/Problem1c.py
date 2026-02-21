import numpy as np
import scipy as sp

def delta_lambda(b, cov_hat):

    b = np.asarray(b).ravel() # estimates
    cov_hat = np.asarray(cov_hat) # covariance call

    idx = b.size - 1 # position of lambda

    lam_raw = b[idx]
    lam_hat = 1 / (1 + np.exp(-lam_raw))

    dlam = lam_hat * (1-lam_hat) # derivative w.r.t lam_hat

    var_lam = cov_hat[idx,idx] # pass through hessian
    se_lam = np.sqrt(var_lam)

    se_lam = abs(dlam) * se_lam

    return lam_hat, se_lam



