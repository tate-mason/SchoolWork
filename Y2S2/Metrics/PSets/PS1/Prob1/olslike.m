%construct log-likelihood for normally distributed linear model

function like=olslike(b,Y,X)

K = size(X,2);
beta = b(1:K);
s = b(K+1);

%vector of prediction errors for a given beta
e=Y-X*beta;  

% log-likelihood for N(0, s2)
ll = -0.5*log(2*pi) - 0.5*log(s) - 0.5*(e.^2)./s;

% want to maximize the sum of the log-likelihoods
% this is the same as minimizing the negative of the sum
like=-sum(ll); 

end



    
   
