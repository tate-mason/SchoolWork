using Random, Statistics, Distributions, Plots, Optim

# Setting Parameters
# ============================
Random.seed!(219) # For reproducibility

struct Model
    β::Float64 # discount factor
    x::Float64 # prob of remaining in workforce
    y::Float64 # survival prob
    γ::Float64 # moving cost parameter
    cbar::Float64 # bliss consumption level

    T_min::Int # starting age
    T_max::Int # terminal age

    Z::Int # number of states
    D::Int # number of belief types for δ

    wage::Array{Float64,1} # wage level[z]
    tax::Array{Float64,1} # tax rate[z]
    h_cost::Array{Float64, 2} # housing costs[z, d]
    pension::Float64 # pension level
    health_cost::Array{Float64, 2} # health costs[z, d]
end

# Helper Functions
# ============================

"Consumption for a worker in location z with belief type d"
function c_worker(z::Int, d::Int, M::Model)
  # c = w(z)*τ(z) - E[c(h_cost(z))| δ]
    return M.wage[z] - M.tax[z] - M.h_cost[z, d]
end

"Consumption for a retiree in location z with belief type d"
function c_retiree(z::Int, d::Int, M::Model)
  # c=  pension - E[c(health_cost(z))| δ]
    return M.pension - M.health_cost[z, d]
end

"Period utility: quadratic utility function"
function U_period(c::Float64, moved::Bool, M::Model)
    move_cost = moved ? M.γ : 0.0
    return -0.5 * (M.cbar - c)^2 - move_cost
end

# Backward Induction
# ============================

"""
solve_model(M)

Returns:
- Vw[t_idx, z, d]: value of being a worker at age t_idx in location z with belief type d
- Vr[t_idx, z, d]: value of being a retiree at age t_idx
- pol_w[t_idx, z, d]: optimal location choice for workers
- pol_r[t_idx, z, d]: optimal location choice for retirees

Age index t_idx: t - M.T_min + 1
"""

function solve_model(M::Model)
    T_len = M.T_max - M.T_min + 1 # number of discrete ages
    
    Vw = zeros(Float64, T_len, M.Z, M.D) # Value function for workers
    Vr = zeros(Float64, T_len, M.Z, M.D) # Value function for retirees

    pol_w = zeros(Int, T_len, M.Z, M.D) # Policy function for workers
    pol_r = zeros(Int, T_len, M.Z, M.D) # Policy function for retirees

    t_idx_Tmax = T_len
    # Terminal period: only retirees receive utility
    for z in 1:M.Z, d in 1:M.D
        # staying
        c_here = c_retiree(z, d, M)
        stay_utility = U_period(c_here, false, M)
 
        #moving
        best_move_val = -Inf
        best_zp = z
        for zp in 1:M.Z
            c_there = c_retiree(zp, d, M)
            moved_flag = (zp != z)
            this_val = U_period(c_there, moved_flag, M)
            if this_val > best_move_val
                best_move_val = this_val
                best_zp = zp
            end
        end

        Vr[t_idx_Tmax, z, d] = max(stay_utility, best_move_val)
        pol_r[t_idx_Tmax, z, d] = best_zp
    end

    # Workers at terminal period
    for z in 1:M.Z, d in 1:M.D
        c_here = c_worker(z, d, M)
        stay_utility = U_period(c_here, false, M)

        # moving
        best_move_val = -Inf
        best_zp = z
        for zp in 1:M.Z
            c_there = c_worker(zp, d, M)
            moved_flag = (zp != z)
            this_val = U_period(c_there, moved_flag, M)
            if this_val > best_move_val
                best_move_val = this_val
                best_zp = zp
            end
        end

        Vw[t_idx_Tmax, z, d] = max(stay_utility, best_move_val)
        pol_w[t_idx_Tmax, z, d] = best_zp
    end
    # Backward induction for t < T_max
    for t_idx in (T_len-1):-1:1
        for z in 1:M.Z, d in 1:M.D
            # Retirees
            begin
                c_here = c_retiree(z, d, M)
                u_now = U_period(c_here, false, M)
                cont_val = M.β * M.y * Vr[t_idx+1, z, d]
                Vstay_r = u_now + cont_val
            end
            # moving
            best_move_val_r = -Inf
            best_zp_r = z
            for zp in 1:M.Z
                c_there = c_retiree(zp, d, M)
                u_now = U_period(c_there, (zp != z), M)
                cont_val = M.β * M.y * Vr[t_idx+1, zp, d]
                this_val = u_now + cont_val
                if this_val > best_move_val_r
                    best_move_val_r = this_val
                    best_zp_r = zp
                end
            end
            Vr[t_idx, z, d] = max(Vstay_r, best_move_val_r)
            pol_r[t_idx, z, d] = best_zp_r
            # Workers
            begin
                c_here = c_worker(z, d, M)
                u_now = U_period(c_here, false, M)
                cont_worker = M.β * (
                  M.x * Vw[t_idx+1,z,d] +
                  (1 - M.x) * Vr[t_idx+1,z,d]
                )
                Vstay_w = u_now + cont_worker
            end
            # moving
            best_move_val_w = -Inf
            best_zp_w = z
            for zp in 1:M.Z
                c_there = c_worker(zp, d, M)
                moved_flag = (zp != z)
                u_now = U_period(c_there, moved_flag, M)

                cont_worker = M.β * (
                  M.x * Vw[t_idx+1,zp,d] +
                  (1 - M.x) * Vr[t_idx+1,zp,d]
                )
                this_val = u_now + cont_worker
                if this_val > best_move_val_w
                    best_move_val_w = this_val
                    best_zp_w = zp
                end
            end
            Vw[t_idx, z, d] = max(Vstay_w, best_move_val_w)
            pol_w[t_idx, z, d] = best_zp_w
        end
    end
    return Vw, Vr, pol_w, pol_r
end



# Calibration and Simulation
# ============================
const state_names = [
    "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
    "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
    "MA","MI","MN","MS","MO","MT","NC","ND","NE","NH",
    "NJ","NM","NV","NY","OH","OK","OR","PA","RI","SC",
    "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY",
    "DC"
]

const Z_STATES = length(state_names)

function build_wage_vector()
    wage_dict = Dict(
        "AL"=>48, "AK"=>63, "AZ"=>55, "AR"=>46, "CA"=>78, "CO"=>70, "CT"=>74, "DE"=>62, "FL"=>53, "GA"=>55,
        "HI"=>66, "ID"=>50, "IL"=>64, "IN"=>53, "IA"=>52, "KS"=>51, "KY"=>49, "LA"=>50, "ME"=>51, "MD"=>75,
        "MA"=>80, "MI"=>55, "MN"=>60, "MS"=>45, "MO"=>52, "MT"=>50, "NC"=>55, "ND"=>57, "NE"=>53, "NH"=>62,
        "NJ"=>77, "NM"=>48, "NV"=>56, "NY"=>82, "OH"=>54, "OK"=>50, "OR"=>58, "PA"=>58, "RI"=>60, "SC"=>50,
        "SD"=>52, "TN"=>52, "TX"=>61, "UT"=>58, "VT"=>52, "VA"=>68, "WA"=>76, "WV"=>47, "WI"=>54, "WY"=>55,
        "DC"=>90
    )
    wage_vec = [wage_dict[s] for s in state_names]
    return Float64.(wage_vec)
end

function build_cost_matrices(; D = 2, seed = 1234)
    Random.seed!(seed)

    # Baseline housing cost level by state (e.g. $1000s/month-equivalent / COL index)
    # Higher = more expensive to live there as a worker.
    base_housing = Dict(
        "AL"=>14, "AK"=>20, "AZ"=>18, "AR"=>13, "CA"=>32, "CO"=>24, "CT"=>26, "DE"=>20, "FL"=>22, "GA"=>17,
        "HI"=>35, "ID"=>17, "IL"=>21, "IN"=>15, "IA"=>14, "KS"=>14, "KY"=>13, "LA"=>14, "ME"=>17, "MD"=>25,
        "MA"=>30, "MI"=>16, "MN"=>19, "MS"=>12, "MO"=>15, "MT"=>18, "NC"=>18, "ND"=>16, "NE"=>15, "NH"=>22,
        "NJ"=>29, "NM"=>16, "NV"=>20, "NY"=>34, "OH"=>15, "OK"=>13, "OR"=>22, "PA"=>20, "RI"=>23, "SC"=>16,
        "SD"=>14, "TN"=>16, "TX"=>18, "UT"=>20, "VT"=>19, "VA"=>23, "WA"=>28, "WV"=>12, "WI"=>16, "WY"=>17,
        "DC"=>33
    )

    # Baseline retiree health/amenity "cost" (lower is better for retirees).
    base_health = Dict(
        "AL"=>11, "AK"=>18, "AZ"=>9,  "AR"=>11, "CA"=>16, "CO"=>14, "CT"=>17, "DE"=>13, "FL"=>8,  "GA"=>11,
        "HI"=>15, "ID"=>12, "IL"=>14, "IN"=>12, "IA"=>11, "KS"=>11, "KY"=>12, "LA"=>12, "ME"=>13, "MD"=>16,
        "MA"=>18, "MI"=>12, "MN"=>11, "MS"=>12, "MO"=>11, "MT"=>12, "NC"=>10, "ND"=>12, "NE"=>11, "NH"=>14,
        "NJ"=>18, "NM"=>10, "NV"=>10, "NY"=>19, "OH"=>12, "OK"=>12, "OR"=>13, "PA"=>14, "RI"=>15, "SC"=>9,
        "SD"=>11, "TN"=>10, "TX"=>9,  "UT"=>11, "VT"=>14, "VA"=>12, "WA"=>15, "WV"=>13, "WI"=>12, "WY"=>12,
        "DC"=>20
    )

    base_housing_vec = [base_housing[s] for s in state_names]
    base_health_vec  = [base_health[s]  for s in state_names]

    Z = length(state_names)

    # We'll now generate D different "belief-adjusted" versions for each state.

    housing_cost = zeros(Float64, Z, D)
    health_cost  = zeros(Float64, Z, D)

    for z in 1:Z
        for d in 1:D
            # belief shock: mean 0, a bit of dispersion (you can tune this)
            # optimistic (d=1): downward bias
            # pessimistic (d=2): upward bias
            if d == 1
                shock_h = rand(Normal(-1.0, 0.5))
                shock_r = rand(Normal(-0.5, 0.5))
            else
                shock_h = rand(Normal(+1.0, 0.5))
                shock_r = rand(Normal(+0.5, 0.5))
            end

            housing_cost[z, d] = max(0.1, base_housing_vec[z] + shock_h)
            health_cost[z, d]  = max(0.1, base_health_vec[z]  + shock_r)
        end
    end

    return housing_cost, health_cost
end

function model()
    # Define model parameters
    β = 0.96
    x = 0.90
    y = 0.98
    γ = 12.0
    cbar = 1

    T_min = 40
    T_max = 80

    Z = Z_STATES # number of locations
    D = 2 # number of belief types

    wage_vec = build_wage_vector() 
    tax_vec = 0.2 * wage_vec # flat 20% tax rate for simplicity
    h_cost, health_cost = build_cost_matrices(D = D, seed = 1234)
    pension = mean(wage_vec)*0.3

    M = Model(
        β, x, y, γ, cbar,
        T_min, T_max,
        Z, D,
        wage_vec,
        tax_vec,
        h_cost,
        pension,
        health_cost
    )
    return M
end

using StatsBase, Plots

###########################################################
# Simulation with top-10 restriction and realistic survival
###########################################################

function simulate_life(M::Model, Vw, Vr, pol_w, pol_r; z0::Int=1, d0::Int=1, seed=1234)
    Random.seed!(seed)

    T_len = M.T_max - M.T_min + 1
    ages = collect(M.T_min:M.T_max)

    # storage
    loc_path   = fill(z0, T_len)
    role_path  = fill("worker", T_len)
    alive_path = trues(T_len)

    move_worker  = zeros(Int, M.Z, M.Z)
    move_retiree = zeros(Int, M.Z, M.Z)

    current_z = z0
    current_d = d0
    is_retired = false
    alive = true

    for (idx, t) in enumerate(ages)
        if !alive
            role_path[idx] = "dead"
            alive_path[idx] = false
            continue
        end

        if !is_retired
            role_path[idx] = "worker"
            pol_dest = pol_w[idx, current_z, current_d]
            move_worker[current_z, pol_dest] += 1
            current_z = pol_dest
            loc_path[idx] = current_z

            # smoother retirement: raise chance only after 60
            retire_prob = if t < 62
                0.03
            elseif t < 70
                0.1
            else 
                1.0
            end
            if rand() < retire_prob
                is_retired = true
            end

        else
            role_path[idx] = "retiree"
            pol_dest = pol_r[idx, current_z, current_d]
            move_retiree[current_z, pol_dest] += 1
            current_z = pol_dest
            loc_path[idx] = current_z

            # low annual mortality until very old
            death_prob = if t < 75
                0.05
            elseif t < 80
                0.1
            else
                1
            end
            if rand() < death_prob
                alive = false
            end
        end
    end

    return (
        age = ages,
        loc = loc_path,
        role = role_path,
        alive = alive_path,
        moves_worker = move_worker,
        moves_retiree = move_retiree,
        moves_total = move_worker .+ move_retiree
    )
end

###########################################################
# Summary + top-10 restriction
###########################################################

function summarize_life(life)
    arrivals_worker  = vec(sum(life.moves_worker,  dims=1))
    arrivals_retiree = vec(sum(life.moves_retiree, dims=1))

    top10_worker  = sortperm(arrivals_worker,  rev=true)[1:10]
    top10_retiree = sortperm(arrivals_retiree, rev=true)[1:10]

    println("---- Worker migration (top 10 destinations) ----")
    for idx in top10_worker
        println(state_names[idx], " — arrivals: ", round(arrivals_worker[idx], digits=0))
    end
    println("\n---- Retiree migration (top 10 destinations) ----")
    for idx in top10_retiree
        println(state_names[idx], " — arrivals: ", round(arrivals_retiree[idx], digits=0))
    end

    alive_share = mean(life.alive)
    println("\nAlive at age 80: ", round(100*alive_share, digits=1), "%")
end

###########################################################
# Example run
###########################################################

M = model()
Vw, Vr, pol_w, pol_r = solve_model(M)
life = simulate_life(M, Vw, Vr, pol_w, pol_r; z0=1, d0=1, seed=42)

summarize_life(life)

###########################################################
# Visualization restricted to top-10
###########################################################

arrivals_worker  = vec(sum(life.moves_worker,  dims=1))
arrivals_retiree = vec(sum(life.moves_retiree, dims=1))
top10w = sortperm(arrivals_worker,  rev=true)[1:10]
top10r = sortperm(arrivals_retiree, rev=true)[1:10]

p1 = heatmap(
    life.moves_worker[top10w, top10w],
    xticks=(1:10, state_names[top10w]),
    yticks=(1:10, state_names[top10w]),
    title="Worker Migration (Top 10 States)",
    xlabel="Destination",
    ylabel="Origin",
    color=:viridis
)

p2 = heatmap(
    life.moves_retiree[top10r, top10r],
    xticks=(1:10, state_names[top10r]),
    yticks=(1:10, state_names[top10r]),
    title="Retiree Migration (Top 10 States)",
    xlabel="Destination",
    ylabel="Origin",
    color=:magma
)

plot(p1, p2, layout=(2,1))
savefig("migration_heatmaps.png")
