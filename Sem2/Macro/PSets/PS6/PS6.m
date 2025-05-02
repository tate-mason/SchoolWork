%% Problem Set 6 - Tate Mason

%% Implementation of Parameters
T = 65;
R = 40;
n = 0.011;
k1 = 0;
tau = 0.11;
mu = 0.5;
sigma = 3;
beta = 0.96;
delta = 0.06;
alpha = 0.36;
rho = 0.9;
sigma_sq = 0.03;

max_iter = 1000;
tol = 1e-6;

%% Discretization
n_k = 100;
n_z = 9;
k_min = 0.00001;
k_max = 50;

% Lambda
lambda = load('lambda_HW6.in');
lambda = lambda(:,2);

lambda(1:24) = lambda(25);

% kgrid
k_grid = linspace(0,1,n_k).^2*k_max;
k_grid(1) = k_min;

% zgrid
z_grid = load("zgrid.txt");
n_z = length(z_grid);

% Transition Matrix
P = load('P.txt');

% Stationary Distribution
pi = load('pi.txt');

