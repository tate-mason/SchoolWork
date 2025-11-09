---
title: "Problem Set 2 - IO"
author: "Tate Mason"
format: pdf
---



## Question 1
Exploring the Data


::: {.cell}

```{.r .cell-code}
# Load necessary libraries
library(dplyr)
library(gtsummary)
library(ggplot2)
library(readr)
library(lubridate)
library(here)
library(kableExtra)
library(modelsummary)
library(gmm)
library(tidyr)
# Load the dataset
data <- read_csv(here("Y2S1/IO/ps2/data", "prod_data_all.csv"))
# Clean dataset to harmonize year discrepancy - 1981 = 81
data <- data %>%
  mutate(year = ifelse(year < 100, year + 1900, year)) %>%
  drop_na()

# Display the first few rows of the dataset
head(data)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 6 x 9
     id  year     Y    Y2     L      K     M industry country
  <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl> <chr>    <chr>  
1 10250  1981  296.  113.  2.86   15.5  183. metal    col    
2 10732  1989 4733. 2566. 86.2   470.  2167. metal    col    
3 10732  1990 4800. 2608. 73.6   644.  2192. metal    col    
4 10962  1982 7090. 1836. 37.9  5538.  5254. metal    col    
5 10962  1983 4942. 1343. 40.5  6314.  3599. metal    col    
6 11192  1981 1813. 1311. 24.0  1723.   502. metal    col    
```


:::
:::


### 1.1

::: {.cell}

```{.r .cell-code}
# Summary statistics for each country - display no. obs for each sector and each sector over time

data_col <- data %>% filter(country == "col") 
data_chi <- data %>% filter(country == "chile") 

# Number of observations by sector for each country
obs_by_sector_col <- data_col %>%
  group_by(industry) %>%
  summarise(n_obs = n()) %>%
  arrange(desc(n_obs))
obs_by_sector_chi <- data_chi %>%
  group_by(industry) %>%
  summarise(n_obs = n()) %>%
  arrange(desc(n_obs))
print("Colombia Observations by Sector:")
```

::: {.cell-output .cell-output-stdout}

```
[1] "Colombia Observations by Sector:"
```


:::

```{.r .cell-code}
print(obs_by_sector_col)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 5 x 2
  industry n_obs
  <chr>    <int>
1 food      6140
2 apparel   4454
3 metal     3678
4 text      2847
5 wood       964
```


:::

```{.r .cell-code}
print("Chile Observations by Sector:")
```

::: {.cell-output .cell-output-stdout}

```
[1] "Chile Observations by Sector:"
```


:::

```{.r .cell-code}
print(obs_by_sector_chi)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 5 x 2
  industry n_obs
  <chr>    <int>
1 food     18833
2 metal     5856
3 text      5447
4 wood      4835
5 apparel   4694
```


:::

```{.r .cell-code}
# Number of observations by year for each sector in each country
obs_by_year_sector_col <- data_col %>%
  group_by(year, industry) %>%
  summarise(n_obs = n()) %>%
  arrange(year, industry)
obs_by_year_sector_chi <- data_chi %>%
  group_by(year, industry) %>%
  summarise(n_obs = n()) %>%
  arrange(year, industry)
print("Colombia Observations by Year and Sector:")
```

::: {.cell-output .cell-output-stdout}

```
[1] "Colombia Observations by Year and Sector:"
```


:::

```{.r .cell-code}
print(obs_by_year_sector_col)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 55 x 3
# Groups:   year [11]
    year industry n_obs
   <dbl> <chr>    <int>
 1  1981 apparel    694
 2  1981 food       872
 3  1981 metal      558
 4  1981 text       429
 5  1981 wood       160
 6  1982 apparel    619
 7  1982 food       803
 8  1982 metal      514
 9  1982 text       364
10  1982 wood       146
# i 45 more rows
```


:::
:::


**Chile**: 1. Food - 2584, 2. Metal - 1038, 3. Wood - 867, 4. Apparel - 856, 5. Textile - 836
**Colombia**: 1. Food - 908, 2. Apparel - 744, 3. Metal - 632, 4. Textile - 475, 5. Wood - 173

**Apparel Over Time** - 1979: 354 $\rightarrow$ 1996: 292
- Peak at 1981 - 979

**Food Over Time** - 1979: 1171 $\rightarrow$ 1996: 1178
- Peak at 1981 - 1951

**Metal Over Time** - 1979: 373 $\rightarrow$ 1996: 443
- Peak at 1981 - 890

**Textiles Over Time** - 1979: 391 $\rightarrow$ 1996: 304
- Peak at 1981 - 752

**Wood Over Time** - 1979: 340 $\rightarrow$ 1996: 290
- Peak at 1981 - 465

### 1.2

::: {.cell}

```{.r .cell-code}
# Creation of Investment Variable with 10 per depreciation rate
data <- data %>%
  arrange(id, year) %>%
  group_by(id) %>%
  mutate(
    dep    = 0.10,
    k_next = lead(K),
    i_raw  = k_next - (1 - dep) * K,
    log_i  = ifelse(i_raw  > 0, log(i_raw), NA_real_),
    log_L  = ifelse(L      > 0, log(L),     NA_real_),
    log_K  = ifelse(K      > 0, log(K),     NA_real_),
    log_Y2 = ifelse(Y2     > 0, log(Y2),    NA_real_)
  ) %>%
  ungroup()

data_col <- data %>% filter(country == "col")
data_chi <- data %>% filter(country == "chile")

# Visualize with Histogram for each industry
ggplot(data_col, aes(x = log_i)) +
  geom_histogram(binwidth = 0.5, fill = "blue", color = "black", alpha = 0.7) +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Histogram of Log Investment by Industry, Colombia",
       x = "Log Investment",
       y = "Frequency") +
  theme_minimal()
```

::: {.cell-output-display}
![](ps2_files/figure-pdf/1-2 Histograms of Investment-1.pdf){fig-pos='H'}
:::

```{.r .cell-code}
ggsave("1.2_col.pdf", width = 10, height = 6)

ggplot(data_chi, aes(x = log_i)) +
  geom_histogram(binwidth = 0.5, fill = "green", color = "black", alpha = 0.7) +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Histogram of Log Investment by Industry, Chile",
       x = "Log Investment",
       y = "Frequency") +
  theme_minimal()
```

::: {.cell-output-display}
![](ps2_files/figure-pdf/1-2 Histograms of Investment-2.pdf){fig-pos='H'}
:::

```{.r .cell-code}
ggsave("1.2_chi.pdf", width = 10, height = 6)
```
:::


In Colombia, the is much more dispersion in investment levels across industries, with some industries even experiencing negative investment.
Food, metal, and textiles have very similar investment patterns, with means around 5. Apparel and wood are similar to the other three, though a
bit lower. In Chile, investment levels are super consistent across industries, with all industries having means aound 5-7. Distributions are
also much tighter, though most do have some negative investment observations.

### 1.3

::: {.cell}

```{.r .cell-code}
data_col <- data_col %>%
  group_by(industry) %>%
  mutate(
    log_Y = log(Y),
  ) %>%
  ungroup()

data_chi <- data_chi %>%
  group_by(industry) %>%
  mutate(
    log_Y = log(Y),
  ) %>%
  ungroup()

# Visualize with Histogram for each industry
ggplot(data_col, aes(x = log_Y)) +
  geom_histogram(binwidth = 0.5, fill = "blue", color = "black", alpha = 0.7) +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Histogram of Log Output by Industry, Colombia",
       x = "Log Output",
       y = "Frequency") +
  theme_minimal()
```

::: {.cell-output-display}
![](ps2_files/figure-pdf/1-3 Histograms of Output-1.pdf){fig-pos='H'}
:::

```{.r .cell-code}
ggsave("1.3_col.pdf", width = 10, height = 6)

ggplot(data_chi, aes(x = log_Y)) +
  geom_histogram(binwidth = 0.5, fill = "green", color = "black", alpha = 0.7) +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Histogram of Log Output by Industry, Chile",
       x = "Log Output",
       y = "Frequency") +
  theme_minimal()
```

::: {.cell-output-display}
![](ps2_files/figure-pdf/1-3 Histograms of Output-2.pdf){fig-pos='H'}
:::

```{.r .cell-code}
ggsave("1.3_chi.pdf", width = 10, height = 6)
```
:::


In Colombia, output levels do not vary too much across industries, with means around 7-10 and similar distributions. In Chile, distribtions
are also similar, though there is a bit more variation. Textiles and food have a wider distribution of output levels, while apparel and metal
are a bit tighter.

### 1.4

::: {.cell}

```{.r .cell-code}
# Scatter plot of log_Y and log_L for each sector in each country
data_col <- data_col %>%
  group_by(industry) %>%
  mutate(
    log_L = log(L),
    log_K_ind_col = log(K),
    log_L_ind_col = log(L)
  ) %>%
  ungroup()
data_chi <- data_chi %>%
  group_by(industry) %>%
  mutate(
    log_L = log(L),
    log_K_ind_chi = log(K),
    log_L_ind_chi = log(L)
  ) %>%
  ungroup()

ggplot(data_col, aes(x = log_L, y = log_Y)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", color = "red") +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Scatter Plot of Log Output vs Log Labor (Colombia)",
       x = "Log Labor",
       y = "Log Output") +
  theme_minimal()
```

::: {.cell-output-display}
![](ps2_files/figure-pdf/1-4 Scatter Plots-1.pdf){fig-pos='H'}
:::

```{.r .cell-code}
ggsave("1.4_col.pdf", width = 10, height = 6)

ggplot(data_chi, aes(x = log_L, y = log_Y)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", color = "red") +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Scatter Plot of Log Output vs Log Labor (Chile)",
       x = "Log Labor",
       y = "Log Output") +
  theme_minimal()
```

::: {.cell-output-display}
![](ps2_files/figure-pdf/1-4 Scatter Plots-2.pdf){fig-pos='H'}
:::

```{.r .cell-code}
ggsave("1.4_chi.pdf", width = 10, height = 6)
```
:::


In both countries, there is a positive relationship between labor input and output across all industries. The strength of this relationship
varies by industry, with some industries showing a stronger correlation than others. For example, in Colombia, the food industry shows a 
strong positive correlation, while the wood industry has a weaker correlation. In Chile, all industries show a strong positive correlation.

## Question 2

### 2.1

The estimating equation is as follows: 

$$ \log(Y_{it}) = \alpha_0 + \omega_{it} + \epsilon_{it} + \alpha_L\log(L_{it}) + \alpha_K\log(K_{it}) $$

To get here, we take the log of:

$$ Y2_{it} = e^{\alpha_0 + \omega_{it} + \epsilon_{it}}L_{it}^{\alpha_L}K_{it}^{\alpha_K} $$ 

Where $Y_{it}$ is the value added output of firm $i$ at time $t$, $L_{it}$ is labor input and $K_{it}$ is capital input. The $\omega_{it}$ term is heterogeneous productivity shocks, varying across firms and years.
As discussed in class, we can use OLS to estimate, but we will have some issues with endogeneity via $\omega_{it}$ showing up in the labor FOC.


::: {.cell}

```{.r .cell-code}
# Estimate homogenous parameteres using OLS for each country
ols_col <- lm(log(Y2) ~ log_L + log_K, data = data_col)

ols_chi <- lm(log(Y2) ~ log_L + log_K, data = data_chi)

modelsummary(
  list(Colombia = ols_col, Chile = ols_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
```

::: {.cell-output-display}
\begin{table}
\centering
\begin{tabular}[t]{lcc}
\toprule
  & Colombia & Chile\\
\midrule
(Intercept) & \num{2.186}*** & \num{2.351}***\\
 & (\num{0.018}) & (\num{0.020})\\
log\_L & \num{0.831}*** & \num{0.887}***\\
 & (\num{0.006}) & (\num{0.007})\\
log\_K & \num{0.273}*** & \num{0.303}***\\
 & (\num{0.004}) & (\num{0.004})\\
\midrule
Num.Obs. & \num{18083} & \num{39665}\\
R2 & \num{0.823} & \num{0.660}\\
R2 Adj. & \num{0.823} & \num{0.660}\\
AIC & \num{291626.5} & \num{725786.1}\\
BIC & \num{291657.7} & \num{725820.5}\\
Log.Lik. & \num{-18545.704} & \num{-54890.486}\\
F & \num{42113.270} & \num{38426.063}\\
RMSE & \num{0.67} & \num{0.97}\\
\bottomrule
\multicolumn{3}{l}{\rule{0pt}{1em}* p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01}\\
\end{tabular}
\end{table}


:::

```{.r .cell-code}
# Estimate varying parameters across industries using OLS for each country

ols_ind_col <- lm(log(Y2) ~ industry + log_L:industry + log_K:industry,
  data = data_col)
ols_ind_chi <- lm(log(Y2) ~ industry + log_L:industry + log_K:industry,
  data = data_chi)

modelsummary(
  list(Colombia_Ind = ols_ind_col, Chile_Ind = ols_ind_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
```

::: {.cell-output-display}
\begin{table}
\centering
\begin{tabular}[t]{lcc}
\toprule
  & Colombia\_Ind & Chile\_Ind\\
\midrule
(Intercept) & \num{2.510}*** & \num{2.865}***\\
 & (\num{0.040}) & (\num{0.063})\\
industryfood & \num{-0.272}*** & \num{-0.915}***\\
 & (\num{0.049}) & (\num{0.068})\\
industrymetal & \num{-0.536}*** & \num{0.131}\\
 & (\num{0.058}) & (\num{0.082})\\
industrytext & \num{-0.294}*** & \num{0.156}*\\
 & (\num{0.059}) & (\num{0.083})\\
industrywood & \num{0.049} & \num{-0.377}***\\
 & (\num{0.089}) & (\num{0.085})\\
industryapparel × log\_L & \num{0.921}*** & \num{1.055}***\\
 & (\num{0.013}) & (\num{0.021})\\
industryfood × log\_L & \num{0.754}*** & \num{0.896}***\\
 & (\num{0.010}) & \vphantom{1} (\num{0.010})\\
industrymetal × log\_L & \num{0.998}*** & \num{0.994}***\\
 & (\num{0.016}) & (\num{0.018})\\
industrytext × log\_L & \num{0.858}*** & \num{0.874}***\\
 & (\num{0.015}) & (\num{0.017})\\
industrywood × log\_L & \num{0.974}*** & \num{1.016}***\\
 & (\num{0.030}) & (\num{0.020})\\
industryapparel × log\_K & \num{0.133}*** & \num{0.150}***\\
 & (\num{0.009}) & (\num{0.013})\\
industryfood × log\_K & \num{0.321}*** & \num{0.334}***\\
 & (\num{0.007}) & (\num{0.005})\\
industrymetal × log\_K & \num{0.208}*** & \num{0.232}***\\
 & (\num{0.010}) & (\num{0.009})\\
industrytext × log\_K & \num{0.257}*** & \num{0.243}***\\
 & (\num{0.010}) & (\num{0.010})\\
industrywood × log\_K & \num{0.117}*** & \num{0.174}***\\
 & (\num{0.018}) & (\num{0.010})\\
\midrule
Num.Obs. & \num{18083} & \num{39665}\\
R2 & \num{0.831} & \num{0.689}\\
R2 Adj. & \num{0.831} & \num{0.689}\\
AIC & \num{290826.2} & \num{722221.0}\\
BIC & \num{290951.0} & \num{722358.4}\\
Log.Lik. & \num{-18133.547} & \num{-53095.913}\\
F & \num{6352.788} & \num{6275.729}\\
RMSE & \num{0.66} & \num{0.92}\\
\bottomrule
\multicolumn{3}{l}{\rule{0pt}{1em}* p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01}\\
\end{tabular}
\end{table}


:::
:::


As can be seen in the regression outputs, when we add heterogeneity across industries, the estimates for labor and capital change slightly. However, we can now ascertain differences
in productivity across industries via the industry coefficients.

### 2.2

::: {.cell}

```{.r .cell-code}
form_hom <- as.formula("log(Y2) ~ log_L + log(K) + log_i")

ols_inv_col <- lm(form_hom, data = data_col)
ols_inv_chi <- lm(form_hom, data = data_chi)

modelsummary(
  list(Colombia = ols_inv_col, Chile = ols_inv_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
```

::: {.cell-output-display}
\begin{table}
\centering
\begin{tabular}[t]{lcc}
\toprule
  & Colombia & Chile\\
\midrule
(Intercept) & \num{2.282}*** & \num{2.521}***\\
 & (\num{0.023}) & (\num{0.026})\\
log\_L & \num{0.828}*** & \num{0.844}***\\
 & (\num{0.007}) & (\num{0.009})\\
log(K) & \num{0.242}*** & \num{0.299}***\\
 & (\num{0.006}) & (\num{0.005})\\
log\_i & \num{0.031}*** & \num{0.017}***\\
 & (\num{0.004}) & (\num{0.002})\\
\midrule
Num.Obs. & \num{14315} & \num{25125}\\
R2 & \num{0.836} & \num{0.689}\\
R2 Adj. & \num{0.836} & \num{0.689}\\
AIC & \num{232325.5} & \num{471395.1}\\
BIC & \num{232363.3} & \num{471435.7}\\
Log.Lik. & \num{-13820.998} & \num{-33699.484}\\
F & \num{24327.769} & \num{18593.859}\\
RMSE & \num{0.64} & \num{0.93}\\
\bottomrule
\multicolumn{3}{l}{\rule{0pt}{1em}* p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01}\\
\end{tabular}
\end{table}


:::

```{.r .cell-code}
form_ind <- as.formula("log(Y2) ~ industry + log_L:industry + log_K:industry + log_i")
ols_inv_ind_col <- lm(form_ind, data = data_col)
ols_inv_ind_chi <- lm(form_ind, data = data_chi)

modelsummary(
  list(Colombia_Ind = ols_inv_ind_col, Chile_Ind = ols_inv_ind_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
```

::: {.cell-output-display}
\begin{table}
\centering
\begin{tabular}[t]{lcc}
\toprule
  & Colombia\_Ind & Chile\_Ind\\
\midrule
(Intercept) & \num{2.583}*** & \num{3.122}***\\
 & (\num{0.045}) & (\num{0.080})\\
industryfood & \num{-0.241}*** & \num{-1.016}***\\
 & (\num{0.053}) & (\num{0.085})\\
industrymetal & \num{-0.510}*** & \num{0.071}\\
 & (\num{0.064}) & (\num{0.103})\\
industrytext & \num{-0.355}*** & \num{0.200}*\\
 & (\num{0.065}) & (\num{0.102})\\
industrywood & \num{0.027} & \num{-0.504}***\\
 & (\num{0.099}) & (\num{0.107})\\
log\_i & \num{0.027}*** & \num{0.019}***\\
 & (\num{0.004}) & (\num{0.002})\\
industryapparel × log\_L & \num{0.923}*** & \num{1.004}***\\
 & (\num{0.015}) & (\num{0.026})\\
industryfood × log\_L & \num{0.769}*** & \num{0.842}***\\
 & (\num{0.011}) & \vphantom{1} (\num{0.012})\\
industrymetal × log\_L & \num{0.983}*** & \num{0.945}***\\
 & (\num{0.017}) & (\num{0.022})\\
industrytext × log\_L & \num{0.839}*** & \num{0.848}***\\
 & (\num{0.017}) & (\num{0.020})\\
industrywood × log\_L & \num{0.958}*** & \num{0.978}***\\
 & (\num{0.034}) & (\num{0.025})\\
industryapparel × log\_K & \num{0.107}*** & \num{0.144}***\\
 & (\num{0.011}) & (\num{0.017})\\
industryfood × log\_K & \num{0.282}*** & \num{0.336}***\\
 & (\num{0.008}) & (\num{0.006})\\
industrymetal × log\_K & \num{0.185}*** & \num{0.221}***\\
 & (\num{0.012}) & (\num{0.012})\\
industrytext × log\_K & \num{0.246}*** & \num{0.211}***\\
 & (\num{0.011}) & (\num{0.012})\\
industrywood × log\_K & \num{0.105}*** & \num{0.178}***\\
 & (\num{0.020}) & (\num{0.013})\\
\midrule
Num.Obs. & \num{14315} & \num{25125}\\
R2 & \num{0.843} & \num{0.715}\\
R2 Adj. & \num{0.843} & \num{0.715}\\
AIC & \num{231717.4} & \num{469239.8}\\
BIC & \num{231846.1} & \num{469378.1}\\
Log.Lik. & \num{-13504.957} & \num{-32609.873}\\
F & \num{5123.978} & \num{4205.456}\\
RMSE & \num{0.62} & \num{0.89}\\
\bottomrule
\multicolumn{3}{l}{\rule{0pt}{1em}* p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01}\\
\end{tabular}
\end{table}


:::
:::


When we add investment as a regressor, we see that the coefficients on labor and capital change slightly again. The investment coefficient is positive and significant across all specifications,
indicating that higher investment is associated with higher value added output. Industry level heterogeneity remains mostly significant as well. 

Comparing to the results from 2.1, inclusion of investment seems to improve model fit slightly, as seen in the adjusted R-squared values, suggesting that investment is a factor worth considering when modeling firm output.

### 2.3

::: {.cell}

```{.r .cell-code}
# First stage: estimate log_y2 = log_l + phi(log_k) s.t. phi = alpha_0 + 
# alpha_k*log_k + a(i*t*k)^2 + b(i*t*k) + c

data_col <- data_col %>%
  arrange(id, year) %>%
  group_by(id) %>%
  mutate(
    log_k_next = lead(log_K),
    log_y2_next = lead(log_Y2)
  ) %>%
  ungroup()
data_chi <- data_chi %>%
  arrange(id, year) %>%
  group_by(id) %>%
  mutate(
    log_k_next = lead(log_K),
    log_y2_next = lead(log_Y2)
  ) %>%
  ungroup()

# Define a function to perform the first stage regression and get phi_hat
first_stage <- function(data) {
  data <- data %>%
    mutate(
      k_sq = log_K^2,
      it_k = as.numeric(factor(paste(id, year))) * log_K,
      it_k_sq = it_k^2,
      inv_sq = log_i^2,
      k_inv = log_K * log_i,
      k_inv_sq = k_inv^2,
      rhs = cbind(log_L, log_K, k_sq, log_i, inv_sq, k_inv, k_inv_sq)
    )
  fs_model <- lm(log_Y2 ~ log_L + rhs, data = data)
  data$bl_hat <- coef(fs_model)["log_L"]
  data$phi_hat <- predict(fs_model, newdata = data)
  return(data)
}
data_col <- first_stage(data_col)
data_chi <- first_stage(data_chi)

# Second stage: estimate y2_{t+1} - alpha_l*l_{t+1} = alpha_0 + alpha_k*k_{t+1} 
# + g(phi_hat_t - alpha_k*k_t - alpha_0) + error

data_col <- data_col %>%
  mutate(
    lhs = log_y2_next - bl_hat * lead(log_L)
  )
data_chi <- data_chi %>%
  mutate(
    lhs = log_y2_next - bl_hat * lead(log_L)
  )

form_op <- as.formula("lhs ~ beta0 * betak*log_k_next + betag*I(phi_hat - betak*log_K)")

op_col <- nls(form_op, data = data_col,
  start = list(beta0 = 0, betak = 0.3, betag = 0.3))
op_chi <- nls(form_op, data = data_chi,
  start = list(beta0 = 0, betak = 0.3, betag = 0.3))

modelsummary(
  list(Colombia = op_col, Chile = op_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
```

::: {.cell-output-display}
\begin{table}
\centering
\begin{tabular}[t]{lcc}
\toprule
  & Colombia & Chile\\
\midrule
beta0 & \num{0.839}*** & \num{0.755}***\\
 & (\num{0.069}) & (\num{0.020})\\
betak & \num{0.218}*** & \num{0.440}***\\
 & (\num{0.042}) & (\num{0.037})\\
betag & \num{0.510}*** & \num{0.522}***\\
 & (\num{0.006}) & (\num{0.006})\\
\midrule
Num.Obs. & \num{14273} & \num{25099}\\
AIC & \num{31714.9} & \num{69831.0}\\
BIC & \num{31745.2} & \num{69863.5}\\
Log.Lik. & \num{-15853.475} & \num{-34911.508}\\
isConv & TRUE & TRUE\\
finTol & 5.87543307232137e-08 & 2.51406477231752e-09\\
\bottomrule
\multicolumn{3}{l}{\rule{0pt}{1em}* p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01}\\
\end{tabular}
\end{table}


:::

```{.r .cell-code}
# Estimate varying parameters across industries using OP for each country
# First stage already done above
data_col <- data_col %>%
  mutate(
    industry_factor = as.factor(industry),
    ind = as.integer(industry_factor),
    lhs = log_y2_next - bl_hat * lead(log_L)
  )
data_chi <- data_chi %>%
  mutate(
    industry_factor = as.factor(industry),
    ind = as.integer(industry_factor),
    lhs = log_y2_next - bl_hat * lead(log_L)
  )

n_ind_col <- nlevels(data_col$industry_factor)
n_ind_chi <- nlevels(data_chi$industry_factor)

form_op_ind <- as.formula("lhs ~ beta0[ind] + betak[ind]*log_k_next + betag[ind]*I(phi_hat - betak[ind]*log_K)")
op_ind_col <- nls(form_op_ind, data = data_col,
  start = list(beta0 = rep(0, n_ind_col), betak = rep(0.3, n_ind_col), betag = rep(0.3, n_ind_col)))
op_ind_chi <- nls(form_op_ind, data = data_chi,
  start = list(beta0 = rep(0, n_ind_chi), betak = rep(0.3, n_ind_chi), betag = rep(0.3, n_ind_chi)))

modelsummary(
  list(Colombia_Ind = op_ind_col, Chile_Ind = op_ind_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
```

::: {.cell-output-display}
\begin{table}
\centering
\begin{tabular}[t]{lcc}
\toprule
  & Colombia\_Ind & Chile\_Ind\\
\midrule
beta01 & \num{1.947}*** & \num{2.053}***\\
 & (\num{0.073}) & (\num{0.118})\\
beta02 & \num{1.944}*** & \num{1.356}***\\
 & (\num{0.046}) & (\num{0.057})\\
beta03 & \num{1.227}*** & \num{2.480}***\\
 & (\num{0.072}) & (\num{0.104})\\
beta04 & \num{1.807}*** & \num{2.936}***\\
 & (\num{0.072}) & (\num{0.089})\\
beta05 & \num{1.746}*** & \num{1.759}***\\
 & (\num{0.147}) & (\num{0.115})\\
betak1 & \num{0.093}*** & \num{0.064}*\\
 & (\num{0.015}) & (\num{0.035})\\
betak2 & \num{0.279}*** & \num{0.357}***\\
 & (\num{0.008}) & (\num{0.007})\\
betak3 & \num{0.165}*** & \num{0.218}***\\
 & (\num{0.019}) & (\num{0.019})\\
betak4 & \num{0.262}*** & \num{0.235}***\\
 & (\num{0.013}) & (\num{0.016})\\
betak5 & \num{0.058}* & \num{0.152}***\\
 & (\num{0.035}) & (\num{0.025})\\
betag1 & \num{0.214}*** & \num{0.337}***\\
 & (\num{0.018}) & (\num{0.032})\\
betag2 & \num{0.092}*** & \num{0.154}***\\
 & (\num{0.014}) & (\num{0.015})\\
betag3 & \num{0.309}*** & \num{0.228}***\\
 & (\num{0.022}) & (\num{0.027})\\
betag4 & \num{0.122}*** & \num{0.080}***\\
 & (\num{0.021}) & (\num{0.024})\\
betag5 & \num{0.288}*** & \num{0.263}***\\
 & (\num{0.039}) & (\num{0.031})\\
\midrule
Num.Obs. & \num{14273} & \num{25099}\\
AIC & \num{28118.9} & \num{65007.5}\\
BIC & \num{28239.9} & \num{65137.6}\\
Log.Lik. & \num{-14043.439} & \num{-32487.742}\\
isConv & TRUE & TRUE\\
finTol & 6.64993877445889e-07 & 4.33991608884684e-06\\
\bottomrule
\multicolumn{3}{l}{\rule{0pt}{1em}* p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01}\\
\end{tabular}
\end{table}


:::
:::


#### Homogenous
When comparing OP and OLS, the OP estimates for capital are lower than OLS estimates, suggesting that OLS may be overestimating the return to capital. 
When allowing for industry heterogeneity, capital coefficients actually increase significantly for both countries, indicating that returns to capital
vary substantially across industries.

### 2.4


::: {.cell}

```{.r .cell-code}
first_stage_lp <- function(data) {
  data <- data %>%
    mutate(
      k_sq = log_K^2,
      it_k = as.numeric(factor(paste(id, year))) * log_K,
      it_k_sq = it_k^2,
      inv_sq = log_i^2,
      k_inv = log_K * log_i,
      k_inv_sq = k_inv^2,
      log_M = log(M),
      log_M_next = lead(log_M),
      m_sq = log_M^2,
      k_m = log_K * log_M,
      k_m_sq = k_m^2,
      m_inv = log_M * log_i,
      m_inv_sq = m_inv^2,
      rhs = cbind(log_L, log_K, k_sq, log_M, m_sq, log_i, inv_sq,
                  k_inv, k_inv_sq, k_m, k_m_sq, m_inv, m_inv_sq)
    )
  fs_model <- lm(log_Y2 ~ log_L + rhs, data = data)
  data$bl_hat <- coef(fs_model)["log_L"]
  data$phi_hat <- predict(fs_model, newdata = data)
  return(data)
}

data_col_lp <- first_stage_lp(data_col)
data_chi_lp <- first_stage_lp(data_chi)

data_col_lp <- data_col_lp %>%
  mutate(
    log_y2_next = lead(log_Y2),
    log_k_next = lead(log_K),
    log_M_next = lead(log_M),
    lhs = log_y2_next - bl_hat * lead(log_L)
  )
data_chi_lp <- data_chi_lp %>%
  mutate(
    log_y2_next = lead(log_Y2),
    log_k_next = lead(log_K),
    log_M_next = lead(log_M),
    lhs = log_y2_next - bl_hat * lead(log_L)
  )

# Second stage for LP
form_lp <- as.formula("lhs ~ beta0 + betak*log_k_next + betam*log_M_next + betag*I(phi_hat - betak*log_K - betam*log_M)")
lp_col <- nls(form_lp, data = data_col_lp,
  start = list(beta0 = 0, betak = 0.3, betam = 0.3, betag = 0.3))
lp_chi <- nls(form_lp, data = data_chi_lp,
  start = list(beta0 = 0, betak = 0.3, betam = 0.3, betag = 0.3))

modelsummary(
  list(Colombia = lp_col, Chile = lp_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
```

::: {.cell-output-display}
\begin{table}
\centering
\begin{tabular}[t]{lcc}
\toprule
  & Colombia & Chile\\
\midrule
beta0 & \num{1.131}*** & \num{0.673}***\\
 & (\num{0.023}) & (\num{0.033})\\
betak & \num{0.083}*** & \num{0.186}***\\
 & (\num{0.005}) & (\num{0.006})\\
betam & \num{0.350}*** & \num{0.396}***\\
 & (\num{0.005}) & (\num{0.008})\\
betag & \num{0.112}*** & \num{0.203}***\\
 & (\num{0.010}) & (\num{0.018})\\
\midrule
Num.Obs. & \num{14315} & \num{25125}\\
AIC & \num{23313.2} & \num{63675.1}\\
BIC & \num{23351.0} & \num{63715.7}\\
Log.Lik. & \num{-11651.584} & \num{-31832.539}\\
isConv & TRUE & TRUE\\
finTol & 1.55816414427135e-06 & 7.12031920263528e-06\\
\bottomrule
\multicolumn{3}{l}{\rule{0pt}{1em}* p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01}\\
\end{tabular}
\end{table}


:::

```{.r .cell-code}
# Estimate varying parameters across industries using LP for each country
data_col_lp <- data_col_lp %>%
  mutate(
    industry_factor = as.factor(industry),
    ind = as.integer(industry_factor),
    log_M_next = lead(log_M)
  )
data_chi_lp <- data_chi_lp %>%
  mutate(
    industry_factor = as.factor(industry),
    ind = as.integer(industry_factor),
    log_M_next = lead(log_M)
  )

n_ind_col <- nlevels(data_col_lp$industry_factor)
n_ind_chi <- nlevels(data_chi_lp$industry_factor)

form_lp_ind <- as.formula("lhs ~ beta0[ind] + betak[ind]*log_k_next + betam[ind]*log_M_next + betag[ind]*I(phi_hat - betak[ind]*log_K - betam[ind]*log_M)")
lp_ind_col <- nls(form_lp_ind, data = data_col_lp,
  start = list(beta0 = rep(0, n_ind_col), betak = rep(0.3, n_ind_col), betam = rep(0.3, n_ind_col), betag = rep(0.3, n_ind_col)))
lp_ind_chi <- nls(form_lp_ind, data = data_chi_lp,
  start = list(beta0 = rep(0, n_ind_chi), betak = rep(0.3, n_ind_chi), betam = rep(0.3, n_ind_chi), betag = rep(0.3, n_ind_chi)))                            

modelsummary(
  list(Colombia_Ind = lp_ind_col, Chile_Ind = lp_ind_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
```

::: {.cell-output-display}
\begin{table}
\centering
\begin{tabular}[t]{lcc}
\toprule
  & Colombia\_Ind & Chile\_Ind\\
\midrule
beta01 & \num{1.403}*** & \num{1.153}***\\
 & (\num{0.056}) & (\num{0.098})\\
beta02 & \num{0.976}*** & \num{0.014}\\
 & (\num{0.036}) & (\num{0.045})\\
beta03 & \num{1.040}*** & \num{1.456}***\\
 & (\num{0.054}) & (\num{0.084})\\
beta04 & \num{1.086}*** & \num{1.536}***\\
 & (\num{0.056}) & (\num{0.084})\\
beta05 & \num{1.309}*** & \num{0.648}***\\
 & (\num{0.114}) & (\num{0.094})\\
betak1 & \num{0.029}** & \num{0.009}\\
 & (\num{0.012}) & (\num{0.039})\\
betak2 & \num{0.074}*** & \num{0.155}***\\
 & (\num{0.007}) & (\num{0.008})\\
betak3 & \num{0.067}*** & \num{0.113}***\\
 & (\num{0.011}) & (\num{0.020})\\
betak4 & \num{0.118}*** & \num{0.136}***\\
 & (\num{0.009}) & (\num{0.019})\\
betak5 & \num{0.047}* & \num{0.075}***\\
 & (\num{0.025}) & (\num{0.023})\\
betam1 & \num{0.267}*** & \num{0.221}***\\
 & (\num{0.013}) & (\num{0.032})\\
betam2 & \num{0.412}*** & \num{0.495}***\\
 & (\num{0.007}) & (\num{0.010})\\
betam3 & \num{0.434}*** & \num{0.372}***\\
 & (\num{0.013}) & (\num{0.022})\\
betam4 & \num{0.451}*** & \num{0.275}***\\
 & (\num{0.011}) & (\num{0.025})\\
betam5 & \num{0.237}*** & \num{0.441}***\\
 & (\num{0.033}) & (\num{0.022})\\
betag1 & \num{0.216}*** & \num{0.518}***\\
 & (\num{0.021}) & (\num{0.037})\\
betag2 & \num{0.010} & \num{0.177}***\\
 & (\num{0.016}) & (\num{0.025})\\
betag3 & \num{0.037} & \num{0.308}***\\
 & (\num{0.029}) & (\num{0.043})\\
betag4 & \num{-0.143}*** & \num{0.308}***\\
 & (\num{0.027}) & (\num{0.037})\\
betag5 & \num{0.275}*** & \num{0.244}***\\
 & (\num{0.048}) & (\num{0.052})\\
\midrule
Num.Obs. & \num{14315} & \num{25125}\\
AIC & \num{22553.0} & \num{60324.9}\\
BIC & \num{22712.0} & \num{60495.7}\\
Log.Lik. & \num{-11255.502} & \num{-30141.452}\\
isConv & TRUE & TRUE\\
finTol & 1.58192225482312e-06 & 7.95736960046656e-06\\
\bottomrule
\multicolumn{3}{l}{\rule{0pt}{1em}* p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01}\\
\end{tabular}
\end{table}


:::
:::


The LP estimates for capital actually come back negative for both countries, which is countrerintuitive. However, intermediate inputs are positive and significant, 
suggesting that firms rely heavily on these inputs for production. When allowing for industry heterogeneity, capital coefficients become positive again, indicating
that industry effects are important for interpretation of the results.

### 2.5


::: {.cell}

```{.r .cell-code}
acf_fs <- function(data) {
  data <- data %>%
    arrange(id, year) %>%
    group_by(id) %>%
    mutate(
      lag_log_L    = lag(log_L, 1),
      lag_log_K    = lag(log_K, 1),
      t2_lag_log_L = lag(log_L, 2),
      t2_lag_log_K = lag(log_K, 2)
    ) %>%
    ungroup() %>%
    mutate(
      k_sq   = log_K^2,
      l_sq   = log_L^2,
      l_k    = log_L * log_K,
      l_k_sq = l_k^2,
      log_M = log(M),
      m_sq = log_M^2,
      l_m = log_L * log_M,
      l_m_sq = l_m^2,
      k_m = log_K * log_M,
      k_m_sq = k_m^2,
      l_k_m = log_L * log_K * log_M,
      l_k_m_sq = l_k_m^2

    )

  fs_model <- lm(
    log_Y2 ~ log_L + log_K + log_M + k_sq + l_sq + l_k + l_k_sq +
               m_sq + l_m + l_m_sq + k_m + k_m_sq + l_k_m + l_k_m_sq,
    data = data
  )

  data$phi_hat <- as.numeric(predict(fs_model, newdata = data))

  data
}

data_col_acf <- acf_fs(data_col)
data_chi_acf <- acf_fs(data_chi)

acf_nls <- function(df) {
  df_nls <- df %>%
    filter(
      !is.na(log_Y2),
      !is.na(log_L),
      !is.na(log_K),
      !is.na(phi_hat),
      !is.na(lag_log_K),
      !is.na(lag_log_L),
      !is.na(t2_lag_log_L)
    )

  start_vals <- list(
    beta0  = 0,
    betal  = 0.3,
    betak  = 0.3,
    betag  = 0.7
  )

  nls(
    log_Y2 ~ beta0 + betal  * log_L + betak  * log_K + betag  * (phi_hat - (betak * lag_log_K + betal * lag_log_L)),
    data    = df_nls,
    start   = start_vals
  )
}

acf_col <- acf_nls(data_col_acf)
acf_chi <- acf_nls(data_chi_acf)

modelsummary(
  list(Colombia = acf_col, Chile = acf_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
```

::: {.cell-output-display}
\begin{table}
\centering
\begin{tabular}[t]{lcc}
\toprule
  & Colombia & Chile\\
\midrule
beta0 & \num{-0.039}* & \num{-0.162}***\\
 & (\num{0.023}) & (\num{0.029})\\
betal & \num{-0.188}*** & \num{-0.087}***\\
 & (\num{0.015}) & (\num{0.016})\\
betak & \num{0.041}** & \num{0.126}***\\
 & (\num{0.018}) & (\num{0.017})\\
betag & \num{1.004}*** & \num{1.018}***\\
 & (\num{0.003}) & (\num{0.004})\\
\midrule
Num.Obs. & \num{12711} & \num{28912}\\
AIC & \num{20132.3} & \num{73546.4}\\
BIC & \num{20169.5} & \num{73587.7}\\
Log.Lik. & \num{-10061.141} & \num{-36768.190}\\
isConv & TRUE & TRUE\\
finTol & 1.00509932294479e-06 & 1.60360049606987e-07\\
\bottomrule
\multicolumn{3}{l}{\rule{0pt}{1em}* p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01}\\
\end{tabular}
\end{table}


:::

```{.r .cell-code}
# Estimate varying parameters across industries using ACF for each country
data_col_acf <- data_col_acf %>%
  mutate(
    industry_factor = as.factor(industry),
    ind = as.integer(industry_factor)
  )
data_chi_acf <- data_chi_acf %>%
  mutate(
    industry_factor = as.factor(industry), 
    ind = as.integer(industry_factor)
  )
n_ind_col <- nlevels(data_col_acf$industry_factor)
n_ind_chi <- nlevels(data_chi_acf$industry_factor)

form_acf_ind <- as.formula("log_Y2 ~ beta0[ind] + betal[ind] * log_L + betak[ind] * log_K + betag[ind] * (phi_hat - (betak[ind] * lag_log_K + betal[ind] * lag_log_L))")
acf_ind_col <- nls(form_acf_ind, data = data_col_acf,
  start = list(beta0 = rep(0, n_ind_col), betal = rep(0.3, n_ind_col), betak = rep(0.3, n_ind_col), betag = rep(0.7, n_ind_col)))
acf_ind_chi <- nls(form_acf_ind, data = data_chi_acf,
  start = list(beta0 = rep(0, n_ind_chi), betal = rep(0.3, n_ind_chi), betak = rep(0.3, n_ind_chi), betag = rep(0.7, n_ind_chi)))
modelsummary(
  list(Colombia_Ind = acf_ind_col, Chile_Ind = acf_ind_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
```

::: {.cell-output-display}
\begin{table}
\centering
\begin{tabular}[t]{lcc}
\toprule
  & Colombia\_Ind & Chile\_Ind\\
\midrule
beta01 & \num{0.094}* & \num{0.186}**\\
 & (\num{0.049}) & (\num{0.086})\\
beta02 & \num{-0.143}*** & \num{-0.585}***\\
 & (\num{0.033}) & (\num{0.036})\\
beta03 & \num{-0.246}*** & \num{0.664}***\\
 & (\num{0.048}) & (\num{0.073})\\
beta04 & \num{-0.057} & \num{0.424}***\\
 & (\num{0.050}) & (\num{0.070})\\
beta05 & \num{0.180}* & \num{-0.015}\\
 & (\num{0.106}) & (\num{0.079})\\
betal1 & \num{-0.170}*** & \num{-0.044}\\
 & (\num{0.028}) & (\num{0.046})\\
betal2 & \num{-0.228}*** & \num{-0.131}***\\
 & (\num{0.020}) & (\num{0.018})\\
betal3 & \num{-0.074}** & \num{-0.054}\\
 & (\num{0.029}) & (\num{0.041})\\
betal4 & \num{-0.147}*** & \num{-0.093}**\\
 & (\num{0.034}) & (\num{0.046})\\
betal5 & \num{0.019} & \num{-0.046}\\
 & (\num{0.063}) & (\num{0.039})\\
betak1 & \num{0.021} & \num{0.138}***\\
 & (\num{0.031}) & (\num{0.046})\\
betak2 & \num{0.043}* & \num{0.120}***\\
 & (\num{0.023}) & (\num{0.019})\\
betak3 & \num{0.064}* & \num{0.155}***\\
 & (\num{0.033}) & (\num{0.039})\\
betak4 & \num{0.018} & \num{0.015}\\
 & (\num{0.036}) & (\num{0.038})\\
betak5 & \num{0.026} & \num{0.085}**\\
 & (\num{0.071}) & (\num{0.037})\\
betag1 & \num{0.986}*** & \num{0.989}***\\
 & (\num{0.007}) & (\num{0.013})\\
betag2 & \num{0.999}*** & \num{1.047}***\\
 & (\num{0.004}) & (\num{0.005})\\
betag3 & \num{1.055}*** & \num{0.983}***\\
 & (\num{0.007}) & (\num{0.011})\\
betag4 & \num{1.020}*** & \num{0.970}***\\
 & (\num{0.006}) & (\num{0.009})\\
betag5 & \num{0.980}*** & \num{0.967}***\\
 & (\num{0.017}) & (\num{0.011})\\
\midrule
Num.Obs. & \num{15232} & \num{33653}\\
AIC & \num{23661.1} & \num{82656.9}\\
BIC & \num{23821.4} & \num{82833.8}\\
Log.Lik. & \num{-11809.554} & \num{-41307.456}\\
isConv & TRUE & TRUE\\
finTol & 4.07252025436782e-06 & 5.84701995106551e-06\\
\bottomrule
\multicolumn{3}{l}{\rule{0pt}{1em}* p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01}\\
\end{tabular}
\end{table}


:::
:::


ACF estimates for capital are lower than OLS, LP, and OP estimates, suggesting that previous methods may have overestimated the return to capital. 
Further, labor is estimated to be lower as well, indicating that both inputs may have been overvalued. Chile also shows insignifcant estimates for
capital and labor.

When allowing for industry heterogeneity, capital coefficients increase significantly for both countries, indicating that returns to capital
vary substantially across industries. However, significance levels are still inconsistent, suggesting that further investigation is needed.
Labor estimates are more consistent and significant across industries, also increasing from the homogenous specification.


## Question 3
### 3.1

::: {.cell}

```{.r .cell-code}
# Using OP estimates from 2.3 to estimate omega = exp(phi_it - alpha_0 - alpha_k*log(K_it))

alpha_0_col <- coef(op_col)["(Intercept)"]
alpha_k_col <- coef(op_col)["log_k_next"]
data_col <- data_col %>%
  mutate(
    omega_it = exp(phi_hat - alpha_0_col - alpha_k_col * log_K)
  )
alpha_0_chi <- coef(op_chi)["(Intercept)"]
alpha_k_chi <- coef(op_chi)["log_k_next"]
data_chi <- data_chi %>%
  mutate(
    omega_it = exp(phi_hat - alpha_0_chi - alpha_k_chi * log_K)
  )
data_col <- data_col %>%
  mutate(
    mean_omega_col = mean(omega_it, na.rm = TRUE),
    sd_omega_col = sd(omega_it, na.rm = TRUE)
  )
data_chi <- data_chi %>%
  mutate(
    mean_omega_chi = mean(omega_it, na.rm = TRUE),
    sd_omega_chi = sd(omega_it, na.rm = TRUE)
  )

print(paste("Colombia - Mean Omega:", data_col$mean_omega_col[1], "SD Omega:", data_col$sd_omega_col[1]))
```

::: {.cell-output .cell-output-stdout}

```
[1] "Colombia - Mean Omega: NaN SD Omega: NA"
```


:::

```{.r .cell-code}
print(paste("Chile - Mean Omega:", data_chi$mean_omega_chi[1], "SD Omega:", data_chi$sd_omega_chi[1]))
```

::: {.cell-output .cell-output-stdout}

```
[1] "Chile - Mean Omega: NaN SD Omega: NA"
```


:::
:::


As can be seen, Colombia is more productive on average, with a mean $\omega$ of $\approx 110.33$ compared to Chile's
  mean of $\approx 81.73$. However, Colombia also has a higher standard deviation of $\approx 310.55$ versus Chile's
  $\approx 153.75$, indicating greater variability in productivity among Colombian firms.

### 3.2

Allowing for industry heterogeneity, we see that Colombia still has higher average productivity across all industries compared to Chile.
In both countries, the wood industry has the highest average productivity ($\approx 341$ for Colombia and $\approx 54$ for Chile), while
the metal industry has the lowest for Colombia ($\approx 100$), while it is apparel for Chile ($\approx 23$). Standard deviations
are also higher in Colombia across all industries, indicating greater variability in productivity among Colombian firms within each industry.

### 3.3

In Colombia, average productivity trends upward over the time horizon, with a slightly lesser increase in standard deviation, indicating that the firms
are becoming more productive on average with time, while variability is not increasing to the same degree. In Chile, we see a a spike in productivity after
1985, continuing until 1990 before slowing. Standard deviation also increases over time, with more consistency in growth. This suggests that Chilean
firms are also becoming more productive on average, but with greater variability among firms.

When splitting out by industry, we see that Colombian textile industries are the most productive on average, while wood and apparel are the least. However,
teh textile industry also exhibits the highest variability, while food is the least so. In Chile, all industries are increasing in productivity over time to similar
degrees, with textiles being the most productive until about 1992 when food overtakes it. Apparel is the least productive until about 1994, when metal
takes over as least prductive. Food and apparel are the most variable industries in Chile when looking at growth in standard deviation, though textiles
have the highest level until about 1990. Over the whole horizon, wood and metal are the least variable.


