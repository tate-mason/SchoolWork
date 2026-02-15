import numpy as np
import scipy as sp

"""
Helper file to use Delta Method to recover s.e. for AME of Parent having 4 yr.
"""

## All functions come straight from 1b helper
# Logitstic function
def logistic(z):
    return 1 / (1+np.exp(-z))

def nll(beta, W, Y):
    z = W @ beta
    return -np.sum(Y*z - np.log1p(np.exp(z))) # Negative log-likelihood function for the logit model

def grad_nll(beta, W, Y):
    # Defining the gradient for the logit
    z = W @ beta
    # Calculate the predicted probabilities using the logistic function
    p = logistic(z)
    g = W.T @ (p-Y) # Gradient of the negative log-likelihood function for the logit model
    return g

def hess_nll(beta, W, Y):
    # Defining the Hessian for the logit
    z = W @ beta
    p = logistic(z)
    # Calculate the predicted probabilities using the logistic function
    w = p * (1-p)
    H = W.T @ (W * w[:, None]) # Hessian of the negative log-likelihood function for the logit model
    H_inv = np.linalg.inv(H)
    return H, H_inv

# logistic distribution
def predict_prob(W, beta):
    return logistic(W @ beta)

# recover gradient of ame
def grad_ame_discrete(beta, W, k, x1=1.0, x0=0.0):
    W1 = W.copy()
    W0 = W.copy()

    W1[:, k] = x1
    W0[:, k] = x0

    p1 = predict_prob(W1, beta)
    p0 = predict_prob(W0, beta)

    # gradients for those with and without parentBA
    g1 = (p1*(1-p1))[:, None] * W1
    g0 = (p0*(1-p0))[:, None] * W0
    return (g1-g0).mean(axis=0)

# delta method
def delta(beta, W, Y):
    #call hessian and gradient functions
    H, H_inv = hess_nll(beta, W, Y)
    grad_m = grad_ame_discrete(beta, W, k=1)

    # compute se.
    se_ame = np.sqrt(grad_m @ H_inv @ grad_m)
    return se_ame



