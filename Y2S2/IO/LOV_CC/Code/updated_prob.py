import pandas as pd
import os
import numpy as np
import scipy as sp
from scipy.special import logsumexp
import matplotlib.pyplot as plt
import seaborn as sns
from tabulate import tabulate
from collections import namedtuple
from progress.bar import IncrementalBar

"""
This file will be used to do initial simulation of the love of variety problem:
    - Consumer Problem: U_ijt = beta_i*X_jt - gamma_i*(Sigma_jt) + a_ijt + epsilon_ijt
        s.t. gamma ~ N(0, sigma_gamma); Sigma_jt = sum_t^T  X_jt
    - Firm Problem: V(a_t;Sigma_jt, lambda_t(gamma_i)) = {pi + int_gamma V(a';Sigma_jt+1, lambda_t+1(gamma_i))dlambda_t(gamma_i)}
        s.t. pi = (1+a)p - c
             lambda_t(gamma) ~ N(1/Sigma_jt, sigma_lambda), a = {0,1}
Structure:
    1) solve consumer's choice problem
    2) compute individual shares of products
    3) compute firm's problem, choosing optimal a
    4) find partial equilibrium
Landscape:
    1) T = 100
    2) J = 5
    3) i = 1
    4) gamma = range(0.2(0.3)0.8), beta = range(0.2(0.3)0.8)
Functions:

Libraries Used:
    - numpy: used for numerical operation
    - scipy: used for optimization routines
    - matplotlib, seaborn: used for plotting
    - tabulate: better output text results

"""

#=============================================================#
# Setup and Parameter Definition                              #
#=============================================================#

output_dir = os.chdir('../Output/')

rng = np.random.default_rng(seed=219)

# Parameterization
T = 100
sigma_gamma = [0.5, 1.0, 1.5]
kappa = 5

regimes = [
    (0.2, 0.2, 'Low regime (β=0.2, γ=0.2)', '-.'),
    (0.5, 0.5, 'Medium regime (β=0.5, γ=0.5)', ':'),
    (0.8, 0.8, 'High regime (β=0.8, γ=0.8)', '--'),
    (0.2, 0.5, 'Mixed regime (β=0.2, γ=0.5)', '-'),
    (0.8, 0.5, 'Mixed regime (β=0.8, γ=0.5)', '-'),
    (0.5, 0.2, 'Mixed regime (β=0.5, γ=0.2)', '-'),
    (0.5, 0.8, 'Mixed regime (β=0.5, γ=0.8)', '-'),
    (0.8, 0.2, 'Mixed regime (β=0.8, γ=0.2)', '-'),
    (0.2, 0.8, 'Mixed regime (β=0.2, γ=0.8)', '-')
]

J = 5
S = 1000
X_bar = rng.standard_normal()
sigma_x = rng.standard_normal() * 0.5 + 1.0

ConsResult = namedtuple('ConsResult', ['x_chosen_all', 'x_bar_all', 'X_jt_all', 'V_all', 'prob_all', 'U_all', 'll'])

# Consumer Choice Problem

def simulate_cons(beta, gamma, kappa, sigma_gamma, T, J, X_bar, sigma_x, rng, S=1000):
    x_chosen_all = np.zeros((S, T))
    x_bar_all    = np.zeros((S, T))
    X_jt_all     = np.zeros((S, T, J))
    V_all        = np.zeros((S, T, J))
    ll_all       = np.zeros(S)
    prob_all     = np.zeros((S, T, J))

    for s in range(S):

        epsilon_ijt = rng.gumbel(0,1, size=J)

        x_chosen = np.zeros(T) # empty vector of choices per period
        X_jt = np.zeros((T,J))
        x_bar = np.zeros(T)
        x_bar[0] = X_bar

        Sigma = np.zeros(T) # empty vector for the sum of characteristics

        V = np.zeros((T, J))
        chosen_idx = np.zeros(T, dtype=int)

        X_jt[0] = rng.normal(loc=x_bar[0], scale=sigma_x, size=J)
        a = np.zeros(T)

        a[0] = 0
        epsilon_0 = rng.gumbel(0,1,size=J)
        u0 = beta*X_jt[0] - gamma*0 + a[0] + epsilon_0
        V[0] = u0
        chosen_idx[0] = np.argmax(u0)
        x_chosen[0] = X_jt[0, chosen_idx[0]]
        Sigma[0] = x_chosen[0]
        U_all = np.zeros((S, T))

        for t in range(1, T):
            u = np.zeros(J)
            a[t] = 0.20
            x_bar[t] = np.mean(x_chosen[:t])
            X_jt[t] = rng.normal(loc=x_bar[t], scale=sigma_x, size=J)
            for j in range(J):
                u[j] = beta*X_jt[t,j] - gamma*Sigma[t-1]**2 + kappa*a[t] + epsilon_ijt[j]
            V[t] = u
            chosen_idx[t] = np.argmax(u)
            x_chosen[t] = X_jt[t, chosen_idx[t]] 
            Sigma[t] = x_chosen[t] - np.mean(x_chosen[:t+1])

        ll = -np.sum(V[np.arange(T), chosen_idx]-logsumexp(V,axis=1,keepdims=True))
        prob = np.exp(V) / np.exp(V).sum(axis=1, keepdims=True)
        prob_all[s] = prob
        x_chosen_all[s] = x_chosen
        x_bar_all[s] = x_bar
        X_jt_all[s] = X_jt
        V_all[s] = V
        U_all[s] = V[np.arange(T), chosen_idx]
        ll_all[s] = ll
    return ConsResult(
            x_chosen_all.mean(axis=0),  # shape (T,)
            x_bar_all.mean(axis=0),      # shape (T,)
            X_jt_all.mean(axis=0),       # shape (T, J)
            V_all.mean(axis=0),          # shape (T, J)
            prob_all.mean(axis=0),             # shape (T,J)
            U_all.mean(axis=0),              # shape (T,)
            ll_all.mean())               # scalar

colors = plt.cm.tab10(np.linspace(0,1,len(regimes)))

fig, ax = plt.subplots(figsize=(8, 4))
for (beta, gamma, label, ls), color in zip(regimes, colors):
    x_chosen, x_bar, X_jt, V, prob, U, ll = simulate_cons(
        beta, gamma, 5, sigma_gamma[1], T, J, X_bar, sigma_x, rng
    )
    ax.plot(np.arange(T), U, label=label, color=color, linewidth=1.5, linestyle=ls)

ax.set_xlabel("Period")
ax.set_ylabel("Utility")
ax.set_title("Consumer Utility by Regime")
ax.legend(fontsize=7)
plt.tight_layout()
plt.savefig("consumer_utility_by_regime.pdf", bbox_inches='tight', format='pdf')


# Consumer Choice by Regime

colors = plt.cm.tab10(np.linspace(0,1,len(regimes)))

for j in range(J):
    fig, ax = plt.subplots(figsize=(8,4))

    for (beta, gamma, label,ls), color in zip(regimes, colors):
        x_chosen, x_bar, X_jt, V, prob, ll, U = simulate_cons(
            beta, gamma, 5, sigma_gamma[1], T, J, X_bar, sigma_x, rng
        )

        prob_smooth = np.convolve(prob[:,j], np.ones(5)/5, mode='same')
        ax.plot(np.arange(T), prob_smooth, label=label, color=color, linewidth=1.5, linestyle=ls)
    ax.set_title(f"Product {j+1}", fontsize=9)
    ax.set_xlabel("Period")
    ax.set_ylim(0.15,0.27)
    ax.set_xlim(5, 95)
    ax.set_ylabel("Choice Probability")
    ax.legend(fontsize=7, loc="upper left", bbox_to_anchor=(0,1))
    fig.suptitle("Choice Probability by Product and Regime", fontsize=13, y=1.01)
    plt.tight_layout()
    plt.savefig(f"choice_prob_product_{j+1}.pdf", bbox_inches='tight', format='pdf')

def simulate_cons_markov(beta, gamma, kappa, sigma_gamma, T, J, X_bar, sigma_x, rng, S=1000):
    x_chosen_all = np.zeros((S, T))
    x_bar_all    = np.zeros((S, T))
    X_jt_all     = np.zeros((S, T, J))
    V_all        = np.zeros((S, T, J))
    ll_all       = np.zeros(S)
    prob_all     = np.zeros((S, T, J))

    for s in range(S):

        epsilon_ijt = rng.gumbel(0,1, size=J)
        eps_markov = rng.standard_normal(size=T)

        x_chosen = np.zeros(T) # empty vector of choices per period
        X_jt = np.zeros((T,J))
        x_bar = np.zeros(T)
        x_bar[0] = X_bar

        Sigma = np.zeros(T) # empty vector for the sum of characteristics

        V = np.zeros((T, J))
        chosen_idx = np.zeros(T, dtype=int)
        U_all = np.zeros((S, T))

        X_jt[0] = rng.normal(loc=x_bar[0], scale=sigma_x, size=J)
        a = np.zeros(T)

        a[0] = 0
        epsilon_0 = rng.gumbel(0,1,size=J)
        u0 = beta*X_jt[0] - gamma*0 + a[0] + epsilon_0
        V[0] = u0
        chosen_idx[0] = np.argmax(u0)
        x_chosen[0] = X_jt[0, chosen_idx[0]]
        Sigma[0] = x_chosen[0]

        for t in range(1, T):
            u = np.zeros(J)
            x_bar[t] = np.mean(x_chosen[:t])
            X_jt[t] = rng.normal(loc=x_bar[t], scale=sigma_x, size=J)
            a[t] = kappa*(x_bar[t-1] - x_chosen[t])**2 # Markovian promotion based on distance from mean 
            for j in range(J):
                u[j] = beta*X_jt[t,j] - gamma*Sigma[t-1]**2 + a[t] + epsilon_ijt[j]
            V[t] = u
            chosen_idx[t] = np.argmax(u)
            x_chosen[t] = X_jt[t, chosen_idx[t]] 
            Sigma[t] = x_chosen[t] - np.mean(x_chosen[:t+1])

        ll = -np.sum(V[np.arange(T), chosen_idx]-logsumexp(V,axis=1,keepdims=True))
        prob = np.exp(V) / np.exp(V).sum(axis=1, keepdims=True)
        prob_all[s] = prob
        x_chosen_all[s] = x_chosen
        x_bar_all[s] = x_bar
        X_jt_all[s] = X_jt
        V_all[s] = V
        U_all[s] = V[np.arange(T), chosen_idx]
        ll_all[s] = ll
    return ConsResult(
            x_chosen_all.mean(axis=0),  # shape (T,)
            x_bar_all.mean(axis=0),      # shape (T,)
            X_jt_all.mean(axis=0),       # shape (T, J)
            V_all.mean(axis=0),          # shape (T, J)
            prob_all.mean(axis=0),             # shape (T,J)
            U_all.mean(axis=0),              # shape (T,)
            ll_all.mean()
            )               


# Utility Plots
colors = plt.cm.tab10(np.linspace(0,1,len(regimes)))

# Utility Plots
fig, ax = plt.subplots(figsize=(8, 4))
colors = plt.cm.tab10(np.linspace(0, 1, len(regimes)))

for (beta, gamma, label, ls), color in zip(regimes, colors):
    x_chosen, x_bar, X_jt, V, prob_all, U, ll = simulate_cons_markov(
        beta, gamma, 5, sigma_gamma[1], T, J, X_bar, sigma_x, rng
    )
    ax.plot(np.arange(T), U, label=label, color=color, linewidth=1.5, linestyle=ls)  # <-- ax.plot, not plt.plot

ax.set_xlabel("Period")
ax.set_ylabel("Utility")
ax.set_title("Consumer Utility by Regime (Markov)")
ax.legend(fontsize=7)
plt.tight_layout()
plt.savefig("consumer_utility_by_regime_markov.pdf", bbox_inches='tight', format='pdf')


for j in range(J):
    fig, ax = plt.subplots(figsize=(8,4))

    for (beta, gamma, label,ls), color in zip(regimes, colors):
        x_chosen, x_bar, X_jt, V, prob, U, ll = simulate_cons_markov(
            beta, gamma, 5, sigma_gamma[1], T, J, X_bar, sigma_x, rng
        )

        prob_smooth = np.convolve(prob[:,j], np.ones(5)/5, mode='same')
        ax.plot(np.arange(T), prob_smooth, label=label, color=color, linewidth=1.5, linestyle=ls)
    ax.set_title(f"Product {j+1}", fontsize=9)
    ax.set_xlabel("Period")
    ax.set_ylim(0.15,0.27)
    ax.set_xlim(5, 95)
    ax.set_ylabel("Choice Probability")
    ax.legend(fontsize=7, loc="upper left", bbox_to_anchor=(0,1))
    fig.suptitle("Choice Probability by Product and Regime", fontsize=13, y=1.01)
    plt.tight_layout()
    plt.savefig(f"choice_prob_product_{j+1}_markov.pdf", bbox_inches='tight', format='pdf')

#=============================================================#
# Firm Value Function w.r.t. CCP                              #
#=============================================================#

p = 2.0
mc = 1.0
beta_disc = 0.9

def firm_value_function(beta, gamma, kappa, beta_disc, mc, sigma_gamma, T, J, X_bar, sigma_x, rng, p, S=1000):

    cons = simulate_cons_markov(beta, gamma, kappa, sigma_gamma, T, J, X_bar, sigma_x, rng, S)

    prob = cons.prob_all
    X_bar = cons.x_bar_all
    x_chosen = cons.x_chosen_all
    X_jt = cons.X_jt_all

    Vf = np.zeros((T+1, J))
    a_opt = np.zeros((T,J))

    for t in range(T-1, -1, -1):
        eps_f = rng.standard_normal(size=J)
        for j in range(J):
            X_kt = X_jt[t].sum() - X_jt[t,j] 
            s_jt = prob[t,j]
            for a_val in [0,1]:
                pi = s_jt*(p-mc) - kappa*((X_bar[t] - x_chosen[t])/X_kt)**2
                EV_f = Vf[t+1, j]
                V_t = pi + beta_disc*EV_f
                if a_val == 0:
                    V_no_ad = V_t
                else:
                    V_ad = V_t

            if V_ad >= V_no_ad:
                Vf[t,j] = V_ad
                a_opt[t,j] = 1
            else:
                Vf[t,j] = V_no_ad
                a_opt[t,j] = 0
    return Vf, a_opt

for (beta, gamma, label, ls), color in zip(regimes, colors):
    Vf, a = firm_value_function(
        beta, gamma, kappa, beta_disc, mc, sigma_gamma, T, J, X_bar, sigma_x, rng, p, 1000
    )
    ax.plot(np.arange(T+1), Vf, label=label, color=color, linewidth=1.5, linestyle=ls)  # <-- ax.plot, not plt.plot

ax.set_xlabel("Period")
ax.set_ylabel("Advertising")
ax.set_title("Firm Advertising Choice in Set Rate Setting")
plt.tight_layout()
plt.savefig("ad_choice_set.pdf", bbox_inches='tight', format='pdf')
plt.show()
