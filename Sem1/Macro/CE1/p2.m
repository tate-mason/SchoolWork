%%%%%%%%%%%%%%
% Tate Mason %
%%%%%%%%%%%%%%

%{
Question 2: Expenditure Shares
    a: find expenditure share of each category
    b: changing shares with c-bar
    c: taking NIPA data to the model
    d: tinkering with the model and solving for
       ca-bar and cs-bar
    e: luxury or necessity?
    f: simulated path for expenditure shares
%}

%%%%%%%%%%%%%%%%%%%
% Part A          %
%%%%%%%%%%%%%%%%%%%

% Define parameters
omega_a = 0.3;  % weight for agriculture
omega_m = 0.3;  % weight for manufacturing
omega_s = 0.4;  % weight for services

p_a = 1;  % price for agriculture
p_m = 1;  % price for manufacturing
p_s = 1;  % price for services

c_bar_a = 0.5;  % constant for agriculture
c_bar_m = 0;    % constant for manufacturing
c_bar_s = 1;    % constant for services

C = 100;  % total expenditure

% Define the system of first-order conditions
% Using symbolic variables for c_a, c_m, and c_s
syms c_a c_m c_s lambda

% Define the utility function's partial derivatives (FOCs)
FOC_a = omega_a / (c_a + c_bar_a) - lambda * p_a == 0;
FOC_m = omega_m / (c_m + c_bar_m) - lambda * p_m == 0;
FOC_s = omega_s / (c_s + c_bar_s) - lambda * p_s == 0;

% Define the budget constraint
budget_eq = p_a * c_a + p_m * c_m + p_s * c_s == C;

% Solve the system of equations for c_a, c_m, c_s, and lambda
sol = solve([FOC_a, FOC_m, FOC_s, budget_eq], [c_a, c_m, c_s, lambda]);

% Extract the solution for c_a, c_m, and c_s
c_a_sol = double(sol.c_a);
c_m_sol = double(sol.c_m);
c_s_sol = double(sol.c_s);

% Calculate the expenditure shares
s_a = p_a * c_a_sol / C;
s_m = p_m * c_m_sol / C;
s_s = p_s * c_s_sol / C;

% Display the results
fprintf('Optimal consumption for agriculture (c_a): %.2f\n', c_a_sol);
fprintf('Optimal consumption for manufacturing (c_m): %.2f\n', c_m_sol);
fprintf('Optimal consumption for services (c_s): %.2f\n', c_s_sol);

fprintf('Expenditure share for agriculture (s_a): %.2f\n', s_a);
fprintf('Expenditure share for manufacturing (s_m): %.2f\n', s_m);
fprintf('Expenditure share for services (s_s): %.2f\n', s_s);

%%%%%%%%%%%%%%%%%%%
% Part B          %
%%%%%%%%%%%%%%%%%%%

% Define parameters
omega_a = 0.3;  % weight for agriculture
omega_m = 0.3;  % weight for manufacturing
omega_s = 0.4;  % weight for services

p_a = 1;  % price for agriculture
p_m = 1;  % price for manufacturing
p_s = 1;  % price for services

% Set specific values for c_bar as per the question
c_bar_a = -0.5;  % c_bar_a < 0
c_bar_m = 0;     % c_bar_m = 0
c_bar_s = 1;     % c_bar_s > 0

% Define a range of total expenditures C
C_values = linspace(10, 500, 100);  % Varying C from 10 to 500

% Preallocate arrays to store expenditure shares
s_a_vals = zeros(size(C_values));
s_m_vals = zeros(size(C_values));
s_s_vals = zeros(size(C_values));

% Loop over different values of C
for i = 1:length(C_values)
    C = C_values(i);
    
    % Define the system of first-order conditions
    syms c_a c_m c_s lambda

    % Define the utility function's partial derivatives (FOCs)
    FOC_a = omega_a / (c_a + c_bar_a) - lambda * p_a == 0;
    FOC_m = omega_m / (c_m + c_bar_m) - lambda * p_m == 0;
    FOC_s = omega_s / (c_s + c_bar_s) - lambda * p_s == 0;
    
    % Define the budget constraint
    budget_eq = p_a * c_a + p_m * c_m + p_s * c_s == C;
    
    % Solve the system of equations
    sol = solve([FOC_a, FOC_m, FOC_s, budget_eq], [c_a, c_m, c_s, lambda]);
    
    % Extract the solution for c_a, c_m, and c_s
    c_a_sol = double(sol.c_a);
    c_m_sol = double(sol.c_m);
    c_s_sol = double(sol.c_s);
    
    % Calculate the expenditure shares
    s_a_vals(i) = p_a * c_a_sol / C;
    s_m_vals(i) = p_m * c_m_sol / C;
    s_s_vals(i) = p_s * c_s_sol / C;
end

% Plot the results
figure;
plot(C_values, s_a_vals, 'r', 'DisplayName', 'Agriculture (s_a)');
hold on;
plot(C_values, s_m_vals, 'g', 'DisplayName', 'Manufacturing (s_m)');
plot(C_values, s_s_vals, 'b', 'DisplayName', 'Services (s_s)');
xlabel('Total Expenditure (C)');
ylabel('Expenditure Shares');
title('Expenditure Shares vs Total Expenditure');
legend('show');
grid on;
hold off;

%%%%%%%%%%%%%%%%%%%
% Part C          %
%%%%%%%%%%%%%%%%%%%
T = readtable('2.4.5.xlsx');
T2 = readtable('3.10.5.xlsx');

year = T.year;
years = str2double(year);
personal_consumption = T.PersonalConsumptionExpenditures; 
government_consumption = T2.GovernmentConsumptionExpenditures1; 
food_beverages = T.FoodAndBeveragesPurchasedForOff_premisesConsumption; 
durable_goods = T.DurableGoods; 
nondurable_goods = T.NondurableGoods; 
services = T.Services; 

% Compute total consumption
C = personal_consumption + government_consumption;

% Compute expenditure for each category
agriculture = food_beverages;
manufacturing = durable_goods + (nondurable_goods - food_beverages);
services = services + government_consumption;

% Compute expenditure shares
s_a = agriculture ./ C;
s_m = manufacturing ./ C;
s_s = services ./ C;

% Plot expenditure shares
figure;
plot(years, s_a, 'r', years, s_m, 'g', years, s_s, 'b');
legend('Agriculture', 'Manufacturing', 'Services');
xlabel('Year');
ylabel('Expenditure Share');
title('Expenditure Shares Over Time');
grid on;

% Display 2019 shares
disp(['2019 Shares: Agriculture = ', num2str(s_a(end)), ...
      ', Manufacturing = ', num2str(s_m(end)), ...
      ', Services = ', num2str(s_s(end))]);

%%%%%%%%%%%%%%%%%%%
% Part D          %
%%%%%%%%%%%%%%%%%%%

% 2019 Expenditure shares (set based on actual data from 2019)
omega_a = s_a(end);
omega_m = s_m(end);
omega_s = s_s(end);

% 1947 Expenditure shares (set based on actual data from 1947)
s_a_1947 = s_a(1,:);
s_m_1947 = s_m(1,:);
s_s_1947 = s_s(1,:);

% Prices (all prices are set to 1)
p_a = 1;
p_m = 1;
p_s = 1;

% Total expenditure in 1947 (set to any fixed value, e.g., C = 100)
C_1947 = 100;

% Define the objective function for fminsearch
objective_function = @(params) calculate_error(params, omega_a, omega_m, omega_s, p_a, p_m, p_s, C_1947, s_a_1947, s_m_1947, s_s_1947);

% Initial guess for c_bar_a and c_bar_s
initial_guess = [-1, 1];  % Initial guess for c_bar_a < 0 and c_bar_s > 0

% Use fminsearch to find the best values of c_bar_a and c_bar_s
optimal_params = fminsearch(objective_function, initial_guess);

% Extract the optimal values of c_bar_a and c_bar_s
c_bar_a_opt = optimal_params(1);
c_bar_s_opt = optimal_params(2);

% Display the results
fprintf('Optimal c_bar_a: %.4f\n', c_bar_a_opt);
fprintf('Optimal c_bar_s: %.4f\n', c_bar_s_opt);

% Function to calculate the squared error between model shares and actual shares
function error_value = calculate_error(params, omega_a, omega_m, omega_s, p_a, p_m, p_s, C, s_a_1947, s_m_1947, s_s_1947)
    c_bar_a = params(1);
    c_bar_s = params(2);
    
    % Calculate the model expenditure shares
    model_shares = calculate_shares(c_bar_a, c_bar_s, omega_a, omega_m, omega_s, p_a, p_m, p_s, C);
    
    % Calculate the squared difference between model shares and 1947 shares
    error_value = sum((model_shares - [s_a_1947, s_m_1947, s_s_1947]).^2);
end

% Function to calculate the expenditure shares given c_bar_a and c_bar_s
function shares = calculate_shares(c_bar_a, c_bar_s, omega_a, omega_m, omega_s, p_a, p_m, p_s, C)
    % Set c_bar_m = 0 as per the problem statement
    c_bar_m = 0;
    
    % Define symbolic variables
    syms c_a c_m c_s lambda

    % First-order conditions (FOCs)
    FOC_a = omega_a / (c_a + c_bar_a) - lambda * p_a == 0;
    FOC_m = omega_m / (c_m + c_bar_m) - lambda * p_m == 0;
    FOC_s = omega_s / (c_s + c_bar_s) - lambda * p_s == 0;

    % Budget constraint
    budget_eq = p_a * c_a + p_m * c_m + p_s * c_s == C;

    % Solve the system of equations
    sol = solve([FOC_a, FOC_m, FOC_s, budget_eq], [c_a, c_m, c_s, lambda]);

    % Extract the consumption values
    c_a_sol = double(sol.c_a);
    c_m_sol = double(sol.c_m);
    c_s_sol = double(sol.c_s);

    % Calculate the expenditure shares
    s_a = p_a * c_a_sol / C;
    s_m = p_m * c_m_sol / C;
    s_s = p_s * c_s_sol / C;

    % Return the shares as a vector
    shares = [s_a, s_m, s_s];
end

%%%%%%%%%%%%%%%%%%%
% Part F          %
%%%%%%%%%%%%%%%%%%%

% Parameters
omega_a = s_a(end); 
omega_m = s_m(end); 
omega_s = s_s(end); 
c_bar_a = -11.0415; 
c_bar_s = 63.8705;  

% Generate a series of C values (adjust the range as needed)
C_values = linspace(min(C), max(C), 73);

% Calculate shares for each C value
shares_a = zeros(size(C_values));
shares_m = zeros(size(C_values));
shares_s = zeros(size(C_values));

for i = 1:length(C_values)
    C = C_values(i);
    shares_a(i) = omega_a * (1 + c_bar_a / C);
    shares_m(i) = omega_m;
    shares_s(i) = omega_s * (1 + c_bar_s / C);
end

% Plot the results
figure;
hold on;

% Plot simulated shares
plot(years, shares_a, 'r-', 'DisplayName', 'Agriculture (Model)');
plot(years, shares_m, 'g-', 'DisplayName', 'Manufacturing (Model)');
plot(years, shares_s, 'b-', 'DisplayName', 'Services (Model)');

plot(years, s_a, 'm-', 'DisplayName', 'Agriculture (Data)');
plot(years, s_m, 'y-', 'DisplayName', 'Manufacturing (Data)');
plot(years, s_s, 'c-', 'DisplayName', 'Services (Data)');

xlabel('Time');
ylabel('Expenditure Shares');
title('Expenditure Shares: Model vs Data');
legend('show');
grid on;

hold off;