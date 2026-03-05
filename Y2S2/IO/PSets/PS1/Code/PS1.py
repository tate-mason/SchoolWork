import numpy as np
import pandas as pd
import scipy as sp
import matplotlib.pyplot as plt
from numpy import std
import statsmodels.api as sm
from statsmodels.sandbox.regression.gmm import IV2SLS
from scipy.optimize import root
import seaborn as sns

sns.set_theme(style="whitegrid", font_scale=1.05)
WM_COLOR = "#0071CE" # Walmart blue
TT_COLOR = "#CC0000" # Target red

palette = {"Walmart": WM_COLOR, "Target": TT_COLOR}

"""
Main file for Problem Set 1 - IO2
"""

df = pd.read_csv('../Data/full_data_zone.csv')
df_l = pd.read_csv('../Data/full_data_zone_long.csv')

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

sns.histplot(data=active, x="mc", hue="firm_name",
             palette=palette, kde=True, alpha=0.5, ax=ax)
ax.set_title("MC Distribution by Firm")
ax.set_xlabel("Marginal Cost")
ax.set_ylabel("Count")
plt.tight_layout()
plt.savefig("../Graphics/mc_dist.pdf")


# --- Price vs. MC --- #
fig,ax = plt.subplots(figsize=(7,4))

"""
data is dataset used
x is variable 1
y is variable 2
hue determines grouping variable
palette determines coloring
alpha transparency
s is bins
"""

sns.scatterplot(data=active, x="mc", y="p", hue="firm_name",
               palette=palette, alpha=0.5, s=25, ax=ax)
# add 45-deg line
lo, hi = active["mc"].min(), active["mc"].max()
ax.plot([lo,hi], [lo,hi], "k--", lw=1, label="p=mc")
ax.legend()
ax.set_title("Price vs. Marginal Cost")
ax.set_xlabel("Marginal Cost")
ax.set_ylabel("Price")
plt.tight_layout()
plt.savefig("../Graphics/price_mc.pdf")

# all positive markup

# --- Income Sorting --- #
fig, ax = plt.subplots(figsize=(7,4))

sns.scatterplot(data=active, x="share", y="inc_mu", hue="firm_name",
                palette=palette, alpha=0.5, s=25, ax=ax)
lo, hi = active["share"].min(), active["share"].max()
ax.plot([lo,hi], [lo,hi], "k--", lw=1, label="Market Avg")
ax.legend()
ax.set_title("Avg Shopper's Income vs. Share")
ax.set_xlabel("Market Share")
ax.set_ylabel("Mean Income")
plt.tight_layout()
plt.savefig("../Graphics/income_sorting.pdf")

# --- Profit Distribution --- #
fig, ax = plt.subplots(figsize=(7,4))

sns.boxplot(data=active, x="firm_name", y="profit",
            palette=palette, width=0.4, ax=ax)
ax.set_title("Profit Distribution by Firm")
ax.set_xlabel("")
ax.set_ylabel("Profit")
plt.tight_layout()
plt.savefig("../Graphics/profit_dist.pdf")

# --- Quality > Price --- #

both = df[(df["active1"]==1) & (df["active2"]==1)].copy()
both["share_diff"] = both["share1"].values - both["share2"].values
both["price_diff"] = both["p1"].values - both["p2"].values

# label each market: does the cheaper firm win?
both["cheaper_wins"] = np.where(
    (both["price_diff"] > 0) & (both["share_diff"] < 0), "TT cheaper, TT wins",   # normal
    np.where(
    (both["price_diff"] < 0) & (both["share_diff"] > 0), "WM cheaper, WM wins",   # normal
    np.where(
    (both["price_diff"] < 0) & (both["share_diff"] < 0), "WM cheaper, TT wins",   # upset!
    "TT cheaper, WM wins")))                                                        # upset!

upset_palette = {
    "WM cheaper, WM wins":  WM_COLOR,
    "TT cheaper, TT wins":  TT_COLOR,
    "WM cheaper, TT wins":  "orange",   # anomaly — cheaper firm loses
    "TT cheaper, WM wins":  "green",
}

fig, ax = plt.subplots(figsize=(7,5))

sns.scatterplot(data=both, x="price_diff", y="share_diff",
                hue="cheaper_wins", palette=upset_palette,
                s=40, alpha=0.8, ax=ax)
ax.axhline(0, color="grey", lw=0.8, ls="--")
ax.axvline(0, color="grey", lw=0.8, ls="--")
ax.annotate("Mkt 266: WalMart cheaper\nbut Target Holds Higher Share",
            xy=(-0.72,-0.59), xytext=(-0.3,-0.75),
            arrowprops=dict(arrowstyle="->", color="black"),
            fontsize=8)
ax.set_title("Price Difference vs. Share Difference")
ax.set_xlabel("Price Difference (WM - TT)")
ax.set_ylabel("Share Difference (WM - TT)")
plt.tight_layout()
plt.savefig("../Graphics/price_share_diff.pdf")

# --- Role of Variety --- #

both["x_diff"] = both["x1"].values - both["x2"].values
fig, ax = plt.subplots(figsize=(7,5))

both["winner"] = np.where(both["share_diff"] > 0, "WM wins", "TT wins")
win_palette = {"WM wins": WM_COLOR, "TT wins": TT_COLOR}

sns.scatterplot(data=both, x="x_diff", y="share_diff",
                hue="winner", palette=win_palette,
                s=40, alpha=0.8, ax=ax)
ax.axhline(0, color="grey", lw=0.8, ls="--")
ax.axvline(0, color="grey", lw=0.8, ls="--")
ax.set_title("Variety Difference vs. Share Difference")
ax.set_xlabel("Variety Difference (WM - TT)")
ax.set_ylabel("Share Difference (WM - TT)")
plt.tight_layout()
plt.savefig("../Graphics/variety_share_diff.pdf")

# --- Monopoly vs. Duopoly --- #

df["structure"] = np.where(
    (df["active1"]==1) & (df["active2"]==1), "Both Active",
    np.where(
        df["active1"]==1, "WM Only", "TT Only"
    ))

active = active.copy()
active["structure"] = active["market"].map(df.set_index("market")["structure"])

fig, axes = plt.subplots(1,2, figsize=(11,4))

for ax, firm, color in zip(axes, ["Walmart", "Target"], [WM_COLOR, TT_COLOR]):
    sub = active[active["firm_name"]==firm]
    order = ["WM Only", "Both Active"] if firm == "Walmart" else ["TT Only", "Both Active"]
    sns.boxplot(data=sub, x="structure", y="profit",
                order=order, palette=[color, "lightgrey"], width=0.5, ax=ax)
    ax.set_title(f"{firm} Market Share by Structure")
    ax.set_xlabel("")
    ax.set_ylabel("Profit")

plt.tight_layout()
plt.savefig("../Graphics/monopoly_duopoly.pdf")



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
