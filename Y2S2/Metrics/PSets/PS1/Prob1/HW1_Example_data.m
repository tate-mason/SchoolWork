%Data for HW 1 Example
%Setting up the data for a linear conditional expectation problem

clear

%set the seed for random number generator so draws are always same
rng('default');
rng(555);

%defining sample size
N=5000;

%observable characteristics - build in covariance between regressors
common=randn(N,1);
A=(0.5*common+0.5*randn(N,1))>0;
B=0.25*common+0.8*randn(N,1);
C=2+0.25*common+1.25*randn(N,1);
X=[ones(N,1) A B C];

%set parameter values
beta=[0.5;0.5;0.75;0.25];

%generate outcomes - assume regressors are exogenous
Y=X*beta+randn(N,1);

save dataHW1_Example Y X




