using Random, Statistics, DataFrames, DataFramesMeta, CSV, CategoricalArrays, Plots

# --- Creating Reproducible Data ---

Random.seed!(0219)

N = 20_000
years = 1999:2:2017
ages = 18:65

# --- Categorical Variables ---

educ_levels = ["HS Dropout", "HS Grad", "College +"]
wealth_levels = ["Bottom 25%", "Middle 50%", "Top 25%"]
industries = ["Blue Collar", "White Collar"]

# --- Draw Random Samples ---

df = DataFrame(
  year=rand(years, N),
  age=rand(ages, N),
  educ=rand(educ_levels, N),
  wealth=rand(wealth_levels, N),
  industry=rand(industries, N)
)

# --- Create Categorical Variables ---

df.educ = categorical(df.educ)
df.wealth = categorical(df.wealth)
df.industry = categorical(df.industry)

# --- Synthetic Economic Variables ---

edu_wage_bump = Dict(
  "HS_Dropout" => 12.0,
  "HS_Grad" => 18.0,
  "College +" => 28.0
)

ind_hours_bump = Dict(
  "Blue Collar" => 42.0,
  "White Collar" => 38.0
)

age_wage_premium(age) = 0.25 * max(age - 18, 0)

hours_noise = 3.0
wage_noise = 4.0

df.hours = [max(0, ind_hours_bump[string(ind)] + hours_noise * randn()) for ind in df.industry]
df.wage = [max(0, edu_wage_bump[string(edu)] + age_wage_premium(a) + wage_noise * randn()) for (edu, a) in zip(df.educ, df.age)]

inc_noise = 50.0
df.inc = df.wage .* df.hours .+ inc_noise .* randn(N)

miss_idx = rand(1:N, round(Int, 0.03N))
df.inc[miss_idx] .= missing

first(df, 5)

@subset!(df, .!ismissing(:inc) .&& .!ismissing(:wage) .&& .!ismissing(:hours))

sort!(df, :year)

g_year_edu = groupby(df, [:year, :educ])
agg_year_educ = combine(g_year_edu,
  :inc => mean => :inc_m,
  :wage => mean => :wage_m,
  :hours => mean => :hours_m)

first(agg_year_educ, 6)

@susbet!(df, .!ismissing(:age) .&& .!ismissing(:educ))

g_age_edu = groupby(df, [:age, :educ])
inc_age_fe_educ = combine(g_age_edu, :inc => mean => :y_m)
wage_age_fe_educ = combine(g_age_edu, :wage => mean => :y_m)
hours_age_fe_educ = combine(g_age_edu, :hours => mean => :y_m)

first(inc_age_fe_educ, 6)

g_age_wealth = groupby(df, [:age, :wealth])
inc_age_fe_wealth = combine(g_age_wealth, :inc => mean => :y_m)
g_age_ind = groupby(df, [:age, :industry])
wage_age_fe_wealth = combine(g_age_wealth, :wage => mean => :y_m)

first(inc_age_fe_wealth, 6)

# Helper: draw line series for each category in a long DataFrame
function plot_age_profile(df_long::DataFrame; title::AbstractString, legendtitle::AbstractString, ylabel::AbstractString)
  groups = unique(df_long[:, 2])  # assumes col2 is the grouping (e.g., :educ_group)
  plt = plot(title=title, xlabel="Age", ylabel=ylabel, legendtitle=legendtitle)
  for g in groups
    sub = df_long[df_long[:, 2].==g, :]      # filter this group's rows
    # sort by age to draw a clean line
    sort!(sub, :age)
    plot!(plt, sub.age, sub.y_m, label=string(g), lw=1.8)
  end
  return plt
end

# Income by education
p1 = plot_age_profile(inc_age_fe_educ; title="Real Income by Education", legendtitle="Education", ylabel="Income")
savefig(p1, "inc_age_fe_educ.pdf")   # saves to your working directory

# Wage by education
p2 = plot_age_profile(wage_age_fe_educ; title="Real Wage by Education", legendtitle="Education", ylabel="Wage")
savefig(p2, "wage_age_fe_educ.pdf")

# Hours by education
p3 = plot_age_profile(hour_age_fe_educ; title="Hours Worked by Education", legendtitle="Education", ylabel="Hours")
savefig(p3, "hour_age_fe_educ.pdf")

# Wage by industry (example of a different grouping)
# Here col2 is :industry already in wage_age_fe_ind
p4 = plot_age_profile(wage_age_fe_ind; title="Real Wage by Industry", legendtitle="Industry", ylabel="Wage")
savefig(p4, "wage_age_fe_ind.pdf")
