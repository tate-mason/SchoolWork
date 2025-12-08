






knitr::opts_chunk$set(echo = TRUE)





# Load necessary libraries
library(tidyverse)
library(haven)
library(here)
library(stargazer)
library(broom)
library(modelsummary)
library(psych)
library(estimatr)
library(AER)
library(sandwich)
library(lmtest)



# Load the dataset
mc <- read_dta(here("Y2S1/Metrics/PSets/PS4/data", "medicarePS.dta"))

describe(mc)
summarise(mc)









#| label: 1.b - plotting
# Plotting averages per quarter of age: outcome, first stage, validity

mc_dat <- mc %>%
  group_by(Age) %>%
  summarize(
    mean_out = mean(DelayCare, na.rm = TRUE),
    mean_treat = mean(Ninsurance, na.rm = TRUE),
    mean_educ = mean(Education, na.rm = TRUE),
    mean_min = mean(Minority, na.rm = TRUE)
  )

plot_sd_trend <- function(data, y_var, title_text, y_label) {
  ggplot(data, aes(x = Age, y = {{ y_var }})) +
    geom_point() +
    geom_smooth(method = "loess", se = FALSE) + 
    geom_vline(xintercept = 65, linetype = "dashed", color = "red") +
    labs(title = title_text, x = "Age (Quarters)", y = y_label) +
    theme_minimal()
}

plot1 <- plot_sd_trend(mc_dat, mean_out, "Delay in Care vs Age", "Mean Delay in Care")
plot2 <- plot_sd_trend(mc_dat, mean_treat, "Number of Insurance Plans vs Age", "Mean Number of Insurance Plans")
plot3 <- plot_sd_trend(mc_dat, mean_educ, "Education vs Age", "Mean Education Level")
plot4 <- plot_sd_trend(mc_dat, mean_min, "Minority Status vs Age", "Mean Minority Status")

library(gridExtra)
grid.arrange(plot1, plot2, plot3, plot4, ncol = 2)




#| label: 1.c - RDD estimation

mc_RDD <- mc %>%
  mutate(
    z = if_else(Age >= 65, 1, 0),
    Agez = Age * z,
  )

tri_kernel <- function(age, cutoff, bandwidth) {
  dist <- abs(age - cutoff)
  ifelse(dist <= bandwidth, (1 - dist / bandwidth), 0)
}

mc_RDD <- mc_RDD %>%
  mutate(
    k = tri_kernel(Age, 65, 5)
  ) %>%
  filter(Age >= 60 & Age <= 70)

rdd_1c <- iv_robust(
  DelayCare ~ Ninsurance + Age + Agez | z + Age + Agez,
  data = mc_RDD,
  weights = k,
  se_type = "HC1" # Huber-White robust standard errors
)
summary(rdd_1c)







mc_RDD_low <- mc_RDD %>%
  mutate(
    k = tri_kernel(Age, 65, 3)
  )

model_1d_low <- iv_robust(
  DelayCare ~ Ninsurance + Age + Agez | z + Age + Agez,
  data = mc_RDD_low,
  weights = k,
  se_type = "HC1"
)
summary(model_1d_low)

mc_RDD_high <- mc_RDD %>%
  mutate(
    k = tri_kernel(Age, 65, 7)
  )
model_1d_high <- iv_robust(
  DelayCare ~ Ninsurance + Age + Agez | z + Age + Agez,
  data = mc_RDD_high,
  weights = k,
  se_type = "HC1"
)
summary(model_1d_high)






#| label: 1.e - covariate balance
covariate_RDD <- iv_robust(
  DelayCare ~ Ninsurance + Age + Agez + Minority + Education | z + Age + Agez + Minority + Education,
  data = mc_RDD,
  weights = k,
  se_type = "HC1"
)
summary(covariate_RDD)











#| label: 2.b - non-linearity
mc_RDD <- mc_RDD %>%
  mutate(
    Oneins = if_else(Ninsurance >= 1, 1, 0),
    Twoins = if_else(Ninsurance >= 2, 1, 0)
  )









#| label: 2.d - RDD with non-linear treatment

RDD_coll <- mc_RDD %>%
  group_by(Age, Minority) %>%
  summarize(
    Oneins = mean(Oneins, na.rm = TRUE),
    Twoins = mean(Twoins, na.rm = TRUE),
    DelayCare = mean(DelayCare, na.rm = TRUE),
    .groups = 'drop'
  )

RDD_coll_white <- RDD_coll %>%
  filter(Minority == 0) %>%
  ggplot(aes(x = Age)) +
  geom_point(aes(y = Oneins), color = "red") +
  geom_smooth(aes(y = Oneins), method = "loess", se = FALSE, color = "red") +
  geom_point(aes(y = Twoins), color = "green") +
  geom_smooth(aes(y = Twoins), method = "loess", se = FALSE, color = "green") +
  geom_vline(xintercept = 65, linetype = "dashed", color = "black") +
  labs(title = "Effect of Increased Coverage (Whites)", x = "Age (Quarters)", y = "Coverage") +
  theme_minimal()
print(RDD_coll_white)

RDD_coll_minority <- RDD_coll %>%
  filter(Minority == 1) %>%
  ggplot(aes(x = Age)) +
  geom_point(aes(y = Oneins), color = "red") +
  geom_smooth(aes(y = Oneins), method = "loess", se = FALSE, color = "red") +
  geom_point(aes(y = Twoins), color = "green") +
  geom_smooth(aes(y = Twoins), method = "loess", se = FALSE, color = "green") +
  geom_vline(xintercept = 65, linetype = "dashed", color = "black") +
  labs(title = "Effect of Increased Coverage (Minorities)", x = "Age (Quarters)", y = "Coverage") +
  theme_minimal()
print(RDD_coll_minority)












#| label: 2.f - scatter of delaycare by race
RDD_delay <- mc_RDD %>%
  group_by(Age, Minority) %>%
  summarize(
    DelayCare = mean(DelayCare, na.rm = TRUE),
    .groups = 'drop'
  )
RDD_delay_white <- RDD_delay %>%
  filter(Minority == 0) %>%
  ggplot(aes(x = Age, y = DelayCare)) +
  geom_point() +
  geom_smooth(method = "loess", se = FALSE, color = "blue") +
  geom_vline(xintercept = 65, linetype = "dashed", color = "black") +
  labs(title = "Delay in Care vs Age (Whites)", x = "Age (Quarters)", y = "Mean Delay in Care") +
  theme_minimal()

RDD_delay_minority <- RDD_delay %>%
  filter(Minority == 1) %>%
  ggplot(aes(x = Age, y = DelayCare)) +
  geom_point() +
  geom_smooth(method = "loess", se = FALSE, color = "blue") +
  geom_vline(xintercept = 65, linetype = "dashed", color = "black") +
  labs(title = "Delay in Care vs Age (Minorities)", x = "Age (Quarters)", y = "Mean Delay in Care") +
  theme_minimal()

grid.arrange(RDD_delay_white, RDD_delay_minority, ncol = 2)











#| label: 2.i - RDD with more interaction
mc_RDD <- mc_RDD %>%
  mutate(
    AgeMin = Age * Minority,
    zMin = z * Minority,
    AgezMin = Agez * Minority
  )

model_2i <- iv_robust(
  DelayCare ~ Oneins + Twoins + Age + Agez + Minority + AgeMin + zMin + AgezMin | 
    z + Age + Agez + Minority + AgeMin + zMin + AgezMin,
  data = mc_RDD,
  weights = k,
  se_type = "HC1"
)
summary(model_2i)
# Add educ stuff












#| label: 3.a - data prep
q3 <- mc_RDD %>%
  mutate(
    Wht_Drop = as.numeric(Minority == 0 & Education == 1),
    Min_Drop = as.numeric(Minority == 1 & Education == 1),
    Wht_HS   = as.numeric(Minority == 0 & Education == 2),
    Min_HS   = as.numeric(Minority == 1 & Education == 2),
    Wht_Col  = as.numeric(Minority == 0 & Education == 3),
    Min_Col  = as.numeric(Minority == 1 & Education == 3)
  )
describe(q3)




#| label: 3.b - 
# omit minority dropouts as base group
loop <- c("Wht_Drop", "Wht_HS", "Min_HS", "Wht_Col", "Min_Col")

for(v in loop) {
  var_z <- paste0(v, "z")
  q3[[var_z]] <- q3[[v]] * q3$z
  
  var_age <- paste0("Age", v)
  q3[[var_age]] <- q3$Age * q3[[v]]
  
  var_agez <- paste0("Age", v, "z")
  q3[[var_agez]] <- q3$Agez * q3[[v]]
}
head(mc)




endog <- "Oneins + Twoins"

ins_iv <- "z + Wht_Drop + Wht_HS + Wht_Col + Min_HSz + Min_Colz"

controls <- paste(
  "Age + Agez",
  "Wht_Drop + Wht_HS + Min_HS + Wht_Col + Min_Col",
  "AgeWht_Drop + AgeWht_HS + AgeMin_HS + AgeWht_Col + AgeMin_Col",
  "AgeWht_Dropz + AgeWht_HSz + AgeMin_HSz + AgeWht_Colz + AgeMin_Colz",
  sep = " + "
)

fmla_str <- paste("DelayCare ~", endog, "+", controls, "|", ins_iv, "+", controls)
fmla <- as.formula(fmla_str)

iv_3d <- iv_robust(
  formula = fmla,
  data = q3,
  weights = k,
  se_type = "HC1"
)
summary(iv_3d)
