






#| label: setup
#| include: true
#| echo: true



# Packages
library(tidyverse)
library(lubridate)
library(stargazer)
library(fixest)
library(here)
library(readr)
library(tidyr)
library(stringr)


# Data
iri <- read_tsv("~/SchoolWork/Y2S1/IO/PS1/IRI.csv", show_col_types = FALSE) 
names(iri) <- gsub("^t", "", names(iri))  # Clean names
iri <- iri %>%
  mutate(
    market_id = interaction(store_id, week_id, drop = TRUE),
    date_id = interaction(year, month, drop = TRUE),
    date = as.Date(paste(year, month, "01", sep = "-"))
  )





#| label: q11-compute
# Distinct counts per market
brands_per_market <- iri %>%
  distinct(market_id, brand) %>%
  count(market_id, name = "n_brands")

mfrs_per_market <- iri %>%
  distinct(market_id, parent) %>%
  count(market_id, name = "n_mfrs")

# Total market sales per market
total_sales_market <- iri %>%
  group_by(market_id) %>%
  summarise(total_sales = sum(quantity, na.rm = TRUE), .groups = "drop")

# Brand-level sales (market x brand)
brand_sales_market <- iri %>%
  group_by(market_id, brand) %>%
  summarise(brand_sales = sum(quantity, na.rm = TRUE), .groups = "drop")

# Per-market price & characteristics (means within market)
market_chars <- iri %>%
  group_by(market_id) %>%
  summarise(
    price_mean     = mean(price, na.rm = TRUE),
    fiber_mean     = mean(fiber, na.rm = TRUE),
    sugars_mean    = mean(sugars, na.rm = TRUE),
    flavored_mean  = mean(as.numeric(flavored), na.rm = TRUE),
    fortified_mean = mean(as.numeric(fortified), na.rm = TRUE),
    .groups = "drop"
  )

# Helper to summarise numeric vectors
summarise_vec <- function(x) {
  tibble(
    mean   = mean(x, na.rm = TRUE),
    sd     = sd(x, na.rm = TRUE),
    median = median(x, na.rm = TRUE),
    max    = max(x, na.rm = TRUE)
  )
}

# Tables for 1.1
tbl_counts <- bind_cols(
  variable = c("n_brands", "n_mfrs"),
  bind_rows(
    summarise_vec(brands_per_market$n_brands),
    summarise_vec(mfrs_per_market$n_mfrs)
  )
)

tbl_total_sales <- bind_cols(
  variable = "total_sales (per market)",
  summarise_vec(total_sales_market$total_sales)
)

tbl_brand_sales <- bind_cols(
  variable = "brand_sales (per market-brand)",
  summarise_vec(brand_sales_market$brand_sales)
)

tbl_price_chars <- tribble(
  ~variable,                 ~mean, ~sd, ~median, ~max,
  "price (market mean)",
    summarise_vec(market_chars$price_mean)$mean,
    summarise_vec(market_chars$price_mean)$sd,
    summarise_vec(market_chars$price_mean)$median,
    summarise_vec(market_chars$price_mean)$max,
  "fiber (market mean)",
    summarise_vec(market_chars$fiber_mean)$mean,
    summarise_vec(market_chars$fiber_mean)$sd,
    summarise_vec(market_chars$fiber_mean)$median,
    summarise_vec(market_chars$fiber_mean)$max,
  "sugars (market mean)",
    summarise_vec(market_chars$sugars_mean)$mean,
    summarise_vec(market_chars$sugars_mean)$sd,
    summarise_vec(market_chars$sugars_mean)$median,
    summarise_vec(market_chars$sugars_mean)$max,
  "flavored share (market mean)",
    summarise_vec(market_chars$flavored_mean)$mean,
    summarise_vec(market_chars$flavored_mean)$sd,
    summarise_vec(market_chars$flavored_mean)$median,
    summarise_vec(market_chars$flavored_mean)$max,
  "fortified share (market mean)",
    summarise_vec(market_chars$fortified_mean)$mean,
    summarise_vec(market_chars$fortified_mean)$sd,
    summarise_vec(market_chars$fortified_mean)$median,
    summarise_vec(market_chars$fortified_mean)$max
)

summary_11 <- bind_rows(
  tbl_counts,
  tbl_total_sales,
  tbl_brand_sales,
  tbl_price_chars
)

summary_11
# If you want a file:
# write_csv(summary_11, "summary_11_descriptives.csv")




#| label: q12-ts
ts_simple <- iri %>%
  group_by(week_id) %>%
  summarise(
    avg_price = mean(price, na.rm = TRUE),
    avg_qty   = mean(quantity, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(week_id)

p_price <- ggplot(ts_simple, aes(x = week_id, y = avg_price)) +
  geom_line() +
  labs(title = "Average Cereal Price over Time",
       x = "Week (week_id)", y = "Average price per ounce")

p_qty <- ggplot(ts_simple, aes(x = week_id, y = avg_qty)) +
  geom_line() +
  labs(title = "Average Cereal Sales (Quantity) over Time",
       x = "Week (week_id)", y = "Average quantity (lbs)")

p_price
p_qty

# Save figures
ggsave("avg_price.png", p_price, width = 10, height = 6, dpi = 300)
ggsave("avg_sales.png", p_qty, width = 10, height = 6, dpi = 300)

# Dual-axis style (scaled)
ts_long_scaled <- ts_simple %>%
  mutate(
    price_scaled = (avg_price - min(avg_price, na.rm = TRUE)) /
                   (max(avg_price, na.rm = TRUE) - min(avg_price, na.rm = TRUE)),
    qty_scaled   = (avg_qty - min(avg_qty, na.rm = TRUE)) /
                   (max(avg_qty, na.rm = TRUE) - min(avg_qty, na.rm = TRUE))
  ) %>%
  select(week_id, price_scaled, qty_scaled) %>%
  pivot_longer(-week_id, names_to = "series", values_to = "value")

p_dual <- ggplot(ts_long_scaled, aes(x = week_id, y = value, color = series)) +
  geom_line() +
  scale_color_manual(values = c("price_scaled" = "steelblue", "qty_scaled" = "firebrick"),
                     labels = c("Avg price (scaled)", "Avg qty (scaled)")) +
  labs(title = "Average Price & Sales over Time (scaled to [0,1])",
       x = "Week (week_id)", y = "Scaled value", color = NULL)

p_dual
ggsave("avg_price_sales_dual.png", p_dual, width = 10, height = 6, dpi = 300)




#| label: q13-hhi
# Brand HHI per market
brand_shares <- iri %>%
  group_by(market_id) %>%
  mutate(total_mkt_sales = sum(quantity, na.rm = TRUE)) %>%
  ungroup() %>%
  group_by(market_id, brand) %>%
  summarise(brand_sales = sum(quantity, na.rm = TRUE),
            total_mkt_sales = first(total_mkt_sales),
            .groups = "drop") %>%
  mutate(share_brand = if_else(total_mkt_sales > 0, brand_sales / total_mkt_sales, 0))

hhi_brand_market <- brand_shares %>%
  group_by(market_id) %>%
  summarise(HHI_brand = sum(share_brand^2, na.rm = TRUE), .groups = "drop")

hhi_brand_week <- iri %>%
  distinct(market_id, week_id) %>%
  inner_join(hhi_brand_market, by = "market_id") %>%
  group_by(week_id) %>%
  summarise(avg_HHI_brand = mean(HHI_brand, na.rm = TRUE), .groups = "drop") %>%
  arrange(week_id)

p_hhi_brand <- ggplot(hhi_brand_week, aes(x = week_id, y = avg_HHI_brand)) +
  geom_line() +
  labs(title = "Average Brand-Level HHI Over Time",
       x = "Week (week_id)", y = "Average HHI (brand)")

p_hhi_brand
ggsave("HHI_brand.png", p_hhi_brand, width = 10, height = 6, dpi = 300)

# Manufacturer (parent) HHI per market
parent_shares <- iri %>%
  group_by(market_id) %>%
  mutate(total_mkt_sales = sum(quantity, na.rm = TRUE)) %>%
  ungroup() %>%
  group_by(market_id, parent) %>%
  summarise(parent_sales = sum(quantity, na.rm = TRUE),
            total_mkt_sales = first(total_mkt_sales),
            .groups = "drop") %>%
  mutate(share_parent = if_else(total_mkt_sales > 0, parent_sales / total_mkt_sales, 0))

hhi_parent_market <- parent_shares %>%
  group_by(market_id) %>%
  summarise(HHI_parent = sum(share_parent^2, na.rm = TRUE), .groups = "drop")

hhi_parent_week <- iri %>%
  distinct(market_id, week_id) %>%
  inner_join(hhi_parent_market, by = "market_id") %>%
  group_by(week_id) %>%
  summarise(avg_HHI_parent = mean(HHI_parent, na.rm = TRUE), .groups = "drop") %>%
  arrange(week_id)

p_hhi_parent <- ggplot(hhi_parent_week, aes(x = week_id, y = avg_HHI_parent)) +
  geom_line() +
  labs(title = "Average Manufacturer-Level HHI Over Time",
       x = "Week (week_id)", y = "Average HHI (manufacturer)")

p_hhi_parent
ggsave("HHI_parent.png", p_hhi_parent, width = 10, height = 6, dpi = 300)

# Combined comparison
hhi_both <- hhi_brand_week %>% inner_join(hhi_parent_week, by = "week_id")

p_hhi_both <- ggplot(hhi_both, aes(x = week_id)) +
  geom_line(aes(y = avg_HHI_brand, color = "Brand HHI")) +
  geom_line(aes(y = avg_HHI_parent, color = "Manufacturer HHI")) +
  scale_color_manual(values = c("Brand HHI" = "steelblue", "Manufacturer HHI" = "firebrick")) +
  labs(title = "Average HHI Over Time (Brand vs Manufacturer)",
       x = "Week (week_id)", y = "Average HHI", color = NULL)

p_hhi_both
ggsave("HHI_brand_vs_parent.png", p_hhi_both, width = 10, height = 6, dpi = 300)







#| label: q2-1
# Prepare data for regression
reg_data <- iri %>%
  group_by(market_id) %>%
  mutate(
    market_fe = as.factor(store_id),
    manufacturer_fe = as.factor(parent),
    time_fe = as.factor(week_id),
    brand_fe = as.factor(brand),
    p_jmt = price,
    total_sales = sum(quantity, na.rm = TRUE),
    sj = quantity / M,
    s0 = 1 - (total_sales / M),
    u = log(sj) - log(s0)
  ) %>%
  ungroup() 












#| label: q2-2
# Regression model
list <- c("fiber", "sugars", "flavored", "fortified",
          "market_fe", "manufacturer_fe", "time_fe")
reg_model <- feols(
  u ~ p_jmt + fiber + sugars + flavored + fortified |
  market_fe + manufacturer_fe + time_fe,
  data = reg_data
)

# Histogram of own price elasticities
reg_data <- reg_data %>%
  mutate(own_price_elasticity = coef(reg_model)["p_jmt"] * p_jmt * (1 - sj))

ggplot(reg_data, aes(x = own_price_elasticity)) +
  geom_histogram(bins = 30, fill = "steelblue", color = "black", alpha = 0.7) +
  labs(title = "Histogram of Own Price Elasticities",
       x = "Own Price Elasticity", y = "Frequency") +
  theme_minimal()




#| label: q2-3
# 2SLS with Price Instrument: Price*Quantity of Sugar

reg_data <- reg_data %>%
  mutate(
    z = sugars * sugar_price,
    z = log(z)

  )
stage2 <- feols(u ~ fiber + sugars + flavored + fortified |
                 market_fe + manufacturer_fe + time_fe | p_jmt ~ z,
               data = reg_data)
summary(stage2)
# Histogram of own price elasticities (2SLS)
reg_data <- reg_data %>%
  mutate(own_price_elasticity_2sls = coef(stage2)["fit_p_jmt"] * p_jmt * (1 - sj))
ggplot(reg_data, aes(x = own_price_elasticity_2sls)) +
  geom_histogram(bins = 30, fill = "firebrick", color = "black", alpha = 0.7) +
  labs(title = "Histogram of Own Price Elasticities (2SLS)",
       x = "Own Price Elasticity (2SLS)", y = "Frequency") +
  theme_minimal()








#| label: q2-4
# Elasticity Matrix for Top 5 Brands by Sales
## Create average matrix by taking average of market level elaticity matrices

top_brands <- reg_data %>%
  group_by(brand) %>%
  summarise(total_sales = sum(quantity, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(total_sales)) %>%
  slice_head(n = 5) %>%
  pull(brand)
elasticity_matrices <- list()
for (mkt in unique(reg_data$market_id)) {
  mkt_data <- reg_data %>% filter(market_id == mkt, brand %in% top_brands)
  n <- nrow(mkt_data)
  if (n < 5) next  # Skip markets with fewer than 5 top brands
  elas_matrix <- matrix(0, nrow = n, ncol = n)
  rownames(elas_matrix) <- mkt_data$brand
  colnames(elas_matrix) <- mkt_data$brand
  for (i in 1:n) {
    for (j in 1:n) {
      if (i == j) {
        elas_matrix[i, j] <- coef(stage2)["fit_p_jmt"] * mkt_data$p_jmt[i] * (1 - mkt_data$sj[i])
      } else {
        elas_matrix[i, j] <- -coef(stage2)["fit_p_jmt"] * mkt_data$p_jmt[j] * mkt_data$sj[i]
      }
    }
  }
  elasticity_matrices[[as.character(mkt)]] <- elas_matrix
}
# Average elasticity matrix
avg_elasticity_matrix <- Reduce("+", elasticity_matrices) / length(elasticity_matrices)
avg_elasticity_matrix




#| label: q2-5
# Calculaete markups for each manufacturer
reg_data <- reg_data %>%
  mutate(
    own_price_elasticity_2sls = coef(stage2)["fit_p_jmt"] * p_jmt * (1 - sj),
    markup = -1 / own_price_elasticity_2sls
  )
markup_summary <- reg_data %>%
  group_by(parent) %>%
  summarise(
    avg_markup = mean(markup, na.rm = TRUE),
    sd_markup = sd(markup, na.rm = TRUE),
    median_markup = median(markup, na.rm = TRUE),
    max_markup = max(markup, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_markup))
markup_summary

ggplot(markup_summary, aes(x = reorder(parent, -avg_markup), y = avg_markup)) +
  geom_bar(stat = "identity", fill = "darkgreen", alpha = 0.7) +
  labs(title = "Average Markup by Manufacturer",
       x = "Manufacturer", y = "Average Markup") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))





#| label: q2-6
# Nested by segment - construct data and calculate conditional shares
reg_data <- reg_data %>%
  mutate(
    nest = as.factor(segment)
  ) %>%
  group_by(market_id, nest) %>%
  mutate(
    total_nest_sales = sum(quantity, na.rm = TRUE),
    share_con = if_else(total_nest_sales > 0, quantity / total_nest_sales, 0)
  ) %>%
  ungroup()










#| label: q2-7
#2SLS with Price Instrument: Price*Quantity of Sugar and Conditional Share Instrument total products

reg_data <- reg_data %>%
  group_by(market_id) %>%
  mutate(
    z_cond = log(n_distinct(brand)),
    sjg = log(share_con),
    z = sugars * sugar_price,
    z = log(z)
  )
s2_nest <- feols(u ~ fiber + sugars + flavored + fortified |
                    market_fe + manufacturer_fe + time_fe | p_jmt + sjg ~ z + z_cond,
                  data = reg_data)
summary(s2_nest)

# Histogram of own price elasticities (2SLS Nested)
reg_data <- reg_data %>%
  mutate(own_price_elasticity_2sls_nest = coef(s2_nest)["fit_p_jmt"] * p_jmt * (1 - sj),
  sgj = log(coef(s2_nest)["fit_share_con"]))
ggplot(reg_data, aes(x = own_price_elasticity_2sls_nest)) +
  geom_histogram(bins = 30, fill = "purple", color = "black", alpha = 0.7) +
  labs(title = "Histogram of Own Price Elasticities (2SLS Nested)",
       x = "Own Price Elasticity (2SLS Nested)", y = "Frequency") +
  theme_minimal()





#| label: q2-8
# Elasticity Matrix for Top 5 Brands by Sales (Nested)
top_nest_brands <- reg_data %>%
  group_by(brand) %>%
  summarise(total_sales = sum(quantity, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(total_sales)) %>%
  slice_head(n = 5) %>%
  pull(brand)
elasticity_nest_matrices <- list()
for (mkt in unique(reg_data$market_id)) {
  mkt_data <- reg_data %>% filter(market_id == mkt, brand %in% top_nest_brands)
  n <- nrow(mkt_data)
  if (n < 5) next  # Skip markets with fewer than 5 top brands
  elas_matrix_nest <- matrix(0, nrow = n, ncol = n)
  rownames(elas_matrix_nest) <- mkt_data$brand
  colnames(elas_matrix_nest) <- mkt_data$brand
  for (i in 1:n) {
    for (j in 1:n) {
      if (i == j) {
        elas_matrix_nest[i, j] <- coef(s2_nest)["fit_p_jmt"] *
          mkt_data$p_jmt[i] * (1 / (1 - coef(s2_nest)["fit_sjg"])) *
          ((1 - coef(s2_nest)["fit_sjg"] * mkt_data$sjg[i]) - (1
            - coef(s2_nest)["fit_sjg"]) * mkt_data$sj[i])
      } else if (mkt_data$nest[i] == mkt_data$nest[j]) {
        elas_matrix_nest[i, j] <- -coef(s2_nest)["fit_p_jmt"] *
          mkt_data$p_jmt[i] * (1 / (1 - coef(s2_nest)["fit_sjg"])) *
          ((1 - coef(s2_nest)["fit_sjg"] * mkt_data$sjg[i]) - (1 
            - coef(s2_nest)["fit_sjg"]) * mkt_data$sj[i])
      } else {
        elas_matrix_nest[i, j] <- coef(s2_nest)["fit_p_jmt"] *
          mkt_data$p_jmt[i] * (1 / (1 - coef(s2_nest)["fit_sjg"])) *
          ((1 - coef(s2_nest)["fit_sjg"] * mkt_data$sjg[i]) - (1 - 
            coef(s2_nest)["fit_sjg"]) * mkt_data$sj[i])

      }
    }
  }
  elasticity_nest_matrices[[as.character(mkt)]] <- elas_matrix_nest
}
# Average elasticity matrix (Nested)
avg_elasticity_nest_matrix <- Reduce("+", elasticity_nest_matrices) /
  length(elasticity_nest_matrices)
avg_elasticity_nest_matrix





#| label: q2-9
# Calculate average markups for each manufacturer (Nested)
reg_data <- reg_data %>%
  mutate(
    ope_nest = coef(s2_nest)["fit_p_jmt"] * p_jmt * (1 - sj),
    markup_nest = -1 / ope_nest
  )
markup_nest_summary <- reg_data %>%
  group_by(parent) %>%
  summarise(
    avg_markup_nest = mean(markup_nest, na.rm = TRUE),
    sd_markup_nest = sd(markup_nest, na.rm = TRUE),
    median_markup_nest = median(markup_nest, na.rm = TRUE),
    max_markup_nest = max(markup_nest, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_markup_nest))
markup_nest_summary
ggplot(markup_nest_summary, aes(x = reorder(parent, -avg_markup_nest),
                                y = avg_markup_nest)) +
  geom_bar(stat = "identity", fill = "orange", alpha = 0.7) +
  labs(title = "Average Markup by Manufacturer (Nested)",
       x = "Manufacturer", y = "Average Markup (Nested)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))





print("HI")







#| label: q3-1
library(BLPestimatoR)
library(tidyverse)
library(Formula)

set.seed(219)

iri <- read_tsv(
  "~/SchoolWork/Y2S1/IO/PS1/IRI.csv",
  show_col_types = FALSE
)

iri <- iri %>%
  mutate(
    cdid = str_c("m_", store_id, "_", week_id),,
    pdid = str_c("p_", brand, "_", store_id, "_", week_id),
    share = pmax(quantity / M, 1e-10)
  )

comp_avg <- function(x) {
  n <- length(x)
  s <- sum(x)
  ifelse(n > 1, (s - x) / (n - 1), 0)
}

iri <- iri %>%
  group_by(cdid) %>%
  mutate(
    blp_sugar = (comp_avg(sugars) - sugars)^2,
    blp_fiber = (comp_avg(fiber) - fiber)^2,
  ) %>%
  ungroup()

inc <- read_tsv("~/SchoolWork/Y2S1/IO/PS1/simulated_agents_income.csv")
nchild <- read_tsv("~/SchoolWork/Y2S1/IO/PS1/simulated_agents_nchild.csv")

inc_mean <- inc %>%
  pivot_longer(-c(year, puma), names_to = "draw", values_to = "income") %>%
  group_by(year, puma) %>%
  summarise(income = mean(income, na.rm = TRUE), .groups = "drop")

nchild_mean <- nchild %>%
  pivot_longer(-c(year, puma), names_to = "draw", values_to = "nchild") %>%
  group_by(year, puma) %>%
  summarise(nchild = mean(nchild, na.rm = TRUE), .groups = "drop")

iri <- iri %>%
  left_join(inc_mean, by = c("year", "puma")) %>%
  left_join(nchild_mean, by = c("year", "puma")) %>%
  mutate(
    fiber_inc = fiber * income,
    sugars_nchild = sugars * nchild,
    sugar_inc = sugars * income,
    fiber_nchild = fiber * nchild,
    income_sq = income^2
  )

nevos_model <- as.formula(
  "share ~ price + fiber + sugars + flavored + fortified |
  0 + pdid |
  fiber + sugars + flavored + fortified |
  0 + blp_sugar + blp_fiber + sugar_inc + fiber_inc + sugars_nchild +
  fiber_nchild + sugar_price"
)

M <- 5
R <- 3

productData <- iri %>%
  transmute(
    pdid, cdid, brand, parent, price, 
    share = pmax(share, 1e-10), fiber, sugars,
    flavored, fortified, blp_sugar, blp_fiber, sugar_price,
    sugar_inc, fiber_inc, sugars_nchild, fiber_nchild,
  )

head(productData)

inc_stack <- inc %>%
  pivot_longer(-c(year, puma), names_to = "draw", values_to = "income") %>%
  mutate(draw = as.integer(gsub("draw_", "", draw))) %>%
  select(year, puma, draw, income)

nchild_stack <- nchild %>%
  pivot_longer(-c(year, puma), names_to = "draw", values_to = "nchild") %>%
  mutate(draw = as.integer(gsub("draw_", "", draw))) %>%
  select(year, puma, draw, nchild)

demo_stack <- inner_join(inc_stack, nchild_stack, by = c("year" ,"puma", "draw"))

demo_data <- iri %>%
  distinct(cdid, year, puma) %>%
  left_join(demo_stack, by = c("year", "puma")) %>%
  select(cdid, income, nchild)

demographicDraws <- demo_data %>%
  slice_sample(n = R, replace = TRUE) %>%
  transmute(
    cdid,
    income = income,
    nchild = nchild
  ) %>%
  as.matrix()

integration_draws <- matrix(rnorm(R * M), nrow = R, ncol = M)

head(demographicDraws)

blp_data <- BLP_data(
  model = nevos_model,
  market_identifier = "cdid",
  product_identifier = "pdid",
  productData = productData,
  demographic_draws = demographicDraws,
  integration_draws = demo_stack,
  integration_weights = rep(1 / 7, 7),
  blp_inner_tol = 1e-6,
  blp_inner_maxit = 100
)
blp_out <- estimateBLP(
  blp_data = blp_data,
  par_theta2 = seq_lin(-1, 1, length.out = M),
  solver_method = "BFGS",
  solver_maxit = 100,
  solver_tol = 1e-6,
  n_threads = 4,
  standardError = "heteroskedastic",
  extremumCheck = FALSE,
  printLevel = 1
)
summary(blp_out)
