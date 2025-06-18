# ECON 8040: Dynamic Economic Theory - Complete Synthesis

**Comprehensive Course Notes for Undergraduate Economics Students**

---

## Table of Contents

1. [Mathematical Foundations](#1-mathematical-foundations)
2. [Dynamic Programming Theory](#2-dynamic-programming-theory)
3. [Neoclassical Growth Model](#3-neoclassical-growth-model)
4. [Search Theory and Unemployment](#4-search-theory-and-unemployment)
5. [Stochastic Growth Models](#5-stochastic-growth-models)
6. [Dynamic General Equilibrium](#6-dynamic-general-equilibrium)
7. [Endogenous Growth Theory](#7-endogenous-growth-theory)
8. [Asset Pricing and Risk](#8-asset-pricing-and-risk)
9. [Computational Methods](#9-computational-methods)
10. [Welfare Economics and Policy](#10-welfare-economics-and-policy)

---

## 1. Mathematical Foundations

### 1.1 Complete Metric Spaces

**Definition: Bounded Function**
A function $f: X \to \mathbb{R}$ is **bounded** if there exists a constant $K > 0$ such that $|f(x)| < K$ for all $x \in X$.

**Definition: Upper Bound and Supremum**
Let $S$ be any subset of $\mathbb{R}$. A number $u \in \mathbb{R}$ is an **upper bound** for the set $S$ if $s \leq u$ for all $s \in S$. The **supremum** of $S$, denoted $\sup(S)$, is the smallest upper bound of $S$.

**Definition: Metric Space**
A **metric space** is a set $S$ and a function $d: S \times S \to \mathbb{R}$ such that:
1. $d(x,y) \geq 0$ for all $x$ and $y$ in $S$
2. $d(x,y) = 0$ if and only if $x = y$
3. $d(x,y) = d(y,x)$ (symmetry)
4. $d(x,z) \leq d(x,y) + d(y,z)$ (triangle inequality)

**Important Examples of Metric Spaces:**
- **Real numbers:** $S = \mathbb{R}$ and $d(x,y) = |x - y|$
- **Discrete metric:** $S = \mathbb{R}$ and $d(x,y) = 1$ if $x \neq y$, $0$ otherwise
- **Bounded sequences:** $S = l^{\infty} = \{x = \{x_t\}_{t=0}^{\infty} : x_t \in \mathbb{R}, \sup_t |x_t| < \infty\}$ with $d(x,y) = \sup_t |x_t - y_t|$
- **Continuous bounded functions:** $S = C(X)$ with $d(f,g) = \sup_{x \in X} |f(x) - g(x)|$

> **Economic Intuition:** The last two examples are crucial for economics. Sequences represent consumption or capital allocations over time, while function spaces contain value functions and policy functions from dynamic programming.

### 1.2 Sequences and Convergence

**Definition: Convergence**
A sequence $\{x_n\}_{n=0}^{\infty}$ with $x_n \in S$ for all $n$ **converges** to $x \in S$ if for every $\varepsilon > 0$ there exists $N_{\varepsilon} \in \mathbb{N}$ such that $d(x_n, x) < \varepsilon$ for all $n \geq N_{\varepsilon}$.

**Definition: Cauchy Sequence**
A sequence $\{x_n\}_{n=0}^{\infty}$ is a **Cauchy sequence** if for every $\varepsilon > 0$ there exists $N_{\varepsilon} \in \mathbb{N}$ such that $d(x_n, x_m) < \varepsilon$ for all $n, m \geq N_{\varepsilon}$.

**Theorem: Convergent sequences are Cauchy**
If a sequence converges in a metric space, then it is a Cauchy sequence.

**Definition: Complete Metric Space**
A metric space $(S,d)$ is **complete** if every Cauchy sequence converges to some point in $S$.

### 1.3 Open and Closed Sets

**Definition: $\varepsilon$-neighborhood**
An **$\varepsilon$-neighborhood** of $x$ is $B_{\varepsilon}(x) = \{y \in S : d(x,y) < \varepsilon\}$.

**Definition: Open Set**
A subset $X \subseteq S$ is **open** if for every $x \in X$, there exists $\varepsilon > 0$ such that $B_{\varepsilon}(x) \subset X$.

**Definition: Closed Set**
A subset $X \subseteq S$ is **closed** if its complement $X^c = S - X$ is open.

**Theorem: Characterization of Closed Sets**
Let $(S,d)$ be a metric space and $X \subseteq S$. Then $X$ is closed if and only if whenever $\{x_n\}_{n=0}^{\infty}$ is a convergent sequence with $x_n \in X$ and $\lim_{n\to\infty} x_n = x$, we have $x \in X$.

### 1.4 Contraction Mapping Theorem

**Definition: Contraction Mapping**
Let $(S,d)$ be a metric space and $T: S \to S$. Then $T$ is a **contraction mapping** if there exists $\beta \in (0,1)$ such that $d(Tx, Ty) \leq \beta d(x,y)$ for all $x,y \in S$. The number $\beta$ is called the **modulus** of the contraction.

**Contraction Mapping Theorem**
Let $(S,d)$ be a complete metric space and $T: S \to S$ be a contraction mapping with modulus $\beta$. Then:
1. $T$ has exactly one fixed point $v^* \in S$
2. For any $v_0 \in S$ and any $n \in \mathbb{N}$: $d(T^n v_0, v^*) \leq \beta^n d(v_0, v^*)$

**Proof sketch:** Define sequence $v_n = T^n v_0$. Show this is Cauchy using contraction property, hence converges to some $v^*$ by completeness. Then $Tv^* = T(\lim v_n) = \lim T v_n = \lim v_{n+1} = v^*$, so $v^*$ is a fixed point. Uniqueness follows from contraction property.

### 1.5 Blackwell's Sufficient Conditions

**Blackwell's Theorem**
Let $X \subseteq \mathbb{R}^l$ and $B(X)$ be the space of bounded functions $f: X \to \mathbb{R}$ with the sup-norm. Let $T: B(X) \to B(X)$ satisfy:
1. **Monotonicity:** If $f(x) \leq g(x)$ for all $x \in X$, then $(Tf)(x) \leq (Tg)(x)$ for all $x \in X$
2. **Discounting:** There exists $\beta \in (0,1)$ such that for all $f \in B(X)$, all $a \geq 0$, and all $x \in X$: $[T(f + a)](x) \leq [Tf](x) + \beta a$

Then $T$ is a contraction mapping with modulus $\beta$.

> **Economic Intuition:** Blackwell's conditions are easier to verify than the contraction mapping definition directly. Monotonicity means "better value functions stay better after applying the operator." Discounting means "constant improvements get discounted by factor $\beta$."

---

## 2. Dynamic Programming Theory

### 2.1 The Bellman Equation

**The Fundamental Dynamic Programming Problem**
We want to solve the functional equation:
$$v(x) = \max_{y \in \Gamma(x)} \{F(x,y) + \beta v(y)\}$$

where:
- $x$ is the **state variable** (e.g., current capital)
- $y$ is the **control variable** (e.g., future capital)
- $F(x,y)$ is the **period return function** (e.g., utility)
- $\beta \in (0,1)$ is the **discount factor**
- $\Gamma(x)$ is the **constraint set**

**The Bellman Operator**
Define the **Bellman operator** $T$ by:
$$(Tv)(x) = \max_{y \in \Gamma(x)} \{F(x,y) + \beta v(y)\}$$

A solution to the Bellman equation is a **fixed point** of $T$: $v^* = Tv^*$.

> **Economic Intuition:** Think of the Bellman operator as a "recipe" that takes your current guess about the value function and gives you a better guess. The true value function is the one that doesn't change when you apply this recipe—it's a fixed point.

### 2.2 Existence and Uniqueness

**Standard Assumptions for Dynamic Programming**
1. $X$ is a convex subset of $\mathbb{R}^l$ and $\Gamma: X \rightrightarrows X$ is nonempty, compact-valued, and continuous
2. $F: X \times X \to \mathbb{R}$ is continuous and bounded, and $\beta \in (0,1)$

**Existence and Uniqueness of Value Function**
Under the standard assumptions, the Bellman operator:
1. Maps $C(X)$ into itself
2. Satisfies Blackwell's conditions
3. Has a unique fixed point $v^* \in C(X)$
4. Value function iteration converges: $\lim_{n\to\infty} T^n v_0 = v^*$ for any $v_0 \in C(X)$

### 2.3 Properties of the Value Function

**Additional Assumptions for Monotonicity**
3. For any fixed $y$, $F(\cdot, y)$ is strictly increasing in all components
4. $\Gamma$ is monotone: if $x \leq x'$, then $\Gamma(x) \subseteq \Gamma(x')$

**Monotonicity of Value Function**
Under assumptions 1-4, the unique fixed point $v^*$ is strictly increasing.

**Additional Assumptions for Concavity**
5. $F$ is strictly concave
6. $\Gamma$ is convex-valued and has a convex graph

**Concavity and Policy Function**
Under assumptions 1-6, the unique fixed point $v^*$ is strictly concave and the optimal policy is a single-valued continuous function $g: X \to X$.

### 2.4 Differentiability and Envelope Theorem

**Differentiability Assumption**
7. $F$ is continuously differentiable on the interior of $X \times X$

**Differentiability of Value Function (Envelope Theorem)**
Under assumptions 1-7, if $x_0$ is an interior point of $X$ and $g(x_0)$ is an interior point of $\Gamma(x_0)$, then $v^*$ is continuously differentiable at $x_0$ and:
$$\frac{\partial v^*(x_0)}{\partial x_i} = \frac{\partial F(x_0, g(x_0))}{\partial x_i}$$

> **Economic Intuition:** The envelope theorem says that the marginal value of the state variable equals the direct marginal effect of that variable on the return function, evaluated at the optimal choice. This is because the indirect effect through the choice variable is zero by the first-order condition.

---

## 3. Neoclassical Growth Model

### 3.1 The Social Planner's Problem

**The Planning Problem**
A social planner chooses consumption and investment to maximize discounted utility:
$$w(k_0) = \max_{\{k_{t+1}\}_{t=0}^{\infty}} \sum_{t=0}^{\infty} \beta^t u(f(k_t) - k_{t+1})$$

subject to:
- $0 \leq k_{t+1} \leq f(k_t)$ (feasibility)
- $k_0$ given (initial capital)

where $f(k_t) - k_{t+1}$ is consumption and $k_{t+1}$ is next period's capital.

**Standard Assumptions**
1. $u: \mathbb{R}_+ \to \mathbb{R}$ is strictly increasing, strictly concave, and bounded
2. $f: \mathbb{R}_+ \to \mathbb{R}_+$ is strictly increasing, strictly concave, with $f(0) = 0$ and $f'(0) > 1/\beta$

### 3.2 The Bellman Equation

**Value Function for Growth Model**
The value function satisfies:
$$V(k) = \max_{0 \leq k' \leq f(k)} \{u(f(k) - k') + \beta V(k')\}$$

**Properties of the Value Function**
Under the standard assumptions:
1. $V(k)$ is continuous, strictly increasing, strictly concave, and continuously differentiable
2. The optimal policy function $g(k)$ is continuous
3. $w(k_0) = V(k_0)$ (the dynamic programming solution equals the sequential solution)

### 3.3 First-Order Conditions

**Optimality Conditions**
The optimal policy satisfies:
1. **First-order condition:** $u'(f(k) - k') = \beta V'(k')$
2. **Envelope condition:** $V'(k) = u'(f(k) - k') f'(k)$
3. **Euler equation:** $u'(c_t) = \beta u'(c_{t+1}) f'(k_{t+1})$

> **Economic Intuition:** The Euler equation says: the marginal cost of saving today (giving up consumption) equals the discounted marginal benefit tomorrow (extra utility from extra output times marginal utility of consumption).

### 3.4 Steady State and Dynamics

**Steady State**
A **steady state** is a capital level $k^*$ such that $g(k^*) = k^*$. It satisfies:
$$\frac{1}{\beta} = f'(k^*) \text{ and } g(k^*) = k^*$$

**Steady State Properties**
1. There exists a unique steady state $k^*$
2. If $k_0 < k^*$, then $k_t$ is increasing and converges to $k^*$
3. If $k_0 > k^*$, then $k_t$ is decreasing and converges to $k^*$

### 3.5 Transversality Condition

**Necessity of Euler Equation and Transversality Condition**
Any solution $\{k_{t+1}\}_{t=0}^{\infty}$ to the planning problem must satisfy:
1. **Euler equation:** $-u'(f(k_t) - k_{t+1}) + \beta u'(f(k_{t+1}) - k_{t+2}) f'(k_{t+1}) = 0$
2. **Transversality condition:** $\lim_{T\to\infty} \beta^T u'(c_T) k_{T+1} = 0$

**Sufficiency**
Any sequence satisfying the Euler equation and transversality condition solves the planning problem.

> **Economic Intuition:** The transversality condition prevents "over-saving"—it ensures that the marginal value of capital goes to zero as time goes to infinity, so we don't accumulate capital indefinitely without consuming.

---

## 4. Search Theory and Unemployment

### 4.1 McCall Search Model

**Setup**
An unemployed worker:
- Has utility function $u(c) = c$ and discount factor $\beta$
- Receives i.i.d. wage offers $w$ drawn from distribution $F(w)$
- Each period chooses to: **accept** (work forever at wage $w$) or **reject** (remain unemployed, get benefit $b$, draw new offer next period)

**Bellman Equation for Search**
The value function for an unemployed worker with wage offer $w$ is:
$$v(w) = \max\left\{\frac{w}{1-\beta}, b + \beta \int_0^{\infty} v(w') dF(w')\right\}$$

### 4.2 Reservation Wage Property

**Reservation Wage**
There exists a **reservation wage** $\bar{w}$ such that:
- Accept if $w \geq \bar{w}$
- Reject if $w < \bar{w}$

The reservation wage satisfies:
$$\frac{\bar{w}}{1-\beta} = b + \beta \int_0^{\infty} v(w') dF(w')$$

### 4.3 Characterization of Reservation Wage

**Value of Unemployment**
Let $U = b + \beta \int_0^{\infty} v(w') dF(w')$ be the value of being unemployed. Then:
$$v(w) = \begin{cases}
U & \text{if } w \leq \bar{w} \\
\frac{w}{1-\beta} & \text{if } w > \bar{w}
\end{cases}$$

At the reservation wage: $U = \frac{\bar{w}}{1-\beta}$.

**Reservation Wage Equation**
The reservation wage satisfies:
$$\bar{w}(1 + \beta\delta - \beta F(\bar{w})) = b(1 - \beta(1-\delta)) + \beta \int_{\bar{w}}^{\infty} w' dF(w')$$

where $\delta$ is the job separation rate.

> **Economic Intuition:** Higher unemployment benefits $b$ increase the reservation wage (workers become pickier). Lower job separation rates $\delta$ also increase reservation wages (job security makes workers choosier). Better job offer distributions (higher wages) increase reservation wages.

### 4.4 Comparative Statics

**Effects on Reservation Wage**
1. $\frac{\partial \bar{w}}{\partial b} > 0$ (higher benefits $\Rightarrow$ higher reservation wage)
2. $\frac{\partial \bar{w}}{\partial \delta} < 0$ (higher separation rate $\Rightarrow$ lower reservation wage)
3. First-order stochastic dominance improvement in $F$ increases $\bar{w}$

---

## 5. Stochastic Growth Models

### 5.1 Environment with Uncertainty

**Stochastic Growth Model Setup**
- **Households:** Maximize expected utility $\sum_{t=0}^{\infty} \sum_{s^t \in S^t} \beta^t \pi_t(s^t) u(c_t(s^t), 1 - n_t(s^t))$
- **Technology:** $y_t(s^t) = A_t(s^t) F(k_t(s^{t-1}), n_t(s^t))$ where $A_t(s^t)$ is a stochastic productivity shock
- **Capital accumulation:** $k_{t+1}(s^t) = (1-\delta)k_t(s^{t-1}) + x_t(s^t)$
- **Feasibility:** $c_t(s^t) + k_{t+1}(s^t) = A_t(s^t) F(k_t(s^{t-1}), n_t(s^t)) + (1-\delta)k_t(s^{t-1})$

### 5.2 Markov Processes

**Markov Property**
A stochastic process $\{s_t\}$ has the **Markov property** if:
$$P(s_{t+1} | s_t, s_{t-1}, \ldots, s_0) = P(s_{t+1} | s_t) = \pi(s_{t+1} | s_t)$$

The transition matrix $\Pi$ has elements $\pi_{ij} = P(s_{t+1} = j | s_t = i)$.

### 5.3 Social Planner's Problem

**Stochastic Planning Problem**
$$\max_{\{c_t(s^t), n_t(s^t), k_{t+1}(s^t)\}} \sum_{t=0}^{\infty} \sum_{s^t \in S^t} \beta^t \pi_t(s^t) u(c_t(s^t), 1 - n_t(s^t))$$

subject to feasibility constraints for all $t$, $s^t$.

**First-Order Conditions**
1. **Euler equation:** 
$$1 = \beta \sum_{s_{t+1} \in S} \frac{\pi_t(s^t, s_{t+1})}{\pi_t(s^t)} \frac{u_c(c_{t+1}(s^t, s_{t+1}), 1 - n_{t+1}(s^t, s_{t+1}))}{u_c(c_t(s^t), 1 - n_t(s^t))} \times$$
$$\left[1 - \delta + A_{t+1}(s^t, s_{t+1}) F_k(k_{t+1}(s^t), n_{t+1}(s^t, s_{t+1}))\right]$$

2. **Labor choice:** 
$$\frac{u_n(c_t(s^t), 1 - n_t(s^t))}{u_c(c_t(s^t), 1 - n_t(s^t))} = A_t(s^t) F_n(k_t(s^{t-1}), n_t(s^t))$$

### 5.4 Recursive Formulation

**Recursive Social Planner's Problem**
With Markov shocks, the problem becomes:
$$v(k, s) = \max_{c, n, k' \geq 0} \left\{u(c, 1-n) + \beta \sum_{s' \in S} \pi(s' | s) v(k', s')\right\}$$

subject to: $c + k' = sF(k, n) + (1-\delta)k$

**Optimality Conditions**
1. **FOC w.r.t. $n$:** $sF_n(k, n) = \frac{u_n(c, 1-n)}{u_c(c, 1-n)}$
2. **FOC w.r.t. $k'$:** $u_c(c, 1-n) = \beta \sum_{s'} \pi(s' | s) v_k(k', s')$
3. **Envelope condition:** $v_k(k, s) = u_c(c, 1-n)[1 - \delta + sF_k(k, n)]$

### 5.5 Guess-and-Verify Method

**Example: Log Utility and Cobb-Douglas Production**
With $u(c) = \log c$, $F(k, n) = k^{\alpha}n^{1-\alpha}$, and $s \in \{s_L, s_H\}$, guess:
$$v(k, s) = A \log k + B(s)$$

The optimal policy functions are:
- $g(k, s) = \alpha\beta s k^{\alpha}$ (future capital)
- $c(k, s) = (1 - \alpha\beta) s k^{\alpha}$ (consumption)

where $A = \frac{\alpha}{1 - \alpha\beta}$.

> **Economic Intuition:** The stochastic growth model shows that optimal saving rates depend on current productivity shocks but the functional form of the policy (fraction of output saved) can remain simple under appropriate assumptions.

---

## 6. Dynamic General Equilibrium

### 6.1 Competitive Equilibrium

**Sequential Markets Competitive Equilibrium**
A competitive equilibrium consists of:
- **Allocations:** $\{c_t^*, x_t^*, k_{t+1}^*, h_t^*, l_t^*\}_{t=0}^{\infty}$
- **Prices:** $\{p_t^*, w_t^*, r_t^*\}_{t=0}^{\infty}$

Such that:
1. Given prices, allocations solve household optimization
2. Given prices, allocations solve firm optimization
3. Markets clear

### 6.2 Arrow-Debreu Equilibrium

**Complete Markets with Uncertainty**
In period 0, agents trade contingent claims for consumption in every possible future state $s^t$:
$$\max \sum_{t=0}^{\infty} \sum_{s^t \in S^t} \beta^t \pi_t(s^t) U(c_t^i(s^t))$$

subject to:
$$\sum_{t=0}^{\infty} \sum_{s^t \in S^t} p_t(s^t) c_t^i(s^t) \leq \sum_{t=0}^{\infty} \sum_{s^t \in S^t} p_t(s^t) e_t^i(s^t)$$

**Asset Pricing Formula**
The price of a contingent claim satisfies:
$$\frac{p_t(s^t)}{p_0(s^0)} = \beta^t \frac{\pi_t(s^t)}{\pi_0(s^0)} \frac{U'(c_t(s^t))}{U'(c_0(s^0))}$$

### 6.3 Recursive Competitive Equilibrium

**State Variables**
In recursive equilibrium, we need to keep track of:
- **Individual state:** $k$ (household's capital)
- **Aggregate state:** $K$ (economy's capital)
- **Shocks:** $s$ (productivity shocks)

**Recursive Competitive Equilibrium**
A collection of functions $\{V^*(k, K, s), c^*(k, K, s), g^*(k, K, s), G^*(K, s), w^*(K, s), r^*(K, s)\}$ such that:

1. **Household optimization:** Given aggregate law of motion $G^*(K, s)$ and prices, policies solve:
$$V(k, K, s) = \max_{c, k'} \{u(c, 1-n) + \beta \sum_{s'} \pi(s' | s) V(k', G^*(K, s), s')\}$$
subject to: $c + k' = w^*(K, s) n + (1 - \delta + r^*(K, s)) k$

2. **Competitive pricing:** $w^*(K, s) = F_N(K, H^*(K, s))$, $r^*(K, s) = F_K(K, H^*(K, s))$

3. **Consistency:** $G^*(K, s) = g^*(K, K, s)$ and $H^*(K, s) = h^*(K, K, s)$

4. **Feasibility:** $c^*(K, K, s) + G^*(K, s) = F(K, H^*(K, s)) + (1-\delta)K$

> **Economic Intuition:** The consistency condition is crucial: households take the aggregate law of motion as given, but in equilibrium, their individual behavior must be consistent with the aggregate behavior they expect.

### 6.4 Welfare Theorems

**First Welfare Theorem**
Any competitive equilibrium allocation is Pareto efficient.

**Second Welfare Theorem**
Any Pareto efficient allocation can be supported as a competitive equilibrium with appropriate transfers.

**Negishi Method**
To find competitive equilibrium:
1. Solve the social planner's problem for Pareto weights $(\alpha^1, \alpha^2)$
2. Choose weights to match competitive equilibrium initial conditions
3. Construct prices from Lagrange multipliers

---

## 7. Endogenous Growth Theory

### 7.1 AK Model

**AK Production Function**
$$Y = AK$$

where $A > 0$ is a constant representing the level of technology. Capital has constant returns—no diminishing marginal product.

**Balanced Growth Path**
With CRRA utility $u(c) = \frac{c^{1-\sigma} - 1}{1-\sigma}$:
$$\frac{c_{t+1}}{c_t} = (\beta A)^{1/\sigma}$$

The growth rate is constant and depends on:
- Technology parameter $A$
- Discount factor $\beta$  
- Intertemporal elasticity of substitution $1/\sigma$

> **Economic Intuition:** Unlike the neoclassical model, the AK model generates endogenous growth because the marginal product of capital doesn't diminish. Higher saving rates permanently increase growth rates.

### 7.2 Learning-by-Doing Model

**Externalities in Production**
Individual firm production: $y = Ak^{\alpha} \bar{K}^{\rho}$

Where:
- $k$ is the firm's capital
- $\bar{K}$ is aggregate capital (external effect)
- $\alpha + \rho = 1$ for sustained growth

**Market vs. Social Optimum**
1. **Competitive equilibrium:** $\frac{c_{t+1}}{c_t} = (\beta(1 - \delta + \alpha A))^{1/\sigma}$
2. **Social optimum:** $\frac{c_{t+1}}{c_t} = (\beta(1 - \delta + A))^{1/\sigma}$
3. **Market failure:** Private growth rate is too low because firms don't internalize the externality

### 7.3 Human Capital Models

**Lucas Model**
Production: $Y = AK^{\alpha} (uHN)^{1-\alpha}$

Human capital accumulation: $\dot{H} = \delta_H(1-u)H$

Where:
- $u$ is fraction of time spent working
- $1-u$ is fraction spent accumulating human capital
- $H$ is average human capital

> **Economic Intuition:** Human capital models show how education and learning create sustained growth. The key insight is that human capital, like physical capital, can be accumulated without diminishing returns in the aggregate.

---

## 8. Asset Pricing and Risk

### 8.1 Stochastic Discount Factor

**Asset Pricing Kernel**
The **stochastic discount factor** or pricing kernel is:
$$m_{t+1} = \beta \frac{u'(c_{t+1})}{u'(c_t)}$$

Any asset with payoff $d_{t+1}$ has price:
$$p_t = E_t[m_{t+1} d_{t+1}]$$

### 8.2 Risk-Free Rate

**Risk-Free Rate Formula**
$$\frac{1}{1 + r^f} = E_t[m_{t+1}] = \beta E_t\left[\frac{u'(c_{t+1})}{u'(c_t)}\right]$$

With CRRA utility and lognormal consumption:
$r^f \approx -\log \beta + \sigma g_c - \frac{1}{2}\sigma^2 \sigma_c^2$

where $g_c$ is consumption growth and $\sigma_c^2$ is its variance.

### 8.3 Equity Premium

**Equity Premium Puzzle**
The excess return on stocks over bonds is:
$E[R^s] - R^f = -\frac{\text{Cov}(m_{t+1}, R^s_{t+1})}{E[m_{t+1}]}$

With CRRA utility:
$E[R^s] - R^f = \gamma \text{Cov}(\Delta \log c_{t+1}, R^s_{t+1})$

**The Puzzle**
- **Historical equity premium:** $\sim 6\%$ annually
- **Consumption-stock return correlation:** $\sim 0.2$
- **Consumption volatility:** $\sim 2\%$ annually
- **Implied risk aversion:** $\gamma \approx 30$ (implausibly high)

> **Economic Intuition:** The equity premium puzzle shows that standard consumption-based models struggle to explain why stocks earn such high returns relative to bonds, given the observed volatility of consumption.

### 8.4 Asset Pricing with Production

**Capital Asset Returns**
In a production economy:
$R^k_{t+1} = \frac{r_{t+1} + q_{t+1}(1-\delta)}{q_t}$

where $r_{t+1}$ is the rental rate and $q_t$ is the price of capital.

**Euler Equation for Capital**
$1 = E_t\left[\beta \frac{u'(c_{t+1})}{u'(c_t)} R^k_{t+1}\right]$

In equilibrium with adjustment costs:
$1 = E_t\left[\beta \frac{u'(c_{t+1})}{u'(c_t)} \frac{F_k(k_{t+1}, n_{t+1}) + q_{t+1}(1-\delta)}{q_t}\right]$

---

## 9. Computational Methods

### 9.1 Value Function Iteration

**Algorithm**
1. **Discretize** state space: $k_1 < k_2 < \ldots < k_N$
2. **Initialize** value function: $V^0(k_i)$ for all $i$
3. **Iterate** until convergence:
   $V^{n+1}(k_i) = \max_j \{u(f(k_i) - k_j) + \beta V^n(k_j)\}$
4. **Extract** policy function: $g(k_i) = k_j$ where $j$ achieves the maximum

**MATLAB Implementation Structure**
```matlab
% Parameters
alpha = 0.36; beta = 0.99; delta = 0.025;

% Grid
kmin = 0.1; kmax = 45; Nk = 500;
Kgrid = linspace(kmin, kmax, Nk);

% Return matrix
c = zeros(Nk, Nk);
for j = 1:Nk
    c(:,j) = Kgrid.^alpha + (1-delta)*Kgrid - Kgrid(j);
end

% Handle feasibility
violations = (c <= 0);
u = log(c.*(c >= 0) + eps) - 1000*violations;

% Value function iteration
V = zeros(Nk, 1);
for iter = 1:maxiter
    [TV, policy] = max(u + beta*ones(Nk,1)*V', [], 2);
    if max(abs(TV - V)) < tol, break; end
    V = TV;
end
```

### 9.2 Policy Function Iteration

**Howard's Improvement Algorithm**
1. **Start** with initial policy $g^0$
2. **Policy evaluation:** Solve $V^n = (I - \beta P_{g^n})^{-1} u_{g^n}$
3. **Policy improvement:** $g^{n+1}(k) = \arg\max_{k'} \{u(f(k) - k') + \beta V^n(k')\}$
4. **Repeat** until $g^{n+1} = g^n$

### 9.3 Projection Methods

**Functional Approximation**
Approximate the value function using basis functions:
$V(k) \approx \sum_{i=1}^n c_i \phi_i(k)$

Common choices:
- **Polynomials:** $\phi_i(k) = k^{i-1}$
- **Chebyshev polynomials**
- **Splines**

### 9.4 Perturbation Methods

**Log-Linearization**
Around steady state $(k^*, c^*)$, approximate:
$\hat{k}_{t+1} = A \hat{k}_t + B \varepsilon_{t+1}$
$\hat{c}_t = C \hat{k}_t$

where $\hat{x}_t = \log(x_t/x^*)$ and $\varepsilon_t$ are shocks.

> **Economic Intuition:** Different methods trade off accuracy and computational speed. Value function iteration is robust but slow. Policy iteration is faster but requires matrix inversions. Projection methods can be very accurate with few parameters. Perturbation methods are fast but only accurate near steady state.

---

## 10. Welfare Economics and Policy

### 10.1 Pareto Efficiency

**Pareto Efficient Allocation**
An allocation is **Pareto efficient** if there is no other feasible allocation that makes at least one agent better off without making any other agent worse off.

**Characterization with CRRA Utility**
With $u^i(c) = \frac{((c^i)^{1-\sigma} - 1)}{1-\sigma}$, Pareto efficiency requires:
$\frac{u'(c^1_t)}{u'(c^2_t)} = \frac{(c^1_t)^{-\sigma}}{(c^2_t)^{-\sigma}} = \frac{\alpha^1}{\alpha^2}$

The ratio of marginal utilities is constant across time and states.

### 10.2 Ricardian Equivalence

**Ricardian Equivalence Theorem**
In economies with:
- Infinite-lived agents
- Perfect capital markets  
- Lump-sum taxes

The timing of taxes does not affect real allocations—only the present value of taxes matters.

> **Economic Intuition:** Government borrowing today must be paid for by higher taxes tomorrow. Forward-looking agents increase saving to pay future taxes, exactly offsetting the government borrowing.

### 10.3 Optimal Taxation

**Ramsey Problem**
Choose tax rates $\{\tau^c_t, \tau^n_t, \tau^k_t\}$ to maximize welfare subject to:
- Government budget constraint
- Private sector optimization
- Resource constraints

**Key Results**
1. **Smooth tax rates:** Optimal taxes are approximately constant over time
2. **Zero capital tax:** In the long run, $\tau^k = 0$ (Chamley-Judd result)
3. **Labor tax smoothing:** Labor taxes absorb shocks to government spending

### 10.4 Social Security

**Pay-As-You-Go System**
Current workers pay taxes to fund current retirees:
$\text{Benefits}_t = \frac{\text{Tax rate} \times \text{Wage bill}_t}{\text{Number of retirees}_t}$

> **Economic Intuition:** Social Security creates both insurance (against longevity risk) and distortions (reduces saving incentives). The welfare effects depend on demographics, risk aversion, and the return differential between Social Security and private capital.

### 10.5 Business Cycle Policy

**Stabilization Policy**
Government can use:
- **Fiscal policy:** Government spending $G_t$ and taxes
- **Monetary policy:** Interest rates and money supply

To stabilize output and employment fluctuations.

**Automatic Stabilizers**
- **Progressive taxation:** Tax rates fall in recessions
- **Unemployment insurance:** Transfers increase in recessions
- **Welfare effects:** Provide insurance but may reduce work incentives

> **Economic Intuition:** The key tension in macroeconomic policy is between providing insurance against aggregate shocks and maintaining proper incentives for work, saving, and investment.

---

## Key Takeaways for Undergraduate Students

### Core Economic Insights

1. **Intertemporal optimization:** Economic agents make choices over time by weighing current costs against future benefits

2. **Equilibrium dynamics:** Markets coordinate individual decisions, but the resulting allocations may not be socially optimal

3. **Role of uncertainty:** Risk and incomplete information fundamentally change economic behavior and policy prescriptions

4. **Growth mechanisms:** Long-run prosperity depends on capital accumulation, technological progress, and human capital formation

5. **Policy trade-offs:** Government interventions provide insurance and correct market failures but create distortions

### Why This Matters

Dynamic economic theory provides the foundation for understanding business cycles, economic growth, asset prices, labor markets, and government policy. The mathematical tools—while challenging—allow economists to make precise predictions and evaluate policy proposals rigorously.

The models you've studied form the backbone of modern macroeconomics and are used by central banks, government agencies, and financial institutions to guide trillion-dollar decisions affecting millions of people.

### Real-World Applications

- **Central banking:** DSGE models guide monetary policy decisions
- **Public finance:** Dynamic tax models inform fiscal policy
- **Asset management:** Consumption-based models price financial securities
- **Labor economics:** Search models explain unemployment dynamics
- **Development economics:** Growth models guide development strategies

### Mathematical Tools Recap

**Complete Metric Spaces:** Framework for measuring "distance" between functions, essential for proving convergence of value function iteration.

**Contraction Mapping Theorem:** Guarantees unique solutions to dynamic programming problems and provides computational algorithms.

**Envelope Theorem:** Relates how the value function changes with parameters to the first-order conditions of the optimization problem.

**Bellman Equation:** Transforms infinite-horizon problems into recursive problems that can be solved computationally.

**Euler Equations:** Characterize optimal consumption and investment paths through intertemporal trade-offs.

**Transversality Conditions:** Prevent "bubble" solutions where agents accumulate assets indefinitely.

**Stochastic Discount Factors:** Link asset prices to consumption patterns and risk preferences.

### Key Economic Mechanisms

**Consumption Smoothing:** Agents prefer stable consumption over time, leading to saving during good times and borrowing during bad times.

**Investment Trade-offs:** Higher investment today means less consumption today but more consumption tomorrow through higher capital stock.

**Search Theory:** Unemployment exists because finding good job matches takes time, and agents optimally choose to be selective.

**Risk and Return:** Higher expected returns compensate for bearing risk, but the required compensation depends on how consumption varies with asset returns.

**Growth Sources:** Long-run growth requires either exogenous technological progress or mechanisms (like learning-by-doing) that prevent diminishing returns to capital.

**Market Completeness:** When markets are complete, competitive equilibria are Pareto efficient. When markets are incomplete, government intervention may improve welfare.

**Time Consistency:** Optimal plans made today may not be optimal to follow tomorrow, creating credibility problems for policymakers.

---

## Summary of Key Equations

### Dynamic Programming
- **Bellman Equation:** $v(x) = \max_{y \in \Gamma(x)} \{F(x,y) + \beta v(y)\}$
- **Contraction Property:** $d(Tf, Tg) \leq \beta d(f,g)$
- **Envelope Theorem:** $\frac{\partial v(x_0)}{\partial x_i} = \frac{\partial F(x_0, g(x_0))}{\partial x_i}$

### Growth Models  
- **Euler Equation:** $u'(c_t) = \beta u'(c_{t+1}) f'(k_{t+1})$
- **Transversality:** $\lim_{T\to\infty} \beta^T u'(c_T) k_{T+1} = 0$
- **AK Growth Rate:** $\frac{c_{t+1}}{c_t} = (\beta A)^{1/\sigma}$

### Search Theory
- **Reservation Wage:** $\frac{\bar{w}}{1-\beta} = b + \beta \int_0^{\infty} v(w') dF(w')$
- **Accept/Reject Rule:** Accept if $w \geq \bar{w}$, Reject if $w < \bar{w}$

### Asset Pricing
- **Stochastic Discount Factor:** $m_{t+1} = \beta \frac{u'(c_{t+1})}{u'(c_t)}$
- **Asset Pricing:** $p_t = E_t[m_{t+1} d_{t+1}]$
- **Equity Premium:** $E[R^s] - R^f = \gamma \text{Cov}(\Delta \log c_{t+1}, R^s_{t+1})$

### Welfare Economics
- **Pareto Efficiency:** $\frac{u'(c^1_t)}{u'(c^2_t)} = \frac{\alpha^1}{\alpha^2}$
- **Ricardian Equivalence:** Only present value of taxes matters
- **Ramsey Taxation:** Smooth tax rates over time

This comprehensive synthesis covers all major concepts from your ECON 8040 course, providing both mathematical rigor and economic intuition suitable for undergraduate understanding. The document serves as both a study guide and reference for understanding how dynamic economic theory applies to real-world policy and business decisions.
