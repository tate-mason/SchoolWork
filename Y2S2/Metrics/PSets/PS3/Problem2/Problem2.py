import numpy as np
from scipy.io import loadmat
import scipy as sp
import pandas as pd

df = loadmat("dataHW3_Problem2.mat")

X = np.asarray(df["Xi"])
Z = np.asarray(df["Zdist"])
Y = np.asarray(df["Y"]).ravel()

# ==================================== #
# (a) Multinomial Probit               #
# ==================================== #

from Problem2a import *

beta_hat, se, rho_hat, res = mnp_opt(X, Z, Y, 3, 300, 0.1, 219)

param_full = np.append(beta_hat, rho_hat)
se_full = np.append(se, np.nan)

res_frame = pd.DataFrame({
    "β, γ, ρ Estimates": param_full,
    "Std. Errors": se_full
})

print(res_frame)
