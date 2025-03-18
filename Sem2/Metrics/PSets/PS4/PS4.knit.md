---
title: Problem Set 4
author: Tate Mason
format: pdf
---



# Question 1 - Hansen 7.17

## Part A

## Part B

## Part C

# Question 2 - Hansen 7.28

## Part B

## Part C

## Part D

## Part E

# EQ 1

# EQ 2



::: {.cell}

```{.r .cell-code}
b0 <- 0
b1 <- 1
n <- 100
sim <- function() {
  X1 <- rexp(n)
  e <- mixtools::rnormmix(n,lambda=c(0.5,0.5),mu=c(-1,2),sigma=c(1,1))
  Y <- b0 + b1*X1 + e
  x <- cbind(1,X1)
  xx <- t(x)%*%x
  xy <- t(x)%*%Y
  bhat <- solve(xx,xy)
  return(c(bhat[2]))
}
```
:::



These results show that the average of $\hat{\beta}_1 \rightarrow\beta_1$ as $n$ grows. The variance also approaches 0. This is consistent with what was derived in class, that as $n\rightarrow\infty$, we see the predicted approach the actual, and variance should be 0 as with sufficiently large $n$, there will be no variance in observations.



::: {.cell}

```{.r .cell-code}
run_mc <- function(n_sims = 1000) {
  mc_res <- sapply(1:n_sims, function(s) {
    sim()
  })
  cat("Mean b1:", mean(mc_res), "\n")
  cat("Variance of b1:", var(mc_res), "\n")
}
```
:::

::: {.cell}

```{.r .cell-code}
run_mc()
```

::: {.cell-output .cell-output-stdout}

```
Mean b1: 0.9990189 
Variance of b1: 0.03658883 
```


:::
:::

::: {.cell}

```{.r .cell-code}
n <- 2
run_mc()
```

::: {.cell-output .cell-output-stdout}

```
Mean b1: 4.822991 
Variance of b1: 21011.35 
```


:::
:::

::: {.cell}

```{.r .cell-code}
n <- 10
run_mc()
```

::: {.cell-output .cell-output-stdout}

```
Mean b1: 1.004985 
Variance of b1: 0.687412 
```


:::
:::

::: {.cell}

```{.r .cell-code}
n <- 50
run_mc()
```

::: {.cell-output .cell-output-stdout}

```
Mean b1: 1.004089 
Variance of b1: 0.07401569 
```


:::
:::

::: {.cell}

```{.r .cell-code}
n <- 500
run_mc()
```

::: {.cell-output .cell-output-stdout}

```
Mean b1: 0.9996898 
Variance of b1: 0.00679776 
```


:::
:::



As $n\rightarrow\infty$, the mean and variance get closer to the true values. This is a showcase of the WLLN.

# EQ 3

## Part A



::: {.cell}

```{.r .cell-code}
b0 <- 0
b1 <- 1
num_sims <- 1000
alpha <- 0.05

sim_test <- function(n,b1_true, b1_null) {
  X <- rexp(n)
  e <- mixtools::rnormmix(n,lambda=c(0.5,0.5),mu=c(-2,2),sigma=c(1,1))
  Y <- b0+b1*X + e
  x <- cbind(1,X)
  xx <- t(x)%*%x
  xy <- t(x)%*%Y
  bhat <- solve(xx,xy)
  b0_hat <- bhat[1]
  b1_hat <- bhat[2]

  yhat <- x %*% bhat
  ehat <- Y - yhat

  sigma_sq_hat <- sum(ehat^2)/(n-2)
  var_cov_matrix <- as.numeric(sigma_sq_hat)*solve(xx)
  se_b1_hat <- sqrt(var_cov_matrix[2,2])
  t_stat <- (b1_hat - b1_null)/se_b1_hat

  df <- n-2
  t_crit <- qt(1-alpha/2,df)
  reject <- abs(t_stat) > t_crit
  p_val <- 2*pt(abs(t_stat), df=df, lower.tail=FALSE)

  return(list(
    b1_hat = b1_hat,
    se_b1_hat = se_b1_hat,
    t_stat = t_stat,
    t_crit = t_crit,
    p_val = p_val,
    reject = reject
  ))
}
```
:::

::: {.cell}

```{.r .cell-code}
run_hypothesis_test <- function(n, b1_true, b1_null) {
  results <- data.frame(
    b1_hat = numeric(num_sims),
    se_b1_hat = numeric(num_sims),
    t_stat = numeric(num_sims),
    p_val = numeric(num_sims),
    reject = logical(num_sims)
  )

  for (i in 1:num_sims) {
    sim_result <- sim_test(n,b1_true,b1_null)
    results$b1_hat[i] <- sim_result$b1_hat
    results$se_b1_hat[i] <- sim_result$se_b1_hat
    results$t_stat[i] <- sim_result$t_stat
    results$p_val[i] <- sim_result$p_val
    results$reject[i] <- sim_result$reject
  }

  reject_rate <- mean(results$reject)
  mean_b1_hat <- mean(results$b1_hat)
  var_b1_hat <- var(results$b1_hat)
  mean_se_b1_hat <- mean(results$se_b1_hat)
  theoretical_var <- mean(results$se_b1_hat^2)

  return(list(
    results = results,
    reject_rate = reject_rate,
    mean_b1_hat = mean_b1_hat,
    var_b1_hat = var_b1_hat,
    mean_se_b1_hat = mean_se_b1_hat,
    theoretical_var = theoretical_var
  ))
}
```
:::

::: {.cell}

```{.r .cell-code}
results_100_true <- run_hypothesis_test(n=100,b1_true=1,b1_null=1)
cat("Part a & b: Results for n = 100, H₀: β₁ = 1 (true value)\n")
```

::: {.cell-output .cell-output-stdout}

```
Part a & b: Results for n = 100, H₀: β₁ = 1 (true value)
```


:::

```{.r .cell-code}
cat("Theoretical rejection rate at α = 0.05 should be: 0.05\n")
```

::: {.cell-output .cell-output-stdout}

```
Theoretical rejection rate at α = 0.05 should be: 0.05
```


:::

```{.r .cell-code}
cat("Observed rejection rate:", results_100_true$rejection_rate, "\n")
```

::: {.cell-output .cell-output-stdout}

```
Observed rejection rate: 
```


:::

```{.r .cell-code}
cat("Mean β̂₁:", results_100_true$mean_b1_hat, "\n")
```

::: {.cell-output .cell-output-stdout}

```
Mean β̂₁: 1.00601 
```


:::

```{.r .cell-code}
cat("Variance of β̂₁:", results_100_true$var_b1_hat, "\n")
```

::: {.cell-output .cell-output-stdout}

```
Variance of β̂₁: 0.05384848 
```


:::

```{.r .cell-code}
cat("Mean standard error of β̂₁:", results_100_true$mean_se_b1_hat, "\n")
```

::: {.cell-output .cell-output-stdout}

```
Mean standard error of β̂₁: 0.2309889 
```


:::

```{.r .cell-code}
cat("Theoretical variance (from SE):", results_100_true$theoretical_var, "\n\n")
```

::: {.cell-output .cell-output-stdout}

```
Theoretical variance (from SE): 0.05453085 
```


:::
:::



## Part C



::: {.cell}

```{.r .cell-code}
sample_size <- c(10,50,500,1000)
results_varying_n <- list()

for (n in sample_size) {
  results_varying_n[[paste0("n", n)]] <- run_hypothesis_test(n=n, b1_true=1, b1_null=1)
  cat("Results for n =", n, ", H₀: β₁ = 1 (true value)\n")
  cat("Rejection rate:", results_varying_n[[paste0("n", n)]]$rejection_rate, "\n")
  cat("Mean β̂₁:", results_varying_n[[paste0("n", n)]]$mean_b1_hat, "\n")
  cat("Variance of β̂₁:", results_varying_n[[paste0("n", n)]]$var_b1_hat, "\n")
  cat("Mean standard error of β̂₁:", results_varying_n[[paste0("n", n)]]$mean_se_b1_hat, "\n")
  cat("Theoretical variance (from SE):", results_varying_n[[paste0("n", n)]]$theortical_var, "\n\n")
}
```

::: {.cell-output .cell-output-stdout}

```
Results for n = 10 , H₀: β₁ = 1 (true value)
Rejection rate: 
Mean β̂₁: 1.059298 
Variance of β̂₁: 1.120389 
Mean standard error of β̂₁: 0.9140865 
Theoretical variance (from SE): 

Results for n = 50 , H₀: β₁ = 1 (true value)
Rejection rate: 
Mean β̂₁: 1.008697 
Variance of β̂₁: 0.1227225 
Mean standard error of β̂₁: 0.3380657 
Theoretical variance (from SE): 

Results for n = 500 , H₀: β₁ = 1 (true value)
Rejection rate: 
Mean β̂₁: 1.00353 
Variance of β̂₁: 0.009792151 
Mean standard error of β̂₁: 0.1004707 
Theoretical variance (from SE): 

Results for n = 1000 , H₀: β₁ = 1 (true value)
Rejection rate: 
Mean β̂₁: 0.9977452 
Variance of β̂₁: 0.004625567 
Mean standard error of β̂₁: 0.07082605 
Theoretical variance (from SE): 
```


:::
:::



## Part D



::: {.cell}

```{.r .cell-code}
results_100_false <- run_hypothesis_test(n=100,b1_true=1,b1_null=0)
cat("Part d: Results for n = 100, H₀: β₁ = 0 (false null)\n")
```

::: {.cell-output .cell-output-stdout}

```
Part d: Results for n = 100, H₀: β₁ = 0 (false null)
```


:::

```{.r .cell-code}
cat("Rejection rate (power):", results_100_false$rejection_rate, "\n")
```

::: {.cell-output .cell-output-stdout}

```
Rejection rate (power): 
```


:::

```{.r .cell-code}
cat("Mean β̂₁:", results_100_false$mean_b1_hat, "\n")
```

::: {.cell-output .cell-output-stdout}

```
Mean β̂₁: 0.9860435 
```


:::

```{.r .cell-code}
cat("Variance of β̂₁:", results_100_false$var_b1_hat, "\n\n")
```

::: {.cell-output .cell-output-stdout}

```
Variance of β̂₁: 0.05306137 
```


:::

```{.r .cell-code}
results_varying_n_false <- list()

for (n in sample_size) {
  set.seed(123)
  results_varying_n_false[[paste0("n", n)]] <- run_hypothesis_test(n = n, b1_true = 1, b1_null = 0)
  
  cat("Results for n =", n, ", H₀: β₁ = 0 (false null)\n")
  cat("Rejection rate (power):", results_varying_n_false[[paste0("n", n)]]$rejection_rate, "\n")
  cat("Mean β̂₁:", results_varying_n_false[[paste0("n", n)]]$mean_b1_hat, "\n")
  cat("Variance of β̂₁:", results_varying_n_false[[paste0("n", n)]]$var_b1_hat, "\n")
}
```

::: {.cell-output .cell-output-stdout}

```
Results for n = 10 , H₀: β₁ = 0 (false null)
Rejection rate (power): 
Mean β̂₁: 1.017303 
Variance of β̂₁: 1.029224 
Results for n = 50 , H₀: β₁ = 0 (false null)
Rejection rate (power): 
Mean β̂₁: 1.009133 
Variance of β̂₁: 0.1264878 
Results for n = 500 , H₀: β₁ = 0 (false null)
Rejection rate (power): 
Mean β̂₁: 1.004012 
Variance of β̂₁: 0.009162103 
Results for n = 1000 , H₀: β₁ = 0 (false null)
Rejection rate (power): 
Mean β̂₁: 0.997987 
Variance of β̂₁: 0.005327341 
```


:::
:::

