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

head(data_raw)

## Demographics
raw_data <- data_raw %>%
  mutate(asian = ifelse(race %in% 4:6, 1, 0),
         chinese = ifelse(raced %in% 400:420, 1, 0),
         filipino = ifelse(raced == 600, 1, 0),
         indian = ifelse(raced == 610, 1, 0),
         korean = ifelse(raced == 620, 1, 0),
         vietnamese = ifelse(raced == 640, 1, 0),
         japanese = ifelse(raced == 500, 1, 0),
         black = ifelse(race == 2, 1, 0),
         renter = ifelse(ownershpd %in% c(21, 22), 1, 0))

## Keep only head of household
head_vars <- c("renter", "rent", "rentgrs", "valueh", "age", "chinese", "japanese",
               "vietnamese", "filipino", "korean", "indian", "black", "asian", "educ",
               "occ1990", "ind1990", "statefip", "metro", "metarea", "farm", "hhtype",
               "sex", "builtyr", "builtyr2", "bedrooms")
ipums_data <- raw_data %>% group_by(year,serial,hhwt) %>% summarize(across(all_of(head_vars), first))

## Filter and Format Data
ipums_data <- ipums_data %>% 
  filter(inctot>0 & year>=1940) %>%
    mutate(rent = ifelse(renter==1, rent, NA),
           rentgrs = ifelse(renter==1, rentgrs, NA),
           valueh = ifelse(renter==0, valueh, NA))
## Create Plotting Vars
ipums_data <- ipums_data %>%
  mutate(rent_inc = 1000*rentgrs/(inctot/12),
         hval_inc = valueh/(inctot/12),
         own_100 = 100*(1-renter),
         inctot_trimmed = pmin(pmax(inctot, quantile(inctot, 0.01)), quantile(inctot, 0.99)))
## Creating Plots
races <- c('asian', 'chinese', 'japanese', 'filipino', 'korean', 'indian', 'vietnamese', 'black')
years <- c(1980, 2019)
nq <- 30

for (r in races) {
  for (y in years){
    ## Rent-to-Income
    p1 <- ggplot(ipums_data[ipums_data$year==y & ipums_data$renter==1, ], aes(x=inctot_trimmed, y=rent_inc)) +
      geom_bin2d(bins=nq) +
      facet_wrap(as.formula(paste('~', r))) +
      labs(title=paste0(y,'Rent to Income Ratio'), x='Income', y='Rent-to-Income (%)') +
      theme_minimal()
    ggsave(file.path(output_path, paste0(r, "_extend_rentsum", y, ".pdf")), p1, device="pdf")
  }
}
