---
title: "Study Guide for Preliminary Exams - 2024-2025"
author: "Tate Mason"
---

## Macro

### Topics of Note
- **ADCE**: Understand how to set up ADCE and how to solve for different equilibria
  - The ADCE is an equilibrium consisting of a set of prices and allocations such that the market clears and all agents are maximizing their utility given the prices.
  - Endowments and consumption are equal, and weighted by pricing.
  $${\max\atop{c_1, c_2}} \sum\limits_{t=0}^{\infty} \beta^t u(c_t)$$
  $$\text{subject to } \sum\limits_{t=0}^{\infty} p_tc_t \leq \sum\limits_{t=0}^{\infty}p_te_t$$
  - In this setup, trade is agreed to at time $t<0$ and is binding for the entire life cycle.
  - The ADCE is a generalization of the Arrow-Debreu model, which assumes that agents can trade in a complete set of markets.
  - To solve, setup the Lagrangian and use the first-order conditions to derive the equilibrium prices and allocations.
    - Solve for the Lagrange multipliers and use them to derive the equilibrium conditions.
  - SPP vs CE
    - SPP: The SPP is a special case of the ADCE where the agents are only allowed to trade in a single market.
      - Does not use prices as weights, instead opting for SP weights.
      - Solve similarly, but looking for equilibrium weights and allocations
    - CE: The CE is a special case of the ADCE where the agents are allowed to trade in multiple markets.
      - Case described above
- **SMCE**: Understand how to set up SMCE and how to solve for different equilibria
- **TDCE**: Understand how to set up TDCE and how to solve for different equilibria
  - TDCE is a modificaion of CE in which the government imposes taxes and transfers on the agents and firms
  - The government uses the taxes and transfers to redistribute the wealth among the agents and firms.
  - To solve, similar to regular CE, but with the added constraint of the government budget constraint, and added MCC of government budget balancing
- **OLG**: How to set up the OLG model and solve for different equilibria
- **Consumption Savings**: Understand how to set up consumption savings, solve for steady state
- **Computational Algorithm**: Be able to set up the MatLab algorithm for various problems or be able to interpret the code in the context of solving a model

#### Topics to Review
- Blackwell Conditions
  - The Blackwell conditions are a set of conditions that ensure the existence of a unique equilibrium in a dynamic programming problem.
  - The conditions are:
    1. Monotonicity: $u\leq v$ implies $T(u)\leq T(v)$
    2. Discounting: $T(u+c) \leq T(u) + \beta c$

    Proof:
    $$\forall \ V, W \in B(K), V(k) \leq W(k) + \sup|V(k) - W(k)| = W(k) + ||V-W|| \forall k\in K $$
    $$T(W)(k) \leq T(V+||V-W||)(k) \forall k\in K $$
    $$T(W)(k)\leq T(V)(k) + \beta||V-W|| \forall k\in K$$
    $$T(V)(k) \leq T(W)(k) + \beta||V-W|| \forall k\in K$$
    $$||T(V)(k)-T(W)(k)|| \leq \beta||V-W|| \forall k\in K$$
    $$\implies {\sup\atop{k\in K}}|T(V)(k)-T(W)(k)| \leq \beta||V-W||$$
    $$\implies ||T(V)-T(W)|| \leq \beta||V-W||$$
    Look at the homeworks for the simple proofs
- Bellman Equation/Operator
  - 
- Pareto Efficient Allocations
- Envelope Conditions
  - The envelope condition finds the derivative of the value function at the optimum
  - Example:
    $$V(k) = \max\limits_{c} \left\{ u(c) + \beta V(k') \right\}$$
    $$\implies V'(k) = u'(c) + \beta V'(k')$$
    - The envelope condition is used to derive the first-order conditions for the optimal consumption and savings decisions of agents in a dynamic programming problem.
- Dynamic Programming/VFI

## Metrics

### Topics of Note
- **PMF**: Properties of PMF
- **Continuously Distributed Random Variables**: Properties of continuous random variables
- **PDF**: Properties of PDF
- **CDF**: Properties of CDF
- **Distributions**: Able to work with Bernoullli, Normal, Uniform
- **Basic Probperties of Error Terms**: Understand the basic properties of error terms, i.e. $\mathbb{E}[Xe^2] = 0$?
- **CEF vs Linear Projection**: Understand the difference between CEF and linear projection
- **Variance (sampling too)**: How to derive and different properties
- **MSE**: Understand the properties of MSE
- **Bias-Variance Decomposition**: Understand the properties of bias-variance decomposition
- **Covariance**: How to calculate
- **Consistency, Unbiasedness, Asymptotic Normality**: Understand the properties and how to show these
- **ATT/ATE**: Define, properties, estimate, $\underbar{V}$ of, $\alpha D_i$ $\rightarrow$ what is $\alpha$?
- **FWL Theorem**: Derive and prove
- **IV Estimation**: Basically everything relating to IV
- **Slutsky Theorem**: Showed up once
- **$\hat{\beta}$**: Understand the properties of $\hat{\beta}$ and how to derive it, and all conditions
  
  - Derive, consistency, unbiansednes, asymptotic normality, $\underbar{V}, \ \hat{\underbar{V}}$, testing, and data matrix form
- **Group-Time ATE**: Assumptions, definitions, derivation
- **Statistical Testing**: Understand the properties of statistical testing, i.e. how to derive the test statistic, how to calculate the p-value, how to interpret the results
- **Errors**: T1, T2 errors
- Homoskedasticity vs Heteroskedasticity: Understand the difference and how they affect $\hat{\beta}$.
- **2023 Q8**: Confused me idk
- **Efficiency of estimator**: Explain and derive
- **Feasible Regression Models**: How to work with
- **Delta Method**: Understand the properties of the delta method and how to apply it
- **GMM**: Estimation and optimal weighting matrix, J-Test
- **Bootstrap**: Understand what bootstrapping is and how to estimate different bootstrap statistics

## Micro

### Topics of Note
- **Choice Theory**: Understand the basic properties of choice theory, i.e. how to derive the utility function, how to calculate the marginal utility, how to calculate the marginal rate of substitution, other stuff
- **Irrelevance of Rejected Items**:
- **WARP**: Understand WARP and associated proofs
- **Cournot Games**: Understand how to set up and solve Cournot games
- **Bertrand Games**: Understand how to set up and solve Bertrand games
- **Preference Relations**: Understand the properties of preference relations and how to derive them
- **Marshallian Demand**: Know how to derive Marshallian demand and how to calculate it
- **Expenditure Function**: Understand the properties of the expenditure function and how to derive it
- **Quasilinear Preferences**: Understand the properties of quasilinear preferences and how to derive them
- **Slutsky Decomposition**: Understand the properties of the Slutsky decomposition and how to derive it
- **Equivalent Variation**: Understand the properties of equivalent variation and how to derive it

#### Games
- **Signaling Games**: Understand how to set up and solve signaling games
- **Bayesian Games**: Understand how to set up and solve Bayesian games for Bayesian Nash Equilibrium
- **Pooled Bayesian Equilibrium**: Understand how to set up and solve pooled Bayesian equilibrium
- **Sequential Equilibrium**: Understand how to set up and solve sequential equilibrium

#### Auctions
- **Definition of Strategy Proof**
- **First Price Auction**: Understand how to set up and solve first price auctions
- **Second Price Auction**: Understand how to set up and solve second price auctions
- **Optimal Auction**: Just memorize the optimal auction
- **Buyer-Seller Auction**: Same as in notes from class
- **2024 - Q4**
- **IR and IC**: BIC vs DIC and how to derive

For Micro, review a lot of Akhil and Nathan's proofs.
