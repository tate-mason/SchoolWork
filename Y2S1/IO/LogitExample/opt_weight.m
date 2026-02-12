function W_opt=opt_weight(params, d)

%GET XI VALUES AT THE PARAMETERS
[xi, market_share, beta, delta]=contract_map(params, d);

%CALCULATE VALUE OF MOMENT FOR EACH PRODUCT
g=(repmat(xi,1, size(params,1)).*d.rc_ivs)';

%GENERATE G MATRIX FOR OPTIMAL WEIGHT MATRIX (SEE HANSENS TEXTBOOK)
G=g*g';

%OPTIMAL WEIGHT MATRIX
W_opt=inv(G./size(xi,2));

end