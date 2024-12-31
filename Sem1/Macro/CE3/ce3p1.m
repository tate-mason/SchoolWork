%% A
% Parameters
rho = 0.8;
sigmasq_ep = 0.05;
mu_z = 0;
n = 2;

% Formulae
p = (1+rho)/2;
sigma_eq = sqrt(sigmasq_ep);
nu = sigma_eq * sqrt((n-1)/(1-rho^2));

%Display results
disp(['p = ', num2str(p)]);
disp(['nu = ', num2str(p)]);

%% B
%Transition Matrix
P2 = [p, 1-p; 1-p,p];
% Stationary Dist
[vec, ~] = eig(P2');
stationary = vec(:,1)/sum(vec(:,1));

disp('Stationary Distribution:');
disp(stationary);

%%C
%Setup
T = 1100;
z = zeros(T,1);
z(1) = mu_z-nu;

%Generating Time Series
for t = 2:T
  u = rand;
  if z(t-1)==(mu_z-nu)
    if u<p
      z(t)=mu_z-nu;
    else
      z(t)=mu_z-nu;
    end
  else
    if u<(1-p)
      z(t)=mu_z-nu;
    else
      z(t)=mu_z+nu;
    end
  end
end

%Plotting Results
plot(z);
title('Generated Time Series');
xlabel('Time');
ylabel('State');

%%D
%Setup
num_sim = 1000;
autocorrelations=zeros(num_sim,1);
variances = zeros(num_sim,1);

for sim=1:num_sim
  z = zeros(T,1);
  z(1) = mu_z-nu;
  for t=2:T
    u = rand;
    if z(t-1) == (mu_z-nu)
      if u<p
        z(t) = mu_z-nu;
      else
        z(t) = mu_z+nu;
      end
    else
      if u<(1-p)
        z(t)=mu_z-nu;
      else
        z(t)=mu_z+nu;
      end
    end
  end
%Toss first 100 periods
z = z(101:end);
%Calc AC and var
autocorrelations(sim) = corr(z(1:end-1), z(2:end));
variances(sim) = var(z);
end
%Display Results
disp(['Average Autocorrelation: ', num2str(mean(autocorrelations))]);
disp(['Average Variance: ', num2str(mean(variances))]);
