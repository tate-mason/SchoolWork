%construct squared moments for linear model

function mom=olsmoments(b,Y,X)

e=Y-X*b;  %prediction error

%Assumption OLS.1 on pg. 56 of Wooldridge tells us that in the population X and u should have zero covariance
%We mimic this in our sample
%Essentially using formula 8.27 in Wooldridge with X as instruments and the identity matrix
t=X'*e/size(X,1);   
mom=t'*t;

end




    
   
