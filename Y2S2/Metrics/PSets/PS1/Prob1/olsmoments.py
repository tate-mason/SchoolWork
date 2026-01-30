import numpy as np

"""
    This file serves to create the function olsmoments. This function relies on numpy for numerical operations,
    and takes inputs b, Y, and X.
"""

def olsmomnets(b, Y, X):
    e = Y-X@b # prediction error

    t = X.T@e / X.shape(0)
    mom = t.T@t

    return mom
