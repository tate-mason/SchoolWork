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

sigma = 1.5
beta = 0.9
mu = 0.15

# read in data
obs = pd.read_csv('../../Data/data_observed.csv', sep='\t')

# reshape data to have one row per county/year with alpha for each mode
obs_piv = obs.pivot_table(
    index = ['year', 'county'], columns='mode', values=['alpha'], aggfunc='first'
).reset_index()

obs_piv.columns = ['year', 'county', 'alpha1', 'alpha2', 'alpha3'] # rename columns

other = obs[obs['mode'] == 1][[
    'year', 'county', 'nb_hh', 'avg_spending_annual_county', 'tax_rate',
    'pop_density', 'rent', 'wage', 'min_dist0', 'presence_state0',
    'tot_empl0', 'tot_size0', 'presence_county0'
]].copy()

df = obs_piv.merge(other, on=['year', 'county'])

# Tax Rates

df['tau0'] = df['tax_rate'] # offline - always taxed (reused for j = 2)
df['tau1'] = df['tax_rate'] * df['presence_state0'] # amazon - taxed if FC in state

# Expenditure Functions

df['e1_ratio'] = np.exp(
    df['alpha1'] + (1-sigma)*(np.log(1+df['tau1']) - np.log(1+df['tau0']))
)

df['e2_ratio'] = np.exp(df['alpha2'])
df['e3_ratio'] = np.exp(
    df['alpha3'] + (1-sigma)*(np.log(1) - np.log(1+df['tau0']))
)

df['e0'] = df['avg_spending_annual_county'] / (1 + df['e1_ratio'] + df['e2_ratio'] + df['e3_ratio'])

df['e1'] = df['e0'] * df['e1_ratio']

# Observed Data

df['rev_obs'] = df['nb_hh'] * df['e1'] # observed gross revenue
df['lab_obs'] = df['wage'] * df['tot_empl0'] # observed labor cost  
df['land_obs'] = df['rent'] * df['tot_size0'] # observed capital cost
df['pop_obs'] = df['pop_density']*df['presence_county0'] # observed population density

df['disc'] = beta ** (df['year'] - df['year'].min()) # discount factor
 
df['nb_tau1'] = df['nb_hh']*df['tau1'] # population adjusted tax rate

def disc_sum(df, col):
    annual = df.groupby('year')[col].sum()
    reutrn (annual*(beta**(annual.index - df['year'].min()))).sum()

obs_R = disc_sum(df, 'rev_obs')
obs_L = disc_sum(df, 'lab_obs')
obs_K = disc_sum(df, 'land_obs')
obs_D = disc_sum(df, 'min_dist0')
obs_P = disc_sum(df, 'pop_obs')

obs_nbhh_disc = disc_sum(df, 'nb_hh')
obs_tax_sum = disc_sum(df, 'nb_tau1')
obs_tax_rate = obs_tax_sum / obs_nbhh_disc

print("=== Observed Discounted Sums ===")
print(f"  Gross Revenue:              ${obs_R:>20,.2f}")
print(f"  Labor Cost:                 ${obs_L:>20,.2f}")
print(f"  Land Cost:                  ${obs_K:>20,.2f}")
print(f"  Shipping Distance:           {obs_D:>20,.2f}  county-miles")
print(f"  Effective Pop. Density:      {obs_P:>20,.2f}")
print(f"  Pop.-wtd Avg. Tax (AMZN):    {obs_tax_rate:>20,.2f}")

# === Perturbation === #


