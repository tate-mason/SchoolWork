## Exercises R for DS ##
library('dslabs')
# 2.11
## Exercise 1 ##
n <- 100

(n*(n+1))/2

## Exercise 2 ##
n <- 1000
(n*(n+1))/2

## Exercise 3 ##
n <- 1000
x <- seq(1, n)
sum(x)

# Answer b

## Exercise 4 ##
log(sqrt(100), 10)

## Exercise 5 ##
# Option A: log(10^x)

## Exercise 6 ##
data("murders")
str(murders)
# Option C

## Exercise 7 ##
# state, abb, region, population, total

## Exercise 8 ##
a <- murders$population
class(a)
# Numeric

## Exercise 9 ##
b <- murders[['abb']]
identical(a, b)
# FALSE

## Exercise 10 ##
class(murders$region)
result <- c(levels(murders$region), length(murders$region))
result
