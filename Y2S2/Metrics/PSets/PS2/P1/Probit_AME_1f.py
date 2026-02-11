
import numpy as np
from scipy.stats import norm


# Probit function
def predict_prob(W, beta):
    return norm.cdf(W @ beta)

def ame_probit(W, beta, k, x1=1.0, x0=0.0):
    W1 = W.copy()
    W0 = W.copy()

    W1[:, k] = x1
    W0[:, k] = x0
    return (predict_prob(W1, beta) - predict_prob(W0, beta)).mean()
