import pandas as pd
import numpy as np
import scipy as sp
import matplotlib.pyplot as plt
import seaborn as sns

"""
This file will be used to demonstrate the initial simulation of the consumer's problem over 100 periods. We will use one consumer to start, with a pre-determined
set of parameters:
    - beta_low = 0.2
    - beta_high = 0.8
    - beta = 0.5
    - gamma_low = 0.2
    - gamma_high = 0.8
    - gamma = 0.5
    - X_jt = 5
    - a_ijt ~ N(alpha*(1/X_jt-X_bar), sigma_a) where alpha is set in different regimes
We will simulate the consumer's choices over 100 periods, and then analyze how the objective changes over time, how the variance in choices change, and how the 
variance changes with regimes. We also want to see how X and sigma comingle.

    Our objective function is:
    U_jt = beta_i*X_jt - gamma*(X_jt - x_bar)^2 + pi*a_ijt + epsilon_ijt
    where epsilon_ijt ~ T1EV

    P_ijt = int exp(U_ijt) / 1 + sum_k exp(U_ikt) dF_j
    s_jt = int P_ijt dF_j 
    HHI_t = sum_j s_jt^2 
    - note: individual HHI, such that HHI is the share of chosen product squared, not market share squared.
"""

rng = np.random.default_rng(seed=219) # set seed for reproducibility

# Parameters
T = 100
sigma_values = [0.5, 1.0, 1.5] # different variance levels

# Regimes
regimes = [
    (0.2, 0.2, 'Low regime (β=0.2, γ=0.2)'),
    (0.5, 0.5, 'Medium regime (β=0.5, γ=0.5)'),
    (0.8, 0.8, 'High regime (β=0.8, γ=0.8)'),
    (0.2, 0.8, 'Mixed regime (β=0.2, γ=0.8)'),
    (0.8, 0.2, 'Mixed regime (β=0.8, γ=0.2)')
]

def simulate(beta, gamma, sigma, T, rng):
    options = np.array([1.0, 2.0, 3.0, 4.0, 5.0])

    x_choices = np.zeros(T)
    x_bar = np.zeros(T)

    x_choices[0] = rng.choice(options)
    x_bar[0] = x_choices[0] # initial mean is just the first choice
    for t in range(1, T):
        x_bar[t] = np.mean(x_choices[:t]) # mean of all prior choices
        x_choices[t] = rng.choice(options)

    return x_choices, x_bar


def rolling_var(x, min_periods=2):
    var = np.full(len(x), np.nan)
    for t in range(min_periods, len(x) + 1):
        var[t-1] = np.var(x[:t], ddof=1)
    return var

fig, axes = plt.subplots(1, 5, figsize=(13, 5), sharey=False)
idx = np.arange(T)
colors = ["#1f77b4", "#ff7f0e", "#2ca02c"]  # one per sigma value

for ax, (beta, gamma, label) in zip(axes, regimes):
    for sigma, color in zip(sigma_values, colors):
        x_choices, _ = simulate(beta, gamma, sigma, T, rng)
        roll_var = rolling_var(x_choices)
        ax.plot(idx, roll_var, label=f"σ={sigma}", color=color, linewidth=1.8)

    ax.set_title(label, fontsize=11)
    ax.set_xlabel("Period")
    ax.set_ylabel("Rolling variance of $X_{jt}$")
    ax.legend(title="σ_x")
    ax.set_xlim(0, T - 1)

fig.suptitle("Expanding-window variance of consumer choices by regime and σ", fontsize=13, y=1.01)
plt.tight_layout()
plt.savefig("../Output/rolling_variance_of_consumer_choices_by_regime_and_sigma.png")
plt.show()

# Consumer Choices

C_x = "#4C72B0"
C_Xb = "black"
C_U = "#C44E52"

fig2, axes2 = plt.subplots(1, 5, figsize=(16, 5), sharey=False)

for ax, (beta, gamma, label) in zip(axes2, regimes):
    x_choices, x_bar = simulate(beta, gamma, sigma_values[1], T, rng)  # using medium sigma for choice simulation

    epsilon = rng.gumbel(size=T)
    U = beta * x_choices - gamma * (x_choices - x_bar) ** 2 + epsilon

    ax.plot(idx, x_choices, label="$X_{jt}$", color=C_x, linewidth=2.0)
    ax.plot(idx, x_bar, label="$\\bar{X}_{jt}$", color=C_Xb, linewidth=1.6, linestyle='--')
    ax.plot(idx, U, label="$U_{jt}$", color=C_U, linewidth=1.2, alpha=0.6)
    ax.set_title(label, fontsize=10)
    ax.set_xlabel("Period")
    ax.set_ylabel("Value")
    ax.legend(fontsize=9)
    ax.set_xlim(0, T - 1)

fig2.suptitle("Consumer choices and utility by regime (σ=1.0)", fontsize=13, y=1.01)
plt.tight_layout()
plt.savefig("../Output/consumer_choices_and_utility_by_regime.png")
plt.show()

# Calculating Choice Probabilities and HHI

options = np.array([1.0, 2.0, 3.0, 4.0, 5.0]) # possible choices

beta, gamma = 0.5, 0.5
x_choices, x_bar = simulate(beta, gamma, sigma_values[1], T, rng)  # using medium sigma for choice simulation

j_obs = np.searchsorted(options, x_choices) # observed choice indices
eps = rng.gumbel(size=(5, T)) # random shocks for each option and period

def calculate_prob_and_hhi(options, x_bar, beta, gamma, eps, j_obs):
    T = len(x_bar)
    ll = 0.0
    s_all = np.zeros((T, len(options)))
    for t in range(T):
        V = beta * options - gamma * (options - x_bar[t]) ** 2 + eps[:, t]
        log_P = V - sp.special.logsumexp(V)
        ll += log_P[j_obs[t]]
        s_all[t] = np.exp(log_P)
    HHI = np.mean(np.sum(s_all ** 2, axis=1))
    return s_all, HHI, ll

