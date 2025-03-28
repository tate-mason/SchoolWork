%% PS4 - Tauchen-Hussey
clear;
clc;

%% Setting parameters
mu = 0;
rho = 0.9;
sigma = 0.0242;
n = 9;

maxit = 10000;

%% Calling GHQuad
[x,w] = ghquad(n, maxit);

%% Problem 1

%Calculating Unconditional Distribution
uncon_mean = mu / (1-rho);
uncon_sd = sigma / sqrt(1-rho^2);

%Calculate Steps and Discretize Space
m = 3;
min_y = uncon_mean - m * uncon_sd;
max_y = uncon_mean + m * uncon_sd;
step = (max_y-min_y) / (n-1);

y_state = zeros(n,1);
for i = 1:n
  y_states(i) = min_y + (i-1)*step;
end

% Transition Probability
P = zeros(n, n);

for i = 1:n
  mean_next = mu + rho*y_states(i);
  for j = 1:n
    if j == 1
      upper_bound = y_states(j) + step/2;
      P(i,j) = normcdf((upper_bound - mean_next)/sigma);
    elseif j == n
      lower_bound = y_states(j) - step/2;
      P(i,j) = 1 - normcdf((lower_bound - mean_next)/sigma);
    else
      upper_bound = y_states(j) + step/2;
      lower_bound = y_states(j) - step/2;
      P(i,j) = normcdf((upper_bound - mean_next)/sigma) - ...
               normcdf((lower_bound - mean_next)/sigma);
    end
  end
end

%Print results
disp('Discretized State Space for y: ');
disp(y_states);

disp('Transition Matrix: ');
disp(P);

%% Problem 2

%Simulation Definition
n_obs = 1000000;
dis = 1000;
total_sim = n_obs + dis;

%Start at Midpoint
state_sim = zeros(total_sim,1);
state_sim(1) = ceil(n/2);

%Seed for reproducibility
rng(19);
u = rand(total_sim, 1);

%Simulate
