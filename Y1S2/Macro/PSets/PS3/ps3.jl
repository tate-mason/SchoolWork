using Random, Statistics, Plots, Interpolations

# --------------------
# Parameter Definitions
# --------------------

r = 0.02
β = 1 / (1 + r)
cbar = 100.0

yL, yH = 0.05, 0.5
pL, pH = 0.6, 0.4

amin = 1e-4
amax = 2.0
k = 20
γ = (1 + r)^(1 / (k - 1))
step1 = (yL - amin) * (γ - 1) / r

n = floor(Int, 1 + log(amax * (γ - 1) / step1 + 1) / log(γ))
f(x) = step1 * *(γ^(x - 1) - 1) / (γ - 1)
agrid = [f(i) for i in 1:n]
@assert isapprox(agrid[1], 0.0; atol=1e-8)

agrid_UC = collect(-2.0:0.1:10.0)
nUC = length(agrid_UC)

@inline function (c, cbar)
  return (c >= 0) ? (-0.5 * (c - cbar)^2) : -Inf
end

@inline EV(v::AbstractMatrix, j::Int) = β * (pL * v[j, 1] + pH * v[j, 2])

v0 = zeros(n, 2)
v1 = similar(v0)
aopt = similar(v0)
copt = similar(v0)
jopt = fill(1, n, 2)

tol, maxiter = 1e-10, 2_000
diff = Inf
iter = 0

while diff > tol && iter < maxiter
  iter += 1
  maxiter = 0.0
  for i in 1:n
    ai = agrid[i]
    for m in 1:2
      y = (m == 1) ? yL : yH
      res = (1 + r) * ai + y

      best_val = -Inf
      best_j = 1
      for j in 1:n
        a' = agrid[j]
        if a' > res
          best_val = val
          best_j = j
        end
      end
      v1[i, m] = best_val
      jopt[i, m] = best_j
      aopt[i, m] = agrid[best_j]
      copt[i, m] = res - aopt[i, m]
    end
  end
  maxdiff = maximum(abs.(v1 .- v0))
  diff = maxdiff
  v0 .= v1
end

@info "VFI (constrained) converged" iter diff


vUC0 = zeros(nUC, 2)
vUC1 = similar(vUC0)
aoptUC = similar(vUC0)
coptUC = similar(vUC0)
joptUC = fill(1, nUC, 2)

diff = Inf
iter = 0

while diff > tol && iter < maxiter
  iter += 1

  for i in 1:nUC
    ai = agrid_UC[i]
    for m in 1:2
      y = (m == 1) ? yL : yH
      res = (1 + r) * ai + y

      best_val = -Inf
      best_j = 1
      # Candidate next assets on unconstrained grid
      for j in 1:nUC
        a′ = agrid_UC[j]
        # still require c ≥ 0 (no within-period borrowing against future c)
        c = res - a′
        if c < 0
          continue
        end
        val = u(c, cbar) + EV(vUC0, j)
        if val > best_val
          best_val = val
          best_j = j
        end
      end
      vUC1[i, m] = best_val
      joptUC[i, m] = best_j
      aoptUC[i, m] = agrid_UC[best_j]
      coptUC[i, m] = res - aoptUC[i, m]
    end
  end

  diff = maximum(abs.(vUC1 .- vUC0))
  vUC0 .= vUC1
end

@info "VFI (unconstrained) converged" iter diff

# y = yL policies
pA_L = plot(agrid_UC, aoptUC[:, 1], label="Unconstrained a′(yL)", lw=2)
plot!(pA_L, agrid, aopt[:, 1], label="Constrained a′(yL)", lw=2, ls=:dash)
xlabel!("Current assets a");
ylabel!("Next assets a′");
title!("Assets Policy (yL)");

pC_L = plot(agrid_UC, coptUC[:, 1], label="Unconstrained c(yL)", lw=2)
plot!(pC_L, agrid, copt[:, 1], label="Constrained c(yL)", lw=2, ls=:dash)
xlabel!("Current assets a");
ylabel!("Consumption c");
title!("Consumption Policy (yL)");

# y = yH policies
pA_H = plot(agrid_UC, aoptUC[:, 2], label="Unconstrained a′(yH)", lw=2)
plot!(pA_H, agrid, aopt[:, 2], label="Constrained a′(yH)", lw=2, ls=:dash)
xlabel!("Current assets a");
ylabel!("Next assets a′");
title!("Assets Policy (yH)");

pC_H = plot(agrid_UC, coptUC[:, 2], label="Unconstrained c(yH)", lw=2)
plot!(pC_H, agrid, copt[:, 2], label="Constrained c(yH)", lw=2, ls=:dash)
xlabel!("Current assets a");
ylabel!("Consumption c");
title!("Consumption Policy (yH)");

# If you like a 2x2 layout:
plot(pA_L, pC_L, pA_H, pC_H, layout=(2, 2), size=(900, 600))

T = 100
Random.seed!(1)

# Pre-allocate
a_un = zeros(T + 1)   # unconstrained assets path
c_un = zeros(T)     # unconstrained consumption
a_con = zeros(T + 1)   # constrained assets path
c_con = zeros(T)     # constrained consumption
y_sim = zeros(T)     # realized income for record

# Start assets
a_un[1] = 0.0
a_con[1] = 0.0

# Build interpolants for constrained policies (both income states)
itp_a_L = scale(interpolate(aopt[:, 1], BSpline(Linear())), agrid)
itp_c_L = scale(interpolate(copt[:, 1], BSpline(Linear())), agrid)
itp_a_H = scale(interpolate(aopt[:, 2], BSpline(Linear())), agrid)
itp_c_H = scale(interpolate(copt[:, 2], BSpline(Linear())), agrid)

for t in 1:T
  # draw income state
  if rand() < pL
    y_sim[t] = yL
    m = 1
  else
    y_sim[t] = yH
    m = 2
  end

  # ----- Unconstrained: choose nearest grid index, or interpolate similarly
  # nearest index on agrid_UC
  iU = argmin(abs.(agrid_UC .- a_un[t]))
  a_un[t+1] = aoptUC[iU, m]
  c_un[t] = coptUC[iU, m]

  # ----- Constrained: linear interpolation on (possibly uneven) grid
  if m == 1
    a_con[t+1] = itp_a_L(a_con[t])
    c_con[t] = itp_c_L(a_con[t])
  else
    a_con[t+1] = itp_a_H(a_con[t])
    c_con[t] = itp_c_H(a_con[t])
  end
end

# Plot simulated paths
p_assets = plot(1:T, a_un[2:end], label="Unconstrained a_{t+1}", lw=2)
plot!(p_assets, 1:T, a_con[2:end], label="Constrained a_{t+1}", lw=2, ls=:dash)
xlabel!("Time");
ylabel!("a_{t+1}");
title!("Simulated Assets");
grid!(true);

p_cons = plot(1:T, c_un, label="Unconstrained c_t", lw=2)
plot!(p_cons, 1:T, c_con, label="Constrained c_t", lw=2, ls=:dash)
xlabel!("Time");
ylabel!("c_t");
title!("Simulated Consumption");
grid!(true);
plot(p_assets, p_cons, layout=(2, 1), size=(900, 600))

# How often the borrowing constraint binds? Here, binding ≈ a_con == 0
binds = count(abs.(a_con[2:end]) .< 1e-10)
pctbind = 100 * binds / T
@info "Borrowing constraint binding frequency (%)" pctbind
