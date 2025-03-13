%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Tate Mason - David.Mason2@uga.edu   %%
%% Midterm Exam - Take Home Section    %%
%% Due on Mar 17, 2025                 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;
clc;

%% Definition of Parameters %%

r = 0.04;
beta = 0.95;
sigma = 3;
T = 40;
cmin = 0.1;
y = 1
W = 10;

%% Definition of kgrid %%

kmin = 0;
kmax = 100;
nk = 100;
kgrid = linspace(kmin, kmax, nk);

dense = kmin + (kmax - kmin)*((0:nk-1)/(nk-1)).^2;
kgrid = sort(unique([kgrid, dense]));
kgrid = kgrid(1:nk);

%% Definition of xgrid %%

xgrid = [0.01:0.1:3.91];
xprob = [0.8, 0.2];

%% Definition of zgrid %%

zgrid = zeros(1:v)

%% Value and Policy %%
V = zeros(1:nk, 1:m, 1:r-1);
VR = zeros(1:nk, 1:m, r:T);


