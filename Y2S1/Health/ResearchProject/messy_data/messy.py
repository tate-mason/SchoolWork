import datetime

############################################################################################
# Purpose: This script simulates a messy dataset and performs analysis on it, including    #
# value funciton iteration and optimization.                                               #
############################################################################################

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.optimize import minimize
import seaborn as sns

# Set random seed for reproducibility
np.random.seed(219)
sns.set(style="whitegrid")
plt.rcParams.update({'font.size': 14})
pd.set_option('display.float_format', lambda x: '%.4f' % x)
today = datetime.date.today().strftime("%Y-%m-%d")
output_dir = f"output/messy_{today}/"
import os
os.makedirs(output_dir, exist_ok=True)
# Simulate a messy dataset
n_samples = 1000
data = {
# Risk aversion: high or low
    'risk_aversion': np.random.choice(['high', 'low'], size=n_samples),
# Drug tolerance: high or low
    'drug_tolerance': np.random.choice(['high', 'low'], size=n_samples),
# Beta parameter: 0.94
    'beta': np.random.choice([0.94], size=n_samples),
# Risk error: normally distributed noise
    'risk_error': np.random.normal(0, 0.1, size=n_samples),
# Prescribing Prob: probability of prescribing a drug
    'prescribing_prob': np.random.uniform(0, 1, size=n_samples)
}
df = pd.DataFrame(data)

# Addict Specific Parameters
# Addict Risk Aversion
# High risk aversion leads to a lower probability of reengaging in searching for drugs
# Low risk aversion leads to a higher probability of reengaging in searching for drugs
df['addict_risk_aversion'] = df['risk_aversion'].apply(lambda x: 0.8 if x == 'high' else 0.2)
# Addict Drug Tolerance
# High drug tolerance leads to a higher probability of reengaging in searching for drugs, since doctors will not prescribe more
# Low drug tolerance leads to a lower probability of reengaging in searching for drugs, since doctors will prescribe more without violating their constaint
df['addict_drug_tolerance'] = df['drug_tolerance'].apply(lambda x: 0.7 if x == 'high' else 0.3)
# Addict risk aversion growth path: r' = r + risk_error
df['addict_risk_aversion_growth'] = df['addict_risk_aversion'] + df['risk_error']
# Search cost: Start at 1, increase by 0.5 for each failed search
df['search_cost'] = 1 + 0.5 * (1 - df['prescribing_prob'])
# Prescriptions: number of prescriptions received, influenced by drug tolerance
df['prescriptions'] = df['addict_drug_tolerance'] * 10
# Addict U(c) function: CRRA
def utility(c, risk_aversion):
    if risk_aversion == 1:
        return np.log(c)
    else:
        return (c**(1 - risk_aversion)) / (1 - risk_aversion)
# Addict Consumption: c = gamma*prescriptions + r^(1/gamma)*sum(search_cost)
# where gamma is drug tolerance
df['consumption'] = df['addict_drug_tolerance'] * df['prescriptions'] + \
                    df['addict_risk_aversion_growth']**(1/df['addict_risk_aversion']) * df['search_cost']
# Addict bellmans:
# Initial state: V0(risk_aversion, drug_tolerance) = U(consumption) + beta * (1-prescribing_prob) * V0(risk_aversion, drug_tolerance) + beta * prescribing_prob * V1(risk_aversion', drug_tolerance)
# If matched: V1(risk_aversion', drug_tolerance) = max(V_stay, V_find)
# Where V_stay = U(consumption) + beta * V1(risk_aversion, drug_tolerance)
# and V_find = U(consumption) + beta * (1-prescribing_prob) * V0(risk_aversion, drug_tolerance) + beta * prescribing_prob * V1(risk_aversion', drug_tolerance)
def bellman_initial(row, V0, V1):
    u = utility(row['consumption'], row['addict_risk_aversion'])
    expected_value = row['beta'] * ((1 - row['prescribing_prob']) * V0 + row['prescribing_prob'] * V1)
    return u + expected_value
def bellman_matched(row, V0, V1):
    u = utility(row['consumption'], row['addict_risk_aversion'])
    V_stay = u + row['beta'] * V1
    V_find = u + row['beta'] * ((1 - row['prescribing_prob']) * V0 + row['prescribing_prob'] * V1)
    return max(V_stay, V_find)
# Value Function Iteration
V0 = 0
V1 = 0
tolerance = 1e-6
max_iterations = 1000
for iteration in range(max_iterations):
    V0_new = df.apply(lambda row: bellman_initial(row, V0, V1), axis=1).mean()
    V1_new = df.apply(lambda row: bellman_matched(row, V0, V1), axis=1).mean()
    if abs(V0_new - V0) < tolerance and abs(V1_new - V1) < tolerance:
        break
    V0, V1 = V0_new, V1_new
# Output results
df['V0'] = V0
df['V1'] = V1
df.to_csv(os.path.join(output_dir, "messy_dataset_analysis.csv"), index=False)
# Plotting the distribution of consumption
plt.figure(figsize=(10, 6))
sns.histplot(df['consumption'], bins=30, kde=True)
plt.title('Distribution of Consumption')
plt.xlabel('Consumption')
plt.ylabel('Frequency')
plt.savefig(os.path.join(output_dir, "consumption_distribution.png"))
plt.close()
# Plotting the value functions
plt.figure(figsize=(10, 6))
sns.histplot(df['V0'], color='blue', label='V0', bins=30, kde=True, stat="density", alpha=0.6)
sns.histplot(df['V1'], color='orange', label='V1', bins=30, kde=True, stat="density", alpha=0.6)
plt.title('Distribution of Value Functions V0 and V1')
plt.xlabel('Value Function')
plt.ylabel('Density')
plt.legend()
plt.savefig(os.path.join(output_dir, "value_function_distribution.png"))
plt.close()
print(f"Analysis complete. Results saved in {output_dir}")
