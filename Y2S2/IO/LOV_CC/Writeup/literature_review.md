# Love of Variety: Literature Review

**Tate Mason**  
*April 2026*

---

## Overview

This project develops a model of consumer "love of variety" (LOV) and firm advertising behavior, studied through simulation. The core idea is that consumers derive utility from product attributes but are penalized for consuming the same attributes repeatedly — capturing the empirical regularity that consumers value novelty and variety. The project proceeds in two stages: an initial simulation establishing baseline consumer dynamics, and a richer model incorporating firm behavior and endogenous advertising.

---

## 1. Consumer Problem

### 1.1 Initial Formulation (Mason, March 2026)

The consumer maximizes utility over a choice set of products. The utility function is:

$$U_{ijt} = \beta_i \cdot X_{jt} - \gamma_{ijt}(X_{jt} - \bar{X}_{jt})^2 + \epsilon_{ijt}$$

where:
- $X_{jt}$ is the attribute of product $j$ at time $t$
- $\bar{X}_{jt}$ is the running mean attribute (history of past choices)
- $\beta_i$ governs preference for higher attributes
- $\gamma_{ijt}$ governs sensitivity to sameness — the love-of-variety parameter
- $\epsilon_{ijt} \sim \text{T1EV}$ is an idiosyncratic error

Choice probabilities follow the standard logit form:

$$P_{ijt} = \frac{e^{U_{ijt}}}{\sum_k e^{U_{ikt}}}$$

The firm presents three products per period, drawn from $C_t \sim \mathcal{N}(\bar{X}_{j,t}, \sigma_x^2)$, where $\sigma_x$ controls the dispersion of the offered choice set.

### 1.2 Extended Formulation (Mason, April 2026)

The full model extends the utility function to include advertising and an outside option:

$$U_{ijt} = \beta_i X_{jt} - \gamma_i (\Sigma_{ijt})^2 + \kappa a_{jt} - \alpha_j p_{jt} + \xi_j + \epsilon_{ijt}$$

where $\Sigma_j = X_{it} - X_{jt}$ is the cumulative sum of attributes chosen through time $t$, capturing the full history of consumption rather than only the mean deviation. The inclusion of $\Sigma_j$ means consumers are penalized for accumulating a homogeneous consumption history. The choice probability adds an outside option:

$$P_{ijt} = \frac{e^{U_{ijt}}}{1 + \sum_k e^{U_{ikt}}}$$

---

## 2. Firm Problem

The firm maximizes profits by choosing advertising intensity $a_{jt}$. Per-period profits are:

$$\pi_{jt} = s_{jt}(p_{jt}, a_{jt})(p_{jt} - mc_{jt}) - \kappa a_{jt}^2$$

where $s_{jt}$ is market share (i.e., the consumer's choice probability), and advertising costs are quadratic. Two advertising regimes are studied:

**Fixed advertising:** $a_{jt} = 0.2$ for all $j, t$.

**Markov advertising:** $a_{jt} \sim \text{lognormal}\!\left(\frac{(\bar{X}_{it} - X_{jt})^2}{1 + \sum_k (X_{kt} - X_{kt})^2},\, \sigma_a\right)$, meaning the firm advertises more when its product is more differentiated from the average product in the market.

The firm's dynamic value function is:

$$V(a_{jt} | \lambda_{jt}(\gamma_i)) = \max_{\pi_{jt}} \left\{ \pi_{jt} + \int_\gamma V'(a_{j,t+1} | \lambda_{j,t+1}(\gamma_i))\, d\lambda(\gamma) \right\}$$

where $\lambda(\gamma)$ is the firm's belief distribution over consumer type $\gamma_i$. The firm updates its mean belief using past purchase history: $\lambda_t(\gamma) \sim \mathcal{N}(1/\Sigma_{jt},\, \sigma_\lambda)$.

---

## 3. Simulation Design

### 3.1 Parameters

| Parameter | Value | Description |
|---|---|---|
| $T$ | 100 | Periods |
| $J$ | 5 | Products |
| $S$ | 1,000 | Simulation draws |
| $\beta_i$ | {0.2, 0.5, 0.8} | Consumer preference for attributes |
| $\gamma_i$ | {0.2, 0.5, 0.8} | Consumer cost of sameness |
| $\kappa$ | 2 | Advertising cost parameter |
| $\alpha_j$ | 0 | Price sensitivity (zeroed out) |
| $p_{jt}$ | 2 | Price |
| $mc_{jt}$ | 1 | Marginal cost |
| $\beta_{DF}$ | 0.9 | Firm discount factor |

### 3.2 Regimes

Nine parameter combinations are examined: low ($\beta = \gamma = 0.2$), medium ($\beta = \gamma = 0.5$), high ($\beta = \gamma = 0.8$), and six mixed regimes spanning all combinations of $\beta, \gamma \in \{0.2, 0.5, 0.8\}$.

---

## 4. Key Findings

### 4.1 Consumer Utility Dynamics

Consumer utility declines monotonically over time across all regimes and specifications. This is a mechanical consequence of the model: as the consumer repeatedly selects from the same distribution of products, $\Sigma_j$ accumulates and the sameness penalty compounds. The rate of decline is steeper for higher $\gamma$, as expected.

In the initial simulation, under low $\beta$ and $\gamma$, the consumer converges to a "steady state" where utility tracks the chosen attribute after roughly 50 periods. The medium regime requires closer to 75 periods, with persistent volatility. The high regime produces intermittent utility spikes — consumers like what they like more, but are also more punished by repetition, creating volatile dynamics. Mixed regimes produce asymmetric patterns: high $\gamma$ / low $\beta$ leads to persistently negative utility, while low $\gamma$ / high $\beta$ produces positive utility spikes from attribute-rich choices.

### 4.2 Rolling Variance of Consumer Choices

With $\sigma_x \in \{0.5, 1.0, 1.5\}$, higher $\sigma_x$ universally produces more volatile choice variance over time. The convergence speed depends on regime: lower $\gamma$ leads to faster stabilization regardless of $\sigma_x$. The high-$\gamma$ regimes show sustained growth in variance for the largest $\sigma_x$ value, while the lower two converge after 25–50 periods. This suggests that consumer sensitivity to sameness amplifies the impact of firm-side dispersion in the choice set.

### 4.3 Firm Advertising

Under **fixed advertising**, choice probabilities across all five products are bunched near $0.2$ (consistent with equal shares among five products plus the outside option). Advertising incentives are uniformly negative — the firm always prefers not to advertise under the fixed specification, which is unsurprising given that fixed advertising adds cost without strategic information content.

Under **Markov advertising**, choice probabilities show substantially more variation, particularly for Product 1. The Markov rule — advertising more when differentiation is high — generates richer dynamics where products cycle in and out of favor as the firm adjusts to the evolving consumption history. The ad incentive is positive under Markov advertising, confirming the model's internal consistency: when advertising is targeted to differentiated products, it is profitable.

---

## 5. Connections to the Literature

This model connects to several strands of the IO and marketing literature:

- **Love of variety / demand for diversity:** The $\gamma$ parameter directly encodes a form of variety-seeking behavior analogous to that studied in brand-switching and category purchase contexts. The quadratic sameness penalty echoes the "ideal point" models in hedonic demand.

- **Dynamic discrete choice:** The sequential choice structure and the role of consumption history ($\Sigma_j$) is reminiscent of habit formation and state dependence models (e.g., Heckman 1981; Erdem and Keane 1996). Here, however, the state variable works in the opposite direction — past consumption *hurts* future utility, creating variety-seeking rather than habit persistence.

- **Firm belief updating / targeted advertising:** The Markov advertising rule, where the firm advertises based on its inference about $\gamma$ from past purchases, connects to the Bayesian persuasion and targeted advertising literatures. The firm uses consumption history as a signal of consumer type.

- **Recommender systems and algorithmic curation:** The setup — a firm choosing which products to surface to a consumer, with the consumer preferring variety — directly maps onto the economics of recommendation algorithms. The tension between consumer preference for novelty and firm incentives to promote specific products is a central theme in the emerging literature on platform design and filter bubbles.

---

## 6. Next Steps

- Make the advertising decision fully endogenous to the firm's belief distribution over $\gamma$.
- Extend to a population of heterogeneous consumers ($i > 1$) and study aggregate market share dynamics.
- Estimate $\beta$ and $\gamma$ from data using the simulated likelihood implied by the model.
- Analyze welfare implications of different advertising regimes for consumer surplus.
