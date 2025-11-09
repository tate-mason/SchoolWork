






knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)






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




#| label: 1-1 Summary Statistics
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
print(obs_by_sector_col)
print("Chile Observations by Sector:")
print(obs_by_sector_chi)

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
print(obs_by_year_sector_col)
























#| label: 1-2 Histograms of Investment
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
ggsave("1.2_col.pdf", width = 10, height = 6)

ggplot(data_chi, aes(x = log_i)) +
  geom_histogram(binwidth = 0.5, fill = "green", color = "black", alpha = 0.7) +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Histogram of Log Investment by Industry, Chile",
       x = "Log Investment",
       y = "Frequency") +
  theme_minimal()
ggsave("1.2_chi.pdf", width = 10, height = 6)









#| label: 1-3 Histograms of Output
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
ggsave("1.3_col.pdf", width = 10, height = 6)

ggplot(data_chi, aes(x = log_Y)) +
  geom_histogram(binwidth = 0.5, fill = "green", color = "black", alpha = 0.7) +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Histogram of Log Output by Industry, Chile",
       x = "Log Output",
       y = "Frequency") +
  theme_minimal()
ggsave("1.3_chi.pdf", width = 10, height = 6)








#| label: 1-4 Scatter Plots
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
ggsave("1.4_col.pdf", width = 10, height = 6)

ggplot(data_chi, aes(x = log_L, y = log_Y)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", color = "red") +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Scatter Plot of Log Output vs Log Labor (Chile)",
       x = "Log Labor",
       y = "Log Output") +
  theme_minimal()
ggsave("1.4_chi.pdf", width = 10, height = 6)






















#| label: 2-1 OLS
# Estimate homogenous parameteres using OLS for each country
ols_col <- lm(log(Y2) ~ log_L + log_K, data = data_col)

ols_chi <- lm(log(Y2) ~ log_L + log_K, data = data_chi)

modelsummary(
  list(Colombia = ols_col, Chile = ols_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
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







#| label: 2-1 OLS w/ Investment
form_hom <- as.formula("log(Y2) ~ log_L + log(K) + log_i")

ols_inv_col <- lm(form_hom, data = data_col)
ols_inv_chi <- lm(form_hom, data = data_chi)

modelsummary(
  list(Colombia = ols_inv_col, Chile = ols_inv_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)

form_ind <- as.formula("log(Y2) ~ industry + log_L:industry + log_K:industry + log_i")
ols_inv_ind_col <- lm(form_ind, data = data_col)
ols_inv_ind_chi <- lm(form_ind, data = data_chi)

modelsummary(
  list(Colombia_Ind = ols_inv_ind_col, Chile_Ind = ols_inv_ind_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)









#| label: 2-3 OP Estimation
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










#| label: 2-4 LP Estimation
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









#| label: 2-5 ACF Estimation
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














#| label: 3-1 Estimating ω
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
print(paste("Chile - Mean Omega:", data_chi$mean_omega_chi[1], "SD Omega:", data_chi$sd_omega_chi[1]))
