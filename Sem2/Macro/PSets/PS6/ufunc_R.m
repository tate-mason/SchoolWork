


% Solve optimization problem and finding utility and value function for retirement years
function f = ufunc_R(kp,ik,t)


    % Defining parametrs
    global b beta kgrid r VR


    % Consumption using budget constraint
    c = kgrid(ik)*(1+r) + b - kp;  


    % labor supply is zero
    l = 0;


    % Current utility
    u = utilityfunction(c,l);


    % Locate optimal capital on the grid
    jlo = find(kgrid <= kp, 1, 'last');


    % Calculating linear interpolation weights
    weight = (kp-kgrid(jlo))/(kgrid(jlo+1)-kgrid(jlo));


    % Next period utility
    V_hat = (1-weight)*VR(jlo,t+1) + weight*VR(jlo+1,t+1); % Note that retired agents do not experience any uncertainty so there is no expected value function
    
    % Calculating total value
    f = u + beta*V_hat;
    f = -f;               % fmindbn minimizes, negating for maximization



end
