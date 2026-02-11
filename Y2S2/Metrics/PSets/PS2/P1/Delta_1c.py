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

# Delta method call
def delta_method(H_inv, g):
    # variance
    sandwich = g.T @ H_inv @ g
    # std. error
    se_delta = np.sqrt(sandwich)
    # return value
    return se_delta

def delta_se(beta_hat, W, Y):
    # Pack all into one function
    # Hessian call
    _, H_inv = hess_nll(beta_hat, W, Y)
    # Gradient call
    grad_g = grad_nll(beta_hat, W, Y)
    # return se
    return delta_method(H_inv, grad_g)
