using Distributions, Random, Statistics, LinearAlgebra
using DataFrames, CSV, Chain, DataFramesMeta, StatsBase
using GLM, FixedEffectModels, Econometrics, RegressionTables, Optim, NLsolve
using Plots, StatsPlots
using LaTeXStrings, Latexify

"""
This is an attempt to translate the code for Problem Set 3 from
R to Julia. 
"""

"""
Problem 1: Load Data and Create Summary Statistics
 - First, load the data from the CSV file "Data/prod_level_data.csv",
 - Then, clean the data by pivoting it to long format
 - Finally, create a summary statistics table
 - Further, make scatter plots to see correlation b/w characteristics and share
"""

# Data Loading

main_data = CSV.read("Data/prod_level_data.csv", DataFrame)

main_long = @chain main_data begin
  stack(_,
      r"^(x|p|ave_dist|s|mc)\d+$",
      variable_name=:var,
      value_name=:value)
  transform(:var => ByRow(x -> replace(x, r"\d+" => "")) => :base)
  transform(:var => ByRow(x -> parse(Int, replace(x, r"\D+" => ""))) => :prod)
  unstack([:market, :prod], :base, :value)
  sort([:market, :prod])
end

first(main_data, 5) |> display

# Summary Statistics Table

summ_tab = @chain main_long begin
  select(_, [:x, :p, :ave_dist, :s, :mc])
  describe(_, :mean, :std, :min, :max, :nmissing)
end

summ_tab |> display

# Scatter Plots

## Price vs Share

pps_plt = plot(main_long.p, main_long.s,
     seriestype = :scatter,
     title = "Price vs Market Share",
     xlabel = "Price (p)",
     ylabel = "Market Share (s)",
     legend = false)
## Rating vs Share
pxs_plt = plot(main_long.x, main_long.s,
     seriestype = :scatter,
     title = "Rating vs Market Share",
     xlabel = "Rating (x)",
     ylabel = "Market Share (s)",
     legend = false)
## Average Distance vs Share
adxs_plt = plot(main_long.ave_dist, main_long.s,
     seriestype = :scatter,
     title = "Average Distance vs Market Share",
     xlabel = "Average Distance (ave_dist)",
     ylabel = "Market Share (s)",
     legend = false)

## Put all plots in one figure
plot_layout = @layout [a b; c d]
plot(pps_plt, pxs_plt, adxs_plt,
     layout = plot_layout,
     size = (800, 600))
## Save the plot
savefig("Outputs/problem1_scatter_plots.png")

"""
Problem 2: Estimate Linear Models
  - First naive OLS
  - Then IV for price
  - Finally IV for price and average distance
"""

# Naive OLS
## Create s0 and ln_s0

main_reg = @chain main_long begin
  groupby(:market)
  @transform(:s0 = 1 .- sum(:s))
  @transform(:l_s = log.(:s) .- log.(:s0))
  select(_, Not([:s0]))
end

## Estimate OLS
ols_mn2 = lm(@formula(l_s ~ x + p), main_reg)
## Display results
coeftable(ols_mn2) |> display
summary(ols_mn2)   |> display
# IV for Price
## Estimate IV
iv_mn2 = reg(main_reg, @formula(l_s ~ 1 + x + (p ~ mc)))
## Display results
coeftable(iv_mn2) |> display
summary(iv_mn2) |> display
# IV for Price and Average Distance
## Estimate IV
iv2_mn2 = reg(main_reg, @formula(l_s ~ 1 + x + ave_dist + (p ~ mc)))
## Display results
coeftable(iv2_mn2) |> display
summary(iv2_mn2) |> display

"""
Problem 3: GMM Estimation of Exogenous Choice Set
  - First, load in search set data
  - Then, define GMM and Helper functions
  - Finally, estimate the model via Optim
"""

# Load Search Set Data
search_data = CSV.read("Data/search_set_data.csv", DataFrame)
first(search_data, 5) |> display

# Pivot the search data and create search matrix
min_market = minimum(skipmissing(search_data.market))

s_mat = @chain search_data begin
  @subset(:market .== min_market)
  select(:prod1, :prod2, :prod3, :prod4)
  Matrix
end

@assert size(s_mat, 1) == 16 && size(s_mat, 2) == 4         

df4 = @chain main_long begin
  @transform(:prod = Int.(:prod))
  sort([:market, :prod])
  groupby(:market)
  @subset(:s .> 0)
  @transform(:s_clamped = max.(:s, 1e-12))
  @transform(:s0 = max.(1 .- sum(:s_clamped), 1e-12))
  @transform(:delta = log.(:s_clamped) .- log.(:s0))
  select(Not(:s_clamped))
  DataFrame
end
first(df4, 5) |> display

# Helper Functions

n = nrow(df4)
dfZ = transform(df4, [:s] => (_ -> 0.0) => :y)
fZ = @formula(y ~ 1 + x + ave_dist + mc)
Z = modelmatrix(fZ, dfZ)
W = (Z'*Z) / n

eps = 1e-12

delta0 = copy(df4.delta)

idx_vec = let
  df = DataFrame(idx = 1:n, market = df4.market)
  groups = groupby(df, :market)
  [collect(g.idx) for g in groups]
end

σ(x) = 1 ./ (1 .+ exp.(-x))

function pifunc(mu::Float64, ave_dist::Vector{Float64}; eps::Float64 = 1e-12)
  pi = σ.(10 .+ mu .* ave_dist)
  return clamp.(pi, eps, 1.0 - eps)
end

function predict_share(delta::AbstractVector{<:Real},
                       pi::AbstractVector{<:Real},
                       s_mat::AbstractMatrix{<:Real})
  fixer = max(0.0, maximum(delta))
  exp_fix = exp.(delta .- fixer)
  denom = exp(-fixer) .+ vec(s_mat * exp_fix)

  logP = vec(s_mat * log.(pi) .+ (1 .- s_mat) * log.(1 .- pi))
  P = exp.(logP)

  con_P = s_mat .* permutedims(exp_fix)
  con_P ./= denom

  s_hat = vec(sum(con_P .* P, dims = 1))
  return s_hat
end

function con_map(mu,
                 delta_init,
                 df,
                 idx_vec,
                 s_mat;
                 tol = 1e-10,
                 max_iter = 1_000)
  eps = 1e-12

  s_obs = max.(df.s, eps)
  ave_dist_vec = coalesce.(df.ave_dist, 0.0)
  pi_all = pifunc(mu, ave_dist_vec; eps=eps)

  delta = copy(delta_init)
  diff = Inf

  for iter in 1:max_iter
    s_hat = similar(delta)

    for idx in idx_vec
      s_hat[idx] = predict_share(delta[idx], pi_all[idx], s_mat)
    end
    s_hat = max.(s_hat, eps)
    delta_new = delta .+ log.(s_obs) .- log.(max.(s_hat, 1e-12))

    diff = maximum(abs.(delta_new .- delta))
    delta .= delta_new

    if isfinite(diff) && diff < tol
      return (delta = delta, converged = true, iter = iter, diff = diff)
    end
  end
  return (delta = delta, converged = false, iter = max_iter, diff = diff)
end

delta_last_ref = Ref(copy(delta0))
delta_last = copy(delta0)

function gmm_exog(theta::AbstractVector{<:Real})
  global delta_last

  beta0 = theta[1]
  beta1 = theta[2]
  alpha = theta[3]
  mu    = theta[4]


  cm = con_map(
    mu,
    delta_last,
    df4,
    idx_vec,
    s_mat;
    tol = 1e-12,
    max_iter = 100_000
  )
  if !cm.converged || any(!isfinite, cm.delta) || maximum(abs.(cm.delta)) > 1e3
    return 1e12
  end
  
  delta_last = cm.delta
  xi = cm.delta

  Q = (Z' * xi) ./ n
  obj = (Q' * W * Q)[1]
  if !isfinite(obj)
    obj = 1e12
  end
  return obj
end

if @isdefined iv2_mn2
  b = coef(iv2_mn2)
  theta_init = [
    b[1],
    b[2 ],
    b[3 ],
    -1.0
  ]
else
  theta_init = [1.0, 0.2, -0.25, 0.0]
end

obj(theta) = gmm_exog(theta)

opts = Optim.Options(iterations = 10_000, x_abstol = 1e-8)

res = optimize(
  obj,
  theta_init,
  NelderMead(),
  opts
)
theta_hat = Optim.minimizer(res)
obj_val = Optim.minimum(res)
convergence = Optim.converged(res)

resolve = con_map(
  theta_hat[4],
  delta0,
  df4,
  idx_vec,
  s_mat;
  tol = 1e-12,
  max_iter = 100_000
)
@assert resolve.converged
delta_hat = resolve.delta
# Display Results
println("GMM Estimation Results:")
println("Theta Hat: ", theta_hat)
println("Objective Value: ", obj_val)
println("Convergence: ", convergence)

