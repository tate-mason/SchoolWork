import numpy as np
import pandas as pd
from scipy.io import loadmat

"""
    This script serves to convert the MATLAB .mat data file 'dataHW1_Problem2.mat' into a CSV file 'dataHW1_Problem2.csv'.
    Libraries:
    - numpy: for numerical operations
    - pandas: for data manipulation and analysis
    - scipy.io: for loading MATLAB files
"""

mat = loadmat('dataHW1_Problem2.mat') # Load the .mat file
X = mat['X'] # Extract X matrix
Y = mat['Y'] # Extract Y vector

if Y.ndim > 1 and Y.shape[1] == 1:
    Y = Y.reshape(-1)           # Reshape Y to be a 1D array if necessary

df = pd.DataFrame(
    np.column_stack([Y, X]),
    columns = ['Y'] + [f'X{j+1}' for j in range(X.shape[1])]
) # Create DataFrame with appropriate column names

df.to_csv('dataHW1_Problem2.csv', index = False)   # Save DataFrame to CSV file without index
