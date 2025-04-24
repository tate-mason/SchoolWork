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
z_mu = 0;
zgrid = zeros(zn, 1);

zsd = sqrt((sigma_sq^2)/(1-rho^2));
zlo = z_mu - 2*zsd;
zhi = z_mu + 2*zsd;
z_step = (zhi - zlo)/(zn-1);
zgrid = zlo:z_step:zhi;
zsize = length(zgrid);

% Transition matrix
maxit = 10000;
pmat = zeros(zn,zn);

% Calling ghquad
[x,w] = ghquad(zn, 10000);

% Transition Probabilities
for i = 1:zn
  mu_next = zmu + rho*zgrid(i);
  for j = 1:zn
    pmat(i,j) = w(j)/sqrt(pi)*exp(-(0.5)*((zgrid(j) - rho*zgrid(i))/sigma)^2)/exp(-x(j)^2);
  end
  dens = sum(pmat(i,:));
  pmat(i,:) = pmat(i,:)/dens;
end

pmat_cum = cumsum(pmat, 2);

%% Coding Model Solution

% Guessing r and b
r = 0;
b = 0;

KN = ((r+delta)/alpha)^(1/alpha-1);
wage = (1-alpha)*KN^(alpha);

%% Retired

coptr = zeros(ksize, T-R);
koptr = zeros(ksize, T-R);
voptr = zeros(ksize, T-R);





