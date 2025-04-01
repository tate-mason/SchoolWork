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
  y_state(i) = uncon_mean + sqrt(2)*sigma*x(i);
end

% Transition Probability
P = zeros(n, n);

for i = 1:n
  mean_next = mu + rho*y_state(i);
  for j = 1:n
    P(i,j) = w(j)/sqrt(pi)*exp(-(0.5)*((y_state(j) - rho*y_state(i))/sigma)^2)/exp(-x(j)^2);
  end
  dens = sum(P(i,:));
  P(i,:) = P(i,:)/dens;
end

%Print results
disp('Discretized State Space for y: ');
disp(y_state);

disp('Transition Matrix: ');
disp(P);

%% Problem 2

n = 1000000;
dis = 1000;

y_sim = zeros(n, 1);

init = randi(length(y_state));
y_sim(1) = y_state(init);

current_state = init;

for t = 2:n
  cum_prob = cumsum(P(current_state, :));
  r = rand();
  next_state = find(r <= cum_prob, 1, 'first');
  y_sim(t) = y_state(next_state);
  current_state = next_state;
end

y_sim_final = y_sim(dis+1:end);

y_t = y_sim_final(1:end-1);
y_tp1 = y_sim_final(2:end);

y_mean = mean(y_sim_final);
y_demean = y_t - y_mean;
y_tp1_demean = y_tp1 - y_mean;

rho_hat = (y_demean' * y_tp1_demean)/(y_demean'*y_demean);

e_hat = y_tp1 - (mu + rho_hat*y_t);
sigma_hat = sqrt(mean(e_hat.^2));

fprintf('Estimated autocorrelation coefficient (rho_hat): %.6f\n', rho_hat);
fprintf('Estimated variance (sigma_hat): %.6f\n', sigma_hat);
