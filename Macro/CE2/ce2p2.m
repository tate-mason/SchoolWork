%% Computational Exercise 2 - ECON 8040: Problem 2
% Set Workspace
clear;
clc;

% Parameters
sigma = 2;      
alpha = 1/3;     
delta = 0.0767;      
beta = 0.9804;       
gamma = 0.02;       
eta = 0.01;          
A = 0.5226;                

tol = 1e-6;
% Steady-state capital
kss = 1; % This is normalized as per the problem

% Create grid for capital (100 points between 0.1kss and 2kss)
k_min = 0.1 * kss;
k_max = 2 * kss;
n = 100;
kgrid = linspace(k_min, k_max, n);

% Initialize value function and policy function
V = zeros(n, 1);
Tv = V;
policy_k = zeros(n, 1);

ucgrid = zeros(n,n);
for i = 1:n 
    for j = 1:n
        c = A*kgrid(i)^alpha + (1-delta)*kgrid(i) - (1+eta)*(1+gamma)*kgrid(j);
        if c > 0
            ucgrid(i,j) = (c^(1-sigma))/(1-sigma) + beta*V(j);
        else 
            ucgrid(i,j) = -1e20;
        end
    end
end

disp(ucgrid);
% Value function iteration
Vgrid = zeros(n,n); % initialize matrix for showing how updating works
for i = 1:n
    Vgrid(i,:) = ucgrid(i,:) + (1+gamma)^(1-sigma)*beta*V';
    [vmax, kmax] = max(ucgrid(i,:) + beta*V');
    Tv(i) = vmax;
    g(i) = kgrid(kmax);
end

disp(Vgrid);
disp(Tv);
disp(g);

err1 = norm(V-Tv); % Euclidean norm
err2 = abs(max(V-Tv)); % maximum difference between adjacent values

%% enter value function iteration
V = Tv;
err = err1;
it = 0;
while err > tol && it < 500
    tic;
    for i = 1:n
        [vmax, kmax] = max(ucgrid(i,:) + beta*V');
        Tv(i) = vmax;
        g(i) = kgrid(kmax);
    end
    
    % check for convergence and update guess
    err = norm(V - Tv);
    V = Tv;
    it = it+1;

    % display error every 50 iterations
    if mod(it,50) == 0
        disp(strcat('Iteration=', num2str(it)));
        disp(strcat('Error=', num2str(err)));
    end
end

if it < 500
    disp(strcat('Converged at it=', num2str(it)));
    disp(strcat('Error=', num2str(err)));
else
    disp('Failed to converge');
end
toc;

diff = 1;
while diff > tol
    for i = 1:n
        k = kgrid(i);
        max_val = -inf;
        for j = 1:n
            k_next = kgrid(j);
            c = A * k^alpha + (1 - delta)*k - (1 + gamma)*(1+eta)*k_next;
            if c > 0
                value = (c^(1 - sigma))/(1 - sigma) + beta*V(j);
                if value > max_val
                    max_val = value;
                    policy_k(i) = k_next;
                end
            end
        end
        V_new(i) = max_val;
    end
    diff = max(abs(V_new - V));
    V = V_new;
end

% Simulation for 50 periods
T = 50;
k_path = zeros(T, 1);    % Capital over time
c_path = zeros(T, 1);    % Consumption over time
y_path = zeros(T, 1);    % Output over time

k_path(1) = 0.5 * kss;   % Initial capital

for t = 1:T
    k = k_path(t);
    % Find optimal k_next from policy function
    [~, idx] = min(abs(kgrid - k));
    k_next = policy_k(idx);
    
    % Calculate output and consumption
    y_path(t) = A * k^alpha;                        
    c_path(t) = y_path(t) + (1 - delta)*k - (1 + gamma)*(1+eta)*k_next; % Consumption at time t
    
    % Store next period's capital
    if t < T
        k_path(t+1) = k_next;
    end
end


% Calculate and print convergence metrics
k_ss_actual = k_path(end);
c_ss_actual = c_path(end);
y_ss_actual = y_path(end);

%% plot result
% Benchmark: we have analytical result for g(k) in full depreciation
gstar = ((A * alpha*beta)/((1+gamma)*(1+eta)))*kgrid.^alpha;
kstar = (A/((1 + gamma)*(1 + eta)-(1 - delta)))^(1 / (1 - alpha));

newcolors = [0.00 0.00 0.00
             0.00 0.19 0.29
             0.84 0.16 0.16
             0.00 0.00 0.00];

colororder(newcolors);
plot(kgrid(1,:), kgrid(1,:), '--');
hold on;
plot(kgrid(1,:), gstar, '-', 'LineWidth', 1.5);
plot(kgrid(1,:), g(1,:), '-','LineWidth', 1.5);
plot(kstar,kstar,'*');
%title('Policy Function, Full Depreciation');
xlabel('k');
ylabel('g(k)');
legend('', 'Analytical', 'VFI', '', 'Location', 'Northwest');
xlim([k_min, k_max]);
ylim([k_min, k_max]);
grid on;

% Policy Functions of capital, output, and consumption
figure;
subplot(3,1,1);
plot(1:T, k_path);
title('Capital');
xlabel('Time');
ylabel('Capital');

subplot(3,1,2);
plot(1:T, c_path);
title('Consumption');
xlabel('Time');
ylabel('Consumption');

subplot(3,1,3);
plot(1:T, y_path);
title('Output');
xlabel('Time');
ylabel('Output');
fprintf('Steady state capital: %.4f\n', k_ss_actual);
fprintf('Steady state consumption: %.4f\n', c_ss_actual);
fprintf('Steady state output: %.4f\n', y_ss_actual);
fprintf('K/Y ratio: %.4f\n', k_ss_actual / y_ss_actual);
fprintf('Investment rate: %.4f\n', ((1+gamma)*(1+eta) - (1-delta)) * k_ss_actual / y_ss_actual);
