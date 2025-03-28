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

y_state = zeros(n,1);
for i = 1:n
  y_states(i) = uncon_mean + sqrt(2)*uncon_sd*x(i);
end

% Transition Probability
P = zeros(n, n);

for i = 1:n
  mean_next = mu + rho*y_states(i);
  for j = 1:n
    P(i,j) = w(j) * normpdf(y_states(j), mean_next, sigma) / ...
             normpdf(y_states(j), uncon_mean, uncon_sd);
  end
  P(i,:) = P(i,:) / sum(P(i,:));
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
for t = 1:total_sim-1
  cum_prob = cumsum(P(state_sim(t),:)');
  state_sim(t+1) = find(u(t) <= cum_prob, 1);
end

y_sim = zeros(n_obs, 1);
for t = 1:n_obs
  y_sim(t) = y_states(state_sim(t+dis));
end


