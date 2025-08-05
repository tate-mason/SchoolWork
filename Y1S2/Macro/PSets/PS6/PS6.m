%% PS6 - Tate Mason
% Implementation of the advanced macroeconomics model with and without Social Security

clear all;
close all;

%% Parameters
T = 65;           % Total life periods
R = 40;           % Retirement age
n = 0.011;        % Population growth rate
k1 = 0;           % Initial capital for newborns
tau = 0.11;       % Social security tax
mu = 0.5;         % Weight on consumption in utility
sigma = 3;        % Risk aversion coefficient
beta = 0.96;      % Discount factor
alpha = 0.36;     % Capital share
delta = 0.06;     % Depreciation rate
rho = 0.9;        % AR(1) coefficient
sigma_eps = 0.03; % Shock variance

%% Discretization
% Capital grid
nk = 100;                  % number of grid points for capital
p = 2;                     % Power for non-linear spacing
kgrid = 100 * (linspace(k1, 1, nk).^p);    % Creating values on kgrid (Maximum capital is 100)

zgrid = load('zgrid.txt');
P = load('P.txt');
Pi = load('Pi.txt'); % Invariant distribution of productivity

lambda_data = load('lambda_HW6.in');
ages = lambda_data(:,1);
lambda_values = lambda_data(:,2);

% Create a full lambda vector for all ages in the model (1 to T)
lambda = ones(T, 1);
for i = 1:length(ages)
    age = ages(i);
    if age >= 1 && age <= T
        lambda(age) = lambda_values(i);
    end
end

% For ages not covered in the file (1-24), use a simple increasing pattern
for t = 1:24
    lambda(t) = lambda(25) * (t/25)^2; % Quadratic increase up to age 25
end

nz = length(zgrid);

%% Initialize arrays for solving the model
% Initialize value functions and decision rules
V = zeros(nk, nz, R-1);  % Value function for working ages (1 to R-1)
VR = zeros(nk, T-R+1);   % Value function for retirement ages (R to T)

copt = zeros(nk, nz, R-1);   % Consumption for working ages
kopt = zeros(nk, nz, R-1);   % Savings for working ages
lopt = zeros(nk, nz, R-1);   % Labor supply for working ages

coptR = zeros(nk, T-R+1);    % Consumption for retired ages
koptR = zeros(nk, T-R+1);    % Savings for retired ages

% Tolerance level for convergence
tol = 1e-4;
max_iter = 100;

%% Solving the model with Social Security (tau = 0.11)

% Initial guesses for interest rate and pension benefit
r_guess = 0.04;
b_guess = 0.4;

diff = 1;
iter = 0;

fprintf('\nSolving model with Social Security (tau = %.2f, beta = %.2f)\n', tau, beta);

% Main loop for finding equilibrium
while diff > tol && iter < max_iter
    iter = iter + 1;
    
    % Compute capital-to-labor ratio and wage
    K_N = ((r_guess + delta) / alpha)^(1/(alpha-1));
    w = (1-alpha) * K_N^alpha;
    
    %% Solve household problem using backward induction
    
    % (a) Solve for retirement years (backward from T to R)
    for t = T:-1:R
        t_index = t - R + 1;  % Index for the VR, coptR, and koptR arrays
        
        for ik = 1:nk
            k = kgrid(ik);
            
            if t == T
                % In the last period, consume everything
                coptR(ik, t_index) = k * (1 + r_guess) + b_guess;
                koptR(ik, t_index) = 0;
                
                % Compute utility (labor supply is 0 in retirement)
                VR(ik, t_index) = utility(coptR(ik, t_index), 0, mu, sigma);
            else
                % For other retirement periods, solve for optimal savings
                max_val = -1e10;
                opt_c = 0;
                opt_k = 0;
                
                for ik_next = 1:nk
                    k_next = kgrid(ik_next);
                    c = k * (1 + r_guess) + b_guess - k_next;
                    
                    if c > 0 % Check for positive consumption
                        next_t_index = t_index + 1;  % Index for the next period
                        val = utility(c, 0, mu, sigma) + beta * VR(ik_next, next_t_index);
                        
                        if val > max_val
                            max_val = val;
                            opt_c = c;
                            opt_k = k_next;
                        end
                    end
                end
                
                coptR(ik, t_index) = opt_c;
                koptR(ik, t_index) = opt_k;
                VR(ik, t_index) = max_val;
            end
        end
    end
    
    % Solve for working years (backward from R-1 to 1)
    for t = (R-1):-1:1
        for ik = 1:nk
            for iz = 1:nz
                k = kgrid(ik);
                z = zgrid(iz);
                
                max_val = -1e10;
                opt_c = 0;
                opt_k = 0;
                opt_l = 0;
                
                for ik_next = 1:nk
                    k_next = kgrid(ik_next);
                    
                    % Calculate labor supply using FOC
                    l = (mu*w*exp(z)*lambda(t)*(1-tau) - (1-mu)*(k*(1+r_guess) - k_next)) / (w*exp(z)*lambda(t)*(1-tau));
                    
                    l = min(max(l, 0), 1);
                    
                    % Calculate consumption
                    c = k*(1+r_guess) + w*exp(z)*lambda(t)*l*(1-tau) - k_next;
                    
                    if c > 0
                        % Calculate expected value for next period
                        expected_val = 0;
                        
                        if t == R-1
                            for ik_r = 1:nk
                                if abs(kgrid(ik_r) - k_next) < 1e-10
                                    expected_val = VR(ik_r, 1);
                                    break;
                                elseif kgrid(ik_r) > k_next
                                    % Linear interpolation
                                    weight = (k_next - kgrid(ik_r-1)) / (kgrid(ik_r) - kgrid(ik_r-1));
                                    expected_val = VR(ik_r-1, 1) * (1-weight) + VR(ik_r, 1) * weight;
                                    break;
                                end
                            end
                        else
                            % Expected value over possible productivity shocks
                            for iz_next = 1:nz
                                prob = P(iz, iz_next);
                                
                                % Linear interpolation for k_next
                                if k_next <= kgrid(1)
                                    expected_val = expected_val + prob * V(1, iz_next, t+1);
                                elseif k_next >= kgrid(end)
                                    expected_val = expected_val + prob * V(end, iz_next, t+1);
                                else
                                    % Find nearest grid points
                                    ik_low = find(kgrid <= k_next, 1, 'last');
                                    ik_high = find(kgrid >= k_next, 1, 'first');
                                    
                                    if ik_low == ik_high
                                        expected_val = expected_val + prob * V(ik_low, iz_next, t+1);
                                    else
                                        % Linear interpolation
                                        weight = (k_next - kgrid(ik_low)) / (kgrid(ik_high) - kgrid(ik_low));
                                        expected_val = expected_val + prob * ...
                                            (V(ik_low, iz_next, t+1) * (1-weight) + ...
                                             V(ik_high, iz_next, t+1) * weight);
                                    end
                                end
                            end
                        end
                        
                        val = utility(c, l, mu, sigma) + beta * expected_val;
                        
                        if val > max_val
                            max_val = val;
                            opt_c = c;
                            opt_k = k_next;
                            opt_l = l;
                        end
                    end
                end
                
                copt(ik, iz, t) = opt_c;
                kopt(ik, iz, t) = opt_k;
                lopt(ik, iz, t) = opt_l;
                V(ik, iz, t) = max_val;
            end
        end
    end
    
    %% Compute invariant distribution using non-stochastic simulation
    % Initialize distributions
    Gamma = zeros(nk, nz, R-1);     % Distribution for working ages (1 to R-1)
    GammaR = zeros(nk, T-R+1);      % Distribution for retirement ages (R to T)
    
    Gamma(1, :, 1) = Pi; % Use the loaded invariant distribution
    
    % Compute age-dependent adjustment factor for population growth
    adj = zeros(1, T);
    g = 1;
    for t = T:-1:1
        adj(t) = g;
        g = g * (1 + n);
    end
    
    % Forward iteration for ages 1 to T
    for t = 1:T-1
        if t < R
            % Working age
            for ik = 1:nk
                for iz = 1:nz
                    mass = Gamma(ik, iz, t);
                    if mass > 0
                        k_next = kopt(ik, iz, t);
                        
                        % Find location of k_next in grid
                        if k_next <= kgrid(1)
                            j_lo = 1;
                            weight = 0;
                        elseif k_next >= kgrid(end)
                            j_lo = nk - 1;
                            weight = 1;
                        else
                            j_lo = find(kgrid <= k_next, 1, 'last');
                            weight = (k_next - kgrid(j_lo)) / (kgrid(j_lo+1) - kgrid(j_lo));
                        end
                        
                        % Distribute mass based on transition probabilities
                        if t < R-1
                            for iz_next = 1:nz
                                Gamma(j_lo, iz_next, t+1) = Gamma(j_lo, iz_next, t+1) + ...
                                    mass * (1-weight) * P(iz, iz_next);
                                Gamma(j_lo+1, iz_next, t+1) = Gamma(j_lo+1, iz_next, t+1) + ...
                                    mass * weight * P(iz, iz_next);
                            end
                        else
                            GammaR(j_lo, 1) = GammaR(j_lo, 1) + mass * (1-weight);
                            GammaR(j_lo+1, 1) = GammaR(j_lo+1, 1) + mass * weight;
                        end
                    end
                end
            end
        else
            % Retirement age
            for ik = 1:nk
                mass = GammaR(ik, t-R+1);
                if mass > 0
                    t_index = t - R + 1;  % Index for retirement arrays
                    next_t_index = t_index + 1;  % Index for next period
                    
                    k_next = koptR(ik, t_index);
                    
                    % Find location of k_next in grid
                    if k_next <= kgrid(1)
                        j_lo = 1;
                        weight = 0;
                    elseif k_next >= kgrid(end)
                        j_lo = nk - 1;
                        weight = 1;
                    else
                        j_lo = find(kgrid <= k_next, 1, 'last');
                        weight = (k_next - kgrid(j_lo)) / (kgrid(j_lo+1) - kgrid(j_lo));
                    end
                    
                    if t < T
                        GammaR(j_lo, next_t_index) = GammaR(j_lo, next_t_index) + mass * (1-weight);
                        GammaR(j_lo+1, next_t_index) = GammaR(j_lo+1, next_t_index) + mass * weight;
                    end
                end
            end
        end
    end
    
    % Adjust for population growth
    for t = 1:R-1
        Gamma(:, :, t) = Gamma(:, :, t) * adj(t);
    end
    
    for t = 1:T-R+1
        GammaR(:, t) = GammaR(:, t) * adj(t+R-1);
    end

    total_mass = sum(sum(sum(Gamma))) + sum(sum(GammaR));
    Gamma = Gamma / total_mass;
    GammaR = GammaR / total_mass;
    
    %% Compute aggregate K and L using the corrected formulas
    K = 0;
    L = 0;
    
    for t = 1:R-1
        for iz = 1:nz
            for ik = 1:nk
                K = K + Gamma(ik, iz, t) * kgrid(ik);
            end
        end
    end
    
    for t = 1:T-R+1
        for ik = 1:nk
            K = K + GammaR(ik, t) * kgrid(ik);
        end
    end
    
    for t = 1:R-1
        for iz = 1:nz
            for ik = 1:nk
                L = L + lambda(t) * exp(zgrid(iz)) * Gamma(ik, iz, t) * lopt(ik, iz, t);
            end
        end
    end
    
    % Compute new interest rate and wage
    r_new = alpha * (K/L)^(alpha-1) - delta;
    w_new = (1-alpha) * (K/L)^alpha;
    
    numerator = tau * w * L;
    denominator = 0;
    
    for t = 1:T-R+1
        for ik = 1:nk
            denominator = denominator + GammaR(ik, t);
        end
    end
    
    b_new = numerator / denominator;
    
    %% Check convergence and update
    diff = max(abs(r_new - r_guess), abs(b_new - b_guess));
    
    % Update with weighted avg. to improve convergence
    r_guess = 0.7 * r_guess + 0.3 * r_new;
    b_guess = 0.7 * b_guess + 0.3 * b_new;
    
    fprintf('Iteration %d: r = %.6f, b = %.6f, diff = %.6f\n', iter, r_guess, b_guess, diff);
end

%% Store results with Social Security
r_with_SS = r_guess;
b_with_SS = b_guess;
w_with_SS = w_new;
K_with_SS = K;
L_with_SS = L;
Y_with_SS = K^alpha * L^(1-alpha);
Gamma_with_SS = Gamma;
GammaR_with_SS = GammaR;
copt_with_SS = copt;
kopt_with_SS = kopt;
lopt_with_SS = lopt;
coptR_with_SS = coptR;
koptR_with_SS = koptR;
V_with_SS = V;
VR_with_SS = VR;

% Compute welfare of newborn with Social Security
V_o_with_SS = compute_newborn_welfare(V_with_SS, Pi);

fprintf('\nResults with Social Security (tau = %.2f):\n', tau);
fprintf('Interest rate: %.4f\n', r_with_SS);
fprintf('Wage rate: %.4f\n', w_with_SS);
fprintf('Pension benefit: %.4f\n', b_with_SS);
fprintf('Aggregate capital: %.4f\n', K_with_SS);
fprintf('Aggregate labor: %.4f\n', L_with_SS);
fprintf('Output: %.4f\n', Y_with_SS);
fprintf('Welfare of newborn: %.4f\n', V_o_with_SS);

%% Solving the model without Social Security (tau = 0)
fprintf('\nSolving model without Social Security (tau = 0, beta = %.2f)\n', beta);

% Set tau = 0 for the case without Social Security
tau = 0;

r_guess = r_with_SS;
b_guess = 0;  % No pension benefit with tau = 0

diff = 1;
iter = 0;

% Main loop (same as before but with tau = 0)
while diff > tol && iter < max_iter
    iter = iter + 1;
    
    % Step 3: Compute K/N, w based on r_guess
    K_N = ((r_guess + delta) / alpha)^(1/(alpha-1));
    w = (1-alpha) * K_N^alpha;
    
    %% Solve household problem using backward induction
    
    V = zeros(nk, nz, R-1);  % Value function for working ages (1 to R-1)
    VR = zeros(nk, T-R+1);   % Value function for retirement ages (R to T)
    
    % Decision rules
    copt = zeros(nk, nz, R-1);   % Consumption for working ages
    kopt = zeros(nk, nz, R-1);   % Savings for working ages
    lopt = zeros(nk, nz, R-1);   % Labor supply for working ages
    
    coptR = zeros(nk, T-R+1);    % Consumption for retired ages
    koptR = zeros(nk, T-R+1);    % Savings for retired ages
    
    % Solve for retirement years (backward from T to R)
    for t = T:-1:R
        t_index = t - R + 1;  % Index for the VR, coptR, and koptR arrays
        
        for ik = 1:nk
            k = kgrid(ik);
            
            if t == T
                % In the last period, consume everything
                coptR(ik, t_index) = k * (1 + r_guess) + b_guess;
                koptR(ik, t_index) = 0;
                
                % Compute utility (labor supply is 0 in retirement)
                VR(ik, t_index) = utility(coptR(ik, t_index), 0, mu, sigma);
            else
                % For other retirement periods, solve for optimal savings
                max_val = -1e10;
                opt_c = 0;
                opt_k = 0;
                
                for ik_next = 1:nk
                    k_next = kgrid(ik_next);
                    c = k * (1 + r_guess) + b_guess - k_next;
                    
                    if c > 0 % Check for positive consumption
                        next_t_index = t_index + 1;  % Index for the next period
                        val = utility(c, 0, mu, sigma) + beta * VR(ik_next, next_t_index);
                        
                        if val > max_val
                            max_val = val;
                            opt_c = c;
                            opt_k = k_next;
                        end
                    end
                end
                
                coptR(ik, t_index) = opt_c;
                koptR(ik, t_index) = opt_k;
                VR(ik, t_index) = max_val;
            end
        end
    end
    
    % Solve for working years (backward from R-1 to 1)
    for t = (R-1):-1:1
        for ik = 1:nk
            for iz = 1:nz
                k = kgrid(ik);
                z = zgrid(iz);
                
                max_val = -1e10;
                opt_c = 0;
                opt_k = 0;
                opt_l = 0;
                
                for ik_next = 1:nk
                    k_next = kgrid(ik_next);
                    
                    % Calculate labor supply using FOC (as shown in the algorithm)
                    l = (mu*w*exp(z)*lambda(t)*(1-tau) - (1-mu)*(k*(1+r_guess) - k_next)) / (w*exp(z)*lambda(t)*(1-tau));
                    
                    % Ensure labor supply is in the correct range [0,1]
                    l = min(max(l, 0), 1);
                    
                    % Calculate consumption
                    c = k*(1+r_guess) + w*exp(z)*lambda(t)*l*(1-tau) - k_next;
                    
                    if c > 0
                        % Calculate expected value for next period
                        expected_val = 0;
                        
                        if t == R-1
                            % Transition to retirement in the next period
                            for ik_r = 1:nk
                                if abs(kgrid(ik_r) - k_next) < 1e-10
                                    expected_val = VR(ik_r, 1);
                                    break;
                                elseif kgrid(ik_r) > k_next
                                    % Linear interpolation
                                    weight = (k_next - kgrid(ik_r-1)) / (kgrid(ik_r) - kgrid(ik_r-1));
                                    expected_val = VR(ik_r-1, 1) * (1-weight) + VR(ik_r, 1) * weight;
                                    break;
                                end
                            end
                        else
                            % Expected value over possible productivity shocks
                            for iz_next = 1:nz
                                prob = P(iz, iz_next);
                                
                                % Linear interpolation for k_next
                                if k_next <= kgrid(1)
                                    expected_val = expected_val + prob * V(1, iz_next, t+1);
                                elseif k_next >= kgrid(end)
                                    expected_val = expected_val + prob * V(end, iz_next, t+1);
                                else
                                    % Find nearest grid points
                                    ik_low = find(kgrid <= k_next, 1, 'last');
                                    ik_high = find(kgrid >= k_next, 1, 'first');
                                    
                                    if ik_low == ik_high
                                        expected_val = expected_val + prob * V(ik_low, iz_next, t+1);
                                    else
                                        % Linear interpolation
                                        weight = (k_next - kgrid(ik_low)) / (kgrid(ik_high) - kgrid(ik_low));
                                        expected_val = expected_val + prob * ...
                                            (V(ik_low, iz_next, t+1) * (1-weight) + ...
                                             V(ik_high, iz_next, t+1) * weight);
                                    end
                                end
                            end
                        end
                        
                        val = utility(c, l, mu, sigma) + beta * expected_val;
                        
                        if val > max_val
                            max_val = val;
                            opt_c = c;
                            opt_k = k_next;
                            opt_l = l;
                        end
                    end
                end
                
                copt(ik, iz, t) = opt_c;
                kopt(ik, iz, t) = opt_k;
                lopt(ik, iz, t) = opt_l;
                V(ik, iz, t) = max_val;
            end
        end
    end
    
    %% Compute invariant distribution 
    % Initialize distributions
    Gamma = zeros(nk, nz, R-1);     % Distribution for working ages (1 to R-1)
    GammaR = zeros(nk, T-R+1);      % Distribution for retirement ages (R to T)
    
    Gamma(1, :, 1) = Pi; % Use the loaded invariant distribution
    
    % Forward iteration for ages 1 to T
    for t = 1:T-1
        if t < R
            % Working age
            for ik = 1:nk
                for iz = 1:nz
                    mass = Gamma(ik, iz, t);
                    if mass > 0
                        k_next = kopt(ik, iz, t);
                        
                        % Find location of k_next in grid
                        if k_next <= kgrid(1)
                            j_lo = 1;
                            weight = 0;
                        elseif k_next >= kgrid(end)
                            j_lo = nk - 1;
                            weight = 1;
                        else
                            j_lo = find(kgrid <= k_next, 1, 'last');
                            weight = (k_next - kgrid(j_lo)) / (kgrid(j_lo+1) - kgrid(j_lo));
                        end
                        
                        if t < R-1
                            for iz_next = 1:nz
                                Gamma(j_lo, iz_next, t+1) = Gamma(j_lo, iz_next, t+1) + ...
                                    mass * (1-weight) * P(iz, iz_next);
                                Gamma(j_lo+1, iz_next, t+1) = Gamma(j_lo+1, iz_next, t+1) + ...
                                    mass * weight * P(iz, iz_next);
                            end
                        else
                            % Working age -> retirement transition
                            GammaR(j_lo, 1) = GammaR(j_lo, 1) + mass * (1-weight);
                            GammaR(j_lo+1, 1) = GammaR(j_lo+1, 1) + mass * weight;
                        end
                    end
                end
            end
        else
            % Retirement age
            for ik = 1:nk
                mass = GammaR(ik, t-R+1);
                if mass > 0
                    t_index = t - R + 1;  % Index for retirement arrays
                    next_t_index = t_index + 1;  % Index for next period
                    
                    k_next = koptR(ik, t_index);
                    
                    % Find location of k_next in grid
                    if k_next <= kgrid(1)
                        j_lo = 1;
                        weight = 0;
                    elseif k_next >= kgrid(end)
                        j_lo = nk - 1;
                        weight = 1;
                    else
                        j_lo = find(kgrid <= k_next, 1, 'last');
                        weight = (k_next - kgrid(j_lo)) / (kgrid(j_lo+1) - kgrid(j_lo));
                    end
                    
                    % Distribute mass for next period
                    if t < T
                        GammaR(j_lo, next_t_index) = GammaR(j_lo, next_t_index) + mass * (1-weight);
                        GammaR(j_lo+1, next_t_index) = GammaR(j_lo+1, next_t_index) + mass * weight;
                    end
                end
            end
        end
    end
    
    % Adjust for population growth
    for t = 1:R-1
        Gamma(:, :, t) = Gamma(:, :, t) * adj(t);
    end
    
    for t = 1:T-R+1
        GammaR(:, t) = GammaR(:, t) * adj(t+R-1);
    end
    
    total_mass = sum(sum(sum(Gamma))) + sum(sum(GammaR));
    Gamma = Gamma / total_mass;
    GammaR = GammaR / total_mass;
    
    %% Compute aggregate K and L 
    K = 0;
    L = 0;
    
    for t = 1:R-1
        for iz = 1:nz
            for ik = 1:nk
                K = K + Gamma(ik, iz, t) * kgrid(ik);
            end
        end
    end
    
    for t = 1:T-R+1
        for ik = 1:nk
            K = K + GammaR(ik, t) * kgrid(ik);
        end
    end
    
    for t = 1:R-1
        for iz = 1:nz
            for ik = 1:nk
                L = L + lambda(t) * exp(zgrid(iz)) * Gamma(ik, iz, t) * lopt(ik, iz, t);
            end
        end
    end
    
    % Compute new interest rate and wage
    r_new = alpha * (K/L)^(alpha-1) - delta;
    w_new = (1-alpha) * (K/L)^alpha;
    
    % No pension benefit with tau = 0
    b_new = 0;
    
    %% Check convergence and update
    diff = abs(r_new - r_guess);
    
    % Update with weighted avg to improve convergence
    r_guess = 0.7 * r_guess + 0.3 * r_new;
    
    fprintf('Iteration %d: r = %.6f, diff = %.6f\n', iter, r_guess, diff);
end

%% Store results without Social Security
r_without_SS = r_guess;
b_without_SS = b_guess;
w_without_SS = w_new;
K_without_SS = K;
L_without_SS = L;
Y_without_SS = K^alpha * L^(1-alpha);
Gamma_without_SS = Gamma;
GammaR_without_SS = GammaR;
copt_without_SS = copt;
kopt_without_SS = kopt;
lopt_without_SS = lopt;
coptR_without_SS = coptR;
koptR_without_SS = koptR;
V_without_SS = V;
VR_without_SS = VR;

% Compute welfare of newborn without Social Security
V_o_without_SS = compute_newborn_welfare(V_without_SS, Pi);

fprintf('\nResults without Social Security (tau = 0):\n');
fprintf('Interest rate: %.4f\n', r_without_SS);
fprintf('Wage rate: %.4f\n', w_without_SS);
fprintf('Pension benefit: %.4f\n', b_without_SS);
fprintf('Aggregate capital: %.4f\n', K_without_SS);
fprintf('Aggregate labor: %.4f\n', L_without_SS);
fprintf('Output: %.4f\n', Y_without_SS);
fprintf('Welfare of newborn: %.4f\n', V_o_without_SS);

%% Comparison of results with and without Social Security
fprintf('\nComparison of Results with Beta = %.2f:\n', beta);
fprintf('%-20s %-15s %-15s %-15s\n', 'Variable', 'With SS', 'Without SS', 'Change (%)');
fprintf('%-20s %-15.4f %-15.4f %-15.2f\n', 'Interest rate', r_with_SS, r_without_SS, (r_without_SS/r_with_SS-1)*100);
fprintf('%-20s %-15.4f %-15.4f %-15.2f\n', 'Aggregate capital', K_with_SS, K_without_SS, (K_without_SS/K_with_SS-1)*100);
fprintf('%-20s %-15.4f %-15.4f %-15.2f\n', 'Aggregate labor', L_with_SS, L_without_SS, (L_without_SS/L_with_SS-1)*100);
fprintf('%-20s %-15.4f %-15.4f %-15.2f\n', 'Wage rate', w_with_SS, w_without_SS, (w_without_SS/w_with_SS-1)*100);
fprintf('%-20s %-15.4f %-15.4f %-15.2f\n', 'Output', Y_with_SS, Y_without_SS, (Y_without_SS/Y_with_SS-1)*100);
fprintf('%-20s %-15.4f %-15.4f %-15.2f\n', 'Newborn welfare', V_o_with_SS, V_o_without_SS, (V_o_without_SS/V_o_with_SS-1)*100);

if V_o_without_SS > V_o_with_SS
    fprintf('\nNewborn generations prefer to start in a steady state WITHOUT Social Security.\n');
else
    fprintf('\nNewborn generations prefer to start in a steady state WITH Social Security.\n');
end

%% Plot wealth and labor supply profiles by age
figure;

% Compute average capital by age
avg_k_with_SS = compute_avg_k_by_age(Gamma_with_SS, GammaR_with_SS, kgrid, T, R);
avg_k_without_SS = compute_avg_k_by_age(Gamma_without_SS, GammaR_without_SS, kgrid, T, R);

subplot(2,1,1);
plot(1:T, avg_k_with_SS, 'b-', 'LineWidth', 2);
hold on;
plot(1:T, avg_k_without_SS, 'r--', 'LineWidth', 2);
xlabel('Age');
ylabel('Capital');
title('Average Capital by Age');
legend('With Social Security', 'Without Social Security');
grid on;
xline(R, 'k--', 'Retirement Age');

% Compute average labor supply by age
avg_l_with_SS = compute_avg_l_by_age(Gamma_with_SS, lopt_with_SS, R);
avg_l_without_SS = compute_avg_l_by_age(Gamma_without_SS, lopt_without_SS, R);

subplot(2,1,2);
plot(1:R-1, avg_l_with_SS, 'b-', 'LineWidth', 2);
hold on;
plot(1:R-1, avg_l_without_SS, 'r--', 'LineWidth', 2);
xlabel('Age');
ylabel('Labor Supply');
title('Average Labor Supply by Age');
legend('With Social Security', 'Without Social Security');
grid on;

saveas(gcf, 'wealth_labor_profiles.png');

%% Results table as required in the homework
results_table = table;
results_table.Variables = [K_with_SS, K_without_SS; 
                          L_with_SS, L_without_SS;
                          w_with_SS, w_without_SS;
                          r_with_SS, r_without_SS;
                          b_with_SS, b_without_SS;
                          V_o_with_SS, V_o_without_SS];
results_table.Properties.RowNames = {'capital K', 'labor L', 'wage w', 'interest r', 'pension benefit b', 'newborn welfare V^o'};
results_table.Properties.VariableNames = {'with_SS', 'without_SS'};

% Display the table
disp(results_table);

%% Repeating with beta = 0.99
% Initialize value functions and decision rules
beta = 0.99;
V = zeros(nk, nz, R-1);  % Value function for working ages (1 to R-1)
VR = zeros(nk, T-R+1);   % Value function for retirement ages (R to T)

copt = zeros(nk, nz, R-1);   % Consumption for working ages
kopt = zeros(nk, nz, R-1);   % Savings for working ages
lopt = zeros(nk, nz, R-1);   % Labor supply for working ages

coptR = zeros(nk, T-R+1);    % Consumption for retired ages
koptR = zeros(nk, T-R+1);    % Savings for retired ages

% Tolerance level for convergence
tol = 1e-4;
max_iter = 100;

%% Solving the model with Social Security (tau = 0.11)

% Initial guesses for interest rate and pension benefit
r_guess = 0.04;
b_guess = 0.4;

diff = 1;
iter = 0;

fprintf('\nSolving model with Social Security (tau = %.2f, beta = %.2f)\n', tau, beta);

% Main loop for finding equilibrium
while diff > tol && iter < max_iter
    iter = iter + 1;
    
    % Compute capital-to-labor ratio and wage
    K_N = ((r_guess + delta) / alpha)^(1/(alpha-1));
    w = (1-alpha) * K_N^alpha;
    
    %% Solve household problem using backward induction
    
    % (a) Solve for retirement years (backward from T to R)
    for t = T:-1:R
        t_index = t - R + 1;  % Index for the VR, coptR, and koptR arrays
        
        for ik = 1:nk
            k = kgrid(ik);
            
            if t == T
                % In the last period, consume everything
                coptR(ik, t_index) = k * (1 + r_guess) + b_guess;
                koptR(ik, t_index) = 0;
                
                % Compute utility (labor supply is 0 in retirement)
                VR(ik, t_index) = utility(coptR(ik, t_index), 0, mu, sigma);
            else
                % For other retirement periods, solve for optimal savings
                max_val = -1e10;
                opt_c = 0;
                opt_k = 0;
                
                for ik_next = 1:nk
                    k_next = kgrid(ik_next);
                    c = k * (1 + r_guess) + b_guess - k_next;
                    
                    if c > 0 % Check for positive consumption
                        next_t_index = t_index + 1;  % Index for the next period
                        val = utility(c, 0, mu, sigma) + beta * VR(ik_next, next_t_index);
                        
                        if val > max_val
                            max_val = val;
                            opt_c = c;
                            opt_k = k_next;
                        end
                    end
                end
                
                coptR(ik, t_index) = opt_c;
                koptR(ik, t_index) = opt_k;
                VR(ik, t_index) = max_val;
            end
        end
    end
    
    % Solve for working years (backward from R-1 to 1)
    for t = (R-1):-1:1
        for ik = 1:nk
            for iz = 1:nz
                k = kgrid(ik);
                z = zgrid(iz);
                
                max_val = -1e10;
                opt_c = 0;
                opt_k = 0;
                opt_l = 0;
                
                for ik_next = 1:nk
                    k_next = kgrid(ik_next);
                    
                    % Calculate labor supply using FOC
                    l = (mu*w*exp(z)*lambda(t)*(1-tau) - (1-mu)*(k*(1+r_guess) - k_next)) / (w*exp(z)*lambda(t)*(1-tau));
                    
                    l = min(max(l, 0), 1);
                    
                    % Calculate consumption
                    c = k*(1+r_guess) + w*exp(z)*lambda(t)*l*(1-tau) - k_next;
                    
                    if c > 0
                        % Calculate expected value for next period
                        expected_val = 0;
                        
                        if t == R-1
                            for ik_r = 1:nk
                                if abs(kgrid(ik_r) - k_next) < 1e-10
                                    expected_val = VR(ik_r, 1);
                                    break;
                                elseif kgrid(ik_r) > k_next
                                    % Linear interpolation
                                    weight = (k_next - kgrid(ik_r-1)) / (kgrid(ik_r) - kgrid(ik_r-1));
                                    expected_val = VR(ik_r-1, 1) * (1-weight) + VR(ik_r, 1) * weight;
                                    break;
                                end
                            end
                        else
                            % Expected value over possible productivity shocks
                            for iz_next = 1:nz
                                prob = P(iz, iz_next);
                                
                                % Linear interpolation for k_next
                                if k_next <= kgrid(1)
                                    expected_val = expected_val + prob * V(1, iz_next, t+1);
                                elseif k_next >= kgrid(end)
                                    expected_val = expected_val + prob * V(end, iz_next, t+1);
                                else
                                    % Find nearest grid points
                                    ik_low = find(kgrid <= k_next, 1, 'last');
                                    ik_high = find(kgrid >= k_next, 1, 'first');
                                    
                                    if ik_low == ik_high
                                        expected_val = expected_val + prob * V(ik_low, iz_next, t+1);
                                    else
                                        % Linear interpolation
                                        weight = (k_next - kgrid(ik_low)) / (kgrid(ik_high) - kgrid(ik_low));
                                        expected_val = expected_val + prob * ...
                                            (V(ik_low, iz_next, t+1) * (1-weight) + ...
                                             V(ik_high, iz_next, t+1) * weight);
                                    end
                                end
                            end
                        end
                        
                        val = utility(c, l, mu, sigma) + beta * expected_val;
                        
                        if val > max_val
                            max_val = val;
                            opt_c = c;
                            opt_k = k_next;
                            opt_l = l;
                        end
                    end
                end
                
                copt(ik, iz, t) = opt_c;
                kopt(ik, iz, t) = opt_k;
                lopt(ik, iz, t) = opt_l;
                V(ik, iz, t) = max_val;
            end
        end
    end
    
    %% Compute invariant distribution using non-stochastic simulation
    % Initialize distributions
    Gamma = zeros(nk, nz, R-1);     % Distribution for working ages (1 to R-1)
    GammaR = zeros(nk, T-R+1);      % Distribution for retirement ages (R to T)
    
    Gamma(1, :, 1) = Pi; % Use the loaded invariant distribution
    
    % Compute age-dependent adjustment factor for population growth
    adj = zeros(1, T);
    g = 1;
    for t = T:-1:1
        adj(t) = g;
        g = g * (1 + n);
    end
    
    % Forward iteration for ages 1 to T
    for t = 1:T-1
        if t < R
            % Working age
            for ik = 1:nk
                for iz = 1:nz
                    mass = Gamma(ik, iz, t);
                    if mass > 0
                        k_next = kopt(ik, iz, t);
                        
                        % Find location of k_next in grid
                        if k_next <= kgrid(1)
                            j_lo = 1;
                            weight = 0;
                        elseif k_next >= kgrid(end)
                            j_lo = nk - 1;
                            weight = 1;
                        else
                            j_lo = find(kgrid <= k_next, 1, 'last');
                            weight = (k_next - kgrid(j_lo)) / (kgrid(j_lo+1) - kgrid(j_lo));
                        end
                        
                        % Distribute mass based on transition probabilities
                        if t < R-1
                            for iz_next = 1:nz
                                Gamma(j_lo, iz_next, t+1) = Gamma(j_lo, iz_next, t+1) + ...
                                    mass * (1-weight) * P(iz, iz_next);
                                Gamma(j_lo+1, iz_next, t+1) = Gamma(j_lo+1, iz_next, t+1) + ...
                                    mass * weight * P(iz, iz_next);
                            end
                        else
                            GammaR(j_lo, 1) = GammaR(j_lo, 1) + mass * (1-weight);
                            GammaR(j_lo+1, 1) = GammaR(j_lo+1, 1) + mass * weight;
                        end
                    end
                end
            end
        else
            % Retirement age
            for ik = 1:nk
                mass = GammaR(ik, t-R+1);
                if mass > 0
                    t_index = t - R + 1;  % Index for retirement arrays
                    next_t_index = t_index + 1;  % Index for next period
                    
                    k_next = koptR(ik, t_index);
                    
                    % Find location of k_next in grid
                    if k_next <= kgrid(1)
                        j_lo = 1;
                        weight = 0;
                    elseif k_next >= kgrid(end)
                        j_lo = nk - 1;
                        weight = 1;
                    else
                        j_lo = find(kgrid <= k_next, 1, 'last');
                        weight = (k_next - kgrid(j_lo)) / (kgrid(j_lo+1) - kgrid(j_lo));
                    end
                    
                    if t < T
                        GammaR(j_lo, next_t_index) = GammaR(j_lo, next_t_index) + mass * (1-weight);
                        GammaR(j_lo+1, next_t_index) = GammaR(j_lo+1, next_t_index) + mass * weight;
                    end
                end
            end
        end
    end
    
    % Adjust for population growth
    for t = 1:R-1
        Gamma(:, :, t) = Gamma(:, :, t) * adj(t);
    end
    
    for t = 1:T-R+1
        GammaR(:, t) = GammaR(:, t) * adj(t+R-1);
    end

    total_mass = sum(sum(sum(Gamma))) + sum(sum(GammaR));
    Gamma = Gamma / total_mass;
    GammaR = GammaR / total_mass;
    
    %% Compute aggregate K and L using the corrected formulas
    K = 0;
    L = 0;
    
    for t = 1:R-1
        for iz = 1:nz
            for ik = 1:nk
                K = K + Gamma(ik, iz, t) * kgrid(ik);
            end
        end
    end
    
    for t = 1:T-R+1
        for ik = 1:nk
            K = K + GammaR(ik, t) * kgrid(ik);
        end
    end
    
    for t = 1:R-1
        for iz = 1:nz
            for ik = 1:nk
                L = L + lambda(t) * exp(zgrid(iz)) * Gamma(ik, iz, t) * lopt(ik, iz, t);
            end
        end
    end
    
    % Compute new interest rate and wage
    r_new = alpha * (K/L)^(alpha-1) - delta;
    w_new = (1-alpha) * (K/L)^alpha;
    
    numerator = tau * w * L;
    denominator = 0;
    
    for t = 1:T-R+1
        for ik = 1:nk
            denominator = denominator + GammaR(ik, t);
        end
    end
    
    b_new = numerator / denominator;
    
    %% Check convergence and update
    diff = max(abs(r_new - r_guess), abs(b_new - b_guess));
    
    % Update with weighted avg. to improve convergence
    r_guess = 0.7 * r_guess + 0.3 * r_new;
    b_guess = 0.7 * b_guess + 0.3 * b_new;
    
    fprintf('Iteration %d: r = %.6f, b = %.6f, diff = %.6f\n', iter, r_guess, b_guess, diff);
end

%% Store results with Social Security
r_with_SS = r_guess;
b_with_SS = b_guess;
w_with_SS = w_new;
K_with_SS = K;
L_with_SS = L;
Y_with_SS = K^alpha * L^(1-alpha);
Gamma_with_SS = Gamma;
GammaR_with_SS = GammaR;
copt_with_SS = copt;
kopt_with_SS = kopt;
lopt_with_SS = lopt;
coptR_with_SS = coptR;
koptR_with_SS = koptR;
V_with_SS = V;
VR_with_SS = VR;

% Compute welfare of newborn with Social Security
V_o_with_SS = compute_newborn_welfare(V_with_SS, Pi);

fprintf('\nResults with Social Security (tau = %.2f), beta = 0.99:\n', tau);
fprintf('Interest rate: %.4f\n', r_with_SS);
fprintf('Wage rate: %.4f\n', w_with_SS);
fprintf('Pension benefit: %.4f\n', b_with_SS);
fprintf('Aggregate capital: %.4f\n', K_with_SS);
fprintf('Aggregate labor: %.4f\n', L_with_SS);
fprintf('Output: %.4f\n', Y_with_SS);
fprintf('Welfare of newborn: %.4f\n', V_o_with_SS);

%% Solving the model without Social Security (tau = 0), beta = 0.99
fprintf('\nSolving model without Social Security (tau = 0, beta = %.2f)\n', beta);

% Set tau = 0 for the case without Social Security
tau = 0;

r_guess = r_with_SS;
b_guess = 0;  % No pension benefit with tau = 0

diff = 1;
iter = 0;

% Main loop (same as before but with tau = 0)
while diff > tol && iter < max_iter
    iter = iter + 1;
    
    % Step 3: Compute K/N, w based on r_guess
    K_N = ((r_guess + delta) / alpha)^(1/(alpha-1));
    w = (1-alpha) * K_N^alpha;
    
    %% Solve household problem using backward induction
    
    V = zeros(nk, nz, R-1);  % Value function for working ages (1 to R-1)
    VR = zeros(nk, T-R+1);   % Value function for retirement ages (R to T)
    
    % Decision rules
    copt = zeros(nk, nz, R-1);   % Consumption for working ages
    kopt = zeros(nk, nz, R-1);   % Savings for working ages
    lopt = zeros(nk, nz, R-1);   % Labor supply for working ages
    
    coptR = zeros(nk, T-R+1);    % Consumption for retired ages
    koptR = zeros(nk, T-R+1);    % Savings for retired ages
    
    % Solve for retirement years (backward from T to R)
    for t = T:-1:R
        t_index = t - R + 1;  % Index for the VR, coptR, and koptR arrays
        
        for ik = 1:nk
            k = kgrid(ik);
            
            if t == T
                % In the last period, consume everything
                coptR(ik, t_index) = k * (1 + r_guess) + b_guess;
                koptR(ik, t_index) = 0;
                
                % Compute utility (labor supply is 0 in retirement)
                VR(ik, t_index) = utility(coptR(ik, t_index), 0, mu, sigma);
            else
                % For other retirement periods, solve for optimal savings
                max_val = -1e10;
                opt_c = 0;
                opt_k = 0;
                
                for ik_next = 1:nk
                    k_next = kgrid(ik_next);
                    c = k * (1 + r_guess) + b_guess - k_next;
                    
                    if c > 0 % Check for positive consumption
                        next_t_index = t_index + 1;  % Index for the next period
                        val = utility(c, 0, mu, sigma) + beta * VR(ik_next, next_t_index);
                        
                        if val > max_val
                            max_val = val;
                            opt_c = c;
                            opt_k = k_next;
                        end
                    end
                end
                
                coptR(ik, t_index) = opt_c;
                koptR(ik, t_index) = opt_k;
                VR(ik, t_index) = max_val;
            end
        end
    end
    
    % Solve for working years (backward from R-1 to 1)
    for t = (R-1):-1:1
        for ik = 1:nk
            for iz = 1:nz
                k = kgrid(ik);
                z = zgrid(iz);
                
                max_val = -1e10;
                opt_c = 0;
                opt_k = 0;
                opt_l = 0;
                
                for ik_next = 1:nk
                    k_next = kgrid(ik_next);
                    
                    % Calculate labor supply using FOC (as shown in the algorithm)
                    l = (mu*w*exp(z)*lambda(t)*(1-tau) - (1-mu)*(k*(1+r_guess) - k_next)) / (w*exp(z)*lambda(t)*(1-tau));
                    
                    % Ensure labor supply is in the correct range [0,1]
                    l = min(max(l, 0), 1);
                    
                    % Calculate consumption
                    c = k*(1+r_guess) + w*exp(z)*lambda(t)*l*(1-tau) - k_next;
                    
                    if c > 0
                        % Calculate expected value for next period
                        expected_val = 0;
                        
                        if t == R-1
                            % Transition to retirement in the next period
                            for ik_r = 1:nk
                                if abs(kgrid(ik_r) - k_next) < 1e-10
                                    expected_val = VR(ik_r, 1);
                                    break;
                                elseif kgrid(ik_r) > k_next
                                    % Linear interpolation
                                    weight = (k_next - kgrid(ik_r-1)) / (kgrid(ik_r) - kgrid(ik_r-1));
                                    expected_val = VR(ik_r-1, 1) * (1-weight) + VR(ik_r, 1) * weight;
                                    break;
                                end
                            end
                        else
                            % Expected value over possible productivity shocks
                            for iz_next = 1:nz
                                prob = P(iz, iz_next);
                                
                                % Linear interpolation for k_next
                                if k_next <= kgrid(1)
                                    expected_val = expected_val + prob * V(1, iz_next, t+1);
                                elseif k_next >= kgrid(end)
                                    expected_val = expected_val + prob * V(end, iz_next, t+1);
                                else
                                    % Find nearest grid points
                                    ik_low = find(kgrid <= k_next, 1, 'last');
                                    ik_high = find(kgrid >= k_next, 1, 'first');
                                    
                                    if ik_low == ik_high
                                        expected_val = expected_val + prob * V(ik_low, iz_next, t+1);
                                    else
                                        % Linear interpolation
                                        weight = (k_next - kgrid(ik_low)) / (kgrid(ik_high) - kgrid(ik_low));
                                        expected_val = expected_val + prob * ...
                                            (V(ik_low, iz_next, t+1) * (1-weight) + ...
                                             V(ik_high, iz_next, t+1) * weight);
                                    end
                                end
                            end
                        end
                        
                        val = utility(c, l, mu, sigma) + beta * expected_val;
                        
                        if val > max_val
                            max_val = val;
                            opt_c = c;
                            opt_k = k_next;
                            opt_l = l;
                        end
                    end
                end
                
                copt(ik, iz, t) = opt_c;
                kopt(ik, iz, t) = opt_k;
                lopt(ik, iz, t) = opt_l;
                V(ik, iz, t) = max_val;
            end
        end
    end
    
    %% Compute invariant distribution 
    % Initialize distributions
    Gamma = zeros(nk, nz, R-1);     % Distribution for working ages (1 to R-1)
    GammaR = zeros(nk, T-R+1);      % Distribution for retirement ages (R to T)
    
    Gamma(1, :, 1) = Pi; % Use the loaded invariant distribution
    
    % Forward iteration for ages 1 to T
    for t = 1:T-1
        if t < R
            % Working age
            for ik = 1:nk
                for iz = 1:nz
                    mass = Gamma(ik, iz, t);
                    if mass > 0
                        k_next = kopt(ik, iz, t);
                        
                        % Find location of k_next in grid
                        if k_next <= kgrid(1)
                            j_lo = 1;
                            weight = 0;
                        elseif k_next >= kgrid(end)
                            j_lo = nk - 1;
                            weight = 1;
                        else
                            j_lo = find(kgrid <= k_next, 1, 'last');
                            weight = (k_next - kgrid(j_lo)) / (kgrid(j_lo+1) - kgrid(j_lo));
                        end
                        
                        if t < R-1
                            for iz_next = 1:nz
                                Gamma(j_lo, iz_next, t+1) = Gamma(j_lo, iz_next, t+1) + ...
                                    mass * (1-weight) * P(iz, iz_next);
                                Gamma(j_lo+1, iz_next, t+1) = Gamma(j_lo+1, iz_next, t+1) + ...
                                    mass * weight * P(iz, iz_next);
                            end
                        else
                            % Working age -> retirement transition
                            GammaR(j_lo, 1) = GammaR(j_lo, 1) + mass * (1-weight);
                            GammaR(j_lo+1, 1) = GammaR(j_lo+1, 1) + mass * weight;
                        end
                    end
                end
            end
        else
            % Retirement age
            for ik = 1:nk
                mass = GammaR(ik, t-R+1);
                if mass > 0
                    t_index = t - R + 1;  % Index for retirement arrays
                    next_t_index = t_index + 1;  % Index for next period
                    
                    k_next = koptR(ik, t_index);
                    
                    % Find location of k_next in grid
                    if k_next <= kgrid(1)
                        j_lo = 1;
                        weight = 0;
                    elseif k_next >= kgrid(end)
                        j_lo = nk - 1;
                        weight = 1;
                    else
                        j_lo = find(kgrid <= k_next, 1, 'last');
                        weight = (k_next - kgrid(j_lo)) / (kgrid(j_lo+1) - kgrid(j_lo));
                    end
                    
                    % Distribute mass for next period
                    if t < T
                        GammaR(j_lo, next_t_index) = GammaR(j_lo, next_t_index) + mass * (1-weight);
                        GammaR(j_lo+1, next_t_index) = GammaR(j_lo+1, next_t_index) + mass * weight;
                    end
                end
            end
        end
    end
    
    % Adjust for population growth
    for t = 1:R-1
        Gamma(:, :, t) = Gamma(:, :, t) * adj(t);
    end
    
    for t = 1:T-R+1
        GammaR(:, t) = GammaR(:, t) * adj(t+R-1);
    end
    
    total_mass = sum(sum(sum(Gamma))) + sum(sum(GammaR));
    Gamma = Gamma / total_mass;
    GammaR = GammaR / total_mass;
    
    %% Compute aggregate K and L 
    K = 0;
    L = 0;
    
    for t = 1:R-1
        for iz = 1:nz
            for ik = 1:nk
                K = K + Gamma(ik, iz, t) * kgrid(ik);
            end
        end
    end
    
    for t = 1:T-R+1
        for ik = 1:nk
            K = K + GammaR(ik, t) * kgrid(ik);
        end
    end
    
    for t = 1:R-1
        for iz = 1:nz
            for ik = 1:nk
                L = L + lambda(t) * exp(zgrid(iz)) * Gamma(ik, iz, t) * lopt(ik, iz, t);
            end
        end
    end
    
    % Compute new interest rate and wage
    r_new = alpha * (K/L)^(alpha-1) - delta;
    w_new = (1-alpha) * (K/L)^alpha;
    
    % No pension benefit with tau = 0
    b_new = 0;
    
    %% Check convergence and update
    diff = abs(r_new - r_guess);
    
    % Update with weighted avg to improve convergence
    r_guess = 0.7 * r_guess + 0.3 * r_new;
    
    fprintf('Iteration %d: r = %.6f, diff = %.6f\n', iter, r_guess, diff);
end

%% Store results without Social Security
r_without_SS = r_guess;
b_without_SS = b_guess;
w_without_SS = w_new;
K_without_SS = K;
L_without_SS = L;
Y_without_SS = K^alpha * L^(1-alpha);
Gamma_without_SS = Gamma;
GammaR_without_SS = GammaR;
copt_without_SS = copt;
kopt_without_SS = kopt;
lopt_without_SS = lopt;
coptR_without_SS = coptR;
koptR_without_SS = koptR;
V_without_SS = V;
VR_without_SS = VR;

% Compute welfare of newborn without Social Security
V_o_without_SS = compute_newborn_welfare(V_without_SS, Pi);

fprintf('\nResults without Social Security (tau = 0), beta=0.99:\n');
fprintf('Interest rate: %.4f\n', r_without_SS);
fprintf('Wage rate: %.4f\n', w_without_SS);
fprintf('Pension benefit: %.4f\n', b_without_SS);
fprintf('Aggregate capital: %.4f\n', K_without_SS);
fprintf('Aggregate labor: %.4f\n', L_without_SS);
fprintf('Output: %.4f\n', Y_without_SS);
fprintf('Welfare of newborn: %.4f\n', V_o_without_SS);

%% Comparison of results with and without Social Security
fprintf('\nComparison of Results with Beta = %.2f:\n', beta);
fprintf('%-20s %-15s %-15s %-15s\n', 'Variable', 'With SS', 'Without SS', 'Change (%)');
fprintf('%-20s %-15.4f %-15.4f %-15.2f\n', 'Interest rate', r_with_SS, r_without_SS, (r_without_SS/r_with_SS-1)*100);
fprintf('%-20s %-15.4f %-15.4f %-15.2f\n', 'Aggregate capital', K_with_SS, K_without_SS, (K_without_SS/K_with_SS-1)*100);
fprintf('%-20s %-15.4f %-15.4f %-15.2f\n', 'Aggregate labor', L_with_SS, L_without_SS, (L_without_SS/L_with_SS-1)*100);
fprintf('%-20s %-15.4f %-15.4f %-15.2f\n', 'Wage rate', w_with_SS, w_without_SS, (w_without_SS/w_with_SS-1)*100);
fprintf('%-20s %-15.4f %-15.4f %-15.2f\n', 'Output', Y_with_SS, Y_without_SS, (Y_without_SS/Y_with_SS-1)*100);
fprintf('%-20s %-15.4f %-15.4f %-15.2f\n', 'Newborn welfare', V_o_with_SS, V_o_without_SS, (V_o_without_SS/V_o_with_SS-1)*100);

if V_o_without_SS > V_o_with_SS
    fprintf('\nNewborn generations prefer to start in a steady state WITHOUT Social Security.\n');
else
    fprintf('\nNewborn generations prefer to start in a steady state WITH Social Security.\n');
end

%% Plot wealth and labor supply profiles by age
figure;

% Compute average capital by age
avg_k_with_SS = compute_avg_k_by_age(Gamma_with_SS, GammaR_with_SS, kgrid, T, R);
avg_k_without_SS = compute_avg_k_by_age(Gamma_without_SS, GammaR_without_SS, kgrid, T, R);

subplot(2,1,1);
plot(1:T, avg_k_with_SS, 'b-', 'LineWidth', 2);
hold on;
plot(1:T, avg_k_without_SS, 'r--', 'LineWidth', 2);
xlabel('Age');
ylabel('Capital');
title('Average Capital by Age');
legend('With Social Security', 'Without Social Security');
grid on;
xline(R, 'k--', 'Retirement Age');

% Compute average labor supply by age
avg_l_with_SS = compute_avg_l_by_age(Gamma_with_SS, lopt_with_SS, R);
avg_l_without_SS = compute_avg_l_by_age(Gamma_without_SS, lopt_without_SS, R);

subplot(2,1,2);
plot(1:R-1, avg_l_with_SS, 'b-', 'LineWidth', 2);
hold on;
plot(1:R-1, avg_l_without_SS, 'r--', 'LineWidth', 2);
xlabel('Age');
ylabel('Labor Supply');
title('Average Labor Supply by Age');
legend('With Social Security', 'Without Social Security');
grid on;

saveas(gcf, 'wealth_labor_profiles99.png');

%% Results table as required in the homework
results_table = table;
results_table.Variables = [K_with_SS, K_without_SS; 
                          L_with_SS, L_without_SS;
                          w_with_SS, w_without_SS;
                          r_with_SS, r_without_SS;
                          b_with_SS, b_without_SS;
                          V_o_with_SS, V_o_without_SS];
results_table.Properties.RowNames = {'capital K', 'labor L', 'wage w', 'interest r', 'pension benefit b', 'newborn welfare V^o'};
results_table.Properties.VariableNames = {'with_SS', 'without_SS'};

% Display the table
disp(results_table);
% Utility function
function u = utility(c, l, mu, sigma)
    if c <= 0
        u = -1e10;
        return;
    end
    
    % Utility function as specified in the model
    u = ((c^mu * (1-l)^(1-mu))^(1-sigma) - 1) / (1-sigma);
end

% Function to compute expected welfare of a newborn
function V_o = compute_newborn_welfare(V, Pi)
    
    % Get the value at age 1, k=0, weighted by productivity distribution
    V_o = sum(V(1, :, 1) .* Pi); 
end

% Function to compute average capital by age
function avg_k = compute_avg_k_by_age(Gamma, GammaR, kgrid, T, R)
    avg_k = zeros(1, T);
    
    % Working ages
    for t = 1:R-1
        k_sum = 0;
        mass_sum = 0;
        
        for ik = 1:length(kgrid)
            for iz = 1:size(Gamma, 2)
                k_sum = k_sum + kgrid(ik) * Gamma(ik, iz, t);
                mass_sum = mass_sum + Gamma(ik, iz, t);
            end
        end
        
        if mass_sum > 0
            avg_k(t) = k_sum / mass_sum;
        end
    end
    
    % Retirement ages
    for t = R:T
        t_index = t - R + 1;  % Index for retirement arrays
        k_sum = 0;
        mass_sum = 0;
        
        for ik = 1:length(kgrid)
            k_sum = k_sum + kgrid(ik) * GammaR(ik, t_index);
            mass_sum = mass_sum + GammaR(ik, t_index);
        end
        
        if mass_sum > 0
            avg_k(t) = k_sum / mass_sum;
        end
    end
end

% Function to compute average labor supply by age
function avg_l = compute_avg_l_by_age(Gamma, lopt, R)
    avg_l = zeros(1, R-1);
    
    for t = 1:R-1
        l_sum = 0;
        mass_sum = 0;
        
        for ik = 1:size(Gamma, 1)
            for iz = 1:size(Gamma, 2)
                l_sum = l_sum + lopt(ik, iz, t) * Gamma(ik, iz, t);
                mass_sum = mass_sum + Gamma(ik, iz, t);
            end
        end
        
        if mass_sum > 0
            avg_l(t) = l_sum / mass_sum;
        end
    end
end
