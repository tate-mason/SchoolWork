########################################
## Introduction to R Programming #######
######    Abdul M Khan       ###########
###### Callaway: Topic 0(Class 2) ######
##### 1/13/2025                #########
########################################


# From last week
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



# Class 2
firm_data$employees  # Access columns from data frame
class(firm_data$employees) # class of this column is numeric
mean(firm_data$employees)  # we can do anyk ind of normal calculation with vectors from a column

firm_data[3,2]  #Indexing a data frame, trying to find out the 3rd row and 2nd column elemennt
firm_data[3,]  # whole row 3rd
firm_data[,2]  #whole column 2
firm_data[,c(1,2)]  #


nrow(firm_data)  #number of rows of a data frame
ncol(firm_data)  #number of columns of data frame


colnames(firm_data)  #names of columns of a dataframe
rownames(firm_data)  #


dim(firm_data)

unusal_list <- list(numbers=five,
                    df=firm_data) # A list of a vector and a data frame

#Access element in list
unusal_list$df  #Accessor symbol($) works same way as dataframe

unusal_list[2]
unusal_list[[2]]

class(unusal_list[2])
class(unusal_list$df)
class(unusal_list[[2]])


# Matrices
mat <- matrix(c(1,2,3,4), nrow = 2, byrow = TRUE)
mat

mat[1,2]
class(mat[2,])
class(mat[2,,drop=FALSE])

mat2 <- matrix(c(5,6,7,8), nrow = 2, byrow = TRUE)

mat + mat2

mat - mat2


mat / mat2

mat *mat2

mat %*% mat2

t(mat) #Transpose

solve(mat) # inverse of matrix

det(mat)


# Factors

class(firm_data$industry)

# changing industry as factors
firm_data$industry <- as.factor(firm_data$industry)
class(firm_data$industry)
firm_data$industry



head(firm_data) # gives first 5 elements/row with column names

str(firm_data)

str(five)

#Logicals

# ==, <=, >=, <, >

five == 3  #Give element by element comparison

five< 3

manufacturing_firms <- subset(firm_data,
                              industry== "Manufacturing")
manufacturing_firms


c(1,2,3) != 3
!(c(1,2,3)==3)

(c(1,2,3,4,5) >= 3) & (c(1,2,3,4,5)< 5)


(c(1,2,3,4,5) >= 3) | (c(1,2,3,4,5)< 5)

# %in%

c(1,7) %in% c(1,2,3,4,5) # looks the first vectors are in second vector

# any, all

any(c(1,7) %in% c(1,2,3,4,5)) # TRUE if any of the vector elements are true 

all(c(1,7) %in% c(1,2,3,4,5))  # TRUE if all of the vector elements are true 




#Writing functions

quadratic_solver <- function(a,b,c){
  x = (-b + sqrt(b^2 - 4*a*c))/2*a
  print(x)
}

quadratic_solver(1,4,3)
quadratic_solver(-1,5,10)

quadratic_solver2 <- function(b,c, a=1){
  x = (-b + sqrt(b^2 - 4*a*c))/2*a
  print(x)
}
quadratic_solver2(4,3)
quadratic_solver(4,3)


quadratic_solver2(c=3, b=4) #you don't have to maintain default order of argument


#if/else

large_or_small <- function(employees){
  if(employees > 100) {
    return("large")
  } else{
    return("small")
  }
}

large_or_small(25)


# for loops

out <- c()
for(i in 1:10){
  out[i] <- i*3
}

out

# Vectorization

log(five)

firm_data$employees
large_or_small(firm_data$employees)

# sapply - simplify apply
# lapply - list
# vapply - vectors
# apply - matrix or data.frame


large_or_small_vectorized <- function(employees_vec){
  sapply(employees_vec, large_or_small)
}

large_or_small_vectorized(firm_data$employees)


sapply(1:10, function(i) i*3)

large_or_small_vectorized2 <- function(employees_vec){
  ifelse(employees_vec >100, "large", "small")
}

large_or_small_vectorized2(firm_data$employees)
