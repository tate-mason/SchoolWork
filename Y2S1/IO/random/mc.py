import pandas as pd
import seaborn as sb
import numpy as np
import math
import statsmodels.api as sm

rng = np.random.default_rng(19)

N = 500
R = 300
beta_true = np.array([-0.5, 1.0, -0.8])

def logistic(z):
    out = np.empty_like(z, dtype=float)
    pos = z>=0
    neg = ~pos
    out[pos] = 1.0/(1.0 + np.exp(-z[pos]))
    ez = np.exp(z[neg])
    out[neg] = ez/(1.0 + ez)
    return out

def irls_logit(X, y, max_iter=100, tol=1e-8):
    n, k = X.shape
    beta = np.zeros(k)
    for it in range(max_iter):
        z = X @ beta
        p = logistic(z)
        W = p*(1-p)
        if np.any(W < 1e-12):
            W = np.clip(W, 1e-12, None)
        g = X.T @ (y-p)
        H = -(X.T*W) @ X
        try:
            step = np.linalg.solve(H, g)
        except np.linalg.LinAlgError:
            step = np.linalg.solve(H - 1e-6*np.eye(k), g)
        beta_new = beta+step
        if np.linalg.norm(step, ord=np.inf) < tol:
            beta = beta_new
            break
        beta = beta_new
    converged = (it < max_iter-1)
    z = X @ beta
    p = logistic(z)
    W = p*(1-p)
    H = (X.T*W) @ X
    try:
        vcov = np.linalg.inv(H)
    except np.linalg.LinAlgError:
        vcov = np.full((k,k), np.nan)
    return beta, vcov, converged, it+1

def fit_logit(X, y):
    model = sm.Logit(y, X)
    try:
        res = model.fit(disp=False, maxiter=200, method="newton")
    except Exception:
        res = model.fit(disp=False, maxiter=200, method="bfgs")
    beta = res.params
    vcov = res.cov_params
    conv = res.mle_retvals.get("converged", True)
    nit = res.mle_retvals.get("iterations", np.nan)
    return beta, vcov, conv, nit

k = len(beta_true)
betas = np.empty((R,k))
ses = np.empty((R,k))
converged_flags = np.zeros(R, dtype=bool)

for r in range(R):
    x1 = rng.normal(0, 1, size=N)
    x2 = rng.normal(0, 1, size=N) + 0.3*x1
    X = np.column_stack([np.ones(N), x1, x2])
    p = logistic(X @ beta_true)
    y = rng.binomial(1, p)
    bh, vc, conv, nit = fit_logit(X, y)
    betas[r] = bh
    if np.all(np.isfinite(vc)):
        ses[r] = np.sqrt(np.diag(vc))
    else:
        ses[r] = np.full(k, np.nan)
    converged_flags[r] = bool(conv)

df = pd.DataFrame(betas, columns=["beta0", "beta1", "beta2"])
mean_est = df.mean()
bias = mean_est.values - beta_true
var = df.var(ddof=1).values
mse = bias**2 + var
zcrit = 1.96

covers = []
for j in range(k):
    bh = betas[:,j]
    se = ses[:,j]
    lower = bh - zcrit * se
    upper = bh + zcrit * se
    cov = np.mean((lower <= beta_true[j]) & (beta_true[j]<=upper))
    covers.append(cov)

summary = pd.DataFrame({
    "True": beta_true,
    "Mean Est.": mean_est.values,
    "Bias": bias,
    "Var": var,
    "MSE": mse,
    "95% CI Coverage": covers
}, index=["beta0","beta1","beta2"]).round(4)

from caas_jupyter_tools import display_dataframe_to_user
display_dataframe_to_user("Logit Monte Carlo Summary", summary)

conv_rate = converged_flags.mean

