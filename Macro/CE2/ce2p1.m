% ECON 8040 - Computational Exercise 2 - Problem 1

%% Defining Params
beta = 0.95;
sigma = 2;
alpha = 0.4;
delta = 0.1;

%% Steady State Capital
k_ss = ((1/beta - 1 + delta)/alpha)^(1/(alpha-1));

%% Given in P1, k_ss = k1_b
k1_b = k_ss

%% System of Equations
f = @(x) [
    x(1)+x(3)-k1_b^alpha-(1-delta)*k1_b;
    x(2)-x(3)^alpha-(1-delta)*x(3);
    x(1)^(-sigma)-x(2)^(-sigma)*beta*(1-delta+alpha*x(3)^(alpha-1))
    ];

%% fsolve to find solutions

x0 = [k_ss, k_ss, k_ss];
options = optimoptions('fsolve','Display','iter');
[x, fval] = fsolve(f,x0,options);

c1 = x(1);
c2 = x(2);
k2 = x(3);

fprintf('Solution for k1_b = k_ss:\n');
fprintf('c1 = %.4f, c2 = %.4f, k2 = %.4f\n', c1, c2, k2);
