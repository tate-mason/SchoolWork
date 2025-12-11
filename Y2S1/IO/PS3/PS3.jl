using CSV, DataFrames, StatsBase, GLM, StatsPlots, Optim, LinearAlgebra
gr()

# Load the dataset
df = CSV.read("Data/prod_level_data.csv", DataFrame)
print(first(df, 5))

# Data Cleaning
## Make long

nM = nrow(df)
J = 4

long = DataFrame(
  market = repeat(df.market, inner = J),
  product = repeat(1:J, outer = nM),
)

# Wide peel helper

function add_long!(long, df, varname::Symbol, prefix::String, J::Int)
  cols = [Symbol(prefix * string(j)) for j in 1:J]
  mat = Matrix(df[:, cols])
  long[!, varname] = vec(mat)
end

add_long!(long, df, :x, "x", J)
add_long!(long, df, :p, "p", J)
add_long!(long, df, :s, "s", J)
add_long!(long, df, :ave_dist, "ave_dist", J)
add_long!(long, df, :mc, "mc", J)

print(first(long, 8))

"""
Getting descripting statistics and plotting
"""

# Summary statistics
vars = [:x, :p, :s, :ave_dist, :mc]

summ_tab = combine(
  long,
  [v => mean => Symbol(string(v), "_mean") for v in vars]...,
  [v => std => Symbol(string(v), "_std") for v in vars]...,
  [v => minimum => Symbol(string(v), "_min") for v in vars]...,
  [v => maximum => Symbol(string(v), "_max") for v in vars]...,
  [v => median => Symbol(string(v), "_median") for v in vars]...
)
print(summ_tab)

# Save summary statistics to a txt file
open("Outputs/PS3_summary_statistics.txt", "w") do io
    show(io, summ_tab)
end

# Scatter Plots

## Rating vs Share

x_rate = lm(@formula(s ~ x), long)
xgrid = range(minimum(long.x), stop = maximum(long.x), length = 100)
yhat = predict(x_rate, DataFrame(x = xgrid))

rate_share = @df long scatter(
  :x, :s,
  xlabel = "Rating",
  ylabel = "Market Share",
  title = "Rating vs Market Share",
)

rate_share_lbf = plot!(
  xgrid,
  yhat,
  lw = 2,
)

## Price vs Share

p_rate = lm(@formula(s ~ p), long)
pgrid = range(minimum(long.p), stop = maximum(long.p), length = 100)
yhat_p = predict(p_rate, DataFrame(p = xgrid))

price_share = @df long scatter(
  :p, :s,
  xlabel = "Price",
  ylabel = "Market Share",
  title = "Price vs Market Share",
)

price_share_lbf = plot!(
  xgrid,
  yhat_p,
  lw = 2,
)

## Distance vs Share

d_rate = lm(@formula(s ~ ave_dist), long)
dgrid = range(minimum(long.ave_dist), stop = maximum(long.ave_dist), length = 100)
yhat_d = predict(d_rate, DataFrame(ave_dist = dgrid))

dist_share = @df long scatter(
  :ave_dist, :s,
  xlabel = "Average Distance",
  ylabel = "Market Share",
  title = "Average Distance vs Market Share",
)

dist_share_lbf = plot!(
  dgrid,
  yhat_d,
  lw = 2,
)

# Display Plots
plot(rate_share_lbf, price_share_lbf, dist_share_lbf, layout = (3, 1))
savefig("Outputs/PS3_descriptive_plots.pdf")

"""
Estimating under complete information

1. Naive OLS estimation
2. IV estimation - price instrument (mc)
3. IV estimation - price + distance (mc, ave_dist)
"""

# Logit shares

g = groupby(long, :market)
long_sout = combine(g) do sub
  s_in = clamp.(sub.s, 1e-8, 1.0)  # Avoid log(0)
  s_out = 1 .- sum(sub.s)
  s_out = max(s_out, 1e-8)  # Avoid log(0)
  DataFrame(market = sub.market,
            product = sub.product,
            x = sub.x,
            p = sub.p,
            s = sub.s,
            ave_dist = sub.ave_dist,
            mc = sub.mc,
            s_out = fill(s_out, nrow(sub)))
end

long_sout.logit_s = log.(long_sout.s .- log.(long_sout.s_out))
print(first(long_sout, 8))

# 1. Naive OLS estimation
ols_model = lm(@formula(logit_s ~ x + p), long_sout)
print(coeftable(ols_model))

# 2. IV estimation - price instrument (mc)
fs = lm(@formula(p ~ x + mc), long)
long_sout.p_hat = predict(fs, long)

iv_model_mc = lm(@formula(logit_s ~ x + p_hat), long_sout)
print(coeftable(iv_model_mc))

# 3. IV estimation - price + distance (mc, ave_dist)
fs2 = lm(@formula(p ~ x + mc + ave_dist), long)
long_sout.p_hat2 = predict(fs2, long)
iv_model_mc_dist = lm(@formula(logit_s ~ x + p_hat2), long_sout)
print(coeftable(iv_model_mc_dist))
# Save model summaries to text files
open("Outputs/PS3_model_summaries.txt", "w") do io
    write(io, "Naive OLS Estimation:\n")
    show(io, coeftable(ols_model))
    write(io, "\n\nIV Estimation - Price Instrument (mc):\n")
    show(io, coeftable(iv_model_mc))
    write(io, "\n\nIV Estimation - Price + Distance (mc, ave_dist):\n")
    show(io, coeftable(iv_model_mc_dist))
end

"""
GMM estimation under incomplete information, exogenous choice set formation
"""

# 1. Load search-set data and reshape
using CSV, DataFrames

df_search = CSV.read("Data/search_set_data.csv", DataFrame)

# add set_id within each market before stacking
g0 = groupby(df_search, :market)
df_search.set_id = similar(df_search.market)
for g in g0
    idx = parentindices(g)[1]
    df_search.set_id[idx] .= 1:nrow(g)
end

search_long = stack(
    df_search,
    [:prod1, :prod2, :prod3, :prod4],
    variable_name = :product,
    value_name    = :in_set,
)

search_long.product = parse.(Int, replace.(String.(search_long.product), "prod" => ""))

search_sorted = sort(search_long, [:market, :set_id, :product])

long_sorted = sort(long, [:market, :product])

markets = unique(long_sorted.market)
nM = length(markets)
J  = length(unique(long_sorted.product))

@assert nrow(long_sorted) == nM * J

s_obs_vec = clamp.(long_sorted.s, 1e-12, 1.0)
s_obs = reshape(s_obs_vec, (J, nM))'   # (nM, J)

using DataFrames

check_sets = combine(
    groupby(search_sorted, [:market, :set_id]),
    nrow      => :n,
    :product  => minimum => :minprod,
    :product  => maximum => :maxprod,
)

println(first(check_sets, 20))

bad = filter(row -> row.n != 4 || row.minprod != 1 || row.maxprod != 4, check_sets)
println("Number of bad (market, set_id) groups: ", nrow(bad))
if nrow(bad) > 0
    println("Example bad groups:")
    println(first(bad, min(10, nrow(bad))))
end

function model_shares_exog(delta::AbstractMatrix,
                           theta::AbstractVector,
                           long_sorted::DataFrame,
                           search_sorted::DataFrame)

    β0, β1, α, μ = theta
    nM, J = size(delta)

    s_model = zeros(nM, J)

    g_long   = groupby(long_sorted, :market)
    g_search = groupby(search_sorted, :market)

    @assert length(g_long) == nM == length(g_search)

    for (m_idx, (sub_long, sub_search)) in enumerate(zip(g_long, g_search))
        @assert nrow(sub_long) == J

        # π_jt from ave_dist
        ave = collect(sub_long.ave_dist)
        η   = clamp.(10 .+ μ .* ave, -700.0, 700.0)
        π   = 1.0 ./ (1.0 .+ exp.(-η))   # length J

        δm = vec(delta[m_idx, :])
        s_m = zeros(J)

        g_sets = groupby(sub_search, :set_id)

        for S in g_sets
            # Build Boolean mask of length J using product & in_set
            inS = falses(J)
            for r in eachrow(S)
                j = Int(r.product)         # product ∈ {1,2,3,4}
                @assert 1 ≤ j ≤ J
                inS[j] = (r.in_set == 1)
            end

            if !any(inS)
                continue
            end

            # P_t(S) = ∏_{j∈S} π_jt ∏_{j∉S} (1-π_jt)
            p_in  = prod(π[inS])
            p_out = prod(1 .- π[.!inS])
            P_S   = p_in * p_out

            if P_S <= 0.0
                continue
            end

            # conditional logit within S
            δS = δm[inS]
            mδ = maximum(δS)
            expδS = exp.(δS .- mδ)
            denom = 1.0 + sum(expδS)
            if !isfinite(denom) || denom <= 0
                return nothing
            end

            P_j_given_S = expδS ./ denom

            idx = findall(inS)
            @inbounds s_m[idx] .+= P_S .* P_j_given_S
        end

        s_model[m_idx, :] .= s_m
    end

    if any(isnan, s_model) || any(!isfinite, s_model)
        return nothing
    end

    return s_model
end

function invert_delta(theta::AbstractVector,
                      long_sorted::DataFrame,
                      search_sorted::DataFrame,
                      s_obs::AbstractMatrix;
                      max_iter::Int    = 50_000,
                      tol::Float64     = 1e-4,
                      damping::Float64 = 0.5)

    nM, J = size(s_obs)
    delta = zeros(nM, J)

    # clamp observed shares once
    s_obs_clamped = clamp.(s_obs, 1e-12, 1.0)

    for it in 1:max_iter
        s_model = model_shares_exog(delta, theta, long_sorted, search_sorted)
        if s_model === nothing
            @warn "model_shares_exog returned nothing in contraction" theta iter=it
            return nothing, false   # HARD failure
        end

        # clamp model shares to avoid log(0)
        s_model_clamped = clamp.(s_model, 1e-12, 1.0)

        diff    = log.(s_obs_clamped) .- log.(s_model_clamped)
        maxdiff = maximum(abs.(diff))

        if !isfinite(maxdiff)
            @warn "Non-finite maxdiff in contraction" theta maxdiff
            return nothing, false   # HARD failure
        end

        # damped update
        delta .+= damping .* diff

        if maxdiff < tol
            @info "Contraction converged in $it iterations" theta maxdiff
            return delta, true      # converged
        end
    end

    # If we get here: no convergence, but numerically well-behaved.
    @warn "Contraction did not reach tol; using last iterate" theta
    return delta, true              # SOFT failure → treat as usable
end

function gmm_obj(theta_vec::AbstractVector)
    nM = length(markets)
    J  = length(unique(long_sorted.product))

    delta, ok = invert_delta(theta_vec, long_sorted, search_sorted, s_obs)
    if !ok || delta === nothing
        return 1e10   # only on true bad numerical failure
    end

    β0, β1, α, μ = theta_vec

    x_mat = reshape(collect(long_sorted.x), (J, nM))'
    p_mat = reshape(collect(long_sorted.p), (J, nM))'

    ξ_mat = delta .- (β0 .+ β1 .* x_mat .+ α .* p_mat)
    ξ_vec = vec(ξ_mat)

    Z = hcat(
        ones(nrow(long_sorted)),
        long_sorted.x,
        long_sorted.mc,
        long_sorted.ave_dist,
    )
    N = size(Z, 1)
    W = (size(Z, 2))   # simple identity

    g = (Z' * ξ_vec) / N
    return dot(g, W * g)
end

θ_test = [0.5, 0.1, -0.5, 0.0]

delta_test, ok_test = invert_delta(θ_test, long_sorted, search_sorted, s_obs)
@show ok_test

theta_start = [0.5, 0.1, -0.1, 0.0]
lower = [-Inf, -Inf, -Inf, -5.0]
upper = [Inf, Inf, Inf, 5.0]

res = optimize(
  gmm_obj,
  lower,
  upper,
  theta_start,
  Fminbox(BFGS())
)

theta_hat = Optim.minimizer(res)
println("GMM Estimates under Exogenous Search Set Formation:")
println(theta_hat)
Q_hat = Optim.minimum(res)
println("GMM Objective Function Value at Optimum: ")
println(Q_hat)


