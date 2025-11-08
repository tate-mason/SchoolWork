






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
# Load the dataset
data <- read_csv(here("Y2S1/IO/ps2/data", "prod_data_all.csv"))
# Clean dataset to harmonize year discrepancy - 1981 = 81
data <- data %>%
  mutate(year = ifelse(year < 100, year + 1900, year))

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

ggplot(data_chi, aes(x = log_i)) +
  geom_histogram(binwidth = 0.5, fill = "green", color = "black", alpha = 0.7) +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Histogram of Log Investment by Industry, Chile",
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
  labs(title = "Histogram of Log Output by Industry, Colombia",
       x = "Log Output",
       y = "Frequency") +
  theme_minimal()
ggplot(data_chi, aes(x = log_Y)) +
  geom_histogram(binwidth = 0.5, fill = "green", color = "black", alpha = 0.7) +
  facet_wrap(~ industry, scales = "free") +
  labs(title = "Histogram of Log Output by Industry, Chile",
       x = "Log Output",
       y = "Frequency") +
  theme_minimal()








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
op_chi <- lm(form_op, data = data_chi)

modelsummary(
  list(Colombia = op_col, Chile = op_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
# Estimate varying parameters across industries using OP for each country
# First stage already done above
data_col <- data_col %>%
  mutate(
    industry_factor = as.factor(industry)
  )
data_chi <- data_chi %>%
  mutate(
    industry_factor = as.factor(industry)
  )
form_op_ind <- as.formula("log_y2_next - log_L:industry_factor ~ industry_factor + log_k_next:industry_factor + I(phi_hat - log_K:industry_factor)")
op_ind_col <- lm(form_op_ind, data = data_col)
op_ind_chi <- lm(form_op_ind, data = data_chi)

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
  fs_model <- lm(log_Y2 ~ rhs, data = data)
  data$phi_hat <- predict(fs_model, newdata = data)
  return(data)
}

data_col_lp <- first_stage_lp(data_col)
data_chi_lp <- first_stage_lp(data_chi)

# Second stage for LP
form_lp <- as.formula("log_y2_next - log_L ~ log_k_next + log_M_next + I(phi_hat - log_K - log_M)")
lp_col <- lm(form_lp, data = data_col_lp)
lp_chi <- lm(form_lp, data = data_chi_lp)

modelsummary(
  list(Colombia = lp_col, Chile = lp_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)

# Estimate varying parameters across industries using LP for each country
data_col_lp <- data_col_lp %>%
  mutate(
    industry_factor = as.factor(industry),
    log_M_next = lead(log_M)
  )
data_chi_lp <- data_chi_lp %>%
  mutate(
    industry_factor = as.factor(industry),
    log_M_next = lead(log_M)
  )
form_lp_ind <- as.formula("log_y2_next - log_L:industry_factor ~ industry_factor + log_k_next:industry_factor + log_M_next:industry_factor + I(phi_hat - log_K:industry_factor - log_M:industry_factor)")

lp_ind_col <- lm(form_lp_ind, data = data_col_lp)
lp_ind_chi <- lm(form_lp_ind, data = data_chi_lp)

modelsummary(
  list(Colombia_Ind = lp_ind_col, Chile_Ind = lp_ind_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)








#| label: 2-5 ACF Estimation 
# ACF Estimation for each country
acf_fs <- function(data) {
  data <- data %>%
    mutate(
      lag_log_L = lag(log_L),
      lag_log_K = lag(log_K),
      t2_lag_log_L = lag(lag_log_L),
      t2_lag_log_K = lag(lag_log_K),
      k_sq = log_K^2,
      it_k = as.numeric(factor(paste(id, year))) * log_K,
      it_k_sq = it_k^2,
      l_sq = log_L^2,
      it_l = as.numeric(factor(paste(id, year))) * log_L,
      it_l_sq = it_l^2,
      l_k = log_L * log_K,
      l_k_sq = l_k^2,
      rhs = cbind(lag_log_L, lag_log_K, t2_lag_log_L, t2_lag_log_K,
                  k_sq, l_sq, it_k, it_k_sq, it_l, it_l_sq, l_k, l_k_sq)
    )
  fs_model <- lm(log_Y2 ~ rhs, data = data)
  data$phi_hat <- predict(fs_model, newdata = data)
  return(data)
}

data_col_acf <- acf_fs(data_col)
data_chi_acf <- acf_fs(data_chi) 
# Second stage for ACF
form_acf <- as.formula("log_Y2 ~ log_L + log_K + I(phi_hat)")
acf_col <- lm(form_acf, data = data_col_acf)
acf_chi <- lm(form_acf, data = data_chi_acf)

modelsummary(
  list(Colombia = acf_col, Chile = acf_chi),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  output = "kableExtra"
)
# Estimate varying parameters across industries using ACF for each country
data_col_acf <- data_col_acf %>%
  mutate(
    industry_factor = as.factor(industry)
  )
data_chi_acf <- data_chi_acf %>%
  mutate(
    industry_factor = as.factor(industry)
  )
form_acf_ind <- as.formula("log_Y2 ~ industry_factor + log_L:industry_factor + log_K:industry_factor + I(phi_hat):industry_factor")
acf_ind_col <- lm(form_acf_ind, data = data_col_acf)
acf_ind_chi <- lm(form_acf_ind, data = data_chi_acf)

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








#| label: 3-2 Using OP estimates by Industry to estimate ω
# Using OP estimates from 2.3 to estimate omega by industry
op_ind_coefs_col <- coef(op_ind_col)
op_ind_coefs_chi <- coef(op_ind_chi)

get_coef_safe <- function(coefs, candidates) {
  hits <- candidates[candidates %in% names(coefs)]
  if (length(hits) == 0) stop("Missing coefficient: tried ", paste(candidates, collapse = ", "))
  unname(coefs[hits[1]])
}

build_industry_omega <- function(data, coefs) {
  inds <- sort(unique(data$industry))

  # industry_factor<ind> dummies in coefs; base = one without its dummy
  dummy_names <- paste0("industry_factor", inds)
  has_dummy   <- dummy_names %in% names(coefs)
  base_ind    <- inds[!has_dummy]
  if (length(base_ind) != 1) stop("Could not identify unique base industry")

  data %>%
    mutate(
      # intercept by industry
      alpha_0_ind =
        if_else(
          industry == base_ind,
          get_coef_safe(coefs, "(Intercept)"),
          get_coef_safe(coefs, "(Intercept)") +
            get_coef_safe(coefs, paste0("industry_factor", industry))
        ),

      # slope on capital by industry:
      # in your OP-ind table coefficients are on log_k_next, so read those
      alpha_k_ind = vapply(
        industry,
        function(ind) {
          get_coef_safe(
            coefs,
            c(
              paste0("log_k_next:industry_factor", ind),
              paste0("industry_factor", ind, ":log_k_next")
            )
          )
        },
        numeric(1)
      ),

      # omega_it for each obs in that industry
      omega_it_ind = exp(phi_hat - alpha_0_ind - alpha_k_ind * log_K)
    ) %>%
    group_by(industry) %>%
    summarise(
      mean_omega_ind = mean(omega_it_ind, na.rm = TRUE),
      sd_omega_ind   = sd(omega_it_ind,   na.rm = TRUE),
      .groups = "drop"
    )
}

op_ind_coefs_col <- coef(op_ind_col)
op_ind_coefs_chi <- coef(op_ind_chi)

col_omega <- build_industry_omega(data_col, op_ind_coefs_col)
chi_omega <- build_industry_omega(data_chi, op_ind_coefs_chi)

cat("Colombia - Omega by Industry:\n"); print(col_omega)
cat("\nChile - Omega by Industry:\n"); print(chi_omega)









#| label: 3-3 Productivity over Time
# Average productivity over time for each country
prod_time_col <- data_col %>%
  group_by(year) %>%
  summarise(
    mean_omega_year = mean(omega_it, na.rm = TRUE),
    sd_omega_year   = sd(omega_it,   na.rm = TRUE)
  )
prod_time_chi <- data_chi %>%
  group_by(year) %>%
  summarise(
    mean_omega_year = mean(omega_it, na.rm = TRUE),
    sd_omega_year   = sd(omega_it,   na.rm = TRUE)
  )
# Plot productivity over time
ggplot(prod_time_col, aes(x = year, y = mean_omega_year)) +
  geom_line(color = "blue") +
  geom_point() +
  labs(title = "Average Productivity Over Time (Colombia)",
       x = "Year",
       y = "Average Productivity (omega)") +
  theme_minimal()
ggplot(prod_time_chi, aes(x = year, y = mean_omega_year)) +
  geom_line(color = "green") +
  geom_point() +
  labs(title = "Average Productivity Over Time (Chile)",
       x = "Year",
       y = "Average Productivity (omega)") +
  theme_minimal()
ggplot(prod_time_col, aes(x = year, y = sd_omega_year)) +
  geom_line(color = "blue") +
  geom_point() +
  labs(title = "Standard Deviation of Productivity Over Time (Colombia)",
       x = "Year",
       y = "SD of Productivity (omega)") +
  theme_minimal()
ggplot(prod_time_chi, aes(x = year, y = sd_omega_year)) +
  geom_line(color = "green") +
  geom_point() +
  labs(title = "Standard Deviation of Productivity Over Time (Chile)",
       x = "Year",
       y = "SD of Productivity (omega)") +
  theme_minimal()
# Average productivity over time for each industry in each country
prod_time_ind_col <- data_col %>%
  group_by(year, industry) %>%
  summarise(
    mean_omega_year_ind = mean(omega_it, na.rm = TRUE),
    sd_omega_year_ind   = sd(omega_it,   na.rm = TRUE)
  )
prod_time_ind_chi <- data_chi %>%
  group_by(year, industry) %>%
  summarise(
    mean_omega_year_ind = mean(omega_it, na.rm = TRUE),
    sd_omega_year_ind   = sd(omega_it,   na.rm = TRUE)
  )
# Plot productivity over time by industry
ggplot(prod_time_ind_col, aes(x = year, y = mean_omega_year_ind, color = industry)) +
  geom_line() +
  geom_point() +
  labs(title = "Average Productivity Over Time by Industry (Colombia)",
       x = "Year",
       y = "Average Productivity (omega)") +
  theme_minimal()
ggplot(prod_time_ind_chi, aes(x = year, y = mean_omega_year_ind, color = industry)) +
  geom_line() +
  geom_point() +
  labs(title = "Average Productivity Over Time by Industry (Chile)",
       x = "Year",
       y = "Average Productivity (omega)") +
  theme_minimal()
ggplot(prod_time_ind_col, aes(x = year, y = sd_omega_year_ind, color = industry)) +
  geom_line() +
  geom_point() +
  labs(title = "SD of Productivity Over Time by Industry (Colombia)",
       x = "Year",
       y = "SD of Productivity (omega)") +
  theme_minimal()
ggplot(prod_time_ind_chi, aes(x = year, y = sd_omega_year_ind, color = industry)) +
  geom_line() +
  geom_point() +
  labs(title = "SD of Productivity Over Time by Industry (Chile)",
       x = "Year",
       y = "SD of Productivity (omega)") +
  theme_minimal()
