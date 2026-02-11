import numpy as np

# Defining the logistic function, negative log-likelihood, gradient, and Hessian for the logit model

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
    return W.T @ (p-Y) # Gradient of the negative log-likelihood function for the logit model

def hess_nll(beta, W, Y):
    # Defining the Hessian for the logit
    z = W @ beta
    p = logistic(z)
    # Calculate the predicted probabilities using the logistic function
    w = p * (1-p)
    return W.T @ (W * w[:, None]) # Hessian of the negative log-likelihood function for the logit model

def fit_logit_mle(W, Y, b0):
    # import optimization method from scipy
    from scipy import optimize as op
    # Optimization Routine
    res = op.minimize(
        nll,
        b0,
        args = (W,Y),
        jac = grad_nll,
    )

    # Extracting coefficients and calculating standard errors
    beta_hat = res.x
    H = hess_nll(beta_hat, W, Y)
    se_hat = np.sqrt(np.diag(np.linalg.inv(H)))

    # Return results
    return beta_hat, se_hat, res

def predict_prob(W, beta):
    return logistic(W @ beta)

def ame_dummy_discrete(beta, W, k, x1=1.0, x0=0.0):
    W1 = W.copy()
    W0 = W.copy()

    W1[:, k] = x1
    W0[:, k] = x0
    return (predict_prob(W1, beta) - predict_prob(W0, beta)).mean()
