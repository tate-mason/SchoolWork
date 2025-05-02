function f = ufunc_R(kp, ik, t)
  global b beta kgrid r vR
  c = kgrid(ik)*(1+r) + b - kp;
  l = 0;
  u = utility(c, l);
  jlo = find(kgrid <= kp, 1, 'last');
  weight = (kp - kgrid(jlo)) / (kgrid(jlo+1) - kgrid(jlo));
  v_hat = (1-weight)*vR(jlo, t+1) + weight*vR(jlo+1, t+1);
  f = -u - beta*v_hat;
end
