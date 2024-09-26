%%%%%%%%%%%%%%
% Tate Mason %
%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%
% Part A          %
%%%%%%%%%%%%%%%%%%%

function newton()
    % Define the function and its derivative
    f = @(x) x^3 - 27;
    f_prime = @(x) 3*x^2;
    
    % Set initial guess and tolerance
    x0 = 0.1;  
    tol = 1e-6;  
    max_iter = 100;  
    
    % Perform Newton's method
    x = x0;
    for i = 1:max_iter
        fx = f(x);
        if abs(fx) < tol
            break;
        end
        x = x - fx / f_prime(x);
    end
    
    % Output results
    fprintf('Solution to Part A:\n');
    fprintf('Solution: x = %.8f\n', x);
    fprintf('Iterations: %d\n', i);
end

newton()

%%%%%%%%%%%%%%%%%%%
% Part B          %
%%%%%%%%%%%%%%%%%%%
function newtons_method_system()
    % Define the system of equations
    F = @(x) [x(1) + x(2) - x(1)*x(2) + 2;
              x(1)*exp(-x(2)) - 1];
    
    % Define the Jacobian matrix
    J = @(x) [1 - x(2), 1 - x(1);
              exp(-x(2)), -x(1)*exp(-x(2))];
    
    % Initial guess
    x0 = [0.1; 0.1];
    
    % Tolerance and maximum iterations
    tol = 1e-6;
    max_iter = 100;
    
    % Apply Newton's method
    [x, k, history] = newton_system(F, J, x0, tol, max_iter);
    
    % Display results
    fprintf('Solution to Part B:\n');
    fprintf('x1 = %.10f\n', x(1));
    fprintf('x2 = %.10f\n', x(2));
    fprintf('Number of iterations: %d\n', k);
    
    % Display iteration history
    fprintf('\nIteration History:\n');
    fprintf('Iter\t     x1\t\t     x2\t\t   ||F(x)||\n');
    for i = 1:size(history, 1)
        fprintf('%3d\t%.10f\t%.10f\t%.10e\n', i-1, history(i,1), history(i,2), norm(F(history(i,:)')));
    end
end

function [x, iterations, history] = newton_system(F, J, x0, tol, max_iter)
    x = x0;
    history = x0';
    
    for iterations = 1:max_iter
        Fx = F(x);
        if norm(Fx) < tol
            break;
        end
        
        Jx = J(x);
        if det(Jx) == 0
            error('Jacobian is singular. Newton''s method fails.');
        end
        
        delta = Jx \ (-Fx);
        x = x + delta;
        history(end+1,:) = x';
    end
    
    if iterations == max_iter
        warning('Maximum iterations reached. The method may not have converged.');
    end
end

newtons_method_system