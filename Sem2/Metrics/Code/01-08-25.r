#############################################
# Author: Tate Mason - dtm63837@uga.edu     #
# Institution: University of Georgia        #
# Date: 01-08-2025                          #
# Lecture - R Intro                         #
#############################################

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


