using Random, Statistics, Distributions, Plots, Optim, DataFrames

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

#---------------------------------#
# Helper Function Definitions     #
# --------------------------------#

function create_model()
    β = 0.94
    x = [0.98, 0.95, 0.90, 0.80, 0.50] # prob of remaining in workforce by age group
    y = [0.999, 0.995, 0.990, 0.980, 0.950] # survival prob by age group
    γ = 2.0
    cbar = 1000.0

    T_min = 40
    T_max = 80
    Z = 51
    D = 3 # belief types - positive, correct, negative
    wage = range(30000.0, stop=80000.0, length=Z) |> collect
    tax = range(0.1, stop=0.3, length=Z) |> collect
    h_cost = [linspace(8000.0, 15000.0, Z) for d in 1:D] |> hcat
    pension = 20000.0
    health_cost = [linspace(5000.0, 20000)]
    health_cost = repeat(health_cost, 1, D)
    return Model(β, x, y, γ, cbar, T_min, T_max, Z, D, wage, tax, h_cost, pension, health_cost)
end

model = create_model()

#================================#
# Data Loading and Preprocessing #
#================================#

function load_empirical_data()
  # Loading CSV
  df = DataFrame(/Volumes/TDP/macro/data/)
end
