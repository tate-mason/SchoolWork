%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Tate Mason - David.Mason2@uga.edu   %%
%% Midterm Exam - Take Home Section    %%
%% Due on Mar 17, 2025                 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;
clc;
close all;

%% Definition of Parameters %%

r = 0.04; % Interest rate
beta = 0.95; % Discount rate
sigma = 3; % Risk aversion
T = 40; % Time
cmin = 0.5; % Minimum consumption level
y = 1; % Income from pension - constant 
W = 10; % Initial wealth
n = 100; % Number of points in kgrid

%% Definition of kgrid %%

kgrid = linspace(0,100^0.5, n).^2; % Creates a denser distribution of points near 0 and goes to 100

%% Definition of xgrid %%
x_data = load('xpts40.txt'); % Loads provided file

xgrid = [zeros(1,40); x_data(:,2)']; % Creates matrix which in the first row has no medical shock and in the second has transposed shocks
pX = [0.8;0.2]; % Definition of given probability of shock

%% Definition of CRRA Utility %%

u = @(c) (c.^(1-sigma))/(1-sigma);

%% Initialization of Value and Policy Functions %%

V = zeros(n,2,T); % Vt - n grid points, 2 shock values, and T periods of time
k_opt = zeros(n,2,T); % Optimal savings

%% Part 3: Raising Minimum Consumption to 0.5 %%

% Initialize new Value and Policy Functions
V_high_cmin = zeros(n,2,T); % Value function with higher cmin
k_opt_high_cmin = zeros(n,2,T); % Optimal savings with higher cmin

%% Starting at t = T for cmin = 0.5 %%

for ik = 1:n % loop over kgrid
  for ix = 1:2 % loop over xgrid in cases of no shock and shock
    kt = kgrid(ik); % Current savings
    xt = xgrid(ix,T); % Current medical expense 
    
    totres = kt*(1+r) + y - xt; % Total resources
    if totres <= cmin
      c = cmin;
      k_next = 0; % Final period --> no saving
    else
      c = totres;
      k_next = 0; % Final period --> no saving
    end
    V_high_cmin(ik, ix, T) = u(c); % Value function with found values
    k_opt_high_cmin(ik, ix, T) = k_next; % Optimal savings (0 in this case)
  end
end

%% Now Move Recursively for cmin = 0.5 %%

for t = (T-1):-1:1 % Starting at period T-1 and moving backwards through time
  for ik = 1:n
    for ix = 1:2
      kt = kgrid(ik);
      xt = xgrid(ix,t); % Using t instead of T
      totres = kt*(1+r) + y - xt;
      if totres <= cmin
        c = cmin;
        k_next = 0;
        V_high_cmin(ik,ix,t) = u(c);
      else
        obj = @(kp) -obj_func(kp,totres,beta,pX,kgrid,V_high_cmin(:,:,t+1),u);
        [k_next,Eval] = fminbnd(obj,0,totres);
        V_high_cmin(ik,ix,t) = -Eval;
      end
      k_opt_high_cmin(ik,ix,t) = k_next;
    end
  end
end

%% Simulation of Medical Expense Shocks with cmin = 0.5 %%

% Create the simulated medical expense shocks
rng(17); % Random seed set
simx = zeros(T,1);
draws = rand(T,1);

for t = 1:T
  if draws(t) <= pX(1)
    simx(t) = xgrid(1,t);
  else
    simx(t) = xgrid(2,t);
  end
end

% Simulating savings with high cmin
ksim_high_cmin = zeros(T+1,1);
ksim_high_cmin(1) = W; % Initial wealth

for t = 1:T
  [~,idx_k] = min(abs(kgrid - ksim_high_cmin(t)));

  if simx(t) == xgrid(1,t)
    idx_x = 1;
  else
    idx_x = 2;
  end
  
  if abs(kgrid(idx_k)-ksim_high_cmin(t)) < 1e-6
    ksim_high_cmin(t+1) = k_opt_high_cmin(idx_k, idx_x, t);
  else
    if ksim_high_cmin(t) < kgrid(1)
      ksim_high_cmin(t+1) = k_opt_high_cmin(1, idx_x, t);  
    elseif ksim_high_cmin(t) > kgrid(end) 
      ksim_high_cmin(t+1) = k_opt_high_cmin(end, idx_x, t);  
    else 
      jlo = find(kgrid <= ksim_high_cmin(t), 1, 'last');
      jlo2 = jlo + 1;
      w = (ksim_high_cmin(t)-kgrid(jlo))/(kgrid(jlo2)-kgrid(jlo));
      ksim_high_cmin(t+1) = (1-w)*k_opt_high_cmin(jlo, idx_x, t) + w*k_opt_high_cmin(jlo2, idx_x, t); 
    end
  end
end

% Plotting the simulated lifecycle savings path
figure;
plot(0:T, ksim_high_cmin, 'r-', 'LineWidth', 2);
title('Lifecycle Savings - Higher Minimum Consumption (c_{min} = 0.5)');
xlabel('Age');
ylabel('Savings (k_t)');
grid on;
saveas(gcf, 'higher_cmin_savings.png');

%% Helper Function %%

function val = obj_func(kp, totres, beta, pX, kgrid, V_next, u)
  c = totres - kp;
  current_u = u(c);

  if kp <= kgrid(1)
    jlo = 1;
  elseif kp >= kgrid(end)
    jlo = length(kgrid)-1;
  else
    jlo = find(kgrid <= kp, 1, 'last');
  end
  jlo2 = jlo+1; 
  w = (kp - kgrid(jlo))/(kgrid(jlo2)-kgrid(jlo));
  Eval = 0;

  for ixp = 1:2
    v_next = (1-w)*V_next(jlo,ixp) + w*V_next(jlo2,ixp);     
    Eval = Eval + pX(ixp)*v_next;
  end
  val = current_u + beta*Eval;
end
