%Shell program for HW 1
clear
clc

%loading in data
load dataHW1_Example

%size of the sample
N=size(Y,1);

%number of parameters to estimate
K=size(X,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Part b)
%estimate using built in OLS features
% "fitlm" is a command that allows you to estimate a linear regression model
mdl=fitlm(X(:,2:4),Y)
% "hac" allows you to calculate heteroskedastic robust SEs
[~,HET_SE,coef] = hac(mdl,'type','HC','weights','HC1','display','off');
Heteroskedastic_robust=[coef HET_SE]


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Part c)
%estimate model using matrix algebra
betahat1=(X'*X)\(X'*Y);

%calculate homoskedastic standard errors (eqn 4.10 in Wooldridge)
e=Y-X*betahat1;
sighat=(e'*e)/(N-K);
var_betahat1=sighat*inv(X'*X);
seHO_betahat1=sqrt(diag(var_betahat1));

%calculate HET standard errors (eqn 4.11 in Wooldridge with sample size adjustment)
mid=zeros(K,K);
for i=1:N
    tt=e(i)^2*X(i,:)'*X(i,:);
    mid=mid+tt;
end
var_betahat1=(N/(N-K))*inv(X'*X)*mid*inv(X'*X);
seHET_betahat1=sqrt(diag(var_betahat1));
MatrixAlg_Results=[betahat1 seHO_betahat1 seHET_betahat1]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Part d)
%estimate model using maximum likelihood

%if you have a multicore processor you can speed up fminunc
%you can add to opts: 'UseParallel',true

opts = optimoptions('fminunc', ...
    'Algorithm','quasi-newton', ...
    'Display','off', ...
    'OptimalityTolerance',1e-8, ...
    'StepTolerance',1e-8);

bstart=[zeros(4,1);0.5];
[betahat_lik,like,e,o,g,h]=fminunc('olslike',bstart,opts,Y,X);
% inv(h) is the variance matrix for estimates - thus the square root of the
% diagonal of inv(h) will give standard errors for parameters
LikResults=[betahat_lik sqrt(diag(inv(h)))]
% fminunc output
disp(o)
%assess convergence by examining the largest absolute element of the gradient at the solution, 
%or largest remaining first-order condition across parameters
norm(g,Inf)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Part e)
%estimate model using method of moments
bstart=zeros(4,1);
%options=optimoptions('fminunc','TolFun',1e-10,'TolX',1e-10);
[betahat_mom,like,e,o,g,h]=fminunc('olsmoments',bstart,opts,Y,X);
MoMResults=betahat_mom
% fminunc output
disp(o)
%assess convergence by examining the largest absolute element of the gradient at the solution, 
%or largest remaining first-order condition across parameters
norm(g,Inf)





