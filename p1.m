%%%%%%%%%%%%%%
% Tate Mason %
%%%%%%%%%%%%%%

%{
Question 1: CRRA Utility Function
    part a: derive a function to model the given utility function
    part b: graph how consumption changes with different levels of risk
            aversion
%}

%%%%%%%%%%%%%%%%%%%
% Part A          %
%%%%%%%%%%%%%%%%%%%

function u = calcU(c, sigma)
    if sigma == 1
        u = log(c);
    else
        u = (c.^(1-sigma)-1)/(1-sigma);
    end
end

%%%%%%%%%%%%%%%%%%%
% Part B          %
%%%%%%%%%%%%%%%%%%%

% Define consumption range
c = linspace(0, 1, 10000);

% Define sigma values
sigma_values = [0, 0.5, 1, 2, 10, 20, 100];
% Create figure
figure;
hold on;

% Plot for each sigma value
for i = 1:length(sigma_values)
    sigma = sigma_values(i);
    u=calcU(c,sigma);
    plot(c, u, 'DisplayName', sprintf('σ = %g', sigma));
end

% Customize plot
xlabel('Consumption (c)');
ylabel('Utility (u)');
title('CRRA Utility Function for Various σ Values');
legend('Location', 'best');
axis([0 1 -1 1]);
grid on;
hold off;

%%%%%%%%%%%%%%%%%%%
% Part C          %
%%%%%%%%%%%%%%%%%%%

function mu = calcMU(c, sigma)
    if sigma == 1
        mu = 1./c;
    else
        mu = c.^(-sigma);
    end
end

% Define consumption range
c = linspace(0, 1, 10000);

% Define sigma values
sigma_values = [0, 0.5, 1, 2, 10, 20, 100];
% Create figure
figure;
hold on;

% Plot for each sigma value
for i = 1:length(sigma_values)
    sigma = sigma_values(i);
    mu=calcMU(c,sigma);
    plot(c, mu, 'DisplayName', sprintf('σ = %g', sigma));
end

% Customize plot
xlabel('Consumption (c)');
ylabel('Marginal Utility (mu)');
title('Marginal Utility for Various σ Values');
legend('Location', 'best');
axis([0 1 -1 1]);
grid on;
hold off;

