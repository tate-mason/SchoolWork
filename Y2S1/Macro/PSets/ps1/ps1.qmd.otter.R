





library(AER)
library(haven)
library(tidyverse)



df <- read_dta("~/SchoolWork/Y2S1/Macro/Data/PSID/PSID.dta")



pivot <- tribble(
  ~year, ~age, ~sex, ~labor_par, ~earnings_annual, ~hourly, ~hr_worked, ~educ_HS, ~educ_coll, ~ind, ~wealth, ~cpi_ratio,
  1999, "ER13010", "ER13011", "ER13601", "ER13218", "ER13224", "ER13363", "ER15937", "ER15952", "ER13216", "S417", .027/0.014,
  2001, "ER17013", "ER17014", "ER17375", "ER17229", "ER17235", "ER17393", "ER19998", "ER20014", "ER17227", "S517", .016/0.014,
  2003, "ER21017", "ER21018", "ER21339", "ER21153", "ER21159", "ER21356", "ER23435", "ER23451", "ER21146", "S617", .019/0.014,
  2005, "ER25017", "ER25018", "ER25328", "ER25142", "ER25148", "ER25345", "ER27402", "ER27418", "ER25128", "S717", .034/0.014,
  2007, "ER36017", "ER36018", "ER36333", "ER36147", "ER36153", "ER36350", "ER40574", "ER40590", "ER36133", "S817", .041/0.014,
  2009, "ER42017", "ER42018", "ER42360", "ER42182", "ER42188", "ER42148", "ER46552", "ER46568", "ER42168", "ER46970", .027/0.014,
  2011, "ER47317", "ER47318", "ER47673", "ER47495", "ER47501", "ER47456", "ER51913", "ER51929", "ER47480", "ER52394", .03/0.014,
  2013, "ER53017", "ER53018", "ER53636", "ER53195", "ER53201", "ER53156", "ER57669", "ER57685", "ER53180", "ER58211", .015/0.014,
  2015, "ER60017", "ER60018", "ER60388", "ER60210", "ER60216", "ER60171", "ER64821", "ER64837", "ER60195", "ER65408", .007/0.014,
  2017, "ER66017", "ER66018", "ER66666", "ER66211", "ER66492", "ER66172", "ER70755", "ER70909", "ER66196", "ER71485", .021/0.014
)



df <- df %>%
  mutate(
    famid = coalesce(!!!rlang::syms(c(
      "ER66009","ER60009","ER53009","ER47309","ER42009",
      "ER36009","ER25009","ER21009","ER17022","ER13019"
    )))
  )

long <- map_dfr(1:nrow(pivot), function(i){
  sel <- pivot[i, ]
  df %>%
    transmute(
      famid,
      year = sel$year,
      sex = .data[[sel$sex]],
      age = .data[[sel$age]],
      inc = .data[[sel$earnings_annual]],
      labor_par = .data[[sel$labor_par]],
      hourly = .data[[sel$hourly]],
      hr_worked = .data[[sel$hr_worked]],
      educ_HS = .data[[sel$educ_HS]],
      educ_coll = .data[[sel$educ_coll]],
      ind = .data[[sel$ind]],
      wealth = .data[[sel$wealth]],
      cpi_ratio = sel$cpi_ratio
    ) 
})

glimpse(long)



long <- long %>%
  filter(
    age >= 25 & age <= 60,
    sex == 1
  ) %>%
  group_by(year) %>%
  mutate(
    wealth_adj = wealth * cpi_ratio,
    inc_adj = inc * cpi_ratio,
    hourly_adj = hourly * cpi_ratio
  )

long <- long %>%
  group_by(year) %>%
  mutate(
    labor_par = as.numeric(labor_par == 0),
    blue_col = as.numeric(ind %in% c(range(67:77), range(47:57), range(17:28), 107:398)),
    white_col = as.numeric(ind %in% c(range(407:479), range(707:718), range(727:759), range(828:897), range(907:937))),
    educ_HS = as.numeric(educ_HS == 1),
    educ_coll = as.numeric(educ_coll == 1),
  )
glimpse(long$age)

prof1 <- long %>%
  group_by(year) %>%
  summarise(
    avg_hourly = mean(hourly_adj, na.rm = TRUE),
    avg_hours = mean(hr_worked, na.rm = TRUE),
    avg_earnings = mean(inc_adj, na.rm = TRUE),
    var_inc = var(inc_adj, na.rm = TRUE),
    var_hours = var(hr_worked, na.rm = TRUE)
  ) %>%
  ggplot(aes(x = year)) +
  geom_line(aes(y = avg_hourly, color = "Hourly Wage"), size = 1) +
  geom_line(aes(y = avg_hours, color = "Hours Worked"),
            size = 1) +
  geom_line(aes(y = avg_earnings, color = "Annual Earnings"),
            size = 1) +
  geom_line(aes(y = var_inc, color = "Variance of Income"),
            size = 1, linetype = "dashed") +
  geom_line(aes(y = var_hours, color = "Variance of Hours Worked"),
            size = 1, linetype = "dashed") +
  labs(
    title = "Average Labor Outcomes for Ages 25-29",
    x = "Age",
    y = "Value",
    color = "Outcome"
  ) +
  scale_color_manual(values = c("Hourly Wage" = "blue", "Hours Worked" = "green", "Annual Earnings" = "red",
    "Variance of Income" = "orange", "Variance of Hours Worked" = "purple")) +
  theme_minimal() +
  theme(legend.position = "bottom")
prof1

