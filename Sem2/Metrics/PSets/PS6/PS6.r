library(Matrix)
library(dplyr)
library(tidyr)
library(magrittr)

df <- read.csv('metrics.csv')
# Creating Variables
id <- df$id
year <- df$year

n <- length(unique(id))
t <- length(unique(year))
nt <- n*t

df %<>% mutate(D=1*(first.displaced <= year & first.displaced !=0), yearf = factor(year))

Y <- Matrix(df$learn)
X <- model.matrix(~ yearf + D-1, data = df)
X <- Matrix(X)

I <- diag(nt)
D <- bdiag(replicate(n,Matrix(rep(1,t)),simplify=FALSE))
M <- I - D%*%solve(t(D)%*%D)%*%t(D)
alpha_hat <- solve(t(X)%*%M%*%X)%*%t(X)%*%M%*%Y
e_hat <- Y - X%*%alpha_hat
var_error = as.numeric(t(e_hat) %*% e_hat) / (nt - ncol(X))
var_alpha = var_error * solve(t(X) %*% M %*% X)
se_alpha = sqrt(diag(var_alpha))

cat("Part A: Report of Estimates\n")
alpha_hat
se_alpha

## Problem B - Diff-in-Differences

id <- df$id
year <- df$year

n <- length(unique(id))
t <- length(unique(year))
nt <- n*t

df %<>% mutate(D=1*(first.displaced <= year & first.displaced !=0), yearf = factor(year))
disp_years <- sort(unique(df$first.displaced[df$first.displaced > 0]))

group_time_effects <- list()

for (g in disp_years) {
  df_current <- df %>% mutate(D_g=1*(first.displaced == g & year>=g))

  Y <- Matrix(df_current$learn)

  X <- model.matrix(~ yearf + D_g-1, data = df_current)
  X <- Matrix(X)

  I <- diag(nt)
D_list <- list()
  individual_ids <- unique(df_current$id)
  
  for (i in 1:n) {
    # Vector of 1s for each time period for this individual
    D_list[[i]] <- Matrix(rep(1, t))
  }
  
  D <- bdiag(D_list)
  
  # Calculate the projection matrix M
  DtD <- t(D) %*% D
  DtD_inv <- solve(DtD)
  M <- I - D %*% DtD_inv %*% t(D)
  
  # Calculate the coefficient estimates
  XtM <- t(X) %*% M
  XtMX <- XtM %*% X
  XtMY <- XtM %*% Y
  
  # Solve for the coefficients
  alpha_hat <- solve(XtMX, XtMY)
  
  # Calculate residuals and variance
  e_hat <- Y - X %*% alpha_hat
  var_error <- as.numeric(t(e_hat) %*% e_hat) / (nt - ncol(X))
  var_alpha <- var_error * solve(XtMX)
  se_alpha <- sqrt(diag(var_alpha))
  
  # Store the results
  group_time_effects[[as.character(g)]] <- list(
    disp_year = g,
    alpha_hat = alpha_hat,
    se_alpha = se_alpha
  )
}

# Function to extract the treatment effect for each group
extract_effect <- function(result) {
  # The treatment coefficient is after all the year coefficients
  year_count <- length(unique(year))
  treatment_index <- year_count + 1
  
  # Extract coefficient and standard error
  coef <- result$alpha_hat[treatment_index]
  se <- result$se_alpha[treatment_index]
  
  # Calculate t-stat and p-value
  t_stat <- coef / se
  p_value <- 2 * pt(abs(t_stat), df = nt - (year_count + 1), lower.tail = FALSE)
  
  # Return as a data frame row
  return(data.frame(
    disp_year = result$disp_year,
    estimate = coef,
    se = se,
    t_stat = t_stat,
    p_value = p_value
  ))
}

# Combine all results
all_effects <- do.call(rbind, lapply(group_time_effects, extract_effect))

# Display the results
print("Group-Time Average Treatment Effects:")
print(all_effects)




# Extract and combine results
treatment_effects <- do.call(rbind, lapply(disp_results, extract_treatment_effect))
print(treatment_effects)
