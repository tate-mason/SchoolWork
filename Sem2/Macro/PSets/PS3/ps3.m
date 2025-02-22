%% AGRID FUNCTION %%
clear
r=0.02;
yvec=[0.05,0.5];
min=0.0001;
amax=2;
k=20;
gamma=(1+r)^(1/(k-1));
step1=(yvec(1)-min)*(gamma-1)/r;
n=floor(1+log(amax*(gamma-1)/step1+1)/log(gamma));
f=@(x)step1*(gamma.^(x-1)-1)/(gamma-1);
agrid=f(1:n)

%% Set Parameters %%
r = 0.02;
beta = (1/1.02);
cbar = 100;
yl = 0.05;
pl = 0.6;
ph = 0.4;

tol = 10e-10
maxiter = 1000

%% Creating V0 %%
v0 = zeros(n:2);
aopt = zeros(n:2);
copt = zeros(n:2);

v1 = 
