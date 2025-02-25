% Solving Consumer's Problem %
clear;
clc;

% Definition of Parameters %
r = 0.02;
beta = 1/(1+r);
cbar = 100;
yL = 0.05;
yH = 0.5;
pL = 0.6;
pH = 0.4;
ygrid = [yL,yH];
pgrid = [pL,pH];

% Bringing in Agrid %
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
% VFI Params %
tol = 1e-10;
maxiter = 1000;
diff = 1;
iter = 0;

% Init Matrices %
v0 = zeros(n,2);
v1 = zeros(n,2);
aopt = zeros(n,2);
copt = zeros(n,2);

% VFI %
while diff > tol && iter<maxiter
  iter = iter + 1;
  for i = 1:n
    for m = 1:2
      y = ygrid(m);
      max_val = -Inf;
      best_a = 0;
      best_c = 0;
      
      for j = 1:n
        a_next = agrid(j);
        c = (1+r)*agrid(i) + y - a_next;
        if c>0
          u = -0.5*(c-cbar)^2;
          EV = beta*(pL*v0(j,1) + pH*v0(j,2));
          val = u+EV;
          if val > max_val
            max_val = val;
            best_a = a_next;
            best_c = c;
          end
        end
      end
      v1(i,m) = max_val;
      aopt(i,m) = best_a;
      copt(i,m) = best_c;
    end
  end
  diff = max(max(abs(v1-v0)));
  v0 = v1;
end

figure;
subplot(2,2,1);
plot(agrid, aopt(:,1), 'b', agrid, agrid, 'k--');
title('Assets Policy Function (yL)');
xlabel('Current Assets');
ylabel('Next Period Assets');

subplot(2,2,2);
plot(agrid, copt(:,1), 'r');
title('Consumption Policy Function (yL)');
xlabel('Current Assets');
ylabel('Consumption');

subplot(2,2,3);
plot(agrid, aopt(:,2), 'b', agrid, agrid, 'k--');
title('Assets Policy Function (yH)');
xlabel('Current Assets');
ylabel('Next Period Assets');

subplot(2,2,4);
plot(agrid, copt(:,2), 'r');
title('Consumption Policy Function (yH)');
xlabel('Current Assets');
ylabel('Consumption');

% Adding Borrowing Constraint %
while diff > tol && iter<maxiter
  iter = iter + 1;
  for i = 1:n
    for m = 1:2
      y = ygrid(m);
      max_val = -Inf;
      best_a = 0;
      best_c = 0;
      for j = 1:n
        a_next = agrid(j);
        c = (1+r)*agrid(i) + y - a_next;
        if a_next >= 0 && c>0
          u = -0.5*(c-cbar)^2;
          EV = beta*(pL*v0(j,1) + pH*v0(j,2));
          val = u+EV;
          if val > max_val
            max_val = val;
            best_a = a_next;
            best_c = c;
          end
        end
      end
      v1(i,m) = max_val;
      aopt(i,m) = best_a;
      copt(i,m) = best_c;
    end
  end
  diff = max(max(abs(v1-v0)));
  v0 = v1;
end

figure;
subplot(2,2,1);
plot(agrid, aopt(:,1), 'b', agrid, agrid, 'k--');
title('Assets Policy Function (yL)');
xlabel('Current Assets');
ylabel('Next Period Assets');

subplot(2,2,2);
plot(agrid, copt(:,1), 'r');
title('Consumption Policy Function (yL)');
xlabel('Current Assets');
ylabel('Consumption');

subplot(2,2,3);
plot(agrid, aopt(:,2), 'b', agrid, agrid, 'k--');
title('Assets Policy Function (yH)');
xlabel('Current Assets');
ylabel('Next Period Assets');

subplot(2,2,4);
plot(agrid, copt(:,2), 'r');
title('Consumption Policy Function (yH)');
xlabel('Current Assets');
ylabel('Consumption');

% Simulations %

T = 100;
a_sim = zeros(T,1);
c_sim = zeros(T,1);
y_sim = zeros(T,1);

rng(1);

for t = 1:T
  if rand < pL
    y_sim(t) = yL;
  else
    y_sim(t) = yH;
  end
  a_sim(t+1)=interp1(agrid,aopt(:,(y_sim(t)==yH)+1), a_sim(t), 'linear','extrap');
  c_sim(t)=interp1(agrid, copt(:,(y_sim(t)==yH)+1), a_sim(t), 'linear', 'extrap');
end

figure;
plot(1:T, a_sim(1:T), 'b', 'LineWidth', 1.5);
title('Simulated Asset Over Time');
xlabel('Time');
ylabel('Assets');

figure;
plot(1:T, c_sim(1:T), 'r', 'LineWidth', 1.5);
title('Simulated Consumption Over Time');
xlabel('Time');
ylabel('Consumption');
