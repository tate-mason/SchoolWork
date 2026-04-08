from PS7_load import *
from PS7_a import run as partA_run

def run():
    alpha, sigma, Xgrid, Xgrid2, ptrans = partA_run()

    Xt_flat = Xt.ravel()
    Y_lag   = np.concatenate([np.full((N, 1), np.nan), Y[:, :-1]], axis=1)  # (N,T)
    t_idx   = np.tile(np.arange(T), (N, 1))                                  # (N,T)

    ccps_df = pd.DataFrame({
        'X_1':   np.tile(X[:, 0], (T, 1)).T.ravel(),
        'X_2':   np.tile(X[:, 1], (T, 1)).T.ravel(),
        'X_t':   Xt_flat,
        'Y_0':   np.tile(Y_0.ravel(), T),
        'Y':     Y.ravel(),
        'lag_Y': Y_lag.ravel(),
        't':     t_idx.ravel(),
    })

# Keep only active individuals
    ccps_df = ccps_df[ccps_df['lag_Y'].notna() & (ccps_df['lag_Y'] != 0)].copy()

    ccps_df['retired']  = (ccps_df['Y'] == 0).astype(int)
    ccps_df['lag_Y_pt'] = (ccps_df['lag_Y'] == 2).astype(int)   # part-time lag dummy
    ccps_df['lag_Y_ft'] = (ccps_df['lag_Y'] == 3).astype(int)   # full-time lag dummy

    period_dummies = pd.get_dummies(ccps_df['t'], prefix='t', drop_first=True).astype(int) # (T-1) dummies for periods 1..T-1, period 0 as base

    X_ccps   = pd.concat([ccps_df[['X_1', 'X_2', 'X_t', 'Y_0', 'lag_Y_pt', 'lag_Y_ft']], # main regressors
                        period_dummies], axis=1)
    res = sm.Logit(ccps_df['retired'], X_ccps).fit(disp=False)
    ccps_df['predicted_prob'] = res.predict(X_ccps)

    return res, ccps_df, period_dummies

if __name__ == '__main__':
    res, df, _ = run()
    print(res.summary())
