# Econometrics Study Guide

## 1. Binary Choice Models

### Key Concepts
- **Binary Outcome Models**: Used when the dependent variable Y ∈ {0,1}
- **Key Parameters of Interest**:
  - Response probability: P(x) = P(Y=1|X=x)
  - Partial/marginal effects: ∂P(x)/∂x₁
  - Average partial effect: E[∂P(x)/∂x₁]
- **Important Relationship**: For binary Y, E[Y|X=x] = P(Y=1|X=x)

### Model Types
1. **Linear Probability Model (LPM)**
   - Model: P(x) = x'β
   - Advantages: Simple, partial effects constant (β₁)
   - Disadvantages: Can predict probabilities outside [0,1], constant partial effects often unrealistic

2. **Single-Index Models**
   - Model: P(x) = G(x'β) where G is a link function (CDF)
   - Partial effect: ∂P(x)/∂x₁ = g(x'β)β₁ where g is derivative of G
   - Common types:
     - **Probit**: P(x) = Φ(x'β) where Φ is standard normal CDF
     - **Logit**: P(x) = Λ(x'β) where Λ(u) = exp(u)/(1+exp(u))

### Maximum Likelihood Estimation
- **Likelihood Function**: L(θ) = ∏ᵢf(Yᵢ|Xᵢ;θ)
- **Log-likelihood**: l(θ) = ∑ᵢlog(f(Yᵢ|Xᵢ;θ))
- **For Probit Model**:
  - l(b) = ∑ᵢYᵢlog(Φ(X'ᵢb)) + (1-Yᵢ)log(1-Φ(X'ᵢb))
  - No explicit solution; use numerical optimization

### M-Estimators
- **Definition**: Estimators that come from minimizing a function M(θ)
- **First Order Condition**: ∑ᵢψ(Yᵢ,Xᵢ,θ̂) = 0 where ψ is derivative of the objective function
- **Asymptotic Distribution**: √n(θ̂-θ) → N(0,V) where V = Q⁻¹ΩQ⁻¹
  - Q = E[∂ψ/∂θ']
  - Ω = E[ψψ']
- **For Probit**: Q = Ω (information matrix equality)
- **Inference**: Estimate V̂ = Ω̂⁻¹ to construct standard errors, t-statistics, etc.

## 2. Alternative Approaches to Causal Inference

### Unconfoundedness Framework
- **Assumption**: (Y(1),Y(0)) ⊥⊥ D|X
- **ATT Identification**: E[Y(1)-Y(0)|D=1] = E[Y|D=1] - E[E[Y|X,D=0]|D=1]
- **ATE Identification**: E[E[Y|X,D=1] - E[Y|X,D=0]]

### Covariate Balance
- If D ⊥⊥ X (covariates balanced across treatment groups):
  - ATT = E[Y|D=1] - E[Y|D=0]
- Checking balance: Compare means/variances of covariates across groups

### Proxy Variables
- If complete unconfoundedness requires unobserved variables W:
  (Y(1),Y(0)) ⊥⊥ D|(X,W)
- Using proxies R such that:
  - D ⊥⊥ (X,W)|R 
  - (Y(1),Y(0)) ⊥⊥ R|(X,W)
- ATT can be identified using proxies

### Treatment Effect Heterogeneity in Regression
- Standard regression model: Y = αD + X'β₀ + e
- Under heterogeneity: α = E[w(D,X)(CATE(X))]
  - w(D,X) = D(1-L(D|X))/E[(D-L(D|X))²]
  - CATE(X) = E[Y(1)-Y(0)|X]
- Weights sum to 1 but can be negative
- α represents ATT only under special conditions:
  - If p(X) = L(D|X) (propensity score is linear) OR
  - If E[Y|X,D=0] = L₀(Y|X) (outcome model is linear)

### Alternative Estimation Approaches
1. **Regression Adjustment**
   - ATT = E[Y|D=1] - E[X'|D=1]β₀
   - Where β₀ estimated from regression of Y on X for untreated

2. **Propensity Score Weighting**
   - No assumptions about outcome model needed
   - ATT = E[(D/p - ((1-D)p(X))/(p(1-p(X))))Y]
   - Weights balance covariate distribution

3. **Doubly Robust Methods**
   - Consistent if EITHER propensity score OR outcome model correctly specified
   - ATT = E[(D/p - ((1-D)p(X))/(p(1-p(X))))(Y-E[Y|X,D=0])]

4. **Machine Learning with Doubly Robust Methods**
   - Cross-fitting approach:
     - Split data into K folds
     - For each fold, estimate p(X) and E[Y|X,D=0] using other K-1 folds
     - Compute estimates using that fold's data
     - Average across folds

## 3. Panel Data Methods

### Framework and Notation
- **Data Structure**: {Yᵢₜ, Dᵢₜ}ⁿᵢ₌₁ for t = 1,...,T
- **Potential Outcomes**: Yᵢₜ(d) - outcome if treatment path = d
- **Staggered Treatment Adoption**: Once treated, always treated
- **Group Definition**: Gᵢ = time period when unit i first treated
- **No Anticipation**: Yᵢₜ = Yᵢₜ(∞) for t < Gᵢ

### Parallel Trends Assumption
- For all t and groups g: E[ΔYₜ(∞)|G=g] = E[ΔYₜ(∞)]
- Motivated by model: Yᵢₜ(∞) = θₜ + ηᵢ + eᵢₜ where ηᵢ = W'ᵢβ

### Difference-in-Differences (DID)
- **Target Parameter**: ATT(g,t) = E[Yₜ(g) - Yₜ(∞)|G=g]
- **Identification**:
  - ATT(g,t) = E[Yₜ-Yg₋₁|G=g] - E[Yₜ-Yg₋₁|U=1]
  - Compare path of outcomes for treated group vs never-treated

### Aggregate Parameters
1. **Overall ATT**:
   - ATT^o = E[TE|U=0] where TE = average effect across post-treatment periods
   - Weighted average: ATT^o = ∑ₘ∑ₜ w^o(g,t)ATT(g,t)

2. **Event Study Parameters**:
   - ATT^es(e) = E[TE(e)|G+e∈[2,T], U=0]
   - Average effect e periods after treatment
   - Pre-testing: Check if ATT^es(e) = 0 for e < 0

### Two-Way Fixed Effects (TWFE) Regression
- Model: Yᵢₜ = θₜ + ηᵢ + αDᵢₜ + eᵢₜ
- **Two periods case**: 
  - Equivalent to regression ΔYᵢ₂ = Δθ₂ + αDᵢ₂ + Δeᵢ₂
  - Robust to treatment effect heterogeneity

- **Multiple periods case**: 
  - α = ∑ₘ∑ₜ w^TWFE(g,t)ATT(g,t)
  - Weights can be negative → may misrepresent treatment effects

### Estimation with Covariates
- Conditional parallel trends: E[ΔYₜ(∞)|X,G=g] = E[ΔYₜ(∞)|X]
- ATT(g,t) = E[Yₜ-Yg₋₁|G=g] - E[E[Yₜ-Yg₋₁|X,U=1]|G=g]
- Can use regression adjustment, propensity score weighting, doubly robust methods

## 4. Generalized Method of Moments (GMM)

### Moment Conditions
- **Framework**: E[g(X,Y;θ)] = 0
- **Overidentification**: More moment conditions (l) than parameters (k)

### Instrumental Variables Example
- **Model**: Y = X'β + e with E[Xe] ≠ 0 (endogeneity)
- **Instrument Z**: E[Ze] = 0
- **Identification**: β = E[ZX']⁻¹E[ZY] if rank(E[ZX']) = k

### GMM Estimation
- **Objective**: Choose β̂ to minimize (Z'Y-Z'Xb)'Ŵ(Z'Y-Z'Xb)
- **GMM Estimator**: β̂ = (X'ZŴZ'X)⁻¹X'ZŴZ'Y
- **Efficient GMM**: Use Ŵ = Ω̂⁻¹ where Ω = var(Ze)
- **Two-step procedure**:
  1. Get initial consistent estimator (e.g., using Ŵ = (Z'Z)⁻¹)
  2. Estimate Ω̂ using residuals
  3. Compute efficient GMM estimator

### Overidentification Tests
- **Null Hypothesis**: H₀: E[Ze] = 0
- **J-statistic**: J(β̂) = n(Z'Y/n-Z'Xβ̂/n)'Ω̂⁻¹(Z'Y/n-Z'Xβ̂/n)
- **Distribution**: Under H₀, J(β̂) → χ²ₗ₋ₖ

### Panel Data Application
- **Moment Conditions**:
  - E[((1{G=g}/pₖ-U/pᵤ)ΔYₜ] - ATT(g,t) = 0
  - E[((1{G=h}/pₕ-U/pᵤ)ΔYₜ] = 0
- **GMM Estimator**: ATT(g,t) = (R'ŴR)⁻¹R'Ŵ(Y'1/n)
- **Efficient GMM**: Combines information optimally across all comparison groups

## Common Themes Across Methods

1. **Identification vs. Estimation**:
   - Identify causal parameters using assumptions
   - Choose estimation method based on model properties

2. **Treatment Effect Heterogeneity**:
   - Simple methods often assume homogeneous effects
   - More complex methods allow for heterogeneity

3. **Trade-offs in Assumptions**:
   - Functional form vs. identification
   - Efficiency vs. robustness

4. **Balancing Covariates**:
   - Regression adjustment, weighting, matching, etc.
   - Goal: Make treated and untreated groups comparable

5. **Inference**:
   - Asymptotic normality: √n(θ̂-θ) → N(0,V)
   - Estimating variance matrix V for hypothesis tests and confidence intervals