clear;
clc;

% Parameters
alpha = 0.3;
sigma = 3;
beta = 0.99;
pi = 0.1;
n = 0.01;
surv_values = [1.0, 0.8]; % First without survival risk, then with

% Grid for medical shock x
xgrid = 0:0.001:0.3;

% Main Solution and Plotting Loop
for surv_idx = 1:length(surv_values)
    surv = surv_values(surv_idx);
    
    % Initialize storage
    k_case1 = zeros(size(xgrid));
    k_case2 = zeros(size(xgrid));
    w_case1 = zeros(size(xgrid));
    w_case2 = zeros(size(xgrid));
    welfare_case1 = zeros(size(xgrid));
    welfare_case2 = zeros(size(xgrid));
    
    for x_idx = 1:length(xgrid)
        x = xgrid(x_idx);
        
        % Case 1: No insurance
        insur = 1;
        tol = 1e-5;
        max_iter = 1000;
        weight = 0.5;
        k_guess = 0.1;
        
        for iter = 1:max_iter
            r = alpha * k_guess^(alpha-1) - 1;
            w = (1-alpha) * k_guess^alpha;
            p = 0;
            
            s_grid = linspace(0, w-p, 1000);
            obj_values = arrayfun(@(s) objective_fn(s, x, insur, surv, w, r, p, sigma, beta, pi, n), s_grid);
            [~, min_idx] = min(obj_values);
            s_opt = s_grid(min_idx);
            
            new_k = surv * s_opt / (1 + n);
            k_new = weight * k_guess + (1-weight) * new_k;
            
            if abs(k_new - k_guess) < tol
                break;
            end
            k_guess = k_new;
        end
        
        k_case1(x_idx) = k_guess;
        w_case1(x_idx) = w;
        
        % Calculate welfare for Case 1
        c_young = w - s_opt;
        c_old_good = s_opt * (1 + r);
        c_old_bad = s_opt * (1 + r) - x;
        utility_young = c_young^(1-sigma)/(1-sigma);
        utility_old = surv * (pi * c_old_bad^(1-sigma)/(1-sigma) + ...
                            (1-pi) * c_old_good^(1-sigma)/(1-sigma));
        if surv < 1.0
            bequest = (1-surv) * s_opt / (1 + n);
            utility_bequest = (w + bequest)^(1-sigma)/(1-sigma);
            welfare_case1(x_idx) = utility_young + utility_old + (1-surv)*utility_bequest;
        else
            welfare_case1(x_idx) = utility_young + utility_old;
        end
        
        % Case 2: With insurance
        insur = 2;
        k_guess = 0.1;
        
        for iter = 1:max_iter
            r = alpha * k_guess^(alpha-1) - 1;
            w = (1-alpha) * k_guess^alpha;
            p = pi * x / (1 + r) * surv;
            
            s_grid = linspace(0, w-p, 1000);
            obj_values = arrayfun(@(s) objective_fn(s, x, insur, surv, w, r, p, sigma, beta, pi, n), s_grid);
            [~, min_idx] = min(obj_values);
            s_opt = s_grid(min_idx);
            
            new_k = (surv * s_opt + p) / (1 + n);
            k_new = weight * k_guess + (1-weight) * new_k;
            
            if abs(k_new - k_guess) < tol
                break;
            end
            k_guess = k_new;
        end
        
        k_case2(x_idx) = k_guess;
        w_case2(x_idx) = w;
        
        % Calculate welfare for Case 2
        c_young = w - s_opt - p;
        c_old = s_opt * (1 + r);
        utility_young = c_young^(1-sigma)/(1-sigma);
        utility_old = surv * beta * c_old^(1-sigma)/(1-sigma);
        if surv < 1.0
            bequest = (1-surv) * s_opt / (1 + n);
            utility_bequest = (w + bequest)^(1-sigma)/(1-sigma);
            welfare_case2(x_idx) = utility_young + utility_old + (1-surv)*utility_bequest;
        else
            welfare_case2(x_idx) = utility_young + utility_old;
        end
    end
    
    % Plot results directly without storing in struct
    figure('Position', [100, 100, 1200, 400]);
    
    % Capital per worker
    subplot(1,3,1);
    plot(xgrid, k_case1, 'b-', 'LineWidth', 2); hold on;
    plot(xgrid, k_case2, 'r--', 'LineWidth', 2);
    title(sprintf('Capital per Worker (surv=%.1f)', surv));
    xlabel('Medical Shock (x)');
    ylabel('k');
    legend('No Insurance', 'With Insurance', 'Location', 'best');
    grid on;
    
    % Wage
    subplot(1,3,2);
    plot(xgrid, w_case1, 'b-', 'LineWidth', 2); hold on;
    plot(xgrid, w_case2, 'r--', 'LineWidth', 2);
    title(sprintf('Wage (surv=%.1f)', surv));
    xlabel('Medical Shock (x)');
    ylabel('w');
    legend('No Insurance', 'With Insurance', 'Location', 'best');
    grid on;
    
    % Welfare
    subplot(1,3,3);
    plot(xgrid, welfare_case1, 'b-', 'LineWidth', 2); hold on;
    plot(xgrid, welfare_case2, 'r--', 'LineWidth', 2);
    title(sprintf('Welfare (surv=%.1f)', surv));
    xlabel('Medical Shock (x)');
    ylabel('Utility');
    legend('No Insurance', 'With Insurance', 'Location', 'best');
    grid on;
end

% Objective Function remains unchanged
function obj = objective_fn(s, x, insur, surv, w, r, p, sigma, beta, pi, n)
    if insur == 1 % No insurance
        c_young = w - s;
        c_old_good = s * (1 + r);
        c_old_bad = s * (1 + r) - x;
        utility_young = c_young^(1-sigma)/(1-sigma);
        utility_old = surv * (pi * c_old_bad^(1-sigma)/(1-sigma) + ...
                         (1-pi) * c_old_good^(1-sigma)/(1-sigma));
        if surv < 1.0
            bequest = (1-surv) * s / (1 + n);
            utility_bequest = (w + bequest)^(1-sigma)/(1-sigma);
            obj = -(utility_young + utility_old + (1-surv)*utility_bequest);
        else
            obj = -(utility_young + utility_old);
        end
    else % With insurance
        c_young = w - s - p;
        c_old = s * (1 + r);
        utility_young = c_young^(1-sigma)/(1-sigma);
        utility_old = surv * beta * c_old^(1-sigma)/(1-sigma);
        if surv < 1.0
            bequest = (1-surv) * s / (1 + n);
            utility_bequest = (w + bequest)^(1-sigma)/(1-sigma);
            obj = -(utility_young + utility_old + (1-surv)*utility_bequest);
        else
            obj = -(utility_young + utility_old);
        end
    end
end
