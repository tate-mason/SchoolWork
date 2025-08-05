%% Computational Exercise 2 - ECON 8040: Problem 1a
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

% Call the newton function with k_ss
x_ss= newton(k_ss, f, J, alpha, delta, beta, sigma);

% Output results
fprintf('Solution for k1 = k_ss:\n');
fprintf('c1 = %.4f\n', x_ss(1));
fprintf('c2 = %.4f\n', x_ss(2));
fprintf('k2 = %.4f\n', x_ss(3));

% Define Newton Function
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
  
    % Variable Definition
    c1 = x(1);
    c2 = x(2);
    k2 = x(3);
end
