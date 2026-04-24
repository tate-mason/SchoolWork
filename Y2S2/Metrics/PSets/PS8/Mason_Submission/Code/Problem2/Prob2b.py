import numpy as np
import scipy as sp
from scipy.special import logsumexp

"""
This file simulates N=20,000 agents through the two-period model. Contains:
    - unpack_params: maps unconstrained theta -> structural parameters
    - sim_moments:   takes b_params and returns (w_sim, k_sim, y_sim)
"""

def unpack_params(b_params):

    a = b_params[0:4] # delta parameters for the 5 wage categories (5th is base, so only 4 free params)
    b = b_params[4:7] # rho parameters for the transition matrix (constrained to sum to 1 with symmetry, so only 3 free params)
    c = b_params[7:9] # beta and gamma parameters (positive, so exponentiate)

    # delta_j = exp(a_j) / (1 + sum(exp(a_1:4))),  delta_5 = 1/(1+sum(exp(a_1:4)))
    denom = 1.0 + np.sum(np.exp(a))
    delta = np.append(np.exp(a) / denom, 1.0 / denom)   # (5,)

    # rho_j = exp(b_j) / (exp(b1) + 2*exp(b2) + 2*exp(b3))
    denom_rho = np.exp(b[0]) + 2*np.exp(b[1]) + 2*np.exp(b[2])
    rho1 = np.exp(b[0]) / denom_rho
    rho2 = np.exp(b[1]) / denom_rho
    rho3 = np.exp(b[2]) / denom_rho

    beta_p  = np.exp(c[0])
    gamma_p = np.exp(c[1])

    Sigma = np.array([
        [rho1+rho2+rho3, rho2,      rho3,      0,           0             ],
        [rho2+rho3,      rho1,      rho2,      rho3,        0             ],
        [rho3,           rho2,      rho1,      rho2,        rho3          ],
        [0,              rho3,      rho2,      rho1,        rho2+rho3     ],
        [0,              0,         rho3,      rho2,        rho1+rho2+rho3],
    ])

    return delta, rho1, rho2, rho3, beta_p, gamma_p, Sigma


def sim_moments(b_params):

    # set parameters and grids
    N    = 20000
    rng  = np.random.default_rng(seed=219)
    disc = 0.9

    delta, rho1, rho2, rho3, beta, gamma, Sigma = unpack_params(b_params)

    w_grid = np.array([0.5, 0.75, 1.0, 1.5, 2.0])
    Nw     = len(w_grid)

    # savings/asset grid — shared across both periods
    Nk     = 100
    k_min  = 0.0
    k_max  = 5.0
    k_grid = np.linspace(k_min, k_max, Nk)

    # wealth grid for period 1 policy function — agents interpolated onto this
    Nk1     = 50
    k1_min  = 1.5
    k1_max  = 3.5
    k1_grid = np.linspace(k1_min, k1_max, Nk1)

    # draw shocks upfront — (N, Nk), indexed into k_grid dimension
    eps_work   = rng.gumbel(size=(N, Nk))
    eps_nowork = rng.gumbel(size=(N, Nk))

    # ------------------------------------------------------------------ #
    # Period 2: Emax(k2, w2) over the savings x wage grid                 #
    # With Type I EV shocks: E[max] = log(exp(V_work) + exp(V_nowork))   #
    # ------------------------------------------------------------------ #

    Emax2 = np.zeros((Nk, Nw))
    for ik, k2 in enumerate(k_grid):
        for iw, w2 in enumerate(w_grid):
            V_work   = beta * np.log(w2 + k2) - gamma + eps_work[:, ik] # value of working in period 2, indexed by k2 grid point
            V_nowork = beta * np.log(k2) + eps_nowork[:, ik] if k2 > 0 else np.full(N, -np.inf) # value of not working in period 2, indexed by k2 grid point
            Emax2[ik, iw] = np.mean(np.logaddexp(V_work, V_nowork)) # expected value in period 2 given k2 and w2, integrating over shocks

    # integrating over next-period wage via transition matrix
    EV1 = Emax2 @ Sigma.T   # (Nk, Nw)

    # ------------------------------------------------------------------ #
    # Period 1 policy: solve for optimal k2 on k1_grid x w_grid           #
    # 50 x 5 = 250 grid solves instead of 20,000 agent-level optimizations#
    # obj = beta*log(c) - gamma*(work) + disc*EV(k2), no shocks here      #
    # ------------------------------------------------------------------ #

    k2_pol_work   = np.zeros((Nk1, Nw)) # optimal k2 for each (k1, w) on the grid, if working in period 1
    k2_pol_nowork = np.zeros((Nk1, Nw)) # optimal k2 for each (k1, w) on the grid, if not working in period 1

    for iw, wi in enumerate(w_grid):
        EV_on_kgrid = EV1[:, iw]   # (Nk,) # expected value in period 2 for each k2 on the grid, given wage wi in period 1

        for ik1, ki in enumerate(k1_grid):

            k2_cand = k_grid.copy() # candidate k2 choices from the grid

            # -- working --
            c_work     = wi + ki - k2_cand # consumption if working in period 1, for each candidate k2
            feasible_w = c_work > 1e-10 # filter out infeasible choices where consumption would be negative or zero
            obj_work   = np.full(Nk, -np.inf) # objective values for working, initialized to -inf for infeasible choices
            obj_work[feasible_w] = (beta * np.log(c_work[feasible_w]) # objective value for working in period 1, for feasible candidate k2 choices
                                    - gamma
                                    + disc * EV_on_kgrid[feasible_w])
            k2_pol_work[ik1, iw] = k2_cand[np.argmax(obj_work)] # optimal k2 choice for working in 1

            # -- not working --
            c_nowork    = ki - k2_cand
            feasible_nw = c_nowork > 1e-10
            obj_nowork  = np.full(Nk, -np.inf)
            obj_nowork[feasible_nw] = (beta * np.log(c_nowork[feasible_nw])
                                       + disc * EV_on_kgrid[feasible_nw])
            k2_pol_nowork[ik1, iw] = k2_cand[np.argmax(obj_nowork)]

    # ------------------------------------------------------------------ #
    # Period 1: draw agents, interpolate policy to their actual k1        #
    # ------------------------------------------------------------------ #

    k1     = rng.uniform(k1_min, k1_max, size=N) # initial wealth/savings for each agent in period 1, drawn uniformly from the k1 grid range
    w1_idx = rng.choice(Nw, size=N, p=delta) # initial wage category for each agent in period 1, drawn from the distribution defined by delta
    w1     = w_grid[w1_idx] # actual wage for each agent in period 1, based on their wage category

    k2_work   = np.zeros(N)
    k2_nowork = np.zeros(N)

    for iw in range(Nw):
        mask = w1_idx == iw # boolean mask for agents with wage category iw in period 1
        k2_work[mask]   = np.interp(k1[mask], k1_grid, k2_pol_work[:, iw])
        k2_nowork[mask] = np.interp(k1[mask], k1_grid, k2_pol_nowork[:, iw])

    # ------------------------------------------------------------------ #
    # Period 1 utilities — shocks indexed by nearest k_grid point         #
    # ------------------------------------------------------------------ #

    ik_w  = np.clip(np.searchsorted(k_grid, k2_work),   0, Nk - 1)  # find the index of the nearest k_grid point for each agent's optimal k2 if working, clipped to valid range
    ik_nw = np.clip(np.searchsorted(k_grid, k2_nowork), 0, Nk - 1)  # find the index of the nearest k_grid point for each agent's optimal k2 if not working, clipped to valid range

    c1_w  = w1 + k1 - k2_work  # consumption in period 1 if working, for each agent
    c1_nw = k1      - k2_nowork # consumption in period 1 if not working, for each agent

    EV_w  = np.array([np.interp(k2_work[i],   k_grid, EV1[:, w1_idx[i]]) for i in range(N)]) # expected value in period 2 for each agent if working in period 1, interpolated from the EV1 grid based on their optimal k2 and wage category
    EV_nw = np.array([np.interp(k2_nowork[i], k_grid, EV1[:, w1_idx[i]]) for i in range(N)]) # expected value in period 2 for each agent if not working in period 1, interpolated from the EV1 grid based on their optimal k2 and wage category

    # value functions for working or not
    V1_work   = (beta * np.log(np.maximum(c1_w,  1e-300))
                 - gamma
                 + eps_work[np.arange(N),  ik_w]
                 + disc * EV_w)

    V1_nowork = (beta * np.log(np.maximum(c1_nw, 1e-300))
                 + eps_nowork[np.arange(N), ik_nw]
                 + disc * EV_nw)

    log_denom = np.logaddexp(V1_work, V1_nowork)
    P1_work   = np.exp(V1_work - log_denom) # probability of working in period 1 for each agent, based on the value functions and shocks

    L1 = (rng.uniform(size=N) < P1_work).astype(int) # labor supply decision in period 1 for each agent, drawn from a Bernoulli distribution with probability P1_work
    k2 = np.where(L1 == 1, k2_work, k2_nowork) # actual k2 choice for each agent based on their labor supply decision in period 1

    # ------------------------------------------------------------------ #
    # Period 2 wage draw via transition matrix                            #
    # ------------------------------------------------------------------ #

    w2_idx = np.array([rng.choice(Nw, p=Sigma[w1_idx[i]]) for i in range(N)])
    w2     = w_grid[w2_idx]

    # ------------------------------------------------------------------ #
    # Period 2 choice: consume everything, just work vs not work          #
    # ------------------------------------------------------------------ #

    # all follows the same logic at t=1, minus savings decision since we are in terminal period.
    ik2 = np.clip(np.searchsorted(k_grid, k2), 0, Nk - 1)

    V2_work   = np.where(w2 + k2 > 0,
                         beta * np.log(np.maximum(w2 + k2, 1e-300)) - gamma + eps_work[np.arange(N),  ik2],
                         -np.inf)
    V2_nowork = np.where(k2 > 0,
                         beta * np.log(np.maximum(k2,       1e-300))          + eps_nowork[np.arange(N), ik2],
                         -np.inf)

    log_denom2 = np.logaddexp(V2_work, V2_nowork)
    P2_work    = np.exp(V2_work - log_denom2)

    L2 = (rng.uniform(size=N) < P2_work).astype(int)

    # ------------------------------------------------------------------ #
    # Package outputs — observed wage is 0 if not working                 #
    # ------------------------------------------------------------------ #

    wage_1 = np.where(L1 == 1, w1, 0.0)
    wage_2 = np.where(L2 == 1, w2, 0.0)

    k_sim = np.column_stack([k1, k2])
    y_sim = np.column_stack([L1, L2])
    w_sim = np.column_stack([wage_1, wage_2])

    return w_sim, k_sim, y_sim
