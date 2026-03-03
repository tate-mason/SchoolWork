import numpy as np
import pandas as pd
import scipy as sp
import matplotlib.pyplot as plt
from numpy import std
import statsmodels.api as sm
from statsmodels.sandbox.regression.gmm import IV2SLS
from scipy.optimize import root
import seaborn as sns

"""
Main file for Problem Set 1 - IO2
"""

df = pd.read_csv('../Data/full_data_zone.csv') # import the long version of the data
print(df.head())

df_l = pd.read_csv('../Data/full_data_zone_long.csv')

WM_active_markets = df["active1"].sum()
TT_active_markets = df["active2"].sum()

WM_avg_cost = df["mc1"].mean()
TT_avg_cost = df["mc2"].mean()

WM_inc_avg = df["micro11"].mean()
TT_inc_avg = df["micro12"].mean()

WM_hi_inc_avg = df["micro21"].mean()
TT_hi_inc_avg = df["micro22"].mean()

trends_df = pd.DataFrame({
    "Value": [
        WM_active_markets,
        WM_avg_cost,
        WM_inc_avg,
        WM_hi_inc_avg,
        TT_active_markets,
        TT_avg_cost,
        TT_inc_avg,
        TT_hi_inc_avg
    ]
}, index=[
    "Walmart: Active Markets",
    "Walmart: Average MC",
    "Walmart: Average Income of Shopper",
    "Walmart: Average Income of High Earning Shoppers",
    "Target: Active Markets",
    "Target: Average MC",
    "Target: Average Income of Shopper",
    "Target: Average Income of High Earning Shoppers"
])

# Variance of MC across markets (single value per firm)
WM_var = df[df["active1"] == 1]["mc1"].var()
TT_var = df[df["active2"] == 1]["mc2"].var()

#fig, ax = plt.subplots()
#sns.barplot(x=["Walmart", "Target"], y=[WM_var, TT_var], ax=ax)
#ax.set_title("Variance of MC across markets")
#ax.set_ylabel("Variance")
#plt.show()


# =================================== #
# (2.3) Profit in each market         #
# =================================== #

df_l["profit"] = 1000 * df_l["share"] * (df_l["p"] - df_l["mc"])

profits_table = df_l.pivot_table(
    index   = "market",
    columns = "firm",
    values  = "profit",
    aggfunc = "sum"
)

with pd.option_context(
    "display.max_rows", None,
    "display.max_columns", None,
    "display.width", None
):
    print(profits_table)

# ================================= #
# (3.1) MNL Estimation              #
# ================================= #

# ================================= #
# (A) Estimation (Uninstrumented)   #
# ================================= #

df_l["outside_share"] = 1 - df_l.groupby("market")["share"].transform("sum")

df_l["DV"] = np.log(df_l["share"]) - np.log(df_l["outside_share"])

X_col = ["x", "p"]

df_l = df_l.replace([np.inf, -np.inf], np.nan).dropna(subset=["DV", "x", "p", "mc"])

X = sm.add_constant(df_l[X_col])
Y = df_l["DV"]

res = sm.OLS(Y, X).fit()

print(res.summary())

# ================================= #
# (A) Estimation (Instrumented)     #
# ================================= #

Z_col = ["x", "mc"]
Z = sm.add_constant(df_l[Z_col])

iv = IV2SLS(Y, X, Z).fit()
print(iv.summary())

# ================================= #
# (3.2) MNL Estimation (True)       #
# ================================= #

# ================================= #
# (A) Estimation                    #
# ================================= #

import pyblp

# base formulation definition
X1 = pyblp.Formulation('1 + x + prices')
X2 = pyblp.Formulation('0 + x + prices')

agent_form = pyblp.Formulation('0 + income')

# product data definition

# adhering to PyBLP naming
prod_data = df_l.rename(columns={"market": "market_ids", "share": "shares", "p": "prices"}).copy()
# defining the product data
prod_data = prod_data[["market_ids", "shares", "prices", "x", "mc", "firm", "zone"]]

# market level inc_mu, inc_sigma
mkt_demo = (
    df_l.groupby("market")[["inc_mu", "inc_sig"]]
    .mean()
    .reset_index()
)

# merging product data and market demos
prod_data = prod_data.merge(mkt_demo, left_on="market_ids", right_on="market", how = "left")
# defining what our instrument is for price
prod_data["demand_instruments0"] = prod_data["mc"]

# agent data

# seed for reproducing
rng = np.random.default_rng(219)

# n
R = 5000

# mean and variance of income
m = np.maximum(mkt_demo["inc_mu"].to_numpy(dtype=float), 1e-12)
s = np.maximum(mkt_demo["inc_sig"].to_numpy(dtype=float), 0.0)

sig2 = np.log1p((s**2) / (m**2))
mu_ln = np.log(m) - 0.5 * sig2
sig_ln = np.sqrt(sig2)

# defining markets
markets = mkt_demo["market"].to_numpy()
# market vector
M = len(markets)

# drawing income from mu, sigma size (M,R)
income_draws = rng.lognormal(mean = mu_ln[:, None], sigma = sig_ln[:, None], size = (M,R))

# defining agent data
agent_data = pd.DataFrame({
    "market_ids": np.repeat(markets, R), # size of market ids
    "weights": np.full(M*R, 1.0/R), # weights size (M*R, 1/R)
    "income": income_draws.ravel() # flattens our income draws
})

# calling the integration protocol
integration = pyblp.Integration("halton", R)

# defining what PyBLP is solving
problem = pyblp.Problem(
    product_formulations = (X1, X2),
    product_data = prod_data,
    agent_formulation = agent_form,
    agent_data = agent_data,
    integration = integration
)

# sigma matrix 2x2 of 0's
sigma0 = np.diag([2,2])
# pi matrix 2x1 of 0's
pi0 = np.array([[0.001], [0.001]])

b0 = np.array([1,1,1])
# calling solution to problem
results = problem.solve(beta=b0,sigma=sigma0, pi = pi0, method="1s")
print(results.pi)
print(results.sigma)

# ============================ #
# Counterfactual Analysis      #
# ============================ #

# extracting estimated betas from last section
beta = results.beta.flatten()
beta_0 = beta[0]
beta_x = beta[1]
beta_p = beta[2]  # alpha -- should be negative

def compute_shares(df, prices):
    df = df.copy()
    df["prices"] = prices

    shares = np.zeros(len(df))

    for m, sub in df.groupby("market_ids"):
        idx = sub.index
        delta = beta_0 + beta_x * sub["x"].values + beta_p * prices[idx]

        exp_delta = np.exp(delta)
        denom = 1 + exp_delta.sum()

        shares[idx] = exp_delta / denom

    return shares


def compute_profit(df, prices):
    shares = compute_shares(df, prices)

    df = df.copy()
    df["shares_new"] = shares
    df["profit"] = 1000 * df["shares_new"] * (prices - df["mc"])

    return df


# ---------------------------------- #
# Build price vectors                #
# ---------------------------------- #

def uniform_prices(p, df, firm, p_val):
    p = p.copy()
    p[df["firm"].values == firm] = p_val
    return p


def zone_prices(p, df, firm, p_vec):
    """p_vec: array of length = number of zones, one price per zone"""
    p = p.copy()
    for i, z in enumerate(np.sort(df["zone"].unique())):
        mask = (df["firm"].values == firm) & (df["zone"].values == z)
        p[mask] = p_vec[i]

    return p  

def market_prices(p, df, firm, p_vec):
    """p_vec: array of length = number of markets, one price per market"""
    p = p.copy()

    for i, m in enumerate(np.sort(df["market_ids"].unique())):
        mask = (df["firm"].values == firm) & (df["market_ids"].values == m)
        p[mask] = p_vec[i]

    return p


# ---------------------------------- #
# FOC functions                      #
# ---------------------------------- #

def uniform_foc(p_val, df, firm):
    p_val = p_val[0]
    p_base = df["prices"].values.copy()
    p = uniform_prices(p_base, df, firm, p_val)
    s = compute_shares(df, p)

    own = df["firm"].values == firm
    mc  = df["mc"].values

    foc = np.sum(
        s[own] + (p_val - mc[own]) * beta_p * s[own] * (1 - s[own])
    )
    return [foc]


def zone_foc(p_vec, df, firm):
    p_vec = np.asarray(p_vec)
    p_base = df["prices"].values.copy()
    p = zone_prices(p_base, df, firm, p_vec)
    s = compute_shares(df, p)

    zones = np.sort(df["zone"].unique())
    focs  = np.zeros(len(zones))
    mc    = df["mc"].values

    for i, z in enumerate(zones):
        mask = (df["firm"].values == firm) & (df["zone"].values == z)
        focs[i] = np.sum(
            s[mask] + (p_vec[i] - mc[mask]) * beta_p * s[mask] * (1 - s[mask])
        )

    return focs


def market_foc(p_vec, df, firm):
    p_vec   = np.asarray(p_vec)
    p_base  = df["prices"].values.copy()
    p   = market_prices(p_base, df, firm, p_vec)
    s   = compute_shares(df, p)

    markets = np.sort(df["market_ids"].unique())
    focs = np.zeros(len(markets))
    mc  = df["mc"].values

    for i, m in enumerate(markets):
        mask = (df["firm"].values == firm) & (df["market_ids"].values == m)
        focs[i] = np.sum(
            s[mask] + (p_vec[i] - mc[mask]) * beta_p * s[mask] * (1 - s[mask])
        )

    return focs


# ---------------------------------- #
# Solve FOCs                         #
# ---------------------------------- #

zones   = np.sort(prod_data["zone"].unique())
markets = np.sort(prod_data["market_ids"].unique())

# --- Uniform ---
uni_sol_f1 = root(lambda p: uniform_foc(p, prod_data, firm=1), x0=[2.0])
uni_sol_f2 = root(lambda p: uniform_foc(p, prod_data, firm=2), x0=[2.0])
# --- Zone ---
z_sol_f1 = root(lambda p: zone_foc(p, prod_data, firm=1), x0=np.full(len(zones), 2.0))
z_sol_f2 = root(lambda p: zone_foc(p, prod_data, firm=2), x0=np.full(len(zones), 2.0))
# --- Market ---
m_sol_f1 = root(lambda p: market_foc(p, prod_data, firm=1), x0=np.full(len(markets), 2.0))
m_sol_f2 = root(lambda p: market_foc(p, prod_data, firm=2), x0=np.full(len(markets), 2.0))


# ---------------------------------- #
# Build price vectors for 9 regimes  #
# ---------------------------------- #

def get_price_vector(df, regime_f1, regime_f2):
    # start from current prices, then overwrite firm by firm
    p = df["prices"].values.copy()

    for firm, regime, sol_z, sol_m, uni_p in [
        (1, regime_f1, z_sol_f1, m_sol_f1, uni_sol_f1),
        (2, regime_f2, z_sol_f2, m_sol_f2, uni_sol_f2),
    ]:
        if regime == "uniform":
            p = uniform_prices(p, df, firm, uni_p.x[0])
        elif regime == "zone":
            p = zone_prices(p, df, firm, sol_z.x)
        elif regime == "market":
            p = market_prices(p, df, firm, sol_m.x)

    return p


# ---------------------------------- #
# Profits & CS for all 9 regimes     #
# ---------------------------------- #

def compute_cs(df, prices):
    cs = 0.0
    df = df.copy()
    df["prices"] = prices
    for m, sub in df.groupby("market_ids"):
        idx = sub.index
        delta = beta_0 + beta_x * sub["x"].values + beta_p * prices[idx]
        cs += np.log(1 + np.exp(delta).sum()) / (-beta_p)
    return cs * 1000  # scale by market size


regime_list = ["uniform", "zone", "market"]
results_table = []

for r1 in regime_list:
    for r2 in regime_list:
        p = get_price_vector(prod_data, r1, r2)
        df_res = compute_profit(prod_data, p)
        pi1 = df_res[df_res["firm"] == 1]["profit"].sum()
        pi2 = df_res[df_res["firm"] == 2]["profit"].sum()
        cs  = compute_cs(prod_data, p)

        results_table.append({
            "Firm 1": r1, "Firm 2": r2,
            "Profit F1": round(pi1, 0),
            "Profit F2": round(pi2, 0),
            "CS":        round(cs,  0),
        })

results_df = pd.DataFrame(results_table)

print("\n=== Profits and CS across all 9 regimes ===")
print(results_df.to_string(index=False))
