## Learning how to use R via translating from Stata


library(pacman)
  p_load(tidyverse,
        foreign,
        haven,
        quantreg,
        ggplot2)

root_path <- "/Users/tate/Library/CloudStorage/Dropbox/Schoolwork/OldAssignments/RM/"
data_path <- file.path(root_path, "Data/RM2-Data/")
output_path <- file.path(root_path, "RM2/RM2-Output/")

data_raw <- read_dta(file.path(data_path,"usa_00035.dta"))

head(data_raw)

## Filtering out those in group quarters
data_raw <- data_raw%>%filter(gq%in% c(1,2,5))

## Managing missing values
vars <- c('inctot', 'incwage', 'ftotinc', 'incother', 'incbus', 'incbusfm', 'incfarm', 'incbus00',
        'incwelfr', 'incsupp', 'incinvst', 'incss', 'incretir', 'valueh', 'rent', 'rentgrs')
for (v in vars) {
  data_raw[[v]] <- ifelse(data_raw[[v]] %in% c(-009995, -000001, 0000001, 0000000, 9999999), NA, data_raw[[v]])
}

data_raw <- data_raw %>%
  mutate(incbus = case_when(
    year %in% c(1950, 1960) ~ data_raw$incbusfm,
    year %in% c(1970,1980,1990) ~data_raw$incbus+data_raw$incfarm,
    year>=2000 ~ data_raw$incbus00
  ))


