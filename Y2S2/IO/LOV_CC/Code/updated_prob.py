import pandas as pd
import os
import numpy as np
import scipy as sp
from scipy.special import logsumexp
import matplotlib.pyplot as plt
import seaborn as sns
from tabulate import tabulate

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
sigma_x = 1.0

# Consumer Choice Problem

def simulate_cons(beta, gamma, sigma_gamma, T, J, X_bar, sigma_x, rng, S=1000):
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

        for t in range(1, T):
            u = np.zeros(J)
            a[t] = 0.23 # 10% chance of promotion
            x_bar[t] = np.mean(x_chosen[:t])
            X_jt[t] = rng.normal(loc=x_bar[t], scale=sigma_x, size=J)
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
        ll_all[s] = ll
    return (x_chosen_all.mean(axis=0),  # shape (T,)
            x_bar_all.mean(axis=0),      # shape (T,)
            X_jt_all.mean(axis=0),       # shape (T, J)
            V_all.mean(axis=0),          # shape (T, J)
            prob_all.mean(axis=0),             # shape (T,J)
            ll_all.mean())               # scalar

# Consumer Choice by Regime

colors = plt.cm.tab10(np.linspace(0,1,len(regimes)))

for j in range(J):
    fig, ax = plt.subplots(figsize=(8,4))

    for (beta, gamma, label,ls), color in zip(regimes, colors):
        x_chosen, x_bar, X_jt, V, prob, ll = simulate_cons(
            beta, gamma, sigma_gamma[1], T, J, X_bar, sigma_x, rng
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
    plt.show()

def simulate_cons_directed_ads(beta, gamma, sigma_gamma, T, J, X_bar, sigma_x, rng, S=1000):
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

        for t in range(1, T):
            u = np.zeros(J)
            ad = 1.0 if j == 1 else 0.0 
            x_bar[t] = np.mean(x_chosen[:t])
            X_jt[t] = rng.normal(loc=x_bar[t], scale=sigma_x, size=J)
            for j in range(J):
                u[j] = beta*X_jt[t,j] - gamma*Sigma[t-1]**2 + ad + epsilon_ijt[j]
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
        ll_all[s] = ll
    return (x_chosen_all.mean(axis=0),  # shape (T,)
            x_bar_all.mean(axis=0),      # shape (T,)
            X_jt_all.mean(axis=0),       # shape (T, J)
            V_all.mean(axis=0),          # shape (T, J)
            prob_all.mean(axis=0),             # shape (T,J)
            ll_all.mean())               # scalar

colors = plt.cm.tab10(np.linspace(0,1,len(regimes)))

for j in range(J):
    fig, ax = plt.subplots(figsize=(8,4))

    for (beta, gamma, label,ls), color in zip(regimes, colors):
        x_chosen, x_bar, X_jt, V, prob, ll = simulate_cons(
            beta, gamma, sigma_gamma[1], T, J, X_bar, sigma_x, rng
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
    plt.savefig(f"choice_prob_product_{j+1}_directed_ads.pdf", bbox_inches='tight', format='pdf')
    plt.show()
#=============================================================#
# Firm Problem and Equilibrium Analysis                       #
#=============================================================#

def inferred_choice_prob(a, X_j, Sigma_t, lambda_t, beta):
    U_firm = beta*X_j + a - lambda_t*Sigma_t
    U_outside=0
    return np.exp(U_firm) / (1 + np.exp(U_firm))

def solve_firm(Sigma, X_bar, beta, p, c, kappa_vec, a_grid, beta_disc, tol=1e-6):
    T = len(Sigma)
    V = np.zeros((T, len(a_grid)))
    optimal_a = np.zeros(T)

    for i in range(T-1, -1, -1):
        lambda_t = 1 / (Sigma[i]**2) if Sigma[i] > 0 else 1.0
        for j, a in enumerate(a_grid):
            prob = inferred_choice_prob(a, X_bar, Sigma[i], lambda_t, beta)
            pi = prob*((1+a)*p - c - (kappa_vec[i]*a)**2)
            if i < T-1:
                exp_V = np.max(V[i+1])
                V[i,j] = pi + beta_disc*lambda_t*exp_V
            else:
                V[i,j] = pi
    optimal_a = a_grid[np.argmax(V, axis=1)]
    return optimal_a, V

x_chosen, x_bar, X_jt, V_cons, ll = simulate_cons(
    0.5, 0.5, sigma_gamma[1], T, J, X_bar, sigma_x, rng
)
Sigma_path = np.array([np.mean(x_chosen[:t+1]) for t in range(T)])

regimes_1 = regimes[:4]
regimes_2 = regimes[4:]

for fig_num, regime_subset in enumerate([regimes_1, regimes_2], start=1):
    fig, axes = plt.subplots(1, len(regime_subset), 
                             figsize=(3*len(regime_subset), 4), sharey=True)
    
    for ax, (beta, gamma, label) in zip(axes, regime_subset):
        x_chosen, x_bar, X_jt, V_cons, ll = simulate_cons(
            beta, gamma, sigma_gamma[1], T, J, X_bar, sigma_x, rng
        )
        Sigma_path = np.array([np.mean(x_chosen[:t+1]) for t in range(T)])
        kappa_vec = np.clip(
            rng.normal(loc=1/Sigma_path, scale=sigma_lambda[1], size=T),
            0.01, None
        )
        
        optimal_a, _ = solve_firm(
            Sigma_path, X_bar, beta=beta, p=1.0, c=0.5,
            kappa_vec=kappa_vec, a_grid=np.linspace(0, 1, 50), beta_disc=0.9
        )
        
        optimal_a_smooth = np.convolve(optimal_a, np.ones(5)/5, mode='same')
        ax.plot(np.arange(T), optimal_a_smooth, color='steelblue', linewidth=1.5)
        ax.axhline(np.mean(optimal_a_smooth), color='black', linestyle='--',
                   linewidth=1, label=f"Mean={np.mean(optimal_a_smooth):.2f}")
        ax.set_title(label, fontsize=8)
        ax.set_xlabel("Period")
        ax.legend(fontsize=8)
    
    axes[0].set_ylabel("Optimal $a$")
    fig.suptitle("Firm's Optimal Advertising by Consumer Regime", fontsize=13, y=1.01)
    plt.tight_layout()
    plt.savefig(f"firm_optimal_a_by_regime_{fig_num}.pdf", 
                dpi=300, bbox_inches='tight', format='pdf')
    plt.show()
