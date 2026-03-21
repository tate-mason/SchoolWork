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
#======================================#

df = sp.io.loadmat("../../Data/Prob1/dataHW6_problem1.mat")

print(df.keys())

X_s = np.asarray(df["X1"]).squeeze() # static
X_d = np.asarray(df["X1t"]).squeeze()  # dynamic

Y = np.asarray(df["Y"]).squeeze()
Y_0 = np.asarray(df["LY1"]).squeeze()

#=====================================#
# Define Parameters:                  #
#=====================================#

np.random.default_rng(219)

N, T = X_d.shape[0], X_d.shape[1]
J = int(Y.max()) + 1


def log_lik(theta):
    # unpack: 3 params per choice x 3 choices + delta + beta
    params = theta[:9].reshape(3, 3)  # (J-1, 3) — [const, gender, health] per choice
    delta  = theta[9]
    beta   = 0.9 
    eps = np.random.gumbel(loc=0,scale=1)

    V  = np.zeros((N, T, J))
    EV = np.zeros((N, J))

    for t in range(T-1, -1, -1):
        prev_choice = Y_0 if t == 0 else Y[:, t-1]
        u = np.zeros((N, J))

        for j in range(1, J):  # j=0 stays 0
            switching   = delta * (prev_choice != j)
            u[:, j]     = (params[j-1, 0]             # constant
                         + params[j-1, 1]*X_s[:, 1]   # gender
                         + params[j-1, 2]*X_d[:, t]   # health
                         - switching)

        # retirement is absorbing: zero future value for j=0
        emax       = sp.special.logsumexp(EV[:,1:], axis=1, keepdims=True)
        V[:, t, :] = u + beta * emax
        V[:, t, 0] = 0   # retirement: no future utility

        EV = V[:, t, :]

    # choice probs
    P = np.zeros((N, T, J))
    for t in range(T):
        V_t        = V[:, t, :]
        P[:, t, :] = np.exp(V_t - sp.special.logsumexp(V_t, axis=1, keepdims=True))

    # likelihood — skip retired individuals
    Y_int = Y.astype(int)
    Y_0_int = Y_0.astype(int)
    ll    = 0.0
    for t in range(T):
        if t == 0:
            active = (Y_0_int != 0)
        else:
            active = (Y_int[:,t-1] != 0)
        chosen_p     = P[np.arange(N), t, Y_int[:, t]]
        ll          += np.sum(np.log(chosen_p[active] + 1e-10))
    return -ll

# true params as starting guess

x0 = np.zeros(10)

res = sp.optimize.minimize(log_lik, x0, method='L-BFGS-B', 
                           options={'disp':True, 'ftol':1e-12, 'gtol':1e-8})
print(res.x.reshape(-1))
