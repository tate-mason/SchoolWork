import numpy as np
import scipy as sp

"""
Helper function for calculating change in consumer surplus when removing Y=4
    - surplus_func: calculates the change in consumer surplus when removing Y=4, calculating ICV with and without Y=4, dividing by negative of distance to get change in consumer surplus in thousands of dollars, and then averaging
"""

def surplus_func(b, X, Zdist, Zprice, Y, J):
    # same function as used in 2f, but we will now just take V and use it to calculate the change in consumer surplus when we remove Y=4. 
    def new_predict_prob(b, X, Zdist, Zprice, Y, J):
        N, Kx = X.shape
        Jm1 = J-1

        b = np.asarray(b).ravel()

        B = b[:Kx*(Jm1)].reshape((Kx, Jm1), order="F")
        gamma_d = b[-2]
        gamma_p = b[-1]

        V = np.zeros((N, J))

        for j in range(1, J):
            jj = j-1
            V[:, j] = X @ B[:, jj] + gamma_d * Zdist[:,j] + gamma_p * Zprice[:,j]

        return V # return V for use in surplus function

    V = new_predict_prob(b, X, Zdist, Zprice, Y, J) # get V from the function

    inc_val_old = sp.special.logsumexp(V, axis=1) # calculate inclusive value with all 4 choices
    inc_val_new = sp.special.logsumexp(V[:,:3], axis=1) # recalculate inclusive value with only 3 choices, removing the 4th choice (which is the outside option)

    dCS_i = 1000*(inc_val_new - inc_val_old) / (-b[-1]) # divide by negative of distance coefficient to get change in consumer surplus

    # dCS by parentBA
    dCS_BA = dCS_i[X[:, 1] ==1].mean()# calculate average change in consumer surplus by parentBA
    dCS_noBA = dCS_i[X[:, 1] ==0].mean() # calculate average change in consumer surplus by no parentBA

    return dCS_i.mean(), dCS_BA, dCS_noBA # return average change in consumer surplus across all individuals


