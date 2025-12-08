







knitr::opts_chunk$set(echo = TRUE)



library(tidyverse)
library(lubridate)
library(broom)
library(stargazer)
library(ggplot2)
library(modelsummary)
library(psych)
library(here)
library(gridExtra)
library(fixest)
library(AER)





main_data <- read_csv(here("Y2S1/IO/PS3/Data/prod_level_data.csv"))

main_long <- main_data %>%
  pivot_longer(
    cols = -market,
    names_to = c("var", "product"),
    names_pattern = "([a-z_]+)([1-4])",
    values_to = "value"
  ) %>%
  pivot_wider(
    names_from = var,
    values_from = value
  ) %>%
  mutate(
    product = as.integer(product)
  )

head(main_long)
describe(main_long)




main_graph_pxs <- main_long %>%
  group_by(product) %>%
  ggplot(aes(x = s, y = p)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  labs(
    title = "Price vs. Market Share by Product",
    x = "Market Share (s)",
    y = "Price (p)"
  ) +
  facet_wrap(~ product) +
  theme_minimal()

main_graph_xxs <- main_long %>%
  group_by(product) %>%
  ggplot(aes(x = s, y = x)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  labs(
    title = "Rating vs. Market Share by Product",
    x = "Rating (x)",
    y = "Market Share (s)"
  ) +
  facet_wrap(~ product) +
  theme_minimal()

main_graph_sxad <- main_long %>%
  group_by(product) %>%
  ggplot(aes(x = s, y = ave_dist)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  labs(
    title = "Average Distance vs. Market Share by Product",
    x = "Average Distance (ave_dist)",
    y = "Market Share (s)"
  ) +
  facet_wrap(~ product) +
  theme_minimal()

main_graph_pxs
main_graph_xxs
main_graph_sxad








#| label: multinomial logit - no instrument

logit_data <- main_long %>%
  group_by(market) %>%
  mutate(
    s_out = 1 - sum(s),
    logit_s = log(s) - log(s_out)
  ) %>%
  ungroup()

mnl1 <- feols(
  logit_s ~ x + p,
  data = logit_data
)
summary(mnl1)




#| label: 2-2

logit_data <- logit_data %>%
  group_by(product, market) %>%
  mutate(
    zp = mc
  ) %>%
  ungroup()

mnl2 <- ivreg(
  logit_s ~ x + p | x + zp,
  data = logit_data
)
summary(mnl2)




#| label: 2-3

logit_data <- logit_data %>%
  group_by(product, market) %>%
  mutate(
    ad = ave_dist
  ) %>%
  ungroup()

mnl3 <- ivreg(
  logit_s ~ x + p + ad | x + ad + zp,
  data = logit_data
)
summary(mnl3)
