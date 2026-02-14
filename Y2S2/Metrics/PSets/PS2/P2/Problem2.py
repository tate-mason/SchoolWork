import pandas as pd
import numpy as np
import scipy as sp
import scipy.optimize as op
import statsmodels.api as sm

"""
File for problem 2 of HW2 - Multinomial Logit
    Libraries:
        - Pandas: data work
        - Numpy: numerical operations
        - Scipy: optimization routines
        - Statsmodels.api: regression package
"""

# Loading in data
df = sp.io.loadmat('dataHW2_Problem2.mat')
print(df.keys()) # checking column names

# Making data easier to work with in Python, numpy formatting
X = np.asarray(df["Xi"])
Zdist = np.asarray(df["Zdist"])
Zprice = np.asarray(df["Zprice"])
Y = np.asarray(df["Y"]).astype(int).ravel()

#============================================================#
# (a) Multinomial Logit Regression                           #
#============================================================#

from MultLog_2a import * # call helper file

b_hat, se, res = mnl_fit(X, Zdist, Zprice, Y, J=4) # call function to estimate mnl

# create results table
res_frame = pd.DataFrame({
    "Params (2a)": b_hat,
    "Std. Errors (2a)": se
})

print(res_frame) # view results

#============================================================#
# (b) Multinomial Logit Regression - Change Start Values     #
#============================================================#
from MultLog_2b import * # call helper file to use functions

b_hat_b, se_b, res = mnl_fit_b(X, Zdist, Zprice, Y, J=4) # call function to estimate mnl

# append results from spec using ones as starting
res_frame["Params (2b)"] = b_hat_b
res_frame["Std. Errors (2b)"] = se_b 

print(res_frame) # view results

#============================================================#
# (c) Multinomial Logit Regression - Match w/ Opts           #
#============================================================#

#Results match down to final decimal, could be rounding error there. Difference in Py and ML

#============================================================#
# (d) AME - parentBA==1 on attend any 4yr                    #
#============================================================#

from MultLog_2d import * # call helper function from file

b_hat, se, res = mnl_fit(X, Zdist, Zprice, Y, 4) # get b_hat results for use in ame function

ame_2d = ame_mnl(b_hat, X, Zdist, Zprice, Y, 4, 1, 1.0, 0.0) # call ame function

res_frame["Avg. Marginal Effect (2d)"] = ame_2d # append to results table
print(res_frame) # view

#============================================================#
# (e) APP - Calculate Average Predicted Prob and Compare     #
#============================================================#

from MultLog_2e import * # call helper file for app function

app = avg_predict_prob(b_hat, X, Zdist, Zprice, Y, 4) # call app function from helper 

print(app) # print results won't fit with dataframe dimensions :( 

# observable share
obs_share = np.bincount(Y, minlength=4) / len(Y) # counts percentage of Y that group is
print(obs_share) # print

# They match!

#============================================================#
# (f) No more 4 yr private                                   #
#============================================================#

from MultLog_2f import *

pct_change, avg_pct_change = new_predict_prob(b_hat, X, Zdist, Zprice, Y, 4)

print(pct_change) 
print(avg_pct_change)

