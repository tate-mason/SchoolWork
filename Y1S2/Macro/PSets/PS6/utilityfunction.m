

% Function for calculating utility function 

function u = utilityfunction(c,l)   % Value function with consumption and labor supply as arguments


    % Defining parametrs
    global mu sigma
    
    % Utility function:
    u = (((c^mu)*((1-l)^(1-mu)))^(1-sigma))/(1-sigma);
    
    % Labor supply is restricted to be less than 1
    if l > 1
        u = u - 10^(-4);
    end


end
