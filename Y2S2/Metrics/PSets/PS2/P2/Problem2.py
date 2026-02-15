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
    Helper files:
        - MultLog_2a: functions for part (a) multinomial logit regression
        - MultLog_2b: functions for part (b) multinomial logit regression with different starting values
        - MultLog_2d: functions for part (d) calculating average marginal effects
        - MultLog_2e: functions for part (e) calculating average predicted probabilities
        - MultLog_2f: functions for part (f) calculating new predicted probabilities when removing the 4 year private option
        - MultLog_2g: functions for part (g) calculating consumer surplus change when removing the 4 year private option
    File structure:
        - Load in data and make it easier to work with in Python
        - Part (a) Multinomial Logit Regression
        - Part (b) Multinomial Logit Regression with different starting values
        - Part (c) Compare results with different Opts (no effect)
        - Part (d) Calculate Average Marginal Effect of parentBA on attending any 4 year college
        - Part (e) Calculate Average Predicted Probability of each choice and compare to observable shares
        - Part (f) Calculate new predicted probabilities when removing the 4 year private
        - Part (g) Calculate change in consumer surplus when removing the 4 year private option, overall and by parentBA
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

print("Average predicted probability of each choice: ")
print(app) # print results won't fit with dataframe dimensions :( 

# observable share
obs_share = np.bincount(Y, minlength=4) / len(Y) # counts percentage of Y that group is
print("Observable share of each choice: ")
print(obs_share) # print

# They match!

#============================================================#
# (f) No more 4 yr private                                   #
#============================================================#

from MultLog_2f import * # call helper file for new_predict_prob function

P, pct_change, avg_pct_change = new_predict_prob(b_hat, X, Zdist, Zprice, Y, 4) # call helper function

# print results
print("Avg. Predicted Probability After Removing 4 Year Private Option: ")
print(P.mean(axis=0)) 
print("Percent change in predicted probabilities when removing 4 year private option: ")
print(avg_pct_change) 

#============================================================#
# (g) Consumer Surplus Change                                #
#============================================================#

from MultLog_2g import * # call helper file for surplus function
dCS, dcs_BA, dcs_noBA = surplus_func(b_hat, X, Zdist, Zprice, Y, 4) # calling function from helper

print("Average change in consumer surplus (1000's $) when removing 4 year private option: \n", dCS) # print results
print("Average change in consumer surplus (1000's $) by parentBA when removing 4 year private option: \n", dcs_BA) # print results by parentBA
print("Average change in consumer surplus (1000's $) by no parentBA when removing 4 year private option: \n", dcs_noBA) # print results by no parentBA
