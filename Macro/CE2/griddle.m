function g = griddle(a,b,n,p)
    gr = zeros(1,n);
    gr(1) = a;
    gr(n) = b;
    for k = 2:n-1 
        gr(k) = a + (b-a)*((k-1)/(n-1))^p;
    end
    g = gr;
end