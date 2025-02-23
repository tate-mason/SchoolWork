% Load or create asset grid
clear
r=0.02;
yvec=[0.05,0.5];
min=0.0001;
amax=2;
k=20;
gamma=(1+r)^(1/(k-1));
step1=(yvec(1)-min)*(gamma-1)/r;
n=floor(1+log(amax*(gamma-1)/step1+1)/log(gamma));
f=@(x)step1*(gamma.^(x-1)-1)/(gamma-1);
agrid=f(1:n)
if isempty(agrid) || length(agrid) < 10  % If file fails, create grid manually
    a_min = 0;   
    a_max = 5;   
    n = 100;    
    agrid = linspace(a_min, a_max, n)';
end

% Given parameters
r = 0.02;
beta = 1 / (1 + r);
c_bar = 100;
yL = 0.05;
yH = 0.5;
pL = 0.6;
pH = 0.4;
tol = 1e-6;  % Less strict for faster convergence

n = length(agrid); % Number of asset grid points

% Initialize value function and policy function
V = -0.5 * ((agrid - c_bar).^2);  % Smarter initialization
V_new = zeros(n, 2);
copt = zeros(n, 2); % Optimal consumption
aopt = zeros(n, 2); % Optimal savings
jopt = zeros(n, 2); % Index of optimal savings

% Iteration on Bellman equation
max_diff = inf;
iter = 0; % Track number of iterations

while max_diff > tol
    iter = iter + 1;
    for m = 1:2 % Income states: m=1 -> yL, m=2 -> yH
        if m == 1
            y = yL;
        else
            y = yH;
        end
        for i = 1:n % Loop over asset grid
            a = agrid(i);
            max_val = -Inf;
            best_j = 1;

            for j = 1:n  % Future asset choices
                a_prime = agrid(j);
                c = a * (1 + r) + y - a_prime;
                
                if c > 0  % Ensure valid consumption
                    U = -0.5 * (c - c_bar)^2; 
                else
                    U = -1e6;  % Large penalty for infeasibility
                end

                % Compute expected value function
                EV = beta * (pL * V(j, 1) + pH * V(j, 2));  
                val = U + EV;

                % If val is higher, update best savings choice
                if val > max_val
                    max_val = val;
                    best_j = j;
                end
            end

            % Ensure `aopt` is updating correctly
            if best_j > 1  % If best savings choice is not just zero
                aopt(i, m) = agrid(best_j);
            else
                fprintf('Warning: Agent is stuck at zero savings for i=%d, m=%d\n', i, m);
            end

            % Compute optimal consumption
            copt(i, m) = max(0, a * (1 + r) + y - aopt(i, m));
        end
    end
    
    % Check for convergence
    max_diff = max(max(abs(V_new - V)));
    V = V_new;
    
    % Display iteration progress
    fprintf('Iteration %d, max difference = %e\n', iter, max_diff);
end

% Save results
save('policy_functions.mat', 'aopt', 'copt', 'V');

% Plot policy functions
figure;
subplot(2,2,1); plot(agrid, aopt(:,1), 'b', agrid, agrid, 'k--');
xlabel('Current Assets'); ylabel('Next Period Assets');
title('a_{t+1} for y = yL');

subplot(2,2,2); plot(agrid, copt(:,1), 'r');
xlabel('Current Assets'); ylabel('Consumption');
title('c_{t} for y = yL');

subplot(2,2,3); plot(agrid, aopt(:,2), 'b', agrid, agrid, 'k--');
xlabel('Current Assets'); ylabel('Next Period Assets');
title('a_{t+1} for y = yH');

subplot(2,2,4); plot(agrid, copt(:,2), 'r');
xlabel('Current Assets'); ylabel('Consumption');
title('c_{t} for y = yH');
