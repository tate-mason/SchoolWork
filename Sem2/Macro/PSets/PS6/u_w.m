function f = ufunc_W(kp, ik, iz, t)
  global beta kgrid r vW w z_grid lambda tau n_z mu P vR
  
  l = ((mu*w*exp(z_grid(iz))*lambda(t,2)*(1-tau))-((1-mu)*(kgrid(ik)*(1+r)-kp)))/(w*exp(z_grid(iz))*lambda(t,2)*(1-tau));
  if l < 0
    l = 0;
  elseif l > 1
    l = 1;
  end

  y = w*exp(z_grid(iz))*lambda(t,2)*l;
  c = kgrid(ik)*(1+r) + y - kp;

  u = utility(c, l);

  jlo = find(kgrid <= kp, 1, 'last');
  weight = (kp - kgrid(jlo)) / (kgrid(jlo+1) - kgrid(jlo));

  if t == R-1
    v_hat = (1-weight)*vR(jlo, iz) + weight*vR(jlo+1, iz);
  else
    eval = 0;
    for izp = 1:n_z
      eval = eval + P(iz, izp)*vW(jlo, izp, t+1);
    end
  end
  f = -u - beta*eval;
end
