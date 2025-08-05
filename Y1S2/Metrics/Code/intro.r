#############################################
# Author: Tate Mason - dtm63837@uga.edu     #
# Institution: University of Georgia        #
# Date: 01-06-2025                          #
#############################################

######################
# Loading Packages   #
######################

library(lubridate, warn.conflicts=FALSE)
library(dplyr)

########################
# Creating a Dataframe #
########################

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

########################
# Worked Exercises     #
########################

##################
# Problem 1      #
##################
# Creating Vectors Manually and Performing Operations on Them #
x <- seq(2,10, by=2)
y <- c(3,5,7,11,13)
x+y
x-y
x*y
x/y

##################
# Problem 2      #
##################
# Creating a function to find the geometric mean #
geometric_mean <- function(j1, j2, j3, j){
  (j1*j2*j3)^(1/j)
}
print(geometric_mean(10,8,13,3))

##################
# Problem 3      #
##################
# Using Lubridate to find the time elapsed between two dates #
date_diff <- ymd(20220110) - ymd(19810101)
print(date_diff)

##################
# Problem 4      #
##################
# Working with the MTCars dataset #
df <- mtcars
# Part A #
df %>% count()
# Part B #
df %>% ncol()
# Part C #
df %>% colnames()
# Part D #
print(df$mpg>=20)
# Part E #
print(df$mpg>=20 & df$hp>=100)
# Part F #
print(df$cyl>=6 | df$hp>=100)
# Part G #
r10 <- as.vector(df[10,])
print(r10)
# Part H #
order(df$mpg)

#############################################
# End of Script - Reach out with questions  #
#############################################
