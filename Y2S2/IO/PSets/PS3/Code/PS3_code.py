###############################################################################
# PS3 Code – Econ 8220, Spring 2026 | Tate Mason
###############################################################################

import pandas as pd
import numpy as np

# ===========================================================================
# Parameters
# ===========================================================================
sigma   = 1.5    # demand elasticity (1 - sigma = -0.5)
beta    = 0.95   # discount factor
mu      = 0.15   # Amazon profit margin
base_yr = 1999   # base year for discounting

# ===========================================================================
# Step 1. Load and parse observed data
# ===========================================================================
obs = pd.read_csv('../Data/data_observed.csv', sep='\t')

# Pivot so each county-year has one row with alpha for each mode (1, 2, 3)
# Long --> Wide: index = county-year, columns = mode, values = alpha
obs_piv = obs.pivot_table(
    index=['year', 'county'], columns='mode', values=['alpha'], aggfunc='first'
).reset_index()
obs_piv.columns = ['year', 'county', 'alpha1', 'alpha2', 'alpha3']

# Pull non-alpha columns from mode==1 rows (same across modes within county-year)
other = obs[obs['mode'] == 1][[
    'year', 'county', 'nb_hh', 'avg_spending_annual_county', 'tax_rate',
    'pop_density', 'rent', 'wage', 'min_dist0',
    'presence_state0', 'tot_empl0', 'tot_size0', 'presence_county0'
]].copy()

df = obs_piv.merge(other, on=['year', 'county'])

# ===========================================================================
# Step 2. Compute spending by mode using the demand system
# ===========================================================================
# Effective tax rates by mode:
#   tau_0 = tax_rate  (offline always taxed)
#   tau_1 = tax_rate * presence_state0  (Amazon taxed only if FC in state)
#   tau_2 = tax_rate  (taxed online always)
#   tau_3 = 0         (untaxed online never)
#
# Simplifications:
#   j=2: tau_2 = tau_0  =>  log ratio = alpha_2  (tax terms cancel exactly)
#   j=3: tau_3 = 0      =>  log ratio = alpha_3 + (1-sigma)*[log(1) - log(1+tau_0)]
#   j=1: ratio depends on presence_state0

df['tau0'] = df['tax_rate']
df['tau1'] = df['tax_rate'] * df['presence_state0']

df['ratio1'] = np.exp(
    df['alpha1'] + (1 - sigma) * (np.log(1 + df['tau1']) - np.log(1 + df['tau0']))
)
df['ratio2'] = np.exp(df['alpha2'])   # tau2 = tau0, difference is zero
df['ratio3'] = np.exp(
    df['alpha3'] + (1 - sigma) * (np.log(1 + 0) - np.log(1 + df['tau0']))
)

# Solve for levels:
#   e_total = e_0 * (1 + r1 + r2 + r3)  =>  e_0 = e_total / (1 + r1 + r2 + r3)
#   e_j = r_j * e_0
df['e0'] = df['avg_spending_annual_county'] / (1 + df['ratio1'] + df['ratio2'] + df['ratio3'])
df['e1'] = df['ratio1'] * df['e0']

# Sanity check
assert np.allclose(
    df['e0'] + df['e1'] + df['ratio2'] * df['e0'] + df['ratio3'] * df['e0'],
    df['avg_spending_annual_county']
), "Spending shares don't sum to total — check demand system."

# ===========================================================================
# Step 3. Observed quantities for each county-year
# ===========================================================================
df['rev_o']  = df['nb_hh'] * df['e1']                        # Amazon gross revenue
df['lab_o']  = df['wage']  * df['tot_empl0']                 # labor cost
df['land_o'] = df['rent']  * df['tot_size0']                 # land cost
df['pop_o']  = df['pop_density'] * df['presence_county0']    # effective pop density

df['disc'] = beta ** (df['year'] - base_yr)

# Population-weighted Amazon tax rate components
df['tau1']   = df['tax_rate'] * df['presence_state0']
df['nb_tau1'] = df['nb_hh'] * df['tau1']

def disc_sum(df, col):
    """Aggregate col across counties within each year, then discount and sum over years."""
    annual = df.groupby('year')[col].sum()
    return (annual * (beta ** (annual.index - base_yr))).sum()

obs_R = disc_sum(df, 'rev_o')
obs_L = disc_sum(df, 'lab_o')
obs_K = disc_sum(df, 'land_o')
obs_D = disc_sum(df, 'min_dist0')
obs_P = disc_sum(df, 'pop_o')

obs_nbhh_disc = disc_sum(df, 'nb_hh')
obs_tax_sum   = disc_sum(df, 'nb_tau1')
obs_tax_rate  = obs_tax_sum / obs_nbhh_disc

print("=== Observed Discounted Sums ===")
print(f"  Gross Revenue:              ${obs_R:>20,.2f}")
print(f"  Labor Cost:                 ${obs_L:>20,.2f}")
print(f"  Land Cost:                  ${obs_K:>20,.2f}")
print(f"  Shipping Distance:           {obs_D:>20,.2f}  county-miles")
print(f"  Effective Pop. Density:      {obs_P:>20,.2f}")
print(f"  Pop.-wtd avg Amazon tax:     {obs_tax_rate:.4f}")

# ===========================================================================
# Step 4. Load perturbation files and compute swap-level deltas
# ===========================================================================
p_all = pd.concat(
    [pd.read_csv(f'../Data/perturb_data{i}.csv', sep='\t') for i in range(1, 5)],
    ignore_index=True
)
print(f"\nLoaded {len(p_all):,} perturb rows across {p_all['swapid'].nunique()} swaps.")

# Merge observed quantities onto perturb rows
obs_cols = ['year', 'county',
            'alpha1', 'alpha2', 'alpha3',
            'nb_hh', 'avg_spending_annual_county', 'tax_rate',
            'pop_density', 'rent', 'wage',
            'min_dist0', 'presence_state0', 'tot_empl0', 'tot_size0', 'presence_county0',
            'rev_o', 'lab_o', 'land_o', 'pop_o', 'disc', 'tau1']
pm = p_all.merge(df[obs_cols], on=['year', 'county'], how='left')

# Perturbed spending (e1 under new network)
pm['tau1_p']   = pm['tax_rate'] * pm['presence_state1']
pm['ratio1_p'] = np.exp(
    pm['alpha1'] + (1 - sigma) * (np.log(1 + pm['tau1_p']) - np.log(1 + pm['tax_rate']))
)
pm['ratio2_p'] = np.exp(pm['alpha2'])
pm['ratio3_p'] = np.exp(
    pm['alpha3'] + (1 - sigma) * (np.log(1 + 0) - np.log(1 + pm['tax_rate']))
)
pm['e1_p'] = (
    pm['avg_spending_annual_county'] /
    (1 + pm['ratio1_p'] + pm['ratio2_p'] + pm['ratio3_p'])
) * pm['ratio1_p']

# Perturbed quantities
pm['rev_p']  = pm['nb_hh'] * pm['e1_p']
pm['lab_p']  = pm['wage']  * pm['tot_empl1']
pm['land_p'] = pm['rent']  * pm['tot_size1']
pm['pop_p']  = pm['pop_density'] * pm['presence_county1']

# Discounted deltas: (observed - perturbed) * discount factor
for col, obs_c, pert_c in [
    ('rev',  'rev_o',   'rev_p'),
    ('lab',  'lab_o',   'lab_p'),
    ('land', 'land_o',  'land_p'),
    ('dist', 'min_dist0', 'min_dist1'),
    ('pop',  'pop_o',   'pop_p'),
]:
    pm[f'ddelta_{col}'] = (pm[obs_c] - pm[pert_c]) * pm['disc']

# For population-weighted tax rate
pm['delta_wtax'] = (pm['tau1'] - pm['tau1_p']) * pm['nb_hh'] * pm['disc']

# Aggregate deltas to swap level
swap = pm.groupby('swapid')[[
    'ddelta_rev', 'ddelta_lab', 'ddelta_land',
    'ddelta_dist', 'ddelta_pop', 'delta_wtax'
]].sum()

perturb_q1 = pd.DataFrame({
    'revenue':     obs_R        - swap['ddelta_rev'],
    'labor':       obs_L        - swap['ddelta_lab'],
    'land':        obs_K        - swap['ddelta_land'],
    'distance':    obs_D        - swap['ddelta_dist'],
    'pop_density': obs_P        - swap['ddelta_pop'],
    'tax_rate':   (obs_tax_sum  - swap['delta_wtax']) / obs_nbhh_disc,
}, index=swap.index)
 
print("\nMeans:")
print(perturb_q1.mean())
# ===========================================================================
# Step 5. Build 10-column panel and estimation variables
# ===========================================================================
panel = pd.DataFrame(index=swap.index)

# Columns 1-5: observed (constant across swaps)
panel['obs_rev']  = obs_R
panel['obs_lab']  = obs_L
panel['obs_land'] = obs_K
panel['obs_dist'] = obs_D
panel['obs_pop']  = obs_P

# Columns 6-10: perturbed = observed + (perturbed - observed)
panel['pert_rev']  = obs_R - swap['ddelta_rev']
panel['pert_lab']  = obs_L - swap['ddelta_lab']
panel['pert_land'] = obs_K - swap['ddelta_land']
panel['pert_dist'] = obs_D - swap['ddelta_dist']
panel['pert_pop']  = obs_P - swap['ddelta_pop']

panel['delta_rev']  = panel['obs_rev']  - panel['pert_rev']
panel['delta_lab']  = panel['obs_lab']  - panel['pert_lab']
panel['delta_land'] = panel['obs_land'] - panel['pert_land']
panel['delta_dist'] = panel['obs_dist'] - panel['pert_dist']
panel['delta_pop']  = panel['obs_pop']  - panel['pert_pop']

# Estimation variables from the revealed-preference inequality:
panel['y_tilde'] = mu * panel['delta_rev'] - panel['delta_lab'] - panel['delta_land']
panel['x_d']     = panel['delta_dist']
panel['x_p']     = panel['delta_pop']

# Perturbed population-weighted tax rate
panel['tax_rate_pert'] = (obs_tax_sum + swap['delta_wtax']) / obs_nbhh_disc


panel.to_csv('../Data/estimation_panel.csv')
print("\n10-column estimation panel saved to estimation_panel.csv")
print(f"  Number of swaps: {len(panel)}")

# ===========================================================================
# Question 2. Pairwise Correlations
# ===========================================================================
print("\n=== Question 2: Pairwise Correlations ===")
corr_df = panel[['pert_rev', 'pert_lab', 'pert_land', 'pert_dist', 'pert_pop', 'tax_rate_pert']].rename(
    columns={
        'pert_rev':       'Revenue',
        'pert_lab':       'Labor',
        'pert_land':      'Land',
        'pert_dist':      'Distance',
        'pert_pop':       'Pop. Density',
        'tax_rate_pert':  'Tax Rate'
    }
)
print(corr_df.corr().round(3).to_string())

# ===========================================================================
# Exercise 3.1(a). Isolate gamma — conditioning on |x_p| < 25th percentile
# ===========================================================================
print("\n=== Exercise 3.1(a): gamma bounds, conditioning on |x_p| < p25 ===")

abs_xp  = panel['x_p'].abs()
p25_xp  = abs_xp.quantile(0.25)
sub_a   = panel[abs_xp <= p25_xp]
pos_a   = sub_a[sub_a['x_d'] > 0]   # observed has longer distance → UB on gamma
neg_a   = sub_a[sub_a['x_d'] < 0]   # observed has shorter distance → LB on gamma

# Rearranging by sign of sum(x_d):
ub_a = pos_a['y_tilde'].sum() / pos_a['x_d'].sum()
lb_a = neg_a['y_tilde'].sum() / neg_a['x_d'].sum()

print(f"  25th percentile of |x_p|: {p25_xp:.2f}")
print(f"  Swaps used: {len(sub_a)} total ({len(pos_a)} with x_d>0, {len(neg_a)} with x_d<0)")
print(f"  Upper bound on gamma (x_d>0 group): {ub_a:.4f}")
print(f"  Lower bound on gamma (x_d<0 group): {lb_a:.4f}")
print(f"  Identified interval: [{min(lb_a, ub_a):.4f}, {max(lb_a, ub_a):.4f}]")

panel['delta_tax'] = panel['tax_rate_pert'] - obs_tax_rate  # or however you stored it

abs_xd      = panel['x_d'].abs()
abs_dtax    = panel['delta_tax'].abs()

# Thresholds — tune these
xd_thresh   = abs_xd.quantile(0.50)      
tax_thresh  = abs_dtax.quantile(0.25)    

# Refined groups
pos_refined = panel[(panel['x_d'] > xd_thresh) & (abs_dtax <= tax_thresh)]
neg_refined = panel[(panel['x_d'] < -xd_thresh) & (abs_dtax <= tax_thresh)]

ub_refined = pos_refined['y_tilde'].sum() / pos_refined['x_d'].sum()
lb_refined = neg_refined['y_tilde'].sum() / neg_refined['x_d'].sum()

print("\n=== Refined bounds with additional tax change conditioning ===")
print(f"  Thresholds: |x_d| > {xd_thresh:.2f},  |delta_tax| <= {tax_thresh:.4f}")
print(f"  Swaps used: {len(pos_refined)} with x_d > {xd_thresh:.2f}, {len(neg_refined)} with x_d < {-xd_thresh:.2f}")
print(f"  Upper bound on gamma: {ub_refined:.4f}")
print(f"  Lower bound on gamma: {lb_refined:.4f}")
print(f"  Identified interval: [{min(lb_refined, ub_refined):.4f}, {max(lb_refined, ub_refined):.4f}]")
# ===========================================================================
# Exercise 3.1(b). Gamma bounds — all swaps, no conditioning
# ===========================================================================
print("\n=== Exercise 3.1(b): gamma bounds, all swaps ===")

pos_b = panel[panel['x_d'] > 0]
neg_b = panel[panel['x_d'] < 0]
ub_b  = pos_b['y_tilde'].sum() / pos_b['x_d'].sum()
lb_b  = neg_b['y_tilde'].sum() / neg_b['x_d'].sum()

print(f"  Swaps: {len(pos_b)} with x_d>0, {len(neg_b)} with x_d<0")
print(f"  Upper bound on gamma: {ub_b:.4f}")
print(f"  Lower bound on gamma: {lb_b:.4f}")
print(f"  Identified interval: [{min(lb_b, ub_b):.4f}, {max(lb_b, ub_b):.4f}]")

