clear; clc;

%% **Step 1: Define Parameters**
r = 0.02;
beta = 1 / (1 + r);
c_bar = 100;
yL = 0.05;
yH = 0.5;
pL = 0.6;
pH = 0.4;
tol = 1e-10;

%% **Step 2: Create Grid for Assets**
r=0.02;
yvec=[0.05,0.5];
min=0.0001;
amax=2;
k=20;
gamma=(1+r)^(1/(k-1));
step1=(yvec(1)-min)*(gamma-1)/r;
n=floor(1+log(amax*(gamma-1)/step1+1)/log(gamma));
f=@(x)step1*(gamma.^(x-1)-1)/(gamma-1);
Agrid=f(1:n)
%% **Step 3: Initialize Matrices**
V0 = zeros(n, 2);
V1 = zeros(n, 2);
aopt = zeros(n, 2);
copt = zeros(n, 2);

% Initialize Value Function Based on Initial Wealth
V0(:,1) = -0.5 * (Agrid + yL - c_bar).^2;
V0(:,2) = -0.5 * (Agrid + yH - c_bar).^2;

%% **Step 4: Value Function Iteration**
diff = inf;
iteration = 0;

while diff > tol
    iteration = iteration + 1;
    for i = 1:n
        for m = 1:2
            y = (m == 1) * yL + (m == 2) * yH;
            possible_c = Agrid(i) * (1 + r) + y - Agrid;
            possible_c(possible_c < 0) = -inf;

            % Utility function
            U = -0.5 * (possible_c - c_bar).^2;

            % Bellman Equation Update
            Bellman = U + beta * (pL * V0(:, 1) + pH * V0(:, 2));

            % Debugging: Print Bellman values for early iterations
            if i == 1 && m == 1 && iteration <= 5
                disp(['Iteration ', num2str(iteration), ': Bellman Values (first 5)']);
                disp(Bellman(1:5));
            end

            % Find Maximum Value Function
            [V1(i,m), j_star] = max(Bellman(:));
            aopt(i,m) = Agrid(j_star);
            copt(i,m) = Agrid(i) * (1 + r) + y - aopt(i,m);
        end
    end

    % Check Convergence
    diff = max(abs(V1(:) - V0(:)));
    disp(['Iteration ', num2str(iteration), ', max diff: ', num2str(diff)]);
    V0 = V1; % Update value function
end

%% **Step 5: Check If aopt is Constant**
if all(aopt(:,1) == aopt(1,1)) && all(aopt(:,2) == aopt(1,2))
    disp('WARNING: aopt is constant across all grid points!');
end

