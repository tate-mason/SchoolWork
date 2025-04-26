# Econometrics Final Review

## Key Econometrics Concepts

### Consisteny of Error Variance Estimators

$\hat{e}_i = Y_i - x_i^T\hat{\beta} = x_i^T\beta + e_i - x_i^T\hat{\beta} = e_i - x_i^T(\hat{\beta}-\beta)$

$\Rightarrow \hat{e}_i^2 = e_i^2 -2e_ix_i^T(\hat{\beta}-\beta) + (\hat{\beta}-\beta)^Tx_ix_i^T(\hat{\beta}-\beta)$

$\Rightarrow \frac{1}{n}\sum\hat{e}_i^2=\frac{1}{n}\sum e_i^2-2(\frac{1}{n}\sum e_ix_i^T)(\hat{\beta}-\beta)+(\hat{\beta}-\beta)(\frac{1}{n}\sum x_ix_i^T)(\hat{\beta}-\beta)$

* First term, $\frac{1}{n}\sum e_i^2$ converges in probability to $\sigma^2$. 
* The second term $-2(\frac{1}{n}\sum e_ix_i^T)$ converges in probability to zero.  
* The final term converges in probability to $\mathbb{E}[x_ix_i^T]$. So, we can say that $\hat{\sigma}^2 {p\atop\rightarrow} \sigma^2$

### Projection Error

$e=Y-x^T\beta$

$\mathbb{E}[xe] = \mathbb{E}[x(Y-x^T\beta)]$

$= \mathbb{E}[xY]-\mathbb{E}[xx^T]\beta$ 

$= \mathbb{E}[xY] - \mathbb{E}[xx^T]\mathbb{E}[xx^T]^{-1}\mathbb{E}[xY]$

$= \mathbb{E}[xY] - \mathbb{E}[xY] = 0$

Basically, understand definitions of derivations of different things.

### Variance of the CEF Error

$\sigma^2 = var(e) = \mathbb{E}[(e-\mathbb{E}[e])^2] = \mathbb{E}[e^2]$

$\sigma^2$ measures amount of variation in $Y$ that isn't accounted for by $\mathbb{E}[Y|X]$.

### Jenson's Inequality

$g(\mathbb{E}[x]) \leq \mathbb{E}[g(x)]$

### Regression derivations

How much $Y$ changes, on average, when $x_i$ increases by one unit, holding the other regressors $x_{-i}$ constant.

### Partial Effects

* Hold other regressors constant, but do not hold variables unrelated to the regression constant.

* $\nabla_1 m(x)$ is a function of $x$

* Partial effects are about average changes rather than individual level effects

### Homoskedasticity Assumption

$\mathbb{E}[e^2|X] = \sigma^2$

$\Rightarrow\Omega = \mathbb{E}[xx^T\mathbb{E}[e^2|X]] = \sigma^2\mathbb{E}[xx^T]$

$\Rightarrow V_0 = \sigma^2\mathbb{E}[xx^T]^{-1}$

### Least Squares Estimator

$\hat{\beta}=(\frac{1}{n}\sum^nx_ix_i^T)^{-1}(\frac{1}{n}\sum^nx_iY_i)$

* Consistent under Weak Law of Large Numbers and Central Limit Theorem

$\sqrt{n}(\hat{\beta}-\beta) \rightarrow N(0,\underline{V}_{\beta})$

$\underline{V}_{\beta}=\mathbb{E}[xx^t]^{-1}\mathbb{E}[xx^Te^2]\mathbb{E}[xx^T]^{-1}$

### T-Statistic

$t = \frac{(\hat{\theta}-\theta)}{s.e.(\hat{\theta})} = \frac{\sqrt{n}(\hat{\theta}-\theta_0)}{\sqrt{\sigma^2}}$

* Case 1: $H_0$ is true:
$t=\frac{\sqrt{n}(\hat{\theta}-\theta_0)}{\sqrt{\sigma^2}}+op(1)$
* Case 2: $H_1$ is true:
$\hat{\theta}-\theta_0{p\atop\rightarrow}\theta-\theta_0\ne0$
  * t converges

### Conditional Expectation

$\mathbb{E}[Y|X] = m(x)$

### CEF Error

$e: Y-m(x)$
* $\mathbb{E}[e|x] = 0$
* $\mathbb{E}[e] = 0
  * using conditioning theorem

### Saturated Model

* Include all terms and all possible interactions between them

### Best Predictor

* $m(x)$ minimizes the mean squared prediction error.

$MSPE = \mathbb{E}[(y-g(x))^2]$

* For $m(x)$, MSPE is $\sigma^2 = var(e)$

### Best Linear Predictor

* Linear CEF: $\mathbb{E}[Y|X] = x^T\beta$
  * such that $\beta$ is a k by 1 vector
* $x^T\beta$ is the best linear projection

* $\beta = \mathbb{E}[xx^T]^{-1}\mathbb{E}[xY]$ is the linear projection coefficient

### Best Linear Approximation

$\hat{\beta}=(\frac{1}{n}\sum^nx_ix_i^T)^{-1}\frac{1}{n}\sum^nx_iy_i$
* This is Consistent

### Standard Error $(\hat{\theta})$
$=\frac{\sqrt{\sigma^2}}{\sqrt{n}}$

### Confidence Interval

$\hat{C}=\sqrt{\hat{\theta}\pm 1.96*s.e.(\theta)}$

### Central Limit Theorem

* $\sqrt{n}(\bar{x}-\mathbb{E}[x]){d\atop\rightarrow}N(0,\sigma^2)$ s.t. $\sigma^2 = var(x)$

### Consistency and Distribuion

* Consistency using WLLN and CMT to show convergence in probability
* Distribution uses CLT and Delta Method to show convergence in Distribution

### WLLN
* $\bar{x}{p\atop\rightarrow}\mathbb{E}[x]$ implies that $\bar{x}$ is consistent for $\mathbb{E}[x]$

### Lypunou's Theorem

* $\mathbb{E}[|x|^r]^{\frac{1}{r}}\leq\mathbb{E}[|x|^p]^{\frac{1}{p}}$
- Let $g(x) = x^{\frac{p}{r}}$ and $Y=|x|^r$ $\Rightarrow g(\mathbb{E}[Y])\leq\mathbb{E}[g(Y)]$

Plug into Jensen's, $\mathbb{E}[|x|^r]^{\frac{p}{r}}\leq\mathbb{E}[(|x|^r)^{\frac{p}{r}}]$

$\mathbb{E}[|x|^r]^{\frac{p}{r}}\leq\mathbb{E}[|x|^p]$

$\mathbb{E}[|x|^r]^{\frac{1}{r}}\leq\mathbb{E}[|x|^p]^{\frac{1}{p}}$

* States that if higher moments exist, then lower order do as well

### Markov's Inequality

$\mathbb{E}[x] = \int\limits_{-\infty}^{\infty}xfx(x)dx$

$=\int\limits_a^{\infty}xfx(x)dx + \int\limits_0^axfx(x)dx\geq a\int\limits_a^{\infty}fx(x)dx) = a(1-fx(a))=aP(x\geq a)$

$\Rightarrow\frac{\mathbb{E}[x]}{a}\geq P(x\geq a)$

* States that distributions are bound

### Chebyshev's Inequality


