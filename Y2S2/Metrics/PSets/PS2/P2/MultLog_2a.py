import numpy as np
import scipy as sp

"""
Helper function for multinomial logit
"""

def mnl_mle(Xi, Zdist, Zprice, Y, maxiter=500):
    N = Y.size # pop size
    J = 4 # Alternatives

    K = Xi.shape[1] # (N, 3)
    Lz = 2 # (dist, price)
    Jm1 = J-1 # 3

    # normalize w.r.t. base case
    Z_dist_norm  = Zdist - Zdist[:, [0]]
    Z_price_norm = Zprice - Zprice[:, [0]]

    p = Jm1 + Jm1*K + Lz
    x0 = np.zeros(p)

    def nll(b):
        b = np.asarray(b).ravel()
        if b.size != p:
            raise ValueError(f"Expected length {p}, got {b.size}")

        idx = 0
        alpha = b[idx:idx + Jm1]; idx += Jm1
        beta = b[idx:idx + Jm1 * K].reshape(Jm1, K); idx += Jm1*K
        gamma = b[idx:idx + Lz]

        V = np.zeros((N, J))
        for j in range(1, J):
            V[:, j] = (
                alpha[j-1]
                + Xi @beta[j-1]
                + gamma[0] * Z_dist_norm
                + gamma[1] * Z_price_norm
            )

        V = V - V.max(axis=1, keepdims=True)
        expV = np.exp(V)
        P = expV / expV.sum(axis=1, keepdims=True)

        return -np.log(P[np.arange(N), Y]).sum()

    res = sp.optimize.minimize(
        nll,
        x0,
    )

    b_hat = res.x
    hess = np.asarray(res.hess_inv)
    se = np.sqrt(np.diag(hess))

    meta = {
        "N": N,
        "J": J,
        "param_len": p,
        "converged": bool(res.success),
        "message": res.message,
        "fun": res.fun,
        "niter": res.nit,
    }

    return b_hat, se, res, meta

def unpack_params(b_hat, J=4):
    b_hat = np.asarray(b_hat).ravel()
    Jm1 = J-1
    Kx = 3
    Lz = 2
    p = Jm1 + Jm1*Kx + Lz
    
    idx = 0
    alpha = b_hat[idx:idx+Jm1]; idx += Jm1
    beta  = b_hat[idx:idx+Jm1*Kx].reshape(Jm1, Kx); idx += Jm1 * Kx
    gamma = b_hat[idx:idx+Lz]

    return{
        "alpha": alpha,
        "beta": beta,
        "gamma": gamma
    }

