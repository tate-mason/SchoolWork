import numpy as np
import pandas as pd
import scipy as sp
import matplotlib.pyplot as plt
from numpy import std
import statsmodels.api as sm
from statsmodels.sandbox.regression.gmm import IV2SLS

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

#print(trends_df)
#
#price = df_l["p"]
#price = np.arange(len(df_l))
#
#for f, sub in df_l.groupby("firm"):
#    plt.figure()
#
#    plt.bar(sub["zone"], std(sub["p"]))
#    plt.title(f"Firm {f}")
#    plt.xlabel("Zone")
#    plt.ylabel("Variance of Price")
#    plt.show()
#
#for f, sub in df_l.groupby("firm"):
#    plt.figure()
#
#    plt.bar(sub["zone"], std(sub["x"]))
#    plt.title(f"Firm {f}")
#    plt.xlabel("Zone")
#    plt.ylabel("Variancce of Chars.")
#    plt.show()
#
#for f, sub in df_l.groupby("firm"):
#    plt.figure()
#
#    plt.scatter


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
df_l = df_l.replace([np.inf, -np.inf], np.nan).dropna(subset=["x","p","mc","micro1"])

df_l["inc_p"] = df_l["p"] * df_l["inc_mu"]
df_l["inc_x"] = df_l["x"] * df_l["inc_mu"]
df_l["inc_mc"] = df_l["inc_mu"] * df_l["mc"]

Z_col_het = ["x", "mc", "inc_x", "inc_mc"]

X_col_het = ["x", "p", "inc_x", "inc_p"]

Z_het = sm.add_constant(df_l[Z_col_het])
X_het = sm.add_constant(df_l[X_col_het])

het_est = IV2SLS(Y, X_het, Z_het).fit()
print(het_est.summary())


