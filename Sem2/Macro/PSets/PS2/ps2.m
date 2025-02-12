% Define parameters
beta = 0.95;
cl = exp(0.98);
ch = exp(1.02);
Pi_L = 0.5;  % Probability for low state
Pi_H = 1 - Pi_L; % Probability for high state
R = 0;  % Adjust R if necessary

% Define parameter combinations
alpha_values = [1, 0.5, -1];
rho_values = [1, 0.5, -1];

% Tolerance level
tol = 1e-8;
max_iter = 1000; % Max iterations to avoid infinite loops

% Function to compute f(U0)
f_U0 = @(U0, alpha, rho) ((Pi_L * ((1 - beta) * cl^rho + beta * U0^rho)^(alpha/rho) + ...
                           Pi_H * ((1 - beta) * ch^rho + beta * U0^rho)^(alpha/rho))^(1/alpha)) - R;

% Initialize results storage
alpha_results = zeros(length(alpha_values), 4); % Columns: Alpha, Eta, U0, Iterations
rho_results = zeros(length(rho_values), 4); % Columns: Rho, Eta, U0, Iterations

% Iterate over alpha values
for i = 1:length(alpha_values)
    alpha = alpha_values(i);
    rho = 1; % Fix rho for this table
    
    % Initial guess
    U0_old = 1;
    iter = 0;
    
    while true
        % Compute new U0
        U0_new = f_U0(U0_old, alpha, rho);
        
        % Check for convergence
        if abs(U0_new - U0_old) < tol || iter > max_iter
            break;
        end
        
        % Update for next iteration
        U0_old = U0_new;
        iter = iter + 1;
    end
    
    % Store result
    eta = U0_new;
    alpha_results(i, :) = [alpha, eta, U0_new, iter];
end

% Iterate over rho values
for j = 1:length(rho_values)
    rho = rho_values(j);
    alpha = 1; % Fix alpha for this table
    
    % Initial guess
    U0_old = 1;
    iter = 0;
    
    while true
        % Compute new U0
        U0_new = f_U0(U0_old, alpha, rho);
        
        % Check for convergence
        if abs(U0_new - U0_old) < tol || iter > max_iter
            break;
        end
        
        % Update for next iteration
        U0_old = U0_new;
        iter = iter + 1;
    end
    
    % Store result
    eta = U0_new;
    rho_results(j, :) = [rho, eta, U0_new, iter];
end

% Create tables
alpha_table = array2table(alpha_results, 'VariableNames', {'Alpha', 'Eta', 'U0', 'Iterations'});
rho_table = array2table(rho_results, 'VariableNames', {'Rho', 'Eta', 'U0', 'Iterations'});

% Display tables
disp('Results for different Alpha values:');
disp(alpha_table);

disp('Results for different Rho values:');
disp(rho_table);
