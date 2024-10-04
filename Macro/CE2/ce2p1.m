% ECON 8040 - Computational Exercise 2 - Problem 1

% Define parameters
beta = 0.95;
sigma = 2;
alpha = 0.4;
delta = 0.1;

% Calculate steady state capital
k_ss = ((1/beta - 1 + delta) / alpha)^(1/(alpha-1));

% (a) Solve for allocation when k1 = k_ss
k1 = k_ss;

% Define the system of equations
f = @(x) [
    x(1) + x(3) - k1^alpha - (1-delta)*k1;
    x(2) - x(3)^alpha - (1-delta)*x(3);
    x(1)^(-sigma) - beta * x(2)^(-sigma) * (1 - delta + alpha*x(3)^(alpha-1))
];

% Initial guess
x0 = [k_ss, k_ss, k_ss];

% Solve using Newton's method
options = optimoptions('fsolve', 'Display', 'off');
solution = fsolve(f, x0, options);

c1 = solution(1);
c2 = solution(2);
k2 = solution(3);

fprintf('(a) Solution for k1 = k_ss:\n');
fprintf('c1 = %.4f\n', c1);
fprintf('c2 = %.4f\n', c2);
fprintf('k2 = %.4f\n\n', k2);

% (b) Solve for different initial capital values
K = [0.5*k_ss, 0.75*k_ss, k_ss, 1.5*k_ss, 2*k_ss];
results = zeros(length(K), 4);

for i = 1:length(K)
    k1 = K(i);
    
    % Update the first equation in the system
    f = @(x) [
        x(1) + x(3) - k1^alpha - (1-delta)*k1;
        x(2) - x(3)^alpha - (1-delta)*x(3);
        x(1)^(-sigma) - beta * x(2)^(-sigma) * (1 - delta + alpha*x(3)^(alpha-1))
    ];
    
    % Solve using Newton's method
    solution = fsolve(f, x0, options);
    
    c1 = solution(1);
    c2 = solution(2);
    k2 = solution(3);
    
    % Calculate w(k1)
    w = (c1^(1-sigma))/(1-sigma) + beta * (c2^(1-sigma))/(1-sigma);
    
    results(i,:) = [k1, c1, c2, w];
end

% Plot w(k1)
hold on;
plot(results(:,1), results(:,4), 'b-o');
title('Value Function w(k1)');
xlabel('k1');
ylabel('w(k1)');
grid on;

% Display results
fprintf('(b) Results for different k1 values:\n');
fprintf('   k1       c1       c2       w(k1)\n');
fprintf('%7.4f  %7.4f  %7.4f  %7.4f\n', results');
