%% Tate Mason - PS6

%% Setting Parameters
T = 65;
R = 40;
n = 0.011;
k1 = 0;
tau = 0.11;
mu = 0.5;
sigma = 3;
beta = 0.96;
alpha = 0.36;
delta = 0.06;
rho = 0.9;
sigma_sq =  0.03;
tau = 0.11;

max_iter = 100;
tol = 1e-4;

%% Discretize Variables

num_k = 100;
num_z = 7;
k_min = 0.0001;
k_max = 50;

%% Loading Lambda

lambda = load('lambda_HW6.in');
lambda = lambda(:,2);

%% Init State Space

% kgrid
k_grid = linspace(0:2:100).^2 * 100;
kn = length(kgrid);

% zgrid
zn = 9;


