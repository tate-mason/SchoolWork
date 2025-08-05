import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import fredapi
import os
from datetime import datetime
import seaborn as sns

# Set up paths
root_path = "~/Dropbox/Schoolwork/Macro1/ProblemSets/PS0"
code_path = os.path.join(root_path, "code")
data_path = os.path.join(root_path, "Data")
output_path = os.path.join(root_path, "Output")

# Initialize FRED API
fred = fredapi.Fred(api_key='3937d3e1a400536de448b9415c9114d9')

# Set plot style
plt.style.use('seaborn')

# Problem 2
def problem_2():
    # Part A
    pcend = fred.get_series('PCEND')
    pces = fred.get_series('PCES')
    gdp = fred.get_series('GDP')
    
    # Filter data after 2005
    start_date = '2005-01-01'
    df = pd.DataFrame({
        'PCEND': pcend,
        'PCES': pces,
        'GDP': gdp
    }).loc[start_date:]
    
    df['PCENDS'] = df['PCEND'] + df['PCES']
    df['pce_percent_gdp'] = df['PCENDS'] / df['GDP']
    
    plt.figure(figsize=(10, 6))
    plt.plot(df.index, df['pce_percent_gdp'])
    plt.title('Consumption of Non-Durables and Services: % of GDP')
    plt.xlabel('Time')
    plt.ylabel('Percentage of GDP')
    plt.savefig(os.path.join(output_path, 'graph2a.png'))
    plt.close()
    
    # Parts B through G follow similar pattern...

# Problem 3
def problem_3():
    # Part A
    gdp_pc = fred.get_series('A939RX0Q048SBEA')
    df = pd.DataFrame({'GDP': gdp_pc})
    df['rGDP_pc'] = np.log(df['GDP'])
    
    # Create date numeric values for regression
    df['date_num'] = (df.index - df.index[0]).days
    
    # Fit linear regression
    from sklearn.linear_model import LinearRegression
    X = df['date_num'].values.reshape(-1, 1)
    y = df['rGDP_pc'].values
    model = LinearRegression()
    model.fit(X, y)
    df['trend'] = model.predict(X)
    df['dt_GDP'] = df['rGDP_pc'] - df['trend']
    
    # Plot results
    plt.figure(figsize=(10, 6))
    plt.plot(df.index, df['rGDP_pc'])
    plt.plot(df.index, df['trend'])
    plt.title('Log Real GDP per Capita with Trend')
    plt.savefig(os.path.join(output_path, '3aa.png'))
    plt.close()
    
    # Parts B through E follow similar pattern...

# Problem 4-8 follow similar patterns...

if __name__ == "__main__":
    problem_2()
    # problem_3()
    # etc...
