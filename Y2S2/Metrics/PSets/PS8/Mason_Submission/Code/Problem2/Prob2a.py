import numpy as np

"""
This file creates moments to be used in SMM. Contains:
    - gmm_moments: takes data arrays and returns a vector of moments
"""

def gmm_moments(k, y, w):

    m = []

    # y is (N,2): col 0 = period 1 work, col 1 = period 2 work
    l1 = y[:, 0]
    l2 = y[:, 1]

    # w is (N,2): observed wage (0 if not working)
    w1 = w[:, 0]
    w2 = w[:, 1]

    # k is (N,2): col 0 = period 1 assets, col 1 = period 2 assets (savings)
    k1 = k[:, 0]
    k2 = k[:, 1]

    # Asset moments
    m.append(np.mean(k1))           # mean assets period 1
    m.append(np.mean(k2))           # mean assets period 2
    m.append(np.std(k2))            # std of savings
    m.append(np.mean(k2 - k1))      # mean change in assets (savings rate)

    # Labor force participation
    m.append(np.mean(l1))           # LFP period 1
    m.append(np.mean(l2))           # LFP period 2

    # Wage distribution moments — use workers only so zeros don't corrupt
    w1_work = w1[l1 == 1]
    w2_work = w2[l2 == 1]

    w_grid = np.array([0.5, 0.75, 1.0, 1.5, 2.0])
    for wj in w_grid:
        m.append(np.mean(np.isclose(w1_work, wj)))   # share at each wage point, period 1
    for wj in w_grid:
        m.append(np.mean(np.isclose(w2_work, wj)))   # share at each wage point, period 2

    # LFP by wage group — need offered wage, so condition on workers
    # use period 1 offered wage to split period 2 LFP
    high_w1 = w1 >= 1.5                              # top 2 wage points
    low_w1  = w1 <= 0.75                             # bottom 2 wage points

    m.append(np.mean(l2[high_w1]))  # LFP period 2 for high-wage workers
    m.append(np.mean(l2[low_w1]))   # LFP period 2 for low-wage workers

    # Wage persistence — share who work both periods conditional on period 1 wage
    m.append(np.mean(l2[l1 == 1]))  # LFP period 2 given worked period 1
    m.append(np.mean(l2[l1 == 0]))  # LFP period 2 given did not work period 1

    # Asset-labor correlation
    m.append(np.corrcoef(k1, l1)[0, 1])  # richer agents more/less likely to work?

    return np.array(m)
