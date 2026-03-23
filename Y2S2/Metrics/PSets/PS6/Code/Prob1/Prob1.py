import pandas as pd
import scipy as sp
import numpy as np

#======================================#
# Problem 1 - PS6: DDC Problem         #
#  - Libraries used:                   #
#    * Pandas: Data tables for results #
#    * Scipy: optimization routines    #
#    * Numpy: Linear algebra and       #
#             other numeric operations #
#  - Functions:                        #
#   * log_lik: computes the negative   #
#   log-likelihood of the DDC model    #
#   given parameters                   #
#======================================#

df = sp.io.loadmat("../../Data/Prob1/dataHW6_problem1.mat") # load data

print(df.keys()) # check column names

X_s = np.asarray(df["X1"]).squeeze() # static
X_d = np.asarray(df["X1t"]).squeeze()  # dynamic

Y = np.asarray(df["Y"]).squeeze() # Y
Y_0 = np.asarray(df["LY1"]).squeeze() # initial Y

#=====================================#
# Define Parameters:                  #
#=====================================#

np.random.default_rng(219) # set random seed

N, T = X_d.shape[0], X_d.shape[1] # define individual and time space
J = int(Y.max()) + 1 # choice space

def log_lik(theta):
    beta_s = theta[0:6].reshape(3,2) # static parameters
    beta_d = theta[6:9] # dynamic parameters
    delta = theta[9] # switching cost
    beta = theta[10] # disc. factor

    V = np.zeros((N, T, J)) # value in t
    EV = np.zeros((N, J)) # exp. value in retirement
    EV_t1 = np.zeros((T+1, N, J)) # exp. value in t+1

    for t in range(T-1, -1, -1):
        EV_t = np.zeros((N,J)) # exp. value in t
        for s in range(J):
            u = np.zeros((N, J)) # initial utility

            for j in range(1, J):
                indiv_effects  =  X_s @ beta_s[j-1] # X1 effects
                health_effects = beta_d[j-1] * X_d[:, t] # X1t effects
                switching      = delta * (s!=j) # switching cost
                u[:,j] = indiv_effects + health_effects + switching # utility of choice j

            V_t = u + beta * EV # value of Y={1,2,3}
            V_t[:, 0] = 0  # retirement: no future utility 
            EV_t[:,s] = sp.special.logsumexp(V_t, axis=1) # exp value in t+1
        EV_t1[t] = EV_t # update exp. value
        EV = EV_t # set exp. value for next iteration
    # --- Log-likelihood ---
    ll      = 0.0 # log-likelihood
    Y_int   = Y.astype(int) # convert Y to integer for indexing
    Y_0_int = Y_0.astype(int) # convert Y_0 to integer for indexing
 
    for t in range(T):
        prev   = Y_0_int if t == 0 else Y_int[:, t - 1]  # (N,) state variable
        active = (prev != 0)                               # exclude already-retired
 
        u = np.zeros((N, J))
        for j in range(1, J):
            u[:, j] = (X_s @ beta_s[j-1] + beta_d[j-1] * X_d[:, t] - delta * (prev != j)) # utility of choice j
 
        # Continuation value depends on which j is chosen (becomes next-period state)
        cont    = beta * EV_t1[t + 1] if t < T - 1 else np.zeros((N, J)) # no continuation value in last period
        V_t     = u + cont # value of each choice in t
        V_t[:, 0] = 0.0 # retirement: no utility
 
        log_P   = V_t - sp.special.logsumexp(V_t, axis=1, keepdims=True) # log choice probabilities
        ll     += np.sum(log_P[np.arange(N), Y_int[:, t]][active]) # add log-prob of observed choice for active individuals
 
    return -ll # return negative log-likelihood for minimization

x0  = np.zeros(11) # initial guess for parameters
res = sp.optimize.minimize(log_lik, x0, method='Nelder-Mead',
                           options={'maxiter': 50000, 'xatol': 1e-5,
                                    'fatol': 1e-5, 'adaptive': True}) # minimzation procedure

res_df = pd.DataFrame({
    "Parameter": ["beta_s1_const", "beta_s1_gender",
                  "beta_s2_const", "beta_s2_gender",
                  "beta_s3_const", "beta_s3_gender",
                  "beta_d1", "beta_d2", "beta_d3",
                  "delta", "beta"], # label
    "Estimate":  res.x, # call results
    "True":      [-1., .5, -0.25, .75, -.5, 1., .5, .75, 1., 0.4, 0.9] # list true parameters
})

print(res_df.to_string(index=False)) # print results in a nice format
