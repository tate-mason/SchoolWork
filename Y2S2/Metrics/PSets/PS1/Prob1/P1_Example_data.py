import numpy as np
import pandas as pd

"""
    Translation of ```HW1_Example_data.m``` into Python code. Purpose of this file is to create a simulated dataset to use on a linear
    conditional expectation problem. 

    We will use the library ```pandas``` for dataset creation, and ```numpy``` for numerical operations (mostly random number generation in
    this context).

    Note: While exact values of regressors will not match, they are notably similar as shown in df.head(). This is due to differences in rng
    across Python and MatLab.
"""

seed = 555 # Defining seed number the same as in the example above
rng = np.random.default_rng(seed) # same as rng definition in matlab code

N = 5000 # Defining sample size

# Defining Characteristics - Building in Covariance Between Regressors
common = rng.standard_normal(N) # Covariance
A = (0.5*common + 0.5*rng.standard_normal(N)>0).astype(int)
B = 0.25*common + 0.8*rng.standard_normal(N)
C = 2 + 0.25*common + 1.25*rng.standard_normal(N) 
X = np.column_stack((np.ones(N), A, B, C)) 
# Column stack here just creates the array of all characteristics as well as the ones

# Defining parameter values
beta = np.array([0.5, 0.5, 0.75, 0.25])

# Defining Outcomes - Assuming Regressors are Exog.
Y = (X@beta)+rng.standard_normal(N)

# Saving the data as a CSV for easier loading in future parts
# Saving X to df, specifying what to name the columns
df = pd.DataFrame(X, columns=['const', 'A', 'B', 'C'])
# Saving Y by appending to df
df['Y'] = Y

# Final save - dataHW1_Example.csv holds data akin to that given
df.to_csv('dataHW1_Example.csv', index=False)

# Sanity check
print(df.head)


