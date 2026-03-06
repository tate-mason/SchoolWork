# Homework 4 ReadMe

## Problem 1:
The first problem is to implement a mixed logit model. Code is structured as follows:
- `Problem1.py`: Main script to run the mixed logit model.
- `Prob1a.py`: Contains the implementation of the mixed logit model for part (a).`
- `Prob1b.py`: Calculates AME
- `Prob1c.py`: Calculates S.E. of AME
- `Prob1d.py`: Mixed Logit with GH quadrature

## Problem 2:
The second problem estimates a mixed logit with panel data.
- `Problem2.py`: Main script to run the mixed logit model with panel data.
- `Prob2a.py`: Contains the implementation of the mixed logit model for part (a).
- `Prob2b.py`: Implements EM algorithm for estimation.

## File Structure:
```
| PS4 /
|-- Problem1
|   |-- Problem1.py
|   |-- Prob1a.py
|   |-- Prob1b.py
|   |-- Prob1c.py
|   |-- Prob1d.py
|   |-- dataHW4_Problem1.mat
|-- Problem2
|   |-- Problem2.py
|   |-- Prob2a.py
|   |-- Prob2b.py
|   |-- dataHW4_Problem2.mat
|-- Writeup
|-- README.md
|-- HW4.pdf
|-- Mason_Writeup.pdf
```

## Libraries Needed:
```python
import numpy as np
import scipy.io
import scipy.optimize
import scipy
import pandas
```

## Contact:
For any questions or clarifications, please contact [Tate Mason] at [Tate.Mason@uga.edu].
