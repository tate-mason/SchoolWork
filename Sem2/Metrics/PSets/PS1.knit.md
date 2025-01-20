---
title: "Problem Set 1"
author: "Tate Mason"
date: 01-22-2025
format: 
    pdf:
        number-sections: true
---



# Problem 1:
Use the stringr package and its `str_length` function to calculate the number of characters in each element of `x`.



::: {.cell}

```{.r .cell-code}
library(stringr)
x <- c('economics', 'econometrics','ECON 4750')
str_length(x)
```

::: {.cell-output .cell-output-stdout}

```
[1]  9 12  9
```


:::
:::



# Problem 2:
Try three approaches to calculate the sum of the numbers 1 to $n$

## Approach 1:


::: {.cell}

```{.r .cell-code}
sum_one_to_n_1 <- function(n) {
    x <- seq(1:n)
    sum(x)
}
sum_one_to_n_1(100)
```

::: {.cell-output .cell-output-stdout}

```
[1] 5050
```


:::
:::



## Approach 2:


::: {.cell}

```{.r .cell-code}
sum_one_to_n_2 <- function(n) {
    y <- (n*(n+1))/2
    y
}
sum_one_to_n_2(100)
```

::: {.cell-output .cell-output-stdout}

```
[1] 5050
```


:::
:::



## Approach 3:


::: {.cell}

```{.r .cell-code}
sum_one_to_n_3 <- function(n) {
    sum <- 0
    for (x in 1:n) {
        sum <- sum + x
    }
    sum
}   
sum_one_to_n_3(100)
```

::: {.cell-output .cell-output-stdout}

```
[1] 5050
```


:::
:::



# Problem 3:

## Part A:
Write a function which computes the Fibonacci sequence.


::: {.cell}

```{.r .cell-code}
fibonacci <- function(n) {
    a <- 0
    b <- 1
    for (i in 3:n) {
        c <- a+b
        a <- b
        b <- c
    }
    c
}
fibonacci(5)
```

::: {.cell-output .cell-output-stdout}

```
[1] 3
```


:::
:::



## Part B:
Write a function which computes the 


::: {.cell}

```{.r .cell-code}
alt_seq <- function(a,b,n) {
    for (i in 3:n) {
        c <- a+b
        a <- b
        b <- c
    }
    c
}
alt_seq(3,7,4)
```

::: {.cell-output .cell-output-stdout}

```
[1] 17
```


:::
:::



# Problem 4: 

## Part A:
Write a function which takes `x` as an argument and returns `TRUE` if prime or `FALSE` otherwise.


::: {.cell}

```{.r .cell-code}
is_prime <- function(x) {
    if (x==2) {
        return(TRUE)
    }
    if (x <= 1) {
        return(FALSE)
    }
    for (i in 2:(x-1)) {
        if (x %% i ==0) {
            return(FALSE)
        }
    }
    return(TRUE)
}
a1 <- is_prime(7)
a2 <- is_prime(10)
print(c(a1,a2))
```

::: {.cell-output .cell-output-stdout}

```
[1]  TRUE FALSE
```


:::
:::



## Part B:
Write a function to list all prime numbers 1-n


::: {.cell}

```{.r .cell-code}
prime <- function(n) {
    if (n>=2) {
        x = seq(2,n)
        primes = c()
        for (i in seq(2,n)) {
            if (any(x == i)) {
                primes = c(primes, i)
                x = c(x[(x %% i) != 0], i)
            }
        }
        return(primes)
    }
    else {
        return("Input should be at least 2")
    }
}
prime(100)
```

::: {.cell-output .cell-output-stdout}

```
 [1]  2  3  5  7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97
```


:::
:::



# Problem 5:
## Part A:
Counting observations in `Iris`


::: {.cell}

```{.r .cell-code}
length(iris)
```

::: {.cell-output .cell-output-stdout}

```
[1] 5
```


:::
:::



## Part B:
Finding the mean sepal length in the dataset


::: {.cell}

```{.r .cell-code}
mean(iris$Sepal.Length)
```

::: {.cell-output .cell-output-stdout}

```
[1] 5.843333
```


:::
:::



## Part C:
Calculate the average of the variable `Sepal.Width`. Package `dplyr` used but loading now shown.




::: {.cell}

```{.r .cell-code}
iris %>% filter(Species == 'setosa') %>% summarise(mean(iris$Sepal.Width)) 
```

::: {.cell-output .cell-output-stdout}

```
  mean(iris$Sepal.Width)
1               3.057333
```


:::
:::



## Part D:
Sort the dataset by variable `Petal.Length` and print only the first ten rows


::: {.cell}

```{.r .cell-code}
asc_pl <- sort(iris$Petal.Length)
print_pl <- asc_pl[1:10]
print_pl
```

::: {.cell-output .cell-output-stdout}

```
 [1] 1.0 1.1 1.2 1.2 1.3 1.3 1.3 1.3 1.3 1.3
```


:::
:::



# Problem 6:
Create a function which solves the quadratic equation and provides two solutions.


::: {.cell}

```{.r .cell-code}
quadratic_solver <- function(a,b,c) {
    p <- (-b + sqrt(b^2 - 4*a*c))/(2*a)
    m <- (-b - sqrt(b^2 - 4*a*c))/(2*a)
    print(c(p,m))
}
quadratic_solver(1,4,3)
```

::: {.cell-output .cell-output-stdout}

```
[1] -1 -3
```


:::
:::

