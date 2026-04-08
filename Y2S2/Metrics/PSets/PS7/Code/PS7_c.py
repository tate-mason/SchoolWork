from PS7_load import *
from PS7_a import run as partA_run
from PS7_b import run as partB_run 

def run():
    alpha, sigma, Xgrid, Xgrid2, ptrans = partA_run()
    ccps_res, ccps_data, period_dummies  = partB_run()

    euler      = 0.57722
    grid_rep   = np.tile(Xgrid, T)
    period_rep = np.repeat(np.arange(T), 10)

    pred_df = pd.DataFrame({
        'X_1':      ccps_data['X_1'].mean(),
        'X_2':      ccps_data['X_2'].mean(),
        'X_t':      grid_rep,
        'Y_0':      ccps_data['Y_0'].mean(),
        'lag_Y_pt': 0,
        'lag_Y_ft': 0,
    })
    for col in period_dummies.columns:
        pred_df[col] = (period_rep == int(col.split('_')[1])).astype(int)

    P0_grid   = ccps_res.predict(pred_df).values.reshape(T, 10).T  # (10, T)
    Emax_grid = -np.log(P0_grid) + euler                            # (10, T)
    Emax_next = Emax_grid[:, 1:]                                    # (10, T-1)

    fv_raw             = np.zeros((3, 10, T))
    fv_raw[:, :, :-1]  = np.einsum('pkj,pt->jkt', ptrans, Emax_next)

    return fv_raw, Xgrid2

if __name__ == '__main__':
    fv_raw, _ = run()
    print(f"fv_raw shape: {fv_raw.shape}")
