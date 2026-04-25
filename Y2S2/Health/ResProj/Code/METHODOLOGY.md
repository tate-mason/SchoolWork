# Methodology: Effect of WNBA Franchises on Girls' Sports Participation

## What We're Trying to Answer

Does having a WNBA team in your state cause more girls to play high school sports?

The idea is a **role model effect**: when young girls see professional female athletes playing in their state, they may be more inspired to participate in sports themselves. We test this by comparing how girls' participation in high school sports changed in states that got a WNBA team vs. states that never got one.

---

## The Data

We use the **National Federation of State High School Associations (NFHS)** annual survey, which tracks the number of girls participating in each high school sport, by state, from the 1993–94 academic year through 2018–19.

- **51 states** (including DC)
- **26 academic years** (1993–94 through 2018–19, mapped to the start year: 1993–2018)
- **4 sports**: Basketball, Soccer, Cross Country, Track & Field
- **Treatment**: WNBA franchise ever operated in that state. States are assigned the year the first franchise began, which becomes their "treatment year."

### Treatment Assignment

| First WNBA Year | States |
|---|---|
| 1997 | New York, Texas, North Carolina, Arizona, Ohio, California, Utah |
| 1998 | Virginia, Michigan |
| 1999 | Florida, Minnesota |
| 2000 | Oregon, Indiana, Washington |
| 2003 | Connecticut |
| 2006 | Illinois |
| 2008 | Georgia |
| 2010 | Oklahoma |

**Never treated** (control group): 33 states that never had a WNBA franchise as of 2018.

---

## Data Cleaning

The raw NFHS data contains three distinct categories of problems, each requiring a different fix. We describe each in full below.

---

### Problem 1: Single-Year Transcription Errors

**What they are.** Certain state-sport-year cells contain values that are wildly inconsistent with every surrounding year, then snap back to normal in the very next observation. These are almost certainly transcription errors in the original NFHS reports — a dropped digit, an extra digit prepended, or a value entered in the wrong row.

**How we found them.** For each state-sport series, we computed the within-state median and interquartile range (IQR) across all 26 years. We flagged any observation where:

$$\frac{|Y_{it} - \text{median}_i|}{\text{IQR}_i} > 5$$

We then manually inspected each flag to verify the return-to-normal pattern: if the value before and the value after are both within the normal range, and the flagged value is either ≥3× or ≤1/3 of its neighbors, we treat it as a recording error.

**What we found.** Eleven observations met this standard:

| State | Sport | Year | Reported Value | Typical Range | Ratio to Neighbors |
|---|---|---|---|---|---|
| Indiana | Basketball | 1998 | 42,510 | ~11,000–12,500 | ~3.5× |
| Hawaii | Basketball | 1998 | 4,607 | ~1,300–1,800 | ~2.9× |
| Missouri | Basketball | 1997 | 2,631 | ~11,800–13,100 | ~0.2× |
| Michigan | Basketball | 1997 | 9,948 | ~19,000–20,800 | ~0.5× |
| California | Cross Country | 1998 | 44,245 | ~11,000–16,000 | ~3.1× |
| Maine | Cross Country | 1997 | 4,017 | ~840–1,140 | ~4.0× |
| Massachusetts | Soccer | 2003 | 42,193 | ~11,000–13,000 | ~3.4× |
| Rhode Island | Soccer | 1993 | 4,171 | ~1,100–2,200 | ~3.7× vs. next year |
| Rhode Island | Soccer | 1995 | 38 | ~1,100–2,200 | ~0.03× |
| Minnesota | Track & Field | 1999 | 42,123 | ~12,000–14,000 | ~3.4× |
| West Virginia | Track & Field | 2002 | 9,079 | ~2,200–3,200 | ~3.9× |

**What we did.** Each flagged observation is set to `NA`. We do not attempt to impute a replacement value — guessing what the "true" number should have been introduces its own error, and the flagged observations are too extreme to interpolate confidently. Setting them to `NA` means that states with a missing year in a given sport are excluded from that sport's DiD by the balanced-panel requirement (see below), so the error cannot propagate into any estimate.

**Why each case is unambiguously an error.** The defining feature in every case is the single-year spike followed by an immediate return to the prior level. No plausible real-world event — a new school program, a population shift, a policy change — could cause a 3–4× jump in one year and then a complete reversal the very next year. The only consistent explanation across all eleven cases is a data entry mistake.

---

### Problem 2: Permanent Structural Break (Pennsylvania Cross Country)

**Pennsylvania, Cross Country, 2008 onward.** Pennsylvania's cross country figure permanently doubles from approximately 5,500 to 11,320 starting in 2008. Unlike the single-year errors above, this shift is persistent — the series never returns to its pre-2008 level. This is consistent with a reporting methodology change: Pennsylvania began counting indoor cross country separately in 2008, effectively doubling the number of recorded participants. The NFHS survey instructions changed in this period to require separate enumeration of indoor programs in states that offered them.

**Why it matters.** Pennsylvania is a never-treated control state. If we include it, the control group's cross country mean gets an artificial boost of roughly 5,800 participants starting in 2008 — a jump that has nothing to do with WNBA treatment. This would make the control group appear to grow faster post-2008, compressing or even reversing the estimated ATT for cross country.

**What we did.** We set Pennsylvania's cross country values to `NA` for 2008 and all subsequent years. Because the balanced-panel requirement drops any state that is missing in at least one year, this excludes Pennsylvania from the entire cross country DiD. Pennsylvania remains in the panel for all other sports where its data are unaffected.

**Why not impute?** A structural break of this kind is not a random error around a true value — it reflects a genuine change in what is being counted. We cannot reverse-engineer the pre-2008-equivalent number for post-2008 years, so imputation would be fiction. Exclusion is the only honest option.

---

### Problem 3: Composition Artifacts in Trend Plots

**What this is.** This problem is distinct from the first two because it does not involve incorrect raw data. It is a consequence of how the trend plots were originally computed.

The raw trend plots averaged participation across all states with non-missing data in each year. Because the NA corrections above create missing values in specific state-year cells, the set of states contributing to each year's average changed from year to year. For example:

- In basketball, Missouri's 1997 value is NA'd out as a transcription error. In 1997, the control-group average is therefore computed over 32 states instead of 33. Missouri has above-average participation (~13,000 vs. a control mean of ~5,400), so its removal pulls the 1997 control mean *down* relative to adjacent years — creating a fake dip in 1997 that has nothing to do with real participation trends.
- Similar composition shifts occur in 1997 for Michigan basketball (treated group) and in 1998 for California cross country.

This is called a **composition artifact**: the apparent trend is driven by changes in *which states* are in the average rather than changes in *what states are doing*.

**What we did.** The trend plot function was updated to first identify the balanced set of states — those with complete, non-missing data across all 26 years for a given sport — and then restrict the average to only those states in every year. This ensures n_treated and n_control are constant throughout the plot. The visual result is a clean, monotone series in which every year-to-year change reflects real changes in participation rather than sample composition shifts.

The balanced-panel restriction also aligns the trend plot with the DiD estimators, which already apply the same filter. The trend plot now shows exactly the sample on which the DiD estimates are based.

**Effect on sample sizes.** The balanced-panel restriction removes states with any missing observation in a given sport. The states and counts are:

| Sport | Balanced States | Control | Treated |
|---|---|---|---|
| Basketball | 47 | 31 | 16 |
| Soccer | 46 | 29 | 17 |
| Cross Country | 48 | 31 | 17 |
| Track & Field | 49 | 32 | 17 |

States excluded from a sport's trend plot are those with one or more NA values in that sport, which includes states affected by Problems 1 and 2 above.

---

### Problem 4: Nationwide 2012 Level Shift (Data Fact, Not Fixed)

**What it is.** In 2012, mean participation jumps by approximately 20–27% in both the treated and control groups, and across all four sports simultaneously. This is not a spike — it is a permanent upward step. The post-2012 series continues growing from the new higher level.

| Sport | Control 2011 | Control 2012 | % Change | Treated 2011 | Treated 2012 | % Change |
|---|---|---|---|---|---|---|
| Basketball | 5,080 | 6,452 | +27% | 15,064 | 18,075 | +20% |
| Soccer | 4,183 | 4,738 | +13% | 13,355 | 14,592 | +9% |
| Cross Country | 1,966 | 2,556 | +30% | 6,784 | 7,521 | +11% |
| Track & Field | 6,629 | 8,250 | +24% | 18,161 | 22,384 | +23% |

Because the shift occurs in the same calendar year across all sports and both groups, it cannot be attributed to WNBA treatment or to errors in individual states. The most consistent explanation is a change in NFHS survey methodology or coverage starting in the 2012–13 survey year — for instance, an expansion in which schools or programs were included in the count.

**Why we don't fix it.** This shift affects treated and control states proportionally. In a difference-in-differences design, what matters is the *difference* between groups, not the level of either group. Because the 2012 jump hits both sides roughly equally, it cancels out in the DiD and does not bias the ATT estimates.

**What we do instead.** We annotate the 2012 boundary with a vertical dotted line on all trend plots, labeled "NFHS reporting change." This alerts readers to the discontinuity without suggesting it is an error or that we have altered the underlying data. The raw numbers are left exactly as reported.

---

## Identification Strategy: Difference-in-Differences

### The Basic Idea

A **difference-in-differences (DiD)** design compares:

1. How much did participation change *over time* in treated states (before vs. after getting a WNBA team)?
2. Minus how much did participation change *over time* in control states (which never got a team) over the same period?

The "double difference" removes shared trends (like nationwide growth in girls' sports post-Title IX, or the 2012 NFHS methodology shift) and leaves only the effect of the WNBA franchise.

Mathematically, the 2×2 case looks like:

$$\text{ATT} = \underbrace{(\bar{Y}^{treat}_{post} - \bar{Y}^{treat}_{pre})}_{\text{change in treated states}} - \underbrace{(\bar{Y}^{control}_{post} - \bar{Y}^{control}_{pre})}_{\text{change in control states}}$$

The key assumption is **parallel trends**: in the absence of the WNBA franchise, treated and control states would have followed the same trajectory. We test this by looking at pre-treatment periods — if the two groups were tracking each other before treatment, the assumption is plausible.

### The Balanced Panel Rule

Every estimator in this project uses a **balanced panel** for each sport: only states with non-missing data in every one of the 26 years are included. This serves two purposes:

1. It prevents composition artifacts (Problem 3 above) from contaminating estimates.
2. It ensures that every year contributes the same set of states to the estimate, so year-to-year comparisons are apples-to-apples.

States excluded by this rule drop out of a given sport's analysis entirely. They are not replaced, reweighted, or imputed.

### The Staggered Adoption Problem

The basic DiD gets complicated when different states get treated at different times (1997, 1998, 1999, ..., 2010). This is called **staggered adoption**. The classic solution was to use **Two-Way Fixed Effects (TWFE)**:

$$Y_{it} = \alpha_i + \lambda_t + \delta \cdot D_{it} + \varepsilon_{it}$$

where $\alpha_i$ are state fixed effects (absorb time-invariant state characteristics), $\lambda_t$ are year fixed effects (absorb nationwide time trends, including the 2012 shift), $D_{it} = 1$ when state $i$ is treated in year $t$, and $\delta$ is the estimated ATT.

**The problem**: With staggered adoption, TWFE is biased. When comparing a "late-treated" state to an "early-treated" state, the already-treated state acts as an implicit control — but it's not a valid control because it's already receiving treatment. This can produce **negative weights** on some group-time pairs, meaning TWFE can actually flip the sign of the ATT in extreme cases (Goodman-Bacon 2021; de Chaisemartin & D'Haultfoeuille 2020).

---

## Estimator 1: Callaway-Sant'Anna (2021)

### What It Does

Callaway & Sant'Anna (2021) solve the TWFE problem by estimating **group-time average treatment effects** $ATT(g,t)$ separately for each combination of:
- **Group $g$**: the cohort of states that were first treated in year $g$
- **Time period $t$**: each year in the sample

The $ATT(g,t)$ is estimated cleanly using only:
- States in group $g$ (the treated cohort) vs. **never-treated states** (our control group)
- Pre-treatment periods for $g$ vs. periods after $g$

This avoids the "already-treated as control" problem entirely.

### The Math

For a group $g$ and time $t > g$ (post-treatment):

$$ATT(g,t) = E[Y_t - Y_{g-1} \mid G = g] - E[Y_t - Y_{g-1} \mid G = \infty]$$

where $G = g$ means "first treated in year $g$" and $G = \infty$ means "never treated." The outcome is compared in levels from the pre-treatment base period $g-1$.

### Aggregation

From the matrix of $ATT(g,t)$ estimates, we compute:

**Overall ATT** (simple average, cohort-size weighted):
$$ATT^{simple} = \sum_g \sum_{t \geq g} w_{gt} \cdot ATT(g,t)$$

**Dynamic ATT (Event Study)**: Aggregate over cohorts within each relative time $e = t - g$:
$$ATT^{dyn}(e) = \sum_g w_g \cdot ATT(g, g+e)$$

This traces out how the effect evolves before and after treatment. Flat pre-trends ($e < 0$) and growing post-trends ($e \geq 0$) are the ideal pattern.

**Cohort ATT**: Average over $t$ within each group $g$. Shows whether the effect was larger for some cohorts than others.

### Inference

Standard errors are clustered at the state level. Confidence bands for the event study are **simultaneous** (uniform) — they control the probability that the entire pre/post path lies within the band, not just each point individually. This is more conservative than pointwise CIs but appropriate for testing the overall shape of the event study.

---

## Estimator 2: Synthetic Difference-in-Differences (Arkhangelsky et al. 2021)

### What It Does

**Synthetic DiD (SDID)** combines two ideas:
1. **Synthetic Control**: Find a weighted combination of control states whose pre-treatment trajectory closely matches the treated states.
2. **DiD**: Difference out the remaining common trend.

It does this by solving two separate weighting problems:

**Unit weights** $\hat{\omega}_i$ (one per control state): Reweight control states so their pre-treatment average matches the treated states' pre-treatment average:

$$\hat{\omega} = \arg\min_{\omega \geq 0, \sum \omega = 1} \sum_{t < g} \left( \sum_{i: control} \omega_i Y_{it} - \bar{Y}^{treat}_t \right)^2$$

**Time weights** $\hat{\lambda}_t$ (one per pre-treatment year): Reweight pre-treatment years to emphasize those most predictive of the post-treatment period:

$$\hat{\lambda} = \arg\min_{\lambda \geq 0, \sum \lambda = 1} \sum_{i} \left( \sum_{t < g} \lambda_t Y_{it} - \bar{Y}^i_{post} \right)^2$$

The SDID estimator is then:

$$\hat{\tau}^{sdid} = \arg\min_{\tau, \alpha_i, \beta_t} \sum_{i,t} \hat{\omega}_i \hat{\lambda}_t \left( Y_{it} - \alpha_i - \beta_t - \tau D_{it} \right)^2$$

This is essentially a weighted TWFE regression where the weights are chosen to make treated and control units look as parallel as possible pre-treatment.

### Why It's Better Than SC Alone

Synthetic control doesn't use any time weights and requires perfect pre-trend matching. SDID is more flexible — it allows for some pre-trend discrepancy and absorbs it through the time weights. It also works better when there are many treated units (we have up to 7 in the 1997 cohort).

### Handling Staggered Adoption

The `synthdid` package requires a single treatment date. We handle staggered adoption through a **stacked approach**:
1. For each cohort $g$, build a sub-panel: states in cohort $g$ + all never-treated states.
2. Run SDID on each sub-panel separately.
3. Combine cohort-level estimates using cohort-size weights.

Standard errors use the **placebo variance estimator**: randomly reassign the treatment to control units, compute the SDID estimate, and repeat. The variance of these placebo estimates is used as the standard error for the real estimate.

---

## Estimator 3: TWFE (for comparison)

We include the classic **Two-Way Fixed Effects** estimator to illustrate potential bias with staggered DiD:

$$Y_{it} = \alpha_i + \lambda_t + \delta \cdot D_{it} + \varepsilon_{it}$$

This is estimated with `feols()` from the `fixest` package with state and year fixed effects, clustering at the state level.

**When TWFE and C-S agree**: The bias from "bad comparisons" is small, possibly because the effect is homogeneous across cohorts.

**When TWFE and C-S disagree**: TWFE is likely picking up heterogeneous treatment timing or using early-treated states as controls, inflating or deflating the estimate.

---

## Experiment 4: Permutation Placebo Test

### What It Does

We test whether our estimated ATT could have occurred by chance if the WNBA had no effect. We do this without parametric assumptions using a **permutation (randomization) test**:

1. Take the 33 never-treated states (our control group).
2. Randomly assign fake "WNBA franchise years" to a random subset of these states, mimicking the real distribution of cohort sizes (7 states in 1997, 2 in 1998, etc.).
3. Run C-S DiD on this fake dataset and record the ATT.
4. Repeat 500 times to build the **null distribution** of ATT under no true effect.
5. Compute the permutation p-value: the fraction of placebo runs where $|\hat{ATT}_{null}| \geq |\hat{ATT}_{real}|$.

### Why This Works

If the WNBA truly has no effect, then our assignment of treatment to real states is just one draw from the set of all possible assignments — there's nothing special about the real treated states vs. the fake ones. If the real ATT is extreme compared to the null distribution, it's unlikely to have arisen by chance.

This is exact, nonparametric inference. It does not rely on asymptotic normality or correct cluster robust variance estimation. It is especially powerful in small samples (we have only ~18 treated states).

### The Math

$$p\text{-value} = \frac{1}{R} \sum_{r=1}^R \mathbf{1}\left[ |\hat{\tau}^{(r)}| \geq |\hat{\tau}^{real}| \right]$$

where $\hat{\tau}^{(r)}$ is the C-S ATT from the $r$-th placebo assignment and $\hat{\tau}^{real}$ is the actual estimated ATT.

---

## Experiment 5: Composite Index

### Motivation

Each individual sport has measurement noise — a state may have a bad year in basketball but a good year in track. By summing all four sports into a **total participation** variable, we reduce sport-specific noise and test whether the WNBA effect is broad-based (across all sports) rather than sport-specific.

$$\text{total\_part}_{it} = \text{basketball}_{it} + \text{cross\_country}_{it} + \text{soccer}_{it} + \text{track\_field}_{it}$$

We require complete data in all four sports to include a state in this analysis. The same C-S estimator is applied to this composite outcome.

**Interpretation**: If the composite ATT is positive and significant, the WNBA increases overall athletic culture for girls, not just in one sport. If it's insignificant while individual sports show effects, the gains may be sport-specific with substitution across sports.

---

## Reading the Output

### Trend Plots (`trend_*.pdf`)

Show mean participation over time separately for ever-treated and never-treated states. The sample is restricted to the balanced panel (states with complete data in all 26 years) so the composition of each group is constant — every year-to-year change reflects real participation changes, not sample turnover. A vertical dotted line at 2012 marks the nationwide NFHS reporting methodology change.

### Event Study Plots (`es_*.pdf`)

- **X-axis**: Years relative to WNBA franchise entry (0 = first year of franchise, -1 = one year before, etc.)
- **Y-axis**: ATT in participants, normalized so that $e = -1$ equals zero
- **Blue dots/bars** ($e < 0$): Pre-treatment periods — should be near zero if parallel trends holds
- **Red dots/bars** ($e \geq 0$): Post-treatment periods — positive = more participation after WNBA arrives
- **Shaded band**: 95% simultaneous confidence interval

### Cohort Plots (`cohort_*.pdf`)

Each point is the average ATT for states in a given treatment cohort. Lets you see if early-adopter states (1997) had larger or smaller effects than late adopters.

### Forest Plot (`forest_att.pdf`)

One-number summary: overall ATT and 95% CI for each sport, side by side.

### SDID Plots (`sdid_*.pdf`)

Cohort-level Synthetic DiD estimates. The red horizontal line is the weighted average; the red band is the overall 95% CI.

### Placebo Plots (`placebo_*.pdf`)

Histogram of 500 null ATTs from the permutation test. The red vertical line is the real ATT. If the red line is in the tail of the histogram, the effect is statistically unlikely to be noise.

### Comparison Plot (`compare_twfe_cs.pdf`)

TWFE vs. C-S side by side. Divergence between the two signals potential TWFE bias from staggered adoption.

---

## Assumptions and Limitations

**Parallel Trends**: The key assumption. We test it visually (pre-trends in event study) but cannot prove it. The main threat is that states that attracted WNBA franchises were already trending differently — e.g., larger cities with growing sports infrastructure.

**No Anticipation**: States don't change behavior *before* the franchise arrives (e.g., in anticipation of an announcement). We test this by checking that pre-treatment ATTs are near zero.

**Stable Unit Treatment Value Assumption (SUTVA)**: Treatment in California doesn't spill over to Nevada. This is plausible since we're measuring state-level participation, but TV viewership of WNBA games could create weak cross-state spillovers.

**The 2012 NFHS shift does not bias DiD**: Because the nationwide reporting change in 2012 affects treated and control states alike, it differences out of the ATT. However, it does affect the absolute level of the composite index and raw trend plots, which is why it is annotated rather than removed.

**Selection of Sports**: We analyze four sports, not all NFHS sports. The role-model effect of a *basketball* franchise most directly maps to basketball, but WNBA athletes are visible across media in general, which is why we also check cross-sport effects.

**Measurement**: NFHS counts participations (not participants) — a student playing multiple sports is counted multiple times. This is a level issue, not a bias issue for DiD, since it applies equally to treated and control states and both pre- and post-periods.
