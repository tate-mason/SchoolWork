library(lubridate, warn.conflicts=FALSE)
library(dplyr)

firm_data <- data.frame(
  name = c(
    "ABC Manufacturing",
    "Martin\'s Muffins",
    "Down Home Appliances",
    "Classic City Widgets",
    "Watkinsville Diner"),
  industry = c(
    "Manufacturing",
    "Food Services",
    "Manufacturing",
    "Manufacturing",
    "Food Services"),
  county = c(
    "Clarke",
    "Oconee",
    "Clarke",
    "Clarke",
    "Oconee"),
  employees = c(531, 6, 15, 211, 25))
### Worked Exercises
## Creating Vectors
x <- seq(2,10, by=2)
y <- c(3,5,7,11,13)
x+y
x-y
x*y
x/y

## Geometric Mean
geometric_mean <- function(j1, j2, j3, j){
  (j1*j2*j3)^(1/j)
}
print(geometric_mean(10,8,13,3))

## Lubridate
date_diff <- ymd(20220110) - ymd(19810101)
print(date_diff)

## MTCars Work
df <- mtcars
# a
df %>% count()
# b
df %>% ncol()
# c
df %>% colnames()
# d
print(df$mpg>=20)
# e
print(df$mpg>=20 & df$hp>=100)
# f
print(df$cyl>=6 | df$hp>=100)
# g
r10 <- as.vector(df[10,])
print(r10)
# h
order(df$mpg)
