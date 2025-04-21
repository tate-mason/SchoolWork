---
title: Problem Set 6
author: Tate Mason
format: pdf
---



# Hansen 17.2

# Question 1



::: {.cell}

```{.r .cell-code}
library(Matrix)
library(dplyr)
```

::: {.cell-output .cell-output-stderr}

```

Attaching package: 'dplyr'
```


:::

::: {.cell-output .cell-output-stderr}

```
The following objects are masked from 'package:stats':

    filter, lag
```


:::

::: {.cell-output .cell-output-stderr}

```
The following objects are masked from 'package:base':

    intersect, setdiff, setequal, union
```


:::

```{.r .cell-code}
library(tidyr)
```

::: {.cell-output .cell-output-stderr}

```

Attaching package: 'tidyr'
```


:::

::: {.cell-output .cell-output-stderr}

```
The following objects are masked from 'package:Matrix':

    expand, pack, unpack
```


:::

```{.r .cell-code}
library(magrittr)
```

::: {.cell-output .cell-output-stderr}

```

Attaching package: 'magrittr'
```


:::

::: {.cell-output .cell-output-stderr}

```
The following object is masked from 'package:tidyr':

    extract
```


:::

```{.r .cell-code}
df <- read.csv('metrics.csv')
head(df)
```

::: {.cell-output .cell-output-stdout}

```
   X id displaced EDUC first.displaced  race gender year   earn    learn
1 78  6         0  COL               0 White   Male 2001  43500 10.68052
2 79  6         0  COL               0 White   Male 2003  56500 10.94200
3 80  6         0  COL               0 White   Male 2005  65000 11.08214
4 81  6         0  COL               0 White   Male 2007  86000 11.36210
5 82  6         0  COL               0 White   Male 2009  90300 11.41089
6 83  6         0  COL               0 White   Male 2011 105000 11.56172
```


:::
:::



## Part A

## Part B

## Part C

## Part D

# Question 2

# Question 3

