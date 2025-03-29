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

