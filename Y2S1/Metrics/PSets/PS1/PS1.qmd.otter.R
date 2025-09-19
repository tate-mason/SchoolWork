


















































set.seed(1)
library(dplyr)
library(tidyr)
library(AER)



df <- data.frame(
  id = 1:10000,
  epsilon_D = rnorm(10000, mean = 0, sd = 1),
  epsilon_Y = rnorm(10000, mean = 0, sd = 1),
  U_i = rnorm(10000, mean = 0, sd = 0.5)
)

z_i <- runif(10000, min = 0, max = 1)
df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y
  )





OLS <- lm(Y_i ~ D_i, data = df) 
summary(OLS)





IV <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV)














df <- df %>%
  mutate(
    D_hat = predict(lm(D_i ~ Z_i, data = df)),
    D_tilde = D_i - D_hat
  )
model_a <- lm(Y_i ~ D_hat, data = df)
summary(model_a)



model_b <- lm(Y_i ~ D_i + D_tilde, data = df)
summary(model_b)












df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV5a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5a)



df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
)
IV5b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5b)





df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV6a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6a)



df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
  )
IV6b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6b)











df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 1),
    pC = 1 - pAT - pNT
  )

summarize(df, pC = mean(pC), pNT = mean(pNT), pAT = mean(pAT))

cor(df$D_i, df$Z_i)







df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pZ = length(Z_i == 1)/length(id),
    pD = length(D_i == 1)/length(id),
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 1),
    pC = 1 - pAT - pNT
  )

summarize(df, pC = mean(pC), pNT = mean(pNT), pAT = mean(pAT))

cor(df$D_i, df$Z_i)
















set.seed(2)

df <- data.frame(
  id = 1:10000,
  epsilon_D = rnorm(10000, mean = 0, sd = 1),
  epsilon_Y = rnorm(10000, mean = 0, sd = 1),
  U_i = rnorm(10000, mean = 0, sd = 0.5)
)

z_i <- runif(10000, min = 0, max = 1)
df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y
  )
OLS <- lm(Y_i ~ D_i, data = df) 
summary(OLS)
IV <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV)
df <- df %>%
  mutate(
    D_hat = predict(lm(D_i ~ Z_i, data = df)),
    D_tilde = D_i - D_hat
  )
model_a <- lm(Y_i ~ D_hat, data = df)
summary(model_a)

model_b <- lm(Y_i ~ D_i + D_tilde, data = df)
summary(model_b)
df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV5a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5a)

df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
)
IV5b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5b)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV6a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6a)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
  )
IV6b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6b)
df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 1),
    pC = 1 - pAT - pNT
  )

summarize(df, pC = mean(pC), pNT = mean(pNT), pAT = mean(pAT))

cor(df$Z_i, df$D_i)

df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 1),
    pC = 1 - pAT - pNT
  )

summarize(df, pC = mean(pC), pNT = mean(pNT), pAT = mean(pAT))

cor(df$Z_i, df$D_i)



set.seed(3)
df <- data.frame(
  id = 1:10000,
  epsilon_D = rnorm(10000, mean = 0, sd = 1),
  epsilon_Y = rnorm(10000, mean = 0, sd = 1),
  U_i = rnorm(10000, mean = 0, sd = 0.5)
)

z_i <- runif(10000, min = 0, max = 1)
df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y
  )
OLS <- lm(Y_i ~ D_i, data = df) 
summary(OLS)
IV <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV)
df <- df %>%
  mutate(
    D_hat = predict(lm(D_i ~ Z_i, data = df)),
    D_tilde = D_i - D_hat
  )
model_a <- lm(Y_i ~ D_hat, data = df)
summary(model_a)
model_b <- lm(Y_i ~ D_i + D_tilde, data = df)
summary(model_b)
df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV5a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5a)
df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
)
IV5b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5b)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV6a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6a)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
  )
IV6b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6b)

df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 0),
    pC = 1 - pAT - pNT
  )
length(df$compliers)
cor(df$Z_i, df$D_i)
df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 0),
    pC = 1 - pAT - pNT
  )
length(df$compliers)
cor(df$Z_i, df$D_i)



set.seed(4)

df <- data.frame(
  id = 1:10000,
  epsilon_D = rnorm(10000, mean = 0, sd = 1),
  epsilon_Y = rnorm(10000, mean = 0, sd = 1),
  U_i = rnorm(10000, mean = 0, sd = 0.5)
)

z_i <- runif(10000, min = 0, max = 1)
df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y
  )
OLS <- lm(Y_i ~ D_i, data = df) 
summary(OLS)
IV <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV)
df <- df %>%
  mutate(
    D_hat = predict(lm(D_i ~ Z_i, data = df)),
    D_tilde = D_i - D_hat
  )
model_a <- lm(Y_i ~ D_hat, data = df)
summary(model_a)
model_b <- lm(Y_i ~ D_i + D_tilde, data = df)
summary(model_b)
df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV5a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5a)

df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
)
IV5b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5b)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV6a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6a)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
  )
IV6b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6b)

df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pZ = length(Z_i == 1)/length(id),
    pD = length(D_i == 1)/length(id),
    compliers = (pZ*D_hat)/pD
  )
length(df$compliers)
cor(df$Z_i, df$D_i)
df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 1),
    pC = 1 - pAT - pNT,
  )
length(df$compliers)
cor(df$Z_i, df$D_i)





set.seed(1)

df <- data.frame(
  id = 1:500,
  epsilon_D = rnorm(10000, mean = 0, sd = 1),
  epsilon_Y = rnorm(10000, mean = 0, sd = 1),
  U_i = rnorm(10000, mean = 0, sd = 0.5)
)

z_i <- runif(10000, min = 0, max = 1)
df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y
  )
OLS <- lm(Y_i ~ D_i, data = df) 
summary(OLS)
IV <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV)
df <- df %>%
  mutate(
    D_hat = predict(lm(D_i ~ Z_i, data = df)),
    D_tilde = D_i - D_hat
  )
model_a <- lm(Y_i ~ D_hat, data = df)
summary(model_a)
model_b <- lm(Y_i ~ D_i + D_tilde, data = df)
summary(model_b)
df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV5a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5a)

df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
)
IV5b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5b)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV6a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6a)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
  )
IV6b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6b)

df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 0),
    pC = 1 - pAT - pNT
  )
summarize(df, pC = mean(pC), pNT = mean(pNT), pAT = mean(pAT))

cor(df$D_i, df$Z_i)

df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 0),
    pC = 1 - pAT - pNT
  )
summarize(df, pC = mean(pC), pNT = mean(pNT), pAT = mean(pAT))

cor(df$D_i, df$Z_i)


set.seed(2)

df <- data.frame(
  id = 1:500,
  epsilon_D = rnorm(10000, mean = 0, sd = 1),
  epsilon_Y = rnorm(10000, mean = 0, sd = 1),
  U_i = rnorm(10000, mean = 0, sd = 0.5)
)

z_i <- runif(10000, min = 0, max = 1)
df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y
  )
OLS <- lm(Y_i ~ D_i, data = df) 
summary(OLS)
IV <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV)
df <- df %>%
  mutate(
    D_hat = predict(lm(D_i ~ Z_i, data = df)),
    D_tilde = D_i - D_hat
  )
model_a <- lm(Y_i ~ D_hat, data = df)
summary(model_a)
model_b <- lm(Y_i ~ D_i + D_tilde, data = df)
summary(model_b)
df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV5a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5a)

df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
)
IV5b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5b)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV6a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6a)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
  )
IV6b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6b)

df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 1),
    pC = 1 - pAT - pNT
  )
summarize(df, pC = mean(pC), pNT = mean(pNT), pAT = mean(pAT))

cor(df$D_i, df$Z_i)
  
df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 1),
    pC = 1 - pAT - pNT
  )
summarize(df, pC = mean(pC), pNT = mean(pNT), pAT = mean(pAT))

cor(df$D_i, df$Z_i)



set.seed(3)

df <- data.frame(
  id = 1:500,
  epsilon_D = rnorm(10000, mean = 0, sd = 1),
  epsilon_Y = rnorm(10000, mean = 0, sd = 1),
  U_i = rnorm(10000, mean = 0, sd = 0.5)
)

z_i <- runif(10000, min = 0, max = 1)
df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y
  )
OLS <- lm(Y_i ~ D_i, data = df) 
summary(OLS)
IV <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV)
df <- df %>%
  mutate(
    D_hat = predict(lm(D_i ~ Z_i, data = df)),
    D_tilde = D_i - D_hat
  )
model_a <- lm(Y_i ~ D_hat, data = df)
summary(model_a)
model_b <- lm(Y_i ~ D_i + D_tilde, data = df)
summary(model_b)
df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV5a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5a)

df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
)
IV5b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5b)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV6a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6a)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
  )
IV6b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6b)

df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 1),
    pC = 1 - pAT - pNT
  )
summarize(df, pC = mean(pC), pNT = mean(pNT), pAT = mean(pAT))

cor(df$D_i, df$Z_i)

df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 1),
    pC = 1 - pAT - pNT
  )
summarize(df, pC = mean(pC), pNT = mean(pNT), pAT = mean(pAT))

cor(df$D_i, df$Z_i)



set.seed(4)

df <- data.frame(
  id = 1:10000,
  epsilon_D = rnorm(10000, mean = 0, sd = 1),
  epsilon_Y = rnorm(10000, mean = 0, sd = 1),
  U_i = rnorm(10000, mean = 0, sd = 0.5)
)

z_i <- runif(10000, min = 0, max = 1)
df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y
  )
OLS <- lm(Y_i ~ D_i, data = df) 
summary(OLS)
IV <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV)
df <- df %>%
  mutate(
    D_hat = predict(lm(D_i ~ Z_i, data = df)),
    D_tilde = D_i - D_hat
  )
model_a <- lm(Y_i ~ D_hat, data = df)
summary(model_a)
model_b <- lm(Y_i ~ D_i + D_tilde, data = df)
summary(model_b)
df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV5a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5a)

df <- df %>%
  mutate(
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
)
IV5b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV5b)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 1 * Z_i + 6 * U_i + epsilon_Y
)
IV6a <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6a)
df <- df %>%
  mutate(
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + -1 * Z_i + 6 * U_i + epsilon_Y
  )
IV6b <- ivreg(Y_i ~ D_i | Z_i, data = df)
summary(IV6b)

df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 5 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 1),
    pC = 1 - pAT - pNT
  )
summarize(df, pC = mean(pC), pNT = mean(pNT), pAT = mean(pAT))

cor(df$D_i, df$Z_i)

df <- df %>%
  mutate(
    Z_i = as.numeric(z_i > 0.5),
    D_i = as.numeric(-4 + 10 * Z_i + 4 * U_i + epsilon_D > 0),
    Y_i = 3 + 2 * D_i + 0 * Z_i + 6 * U_i + epsilon_Y,
    pNT = mean(Z_i == 1 & D_i == 0),
    pAT = mean(Z_i == 0 & D_i == 1),
    pC = 1 - pAT - pNT
  )
summarize(df, pC = mean(pC), pNT = mean(pNT), pAT = mean(pAT))

cor(df$D_i, df$Z_i)
