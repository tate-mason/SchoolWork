import numpy as np
from scipy.io import loadmat
import scipy as sp

df = loadmat("dataHW3_Problem2.mat")
print(df.keys())

X = np.asarray(df["Xi"])
Zprice = np.asarray(df["Zprice"])
Zdist = np.asarray(df["Zdist"])
Y = np.asarray(df["Y"]).ravel()

# ==================================== #
# (a) Multinomial Probit               #
# ==================================== #

from Problem2a import *


