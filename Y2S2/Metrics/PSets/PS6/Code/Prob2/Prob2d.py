import numpy as np
import scipy as sp
from scipy.special import logsumexp

#=====================================================#
# This file contains the function for part (d) of     #
# problem 2. It will estimate the DDC, recovering the #
# parameters of the utility function and discount     #
# factor.                                             #
#                                                     #
# Libraries used in this file:                        #
# - numpy                                             #
# - scipy                                             #
#                                                     #
# Functions:                                          #
# - log_lik: computes the negative log-likelihood     #
#   given parameters and data via backward induction  #
# - estimate_params: wraps log_lik with L-BFGS-B      #
#=====================================================#

def log_lik(theta, X, X1, Y, Y_0, transition_matrix, x_grid, X1t_discrete):

    N, T   = X1.shape[0], X1.shape[1]  # individuals and time periods
    J      = 4                          # choice space: 0=retire, 1=not work, 2=part-time, 3=full-time

    # --- Unpack parameters ---
    beta_s = theta[0:6].reshape(3, 2)  # (3 x 2) static parameters, one row per non-retirement choice
    beta_d = theta[6:9]                 # (3,) health state coefficients, one per non-retirement choice
    delta  = theta[9]                   # switching cost
    beta   = theta[10]                  # discount factor

    # --- Cast choice arrays to int ---
    Y_int   = Y.astype(int)
    Y_0_int = Y_0.astype(int)

    # --- Backward induction ---
    # EV_t1[t] stores the value function for period t, shape (N, J)
    # EV_grid tracks the value function on the 10-point x_grid, shape (10, J)
    EV_t1   = np.zeros((T, N, J))
    EV      = np.zeros((N, J))      # terminal EV (zeros at T)
    EV_grid = np.zeros((10, J))     # terminal EV on grid (zeros at T)

    for t in range(T - 1, -1, -1):
        EV_t      = np.zeros((N, J))
        EV_t_grid = np.zeros((10, J))

        # Discrete state indices for each individual at time t
        state_idx = np.clip(
            np.searchsorted(x_grid, X1t_discrete[:, t]), 0, 9
        )  # (N,)

        # Emax on the grid: logsumexp over choices at each grid point
        emax_grid = logsumexp(EV_grid, axis=1)  # (10,)

        for j in range(1, J):
            # --- Individual-level flow utility ---
            indiv_effects  = X @ beta_s[j - 1]                                    # (N,)
            health_effects = beta_d[j - 1] * X1[:, t]                             # (N,)
            prev_choice    = Y_0_int if t == 0 else Y_int[:, t - 1]               # (N,)
            switching      = delta * (prev_choice != j)                            # (N,)
            u_j            = indiv_effects + health_effects - switching            # (N,)

            # --- Grid-level flow utility (no individual effects, no switching) ---
            u_j_grid = beta_d[j - 1] * x_grid                                     # (10,)

            # --- Continuation values ---
            # transition_matrix[:, state_idx, j] is (10, N); transpose to (N, 10)
            EV_t[:, j]  = u_j      + beta * (transition_matrix[:, state_idx, j-1].T @ emax_grid)
            EV_t_grid[:, j] = u_j_grid + beta * (transition_matrix[:, :, j-1].T      @ emax_grid)

        # Normalize retirement to 0
        EV_t[:, 0]      = 0.0
        EV_t_grid[:, 0] = 0.0

        EV_t1[t]  = EV_t
        EV        = EV_t
        EV_grid   = EV_t_grid

    # --- Log-likelihood ---
    ll = 0.0

    for t in range(T):
        prev   = Y_0_int if t == 0 else Y_int[:, t - 1]
        active = (prev != 0)  # only non-retired individuals contribute

        # Flow utilities
        u = np.zeros((N, J))
        for j in range(1, J):
            u[:, j] = X @ beta_s[j - 1] + beta_d[j - 1] * X1[:, t] - delta * (prev != j)
        # Continuation value: EV_t1[t] already has beta baked in from backward pass
        cont = EV_t1[t] if t < T - 1 else np.zeros((N, J))
        V_t = u + cont
        V_t[:, 0] = 0.0  # retirement payoff normalized to 0

        # Logit log-likelihood: V_chosen - logsumexp(V_all)
        numer = V_t[active, Y_int[active, t]]                    # (N_active,)
        denom = logsumexp(V_t[active], axis=1)                   # (N_active,)
        ll   += np.sum(numer - denom)

    return -ll  # return negative log-likelihood for minimization


def estimate_params(X, X1, Y, Y_0, transition_matrix, x_grid, X1t_discrete):
    from scipy.optimize import minimize

    # Initial guess: zeros for utility params, 0.9 for discount factor
    theta_init = np.zeros(11)

    result = minimize(
        log_lik,
        theta_init,
        args=(X, X1, Y, Y_0, transition_matrix, x_grid, X1t_discrete),
        method='BFGS'
    )

    return result.x  # return the estimated parameters
