module MigCalibration

using Random 
using LinearAlgebra
using Optim 
using StatsBase: Weights, sample 
using Plots 
using Distributions

# =========================
# 1. Environment Container
# =========================

"""
DataEnv will hold all exogenous objects for the model.

Conventions:
- Ages are discrete s.t. t = 40:80. Indexed 1:T
- Z locations are discrete s.t. z = 1:51. Indexed 1:Z
- Workers: Use wage and rent arrays
- Retirees: Use pension*wage and healthcare cost arrays
"""

struct DataEnv
  Z::Int                # number of states
  ages::Vector{Int}     # 40:80
  β::Float64            # discount factor
  σ::Float64            # CRRA coefficient
  prob_retire::Float64  # probability of retiring each year (x in model)
  prob_death::Float64   # probability of death each year (y in model)
  pension_rate::Float64 # pension replacement rate
  amenW_base::Vector{Float64} # base amenity for workers by state
  amenR_base::Vector{Float64} # base amenity for retirees by state

  # state x age profiles
  wage::Matrix{Float64}     # pre-tax labor income potential
  tax::Matrix{Float64}      # average tax rate in [0,1]
  rent::Matrix{Float64}     # rental housing cost
  hc_cost::Matrix{Float64}  # healthcare cost for retirees

  # Initial distributions over locations
  init_dist_40::Vector{Float64}  # initial distribution at age 40
end

function check_env(env::DataEnv)
  T = length(env.ages)
  @assert size(env.wage) == (env.Z, T)
  @assert size(env.tax) == (env.Z, T)
  @assert size(env.rent) == (env.Z, T)
  @assert size(env.hc_cost) == (env.Z, T)
  @assert length(env.amenW_base) == env.Z
  @assert length(env.amenR_base) == env.Z
  @assert length(env.init_dist_40) == env.Z
  @assert abs(sum(env.init_dist_40) - 1.0) < 1e-8
end

# =========================
# 2. Preference and Utility
# =========================

"""
CRRA utility function. If c <= 0, return large negative utility.
"""

function u_crra(c::Float64, σ::Float64)
  if c <= 0
    return -1e10
  elseif σ == 1.0
    return log(c)
  else
    return (c^(1 - σ)) / (1 - σ)
  end
end

"""
Compute per-period flow utility for workers in location z at age t.

No shocks here. Shocks enter in logit choice.
"""

function worker_flow_utility(env::DataEnv, z::Int, t::Int, αW::Float64)
  # disposable income net of tax and rent
  y = env.wage[z, t] * (1.0 - env.tax[z, t])
  c = y - env.rent[z, t]
  return u_crra(c, env.σ) + αW * env.amenW_base[z]
end

"""
Compute per-period flow utility for retirees in location z at age t.
"""

function retiree_flow_utility(env::DataEnv, z::Int, t::Int, αR::Float64)
  # disposable income net of tax and rent
  pension = env.pension_rate * env.wage[z, t]
  y = pension * (1.0 - env.tax[z, t])
  c = y - env.hc_cost[z, t]
  return u_crra(c, env.σ) + αR * env.amenR_base[z]
end

# ============================
# 3. Value Function Iteration
# ============================

"""
Solve Dynamic Programming problem via Value Function Iteration.
Return:
- Vw[t,z]: value function for workers at age t in location z
- Vr[t,z]: value function for retirees at age t in location z
- Pw[t,z]: choice probabilities for workers at age t in location z
- Pr[t,z]: choice probabilities for retirees at age t in location z

Embed moving cost γ in choice specific utilities.
Choices follow logit with i.i.d T1 extreme value shocks.
Implies V = log(sum(exp(utilities))) + discounted continuation
"""

function solve_model(env::DataEnv, γW::Float64, γR::Float64,
                     αW::Float64, αR::Float64;)
  check_env(env)

  Z = env.Z
  ages = env.ages
  T = length(ages)
  β = env.β
  pr = env.prob_retire
  pd = env.prob_death

  # allocate
  Vw = zeros(Float64, T, Z)
  Vr = zeros(Float64, T, Z)

  # choice probabilities: (T,Z,Z)
  Pw = zeros(Float64, T, Z, Z)
  Pr = zeros(Float64, T, Z, Z)

  # terminal: no future utility at age 80
  # backward induction
  for t in T:-1:1
    for z in 1:Z
      # -----Retiree-----
      u_stay_r = retiree_flow_utility(env, z, t, αR)
      cont_r_stay = 0.0
      if t < T
        cont_r_stay = β * (1.0 - pd) * Vr[t + 1, z]
      end
      util_r_stay = u_stay_r + cont_r_stay

      # moving options
      util_r = similar(Pr[t, z, :])
      denom_r = 0.0
      for zp in 1:Z
        if zp == z
          util_r[zp] = util_r_stay
        else
          u_move_r = retiree_flow_utility(env, zp, t, αR) - γR
          cont_r_move = 0.0
          if t < T
            cont_r_move = β * (1.0 - pd) * Vr[t + 1, zp]
          end
          util_r[zp] = u_move_r + cont_r_move
        end
        # logit
        denom_r += exp(util_r[zp])
      end
      # log-sum-exp for value function
      Vr[t, z] = log(denom_r)
      # choice probabilities
      for zp in 1:Z
        Pr[t, z, zp] = exp(util_r[zp]) / denom_r
      end
      # -----Worker-----
      u_stay_w = worker_flow_utility(env, z, t, αW)
      cont_w_stay = 0.0
      if t < T
        cont_w_stay = β * (
            (1.0 - pr) * Vw[t+1, z] +
            pr * Vr[t+1, z]
        )
      end
      util_w_stay = u_stay_w + cont_w_stay

      util_w = similar(Pw[t, z, :])
      denom_w = 0.0
      for zp in 1:Z
        if zp == z
          util_w[zp] = util_w_stay
        else
          u_move_w = worker_flow_utility(env, zp, t, αW) - γW
          cont_w_move = 0.0
          if t < T
            cont_w_move = β * (
                (1.0 - pr) * Vw[t+1, zp] +
                pr * Vr[t+1, zp]
            )
          end
          util_w[zp] = u_move_w + cont_w_move
        end
        denom_w += exp(util_w[zp])
      end
      Vw[t, z] = log(denom_w)
      for zp in 1:Z
        Pw[t, z, zp] = exp(util_w[zp]) / denom_w
      end
    end
  end
  return Vw, Vr, Pw, Pr
end

# ============================
# 4. Simulate Agents
# ============================

"""
Simulate a panel of agents from 40 to 80. 

Inputs:
  - θ = (γW, γR, αW, αR)
  - env: DataEnv
  - N: number of agents to simulate
Outputs:
A dictionary with keys:
  - p_move_40_50: fraction of agents moving between age 40 and 50
  - p_move_65p: fraction of agents moving after age 65
  - P_40_50: (Z,Z) migration matrix between age 40 and 50
  - P_65p: (Z,Z) migration matrix after age 65
"""

function simulate_model_moments(theta::NTuple{4,Float64},
                                env::DataEnv;
                                n_agents::Int = 100_000,
                                rng::AbstractRNG = Random.default_rng())

    γW, γR, αW, αR = theta
    check_env(env)

    Z     = env.Z
    ages  = env.ages
    T     = length(ages)

    # 1. Solve model once
    Vw, Vr, Pw, Pr_ = solve_model(env, γW, γR, αW, αR)

    # 2. Counters
    move_40_50 = 0
    obs_40_50  = 0

    move_65p = 0
    obs_65p  = 0

    flows_40_50 = zeros(Float64, Z, Z)
    flows_65p   = zeros(Float64, Z, Z)

    amin = minimum(env.ages)
    amax = maximum(env.ages)

    n_pairs = Int(floor((amax - amin) / 2)) + 1
    exp_pair = zeros(Float64, n_pairs)
    mov_pair = zeros(Float64, n_pairs)

    agepair_index(age) = begin
      if age < amin || age > amax
        return 0
      end
      Int(floor((age - amin) / 2)) + 1
    end
  

    # initial location distribution at 40
    init_w = Weights(env.init_dist_40)

    # 3. Simulate agents
    for n in 1:n_agents
        z = sample(rng, 1:Z, init_w)   # start location
        is_retired = false
        alive = true

        for t in 1:T
            if !alive
                break
            end

            age = ages[t]
            k = agepair_index(age)

            # exposure counts
            if 40 <= age <= 50
                obs_40_50 += 1
            end
            if age >= 65
                obs_65p += 1
            end
            if k > 0
                exp_pair[k] += 1.0
            end

            # choice probabilities for next location
            probs_vec = if is_retired
                collect(@view Pr_[t, z, :])
            else
                collect(@view Pw[t, z, :])
            end

            # guard against numerical junk
            s = sum(probs_vec)
            if !(s > 0.0) || !isfinite(s)
                fill!(probs_vec, 0.0)
                probs_vec[z] = 1.0
                s = 1.0
            end
            @inbounds probs_vec ./= s

            # draw next location
            zp = sample(rng, 1:Z, Weights(probs_vec))
            moved = (zp != z)

            # record moves and flows by age group
            if 40 <= age <= 50 && moved
                move_40_50 += 1
                flows_40_50[z, zp] += 1.0
            end
            if age >= 65 && moved
                move_65p += 1
                flows_65p[z, zp] += 1.0
            end
            if k > 0 && moved
                mov_pair[k] += 1.0
            end

            # death shock
            if rand(rng) < env.prob_death
                alive = false
                break
            end

            # retirement shock
            if !is_retired && rand(rng) < env.prob_retire
                is_retired = true
            elseif t >= 65
                is_retired = true
            end

            # update location
            z = zp
        end
    end

    # 4. Move probabilities
    p_move_40_50 = obs_40_50 > 0 ? move_40_50 / obs_40_50 : NaN
    p_move_65p   = obs_65p  > 0 ? move_65p   / obs_65p   : NaN
    p_move_pairs = [exp_pair[k] > 0 ? mov_pair[k] / exp_pair[k] : NaN for k in 1:n_pairs]

    agepair_starts = [amin + 2*(k-1) for k in 1:n_pairs]

    # 5. Normalize flows to get P(z'|z) among movers
    function normalize_flows(F::Matrix{Float64})
        P = copy(F)
        for i in 1:Z
            s = sum(P[i, :])
            if s > 0.0
                @inbounds P[i, :] ./= s
            end
        end
        return P
    end

    P_40_50 = normalize_flows(flows_40_50)
    P_65p   = normalize_flows(flows_65p)

    return Dict(
        :p_move_40_50 => p_move_40_50,
        :p_move_65p   => p_move_65p,
        :P_40_50      => P_40_50,
        :P_65p        => P_65p,
        :agepair_starts => agepair_starts,
        :p_move_pairs   => p_move_pairs,
        :exp_pair      => exp_pair,
        :mov_pair      => mov_pair
    )
end

# ============================
# 5. Calibration Objective
# ============================

"""
Quadratic loss between simulated and empirical moments.

Targets should be Dict or NamedTuple with:
  - :p_move_40_50
  - :p_move_65p
  - :P_40_50
  - :P_65p
"""

function calib_objective(θ_vec::Vector{Float64},
                         env::DataEnv,
                         n_agents::Int=100_000,
                         w_rate_40::Float64=1.0,
                         w_rate_65::Float64=1.0,
                         w_flow_40::Float64=1.0,
                         w_flow_65::Float64=1.0,)

  # unpack θ
  θ = (θ_vec[1], θ_vec[2], θ_vec[3], θ_vec[4])
  moms = simulate_model_moments(θ, env; n_agents=n_agents)

  # rate errors
  e40 = moms[:p_move_40_50] - targets[:p_move_40_50]
  e65 = moms[:p_move_65p] - targets[:p_move_65p]

  # flow matrix errors
  Pm40 = moms[:P_40_50]
  Pd40 = targets[:P_40_50]
  Pm65 = moms[:P_65p]
  Pd65 = targets[:P_65p]

  @assert size(Pm40) == size(Pd40)
  @assert size(Pm65) == size(Pd65)

  eflow40 = 0.0
  eflow65 = 0.0

  Z = env.Z
  for i in 1:Z, j in 1:Z
    if i != j
      eflow40 += (Pm40[i, j] - Pd40[i, j])^2
      eflow65 += (Pm65[i, j] - Pd65[i, j])^2
    end
  end

  loss = w_rate_40 * e40^2 +
         w_rate_65 * e65^2 +
         w_flow_40 * eflow40 +
         w_flow_65 * eflow65
  return loss
end

# ============================
# 6. Calibration Wrapper
# ============================

"""
Run calibration using Optim.jl.

  θ = (γW, γR, αW, αR) initialized at θ_0
  bounds and weights can be tuned.
"""

function run_calibration(θ_0::NTuple{4, Float64},
                         targets,
                         env::DataEnv;
                         n_agents::Int=100_000)

  lower = [0.0, 0.0, -10.0, -10.0]
  upper = [20.0, 10.0, 5.0, 5.0]

  obj(θ_vec) = calib_objective(θ_vec, targets, env; n_agents=n_agents)

  res = Optim.optimize(obj,
                    lower, upper,
                    collect(θ_0),
                    Fminbox(BFGS()))

  θ_hat = Optim.minimizer(res)
  return θ_hat, res
end

end # module


# Simulated data and testing

using Random, LinearAlgebra, Statistics, .MigCalibration

# ---------------------------
# 1. Basic Grid and Params
# ---------------------------

const STATES = collect(1:49) # 48 contiguous states + DC
Z = length(STATES)
ages = collect(40:80)
T = length(ages)

# Parameters
β = 0.96
σ = 3.0
prob_retire = 0.08
prob_death = 0.04
pension_rate = 0.3

# -------------------------------
# 2. Location Amentities (base)
# -------------------------------

# Simple cross-state pattern: center around 0
amenW_base = range(-0.5, 0.5; length=Z) |> collect
amenR_base = range(0.5, -0.5; length=Z) |> collect 

# ------------------------------------
# 3. Economic Profiles: w, r, τ, hc
# ------------------------------------

wage = zeros(Float64, Z, T)
tax = zeros(Float64, Z, T)
rent = zeros(Float64, Z, T)
hc_cost = zeros(Float64, Z, T)

for (ti, age) in enumerate(ages)
  age_factor = 1.0 + 0.02 * (age - 40)
  for (zi, s) in enumerate(STATES)
    base_w = 40_000.0 + 60_000.0 * (zi - 1)
    wage[zi, ti] = base_w * age_factor

    tax[zi, ti] = 0.05 + 0.17 * (zi - 1) / (Z - 1)

    rent[zi, ti] = 8_000.0 + 16_000.0 * (Z - zi) / (Z - 1)
    hc_cost[zi, ti] = 10_000.0 + 2_000.0 * (zi - 1) / (Z - 1)
  end
end

# -------------------------------
# 4. Initial Distribution at 40
# -------------------------------

# Start with more weight in mid-index states, normalized
weights = [exp(-((zi - Z/2)^2) / (2 * (Z/6)^2)) for zi in 1:Z]
init_dist_40 = normalize(weights, 1)

# -------------------------------
# 5. Create DataEnv
# -------------------------------

env = MigCalibration.DataEnv(
  Z,
  ages,
  β,
  σ,
  prob_retire,
  prob_death,
  pension_rate,
  amenW_base,
  amenR_base,
  wage,
  tax,
  rent,
  hc_cost,
  init_dist_40
)
MigCalibration.check_env(env)

# -------------------------------
# Plotting Move Probabilities by Age Pairs
# -------------------------------

using Plots
"""
Plot move probabilities by:
1. Overall (40-80)
2. By 2-year age pairs
3. Age group (40-50, 65+)
"""

function plot_move_probs(moms_model; targets=nothing)
  # ------ Overall move prob from pairs ---------
  exp_pair = moms_model[:exp_pair]
  mov_pair = moms_model[:mov_pair]
  overall_model = sum(mov_pair) / sum(exp_pair)

  p_overall = bar(
    ["40-80"],
    [overall_model],
    legend= false,
    ylabel= "Move Probability",
    title = "Overall Move Probability (40-80)"
  )

  # ------ By 2-year age pairs ---------
  ages_start = moms_model[:agepair_starts]
  p_pairs = moms_model[:p_move_pairs]

  p_pairs = plot(
    ages_start,
    p_pairs,
    marker = :circle,
    xlabel = "Starting Age of 2-Year Pair",
    ylabel = "Move Probability",
    title = "Move Probabilities by 2-Year Age Pairs",
    xlims = (minimum(ages_start) - 1, 69),
    legend = false
  )

  # ------ By Age Groups ---------
  p40_m = moms_model[:p_move_40_50]
  p65_m = moms_model[:p_move_65p]

  if targets === nothing
    # model only
    p_groups = bar(
      ["40-50", "65+"],
      [p40_m, p65_m],
      legend= false,
      ylabel= "Move Probability",
      title = "Move Probabilities by Age Groups"
    )
  else
    p_groups = bar(
      ["40-50", "65+"],
      [p40_m, p65_m],
      legend= :topleft,
      ylabel= "Move Probability",
      title = "Move Probabilities by Age Groups"
    )
    bar!(
      ["40-50", "65+"],
      [targets[:p_move_40_50], targets[:p_move_65p]],
      label = "Data",
      alpha = 0.5
    )
  end

  # ------ Combined ---------
  savefig(p_pairs, "move_probs_by_age_pairs.pdf")
end

# -------------------------------
# 6. Example Run of Simulation
# -------------------------------

θ_test = (5.5, 5.0, 0.5, 0.5)
moms = MigCalibration.simulate_model_moments(θ_test, env; n_agents=100_000)

plot_move_probs(moms)

println("Probability of moving between 40 and 50: ", moms[:p_move_40_50])
println("Probability of moving after 65: ", moms[:p_move_65p])
println("Move probabilities by 2-year age pairs starting at ages: ", moms[:agepair_starts])
println("Move probabilities by age pairs: ", moms[:p_move_pairs])

