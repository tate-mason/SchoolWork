using LinearAlgebra, Statistics
using Distributions, LaTeXStrings, Plots, Random, Symbolics, Latexify

"""
Let c be a real number lying strictly between -1 and 1.
* often denoted c ∈ (−1, 1).
* (-1,1) represents all real numbers between -1 and 1, 
not including -1 and 1 themselves.

We want to evaluate infinite and finite geometric series:
 - Infinite series: S = 1 + c + c^2 + c^3 + ... = 1/(1-c) for |c| < 1
 - Finite series: S_n = 1 + c + c^2 + ... + C^T = (1 - c^(T+1)) / (1 - c) for |c| < 1
"""

# 14.5.3 Application to Asset Pricing

# True PV of finite lease

function finite_lease_pv_true(T, g, r, x_0)
  G = 1 + g
  R = 1 + r
  return (x_0 * (1 - G^(T + 1) * R^(-T - 1))) / (1 - G * R^(-1))
end

# Approx of finite lease

function finite_lease_pv_approx(T, g, r, x_0)
  x_0 * (T + 1) + x_0 * r * g * (T + 1) / (r - g)
end

# Second Approx

finite_lease_pv_approx_2(T,g,r,x_0) = (x_0 * (T+1))

# Infinite Lease

infinite_lease(g, r, x_0) = x_0 / (1 - (1 + g) * (1 + r)^(-1))

T = 0:50
g = 0.02
r = 0.03
x_0 = 1

y_1 = finite_lease_pv_true.(T, g, r, x_0)
y_2 = finite_lease_pv_approx.(T, g, r, x_0)
y_3 = finite_lease_pv_approx_2.(T, g, r, x_0)

plt = plot(title = L"Finite Lease PV $T$ Periods Ahead",
           xlabel = L"$T$ Periods Ahead", ylabel = L"PV, $p_0$",
           legend = :topleft)

plot!(plt, T, y_1, label = L"True $T$-period Lease PV")
plot!(plt, T, y_2, label = L"$T$-period Lease F-O Approx.")
plot!(plt, T, y_3, label = L"$R$-period Lease F-O Approx., Adj.")

display(plt)
savefig(plt, "finite_lease_pv.pdf")

"""
For smaller values of T, the finite lease approximation is accurate. As we grow,
holding g and r constant, we see deterioration in the approximation.
"""

T = 0:1000
y_1 = finite_lease_pv_true.(T, g, r, x_0)
plt = plot(title = L"Infinite and Finite Lease PV $T$ Periods Ahead",
           xlabel = L"$T$ Periods Ahead", ylabel = L"PV, $p_0$",
           legend = :bottomright)
plot!(plt, T, y_1, label = L"$T$-period Lease PV")
hline!(plt, [infinite_lease(g, r, x_0)], linestyle = :dash,
      label = "Infinite Lease PV")
display(plt)
savefig(plt, "infinite_lease_pv.pdf")

"""
As T grows large, the finite lease PV converges to the infinite lease PV.
This is because as T approaches infinity, the term c^(T+1) in the finite
lease PV formula approaches zero for |c| < 1, leading the finite lease PV
to converge to the infinite lease PV formula.
"""

T = 0:10
plt = plot(title = L"Value of Lease of Length $T$", legend = :topleft,
           xlabel = L"$T$ periods ahead", ylabel = L"PV, $p_0$")
plot!(plt, finite_lease_pv_true.(T, 0.4, 0.9, x_0),
      label = L"Lease PV with $g=0.4 \gg r=0.9$")
plot!(plt, finite_lease_pv_true.(T, 0.4, 0.5, x_0),
      label = L"Lease PV with $g=0.4 < r=0.5$")
plot!(plt, finite_lease_pv_true.(T, 0.4, 0.4001, x_0),
      label = L"Lease PV with $g=0.4 \approx r=0.4001$")
plot!(plt, finite_lease_pv_true.(T, 0.5, 0.4, x_0),
      label = L"Lease PV with $g=0.5 > r=0.4$")
display(plt)
savefig(plt, "lease_value_different_g_r.pdf")


"""
Using Symbolics.jl, we can look at the derivation of why p_0 varies with
different values of g and r.
"""

@variables g, r, x_0
G = (1 + g)
R = (1 + r)
p0 = x_0 / (1 - G * R^(-1))
print("The Formula is")
latexify(p0) |> s -> render(s)

dg = Differential(g)
dp_dg = expand_derivatives(dg(p0))
print("The derivative of p_0 with respect to g is")
latexify(dp_dg) |> s -> render(s)

dr = Differential(r)
dp_dr = expand_derivatives(dr(p0))
print("The derivative of p_0 with respect to r is")
latexify(dp_dr) |> s -> render(s)

# Keynesian Multiplier

function calculate_y(i, b, g, T, y_init)
  y = zeros(T + 1)
  y[1] = i + b * y_init + g
  for t in 2:(T+1)
    y[t] = b * y[t-1] + i + g
  end
  return y
end

i_0 = 0.3
g_0 = 0.3
b = 2 / 3
y_init = 0
T = 100

plt = plot(0:T, calculate_y(i_0, b, g_0, T, y_init),
           title = "Path of Agg. Output Over Time",
           ylim = (0.5, 1.9), xlabel = L"t", ylabel = L"y_t")
hline!([i_0 / (1 - b) + g_0 / (1 - b)], linestyle = :dash,
       seriestype = "hline", legend = false)

bs = round.([1 / 3, 2 / 3, 5 / 6, 0.9], digits = 2)

plt = plot(title = "Changing Consumption as a Fraction of Income",
           xlabel = L"t", ylabel = L"y_t", legend = :topleft)
[plot!(plt, 0:T, calculate_y(i_0, b, g_0, T, y_init),
      label = L"b = $b") for b in bs]
display(plt)
savefig(plt, "keynesian_multiplier.pdf")

x = 0:T
y_0 = calculate_y(i_0, b, g_0, T, y_init)
l = @layout [a;b]

i_1 = 0.4
y_1 = calculate_y(i_1, b, g_0, T, y_init)

plt_1 = plot(x, y_0, label = L"$i = 0.3$", linestyle = :dash,
             title = "An Increase in Investment on Output",
             xlabel = L"$t$", ylabel = L"$y_t$",
             legend = :bottomright)
plot!(plt_1, x, y_1, label = L"$i = 0.4$")

g_1 = 0.4
y_1 = calculate_y(i_0, b, g_1, T, y_init)
plt_2 = plot(x, y_0, label = L"$g = 0.3$", linestyle = :dash,
             title = "An Increase in Government Spending on Output",
             xlabel = L"$t$", ylabel = L"$y_t$",
             legend = :bottomright)

plot!(plt_2, x, y_1, label = L"$g = 0.4$")
plot(plt_1, plt_2, layout = l)
savefig("increase_in_investment.pdf")
