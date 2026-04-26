import numpy as np
import pandas as pd
import scipy as sp

"""
Data dictionary:
    - Observed:
       - year,year
       - county,fips code for county
       - mode,shopping mode. Amazon=1, taxed online competitors=2, non-taxed online competitors=3
       - nb_hh,total households in county
       - avg_spending_annual_county,total retail spending in county=Mode 1+Mode 2+Mode 3 + Mode 0
       - tax_rate,sales tax rate
       - alpha,preferences for county/year/mode
       - pop_density,population density in county
       - rent,rental rate per square foot
       - wage,annual wage for employee at facility
       - min_dist0,shippng distance from FC to county
       - presence_state0,dummy variable indicating if there is FC in the state that the county is located
       - tot_empl0,Total employment at FCs in the county
       - tot_size0,Total square feet of space of FCs in the county
       - presence_county0,dummy variable indicating if there is FC in the the county
    - Perturbation:
       - year,year
       - county,fips code for county
       - min_dist1,shippng distance from FC to county
       - presence_state1,dummy variable indicating if there is FC in the state that the county is located
       - tot_empl1,Total employment at FCs in the county
       - tot_size1,Total square feet of space of FCs in the county
       - swapid,swap number
       - presence_county1,dummy variable indicating if there is FC in the the county
"""

data_obs = pd.read_csv('../../Data/data_observed.csv', sep='\t')
data_perturb1 = pd.read_csv('../../Data/perturb_data1.csv', sep='\t')
data_perturb2 = pd.read_csv('../../Data/perturb_data2.csv', sep='\t')
data_perturb3 = pd.read_csv('../../Data/perturb_data3.csv', sep='\t')
data_perturb4 = pd.read_csv('../../Data/perturb_data4.csv', sep='\t')


print("Data Observed:")
print(data_obs.head())

print("\nPerturbation Data 1:")
print(data_perturb1.head())

print("\nPerturbation Data 2:")
print(data_perturb2.head())

print("\nPerturbation Data 3:")
print(data_perturb3.head())

print("\nPerturbation Data 4:")
print(data_perturb4.head())

# === Problem 1 === #

mu = 0.15 # discounted revenue
beta = 0.95 # discount factor


mask = data_obs['mode'] == 1
data_obs_amazon = data_obs[mask].copy()
offline = data_obs['mode'] == 0
data_obs_offline = data_obs[offline].copy()

t = data_obs_amazon['year'] - data_obs_amazon['year'].min()
discount = beta**t

data_obs_amazon['tau'] = data_obs_amazon['tax_rate']*data_obs_amazon['presence_state0']
data_obs_amazon['choice'] = data_obs_amazon['alpha'] + 2.5*np.log(1 + data_obs_amazon['tau'])

results_obs = {
    'gross_revenue': np.sum(discount*data_obs_amazon['nb_hh']*np.exp(data_obs_amazon['choice'])),
    'labor_cost': np.sum(discount*data_obs_amazon['tot_empl0']*data_obs_amazon['wage']),
    'rent_cost': np.sum(discount*data_obs_amazon['tot_size0']*data_obs_amazon['rent']),
    'ship_dist': np.sum(discount*data_obs_amazon['min_dist0']),
    'pop_dens': np.sum(discount*data_obs_amazon['pop_density']),
    'tax_rate': np.sum(discount*data_obs_amazon['nb_hh'] * data_obs_amazon['tau']) / np.sum(discount*data_obs_amazon['nb_hh'])
}

print("\nResults for Observed Data:")
for key, value in results_obs.items():
    print(f"{key}: {value:.2f}")
