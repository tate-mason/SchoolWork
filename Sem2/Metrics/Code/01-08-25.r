#############################################
# Author: Tate Mason - dtm63837@uga.edu     #
# Institution: University of Georgia        #
# Date: 01-08-2025                          #
# Lecture - R Intro                         #
#############################################
## clear workspace
rm(list=ls())

## set working directory
## Example code
1+1

## Installing Packages ##
# install.packages(c('dslabs', 'lubridate')) ## dslabs for DS book, lubridate needed for HW's
library(lubridate) ## Calling package
# typically write in console as only done once

bday <- "07-15-1985"
# bday = var, "<-" = assigner, string = value

class(bday)
# is a string/character variable

date_bday <- mdy(bday)
class(date_bday)
date_bday
date_bday+1
# adds one day which was not possible with character variable

answer <- 1+1
answer*2
answer/3

## Can use import dataset button in RStudio, though not commonplace ## 

## Importing Data
firm_data <- read.csv('/Users/tate/Downloads/firm_data.csv')
# Download from website and set to path
firm_data <- subset(firm_data, select=-X) # removing needless column "X"
firm_data

## Functions in R ##  
log(5)
log(x=2, base=9) # to specify argument and base explicitly. when specifying, can be put in any order
log(2,9) # without specifying must be in order (arg, base)
# ?log # calls help file for log function

## Vectors
five <- seq(1,5)
five # sequence of 1-5
five+1 # add 1 to each element, same follows for other operations

## Accessing vector elements
five[[3]] # access 3rd element in vector 5
five[c(1,4)] # access multiple elements

length(five) # count number of elements in vector five

vec2 <- c(8,-3,4,1,7)
five + vec2 # vector operations possible

vec3 <- c(2,6)
five + vec3 # loops thru smaller vector until meets length of larger. will receive normal

## Functions for Creating and Operating on Vectors ##
1:10 # create a vector of 1-10
seq(1,10,by=3) # creating a vector of sequence 1-10 by 3's
seq(1,10,length.out=5) # equal spacing vector of 5 elements
# Standard operations
sum(five)
mean(five)
sd(five)
var(five)

sort(c(3,1,5)) # Sort into ascending order
order(c(3,1,5)) # Tells which position in vector holds smallest value

8 %% 3 # modulo function: gives remainder

# Character Vector
string1 <- "metrics"
string2 <- "class"

paste(string1, string2) # concatenates string vector
paste0(string1, string2) # paste without space inserted
# Logical Vectors (Next Time)

