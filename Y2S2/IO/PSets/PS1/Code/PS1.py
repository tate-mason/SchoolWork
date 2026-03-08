import numpy as np
import pandas as pd
import scipy as sp
import matplotlib.pyplot as plt
from numpy import std
import statsmodels.api as sm
from statsmodels.sandbox.regression.gmm import IV2SLS
from scipy.optimize import root
import seaborn as sns

# setting seaborn settings and color scheme
sns.set_theme(style="whitegrid", font_scale=1.05)
WM_COLOR = "#0071CE" # Walmart blue
TT_COLOR = "#CC0000" # Target red

# defining the palette to call in seaborn
palette = {"Walmart": WM_COLOR, "Target": TT_COLOR}

"""
Main file for Problem Set 1 - IO2
"""

# loading data
df = pd.read_csv('../Data/full_data_zone.csv')
df_l = pd.read_csv('../Data/full_data_zone_long.csv')

# calculating profits and markups
df_l["profit"] = 1000*df_l["share"]*(df_l["p"] - df_l["mc"])
df_l["markup"] = df_l["p"] - df_l["mc"]

active = df_l[df_l["active"]==1] # subsetting to active markets

active["firm_name"] = active["firm"].map({1:"Walmart", 2:"Target"}) # label for graphs

# --- MC dist Across Mkt --- #

fig, ax = plt.subplots(figsize=(7,4))

"""
Learning seaborn pardon the nuisance:

data confirms dataset used
x determines variable of interest
hue splits data by group and then colors the same
kde fits a smooth density curve
alpha controls transparentcy allowing for bars to overlap
"""

# creating histogram of MC dist by firm
sns.histplot(data=active, x="mc", hue="firm_name",
             palette=palette, kde=True, alpha=0.5, ax=ax)
ax.set_title("MC Distribution by Firm")
ax.set_xlabel("Marginal Cost")
ax.set_ylabel("Count")
plt.tight_layout()
plt.savefig("../Graphics/mc_dist.pdf") # saving figure to graphics folder


# --- Variety vs Share --- #
# split panel scatter + rolling median; strong 0.8 corr per firm

# creating subset of data for duopoly markets
both = df[(df["active1"]==1) & (df["active2"]==1)].copy()

active = active.copy()

fig, axes = plt.subplots(1, 2, figsize=(10, 4), sharey=False)

# looping through firms and plotting scatter + rolling median for each
for ax, (firm, color) in zip(axes, [("Walmart", WM_COLOR), ("Target", TT_COLOR)]):
    sub = active[active["firm_name"] == firm].sort_values("x")
    ax.scatter(sub["x"], sub["share"], color=color, alpha=0.4, s=20, zorder=2)
    rolling_med = sub["share"].rolling(window=15, center=True, min_periods=5).median()
    ax.plot(sub["x"], rolling_med, color=color, lw=2, zorder=3, label="Rolling median")
    ax.axhline(sub["share"].median(), color="grey", lw=0.8, ls="--", zorder=1)
    ax.set_title(firm)
    ax.set_xlabel("Variety (x)")
    ax.set_ylabel("Market Share")
    ax.legend(fontsize=8)

fig.suptitle("Variety and Market Share by Firm", y=1.01)
plt.tight_layout()
plt.savefig("../Graphics/variety_share.pdf", bbox_inches="tight") # saving figure to graphics folder

# --- Price Dispersion Across Markets --- #
# WM vs TT price per duopoly market; 45-degree line = equal price

fig, ax = plt.subplots(figsize=(6, 6))

# creating scatter of WM vs TT price in duopoly markets
ax.scatter(both["p1"], both["p2"], color=WM_COLOR, alpha=0.5, s=30, zorder=2)

lim_lo = min(both["p1"].min(), both["p2"].min()) - 0.1
lim_hi = max(both["p1"].max(), both["p2"].max()) + 0.1
ax.plot([lim_lo, lim_hi], [lim_lo, lim_hi], color="grey", lw=1, ls="--", zorder=1, label="Equal price")
ax.text(lim_hi - 0.1, lim_lo + 0.15, "WM pricier", ha="right", fontsize=8, color="dimgrey")
ax.text(lim_lo + 0.05, lim_hi - 0.15, "TT pricier", ha="left",  fontsize=8, color="dimgrey")
ax.set_xlim(lim_lo, lim_hi)
ax.set_ylim(lim_lo, lim_hi)
ax.set_aspect("equal")
ax.set_xlabel("Walmart Price")
ax.set_ylabel("Target Price")
ax.set_title("Price Dispersion in Duopoly Markets\n(one dot = one market)")
ax.legend(fontsize=8)
plt.tight_layout()
plt.savefig("../Graphics/price_dispersion.pdf")  # saving figure to graphics folder

# --- Income Distribution by Market Structure --- #
# inc_sig is constant; inc_mu is the meaningful variation
# shows whether richer/poorer markets sort into different structures

df["structure"] = np.where(
    (df["active1"]==1) & (df["active2"]==1), "Duopoly",
    np.where(df["active1"]==1, "WM Only", "TT Only")
)

mkt_inc = df[["market", "inc_mu", "structure"]].drop_duplicates()

struct_palette = {"Duopoly": "steelblue", "WM Only": WM_COLOR, "TT Only": TT_COLOR}
struct_order   = ["WM Only", "Duopoly", "TT Only"]

fig, ax = plt.subplots(figsize=(7, 4))
sns.histplot(data=mkt_inc, x="inc_mu", hue="structure",
             hue_order=struct_order, palette=struct_palette,
             kde=True, alpha=0.45, bins=20, ax=ax)
ax.set_title("Market Income Distribution by Competitive Structure")
ax.set_xlabel("Mean Income (inc_mu)")
ax.set_ylabel("Markets")
plt.tight_layout()
plt.savefig("../Graphics/income_structure.pdf")

# --- Markup Distribution --- #
# violin + strip replaces plain boxplot — shows full shape

active["markup"] = active["p"] - active["mc"]

fig, ax = plt.subplots(figsize=(6, 4))
sns.violinplot(data=active, x="firm_name", y="markup", hue="firm_name",
               palette=palette, inner=None, alpha=0.35, legend=False,
               order=["Walmart", "Target"], ax=ax)
sns.stripplot(data=active, x="firm_name", y="markup", hue="firm_name",
              palette=palette, alpha=0.4, size=3, jitter=True, legend=False,
              order=["Walmart", "Target"], ax=ax)
ax.set_title("Markup Distribution by Firm")
ax.set_xlabel("")
ax.set_ylabel("Markup  (p − mc)")
plt.tight_layout()
plt.savefig("../Graphics/markup_dist.pdf")



# =================================== #
# (2.3) Profit in each market         #
# =================================== #

active["profit"] = 1000 * active["share"] * (active["p"] - active["mc"])

profits_table = active.pivot_table(
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

profits_table.columns = ["Walmart", "Target"]
profits_table = profits_table.round(2)
profits_table.to_csv("../Data/profits_table.csv")

summary = profits_table.agg(["mean", "median", "std", "min", "max"]).round(2)
summary.to_csv("../Data/profits_summary.csv")
# ================================= #
# (3.1) MNL Estimation              #
# ================================= #

# ================================= #
# (A) Estimation (Uninstrumented)   #
# ================================= #

active["outside_share"] = 1 - active.groupby("market")["share"].transform("sum")

active["DV"] = np.log(active["share"]) - np.log(active["outside_share"])

X_col = ["x", "p"]

active = active.replace([np.inf, -np.inf], np.nan).dropna(subset=["DV", "x", "p", "mc"])

X = sm.add_constant(active[X_col])
Y = active["DV"]

res = sm.OLS(Y, X).fit()

print(res.summary())

# ================================= #
# (A) Estimation (Instrumented)     #
# ================================= #

Z_col = ["x", "mc"]
Z = sm.add_constant(active[Z_col])

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
prod_data = active.rename(columns={"market": "market_ids", "share": "shares", "p": "prices"}).copy()
# defining the product data
prod_data = prod_data[["market_ids", "shares", "prices", "x", "mc", "firm", "zone"]]

# market level inc_mu, inc_sigma
mkt_demo = (
    active.groupby("market")[["inc_mu", "inc_sig"]]
    .mean()
    .reset_index()
)

# merging product data and market demos
prod_data = prod_data.merge(mkt_demo, left_on="market_ids", right_on="market", how = "left")
# defining what our instrument is for price
prod_data["demand_instruments0"] = prod_data["mc"]
prod_data["demand_instruments1"] = prod_data["x"] * prod_data["inc_mu"]
prod_data["demand_instruments2"] = prod_data["mc"] * prod_data["inc_mu"]

# agent data

# seed for reproducing
rng = np.random.default_rng(219)

# n
R = 500

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

# defining what PyBLP is solving
problem = pyblp.Problem(
    product_formulations = (X1, X2),
    product_data = prod_data,
    agent_formulation = agent_form,
    agent_data = agent_data,
    integration = pyblp.Integration("mlhs", size=R)
)

# sigma matrix 2x2 of 0's
sigma0 = np.diag([0,0])
# pi matrix 2x1 of 0's
pi0 = np.array([[0.001], [0.001]])

b0 = np.array([1,1,1])
# calling solution to problem
optimization = pyblp.Optimization("bfgs", {'gtol':1e-10, 'maxiter':1000})
results = problem.solve(beta=b0,sigma=sigma0, pi = pi0, method="2s", optimization=optimization)
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
