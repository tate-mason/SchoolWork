% Parameters
beta = 0.95;
cl = exp(0.98);
ch = exp(1.02);
Pi_L = 0.5;  % Probability of low state
Pi_H = 0.5; % Probability of high state
R = 0;

% Define parameters based on given values
alpha_values = [1, 0.5, -1];
rho_values = [1, 0.5, -1];

% Tolerance level
tol = 1e-8;
max_iter = 1000;

% Function to compute f(U0)
f_U0 = @(U0, alpha, rho) ((Pi_L * ((1 - beta) * cl^rho + beta * U0^rho)^(alpha/rho) + ...
                           Pi_H * ((1 - beta) * ch^rho + beta * U0^rho)^(alpha/rho))^(1/alpha)) - R;

% Create variables to store results
alpha_results = zeros(length(alpha_values), 3);
rho_results = zeros(length(rho_values), 3);

% Iterate to make alpha table
for i = 1:length(alpha_values)
    alpha = alpha_values(i);
    rho = 1; % Keep rho fixed
    
    % Initial guess
    U0_old = 1;
    iter = 0;
    
    while true
        % Compute new U0
        U0_new = f_U0(U0_old, alpha, rho);
        
        % Check convergence
        if abs(U0_new - U0_old) < tol || iter > max_iter
            break;
        end
        
        % Update
        U0_old = U0_new;
        iter = iter + 1;
    end
    
    % Save result
    eta = U0_old;
    alpha_results(i, :) = [alpha, eta, iter];
end

% Iterate for rho table
for j = 1:length(rho_values)
    rho = rho_values(j);
    alpha = 1; % Keep alpha fixed
    
    % Initial guess
    U0_old = 1;
    iter = 0;
    
    while true
        % Compute new U0
        U0_new = f_U0(U0_old, alpha, rho);
        
        % Check convergence
        if abs(U0_new - U0_old) < tol || iter > max_iter
            break;
        end
        
        % Update
        U0_old = U0_new;
        iter = iter + 1;
    end
    
    % Save result
    eta = U0_old;
    rho_results(j, :) = [rho, eta, iter];
end

% Create tables
alpha_table = array2table(alpha_results, 'VariableNames', {'Alpha', 'Eta', 'Iterations'});
rho_table = array2table(rho_results, 'VariableNames', {'Rho', 'Eta', 'Iterations'});

% Display tables
disp('Results for different Alpha values:');
disp(alpha_table);

disp('Results for different Rho values:');
disp(rho_table);
