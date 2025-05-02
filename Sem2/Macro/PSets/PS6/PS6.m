%% Problem Set 6 - Tate Mason

%% Defining global variables
global b beta k_grid lambda mu n_k n_z N R r sigma tau v vR w z_grid

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

%% Initializing the value function

% workers
v = zeros(n_k, n_z, R-1);
copt = zeros(n_k, n_z, R-1);
kopt = zeros(n_k, n_z, R-1);
lopt = zeros(n_k, n_z, R-1);

%retirees
vR = zeros(n_k, T-R+1);
coptR = zeros(n_k, T-R+1);
koptR = zeros(n_k, T-R+1);

% Initial guess of r and b
r = 0.1;
b = 0.5;

iter = 0;

converged = false;

while ~converged && iter<max_iter
  KN = ((r+delta)/alpha)^(1/(alpha-1));
  w = (1-alpha)*KN^alpha;
  for ik = 1:n_k
    coptR(ik, T-R+1) = (1+r)*k_grid(ik) + b;
    koptR(ik, T-R+1) = 0;
    vR(ik, T-R+1) = utility(coptR(ik, T-R+1),0);
  end
  
  for t = T-R:-1:1
    for ik = 1:n_k
      k_lower = 0;
      k_upper = min(kgrid(ik)*(1+r) + b -0.0001, 100);
      [kval, fval] = fminbnd(@(kp)ufunc_R(kp, ik, t), k_lower, k_upper);
      koptR(ik, t) = kval;
      coptR(ik, t) = (1+r)*k_grid(ik) + b - kval;
      vR(ik, t) = -fval;
    end
  end

  % Value function iteration for workers
  for t = R-1:-1:1
    for iz = 1:n_z
      for ik = 1:n_k
        k_lower = 0;
        k_upper = min(kgrid(ik)*(1+r) + w*exp(z_grid(iz))*lambda(t,2)*(1-tau)-0.0001, 100);
        [kval, fval] = fminbnd(@(kp)ufunc_W(kp, ik, iz, t), k_lower, k_upper);
        kopt(ik, iz, t) = kval;
        copt(ik, iz, t) = kgrid(ik)*(1+r) + w*exp(z_grid(iz))*lambda(t,2)*(1-tau)*lopt(ik,iz,t) - kval;
        v(ik, iz, t) = -fval;
      end
    end
  end

  % Setting distribution across states
  Gamma = zeros(n_k, n_z, R-1);
  Gamma_R = zeros(n_k, T-R+1);
  Gamma(1,:, 1) = pi;

  for t = 1:R-1
    for ik = 1:n_k
      for iz = 1:n_z
        mass = Gamma(ik, iz, t);
        jlo = find(k_grid <= kopt(ik, iz, t), 1, 'last');
        weight = (kopt(ik, iz, t) - kgrid(jlo)) / (k_grid(jlo+1) - k_grid(jlo));

        for izp = 1:n_z
          if t == R-1
            Gamma_R(jlo, 1) = Gamma_R(jlo, 1) + mass*(1-weight)*P(iz, izp);
            Gamma_R(jlo+1, 1) = Gamma_R(jlo+1, 1) + mass*weight*P(iz, izp);
          else
            Gamma(ik, izp, t+1) = Gamma(ik, izp, t+1) + mass*(1-weight)*P(iz, izp);
            Gamma(ik+1, izp, t+1) = Gamma(ik+1, izp, t+1) + mass*weight*P(iz, izp);
          end
        end
      end
    end
  end
  % Updating the distribution for retirees
  for t = 1:T-R
    for ik = 1:n_k
      mass = Gamma_R(ik,t);
      jlo = find(k_grid <= koptR(ik, t), 1, 'last');
      weight = (koptR(ik, t) - kgrid(jlo)) / (k_grid(jlo+1) - k_grid(jlo));
      Gamma_R(jlo, t+1) = Gamma_R(jlo, t+1) + mass*(1-weight);
      Gamma_R(jlo+1, t+1) = Gamma_R(jlo+1, t+1) + mass*weight;
    end
  end
  % Adjusting the distribution for population growth
  
  g = 1;
  for t = T:-1:1
    adj(t) = g;
    g = g*(1+n);
  end

  Gamma_new = zeros(n_k, n_z, R-1);
  Gamma_new_R = zeros(n_k, T-R+1);

  for t = 1:R-1
    Gamma_new(:,:,t) = Gamma(:,:,t)*adj(t);
  end
  for t = 1:T-R+1
    Gamma_new_R(:,t) = Gamma_R(:,t)*adj(t);
  end

  for ik = 1:n_k
    for iz = 1:n_z
      for t = 1:R-1
        Gamma(ik, iz, t) = Gamma_new(ik, iz, t)/(sum(Gamma_new,'all')+sum(Gamma_new_R,'all'));
      end
    end
  end

  for ik = 1:n_k
    for t = 1:T-R+1
      Gamma_R(ik, t) = Gamma_new_R(ik, t)/(sum(Gamma_new,'all')+sum(Gamma_new_R,'all'));
    end
  end

  % Calculating K and L
  K = 0;
  L = 0;

  % Calculating K and L for workers
  for t = 1:R-1
    for ik = 1:n_k
      for iz = 1:n_z
        K = K + Gamma(ik, iz, t).*kopt(ik,iz,t);
        L = L + Gamma(ik, iz, t).*lambda(t,2).*lopt(ik,iz,t)*exp(z_grid(iz));
      end
    end
  end

  % Total K
  for t = 1:T-R+1
    for ik = 1:n_k
      K = K + Gamma_R(ik, t).*koptR(ik, t);
    end
  end

  % New r and b
  
  r_new = alpha*(K/L)^(alpha-1)-delta;
  b_new = (tau*w*L)/sum(Gamma_R, 'all');

  diff_r = abs(r_new - r);
  diff_b = abs(b_new - b);

  r = 0.5*r + 0.5*r_new;
  b = 0.5*b + 0.5*b_new;

  iter = iter + 1;
  if diff_r < tol && diff_b < tol
    converged = true;
  end
  fprintf('Iteration: %d, r: %.4f, b: %.4f\n', iter, r, b);
end
fprintf('Converged after %d iterations\n', iter);

%% Wealth and Labor Profiles

% Worker
labor = zeros(1, R-1);
wealth_W = zeros(1, R-1); 

for t = 1:R-1
  for ik = 1:n_k
    for iz = 1:n_z
      labor(t) = labor(t) + Gamma(ik, iz, t)*lopt(ik, iz, t);
      wealth_W(t) = wealth_W(t) + Gamma(ik, iz, t)*kopt(ik, iz, t);
    end
  end
end

% Retiree
wealth_R = zeros(1, T-R+1);
for t = 1:T-R+1
  for ik = 1:n_k
    wealth_R(t) = wealth_R(t) + Gamma_R(ik, t)*koptR(ik, t);
  end
end

% Save Profiles
wealth = zeros(4,T);
labor_supp = zeros(4, R-1);
wealth(1, :) = [welath_W, wealth_R];
labor_supp(1, :) = labor;
save('prof.mat', 'wealth', 'labor_supp');

%% Formulating Welfare of Newborns

v0 = 0;
for ik = 1:n_k
  for iz = 1:n_z
    v0 = v0 + pi(ik, iz)*Gamma(ik, iz, 1)*v(ik, iz, 1);
  end
end

%% Comparison

results = cell(7,5);
results(:,1) = {'Captial', 'Labor', 'Wage', 'Interest', 'Pension', 'Newborn Welfare', 'Discount Factor'};
results(:,2) = {K, L, w, r, b, v0, beta};
save('results.mat', 'results');
