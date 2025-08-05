function [x,w]=ghquad(n,maxit);
% Adapted from: Press, et al. Numerical Recipes in Fortran, 2nd ed.
% Returns the abscissas (x) and weights (w) for Gauss-Hermite
% quadrature of order n.
% This is used to compute integrals of the form
%    int(exp(-x^2)f(x))
% over the whole real line.
% The integral is computed as w'f(x);
% The integration will be exact for any polynomial f(x) of order
% less than 2n. maxit - maximum iteratioins.
% Example:
%   To compute the integral of the function exp(-x^2)(x^4+10) use:
%   [x,w]=ghquad(3);
%   int=w'(x^4+10);
% 
% To convert these abscissas and weights to those appropriate for
% computing moments of the standard normal distribution
% multiply the abscissas by sqrt(2) and divide the weights by
% sqrt(pi).

  tol=100;
  pim4=1/pi^0.25;
  m=fix((n+1)/2);
  x=zeros(n,1);
  w=x;
  i=0; 
  while i<m;i=i+1;
    if i==1;z=sqrt(2*n+1)-1.85575*((2*n+1)^(-1/6));
      elseif i==2; z=z-1.14*(n^0.426)/z;
      elseif i==3; z=1.86*z-0.86*x(1);
      elseif i==4;z=1.91*z-0.91*x(2);
      else; z=2*z-x(i-2);
    end;
    its=0;
         while its<maxit; its=its+1;
            p1=pim4;
            p2=0;
            j=0; 
                while j<n;j=j+1;
                    p3=p2;
                    p2=p1;
                    p1=z.*sqrt(2/j).*p2-sqrt((j-1)/j).*p3;
                end;
            pp=sqrt(2*n).*p2;
            z1=z;
            z=z1-p1./pp;
            if abs(z-z1)<1e-14; break; end;
            
          end;
    if its>=maxit; disp('Exceeded allowable iterations in finding root'); end;
      
    x(n+1-i)=-z;
    x(i)=z;
    w(i)=2/(pp.*pp);
    w(n+1-i)=w(i);
   end;
  x=flipdim(x,1);
