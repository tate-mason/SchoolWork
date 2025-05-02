function u = utility(c,l)
  global mu sigma

  u = (((c^mu)*(1-l)^(1-mu)))^(1-sigma)/(1-sigma);

  if l > 1
    u = u - 10e-6;
  end
end
