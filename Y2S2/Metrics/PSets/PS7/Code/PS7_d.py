from PS7_load import *
from PS7_c import run as PartC_run
from PS7_a import run as PartA_run

def run():
    fv_raw, Xgrid2  = PartC_run()
    alpha, sigma, Xgrid, Xgrid2, ptrans = PartA_run()

    State = np.zeros((N, T), dtype=int)
    for cutoff in Xgrid2:
        State += (Xt > cutoff).astype(int)

    Y_lag  = np.concatenate([np.full((N,1), np.nan), Y[:,:-1]], axis=1)
    t_idx  = np.tile(np.arange(T), (N,1))

    df = pd.DataFrame({
        'X_1':     np.tile(X[:,0], (T,1)).T.ravel(),
        'X_2':     np.tile(X[:,1], (T,1)).T.ravel(),
        'X_t':     Xt.ravel(),
        'Y':       Y.ravel(),
        'lag_Y':   Y_lag.ravel(),
        'state_k': State.ravel(),
        't_idx':   t_idx.ravel(),
    })
    df = df[df['lag_Y'].notna() & (df['lag_Y'] != 0)].copy()
    df['j']     = (df['lag_Y'] - 1).astype(int)
    df['k']     = df['state_k'].astype(int)
    df['t_idx'] = df['t_idx'].astype(int)
    df['fv_raw'] = fv_raw[df['j'].values, df['k'].values, df['t_idx'].values]

    def log_likelihood(params):
        b1, b2, b3  = params[0:3], params[3:6], params[6:9]
        scost = params[9]
        beta  = 1 / (1 + np.exp(-params[10]))
        X1_   = df['X_1'].values
        X2_   = df['X_2'].values
        Xt_   = df['X_t'].values
        fv_   = beta * df['fv_raw'].values
        lag   = df['lag_Y'].values
        Y_    = df['Y'].values

        def v(b, j):
            return b[0]*X1_ + b[1]*X2_ + b[2]*Xt_ - scost*(lag!=j) + fv_

        v1, v2, v3 = v(b1,1), v(b2,2), v(b3,3)
        log_denom  = sp.special.logsumexp(
            np.column_stack([np.zeros(len(Y_)), v1, v2, v3]), axis=1)
        log_prob   = ((Y_==0)*(-log_denom) + (Y_==1)*(v1-log_denom)
                    + (Y_==2)*(v2-log_denom) + (Y_==3)*(v3-log_denom))
        return -np.sum(log_prob)

    b0     = np.zeros(11)
    b0[10] = np.log(0.8/0.2)
    result = minimize(log_likelihood, x0=b0, method='BFGS',
                      options={'maxiter':10000, 'gtol':1e-8})
    return result

if __name__ == '__main__':
    result     = run()
    params_hat = result.x
    beta_hat   = 1 / (1 + np.exp(-params_hat[10]))
    se         = np.sqrt(np.diag(np.linalg.inv(result.hess_inv)))
    labels     = ['b1_const','b1_gender','b1_health',
                  'b2_const','b2_gender','b2_health',
                  'b3_const','b3_gender','b3_health',
                  'scost','beta']
    true_vals  = [-0.75,0.25,0.25,-0.25,0.5,0.5,-0.85,0.75,0.75,0.4,0.8]
    tbl = PrettyTable(["Parameter","Estimate","Std. Error","Truth"])
    for i, lab in enumerate(labels):
        est = beta_hat if lab=='beta' else params_hat[i]
        tbl.add_row([lab, f"{est:.4f}", f"{se[i]:.4f}", true_vals[i]])
    print(tbl)
