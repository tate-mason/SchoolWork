import numpy as np
import pandas as pd
import scipy as sp
import statsmodels.api as sm
from scipy.stats import norm
from scipy.optimize import minimize
from prettytable import PrettyTable

# ============================================================
# Load Data
# ============================================================
df  = sp.io.loadmat('../Data/dataHW7_problem1.mat')

X   = df['X1']    # (N, 2): constant, gender
Xt  = df['X1t']   # (N, T): time-varying health
Y   = df['Y']     # (N, T): choices {0,1,2,3}
Y_0 = df['LY1']   # (N, 1): initial period choice

N, T = Y.shape
