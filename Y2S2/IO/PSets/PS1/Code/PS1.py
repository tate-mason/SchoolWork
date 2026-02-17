import numpy as np
import pandas as pd
import scipy as sp
import matplotlib.pyplot as plt

"""
Main file for Problem Set 1 - IO2
"""

df = pd.read_csv('../Data/full_data_zone.csv') # import the long version of the data
print(df.head())

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

print(trends_df)

