

% Solve optimization problem and finding utility and value function for working years
function f = ufunc_W(kp,ik,iz,t)


    % Define global variables
    global beta kgrid lambda mu nz N R r tau V VR w z


    % Defining parametrs

    l = ((mu*w*exp(z(iz))*lambda(t,2)*(1-tau))-((1-mu)*(kgrid(ik)*(1+r)-kp))) / (w*exp(z(iz))*lambda(t,2)*(1-tau)); % laor supply found from optimization

    % labor supply restriced between 0 and 1
    if l < 0
        l = 0;
    elseif l>1
        l=1;
    end


    % Consumption after tax using budget constraint
    y = w*exp(z(iz))*lambda(t,2)*l; % labor income
    c = kgrid(ik)*(1+r) + y*(1-tau) - kp;


     % Current utility
     u = utilityfunction(c,l);


    % Locate optimal capital on the grid
    jlo = find(kgrid <= kp, 1, 'last');


    % Calculating linear interpolation weights
    weight = (kp-kgrid(jlo))/(kgrid(jlo+1)-kgrid(jlo));


    % Calculate utility tomorrow
    if t == R-1                                             % Nex period the agent becomes retired and the value function
       eval = (1-weight)*VR(jlo,1) + weight*VR(jlo+1,1);    % Is calculated using retirement period, so VR for the first period of retirement is used Fkp
    else
       eval = 0;
       for izp = 1:nz
           V_hat = (1-weight)*V(jlo,izp,t+1) + weight*V(jlo+1,izp,t+1);  % For years before that, value function is calculated using interpolation weights
           eval = eval + N(iz,izp) * V_hat;                              % Expected value function using transition matrix for productivy shocks
       end 
    end 
    
    % Calculating total value
    f = u + beta*eval;
    f = -f;                   % fmindbn minimizes, negating for maximization


end
