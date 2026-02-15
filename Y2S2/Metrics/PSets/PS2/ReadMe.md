# PS2 Accompanying Document

## Overview
This document provides and overview of the PS2 code and how to run it. Similar to PS1, the code is organized by problem: P1, P2, and then within each problem, 
there are separate files for each part of the problem, which are then imported into the main file for that problem. All code is in Python, and the main files for 
each problem are `Problem1.py` and `Problem2.py`. The helper files are named according to the part of the problem, for example, `logit_1a.py` for part 1a of problem 1. 

## Running the Code
To run the code, you will need to have Python installed on your computer, along with the necessary libraries, numpy and scipy. These should be installed, but if not, you can install them using pip:

```
pip install numpy scipy
```

Once you have the necessary libraries installed, you can run the main files for each problem. For example, to run problem 1, you would run:

```
python Problem1.py
```

## Writeup

The writeup for the problem set is in the main folder, and is named `PS2_Mason.pdf`. It contains the answers to the questions in the problem set.

## Code Organization

The code is organized as follows:
- `Problem1.py`: Main file for problem 1, which imports the helper files for each part of the problem.
- `logit_1a.py`: Helper file for part 1a of problem 1, which contains the code for fitting a logistic regression model using MLE
- `AME_1b.py`: Helper file for part 1b of problem 1, which contains the code for calculating the average marginal effects of the logistic
- `Delta_1c.py`: Helper file for part 1c of problem 1, which contains the code for calculating the delta method standard errors for the average marginal effects
- `Boot_1d.py`: Helper file for part 1d of problem 1, which contains the code for calculating the bootstrap standard errors for the average marginal effects
- `Probit_1e.py`: Helper file for part 1e of problem 1, which contains the code for fitting a probit model using MLE
- `Probit_AME_1f.py`: Helper file for part 1f of problem 1, which contains the code for calculating the average marginal effects of the probit model
- `Problem2.py`: Main file for problem 2, which imports the helper files for each part of the problem.
- `MultLog_2a.py`: Helper file for part 2a of problem 2, which contains the code for fitting a multinomial logistic regression model using MLE
- `MultLog_2b.py`: Helper file for part 2b of problem 2, which runs the multinomial logit using MLE with new starting values
- `MultLog_2d.py`: Helper file for part 2d of problem 2, which contains the code for calculating the average marginal effects of the multinomial logit model for having a parent with a BA
- `MultLog_2e.py`: Helper file for part 2e of problem 2, which contains the code for calculating the average predicted probabilities of the choices
- `MultLog_2f.py`: Helper file for part 2f of problem 2, which contains the code for calculating the average predicted probability with $Y=4$ removed
- `MultLog_2g.py`: Helper file for part 2g of problem 2, which contains the code for calculating the average change in consumer surplus with $Y=4$ removed 

## Contact

If there are questions or issues, please email me at my school address. Further, please reach out if you would like to further discuss the Python stuff as discussed. I can do my best to explain the code, the environment, and the general differences in coding in Python vs Matlab.
