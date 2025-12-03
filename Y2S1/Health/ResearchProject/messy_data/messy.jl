using LinearAlgebra
using Distributions
using Statistics
using Random
using Plots
using Interpolations

# Setting Parameters
# =========================
# Setting random seed for reproducibility
Random.seed!(219)

# Parameter Definitions
# =========================
β = 0.95          # Discount factor

# Addict Types
# =========================
γ_vals = [0.5, 1.5]  # Different levels of addiction severity
r_vals = [0.1, 0.5]  # Different risk sensitivities

# Search Space
# ========================
S_max = 100.0       # Maximum state value
S_grid = 0:S_max

# Doctor risk and cost params
# ========================
i_grid = 0.0:0.1:2.0  # intensity grid
λ_match = 0.3  # match probability parameter


# Simulation Sizes
# ========================
n_a = 1000  # Number of addicts to simulate
n_d = 600  # Number of doctors to simulate
T = 100  # Time periods

function bellman_addict(β, γ_vals, r_vals, S_grid, tol=1e-6, maxiter=1000)
    nγ, nr, nS = length(γ_vals), length(r_vals), length(S_grid)
    V = zeros(nγ, nr, nS)  # Value function
    V_new = similar(V)

    for iter in 1:maxiter
        for g in 1:nγ, r in 1:nr, s in 1:nS
            γ = γ_vals[g]
            risk = r_vals[r]
            S = S_grid[s]
            # If matched & stay
            p = 1 + 0.5*rand() # random prescription quantity
            y = γ*p - risk^(1/γ)*S
            stay_val = y + β *(λ_match*V[g, r, 1] + (1-λ_match)*V[g, r, s]) # reset search if matched
            # If search this period
            next_s = min(S+1, nS)
            search_val = β * V[g, r, next_s]

            V_new[g, r, s] = max(stay_val, search_val)
        end
   
        diff = maximum(abs.(V_new .- V))
        V .= V_new
        if diff < tol
            println("Addict Bellman coverged in $iter iterations (diff = $diff)")
            break
        end
    end
    return V
end

function bellman_doctor(β, r_vals, i_grid, tol=1e-6, maxiter=1000)
    nr, ni = length(r_vals), length(i_grid)
    V = zeros(nr, ni)  # Value function
    V_new = similar(V)

    for iter in 1:maxiter
        for r in 1:nr
            risk = r_vals[r]
            best_val = -Inf
            for i in i_grid
                P = rand(Poisson(3)) # number of prescriptions written
                a_sum = rand(Poisson(5)) # number of addicts seen
                π = risk^2*P + a_sum - i*risk
                val = π + β * V[r]
                if val > best_val
                    best_val = val
                end
            end
            V_new[r] = best_val
        end
        diff = maximum(abs.(V_new .- V))
        V .= V_new
        if diff < tol
            println("Doctor Bellman coverged in $iter iterations (diff = $diff)")
            break
        end
    end
    return V
end

# Simulation
# ========================

γ_a = rand(Categorical([0.5, 0.5]), n_a)
r_a = rand(Categorical([0.5, 0.5]), n_a)

r_d = rand(Categorical([0.5, 0.5]), n_d)
a_count = zeros(Int, n_d)
P_total = zeros(Float64, n_d)

S_a = zeros(Int, n_a)  # Initial states for addicts
V_a = zeros(Float64, n_a)

risk_cap = rand(Uniform(10, 20), n_d) 
risk_exposure = zeros(Float64, n_d)
active = trues(n_d)
# Simulation Loop
# ========================

exit_count_over_time = zeros(T)
mean_search_over_time = zeros(T)
for t in 1:T
  active_docs= findall(active)
  if isempty(active_docs)
    println("All doctors have exceeded risk capacity at time $t")
    exit_count_over_time[t:end] .= sum(.!active)
    mean_search_over_time[t:end] .= mean(S_a)
    break
  end
  matches = rand(1:n_d, n_a)
  for i in 1:n_a
      doc_idx = matches[i]
      γ = γ_vals[γ_a[i]]; risk_a = r_vals[r_a[i]]
      s = S_a[i]

      if !active[doc_idx]
          S_a[i] = min(s+1, S_max)
          continue
      end

      matched = rand() < λ_match
      if matched
          p = 1 + rand()
          y = γ*p - risk_a^(1/γ)*s
          U = y
          S_a[i] = 0
          V_a[i] = U + β * V_a[i]
          # Update doctor stats
          P_total[doc_idx] += p
          a_count[doc_idx] += 1
          risk_exposure[doc_idx] += r_vals[r_d[doc_idx]]*p
          if risk_exposure[doc_idx] > risk_cap[doc_idx]
              active[doc_idx] = false
              S_a[i] = min(s+1, S_max)
          end
      else
      S_a[i] = min(s+1, S_max)
      end
  end
  exit_count_over_time[t] = sum(.!active)  # total number of inactive doctors at end of period t
  mean_search_over_time[t] = mean(S_a)
end
new_exits_per_period = diff([0; exit_count_over_time])   
# doctor profits
i_choice = 1.0
π_d = [r_vals[r_d[j]]^2 * P_total[j] + a_count[j] - 1.0 * r_vals[r_d[j]] for j in 1:n_d]
mean_π = mean(π_d)
println("Mean doctor profit = ", mean(π_d[active]))
println("Mean addict value  = ", mean(V_a))
println("Share of doctors exited = ", mean(.!active))
println("Mean search stock at end = ", mean(S_a))
# Plotting Results
# ========================
histogram(π_d, bins=30, title="Doctor Profit Distribution", xlabel="Profit", ylabel="Frequency")
savefig("doctor_profit_distribution.pdf")

histogram(V_a, bins=30, title="Addict Value Distribution", xlabel="Value", ylabel="Frequency")
savefig("addict_value_distribution.pdf")

histogram(S_a, bins = 0:1:maximum(S_a), xlabel = "Search stock S (Periods Without a Match", ylabel = "Density", title = "Distribution of Addict Search Stock S", legend = false)
savefig("addict_search_stock_distribution.pdf")

plot(
    risk_cap,
    risk_exposure,
    seriestype = :scatter,
    xlabel = "Risk Capacity",
    ylabel = "Final Exposure",
    title = "Doctor Exposures vs Risk Caps",
)
savefig("doctor_exposure_vs_capacity.pdf")

p_cum = plot(
    1:T,
    exit_count_over_time,
    xlabel = "Time period",
    ylabel = "Cumulative # of exited doctors",
    title = "Cumulative Doctor Exits Over Time",
    linewidth = 2,
    legend = false,
)

# 2. New exits per period (flow)
p_flow = bar(
    1:T,
    new_exits_per_period,
    xlabel = "Time period",
    ylabel = "New exits in period",
    title = "Doctor Exit Flow Per Period",
    legend = false,
)

p_search = plot(
    1:T,
    mean_search_over_time,
    xlabel = "Time period",
    ylabel = "Mean Search Stock S",
    title = "Mean Addict Search Stock Over Time",
    linewidth = 2,
    legend = false,
)
plot(p_cum, p_flow, p_search, layout = (3,1))
savefig("doctor_exits_over_time.pdf")
# End of Code

# Counterfactual Experiments
# ========================

struct MarketParams
    n_a::Int # Number of addicts
    n_d::Int # Number of doctors
    T::Int  # Time periods
    
    λ_match::Float64  # match probability parameter
    risk_cap_low::Float64 # min draw for risk cap of doctors
    risk_cap_high::Float64 # max draw for risk cap of doctors

    exposure_scale::Float64 # how fast exposure accumulates
    exit_penalty::Int # penalty to addict value upon relapse

    seed::Int # random seed
end

function simulate_market(params::MarketParams)
    (; n_a, n_d, T, λ_match, risk_cap_low, risk_cap_high,
       exposure_scale, exit_penalty, seed) = params

    Random.seed!(seed)
    # --- types ---
    # addicts
    γ_vals = [0.5, 1.5]
    r_vals = [0.1, 0.5]
    γ_a = rand(Categorical([0.5, 0.5]), n_a)
    r_a = rand(Categorical([0.5, 0.5]), n_a)

    # doctors
    r_d = rand(Categorical([0.5, 0.5]), n_d)
  
    # --- states over time ---
    S_a = zeros(Int, n_a)  # Initial states for addicts
    V_a = zeros(Float64, n_a)
    P_total = zeros(Float64, n_d)
    a_count = zeros(Int, n_d)
    risk_exposure = zeros(Float64, n_d)
    active = trues(n_d)

    addict_active = trues(n_a)
    addict_exit_over_time = zeros(T)

    risk_cap = rand(Uniform(risk_cap_low, risk_cap_high), n_d)
    exit_count_over_time = zeros(T)
    mean_search_over_time = zeros(T)

    for t in 1:T
      active_docs= findall(active)
      if isempty(active_docs)
        println("All doctors have exceeded risk capacity at time $t")
        exit_count_over_time[t:end] .= sum(.!active)
        mean_search_over_time[t:end] .= mean(S_a)
        addict_exit_over_time[t:end] .= sum(.!addict_active)
        break
      end
      matches = rand(1:n_d, n_a)
      for i in 1:n_a
          if !addict_active[i]
              continue
          end

          doc_idx = matches[i]
          γ = γ_vals[γ_a[i]]; risk_a = r_vals[r_a[i]]
          s = S_a[i]

          if !active[doc_idx]
              S_a[i] = min(s + exit_penalty, 100.0)
              if S_a[i] >= 100.0
                  addict_active[i] = false
              end
              continue
          end

          matched = rand() < λ_match
          if matched
              p = 1 + rand()
              y = γ*p - risk_a^(1/γ)*s
              U = y
              V_a[i] = U + 0.95 * V_a[i]
              S_a[i] = 0
              # Update doctor stats
              P_total[doc_idx] += p
              a_count[doc_idx] += 1
              risk_exposure[doc_idx] += exposure_scale * r_vals[r_d[doc_idx]]*p
              if risk_exposure[doc_idx] > risk_cap[doc_idx]
                  active[doc_idx] = false
                  S_a[i] = min(s+exit_penalty, 100.0)
                  if S_a[i] >= 100.0
                      addict_active[i] = false
                  end
              end
          else
            S_a[i] = min(s+1, 100.0)
            if S_a[i] >= 100.0
                addict_active[i] = false
            end
          end
      end

      exit_count_over_time[t] = sum(.!active)  # total number of inactive doctors at end of period t
      mean_search_over_time[t] = mean(S_a)
      addict_exit_over_time[t] = sum(.!addict_active)
    end

    i_choice = 1.0
    π_doctors = similar(P_total)
    for j in 1:n_d
        risk_doc = r_vals[r_d[j]]
        π_doctors[j] = risk_doc^2 * P_total[j] + a_count[j] - i_choice * risk_doc
    end
    return (
        exit_path = exit_count_over_time,
        addict_exit_path = addict_exit_over_time,
        search_path = mean_search_over_time,
        final_search = copy(S_a),
        active_doctors_end = sum(active),
        pct_active_end = mean(active),
        avg_doctor_profit = mean(π_doctors[active]),
        avg_addict_value = mean(V_a),
        params = params
    )
end

baseline_params = MarketParams(
  1000,
  600,
  100,
  0.3,
  10.0,
  20.0,
  1.0,
  1,
  219
)
baseline_result = simulate_market(baseline_params)
println("Baseline avg doctor profit: ", baseline_result.avg_doctor_profit)
println("Baseline avg addict value: ", baseline_result.avg_addict_value)

# Counterfactual: Higher risk
cf_params = MarketParams(
  1000,
  600,
  100,
  0.3,
  5.0,
  10.0,
  1.0,
  1,
  219
)

cf_result = simulate_market(cf_params)
println("Counterfactual avg doctor profit: ", cf_result.avg_doctor_profit)
println("Counterfactual avg addict value: ", cf_result.avg_addict_value)
println("Doctors active at end (CF): ", cf_result.active_doctors_end)
println("Doctors active at end (Baseline): ", baseline_result.active_doctors_end)
println("Difference in avg addict value: ", cf_result.avg_addict_value - baseline_result.avg_addict_value)
println("Difference in Addict Search Stock Mean: ", mean(cf_result.final_search) - mean(baseline_result.final_search))
println("Addict exits (CF): ", cf_result.addict_exit_path[end])
println("Addict exits (Baseline): ", baseline_result.addict_exit_path[end])

T = baseline_params.T
tgrid = 1:T

p_exit = plot(
  tgrid,
  baseline_result.exit_path,
  label = "Baseline",
  xlabel = "Time Period",
  ylabel = "Cumulative Doctor Exits",
  title = "Doctor Exits Over Time",
  linewidth = 2,
)

plot!(
  p_exit,
  tgrid,
  cf_result.exit_path,
  label = "Increased Risk",
  linestyle = :dash,
  linewidth = 2,
)
display(p_exit)
savefig("counterfactual_doctor_exits.pdf")

p_addict = plot(
  tgrid,
  baseline_result.addict_exit_path,
  label = "Baseline",
  xlabel = "Time Period",
  ylabel = "Cumulative Addict Exits",
  title = "Addict Exits Over Time",
  linewidth = 2,
)
plot!(
  p_addict,
  tgrid,
  cf_result.addict_exit_path,
  label = "Increased Risk",
  linestyle = :dash,
  linewidth = 2,
)
display(p_addict)
savefig("counterfactual_addict_exits.pdf")


p_search = plot(
  tgrid,
  baseline_result.search_path,
  label = "Baseline",
  xlabel = "Time Period",
  ylabel = "Mean Addict Search Stock S",
  title = "Mean Addict Search Stock Over Time",
  linewidth = 2,
)
plot!(
  p_search,
  tgrid,
  cf_result.search_path,
  label = "Increased Risk",
  linestyle = :dash,
  linewidth = 2,
)
display(p_search)
savefig("counterfactual_addict_search_stock.pdf")

p_profit = bar(
    ["Baseline", "Increased Risk"],
    [baseline_result.avg_doctor_profit, cf_result.avg_doctor_profit],
    xlabel = "Scenario",
    ylabel = "Average Doctor Profit",
    title = "Average Doctor Profit: Baseline vs Increased Risk",
    legend = false,
)
display(p_profit)
savefig("counterfactual_doctor_profit.pdf")

p_value = bar(
    ["Baseline", "Increased Risk"],
    [baseline_result.avg_addict_value, cf_result.avg_addict_value],
    xlabel = "Scenario",
    ylabel = "Average Addict Value",
    title = "Average Addict Value: Baseline vs Increased Risk",
    legend = false,
)
display(p_value)
savefig("counterfactual_addict_value.pdf")

# End of Code
