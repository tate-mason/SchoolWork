# Econometrics: Detailed Proofs and Explanations

## 1. Binary Choice Models

### Relationship Between Response Probability and Conditional Expectation

**Proof:** For binary Y ∈ {0,1}, the conditional expectation can be written as:

$$E[Y|X=x] = \sum_{y \in \{0,1\}} y \cdot P(Y=y|X=x)$$

This expands to:
$$E[Y|X=x] = 0 \cdot P(Y=0|X=x) + 1 \cdot P(Y=1|X=x) = P(Y=1|X=x)$$

This shows that for binary outcomes, the conditional expectation equals the response probability.

### Maximum Likelihood Estimation for Probit

**Derivation of the log-likelihood function:**

For binary Y, the conditional PMF can be written as:
$$f(y|x) = P(Y=1|X=x)^y \cdot (1-P(Y=1|X=x))^{(1-y)}$$

Under the probit model, $P(Y=1|X=x) = \Phi(x'\beta)$, so:
$$f(y|x;\beta) = \Phi(x'\beta)^y \cdot (1-\Phi(x'\beta))^{(1-y)}$$

The log-likelihood function is:
$$l_n(\beta) = \sum_{i=1}^n \log(f(Y_i|X_i;\beta)) = \sum_{i=1}^n \{Y_i\log(\Phi(X_i'\beta)) + (1-Y_i)\log(1-\Phi(X_i'\beta))\}$$

**First-order condition (score):**
$$S_n(\beta) = \frac{\partial l_n(\beta)}{\partial \beta} = \sum_{i=1}^n \left(Y_i\frac{\phi(X_i'\beta)}{\Phi(X_i'\beta)}X_i - (1-Y_i)\frac{\phi(X_i'\beta)}{1-\Phi(X_i'\beta)}X_i\right)$$

This can be simplified to:
$$S_n(\beta) = \sum_{i=1}^n \frac{(Y_i-\Phi(X_i'\beta))\phi(X_i'\beta)}{\Phi(X_i'\beta)(1-\Phi(X_i'\beta))}X_i$$

### Asymptotic Distribution of M-Estimators

**Mean Value Theorem Approach:**

Starting with the first-order condition:
$$0 = \frac{1}{n}\sum_{i=1}^n \psi(Y_i, X_i, \hat{\theta})$$

Using the mean value theorem, where $\bar{\theta}$ is between $\hat{\theta}$ and $\theta$:
$$0 = \frac{1}{\sqrt{n}}\sum_{i=1}^n \psi(Y_i, X_i, \hat{\theta}) = \frac{1}{\sqrt{n}}\sum_{i=1}^n \psi(Y_i, X_i, \theta) \\ + \left(\frac{1}{n}\sum_{i=1}^n \frac{\partial\psi(Y_i, X_i, \bar{\theta})}{\partial\tilde{\theta}'}\right)\sqrt{n}(\hat{\theta} - \theta)$$

Rearranging:
$$\sqrt{n}(\hat{\theta} - \theta) = -\left(\frac{1}{n}\sum_{i=1}^n \frac{\partial\psi(Y_i, X_i, \bar{\theta})}{\partial\tilde{\theta}'}\right)^{-1}\frac{1}{\sqrt{n}}\sum_{i=1}^n \psi(Y_i, X_i, \theta)$$

By the Law of Large Numbers:
$$\frac{1}{n}\sum_{i=1}^n \frac{\partial\psi(Y_i, X_i, \bar{\theta})}{\partial\tilde{\theta}'} \stackrel{p}{\rightarrow} Q := E\left[\frac{\partial\psi(Y,X,\theta)}{\partial\tilde{\theta}'}\right]$$

By the Central Limit Theorem (since $E[\psi(Y,X,\theta)] = 0$):
$$\frac{1}{\sqrt{n}}\sum_{i=1}^n \psi(Y_i, X_i, \theta) \stackrel{d}{\rightarrow} N(0, \Omega)$$
where $\Omega := E[\psi(Y,X,\theta)\psi(Y,X,\theta)']$

Therefore:
$$\sqrt{n}(\hat{\theta} - \theta) \stackrel{d}{\rightarrow} N(0, V)$$
where $V = Q^{-1}\Omega Q^{-1}$

### Information Matrix Equality for Probit

For probit under correct specification:
$$Q = E\left[\frac{\phi(X'\beta)^2}{\Phi(X'\beta)(1-\Phi(X'\beta))}XX'\right]$$

$$\Omega = E\left[\frac{\phi(X'\beta)^2}{\Phi(X'\beta)(1-\Phi(X'\beta))}XX'\right]$$

The equality $Q = \Omega$ (information matrix equality) holds because:

1. The expected value of the score is zero: $E[\psi(Y,X,\theta)] = 0$
2. Using the Law of Iterated Expectations and that $E[Y|X] = \Phi(X'\beta)$
3. The variance of the score equals the expected Hessian

Thus, $V = \Omega^{-1}$, simplifying inference.

## 2. Alternative Approaches to Causal Inference

### ATT Identification Under Unconfoundedness

**Proof:**
$$ATT = E[Y(1) - Y(0)|D=1]$$

$$= E[Y(1)|D=1] - E[Y(0)|D=1]$$

We observe $E[Y(1)|D=1] = E[Y|D=1]$. The challenge is $E[Y(0)|D=1]$.

Using the Law of Iterated Expectations:
$$E[Y(0)|D=1] = E[E[Y(0)|X,D=1]|D=1]$$

By unconfoundedness $(Y(0),Y(1)) \perp \!\!\! \perp D|X$:
$$E[Y(0)|X,D=1] = E[Y(0)|X,D=0] = E[Y|X,D=0]$$

Therefore:
$$ATT = E[Y|D=1] - E[E[Y|X,D=0]|D=1]$$

### Decomposition of Regression Coefficient Under Treatment Effect Heterogeneity

**General decomposition:**

For the regression $Y = \alpha D + X'\beta_0 + e$, we can derive:
$$\alpha = \frac{E[(D-L(D|X))Y]}{E[(D-L(D|X))^2]}$$

where $L(D|X)$ is the linear projection of $D$ on $X$.

**Step-by-step derivation:**

1. Using Frisch-Waugh-Lovell theorem:
   $$\alpha = \frac{E[(D-L(D|X))Y]}{E[(D-L(D|X))^2]}$$

2. For the numerator:
   $$E[(D-L(D|X))Y] = E[(1-L(D|X))Y|D=1]p - E[L(D|X)Y|D=0](1-p)$$

3. Using properties of linear projections:
   $$E[(1-L(D|X))Y|D=1]p = E[(1-L(D|X))L_1(Y|X)|D=1]p$$
   $$E[L(D|X)Y|D=0](1-p) = E[L(D|X)L_0(Y|X)|D=0](1-p)$$

4. By law of iterated expectations and some algebra:
   $$E[(D-L(D|X))Y] = E[D(1-L(D|X))(L_1(Y|X) - L_0(Y|X))]$$

5. The denominator equals $E[D(1-L(D|X))]$, so:
   $$\alpha = E\left[\frac{D(1-L(D|X))}{E[(D-L(D|X))^2]}(L_1(Y|X) - L_0(Y|X))\right]$$

6. Defining weights $w(D,X) = \frac{D(1-L(D|X))}{E[(D-L(D|X))^2]}$, we get:
   $$\alpha = E[w(D,X)(L_1(Y|X) - L_0(Y|X))]$$

7. Further decomposition shows:
   $$\alpha = E[w(D,X)(E[Y|X,D=1] - E[Y|X,D=0])] + E[w(D,X)(E[Y|X,D=0] - L_0(Y|X))]$$

8. Under unconfoundedness, $E[Y|X,D=1] - E[Y|X,D=0] = CATE(X)$, and either condition:
   - $p(X) = L(D|X)$ (linear propensity score) or
   - $E[Y|X,D=0] = L_0(Y|X)$ (linear outcome model)
   
   Makes $\alpha = E[w(D,X)CATE(X)]$

### Doubly Robust Estimator Proof

**Proof of double robustness property:**

We want to show that the estimator:
$$ATT = E\left[\left(\frac{D}{p} - \frac{(1-D)p(X)}{p(1-p(X))}\right)(Y - E[Y|X,D=0])\right]$$

Converges to the true ATT if either the propensity score model or the outcome regression model is correctly specified.

Let $p(X;\theta^*)$ be the working propensity score model with pseudo-true parameter $\theta^*$, and $m(X,\beta^*)$ be the working outcome regression model with pseudo-true parameter $\beta^*$.

The pseudo-ATT is:
$$ATT^* = E\left[\frac{D}{p}(Y - m(X;\beta^*))\right] - E\left[\frac{(1-D)p(X;\theta^*)}{p(1-p(X;\theta^*))}(Y - m(X;\beta^*))\right]$$

**Case 1: Outcome Regression Model Correctly Specified**

If $m(X;\beta^*) = E[Y|X,D=0]$, then:
$$E\left[\frac{(1-D)p(X;\theta^*)}{p(1-p(X;\theta^*))}(Y - m(X;\beta^*))\right] = E\left[\frac{(1-D)p(X;\theta^*)}{p(1-p(X;\theta^*))}E[(Y - m(X;\beta^*))|X,D=0]\right] = 0$$

Therefore, $ATT^* = E[\frac{D}{p}(Y - m(X;\beta^*))] = E[Y|D=1] - E[m(X;\beta^*)|D=1] = ATT$

**Case 2: Propensity Score Model Correctly Specified**

If $p(X;\theta^*) = p(X)$, then using the reweighting property and law of iterated expectations:
$$E\left[\frac{(1-D)p(X)}{p(1-p(X))}(Y - m(X;\beta^*))\right] = E[E[Y|X,D=0] - m(X;\beta^*)|D=1]$$

Therefore:
$$ATT^* = E[Y|D=1] - E[E[Y|X,D=0]|D=1] = ATT$$

## 3. Panel Data Methods

### Derivation of the Parallel Trends Assumption

**From unconfoundedness with time-invariant unobservables:**

Start with model for untreated potential outcomes:
$$Y_{it}(\infty) = \theta_t + W_i'\beta + e_{it}$$

The first difference removes the time-invariant term:
$$\Delta Y_{i2}(\infty) = Y_{i2}(\infty) - Y_{i1}(\infty) = (\theta_2 - \theta_1) + (e_{i2} - e_{i1}) = \Delta\theta_2 + \Delta e_{i2}$$

Under unconfoundedness, $E[e_{it}|W,G] = 0$ for all t, which implies $E[\Delta e_{i2}|G] = 0$.

Therefore:
$$E[\Delta Y_{i2}(\infty)|G=g] = \Delta\theta_2$$

This is the same for all groups g, giving us the parallel trends assumption:
$$E[\Delta Y_t(\infty)|G=g] = E[\Delta Y_t(\infty)]$$

### Identification of Group-Time Average Treatment Effects

For $t \geq g$ (post-treatment periods for group g):

$$ATT(g,t) = E[Y_t(g) - Y_t(\infty)|G=g]$$

$$= E[Y_t(g) - Y_{g-1}(\infty)|G=g] - E[Y_t(\infty) - Y_{g-1}(\infty)|G=g]$$

By no anticipation, $Y_{g-1} = Y_{g-1}(\infty)$ for group g.

By parallel trends:
$$E[Y_t(\infty) - Y_{g-1}(\infty)|G=g] = E[Y_t(\infty) - Y_{g-1}(\infty)|U=1]$$

Therefore:
$$ATT(g,t) = E[Y_t - Y_{g-1}|G=g] - E[Y_t - Y_{g-1}|U=1]$$

### Aggregation of Group-Time Average Treatment Effects

**Overall ATT:**

Define $TE_i = \frac{1}{T-G_i+1}\sum_{t=G_i}^T (Y_{it} - Y_{it}(\infty))$ for each treated unit.

Then:
$$ATT^o = E[TE|U=0] = \sum_{g \in \mathcal{G}\setminus\{\infty\}} E[TE|G=g]\bar{p}_g$$

$$= \sum_{g \in \mathcal{G}\setminus\{\infty\}} \frac{1}{T-g+1}\sum_{t=g}^T E[Y_t - Y_t(\infty)|G=g]\bar{p}_g$$

$$= \sum_{g \in \mathcal{G}\setminus\{\infty\}} \sum_{t=g}^T \frac{\bar{p}_g}{T-g+1}ATT(g,t)$$

Where $\bar{p}_g = P(G=g|U=0)$ and weights $w^o(g,t) = \frac{\bar{p}_g}{T-g+1}$.

**Event Study Parameters:**

$$ATT^{es}(e) = E[TE(e)|G+e \in [2,T], U=0]$$

$$= \sum_{g \in \mathcal{G}\setminus\{\infty\}} 1\{g+e \in [2,T]\}P(G=g|G+e \in [2,T], U=0)ATT(g,g+e)$$

### Decomposition of Two-Way Fixed Effects Estimator

For the TWFE model $Y_{it} = \theta_t + \eta_i + \alpha D_{it} + e_{it}$:

1. Define doubly-demeaned variables:
   $$\ddot{Y}_{it} = Y_{it} - \bar{Y}_i - E[Y_t] + \frac{1}{T}\sum_{t=1}^T E[Y_t]$$
   $$\ddot{D}_{it} = D_{it} - \bar{D}_i - E[D_t] + \frac{1}{T}\sum_{t=1}^T E[D_t]$$

2. The coefficient equals:
   $$\alpha = \frac{\frac{1}{T}\sum_{t=1}^T E[\ddot{D}_{it}Y_{it}]}{\frac{1}{T}\sum_{t=1}^T E[\ddot{D}_{it}^2]}$$

3. With some algebra and using properties of double-demeaned variables:
   $$\alpha = \sum_{g \in \mathcal{G}\setminus\{\infty\}} \sum_{t=g}^T w^{TWFE}(g,t)ATT(g,t)$$

4. Where weights:
   $$w^{TWFE}(g,t) = \frac{h(g,t)p_g}{\sum_{g \in \mathcal{G}\setminus\{\infty\}} \sum_{t=g}^T h(g,t)p_g}$$

5. And $h(g,t)$ is a function determined by the group and time period. Some weights can be negative, causing potential misrepresentation of treatment effects.

## 4. Generalized Method of Moments (GMM)

### GMM Estimator Derivation

For overidentified linear model with moment conditions $E[Z(Y-X'\beta)] = 0$:

The GMM estimator minimizes:
$$(Z'Y - Z'X\beta)'\hat{W}(Z'Y - Z'X\beta)$$

First-order condition:
$$-X'Z\hat{W}Z'Y + X'Z\hat{W}Z'X\hat{\beta}_{GMM} = 0$$

Therefore:
$$\hat{\beta}_{GMM} = (X'Z\hat{W}Z'X)^{-1}X'Z\hat{W}Z'Y$$

### Asymptotic Distribution of GMM

Under standard regularity conditions:
$$\sqrt{n}(\hat{\beta}_{GMM} - \beta) = \left(\frac{1}{n}\sum_{i=1}^n X_i'Z_i\hat{W}Z_i'X_i\right)^{-1}\frac{1}{\sqrt{n}}\sum_{i=1}^n X_i'Z_i\hat{W}Z_i'e_i$$

As $n \rightarrow \infty$:
$$\frac{1}{n}\sum_{i=1}^n X_i'Z_i\hat{W}Z_i'X_i \stackrel{p}{\rightarrow} E[X'Z]WE[Z'X]$$

$$\frac{1}{\sqrt{n}}\sum_{i=1}^n X_i'Z_i\hat{W}Z_i'e_i \stackrel{d}{\rightarrow} N(0, E[X'Z]W\Omega WE[Z'X])$$

Therefore:
$$\sqrt{n}(\hat{\beta}_{GMM} - \beta) \stackrel{d}{\rightarrow} N(0, V)$$

Where:
$$V = (E[X'Z]WE[Z'X])^{-1}E[X'Z]W\Omega WE[Z'X](E[X'Z]WE[Z'X])^{-1}$$

### Efficient GMM

Setting $W = \Omega^{-1}$ minimizes the asymptotic variance:
$$\hat{\beta}^o_{GMM} = (X'Z\hat{\Omega}^{-1}Z'X)^{-1}X'Z\hat{\Omega}^{-1}Z'Y$$

With simplified asymptotic variance:
$$V_0 = (E[X'Z]\Omega^{-1}E[Z'X])^{-1}$$

### Overidentification Test

The J-statistic:
$$J(\hat{\beta}) = n\left(\frac{1}{n}Z'Y - \frac{1}{n}Z'X\hat{\beta}\right)'\hat{\Omega}^{-1}\left(\frac{1}{n}Z'Y - \frac{1}{n}Z'X\hat{\beta}\right)$$

Can be rewritten as:
$$J(\hat{\beta}) = n\left[\hat{\Omega}^{-1/2}\left(\frac{1}{n}Z'Y - \frac{1}{n}Z'X\hat{\beta}\right)\right]'\hat{\Omega}^{-1/2}\left(\frac{1}{n}Z'Y - \frac{1}{n}Z'X\hat{\beta}\right)$$

Under $H_0: E[Ze] = 0$:
$$\hat{\Omega}^{-1/2}\left(\frac{1}{n}Z'Y - \frac{1}{n}Z'X\hat{\beta}\right) = (I - R(R'R)^{-1}R')\hat{\Omega}^{-1/2}\frac{1}{n}Z'e + o_p(1)$$

Where $R = \Omega^{-1/2}E[ZX']$

Therefore:
$$J(\hat{\beta}) \stackrel{d}{\rightarrow} u'(I - R(R'R)^{-1}R')u \sim \chi^2_{l-k}$$

Where $u \sim N(0, I_l)$ and $(I - R(R'R)^{-1}R')$ is an idempotent matrix with trace $l-k$.

### GMM for Panel Data Difference-in-Differences

For group-time average treatment effects with moment conditions:
$$E\left[\left(\frac{1\{G=2\}}{p_2} - \frac{U}{p_U}\right)\Delta Y_2\right] - ATT(2,2) = 0$$
$$E\left[\left(\frac{1\{G=3\}}{p_3} - \frac{U}{p_U}\right)\Delta Y_2\right] = 0$$

The GMM estimator is:
$$\hat{\alpha} = (R'\hat{W}R)^{-1}R'\hat{W}\frac{1}{n}Y'1$$

With efficient weighting $\hat{W} = \hat{\Omega}^{-1}$:
$$\hat{\alpha}^o_{gmm} = (R'\hat{\Omega}^{-1}R)^{-1}R'\hat{\Omega}^{-1}\frac{1}{n}Y'1$$

Asymptotic distribution:
$$\sqrt{n}(\hat{\alpha} - \alpha) \stackrel{d}{\rightarrow} N(0, V)$$

Where $V = (R'WR)^{-1}R'W\Omega WR(R'WR)^{-1}$, and for efficient GMM: $V_0 = (R'\Omega^{-1}R)^{-1}$
