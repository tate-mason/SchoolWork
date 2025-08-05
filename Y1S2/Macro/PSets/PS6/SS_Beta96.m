% Author: Kasra Lak
% HW6:OVERLAPPING GENRATIONS MODEL WITH IDIOSYNCRATIC PRODUCTIVITY SHOCKS AND PRODUCTION SECTOR

%% Part 1) Solving the model when retired people receive social security and beta=0.96


% Global variables to be used here and in other functions

global b beta kgrid lambda mu nk nz N R r sigma tau V VR w z


% Parametrization
T       = 65;                   % Number of periods
R       = 40;                   % Retirement age
n       = 0.011;                % Growth rate of population
k1      = 0;                    % Capital endowment at birth period
tau     = 0.11;                 % Rate of tax on young income
mu      = 0.5;                  % Weight on consumption in utility function
sigma   = 3;                    % Coefficinet of risk aversion
beta    = 0.96;                 % Discount factor
alpha       = 0.36;             % Share of capital in Cobb Douglas function
delta       = 0.06;             % Depreciation rate of current capital
rho         = 0.9;              % Persistency parameter in AR(1) procces for z_t
var       = 0.03;               % Variance of innovation (epsilon) in productivity shock

% Importing lambda: Deterministi profile that shows the effect of age on productivity
lambda      = importdata('lambda_HW6.in');      % Pre-defined

% discretizing state variables: capital productiviy space 

nk          = 100;                  % number of elements of capital grid
p = 2;                              % Power is used to create non-linear spacing for capital, so denisity is higher around zero. The funtional form is suggested by DeepSeek AI
kgrid = 100 * (linspace(k1, 1, nk).^p);    % Creating values on kgrid (Maximum capital is 100)

% discretizing state variables: productiviy space 

nz          = 9;                    % number of elements on z grid
[y,w] = ghquad(nz,10000);           % apply Gauss-Hermit quadrature using pre-defined function
z = sqrt(2)*sqrt(var).*y;           % Change in variable for the integral of exp(-x^2)f(x)dx form where x=(y(t+1))/(sqrt(2)sigma)

disp('Descritized space of z using Tauchen_Hussey algorithm:')
disp(z)




% Transition matrix
M = zeros(nz,nz);
for i = 1:nz
	for j = 1:nz
        a = 2*rho*z(i)*z(j) - (rho^2)*(z(i)^2); % Tauchen-Hussey:  From conditional probability distribution
        b=2*var;
        M(i,j) = (w(j)/sqrt(pi))*exp(a/b);   % weights (w) for Gauss-Hermite quadrature of order n come from ghquad function
	end
end

% Normalizing transition matrix such that probabilites add up to one

% Normalized transition matrix
S = sum(M,2);      %sum of each row in M
N = zeros(nz,nz);
for i = 1:nz
    for j = 1:nz
        N(i,j) = M(i,j)/S(i); % N contains normalized elements
    end
end
disp('Normalized transition Matrix for productivity shocks:')
disp(N)


% Cummulative transition matrix
cumN = zeros(nz,nz);
for j = 1:nz
    if j == 1
        for i = 1:nz             
            cumN(i,j) = N(i,j);   %Elements in first coloumn remain 
        end
    elseif j > 1
        for i = 1:nz
            cumN(i,j) = cumN(i,j-1) + N(i,j);  % Ohter coloumns are accumulated
        end
    end
end
disp('Comulative Normalized Transition Matrix:')
disp (cumN)



 
%% Initialize optimal matrices and guess for value function, all zeros:
V = zeros(nk,nz,R-1);    % Value function during working years
copt = zeros(nk,nz,R-1); % Optimal consumption for workers
kopt = zeros(nk,nz,R-1); % Otimal saving for workers
lopt = zeros(nk,nz,R-1); % Optimal labor supply

% For retired agents
VR = zeros(nk,T-R+1); % value function during retirement years
coptR = zeros(nk,T-R+1); % optimal consumption for old
koptR = zeros(nk,T-R+1); % optimal saving for old

% Tolerance level

tol         = 10^(-4);

% Algorithm step 2: Guessing r and b

r = 0.1;
b = 0.5;

diff_r = 1;
diff_b = 1;


it = 0;


while diff_r>tol && diff_b>tol && it<=50

% Algorithm step 3: Capital to labor ratio using our guess of r, wage using firm' FOC

cap = ((r+delta)/alpha)^(1/(alpha-1)); %Steady state capital per capita
 w = (1-alpha)*(cap^alpha);       % Equilibrium wage

% Algorithm step 4: Solving consumer's problem using backward induction:

% Value function for retired agents:

    for ik = 1:nk 
        % starting from terminal period
        coptR(ik,T-R+1) = kgrid(ik)*(1+r) + b; % In the last period consumer does not save and consumes all the remaining resources
        koptR(ik,T-R+1) = 0;                   % Optimal capital is zero
        VR(ik,T-R+1) = utilityfunction(coptR(ik,T-R+1),0);   % Labor supply is zero for retired agents
    end
    
    for t = T-R:-1:1 % rest of retirement years
        for ik = 1:nk
            klow = 0;                                                   % Interval over wich optimal saving is found, has lower bound at zero capital 
            kup = min(kgrid(ik)*(1+r) + b - 0.0001, 100);               % Highest value for asset is such that capital is bounded from above by 100 and conusmption should remain strict positive value (marginal utility goes to infinity if c=0)
            [kval,fval] = fminbnd(@(kp)ufunc_R(kp,ik,t),klow,kup);       % Minimization of "ufunc_R" (defined in seperate file) over values of kp returns optimizer kval and the optimzed value of fval
            koptR(ik,t) = kval;                                         % Optimal level of saving
            coptR(ik,t) = kgrid(ik)*(1+r) + b - kval;                   % Optimal consumption after optimal saving is determined
            VR(ik,t) = -fval;                                           % value function was multiplied by negative in "ufunc_R" to convert minimzation to maximization, needs to be multiplied by another negative again
        end 
    end 



% Value function of working agents:
    
        % Starting from last working period
    for t = R-1:-1:1   
        for iz = 1:nz
            for ik = 1:nk
                klow = 0;
                kup = min(kgrid(ik)*(1+r) + w*exp(z(iz))*lambda(t,2)*(1-tau) - 0.0001, 100); % Budget constraint for working agents
                [kval,fval] = fminbnd(@(kp)ufunc_W(kp,ik,iz,t),klow,kup);
                kopt(ik,iz,t) = kval;
                lopt(ik,iz,t) = ((mu*w*exp(z(iz))*lambda(t,2)*(1-tau))-((1-mu)*(kgrid(ik)*(1+r)-kval))) / (w*exp(z(iz))*lambda(t,2)*(1-tau));  % Optimal labor supply after determining optimal saving
                if lopt(ik,iz,t) < 0
                    lopt(ik,iz,t) = 0;
                elseif lopt(ik,iz,t) > 1
                      l=1;
               end
                copt(ik,iz,t) = kgrid(ik)*(1+r) + w*exp(z(iz))*lambda(t,2)*(1-tau)*lopt(ik,iz,t) - kval;
                V(ik,iz,t) = -fval;
            end
        end      
    end 

    % Algorithm step 5: Invariant distributions for workers and retired

    % Initialize distribution matrices
    Gamma = zeros(nk,nz,R-1);         %Invariant distribtion of workers across capital, productivity and time space
    GammaR = zeros(nk,T-R+1);         %Invariant distribution of retired agents over capital and time space
    Pi = readmatrix("Pi.txt");
    Gamma(1,:,1) = Pi;                % The matrix provided on ELC
    
   
    
    % Invarient distribution during working years
    for t = 1:R-1
        for ik = 1:nk
            for iz = 1:nz
                masscur = Gamma(ik,iz,t);   % Mass of pupulation with particular combination of capital, productivity, at working time periods
                jlo = find(kgrid<=kopt(ik,iz,t),1,'last');   % Locating savings using workers' optimal saving found eariler
                weight = (kopt(ik,iz,t) - kgrid(jlo))/(kgrid(jlo+1) - kgrid(jlo)); % Interpolation weights

                % Allocating this mass over state variables for next periods
                for izp = 1:nz
                    if t == R-1   %The last period before becoming retired
                        GammaR(jlo,1) = GammaR(jlo,1) + masscur*(1-weight)*N(iz,izp);    %The mass population of workers enter to the retirement period
                        GammaR(jlo+1,1) = GammaR(jlo+1,1) + masscur*weight*N(iz,izp);    %So they create the mass population for retired agents for the first retirement period
                      else
                        Gamma(jlo,izp,t+1) = Gamma(jlo,izp,t+1) + masscur*(1-weight)*N(iz,izp);
                        Gamma(jlo+1,izp,t+1) = Gamma(jlo+1,izp,t+1) + masscur*weight*N(iz,izp);
                    end 
                end 
            end 
        end 
    end


    % Invarient distribution during retirement years
    for t = 1:T-R
        for ik = 1:nk                                      %No working, so the loop goes only over capital and time
            masscur = GammaR(ik,t);
            jlo = find(kgrid<=koptR(ik,t),1,'last');
            weight = (koptR(ik,t) - kgrid(jlo))/(kgrid(jlo+1) - kgrid(jlo));
            GammaR(jlo,t+1) = GammaR(jlo,t+1) + masscur*(1-weight);
            GammaR(jlo+1,t+1) = GammaR(jlo+1,t+1) + masscur*weight;
        end
    end 



    % Adjusting distributions for population growth
    
    % adjt(t) is the adjustment vector
    g = 1;
    for t = T:-1:1 
        adj(t) = g;
        g = g*(1+n); 
    end
    %Invariant distributions accounting for poulation growth
    Gamma_grow = zeros(nk,nz,R-1);  
    GammaR_grow = zeros(nk,T-R+1);
    
    for t = 1:R-1
        Gamma_grow(:,:,t) = Gamma(:,:,t)*adj(t);
    end
    
    for t = 1:T-R+1
        GammaR_grow(:,t) = GammaR(:,t)*adj(R-1+t);
    end
    
    % Normalize total mass of people to 1
    for ik = 1:nk
        for iz = 1:nz
            for t = 1:R-1
                Gamma(ik,iz,t) = Gamma_grow(ik,iz,t)/(sum(Gamma_grow,'all')+sum(GammaR_grow,'all'));  % During working years
            end
        end
    end
    
    for ik = 1:nk
        for t = 1:T-R+1
            GammaR(ik,t) = GammaR_grow(ik,t)/(sum(Gamma_grow,'all')+sum(GammaR_grow,'all'));   % During retirement
        end
    end


    % Algorithm step 6: Calculating aggregate capital and labor
    K = 0;
    L = 0;

    % Workers
    for t = 1:R-1
        for ik = 1:nk
            for iz = 1:nz
                K = K + Gamma(ik,iz,t).*kopt(ik,iz,t);                         % The capital supplied by workers
                L = L + Gamma(ik,iz,t).*lopt(ik,iz,t).*lambda(t,2)*exp(z(iz)); % Labor supply
            end
        end
    end
    
    % Total supply of capital by adding assests of retired individuals
    for t = 1:T-R+1
        for ik = 1:nk
            K = K + GammaR(ik,t).*koptR(ik,t);
        end
    end
    
    % Computing new interest rate r_new:
    r_new = alpha*(K/L)^(alpha-1) - delta;  % Using capital to labor ratio equation
    

     % Algorithm step 7: Calculating new value for social benefits:

     b_new = (tau*w*L)/sum(GammaR, 'all');


    % Algorithm step 8: Comparing guesses of r and b with r_new and b_new

    diff_r = abs(r_new - r);
    diff_b = abs(b_new - b);
    
    r = 0.5*r + 0.5*r_new;  % Updating our guess for r
    b = 0.5*b + 0.5*b_new;  % Updating our guess for b
    
    it = it + 1;
    fprintf('With Social Security and Beta = 0.96 : iteration # %d\n', it);
end      % End of "while"


fprintf('The loop to find r and b is complete\n');


%% Part 2b) PROFILE OF WEALTH AND LABOR SUPPLY WITH SOCIAL SECURITY AND BETA=0.96

% Workers
labor = zeros(1,R-1);
wealthW = zeros(1,R-1);
for t = 1:R-1
    for ik = 1:nk
        for iz = 1:nz
            labor(t) = labor(t) + lopt(ik,iz,t)*Gamma(ik,iz,t);     %Total labor supply 
            wealthW(t) = wealthW(t) + kopt(ik,iz,t)*Gamma(ik,iz,t); % Total accumulated assets by workers
        end
    end
end


% Retired agetns
wealthR = zeros(1,T-R+1);
for t = 1:T-R+1
    for ik=1:nk
        wealthR(t) = wealthR(t) + koptR(ik,t)*GammaR(ik,t);  %Total accumulated assets by retired agents
    end
end


% Save profiles
wealth = zeros(4,T);              % Wealth contains assets holding through the whole life-cycle for all the combination of (with and without social security)*(beta=0.96 or beta=0.99)
labor_supply = zeros(4,R-1);
wealth(1,:) = [wealthW,wealthR]; % Wealth of worker and retired with social security and beta=0.96
labor_supply(1,:) = labor;
save('profiles.mat', 'wealth', 'labor_supply')

%% Part 2c) WELFARE OF NEWBORN

V0 = 0;
for ik = 1:nk
    for iz = 1:nz
        V0 = V0 + Gamma(ik,iz,1)*V(ik,iz,1);  %Newborne is worker
    end
end

%% Part 3) Comparing the results
results = cell(7,5);
results(:,1) = {'Capital','Labor','Wage','Interest','Penion Benefit','Newborn Welfare','Discount factor'};   
results(:,2) = {K,L,w,r,b,V0,beta};               % Filling values for the case with social security and beta=0.96
save('results.mat', 'results');













    












