# WNBA_proj.R — Code Explainer

**Research question:** Does the arrival of a WNBA franchise in a state increase girls' high-school sports participation?

**Data:** `master_scraped.csv` — 51 states × 26 academic years (1993–94 through 2018–19), scraped from NFHS participation surveys. Four outcomes: basketball, cross country, soccer, track & field.

**Identification strategy:** Staggered difference-in-differences. WNBA franchises entered different states in different years (1997–2010), creating variation in treatment timing that can be exploited as a natural experiment.

---

## Section 1 — Load & Clean

### What the code does

Reads the wide-format CSV, maps academic-year strings (`"1997-98"`) to the starting calendar year (1997), then surgically sets specific state-year cells to `NA`.

### Why the fixes matter

The raw NFHS data contains transcription errors — single-year spikes that are 3–4× the surrounding values with no plausible substantive explanation. Leaving these in would corrupt pre-trends, inflate variance, and bias the DiD. Each fix is documented with a reason:

| State | Sport | Year | Raw value | Neighbors | Diagnosis |
|-------|-------|------|-----------|-----------|-----------|
| Indiana | Basketball | 1998 | 42,510 | ~12,000 | Extra digit |
| California | Cross Country | 1998 | 44,245 | ~14,000 | Extra digit |
| Massachusetts | Soccer | 2003 | 42,193 | ~12,000 | Extra digit |
| Pennsylvania | Cross Country | 2008+ | ~11,320 | ~5,500 | Methodology change |

Pennsylvania's cross country series gets dropped from all years ≥ 2008 rather than just one year, because the level shift is *permanent* — PA began counting indoor cross country separately, permanently doubling its count. Since PA is a never-treated control state, keeping the post-2008 observations would inflate the control mean and bias all ATT estimates downward.

---

## Section 2 — Treatment Assignment

### What the code does

Joins each state to its `first_treat` year (the year its first WNBA franchise began play). Never-treated states get `first_treat = 0`. Creates a binary treatment indicator:

```r
has_wnba = as.integer(first_treat > 0 & year >= first_treat)
```

### Economic intuition

The treatment is **entry of a professional women's sports franchise**. The hypothesized mechanism is a *role model effect* (Beaman et al. 2012; Lowe 2021): visible female professional athletes raise the perceived returns to girls' sports participation — in terms of social status, career aspiration, or simply perceived possibility — causing more girls to join school teams.

The relevant variation is cross-state and cross-time: some states got a WNBA team in 1997, others in 2000, and some never did. This staggered rollout is the source of causal identification.

**Key assumption (parallel trends):** In the absence of WNBA entry, the trend in girls' participation in treated states would have evolved the same as in never-treated states. This is untestable in the post-period but can be probed pre-treatment (event study pre-trends test).

---

## Section 3 — Data Facts

Descriptive checks: missing values after fixes, summary statistics, mean participation by treated/never-treated group, and cohort sizes. These serve two purposes:

1. **Transparency** — confirm the balanced panel filter is working correctly.
2. **Pre-analysis sanity check** — if treated states already look very different from controls in the pre-period *levels*, that is not itself a problem for DiD (only the *trends* need to be parallel), but large level differences can inflate standard errors.

---

## Section 4 — Map

Choropleth of the 48 contiguous states, coloured by treatment cohort year. Grey states are never-treated controls. This is a standard descriptive figure showing the geographic distribution of treatment.

---

## Section 5 — Raw Trend Plots

### What the code does

For each sport, plots the year-by-year mean participation separately for ever-treated and never-treated states. Only states with complete data in every year enter the plot (balanced panel rule), preventing composition artifacts.

A vertical dotted line at 2011.5 flags the 2012 NFHS reporting methodology change that affected all states and all sports simultaneously — a nationwide shock absorbed by the time fixed effects in the regression, but visible in raw trends.

### What to look for

Visually inspect whether the two groups trend together before 1997 (the first treatment cohort). If the lines diverge pre-1997, parallel trends is harder to defend. If they diverge *after* 1997 and specifically in years when states received franchises, that is prima facie evidence of a treatment effect.

---

## Section 6 — Callaway-Sant'Anna (2021) DiD

### The problem with standard DiD in a staggered setting

The canonical two-period DiD estimand is:

$$\text{ATT} = \underbrace{(\bar{Y}_{treated,post} - \bar{Y}_{treated,pre})}_{\text{change in treated}} - \underbrace{(\bar{Y}_{control,post} - \bar{Y}_{control,pre})}_{\text{change in control}}$$

With only two periods and one cohort, this is clean. With **staggered adoption** (multiple cohorts entering at different times), the standard TWFE estimator implicitly runs many 2×2 DiDs — including comparisons that use *already-treated* states as controls for *later-treated* states. This introduces bias because:

- Already-treated controls may themselves be experiencing dynamic treatment effects.
- The implicit weights on each (cohort, time) cell can be **negative**, meaning the estimator could produce a negative overall ATT even if every cohort-specific effect is positive.

Callaway and Sant'Anna (2021) solve this by estimating **group-time ATTs** separately for each (cohort $g$, time $t$) pair, then aggregating.

### The C-S estimand

Define a **cohort** $g$ as the set of states first treated in year $g$. The group-time ATT is:

$$ATT(g,t) = E[Y_{it}(g) - Y_{it}(\infty) \mid G_i = g]$$

where $Y_{it}(g)$ is the potential outcome for a unit first treated in year $g$, and $Y_{it}(\infty)$ is the never-treated potential outcome.

Under the **conditional parallel trends assumption** (using never-treated controls):

$$E[Y_{it}(\infty) - Y_{i,g-1}(\infty) \mid G_i = g] = E[Y_{it}(\infty) - Y_{i,g-1}(\infty) \mid G_i = \infty]$$

"The trend in untreated potential outcomes for cohort $g$ would have been the same as the trend for never-treated units."

The regression estimator (`est_method = "reg"`) for $ATT(g,t)$ is:

$$\hat{ATT}(g,t) = E\left[\left(Y_{it} - Y_{i,g-1}\right) \cdot \mathbf{1}(G_i = g)\right] - E\left[\left(Y_{it} - Y_{i,g-1}\right) \cdot \mathbf{1}(G_i = \infty)\right]$$

This is a clean 2×2 DiD for each (cohort, time) cell, always comparing to the *same* pre-period ($t = g-1$) and always using *never-treated* states as the comparison group.

### Aggregation

After computing all $ATT(g,t)$ estimates, the code aggregates three ways:

1. **Simple overall ATT** — average across all (cohort, time) cells weighted by cohort size and number of post-treatment periods. This is the headline number.

2. **ATT by cohort** (`type = "group"`) — average $ATT(g,t)$ over $t \geq g$ for each cohort $g$. Useful for checking heterogeneous treatment effects: did early-entry states (1997) benefit more or less than later-entry states (2008)?

3. **Dynamic ATT / event study** (`type = "dynamic"`) — average $ATT(g,t)$ over cohorts at each event-time $e = t - g$. This produces the standard event study plot showing the treatment effect trajectory.

$$ATT(e) = \sum_g w(g,e) \cdot ATT(g, g+e)$$

where weights $w(g,e)$ are proportional to cohort size.

### Normalization to $t = -1$

The event study coefficients are normalized by subtracting the $t = -1$ value:

$$\widetilde{ATT}(e) = \hat{ATT}(e) - \hat{ATT}(-1)$$

This forces the period immediately before treatment to be exactly zero, making the plot easier to read. Pre-treatment coefficients that are close to zero and statistically insignificant (the "flat pre-trends") are evidence in favor of the parallel trends assumption.

### Inference

Standard errors are clustered at the state level (`clustervars = "state_id"`), accounting for serial correlation within states over time. Confidence bands on the event study plot are **simultaneous (uniform)** critical values (`crit.val.egt`), which are wider than pointwise bands and correctly control the probability that *any* pre- or post-period point is spuriously significant.

### Code walkthrough

```r
cs <- att_gt(
  yname         = yname,        # outcome column
  tname         = "year",       # time variable
  idname        = "state_id",   # unit identifier
  gname         = "first_treat",# cohort variable (0 = never treated)
  data          = df_sp,
  control_group = "nevertreated", # only pure controls; never uses already-treated
  est_method    = "reg",        # outcome regression (vs. "ipw" or "dr")
  panel         = TRUE,
  clustervars   = "state_id"
)
```

The balanced panel filter (`n_distinct(year) == n_all_years`) runs inside `run_cs()` so that each sport gets its own set of states with complete data, rather than forcing the same states into every sport regression.

---

## Section 7 — Forest Plot

Extracts the simple overall ATT and its standard error for each sport, computes a 95% CI using $\pm 1.96 \cdot SE$, and plots all four estimates side by side. This is a standard way to summarize multi-outcome studies and visually assess effect heterogeneity across sports.

---

## Section 8 — Synthetic DiD (Arkhangelsky et al. 2021)

> This section gets the most attention because Synthetic DiD is the most methodologically sophisticated estimator in the script.

### Motivation: combining SC and DiD

**Standard DiD** subtracts the before–after change in controls from the before–after change in treated units. It implicitly weights all control units equally and all pre-treatment periods equally. This is fine when parallel trends holds unconditionally, but potentially inefficient or biased when:
- Control units have very different pre-treatment levels (heterogeneous baseline).
- Pre-treatment trends differ but could be equalized by reweighting.

**Synthetic Control (Abadie et al. 2010)** reweights control *units* to construct a weighted average (the "synthetic control") whose pre-treatment outcome path matches the treated unit's path. This is powerful for a single treated unit but doesn't naturally generalize to many treated units, and it doesn't handle time-period reweighting.

**Synthetic DiD** (Arkhangelsky et al. 2021) improves on both:

1. **Unit weights $\hat\omega_i$** — reweight control units so their weighted pre-treatment trend matches the treated average (like SC).
2. **Time weights $\hat\lambda_t$** — reweight pre-treatment periods to down-weight distant pre-treatment years and up-weight recent ones (unlike SC or DiD).
3. **DiD structure** — still takes a double difference, so it remains robust to time-invariant unit-level confounders (absorbed by unit FEs) and to common time trends (absorbed by time FEs).

### The SDID estimator

Let:
- $Y_{it}$ = outcome for unit $i$ in period $t$
- $\mathcal{T}^{pre} = \{1, \ldots, T_0\}$ = pre-treatment periods
- $\mathcal{T}^{post} = \{T_0+1, \ldots, T\}$ = post-treatment periods
- $\mathcal{N}^{co}$ = control units, $\mathcal{N}^{tr}$ = treated units
- $\hat\omega_i$ = unit weights ($\sum_{i \in \mathcal{N}^{co}} \hat\omega_i = 1$, $\hat\omega_i \geq 0$)
- $\hat\lambda_t$ = time weights ($\sum_{t \in \mathcal{T}^{pre}} \hat\lambda_t = 1$, $\hat\lambda_t \geq 0$)

**Step 1 — Solve for time weights** by finding $\hat\lambda_t$ that makes the control-unit average look most like the post-treatment period (in terms of how "representative" each pre-period is):

$$\hat\lambda = \arg\min_{\lambda \in \Delta^{T_0}} \left\| \bar{Y}^{post}_{co} - \sum_{t \in \mathcal{T}^{pre}} \lambda_t \bar{Y}^t_{co} \right\|^2 + \zeta^2 T_0 \|\lambda\|^2$$

where $\bar{Y}^t_{co}$ is the equally-weighted control mean at time $t$ and $\zeta$ is a regularization parameter. The ridge penalty encourages the solution away from a corner solution that puts all weight on a single pre-period.

**Step 2 — Solve for unit weights** by finding $\hat\omega_i$ that makes the synthetic control's pre-treatment *trend* (weighted by $\hat\lambda_t$) match the treated group's pre-treatment trend:

$$\hat\omega = \arg\min_{\omega \in \Delta^{N_0}} \sum_{t \in \mathcal{T}^{pre}} \hat\lambda_t \left( \bar{Y}^t_{tr} - \sum_{i \in \mathcal{N}^{co}} \omega_i Y_{it} \right)^2$$

Note: the time weights $\hat\lambda_t$ appear inside the unit-weight objective, so unit weights are chosen to match the *time-weighted* pre-treatment path — not the equally-weighted one.

**Step 3 — Estimate $\hat\tau^{sdid}$** via a weighted two-way fixed effects regression:

$$(\hat\tau^{sdid}, \hat\mu, \hat\alpha, \hat\beta) = \arg\min_{\tau, \mu, \alpha_i, \beta_t} \sum_{i,t} \hat\omega_i^{DiD} \hat\lambda_t^{DiD} \left(Y_{it} - \mu - \alpha_i - \beta_t - \tau D_{it}\right)^2$$

where:
- $D_{it} = \mathbf{1}(i \in \mathcal{N}^{tr},\ t \in \mathcal{T}^{post})$ is the treatment indicator
- $\hat\omega_i^{DiD}$ extends the unit weights to treated units (equal weight $1/N_{tr}$ each)
- $\hat\lambda_t^{DiD}$ extends the time weights to post-treatment periods (equal weight $1/T_{post}$ each)

The ATT estimate $\hat\tau^{sdid}$ is the coefficient on $D_{it}$ in this weighted TWFE regression. It has a clean DiD interpretation:

$$\hat\tau^{sdid} = \underbrace{\left(\bar{Y}^{post}_{tr} - \bar{Y}^{pre,\hat\lambda}_{tr}\right)}_{\text{time-weighted change in treated}} - \underbrace{\left(\bar{Y}^{post}_{\hat\omega} - \bar{Y}^{pre,\hat\lambda}_{\hat\omega}\right)}_{\text{time-weighted change in synthetic control}}$$

where $\bar{Y}^{pre,\hat\lambda}$ denotes the $\hat\lambda_t$-weighted pre-period average, and $\bar{Y}_{\hat\omega}$ denotes the $\hat\omega_i$-weighted control average.

### Assumptions

| Assumption | What it means | How to probe it |
|---|---|---|
| **Parallel trends (conditional)** | After reweighting, treated and synthetic control have the same counterfactual trend | Pre-period fit in the SDID plot |
| **No anticipation** | Treated states don't change behavior before the franchise arrives | Pre-trend coefficients near zero |
| **SUTVA** | No spillovers between states | Hard to test; partially addressed by using state-level aggregates |
| **Overlap** | Control units can span the treated pre-period trends | Verified by the convex hull constraint on $\hat\omega$ |

### The staggered-adoption problem for SDID

The `synthdid` package implements the estimator for a single treatment cohort (one $T_0$). Our data has **8 treatment cohorts** (1997, 1998, 1999, 2000, 2003, 2006, 2008, 2010). The script handles this with a **stacking** approach:

For each cohort $g$:
1. Extract a sub-panel containing only cohort-$g$ treated states and all never-treated control states.
2. Use all available years (1993–2018) with $T_0 = $ number of years before $g$.
3. Run `synthdid_estimate(Y_mat, N0 = N0_actual, T0 = T0)`.

This produces a cohort-specific ATT: $\hat\tau^{sdid}_g$.

**Aggregation** to an overall ATT uses cohort-size weights:

$$\hat\tau^{sdid} = \sum_g \frac{N_g}{N_{treated}} \hat\tau^{sdid}_g, \qquad \hat{SE}^2 = \sum_g \left(\frac{N_g}{N_{treated}}\right)^2 \hat{SE}^2_g$$

where $N_g$ is the number of treated states in cohort $g$.

**Why not pool all cohorts into one matrix?**  
Treating all 8 cohorts as a single group would require forcing a single $T_0$ and a single set of unit weights. States in cohort 1997 would only have 4 pre-treatment years, while states in cohort 2010 would have 17. The unit weights would be estimated on incompatible pre-periods. Stacking avoids this by letting each cohort have its own $T_0$ and its own set of control weights.

### Matrix layout in the code

```r
Y_mat <- sub %>%
  pivot_wider(names_from = year, values_from = val) %>%
  column_to_rownames("state") %>%
  as.matrix()

# Rows ordered: control states first, then treated
Y_mat <- Y_mat[c(ctrl_rows, trt_rows), , drop = FALSE]
```

`synthdid_estimate(Y_mat, N0, T0)` expects:
- Rows 1 through `N0`: control units.
- Rows `N0+1` through `N`: treated units.
- Columns 1 through `T0`: pre-treatment periods.
- Columns `T0+1` through `T`: post-treatment periods.

`T0` is computed as the number of years strictly before the cohort's `first_treat`:

```r
T0 <- sum(all_years_sub < g)
```

### Inference: placebo standard errors

```r
se = sqrt(vcov(tau_hat, method = "placebo"))
```

The `"placebo"` variance estimator shuffles the treatment assignment among units (like a permutation test) to estimate the variance of $\hat\tau^{sdid}$ under the null. It is more conservative than the bootstrap (`method = "bootstrap"`) and better behaved with small numbers of treated units.

### Why SDID can differ from C-S

Both are consistent for the ATT under parallel trends, but they differ in:

- **Weighting:** SDID up-weights recent pre-treatment periods and control units that best match treated trends; C-S uses equal weights within cohort-time cells.
- **Estimand:** C-S estimates each $ATT(g,t)$ separately and aggregates; SDID estimates a single weighted average directly.
- **Bias-variance tradeoff:** SDID can have lower variance when the unit-weight step achieves a good pre-trend fit, but may be slightly biased if the true parallel trends only holds after controlling for covariates (C-S accommodates covariates more flexibly via `xformla`).

If C-S and SDID point in the same direction and are of similar magnitude, that substantially increases credibility.

---

## Section 9 — TWFE Comparison

### The TWFE model

Two-way fixed effects is the classical DiD panel estimator:

$$Y_{it} = \alpha_i + \lambda_t + \delta \cdot D_{it} + \varepsilon_{it}$$

where:
- $\alpha_i$ = state fixed effect (absorbs all time-invariant state characteristics)
- $\lambda_t$ = year fixed effect (absorbs all state-invariant time shocks, e.g., national trends)
- $D_{it} = \mathbf{1}(\text{state } i \text{ has a WNBA team in year } t)$
- $\delta$ = the treatment effect of interest

`feols()` from the `fixest` package estimates this efficiently with the `| state_id + year` syntax (Demazure–Frisch–Waugh absorption of FEs).

### Why TWFE is biased under staggered adoption

Goodman-Bacon (2021) showed that the TWFE coefficient $\hat\delta$ is a **variance-weighted average of all possible 2×2 DiDs**, including:

1. Early-treated vs. never-treated
2. Late-treated vs. never-treated
3. **Early-treated vs. late-treated** (early treated acts as control for late treated)
4. **Late-treated vs. early-treated** (late treated acts as control for early treated)

Cases 3 and 4 are problematic: if the early-treated states continue to accumulate benefits over time (heterogeneous dynamic effects), they are bad controls for the later-treated states because their post-treatment path is no longer a valid counterfactual. The implicit weights on some (cohort, time) cells can be **negative**, meaning an ATT that is positive everywhere could be estimated as negative.

The script includes TWFE as a comparison to show the magnitude of this potential bias:

```r
feols(yname ~ has_wnba | state_id + year, data = df_sp, cluster = ~state_id)
```

The event-study version uses relative-time dummies:

```r
feols(yname ~ i(rel_time, ref = c(-1, -999)) | state_id + year, ...)
```

where `ref = -1` is the omitted base period and `ref = -999` is the never-treated "relative time" (so those observations contribute to the FE estimation but don't generate spurious relative-time dummies).

### Comparison table

The final comparison table (`compare_twfe_cs.pdf`) plots TWFE and C-S ATTs side by side. If TWFE is lower than C-S, that is consistent with negative weighting suppressing the true effect. If they are similar, TWFE bias is likely small in this application (perhaps because later cohorts are small and treatment effects are not strongly dynamic).

---

## Section 10 — Permutation Placebo Test

### Why permutation?

Cluster-robust standard errors rely on asymptotic approximations that can be poor with small numbers of clusters (here, ≤51 states). Permutation inference is **exact** — it makes no distributional assumptions and is valid in finite samples.

### Procedure

The null hypothesis is $H_0: ATT = 0$ (WNBA franchises have no effect).

Under $H_0$, the treatment assignment is arbitrary — any assignment of states to cohorts should produce an ATT near zero. The test:

1. Take the pool of **never-treated** states (the control group).
2. Randomly assign them fake treatment cohorts, preserving the actual cohort-size distribution (so the permuted dataset looks structurally similar to the real one).
3. Run the full C-S estimator on this permuted dataset and record the placebo ATT.
4. Repeat $R = 500$ times to build the null distribution $\{\hat\tau^{null}_r\}_{r=1}^{500}$.
5. Compute the two-sided permutation p-value:

$$p = \frac{\#\{r : |\hat\tau^{null}_r| \geq |\hat\tau^{real}|\}}{R}$$

**Key design choice:** the permutation draws only from *never-treated* states. Using treated states as fake placebo units would be invalid because they received the actual treatment — their post-1997 data reflects a real effect. Using only never-treated states ensures the null distribution is generated from units that genuinely did not receive treatment.

If the real ATT is in the extreme tail of the null distribution (p < 0.05), we reject $H_0$. The histogram plot shows the null distribution with the real ATT marked as a vertical red line.

---

## Section 11 — Composite Index

### Construction

```r
total_part = basketball + cross_country + soccer + track_field
```

States with *any* missing sport in *any* year are excluded (complete-series requirement across all four sports simultaneously). This is more restrictive than the per-sport panels and will reduce the sample.

### Why a composite?

- Reduces noise: sport-specific measurement error is partially averaged out.
- Provides a single headline number for the overall effect on girls' sports participation.
- Less susceptible to substitution effects (e.g., if WNBA entry raises basketball at the expense of soccer, the composite captures the net).

The composite runs through the same C-S estimator as the individual sports.

---

## Section 12 — Descriptive Visualizations

### Spaghetti plots

Each state is indexed to 100 in 1993, then plotted as a thin line. Bold lines show group means. The vertical dotted line at 1997 marks WNBA founding (first treatment cohort). Indexing removes level differences across states and focuses attention on *growth* — the relevant variation for DiD.

### Cohort trend plots

Same index construction, but lines represent cohort averages rather than individual states. Useful for diagnosing cohort-specific pre-trends and for eyeballing whether later cohorts look different from earlier ones.

### Gantt chart

A state × year heatmap where each cell is colored by treatment status:
- **Grey** = pre-treatment or never-treated
- **Cohort color** = treated in that year

This is the standard way to visualize a staggered adoption panel and immediately conveys which states are available as controls for which treated cohorts.

---

## Section 13 — Summary Table

Collects TWFE ATT, C-S ATT, and SDID ATT (with SEs) for all four sports into a single table. This is the primary results table: three estimators that rely on different assumptions and functional forms, pointing in the same or different directions, for four outcomes.

**Interpreting agreement across estimators:**

- If all three agree in sign and are similar in magnitude → high confidence in the direction of the effect.
- If C-S and SDID agree but TWFE differs → TWFE negative-weighting bias is likely the culprit; prefer C-S/SDID.
- If C-S and SDID disagree → check whether the unit-weight fit in SDID is good (i.e., does the synthetic control track pre-trends well?).

---

## Output Files Summary

| File | Contents |
|---|---|
| `map_wnba_states.pdf` | Map of treated states by cohort |
| `trend_{sport}.pdf` | Raw mean trends by treatment group |
| `es_{sport}.pdf` | C-S event study plots |
| `cohort_{sport}.pdf` | C-S ATT by cohort |
| `sdid_{sport}.pdf` | SDID cohort estimates + pooled ATT |
| `placebo_{sport}.pdf` | Permutation null distribution |
| `compare_twfe_cs.pdf` | TWFE vs. C-S comparison |
| `spaghetti_{sport}.pdf` | State-level indexed trend plots |
| `cohort_trend_{sport}.pdf` | Cohort-mean indexed trend plots |
| `gantt_treatment.pdf` | Staggered adoption Gantt chart |
| `forest_att.pdf` | Overall ATT across sports (C-S) |

---

## Key References

- Callaway, B. & Sant'Anna, P.H.C. (2021). "Difference-in-differences with multiple time periods." *Journal of Econometrics*.
- Arkhangelsky, D., Athey, S., Hirshberg, D.A., Imbens, G.W., & Wager, S. (2021). "Synthetic difference-in-differences." *American Economic Review*.
- Goodman-Bacon, A. (2021). "Difference-in-differences with variation in treatment timing." *Journal of Econometrics*.
- de Chaisemartin, C. & D'Haultfœuille, X. (2020). "Two-way fixed effects estimators with heterogeneous treatment effects." *American Economic Review*.
- Abadie, A., Diamond, A., & Hainmueller, J. (2010). "Synthetic control methods for comparative case studies." *JASA*.
- Beaman, L., Duflo, E., Pande, R., & Topalova, P. (2012). "Female leadership raises aspirations and educational attainment for girls." *Science*.
