%% Computational Exercise 2 - ECON 8040: Problem 1b
% Define parameters
beta = 0.95;
sigma = 2;
alpha = 0.4;
delta = 0.1;

% Calculate steady state capital
k_ss = ((1/beta - 1 + delta) / alpha)^(1/(alpha-1));

% Define the system of equations
f = @(x, k1, alpha, delta, beta, sigma) [
    x(1)+x(3)-k1^alpha - (1-delta)*k1;
    x(2)-x(3)^alpha-(1-delta)*x(3);
    x(1)^(-sigma)-beta*x(2)^(-sigma)*(1-delta+alpha*x(3)^(alpha-1))
];

% Define Jacobian Matrix 
J = @(x, alpha, delta, beta, sigma) [
    1, 0, 1;
    0, 1, -alpha*x(3)^(alpha-1)-(1-delta);
    -sigma*x(1)^(-sigma-1), sigma*beta*x(2)^(-sigma-1)*(1-delta+alpha*x(3)^(alpha-1)), ...
    -beta*x(2)^(-sigma)*alpha*(alpha-1)*x(3)^(alpha-2)
];

% Grid for k1:
k1_grid = [0.5, 0.75, 1, 1.5, 2] * k_ss;
n = length(k1_grid);
results = zeros(n, 4);
w = zeros(n, 1);

% Solving
for i=1:n
  k1 = k1_grid(i);
  x = newton(k1, f, J, alpha, delta, beta, sigma);
  results (i, :) = [k1, x(1), x(2), x(3)];

  c1 = x(1);
  c2 = x(2);
  w(i) = c1^(1-sigma)/1-sigma + beta*c2^(1-sigma)/(1-sigma);
end

% Results
disp('Results');
disp('   k1   c1   c2   k2   w(k1)');
disp([results, w]);

% Plot
figure;
plot(k1_grid, w, 'o-');
title('Value Function');
xlabel('k1');
ylabel('w(k1)');
grid on;

% Newton's Method
function x = newton(k1, f, J, alpha, delta, beta, sigma)
    % Set initial guess and tolerance
    x0 = [k1^alpha/2; k1^alpha/2; k1];  
    tol = 1e-6;  
    max_iter = 1000;  
    
    % Perform Newton's method
    x = x0;
    for i = 1:max_iter
        fx = f(x, k1, alpha, delta, beta, sigma);
        if norm(fx) < tol
            break;
        end
        x = x - J(x, alpha, delta, beta, sigma) \ fx;
    end
end
