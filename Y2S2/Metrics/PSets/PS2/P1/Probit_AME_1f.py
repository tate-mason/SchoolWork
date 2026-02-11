
import numpy as np
from scipy.stats import norm


# Probit function
def predict_prob(W, beta):
    return norm.cdf(W @ beta) # cdf of z = W@beta

def ame_probit(W, beta, k, x1=1.0, x0=0.0):
    W1 = W.copy() # treated
    W0 = W.copy() # untreated

    W1[:, k] = x1 # defining treated 
    W0[:, k] = x0 # defining untreated
    return (predict_prob(W1, beta) - predict_prob(W0, beta)).mean() # AME
