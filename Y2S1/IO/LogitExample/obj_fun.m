function [obj_func, beta]=obj_fun(params,W,d)

%CONTRACTION MAPPING THAT RETURNS DELTA, BETAS (INCL ALPHA) and XI%
[xi, market_share, beta, delta]=contract_map(params, d);

%INTERATION BETWEEN XI AND INSTRUMENTS
Z=d.rc_ivs;

%MOMENTS
M=Z'*xi./(size(d.X,1));

%OBJECTIVE FUNCTION VALUE
obj_func=M'*W*M;
end