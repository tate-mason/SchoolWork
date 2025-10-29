






knitr::opts_chunk$set(echo = TRUE)






# Load necessary libraries
library(dplyr)
library(ggplot2)
library(readr)
library(lubridate)
library(here)
# Load the dataset
data <- read_csv(here("Y2S1/IO/ps2/data", "prod_data_all.csv"))
# Clean dataset to harmonize year discrepancy - 1981 = 81
data <- data %>%
  mutate(year = ifelse(year < 100, year + 1900, year))

# Display the first few rows of the dataset
head(data)




#| label: 1-1 Summary Statistics
# Summary Statistics of the data
data %>%
  group_by(country, industry) %>%
  summarize(
    total_obs_sect = n_distinct(id),
    .groups = 'drop'
  ) %>%
  ungroup() %>%
  arrange(country, industry)

data %>%
  group_by(year, industry) %>%
  summarize(
    n_obs_t = n_distinct(id),
    .groups = 'drop'
  ) %>%
  ungroup() %>%
  arrange(year, industry) %>%
  print()
























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
  labs(title = "Histogram of Log Investment by Industry",
       x = "Log Investment",
       y = "Frequency") +
  theme_minimal()

ggplot(data_chi, aes(x = log_i)) +
  geom_histogram(binwidth = 0.5, fill = "green", color = "black", alpha = 0.7) +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Histogram of Log Investment by Industry",
       x = "Log Investment",
       y = "Frequency") +
  theme_minimal()







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
  labs(title = "Histogram of Log Output by Industry",
       x = "Log Output",
       y = "Frequency") +
  theme_minimal()
ggplot(data_chi, aes(x = log_Y)) +
  geom_histogram(binwidth = 0.5, fill = "green", color = "black", alpha = 0.7) +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Histogram of Log Output by Industry",
       x = "Log Output",
       y = "Frequency") +
  theme_minimal()




#| label: 1-4 Scatter Plots
# Scatter plot of log_Y and log_L for each sector in each country
data_col <- data_col %>%
  group_by(industry) %>%
  mutate(
    log_L = log(L),
  ) %>%
  ungroup()
data_chi <- data_chi %>%
  group_by(industry) %>%
  mutate(
    log_L = log(L),
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

ggplot(data_chi, aes(x = log_L, y = log_Y)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", color = "red") +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Scatter Plot of Log Output vs Log Labor (Chile)",
       x = "Log Labor",
       y = "Log Output") +
  theme_minimal()


















#| label: 2-1 OLS
# Estimate homogenous parameteres using OLS for each country
ols_col <- lm(log(Y2) ~ log_L + log(K), data = data_col)
summary(ols_col)

ols_chi <- lm(log(Y2) ~ log_L + log(K), data = data_chi)
summary(ols_chi)

# Estimate varying parameters across industries using OLS for each country
form <- as.formula("log(Y2) ~ log_L + log(K) + industry")

ols_ind_col <- lm(form, data = data_col)
summary(ols_ind_col)

ols_ind_chi <- lm(form, data = data_chi)
summary(ols_ind_chi)







#| label: 2-1 OLS w/ Investment
form_hom <- as.formula("log(Y2) ~ log_L + log(K) + log_i")
form_het <- as.formula("log(Y2) ~ log_L + log(K) + log_i + industry")

ols_inv_col <- lm(form_hom, data = data_col)
summary(ols_inv_col)
ols_inv_chi <- lm(form_hom, data = data_chi)
summary(ols_inv_chi)

ols_inv_ind_col <- lm(form_het, data = data_col)
summary(ols_inv_ind_col)
ols_inv_ind_chi <- lm(form_het, data = data_chi)
summary(ols_inv_ind_chi)









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
  fs_model <- lm(log_Y2 ~ rhs, data = data)
  data$phi_hat <- predict(fs_model, newdata = data)
  return(data)
}
data_col <- first_stage(data_col)
data_chi <- first_stage(data_chi)

# Second stage: estimate y2_{t+1} - alpha_l*l_{t+1} = alpha_0 + alpha_k*k_{t+1} 
# + g(phi_hat_t - alpha_k*k_t - alpha_0) + error

form_op <- as.formula("log_y2_next - log_L ~ log_k_next + I(phi_hat - log_K)")
op_col <- lm(form_op, data = data_col)
summary(op_col)
op_chi <- lm(form_op, data = data_chi)
summary(op_chi)

# Estimate varying parameters across industries using OP for each country
form_op_ind <- as.formula("log_y2_next - log_L ~ log_k_next + I(phi_hat - log_K) + industry")
op_ind_col <- lm(form_op_ind, data = data_col)
summary(op_ind_col)
op_ind_chi <- lm(form_op_ind, data = data_chi)
summary(op_ind_chi)




#| label: 2-4- Using LP Estimation 
first_stage_lp <- function(data) {
  data <- data %>%
    mutate(
      k_sq = log_K^2,
      log_m = log(M),
      m_sq = log_m^2,
      k_m = log_K * log_m,
      k_m_sq = k_m^2,
      rhs = cbind(log_L, log_K, k_sq, log_m, m_sq, k_m, k_m_sq)
    )
  lp_model <- lm(log_Y2 ~ rhs, data = data)
  data$phi_hat_lp <- predict(lp_model, newdata = data)
  return(data)
}
data_col <- first_stage_lp(data_col)
data_chi <- first_stage_lp(data_chi)

# Second stage: y2_{t+1} - alpha_l*l_{t+1} = alpha_0 + alpha_k*k_{t+1}
# + alpha_m*m_{t+1} + g(phi_hat_t - alpha_k*k_t - alpha_m*m_t - alpha_0) + error

form_lp <- as.formula("log_y2_next - log_L ~ log_k_next + log_m + I(phi_hat_lp - log_K - log_m)")
lp_col <- lm(form_lp, data = data_col)
summary(lp_col)
lp_chi <- lm(form_lp, data = data_chi)
summary(lp_chi)
# Estimate varying parameters across industries using LP for each country
form_lp_ind <- as.formula("log_y2_next - log_L ~ log_k_next + log_m + I(phi_hat_lp - log_K - log_m) + industry")
lp_ind_col <- lm(form_lp_ind, data = data_col)
summary(lp_ind_col)
lp_ind_chi <- lm(form_lp_ind, data = data_chi)
summary(lp_ind_chi)




#| label: 2-5 ACF Estimation
