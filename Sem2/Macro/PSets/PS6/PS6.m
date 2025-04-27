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
lambda(25:64) = lambda_data(:,2);
lambda(1:24) = lambda(25);

%% Init State Space

% kgrid
k_grid = linspace(0:2:100).^2 * 100;
kn = length(kgrid);

% zgrid
z_grid = readmatrix('zgrid.txt');
nz = length(z_grid);

% Transition matrix
maxit = 10000;
P = readmatrix('P.txt');

%% Coding Model Solution

% Guessing r and b
r = 0.04;
b = 0.2;

converged = false;
iter = 0;

while ~converged && iter < max_iter
  iter = iter+1;

  KN = ((r+delta)/alpha)^(1/alpha-1);
  wage = (1-alpha)*KN^(alpha);

  % Retirees
  coptR = zeros(num_k, T-R+1);
  koptR = zeros(num_k, T-R+1);
  voptR = zeros(num_k, T-R+1);

  % Workers
  copt = zeros(num_k, num_z, R-1);
  kopt = zeros(num_k, num_z, R-1);
  lopt = zeros(num_k, num_z, R-1);
  vopt = zeros(num_k, num_z, R-1);

  % Start at the end and iterate backwards
  for ik = 1:num_k
    k = k_grid(ik);

    coptR(ik, T-R+1) = (1+r)*k+b;
    koptR(ik, T-R+1) = 0;
    voptR(ik, T-R+1) = utility(coptR(ik, T-R+1), 0, mu, sigma);
  end

  for it = T-1:-1:R 
    period_idx = it - R + 1;
    for ik = 1:num_k
      k = kgrid(ik);
      current_c = k*(1+r) + b; % c+k'=k(1+r)+b
      opt_val = -1e-10;
      opt_k_idx = 1;

      for ik = 1:num_k
        k_next = kgrid(ik);
        if k_next <= current_c % feasibility constraint
          c = current_c - k_next;
          val = utility(c, 0, mu, sigma) + beta * voptR(ik, period_idx+1);
          if val > opt_val
            opt_val = val;
            opt_k_idx = ik;
          end
        end
      end

      koptR(ik, period_idx) = k_grid(opt_k_idx);
      coptR(ik, period_idx) = current_c - koptR(ik, period_idx);
      voptR(ik, period_idx) = opt_val;
    end
  end

  for it = R-1:-1:1
    for ik = 1:num_k
      for iz = 1:nz
        k = k_grid(ik);
        z = z_grid(iz);

        opt_val = -1e-10;
        opt_k_idx = 1;
        opt_l = 0;
        opt_c = 0;

        for ik_next = 1:num_k
          k_next = k_grid(ik_next);
          l_opt = compute_labor(k, k_next, r, wage, exp(z), lambda(it), tau, mu);
          l_opt = max(0, min(1, l_opt)); % Ensure l is between 0 and 1
          
          labor_inc = wage*exp(z)*lambda(it)*l_opt*(1-tau);
          current_c = k*(1+r) + labor_inc;

          if k_next <= current_c % feasibility constraint
            c = current_c - k_next;
            e_val = 0;
            if it < R-1
              for iz_next = 1:nz
                e_val = e_val + P(iz, iz_next) * voptR(ik_next, iz_next, it+1);
              end
            else
              e_val = voptR(ik_next, 1);
            end

            val = utility(c, l_opt, mu, sigma) + beta * e_val;

            if val > opt_val
              opt_val = val;
              opt_k_idx = ik_next;
              opt_l = l_opt;
              opt_c = c;
            end
          end
        end

        kopt(ik, iz, it) = k_grid(opt_k_idx);
        lopt(ik, iz, it) = opt_l;
        copt(ik, iz, it) = opt_c;
        vopt(ik, iz, it) = opt_val;
      end
    end
  end
  % Invariant distribution
  Gamma = zeros(num_k, num_z, T);

  Pi = readmatrix('Pi.txt');
  Gamma(1, :, 1) = Pi;

  adj = zeros(T,1);
  g = 1;
  for t = T:-1:1
    adj(t) = g;
    g = g*(1+n);
  end
or t = 1:T-1
    if t < R  % Working age
      for ik = 1:num_k
        for iz = 1:nz
          mass = Gamma(ik, iz, t);
          if mass > 0 
            k_next = kopt(ik, iz, t);

            [k_lo_idx, weight] = locate_grid_position(k_grid, k_next);
            
            % Distribute according to transition probabilities
            for iz_next = 1:nz
              prob = P(iz, iz_next);
              Gamma(k_lo_idx, iz_next, t+1) = Gamma(k_lo_idx, iz_next, t+1) + mass*(1-weight)*prob;
              Gamma(k_lo_idx+1, iz_next, t+1) = Gamma(k_lo_idx+1, iz_next, t+1) + mass*weight*prob;
            end
          end
        end
      end
    else  % Retirement age
      for ik = 1:num_k
        mass = sum(Gamma(ik, :, t));
        if mass > 0
          k_next = koptR(ik, t-R+1);
          
          [k_lo_idx, weight] = locate_grid_position(k_grid, k_next);
          
          % No productivity transitions in retirement
          Gamma(k_lo_idx, 1, t+1) = Gamma(k_lo_idx, 1, t+1) + mass*(1-weight);
          Gamma(k_lo_idx+1, 1, t+1) = Gamma(k_lo_idx+1, 1, t+1) + mass*weight;
        end
      end
    end
  end  % End of forward simulation loop

  % Apply population growth adjustment (outside the time loop)
  for t = 1:T
    Gamma(:, :, t) = Gamma(:, :, t)*adj(t);
  end

    total_mass = sum(sum(sum(Gamma)));
    Gamma = Gamma/total_mass;

    K = 0;
    L = 0;

    for t = 1:T
      if t < R
        for ik = 1:num_k
          for iz = 1:nz
            mass = Gamma(ik, iz, t);
            K = K + k_grid(ik) * mass;
            L = L + lopt(ik, iz, t)*exp(z_grid(iz))*lambda(t)*mass;
          end
        end
      else
        for ik = 1:num_k
          mass = sum(Gamma(ik, :, t));
          K = K + k_grid(ik) * mass;
        end
      end
    end

    r_new = alpha*(K/L)^(alpha-1) - delta;

    total_retirees = sum(sum(sum(Gamma(:, :, R:T))));
    total_labor_tax = 0;

    for t = 1:R-1
      for ik = 1:num_k
        for iz = 1:nz
          mass = Gamma(ik, iz, t);
          labor_inc = wage*exp(z_grid(iz))*lambda(t)*lopt(ik, iz, t);
          total_labor_tax = total_labor_tax + tau*labor_inc*mass;
        end
      end
    end

    b_new = total_labor_tax/total_retirees;
    r_diff = abs(r_new - r);
    b_diff = abs(b_new - b);

    if r_diff < tol && b_diff < tol
      converged = true;
      fprintf('Converged in %d iterations\n', iter);
    else
      r = 0.5*r + 0.5*r_new;
      b = 0.5*b + 0.5*b_new;
      fprintf('Iteration %d: r = %.6f, b = %.6f\n', iter, r, b);
    end
  end
benchmark_K = K;
benchmark_L = L;
benchmark_r = r;
benchmark_w = wage;
benchmark_b = b;
init_welfare_SS = expected_welfare_newborn(vopt, 1, Pi);

fprintf('\nEliminating Social Security (tau = 0)\n');
tau = 0;
% Insert repetation of algorithm with tau = 0 below:


%% Helper Functions

function u = utility(c, l, mu, sigma)
    % Utility function
    if c <= 0
        u = -1e10;
        return;
    end
    u = ((c^mu * (1-l)^(1-mu))^(1-sigma) - 1) / (1-sigma);
end

function l = compute_labor(k, k_next, r, w, exp_z, lambda, tau, mu)
    % Compute optimal labor supply from FOC
    cash_on_hand = k * (1 + r);
    l = (mu * w * exp_z * lambda * (1-tau) - (1-mu) * (cash_on_hand - k_next)) / (w * exp_z * lambda * (1-tau));
end

function [lo_idx, weight] = locate_grid_position(grid, val)
    % Find position of val in grid and compute interpolation weight
    n = length(grid);
    
    if val <= grid(1)
        lo_idx = 1;
        weight = 0;
        return;
    elseif val >= grid(n)
        lo_idx = n-1;
        weight = 1;
        return;
    end
    
    % Binary search for position
    lo = 1;
    hi = n;
    
    while hi - lo > 1
        mid = floor((lo + hi) / 2);
        if grid(mid) <= val
            lo = mid;
        else
            hi = mid;
        end
    end
    
    lo_idx = lo;
    weight = (val - grid(lo)) / (grid(lo+1) - grid(lo));
end

function welfare = expected_welfare_newborn(vopt, period, Pi)
    % Compute expected welfare for newborn
    welfare = 0;
    for iz = 1:length(Pi)
        welfare = welfare + Pi(iz) * vopt(1, iz, period);
    end
end

