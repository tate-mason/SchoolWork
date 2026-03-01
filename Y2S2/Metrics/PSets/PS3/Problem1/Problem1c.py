import numpy as np
import scipy as sp

def delta_lambda(b, cov_hat):

    b = np.asarray(b).ravel() # estimates
    cov_hat = np.asarray(cov_hat) # covariance call

    idx = b.size - 1 # position of lambda

    lam_raw = b[idx] # lambda position in b
    lam_hat = 1 / (1 + np.exp(-lam_raw)) # bound lambda to (0,1)

    dlam = lam_hat * (1-lam_hat) # derivative w.r.t lam_hat

    var_lam = cov_hat[idx,idx] # pass through hessian
    se_lam = np.sqrt(var_lam) # standard error of lam_raw

    se_lam = abs(dlam) * se_lam # delta method to get standard error of lam_hat

    return lam_hat, se_lam # return lambda and its standard error



