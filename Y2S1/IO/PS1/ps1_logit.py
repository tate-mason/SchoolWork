
globals().clear()

"""
PyBLP Implementation - Fixed for current API
Install: pip install pyblp
"""
import pandas as pd
import numpy as np
import pyblp

# Set random seed for reproducibility
np.random.seed(42)

# =============================================================================
# LOAD AND PREPARE DATA
# =============================================================================

print("Loading data...")
df = pd.read_csv("~/SchoolWork/Y2S1/IO/PS1/iri.csv", sep='\t')

# Load demographics
income_df = pd.read_csv("simulated_agents_income.csv", sep='\t')
nchild_df = pd.read_csv("simulated_agents_nchild.csv", sep='\t')

# Create market ID
df['market_ids'] = df['store_id'].astype(str) + '_' + df['week_id'].astype(str)

# Calculate shares
df['shares'] = df['quantity'] / df['M']

# PyBLP requires 'prices' (plural) column
df['prices'] = df['price']

# PyBLP requires 'firm_ids' for supply-side or when using X3
df['firm_ids'] = df['parent']  # Parent company is the firm

# Create product IDs (must be unique within market)
df['product_ids'] = df['brand'] + '_' + df['parent']

# Take subset for testing
test_markets = df['market_ids'].unique()
df_test = df[df['market_ids'].isin(test_markets)].copy().reset_index(drop=True)

print(f"Dataset: {len(df_test)} obs, {df_test['market_ids'].nunique()} markets")
print(f"Share range: [{df_test['shares'].min():.4f}, {df_test['shares'].max():.4f}]")

# =============================================================================
# CREATE INSTRUMENTS
# =============================================================================

print("\nCreating instruments...")

# BLP instruments - competitor characteristics
for char in ['sugars', 'fiber']:
    df_test[f'blp_{char}'] = 0.0
    
    for market in df_test['market_ids'].unique():
        market_mask = df_test['market_ids'] == market
        market_data = df_test[market_mask]
        n_products = len(market_data)
        
        if n_products <= 1:
            continue
        
        for idx in market_data.index:
            competitors = df_test[(df_test['market_ids'] == market) & (df_test.index != idx)]
            if len(competitors) > 0:
                comp_sum = competitors[char].sum()
                own_val = df_test.loc[idx, char]
                # BLP formula: (mean_competitors - own)^2
                df_test.loc[idx, f'blp_{char}'] = ((comp_sum / len(competitors)) - own_val) ** 2

# Cost shifter: sugar price × sugar content
df_test['demand_instruments0'] = np.log(df_test['sugars'] * df_test['sugar_price'] + 0.01)
df_test['demand_instruments1'] = df_test['blp_sugars']
df_test['demand_instruments2'] = df_test['blp_fiber']

print("Instruments created")

# =============================================================================
# PREPARE AGENT DATA (Demographics)
# =============================================================================

print("\nPreparing agent data...")

n_draws = 50  # Number of simulation draws per market
income_cols = [col for col in income_df.columns if col.startswith('income')][:n_draws]
nchild_cols = [col for col in nchild_df.columns if col.startswith('nchild')][:n_draws]

agent_data_list = []

for market in df_test['market_ids'].unique():
    market_df = df_test[df_test['market_ids'] == market].iloc[0:1]
    
    # Get puma and year for this market
    puma = market_df['puma'].values[0]
    year = market_df['year'].values[0]
    
    # Get demographic draws for this puma/year
    income_row = income_df[(income_df['puma'] == puma) & (income_df['year'] == year)]
    nchild_row = nchild_df[(nchild_df['puma'] == puma) & (nchild_df['year'] == year)]
    
    if len(income_row) > 0 and len(nchild_row) > 0:
        incomes = income_row[income_cols].values[0] / 10000  # Normalize
        nchilds = nchild_row[nchild_cols].values[0]
        
        # Create agent data for this market
        for i in range(n_draws):
            agent_data_list.append({
                'market_ids': market,
                'weights': 1.0 / n_draws,
                'income': incomes[i],
                'nchild': nchilds[i],
                'nodes0': np.random.randn(),  # For sugar RC
                'nodes1': np.random.randn()   # For fiber RC
            })

agent_data = pd.DataFrame(agent_data_list)
print(f"Agent data: {len(agent_data)} agents across {agent_data['market_ids'].nunique()} markets")

# =============================================================================
# PYBLP FORMULATIONS
# =============================================================================

print("\n" + "="*70)
print("SETTING UP PYBLP PROBLEM")
print("="*70)

# X1: Linear parameters (including prices which will be instrumented)
product_formulations = (
    pyblp.Formulation('0 + prices + flavored + fortified + fiber + sugars'),
    # X2: Random coefficients on sugar and fiber
    pyblp.Formulation('0 + sugars + fiber'),
    # X3: Demographic interactions (sugar×income, fiber×income)
    pyblp.Formulation('0 + blp_sugars + blp_fiber')
)

# Agent formulation for demographics
agent_formulation = pyblp.Formulation('0 + income + nchild')

# Create problem
problem = pyblp.Problem(
    product_formulations=product_formulations,
    product_data=df_test,
    agent_formulation=agent_formulation,
    agent_data=agent_data
)

print(problem)

# =============================================================================
# INITIAL VALUES
# =============================================================================

print("\n" + "="*70)
print("SETTING INITIAL PARAMETERS")
print("="*70)

# Sigma (random coefficient std deviations) for [sugars, fiber]
initial_sigma = np.diag([0.1, 0.1])

# Pi (demographic interactions) for [sugars×income, sugars×nchild; fiber×income, fiber×nchild]
initial_pi = np.array([
    [0.01, 0.01],  # sugars interactions
    [0.01, 0.01]   # fiber interactions
])

# Beta (linear parameters) - REQUIRED when firm_ids is present
# Order: [prices, flavored, fortified, fiber, sugars]
initial_beta = np.array([
    [-3.0],   # price coefficient (negative)
    [0.01],    # flavored
    [0.01],    # fortified
    [0.1],    # fiber (positive preference)
    [0.1]    # sugars (negative preference for too much sugar)
])

print(f"Initial Sigma:\n{initial_sigma}")
print(f"Initial Pi:\n{initial_pi}")
print(f"Initial Beta:\n{initial_beta.flatten()}")

# =============================================================================
# ESTIMATION
# =============================================================================

print("\n" + "="*70)
print("STARTING ESTIMATION (this may take several minutes...)")
print("="*70)

# Solve the problem
results = problem.solve(
    sigma=initial_sigma,
    pi=initial_pi,
    beta=initial_beta,  # ADD initial beta values
    optimization=pyblp.Optimization('l-bfgs-b', {
        'maxiter': 1000,
        'gtol': 1e-5
    }),
    iteration=pyblp.Iteration('squarem', {
        'atol': 1e-12,
        'max_evaluations': 1000
    })
)

# =============================================================================
# RESULTS
# =============================================================================

print("\n" + "="*70)
print("ESTIMATION RESULTS")
print("="*70)
print(results)

# Extract and display parameters
print("\n" + "="*70)
print("PARAMETER ESTIMATES")
print("="*70)

print("\n1. Linear Parameters (β):")
beta_df = pd.DataFrame({
    'Parameter': ['prices', 'flavored', 'fortified', 'fiber', 'sugars'],
    'Estimate': results.beta.flatten(),
    'Std Error': results.beta_se.flatten()
})
print(beta_df.to_string(index=False))

print("\n2. Random Coefficient Std Deviations (Σ):")
sigma_df = pd.DataFrame({
    'Parameter': ['σ_sugars', 'σ_fiber'],
    'Estimate': np.diag(results.sigma),
    'Std Error': np.diag(results.sigma_se) if results.sigma_se is not None else [np.nan, np.nan]
})
print(sigma_df.to_string(index=False))

print("\n3. Demographic Interactions (Π):")
pi_df = pd.DataFrame(
    results.pi,
    index=['sugars', 'fiber'],
    columns=['income', 'nchild']
)
print("Estimates:")
print(pi_df)

if results.pi_se is not None:
    pi_se_df = pd.DataFrame(
        results.pi_se,
        index=['sugars', 'fiber'],
        columns=['income', 'nchild']
    )
    print("\nStandard Errors:")
    print(pi_se_df)

# Diagnostics
print("\n" + "="*70)
print("DIAGNOSTICS")
print("="*70)

print(f"GMM Objective Value: {float(results.objective):.6e}")
print(f"Optimization Status: {float(results.optimization_time):.6e}")


print("\n" + "="*70)
print("ESTIMATION COMPLETE")
print("="*70)

# Save results if desired
# results_df = pd.DataFrame({
#     'beta': results.beta.flatten(),
#     'sigma': np.diag(results.sigma)
# })
# results_df.to_csv('blp_results.csv', index=False)

# Create histogram of own price elasticities
elasticities = results.compute_elasticities()
own_price_elasticities = np.diag(elasticities)
import matplotlib.pyplot as pyplot
pyplot.hist(own_price_elasticities, bins=30, edgecolor='k')
pyplot.title('Histogram of Own Price Elasticities')
pyplot.xlabel('Own Price Elasticity')
pyplot.ylabel('Frequency')
pyplot.grid(True)
pyplot.show()
print("\nHistogram of own price elasticities displayed.")

# Construct elasticity matrix for top 5 brands in terms of sales (own and cross-price elasticities)
