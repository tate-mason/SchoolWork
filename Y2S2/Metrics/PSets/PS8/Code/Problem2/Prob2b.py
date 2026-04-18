import numpy as np
import scipy as sp

"""
This file computes simulated moments based on the moments from Prob2a. Contains:
    - sim_moments: function to compute simulated moments for GMM estimation
"""

def sim_moments(b, k, y, w):

    # Using given parameters

    N = 20000
    rng = np.random.default_rng(seed=219)

    b = 2.0
    g = 0.5
    disc = 0.9

    w_dist = np.array([0.2, 0.2, 0.2, 0.2, 0.2]) # wage probabilities
    w_grid = np.array([0.5, 0.75, 1.0, 1.5, 2.0]) # wage distribution
    rho1, rho2, rho3 = 0.4, 0.2, 0.1 # wage transition parameters

    # transition matrix
    Sigma = np.array([
        [rho1+rho2+rho3, rho2, rho3, 0, 0],
        [rho2+rho3, rho1, rho2, rho3, 0],
        [rho3, rho2, rho1, rho2, rho3],
        [0, rho3, rho2, rho1, rho2+rho3],
        [0, 0, rho3, rho2, rho1+rho2+rho3]
    ])

    N_k = 100 # number of grid points for assets in period 2
    k_min = 0.0 # minimum asset level in period 2
    k_max = 5.0 # maximum asset level in period 2
    k_grid = np.linspace(k_min, k_max, N_k) # asset grid for period 2

    # Period 2

    Nw = len(w_grid)
    Nk = len(k_grid)

    Emax2 = np.zeros((Nk, Nw))
    for ik, k2 in enumerate(k_grid):
        for iw, w2 in enumerate(w_grid):

            c_work = w2 + k2
            c_nowork = k2

            if c_nowork <= 0:
                V_nowork = -np.inf
            else:
                V_nowork = b*np.log(c_nowork)
            if c_work <= 0:
                V_work = -np.inf
            else:
                V_work = b*np.log(c_work) - g

            Emax2[ik, iw] = np.logaddexp(V_nowork, V_work)
    EV1 = Emax2 @ Sigma.T

    # Period 1

    k1 = np.random.uniform(1.5, 3.5, size=N)
    w1_idx = np.random.choice(Nw, size=N, p=w_dist)
    w1 = w_grid[w1_idx]

    k2_work = np.zeros(N)
    k2_nowork = np.zeros(N)

    for i in range(N):
        w = w1[i]
        k = k1[i]
        iw = w1_idx[i]

        EV1_interpolate = sp.interpolate.interp1d(k_grid, EV1[:, iw], 
                                                  kind = 'linear',
                                                  bounds_error = False,
                                                  fill_value = (EV1[0, iw], EV1[-1, iw]))

        def obj_work(k2):
            c = w + k - k2
            if c <= 0:
                return -np.inf
            return -(b*np.log(c) - g + disc*EV1_interpolate(k2))

        def obj_nowork(k2):
            c = k - k2
            if c <= 0:
                return -np.inf
            return -(b*np.log(c) + disc*EV1_interpolate(k2))

        from scipy.optimize import minimize_scalar
        res_w = minimize_scalar(obj_work, bounds=(k_min, max(w+k-1e-6, k_min)), method='bounded')
        res_nw = minimize_scalar(obj_nowork, bounds=(k_min, max(k-1e-6, k_min)), method='bounded')

        k2_work[i] = res_w.x if res_w.success else k_min 
        k2_nowork[i] = res_nw.x if res_nw.success else k_min

    V1_work = np.array([
        b*np.log(w1[i] + k1[i] - k2_work[i]) - g + 
        disc*sp.interpolate.interp1d(k_grid, EV1[:, w1_idx[i]], bounds_error=False, fill_value=(EV1[0, w1_idx[i]], EV1[-1, w1_idx[i]]))(k2_work[i])
        for i in range(N)
    ])

    V1_nowork = np.array([
        b*np.log(k1[i] - k2_nowork[i]) + 
        disc*sp.interpolate.interp1d(k_grid, EV1[:, w1_idx[i]], bounds_error=False, fill_value=(EV1[0, w1_idx[i]], EV1[-1, w1_idx[i]]))(k2_nowork[i])
        for i in range(N)
    ])

    P1_work = np.exp(V1_work) / (np.exp(V1_work) + np.exp(V1_nowork))
    L1 = (np.random.uniform(size=N) < P1_work).astype(int)
    k2 = np.where(L1 == 1, k2_work, k2_nowork)

    w2_idx = np.array([
        np.random.choice(Nw, p=Sigma[w1_idx[i]]) for i in range(N)
    ])

    w2 = w_grid[w2_idx]

    # Period 2 pr(work)

    V2_work = np.array([
        b*np.log(w2[i] + k2[i]) - g if w2[i] + k2[i] > 0 else -np.inf for i in range(N)
    ])
    V2_nowork = np.array([
        b*np.log(k2[i]) if k2[i] > 0 else -np.inf for i in range(N)
    ])

    P2_work = np.exp(V2_work) / (np.exp(V2_work) + np.exp(V2_nowork))
    L2 = (np.random.uniform(size=N) < P2_work).astype(int)

    wage_1 = np.where(L1 == 1, w1, 0)
    wage_2 = np.where(L2 == 1, w2, 0)

    k_sim = np.column_stack([k1, k2])
    y_sim = np.column_stack([L1, L2])
    w_sim = np.column_stack([wage_1, wage_2])

    return w_sim, k_sim, y_sim
