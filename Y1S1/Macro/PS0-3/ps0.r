# Required libraries to be installed first
library(tidyverse)  # for data manipulation and plotting
library(fredr)      # for FRED API access
library(lubridate)  # for date handling
library(readxl)     # for Excel file reading
library(zoo)        # for time series operations

# Set working directory paths
root_path <- "~/Library/CloudStorage/Dropbox/Schoolwork/Macro1/ProblemSets/PS0"
code_path <- file.path(root_path, "code")
data_path <- file.path(root_path, "Data")
output_path <- file.path(root_path, "Output")

# Set FRED API key
fredr_set_key("3937d3e1a400536de448b9415c9114d9")

# Problem 2
if (TRUE) {
  # Part A
  # Get individual series
  pcend <- fredr_series_observations("PCEND")
  pces <- fredr_series_observations("PCES")
  gdp <- fredr_series_observations("GDP")
  
  # Combine the series
  df <- pcend %>%
    select(date, value) %>%
    rename(PCEND = value) %>%
    left_join(
      pces %>% select(date, value) %>% rename(PCES = value),
      by = "date"
    ) %>%
    left_join(
      gdp %>% select(date, value) %>% rename(GDP = value),
      by = "date"
    )
  
  # Filter and calculate
  df <- df %>%
    filter(date >= as.Date("2005-01-01")) %>%
    mutate(
      PCENDS = PCEND + PCES,
      pce_percent_gdp = PCENDS / GDP
    )
  
  # Create plot
  ggplot(df, aes(x = date, y = pce_percent_gdp)) +
    geom_line() +
    labs(
      x = "Time",
      y = "Percentage of GDP",
      title = "Consumption of Non-Durables and Services: % of GDP"
    ) +
    theme_minimal()
  ggsave(file.path(output_path, "graph2a.png"))
  
  # Part B
  pcedg <- fredr_series_observations("PCEDG")
  gpdi <- fredr_series_observations("GPDI")
  
  df_b <- pcedg %>%
    select(date, value) %>%
    rename(PCEDG = value) %>%
    left_join(
      gpdi %>% select(date, value) %>% rename(GPDI = value),
      by = "date"
    ) %>%
    left_join(
      gdp %>% select(date, value) %>% rename(GDP = value),
      by = "date"
    )
  
  df_b <- df_b %>%
    filter(date >= as.Date("2005-01-01")) %>%
    mutate(
      PCEDGI = PCEDG + GPDI,
      durinv_percent_gdp = PCEDGI / GDP
    )
  
  ggplot(df_b, aes(x = date, y = durinv_percent_gdp)) +
    geom_line() +
    labs(
      x = "Time",
      y = "Percentage of GDP",
      title = "Consumption of Durables and Investment: % of GDP"
    ) +
    theme_minimal()
  ggsave(file.path(output_path, "graph2b.png"))
  
  # Similar pattern for parts C through G...
}

# Problem 3
if (FALSE) {
  # Part A
  gdp_pc <- fredr_series_observations("A939RX0Q048SBEA")
  
  df <- gdp_pc %>%
    mutate(
      rGDP_pc = log(value),
      date_num = as.numeric(date)
    )
  
  # Fit linear model
  model <- lm(rGDP_pc ~ date_num, data = df)
  df$dt_GDP <- residuals(model)
  
  # Create plots
  p1 <- ggplot(df, aes(x = date, y = rGDP_pc)) +
    geom_line() +
    geom_smooth(method = "lm", se = FALSE) +
    labs(
      x = "Time",
      y = "Log Real GDP per Capita",
      title = "Real GDP per Capita with Trend"
    ) +
    theme_minimal()
  ggsave(file.path(output_path, "3aa.png"), p1)
  
  p2 <- ggplot(df, aes(x = date, y = dt_GDP)) +
    geom_line() +
    labs(
      x = "Time",
      y = "Detrended Log Real GDP per Capita",
      title = "Detrended Real GDP per Capita"
    ) +
    theme_minimal()
  ggsave(file.path(output_path, "3ab.png"), p2)
  
  # Parts B through E follow similar pattern...
}
