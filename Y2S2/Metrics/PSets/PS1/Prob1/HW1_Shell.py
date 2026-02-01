import numpy as np
import pandas as pd
import statsmodels.api as sm
import scipy as sp
from olslike import *
from olsmoments import *

"""
In this program, I will translate the code provided in ```shell_HW1_Example.m``` to Python. It should be noted not all results will 
match due to differing randomization processes across languages. However, they are closely linked and thus useful. Commenting will
describe discrepancies in code and attempt to explain logic, though please be aware I am using these assignments as an opportunity
to better familiarize myself with Python. AI will be used for bug fixing, but otherwise I am looking through documentation.

Companion Files:
    - olslike.py: helper file which defines the olslike function as depicted in provided ```olslike.m``` file
    - olsmoments.py: similar helper file for olsmoments function, from ```olsmoments.m``` file
    - P1_Example_data.py: data generation file translated from ```HW1_Example_data.m```

Libraries:
    - pandas: data manipulation and loading, not a ton of use besides loading the data generated in
              ```P1_Example_data.py```
    - numpy: workhorse package. all linear algebra and numerical methods come through this. they provide a helpful matlab --> Python
             translation guide if interested.
    - statsmodels: provides ols
    - scipy: provides optimization functions needed for MLE
"""

# Load dataset (CSV)
df = pd.read_csv('dataHW1_Example.csv')
Y = df['Y'].to_numpy()
X = df[['X1', 'X2', 'X3', 'X4']].to_numpy()
## Getting rid of constant from X

# Defining Size of the Sample
N = Y.shape[0] # akin to size, note 0 index as 1st position =0 in Python

# Defining Parameter Space
K = X.shape[1]

###########################################################################################################

"""
    Part B: Estimate with canned OLS functions
"""

mdl = sm.OLS(Y, X) # Call ols from statsmodels
results = mdl.fit(cov_type = 'HC3') # specify heteroskedastic robust SE
print(results.summary()) # get results

###########################################################################################################

"""
    Part C: Matrix Algebra Estimation
"""
β_hat1 = np.linalg.solve((X.T@X), (X.T@Y))
# Calculate homoskedastic s.e. (equation 4.10 in Wooldridge)

e = Y-X@β_hat1

σ_hat = (e.T@e)/(N-K)
var_β_hat1 = σ_hat*np.linalg.inv(X.T@X)
se_H0_β_hat1 = np.sqrt(np.diag(var_β_hat1))

# Calculate heteroskedastic standard errors (equation 4.11 in Wooldridge)
mid = np.zeros((K, K))

mid = X.T @ np.diag(e**2) @ X

var_β_hat1 = (N/(N-K))*np.linalg.inv(X.T@X)@mid@np.linalg.inv(X.T@X)
seHET_βhat1 = np.sqrt(np.diag(var_β_hat1))
MatrixAlg_Results = pd.DataFrame({
    'β_hat1': β_hat1,
    'seHET_βhat1': seHET_βhat1,
    'se_H0_β_hat1': se_H0_β_hat1
})

MatrixAlg_Results.index = [f"β_{j}" for j in range(K)]
print(MatrixAlg_Results)

"""
    Part D: MLE
"""

# Use scipy's optimize.minimize to be equivalent to fminunc

b_start = np.r_[np.zeros(K), 1.0] # using row concatenation func np.r_ to make a row of zeros and then 1.0

"""
    optimize.minimize in exchange for fminunc. 

    arguments:
    - olslike function defined in its file 
    - b_start defined above,
    - taking Y, X from data,
    - using BFGS algorithm to solve
"""

res = sp.optimize.minimize(
    olslike,
    b_start,
    args = (Y, X),
    method = "BFGS"
)

beta_hat = res.x # recovering parameter estimates
vcov = res.hess_inv # recovering variance covariance matrix
se = np.sqrt(np.diag(vcov)) # standard errors

# Put results in easily viewable format
LikResults = pd.DataFrame({
    'β_hat': beta_hat,
    'Std. Error': se
})

print(LikResults) # view

"""
    Part E: MoM 
"""

bstart = np.zeros(4)

# Same as above, but with olsmoments function
res_m = sp.optimize.minimize(
    olsmoments,
    bstart,
    args = (Y, X),
    method = "BFGS"
)

beta_mom = res_m.x
vcov_m = res_m.hess_inv
se_m = np.sqrt(np.diag(vcov_m))

# Put into nicer format 
MoMResults = pd.DataFrame({
    'β_hat': beta_mom,
    'Std. Error': se_m
})

print(MoMResults)


