# Paper Summary - Week 2 of Health Economics

## The Value of Life and the Rise in Health Spending
### Hall and Jones

#### Introduction
- share of resources spent on health care:
  - 1950 - 5.2%
  - 1975 - 9.4%
  - 2000 - 15.4%
- life expectancy increase of approx 10 yr
- standard preferences imply health is superior good
- build on literature:
  1. understand determinants of aggregate health share.
  2. examine broader class of preferences for longevity and consumption.
#### Basic Model 
##### Assumptions
- mortality is constant across age groups
- preferences are static
- income and productivity are constant
##### Model
$$
U(c,x) = \int_0^{\infty}e^{-(1/x)t}u(c)dt = xu(c)
$$

- lifetime utility is present value of per-period utility discounted for mortality at rate $1/x$
- constraints
$$
c+h=y \\
x = f(h)
$$

##### Social Planner's Problem
$$
\max_{c,h}f(h)u(c) \ s.t. c+h=y
$$

##### Optimal Allocation
$$
\frac{s^*}{1-s^*} = \frac{h^*}{c^*} = \frac{\eta_h}{\eta_c}
$$
where $s\equiv\frac{h}{y}, \ \eta_h\equiv f'(h)\frac{h}{x}, \ \eta_c\equiv u'(c)\frac{c}{u}$

##### Assertion
> Consumption elasticity falls relative to health elasticity as income rises, causing health share to rise.
- occurs due to addition of constant to flow of utility, allowing for variation in elasticity of utility
- flow utility:
$$
u(c) = b + \frac{c^{1-\gamma}}{1-\gamma}
$$

---

## On the Concept of Health Capital and the Demand for Health
### Michael Grossman

#### Introduction
- model of demand for health capital
  - health is viewed as a form of human capital
- health capital $\ne$ human capital here
  - stock of knowledge affects market and nonmarket productivity while health stock determines time
  available to spend producing money earnings and commodities
- demand for health services is **not** demand for the service itself, but demand for improved health
outcomes
- model works via:
  - consumers produce commodities with inputs of market goods and their own time, demand for these goods
  and services is a derived demand
- assume individuals inherit an initial stock of health that depreciates over time - at an increasing rate - but can be increased by investment, with death occurring when health stock falls below a threshold
  - novel feature is consumers "choose" length of life
#### Model
- intertemporal utility function:
$$
U = U(\phi_0H_0, ..., \phi_nH_n,Z_0, ...,Z_n)
$$
where $H_0$ is inherited stock of health, $H_i$ is stock of health in period $i$, $\phi_i$ is service flow per unit stock, $h_i = \phi_iH_i$ is total consumption of "health services," and $Z_i$ is total consumption of another commodity in period $i$. 

- net investment equals gross investment minus depreciation:
$$
H_{i+1} - H_i = I_i-\delta_iH_i
$$
rates of depreciation are exogenous, but may vary with age.

- Household production functions:
  $$
    I_i = I_i(M_i,TH_i|E_i) = M_ig(t_i| E_i), \\
    Z_i = Z_i(X_i, T_i|E_i)
  $$
where $M_i$ is medical care, $X_i$ is goods input in production of the commodity, $Z_i, TH_i, T_i$ are time inputs and $E_i$ is the stock of human capital. The second equality associated with $I_i$ can be written as such because all production functions are HD1 in good and time inputs. $t_i = \frac{TH_i}{M_i}$.

- Marginal products of time and medical production of gross investment:
$$
\frac{\partial I_i}{\partial TH_i} = \frac{\partial g}{\partial t_i} = g', \\
\frac{\partial I_i}{\partial M_i} = g - t_ig'
$$

- Goods budget constraint: equates present value of outlays on goods to present value of earnings income over the life cycle plus initial assets (discounted property value)
$$
\sum\frac{P_iM_i + V_iX_i}{(1+r)^i} = \sum\frac{W_iTW_i}{(1+r)^i} + A_0
$$
Where $P_i, \ V_i$ are prices of $M_i, \ X_i$ respectively $W_i$ is wage, $TW_i$ is hours of work, $A_0$ is discounted property income, $r$ is interest rate.

- Time constraint:
$$
TW_i + TL_i + TH_i + T_i = \Omega
$$
$TL_i$ is time lost from market and nonmarket activities due to illness/injury. Sick time added to exhaust total time by all possible uses. $TL_i$ is assumed to be inversely related to health stock.

- Full wealth constraint (sub $TW_i$ into goods constraint):
$$
\sum\frac{P_iM_i V_iX_i + W_i(TL_i + TH_i + T_i)}{(1+r)^i} = \sum\frac{W_i\Omega}{(1+r)^i} + A_0 = R
$$

### Findings:
- More money $\Rightarrow$ more health capital demand
- More educated $\Rightarrow$ higher health quality demand
- Lots of simplifying assumptions
- Care because:
  - econ: shows returns to education for health, shows health capital by wealth strata (basis), and shows optimal investment of time to maintain consumer utility
  - policy: education initiatives lead to better health quality (?)
---

## Dunn, Fernando, Liebman - 
### Introduction 
Motivation - how to best measure value of medical innovation
Addition - CEAR (Tufts Cost Effectiveness Analysis Registry) database and matching to claims data to measure cost growth and innovation in health care sector

### Consumer Welfare and Quality-Adjusted Price Indexes
Consumer welfare change over time:
$$
\Delta\text{Consumer Welfare}_{d,t,t-1} = VSLY\cdot(H_{d,t}-H_{d,t-1}) - (S_{d,t}-S_{d,t-1})
$$
  - this equation accounts for the change in price and quality of treatment

Price index for a disease $d$:
$$
\text{Price Index}_{d,t,t-1} = \frac{S_{d,t-1} - \Delta\text{Consumer Welfare}_{d,t,t-1}}{S_{d,t-1}} \\
= \frac{S_{d,t}}{S_{d,t-1}} - \frac{VSLY\cdot(H_{d,t}-H_{d,t-1})}{S_{d,t-1}}
$$

- intuition:
  - first line shows price index is less than 1, implying consumer welfare is increasing
  - separation of price change from quality improvement
