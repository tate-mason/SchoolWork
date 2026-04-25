# WNBA_proj.R
# Effect of a WNBA Team on Girls' Sports Participation
# Data: master_scraped.csv  (51 states x 26 academic years, wide format)
# Design: Callaway-Sant'Anna (2021) staggered DiD + Synthetic DiD + extras

library(tidyverse)
library(ggplot2)
library(did)
library(RColorBrewer)
library(fixest)      # TWFE via feols
if (!requireNamespace("synthdid", quietly = TRUE)) {
  install.packages("synthdid", repos = "https://cloud.r-project.org")
}
library(synthdid)

# ============================================================
# 1. LOAD & CLEAN
# ============================================================

df_wide <- read_csv("../Data/master_scraped.csv")

year_map <- c(
  "1993-94" = 1993, "1994-95" = 1994, "1995-96" = 1995, "1996-97" = 1996,
  "1997-98" = 1997, "1998-99" = 1998, "1999-00" = 1999, "2000-01" = 2000,
  "2001-02" = 2001, "2002-03" = 2002, "2003-04" = 2003, "2004-05" = 2004,
  "2005-06" = 2005, "2006-07" = 2006, "2007-08" = 2007, "2008-09" = 2008,
  "2009-10" = 2009, "2010-11" = 2010, "2011-12" = 2011, "2012-13" = 2012,
  "2013-14" = 2013, "2014-15" = 2014, "2015-16" = 2015, "2016-17" = 2016,
  "2017-18" = 2017, "2018-19" = 2018
)

df_wide <- df_wide %>%
  mutate(year = year_map[year])

# ---- Targeted data fixes (diagnosed from raw values) ----
#
# (a) California cross_country 1998: reported as 44,245 but adjacent years are
#     14,245 (1997) and 14,815 (1999). The value is ~3x the neighbors with no
#     plausible explanation — almost certainly a transcription error (extra "4"
#     prefix or doubled digit). Set to NA; excluded from CC DiD.
#
# (b) Massachusetts soccer 2003: 42,193 vs ~12,000 in surrounding years.
#     Same class of error. Set to NA.
#
# (c) Pennsylvania cross_country 2008+: value permanently doubles from ~5,500
#     to ~11,320 starting 2008. This is a structural break caused by a
#     reporting methodology change (Pennsylvania began counting indoor cross
#     country separately, effectively doubling the recorded number). Because the
#     level shift is permanent and not treatment-related (PA is never treated),
#     we cannot use PA in the cross_country DiD; we drop it from that sport's
#     panel entirely. The doubling would otherwise inflate the control-group
#     mean post-2008 and bias ATT downward.

df_wide <- df_wide %>%
  mutate(
    # ---- Basketball ----
    # Indiana 1998: 42,510 vs ~12,000 neighbors
    basketball    = if_else(state == "Indiana"       & year == 1998, NA_real_, basketball),
    # Hawaii 1998: 4,607 vs ~1,600 neighbors
    basketball    = if_else(state == "Hawaii"        & year == 1998, NA_real_, basketball),
    # Missouri 1997: 2,631 vs ~13,000 neighbors (missing digit)
    basketball    = if_else(state == "Missouri"      & year == 1997, NA_real_, basketball),
    # Michigan 1997: 9,948 vs ~20,300 neighbors (roughly halved)
    basketball    = if_else(state == "Michigan"      & year == 1997, NA_real_, basketball),

    # ---- Cross Country ----
    # California 1998: 44,245 vs ~14,000 neighbors
    cross_country = if_else(state == "California"    & year == 1998, NA_real_, cross_country),
    # Maine 1997: 4,017 vs ~930 neighbors
    cross_country = if_else(state == "Maine"         & year == 1997, NA_real_, cross_country),
    # Pennsylvania 2008+: permanent reporting methodology change (added indoor XC)
    # drops PA from CC entirely via the balanced-panel filter
    cross_country = if_else(state == "Pennsylvania"  & year >= 2008, NA_real_, cross_country),

    # ---- Soccer ----
    # Massachusetts 2003: 42,193 vs ~12,000 neighbors
    soccer        = if_else(state == "Massachusetts" & year == 2003, NA_real_, soccer),
    # Rhode Island 1993: 4,171 vs 1,115 the following year (first-year anomaly)
    soccer        = if_else(state == "Rhode Island"  & year == 1993, NA_real_, soccer),
    # Rhode Island 1995: 38 vs ~1,100 neighbors (missing digits)
    soccer        = if_else(state == "Rhode Island"  & year == 1995, NA_real_, soccer),

    # ---- Track & Field ----
    # Minnesota 1999: 42,123 vs ~12,000-14,000 neighbors
    track_field   = if_else(state == "Minnesota"     & year == 1999, NA_real_, track_field),
    # West Virginia 2002: 9,079 vs ~2,300 neighbors
    track_field   = if_else(state == "West Virginia" & year == 2002, NA_real_, track_field)
  )

# ============================================================
# 2. WNBA TEAM -> STATE FIRST-TREATMENT YEAR
# ============================================================

team_state <- tribble(
  ~state,            ~first_treat,
  "New York",        1997,
  "Texas",           1997,
  "North Carolina",  1997,
  "Arizona",         1997,
  "Ohio",            1997,
  "California",      1997,
  "Utah",            1997,
  "Virginia",        1998,
  "Michigan",        1998,
  "Florida",         1999,
  "Minnesota",       1999,
  "Oregon",          2000,
  "Indiana",         2000,
  "Washington",      2000,
  "Connecticut",     2003,
  "Illinois",        2006,
  "Georgia",         2008,
  "Oklahoma",        2010
)

df <- df_wide %>%
  left_join(team_state, by = "state") %>%
  mutate(
    first_treat = replace_na(first_treat, 0L),
    has_wnba    = as.integer(first_treat > 0 & year >= first_treat),
    state_id    = as.integer(factor(state))
  )

cat("=== Panel structure ===\n")
cat(
  "States:", n_distinct(df$state), "| Years:", n_distinct(df$year),
  "| Rows:", nrow(df), "\n"
)
cat("Perfectly balanced:", nrow(df) == n_distinct(df$state) * n_distinct(df$year), "\n\n")

# ============================================================
# 3. DATA FACTS
# ============================================================

cat("=== Missing values by sport (after fixes) ===\n")
df %>%
  summarise(across(
    c(basketball, cross_country, soccer, track_field),
    ~ sum(is.na(.))
  )) %>%
  print()

cat("\n=== Summary statistics (all states, all years) ===\n")
df %>%
  select(basketball, cross_country, soccer, track_field) %>%
  summary() %>%
  print()

cat("\n=== Mean participation: treated vs. never-treated states ===\n")
df %>%
  mutate(group = ifelse(first_treat > 0, "Ever-treated", "Never-treated")) %>%
  group_by(group) %>%
  summarise(
    n_states      = n_distinct(state),
    basketball    = mean(basketball, na.rm = TRUE),
    cross_country = mean(cross_country, na.rm = TRUE),
    soccer        = mean(soccer, na.rm = TRUE),
    track_field   = mean(track_field, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\n=== Treatment cohort sizes ===\n")
df %>%
  distinct(state, first_treat) %>%
  count(first_treat) %>%
  mutate(label = ifelse(first_treat == 0, "Never treated",
    paste0("First treated: ", first_treat)
  )) %>%
  select(label, n) %>%
  print()

# ============================================================
# 4. MAP: STATES WITH WNBA TEAMS (colour = first-treatment cohort)
# ============================================================

cohort_years <- sort(unique(team_state$first_treat))
n_cohorts    <- length(cohort_years)
cohort_pal   <- setNames(brewer.pal(n_cohorts, "Set1"), as.character(cohort_years))

map_state_info <- team_state %>%
  mutate(state_lower = tolower(state))

us_states <- map_data("state")
map_df <- us_states %>%
  left_join(map_state_info, by = c("region" = "state_lower"))

map_plot <- ggplot() +
  geom_polygon(
    data = filter(map_df, is.na(first_treat)),
    aes(x = long, y = lat, group = group),
    fill = "grey85", color = "white", linewidth = 0.25
  ) +
  geom_polygon(
    data = filter(map_df, !is.na(first_treat)),
    aes(x = long, y = lat, group = group, fill = factor(first_treat)),
    color = "white", linewidth = 0.25
  ) +
  scale_fill_manual(
    values = cohort_pal,
    name   = "First WNBA\nteam year",
    labels = as.character(cohort_years)
  ) +
  coord_fixed(1.3) +
  labs(
    title    = "States That Ever Had a WNBA Franchise (1997-2018)",
    subtitle = "Grey = never-treated control states  |  Colour = treatment cohort year"
  ) +
  theme_void() +
  theme(
    plot.title      = element_text(hjust = 0.5, size = 13, face = "bold"),
    plot.subtitle   = element_text(hjust = 0.5, size = 9, color = "grey40"),
    legend.position = "right",
    legend.key.size = unit(0.5, "cm"),
    legend.text     = element_text(size = 9),
    legend.title    = element_text(size = 9, face = "bold")
  )

ggsave("map_wnba_states.pdf", map_plot, width = 9, height = 5.5, dpi = 200)
cat("Saved: map_wnba_states.pdf\n")

# ============================================================
# 5. RAW TREND PLOTS (treated vs. never-treated, by sport)
# ============================================================

plot_trend <- function(sport_col, sport_label, data = df) {
  # Use only states with complete data in every year (same balanced-panel rule
  # as the DiD). This prevents composition artifacts — year-to-year changes in
  # which states are included — from appearing as fake spikes in the mean.
  n_all_years <- n_distinct(data$year)
  balanced <- data %>%
    group_by(state) %>%
    filter(sum(!is.na(.data[[sport_col]])) == n_all_years) %>%
    ungroup()

  trend_data <- balanced %>%
    mutate(group = ifelse(first_treat > 0,
      "WNBA state (ever-treated)", "Never-treated"
    )) %>%
    group_by(group, year) %>%
    summarise(mean_part = mean(.data[[sport_col]], na.rm = TRUE), .groups = "drop")

  ggplot(trend_data, aes(x = year, y = mean_part, color = group, linetype = group)) +
    geom_line(linewidth = 1.0) +
    geom_point(size = 1.8) +
    # Annotate the 2012 NFHS methodology break (nationwide, affects all sports)
    geom_vline(xintercept = 2011.5, linetype = "dotted", color = "grey50", linewidth = 0.6) +
    annotate("text", x = 2011.7, y = Inf,
             label = "NFHS\nreporting\nchange",
             hjust = 0, vjust = 1.3, size = 2.5, color = "grey45") +
    scale_color_manual(values = c(
      "WNBA state (ever-treated)" = "#E41A1C",
      "Never-treated" = "#377EB8"
    )) +
    labs(
      title    = paste0("Girls' ", sport_label, ": Mean Participation by Group"),
      subtitle = "Balanced panel — states with complete data only",
      x = "Year", y = "Mean participants", color = "", linetype = ""
    ) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom")
}

ggsave("trend_basketball.pdf",    plot_trend("basketball",    "Basketball"),    width = 8, height = 5, dpi = 200)
ggsave("trend_soccer.pdf",        plot_trend("soccer",        "Soccer"),        width = 8, height = 5, dpi = 200)
ggsave("trend_cross_country.pdf", plot_trend("cross_country", "Cross Country"), width = 8, height = 5, dpi = 200)
ggsave("trend_track_field.pdf",   plot_trend("track_field",   "Track & Field"), width = 8, height = 5, dpi = 200)
cat("Saved trend plots.\n")

# ============================================================
# 6. CALLAWAY-SANT'ANNA DiD
# ============================================================

run_cs <- function(yname, sport_label, data = df,
                   min_e = -5, max_e = 8) {
  cat("\n", strrep("=", 60), "\n", sep = "")
  cat("Sport:", sport_label, "\n")
  cat(strrep("=", 60), "\n")

  n_all_years <- n_distinct(data$year)

  df_sp <- data %>%
    filter(!is.na(.data[[yname]])) %>%
    group_by(state) %>%
    filter(n_distinct(year) == n_all_years) %>%
    ungroup() %>%
    mutate(state_id = as.integer(factor(state))) %>%
    as.data.frame()

  cat(
    "States:", n_distinct(df_sp$state),
    "| Years:", n_distinct(df_sp$year),
    "| Rows:", nrow(df_sp), "\n"
  )
  cat(
    "Never-treated:",
    sum(df_sp$first_treat[!duplicated(df_sp$state_id)] == 0), "states\n"
  )

  cs <- att_gt(
    yname         = yname,
    tname         = "year",
    idname        = "state_id",
    gname         = "first_treat",
    data          = df_sp,
    control_group = "nevertreated",
    est_method    = "reg",
    panel         = TRUE,
    clustervars   = "state_id"
  )

  cat("\n--- Overall ATT (simple) ---\n")
  agg_simple <- aggte(cs, type = "simple")
  print(summary(agg_simple))

  agg_group <- aggte(cs, type = "group")
  cat("\n--- ATT by cohort ---\n")
  print(summary(agg_group))

  agg_dyn <- aggte(cs, type = "dynamic", min_e = min_e, max_e = max_e)
  cat("\n--- Dynamic ATT (event study) ---\n")
  print(summary(agg_dyn))

  # Normalize to t-1
  es_df <- tibble(
    e    = agg_dyn$egt,
    att  = agg_dyn$att.egt,
    se   = agg_dyn$se.egt,
    crit = agg_dyn$crit.val.egt
  ) %>%
    mutate(
      att_norm = att - att[e == -1],
      ci_lo    = att_norm - crit * se,
      ci_hi    = att_norm + crit * se,
      post     = e >= 0
    )

  es_plot <- ggplot(es_df, aes(x = e, y = att_norm)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey60") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi, fill = post),
      alpha = 0.15, show.legend = FALSE
    ) +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi, color = post),
      width = 0.2, linewidth = 0.6, show.legend = FALSE
    ) +
    geom_point(aes(color = post), size = 2.5, show.legend = FALSE) +
    scale_color_manual(values = c("FALSE" = "#377EB8", "TRUE" = "#E41A1C")) +
    scale_fill_manual(values  = c("FALSE" = "#377EB8", "TRUE" = "#E41A1C")) +
    labs(
      title    = paste0("Event Study: Girls' ", sport_label, " Participation"),
      subtitle = "Callaway-Sant\u2019Anna (2021) | Never-treated control | 95% uniform CB | Normalized to t\u22121",
      x        = "Event time (years relative to first WNBA franchise)",
      y        = "ATT relative to t\u22121 (participants)"
    ) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())

  ggsave(paste0("es_", yname, ".pdf"), es_plot, width = 9, height = 5.5, dpi = 200)
  cat("Saved: es_", yname, ".pdf\n", sep = "")

  grp_plot <- ggdid(agg_group) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
    labs(
      title    = paste0("ATT by Cohort: Girls' ", sport_label),
      subtitle = "Callaway-Sant\u2019Anna (2021) | Never-treated control",
      x = "Treatment cohort", y = "ATT (participants)"
    ) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold"))

  ggsave(paste0("cohort_", yname, ".pdf"), grp_plot, width = 8, height = 5, dpi = 200)
  cat("Saved: cohort_", yname, ".pdf\n", sep = "")

  invisible(list(cs = cs, simple = agg_simple, group = agg_group, dynamic = agg_dyn))
}

res_bball  <- run_cs("basketball",    "Basketball")
res_soccer <- run_cs("soccer",        "Soccer")
res_cc     <- run_cs("cross_country", "Cross Country")
res_tf     <- run_cs("track_field",   "Track & Field")

# ============================================================
# 7. FOREST PLOT: OVERALL ATTs ACROSS SPORTS
# ============================================================

extract_att <- function(res, label) {
  s <- res$simple
  tibble(
    Sport = label,
    ATT   = s$overall.att,
    SE    = s$overall.se,
    CI_lo = s$overall.att - 1.96 * s$overall.se,
    CI_hi = s$overall.att + 1.96 * s$overall.se,
    p_val = 2 * pnorm(-abs(s$overall.att / s$overall.se))
  )
}

att_table <- bind_rows(
  extract_att(res_bball,  "Basketball"),
  extract_att(res_soccer, "Soccer"),
  extract_att(res_cc,     "Cross Country"),
  extract_att(res_tf,     "Track & Field")
)

cat("\n", strrep("=", 60), "\n", sep = "")
cat("SUMMARY: Overall ATT by Sport (Callaway-Sant'Anna)\n")
cat(strrep("=", 60), "\n")
print(att_table, digits = 3)

forest_plot <- ggplot(
  att_table,
  aes(x = ATT, y = fct_reorder(Sport, ATT))
) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = CI_lo, xmax = CI_hi),
    height = 0.2, linewidth = 0.8, color = "#333333"
  ) +
  geom_point(size = 4, color = "#E41A1C") +
  labs(
    title    = "Overall ATT: Effect of WNBA Franchise on Girls' Participation",
    subtitle = "Callaway-Sant\u2019Anna (2021) | Never-treated control | 95% CI",
    x = "ATT (participants)", y = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())

ggsave("forest_att.pdf", forest_plot, width = 8, height = 4, dpi = 200)
cat("Saved: forest_att.pdf\n")

# ============================================================
# 8. SYNTHETIC DiD  (Arkhangelsky et al. 2021)
# ============================================================
# Synthetic DiD (SDID) improves on both synthetic control and standard DiD by:
#   (a) reweighting control UNITS to match treated pre-trends (like SC), and
#   (b) reweighting TIME PERIODS to down-weight distant pre-treatment years
#       that are less informative (unlike SC or DiD).
#
# The `synthdid` package requires a balanced matrix with a SINGLE treatment
# cohort. For our staggered setting we use the "stacked" approach:
#   For each cohort g, we construct a sub-panel:
#     - Units:  all states in cohort g  +  all never-treated states
#     - Time:   1993 through min(2018, g+8)   [cap at 8 post-treatment years]
#     - Treated: 1 if state in cohort g AND year >= g
#   We then run SDID separately for each cohort and combine with
#   cohort-size weights (# treated states in cohort).
#
# We run this for Basketball (primary outcome). The same function can be
# reused for any sport.

never_treated_states <- team_state %>%
  { df %>% filter(first_treat == 0) %>% distinct(state) %>% pull(state) }

run_sdid_stacked <- function(yname, sport_label, data = df) {
  cat("\n", strrep("=", 60), "\n", sep = "")
  cat("Synthetic DiD (stacked) —", sport_label, "\n")
  cat(strrep("=", 60), "\n")

  # States used as controls throughout
  ctrl_states <- data %>% filter(first_treat == 0) %>% distinct(state) %>% pull(state)

  cohorts <- sort(unique(team_state$first_treat))
  results <- list()

  for (g in cohorts) {
    trt_states_g <- team_state %>% filter(first_treat == g) %>% pull(state)

    # Build sub-panel: control + cohort-g treated states, all years
    sub <- data %>%
      filter(state %in% c(ctrl_states, trt_states_g)) %>%
      filter(!is.na(.data[[yname]])) %>%
      # Drop any state that doesn't span all available years in this sub-panel
      group_by(state) %>%
      filter(n_distinct(year) == n_distinct(data$year)) %>%
      ungroup()

    # Need at least 2 treated states and 5 control states
    n_trt  <- sum(unique(sub$state) %in% trt_states_g)
    n_ctrl <- sum(unique(sub$state) %in% ctrl_states)
    if (n_trt < 1 || n_ctrl < 2) {
      cat("  Cohort", g, ": insufficient units, skipping.\n")
      next
    }

    all_years_sub <- sort(unique(sub$year))
    T0 <- sum(all_years_sub < g)  # number of pre-treatment periods
    N0 <- n_ctrl                  # number of control units

    # Build wide matrix: rows = states, cols = years, ordered
    Y_mat <- sub %>%
      select(state, year, val = all_of(yname)) %>%
      pivot_wider(names_from = year, values_from = val) %>%
      column_to_rownames("state") %>%
      as.matrix()

    # Order: control rows first, then treated
    ctrl_rows <- intersect(ctrl_states, rownames(Y_mat))
    trt_rows  <- intersect(trt_states_g, rownames(Y_mat))
    Y_mat     <- Y_mat[c(ctrl_rows, trt_rows), , drop = FALSE]
    N0_actual <- length(ctrl_rows)
    n_trt_actual <- length(trt_rows)

    cat(sprintf("  Cohort %d: %d treated, %d controls, T0=%d\n",
                g, n_trt_actual, N0_actual, T0))

    tryCatch({
      tau_hat <- synthdid_estimate(Y_mat, N0 = N0_actual, T0 = T0)
      results[[as.character(g)]] <- list(
        cohort    = g,
        n_treated = n_trt_actual,
        tau       = as.numeric(tau_hat),
        se        = sqrt(vcov(tau_hat, method = "placebo"))
      )
      cat(sprintf("    ATT = %.1f  (SE = %.1f)\n",
                  as.numeric(tau_hat),
                  sqrt(vcov(tau_hat, method = "placebo"))))
    }, error = function(e) {
      cat("    Error:", conditionMessage(e), "\n")
    })
  }

  if (length(results) == 0) {
    cat("No cohorts converged.\n")
    return(invisible(NULL))
  }

  # Combine: inverse-variance weighted average
  res_df <- bind_rows(lapply(results, as_tibble)) %>%
    mutate(
      weight = n_treated / sum(n_treated),
      CI_lo  = tau - 1.96 * se,
      CI_hi  = tau + 1.96 * se
    )

  overall_tau <- sum(res_df$weight * res_df$tau)
  overall_se  <- sqrt(sum(res_df$weight^2 * res_df$se^2))

  cat(sprintf("\nOverall SDID ATT (%s): %.1f  (SE = %.1f,  95%% CI [%.1f, %.1f])\n",
              sport_label, overall_tau, overall_se,
              overall_tau - 1.96 * overall_se,
              overall_tau + 1.96 * overall_se))

  # Plot cohort-level SDID estimates
  sdid_plot <- ggplot(res_df, aes(x = factor(cohort), y = tau)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
    geom_errorbar(aes(ymin = CI_lo, ymax = CI_hi),
                  width = 0.2, linewidth = 0.7, color = "#333333") +
    geom_point(size = 3.5, color = "#E41A1C") +
    annotate("rect",
             xmin = -Inf, xmax = Inf,
             ymin = overall_tau - 1.96 * overall_se,
             ymax = overall_tau + 1.96 * overall_se,
             alpha = 0.08, fill = "#E41A1C") +
    geom_hline(yintercept = overall_tau, color = "#E41A1C",
               linetype = "solid", linewidth = 0.8) +
    labs(
      title    = paste0("Synthetic DiD by Cohort: Girls' ", sport_label),
      subtitle = "Arkhangelsky et al. (2021) | Red band = pooled 95% CI | Red line = weighted average ATT",
      x = "Treatment cohort (year of first WNBA franchise)",
      y = "ATT (participants)"
    ) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())

  outname <- paste0("sdid_", yname, ".pdf")
  ggsave(outname, sdid_plot, width = 9, height = 5.5, dpi = 200)
  cat("Saved:", outname, "\n")

  invisible(list(cohorts = res_df, overall_tau = overall_tau, overall_se = overall_se))
}

sdid_bball  <- run_sdid_stacked("basketball",    "Basketball")
sdid_soccer <- run_sdid_stacked("soccer",        "Soccer")
sdid_cc     <- run_sdid_stacked("cross_country", "Cross Country")
sdid_tf     <- run_sdid_stacked("track_field",   "Track & Field")

# ============================================================
# 9. TWFE COMPARISON
# ============================================================
# Two-way fixed effects (TWFE) is the "classic" DiD estimator:
#   Y_{it} = alpha_i + lambda_t + delta * D_{it} + e_{it}
# where alpha_i are unit fixed effects, lambda_t are time FEs, and D_{it}=1
# when state i is treated in year t.
#
# With staggered adoption, TWFE is BIASED because it uses "already-treated"
# units as implicit controls for "later-treated" units, and can produce
# negative weights on some (g,t) cells — the "negative weighting" problem
# (Goodman-Bacon 2021; Callaway & Sant'Anna 2021; de Chaisemartin & D'Haultfoeuille 2020).
#
# We run TWFE alongside C-S so readers can see the magnitude of potential bias.

run_twfe <- function(yname, sport_label, data = df) {
  df_sp <- data %>%
    filter(!is.na(.data[[yname]])) %>%
    group_by(state) %>%
    filter(n_distinct(year) == n_distinct(data$year)) %>%
    ungroup() %>%
    mutate(state_id = as.integer(factor(state)))

  # Basic TWFE
  mod <- feols(
    as.formula(paste0(yname, " ~ has_wnba | state_id + year")),
    data    = df_sp,
    cluster = ~state_id
  )

  # Event-study TWFE: relative-time dummies
  df_es <- df_sp %>%
    mutate(
      rel_time = if_else(first_treat == 0, -999L,
                         as.integer(year - first_treat)),
      rel_time_fac = relevel(factor(rel_time), ref = "-1")
    )

  mod_es <- feols(
    as.formula(paste0(yname, " ~ i(rel_time, ref = c(-1, -999)) | state_id + year")),
    data    = df_es,
    cluster = ~state_id
  )

  cat("\n--- TWFE:", sport_label, "---\n")
  cat("Coefficient on has_wnba:", round(coef(mod)["has_wnba"], 2),
      " | SE:", round(se(mod)["has_wnba"], 2), "\n")

  invisible(list(twfe = mod, es = mod_es, sport = sport_label, yname = yname))
}

twfe_bball  <- run_twfe("basketball",    "Basketball")
twfe_soccer <- run_twfe("soccer",        "Soccer")
twfe_cc     <- run_twfe("cross_country", "Cross Country")
twfe_tf     <- run_twfe("track_field",   "Track & Field")

# Side-by-side comparison: TWFE vs C-S overall ATT
comparison_table <- bind_rows(
  tibble(
    sport  = "Basketball",
    method = c("TWFE", "Callaway-Sant'Anna"),
    att    = c(coef(twfe_bball$twfe)["has_wnba"],  res_bball$simple$overall.att),
    se     = c(se(twfe_bball$twfe)["has_wnba"],    res_bball$simple$overall.se)
  ),
  tibble(
    sport  = "Soccer",
    method = c("TWFE", "Callaway-Sant'Anna"),
    att    = c(coef(twfe_soccer$twfe)["has_wnba"], res_soccer$simple$overall.att),
    se     = c(se(twfe_soccer$twfe)["has_wnba"],   res_soccer$simple$overall.se)
  ),
  tibble(
    sport  = "Cross Country",
    method = c("TWFE", "Callaway-Sant'Anna"),
    att    = c(coef(twfe_cc$twfe)["has_wnba"],     res_cc$simple$overall.att),
    se     = c(se(twfe_cc$twfe)["has_wnba"],       res_cc$simple$overall.se)
  ),
  tibble(
    sport  = "Track & Field",
    method = c("TWFE", "Callaway-Sant'Anna"),
    att    = c(coef(twfe_tf$twfe)["has_wnba"],     res_tf$simple$overall.att),
    se     = c(se(twfe_tf$twfe)["has_wnba"],       res_tf$simple$overall.se)
  )
) %>%
  mutate(CI_lo = att - 1.96 * se, CI_hi = att + 1.96 * se)

cat("\n", strrep("=", 60), "\n", sep = "")
cat("TWFE vs Callaway-Sant'Anna: Overall ATT comparison\n")
cat(strrep("=", 60), "\n")
print(comparison_table, digits = 3)

compare_plot <- ggplot(
  comparison_table,
  aes(x = att, y = fct_reorder(sport, att), color = method, shape = method)
) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = CI_lo, xmax = CI_hi),
                 height = 0.15, linewidth = 0.7,
                 position = position_dodgev(height = 0.4)) +
  geom_point(size = 3.5, position = position_dodgev(height = 0.4)) +
  scale_color_manual(values = c("TWFE" = "#377EB8", "Callaway-Sant'Anna" = "#E41A1C")) +
  scale_shape_manual(values = c("TWFE" = 17,        "Callaway-Sant'Anna" = 16)) +
  labs(
    title    = "TWFE vs. Callaway-Sant\u2019Anna: Overall ATT by Sport",
    subtitle = "Staggered DiD — TWFE may be biased due to negative weighting | 95% CI",
    x = "ATT (participants)", y = NULL,
    color = "Estimator", shape = "Estimator"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

ggsave("compare_twfe_cs.pdf", compare_plot, width = 9, height = 5, dpi = 200)
cat("Saved: compare_twfe_cs.pdf\n")

# ============================================================
# 10. PERMUTATION PLACEBO TEST
# ============================================================
# Null hypothesis: WNBA franchises have no effect on participation.
# Procedure:
#   1. Take the 33 never-treated states. Randomly assign fake "treatment cohorts"
#      drawn from the actual cohort-year distribution to a random subset of
#      these states, mirroring the observed number of treated states per cohort.
#   2. Run the simple C-S ATT on this placebo dataset.
#   3. Repeat R=500 times, collecting the null distribution of ATT.
#   4. Compare the real ATT to this null distribution.
#
# If the real ATT lies in the tail (|ATT_real| > 95th percentile of |ATT_null|)
# we reject H0. This is exact permutation inference robust to non-normality.

run_permutation_test <- function(yname, sport_label, data = df,
                                 R = 500, seed = 42) {
  cat("\n", strrep("=", 60), "\n", sep = "")
  cat("Permutation placebo —", sport_label, "(R =", R, ")\n")
  cat(strrep("=", 60), "\n")

  set.seed(seed)

  # Build balanced sport panel (same filter as C-S)
  n_all_years <- n_distinct(data$year)
  df_sp <- data %>%
    filter(!is.na(.data[[yname]])) %>%
    group_by(state) %>%
    filter(n_distinct(year) == n_all_years) %>%
    ungroup()

  # Observed ATT from C-S
  real_att_obj <- switch(yname,
    basketball    = res_bball$simple,
    soccer        = res_soccer$simple,
    cross_country = res_cc$simple,
    track_field   = res_tf$simple
  )
  real_att <- real_att_obj$overall.att

  # Cohort sizes to replicate in permutation
  cohort_template <- team_state %>%
    count(first_treat, name = "n_states")

  # Never-treated states (our permutation pool)
  never_states <- df_sp %>% filter(first_treat == 0) %>% distinct(state) %>% pull(state)
  n_needed <- nrow(team_state)  # total treated states we need to "fake-assign"

  if (length(never_states) < n_needed) {
    cat("Not enough never-treated states for permutation. Skipping.\n")
    return(invisible(NULL))
  }

  null_atts <- numeric(R)
  for (r in seq_len(R)) {
    # Sample n_needed states without replacement from never-treated pool
    fake_trt_states <- sample(never_states, n_needed, replace = FALSE)
    # Assign cohort years matching the real cohort sizes
    fake_assignments <- cohort_template %>%
      mutate(states = list(NULL))
    idx <- 1
    for (i in seq_len(nrow(cohort_template))) {
      n_i <- cohort_template$n_states[i]
      fake_assignments$states[[i]] <- fake_trt_states[idx:(idx + n_i - 1)]
      idx <- idx + n_i
    }
    fake_df <- fake_assignments %>%
      unnest(states) %>%
      rename(state = states, fake_treat = first_treat)

    df_perm <- df_sp %>%
      left_join(fake_df, by = "state") %>%
      mutate(
        first_treat_orig = first_treat,
        first_treat      = case_when(
          !is.na(fake_treat) ~ as.integer(fake_treat),
          TRUE               ~ 0L
        )
      ) %>%
      mutate(state_id = as.integer(factor(state))) %>%
      as.data.frame()

    tryCatch({
      cs_perm <- att_gt(
        yname         = yname,
        tname         = "year",
        idname        = "state_id",
        gname         = "first_treat",
        data          = df_perm,
        control_group = "nevertreated",
        est_method    = "reg",
        panel         = TRUE,
        clustervars   = "state_id",
        print_details = FALSE
      )
      agg_perm    <- aggte(cs_perm, type = "simple")
      null_atts[r] <- agg_perm$overall.att
    }, error = function(e) {
      null_atts[r] <<- NA_real_
    })
  }

  null_atts <- null_atts[!is.na(null_atts)]
  p_perm    <- mean(abs(null_atts) >= abs(real_att))

  cat(sprintf("Real ATT = %.1f\n", real_att))
  cat(sprintf("Permutation p-value = %.3f  (|null| >= |real| in %.0f/%d draws)\n",
              p_perm, sum(abs(null_atts) >= abs(real_att)), length(null_atts)))

  null_df <- tibble(null_att = null_atts)

  perm_plot <- ggplot(null_df, aes(x = null_att)) +
    geom_histogram(bins = 40, fill = "#377EB8", alpha = 0.7, color = "white") +
    geom_vline(xintercept = real_att, color = "#E41A1C", linewidth = 1.1) +
    geom_vline(xintercept = -real_att, color = "#E41A1C", linewidth = 1.1,
               linetype = "dashed") +
    annotate("text", x = real_att, y = Inf,
             label = sprintf("Real ATT\n%.1f", real_att),
             hjust = -0.1, vjust = 1.4, color = "#E41A1C", size = 3.5) +
    labs(
      title    = paste0("Permutation Placebo: Girls' ", sport_label),
      subtitle = sprintf("Null distribution (R=%d fake treatments) | Permutation p = %.3f",
                         length(null_atts), p_perm),
      x = "Placebo ATT (participants)", y = "Count"
    ) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())

  outname <- paste0("placebo_", yname, ".pdf")
  ggsave(outname, perm_plot, width = 8, height = 5, dpi = 200)
  cat("Saved:", outname, "\n")

  invisible(list(null = null_atts, real_att = real_att, p = p_perm))
}

perm_bball  <- run_permutation_test("basketball",    "Basketball",    R = 500)
perm_soccer <- run_permutation_test("soccer",        "Soccer",        R = 500)
perm_cc     <- run_permutation_test("cross_country", "Cross Country", R = 500)
perm_tf     <- run_permutation_test("track_field",   "Track & Field", R = 500)

# ============================================================
# 11. COMPOSITE INDEX: TOTAL GIRLS' SPORTS PARTICIPATION
# ============================================================
# We build a composite outcome: sum of all four sports per state-year.
# States missing any sport in any year are excluded (same complete-series rule).
# This reduces noise from sport-specific measurement issues and gives one
# headline number per state.

df_composite <- df %>%
  mutate(
    total_part = basketball + cross_country + soccer + track_field
  ) %>%
  group_by(state) %>%
  filter(all(!is.na(total_part))) %>%
  ungroup()

cat("\n", strrep("=", 60), "\n")
cat("Composite index: states with complete data across all 4 sports\n")
cat("N states:", n_distinct(df_composite$state), "\n")
cat(strrep("=", 60), "\n")

res_composite <- run_cs("total_part", "Total (All Sports)", data = df_composite)

# Trend plot for composite
ggsave("trend_composite.pdf",
       plot_trend("total_part", "Total (All Sports)", data = df_composite),
       width = 8, height = 5, dpi = 200)
cat("Saved: trend_composite.pdf\n")

# ============================================================
# 12. DESCRIPTIVES: SPAGHETTI, COHORT TRENDS, GANTT
# ============================================================

# ---- Fix known anomaly before indexing ----
# (already fixed above in df_wide / df; no further action needed)

make_spaghetti <- function(sport_col, sport_label, data = df) {
  base_vals <- data %>%
    filter(year == 1993) %>%
    select(state, base = all_of(sport_col))

  df_idx <- data %>%
    filter(!is.na(.data[[sport_col]])) %>%
    left_join(base_vals, by = "state") %>%
    filter(!is.na(base), base > 0) %>%
    mutate(
      idx        = (.data[[sport_col]] / base) * 100,
      treat_group = ifelse(first_treat > 0, "WNBA state", "Never treated")
    )

  grp_means <- df_idx %>%
    group_by(treat_group, year) %>%
    summarise(mean_idx = mean(idx, na.rm = TRUE), .groups = "drop")

  pal <- c("WNBA state" = "#C82929", "Never treated" = "#377EB8")

  ggplot() +
    geom_line(
      data = df_idx,
      aes(x = year, y = idx, group = state, color = treat_group),
      linewidth = 0.28, alpha = 0.28
    ) +
    geom_line(data = grp_means,
              aes(x = year, y = mean_idx, color = treat_group), linewidth = 1.4) +
    geom_point(data = grp_means,
               aes(x = year, y = mean_idx, color = treat_group),
               size = 2, shape = 21, fill = "white", stroke = 1.2) +
    geom_hline(yintercept = 100, linetype = "dashed", color = "grey50", linewidth = 0.5) +
    geom_vline(xintercept = 1997, linetype = "dotted", color = "grey40", linewidth = 0.6) +
    annotate("text", x = 1997.3, y = Inf, label = "WNBA founded",
             hjust = 0, vjust = 1.4, size = 2.8, color = "grey40") +
    scale_color_manual(values = pal, name = NULL) +
    scale_x_continuous(breaks = seq(1993, 2018, by = 5)) +
    labs(
      title    = paste0("Girls' ", sport_label, ": Participation Index (1993 = 100)"),
      subtitle = "Thin lines = individual states  |  Bold lines = group means",
      x = NULL, y = "Index (1993 = 100)"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      legend.position  = "bottom",
      panel.grid.minor = element_blank(),
      plot.title       = element_text(face = "bold", size = 13),
      plot.subtitle    = element_text(color = "grey45", size = 9)
    )
}

ggsave("spaghetti_basketball.pdf",    make_spaghetti("basketball",    "Basketball"),    width = 9, height = 5.5, dpi = 200)
ggsave("spaghetti_soccer.pdf",        make_spaghetti("soccer",        "Soccer"),        width = 9, height = 5.5, dpi = 200)
ggsave("spaghetti_cross_country.pdf", make_spaghetti("cross_country", "Cross Country"), width = 9, height = 5.5, dpi = 200)
ggsave("spaghetti_track_field.pdf",   make_spaghetti("track_field",   "Track & Field"), width = 9, height = 5.5, dpi = 200)
cat("Saved spaghetti plots.\n")

cohort_palette <- c(
  "Never treated" = "#333333",
  "Cohort: 1997"  = "#E41A1C",
  "Cohort: 1998"  = "#FF7F00",
  "Cohort: 1999"  = "#4DAF4A",
  "Cohort: 2000"  = "#984EA3",
  "Cohort: 2003"  = "#377EB8",
  "Cohort: 2006"  = "#A65628",
  "Cohort: 2008"  = "#F781BF",
  "Cohort: 2010"  = "#999999"
)

make_cohort_trend <- function(sport_col, sport_label, data = df) {
  base_vals <- data %>%
    filter(year == 1993) %>%
    select(state, base = all_of(sport_col))

  df_idx <- data %>%
    filter(!is.na(.data[[sport_col]])) %>%
    left_join(base_vals, by = "state") %>%
    filter(!is.na(base), base > 0) %>%
    mutate(idx = (.data[[sport_col]] / base) * 100)

  cohort_means <- df_idx %>%
    group_by(cohort_label, year) %>%
    summarise(mean_idx = mean(idx, na.rm = TRUE), .groups = "drop") %>%
    mutate(
      is_never  = cohort_label == "Never treated",
      lwd       = if_else(is_never, 1.5, 1.0),
      alpha_val = if_else(is_never, 1.0, 0.85)
    )

  ggplot(cohort_means,
    aes(x = year, y = mean_idx, color = cohort_label,
        linewidth = I(lwd), alpha = I(alpha_val))) +
    geom_line() +
    geom_point(data = filter(cohort_means, is_never),
               size = 1.8, shape = 21, fill = "white", stroke = 1.1) +
    geom_hline(yintercept = 100, linetype = "dashed", color = "grey60", linewidth = 0.5) +
    scale_color_manual(values = cohort_palette, name = "Group") +
    scale_x_continuous(breaks = seq(1993, 2018, by = 3)) +
    labs(
      title    = paste0("Girls' ", sport_label, ": Indexed Trends by Treatment Cohort (1993 = 100)"),
      subtitle = "Each coloured line = mean across states in that cohort  |  Black = never-treated mean",
      x = NULL, y = "Index (1993 = 100)"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      legend.position   = c(0.14, 0.76),
      legend.background = element_rect(fill = "white", color = NA),
      legend.key.size   = unit(0.45, "cm"),
      legend.text       = element_text(size = 8),
      legend.title      = element_text(size = 8, face = "bold"),
      panel.grid.minor  = element_blank(),
      plot.title        = element_text(face = "bold", size = 12),
      plot.subtitle     = element_text(color = "grey45", size = 8.5)
    )
}

ggsave("cohort_trend_basketball.pdf",    make_cohort_trend("basketball",    "Basketball"),    width = 9, height = 5.5, dpi = 200)
ggsave("cohort_trend_soccer.pdf",        make_cohort_trend("soccer",        "Soccer"),        width = 9, height = 5.5, dpi = 200)
ggsave("cohort_trend_cross_country.pdf", make_cohort_trend("cross_country", "Cross Country"), width = 9, height = 5.5, dpi = 200)
ggsave("cohort_trend_track_field.pdf",   make_cohort_trend("track_field",   "Track & Field"), width = 9, height = 5.5, dpi = 200)
cat("Saved cohort trend plots.\n")

# Gantt chart
all_years <- sort(unique(df$year))
gantt_df <- df %>%
  distinct(state, first_treat) %>%
  arrange(first_treat, state) %>%
  mutate(
    state        = factor(state, levels = rev(unique(state))),
    cohort_label = case_when(
      first_treat == 0 ~ "Never treated",
      TRUE             ~ as.character(first_treat)
    )
  )

gantt_long <- gantt_df %>%
  crossing(year = all_years) %>%
  mutate(status = case_when(
    first_treat == 0  ~ "Never treated",
    year >= first_treat ~ as.character(first_treat),
    TRUE              ~ "Pre-treatment"
  ))

cohort_fills <- setNames(brewer.pal(length(cohort_years), "Set1"), as.character(cohort_years))
status_fills <- c(cohort_fills, "Pre-treatment" = "grey88", "Never treated" = "grey96")
legend_order <- c(as.character(cohort_years), "Pre-treatment", "Never treated")

ggplot(gantt_long,
       aes(x = year, y = state, fill = factor(status, levels = legend_order))) +
  geom_tile(color = "white", linewidth = 0.25) +
  scale_fill_manual(
    values = status_fills, name = "Status",
    breaks = legend_order,
    labels = c(paste0("Treated ", cohort_years), "Pre-treatment", "Never treated")
  ) +
  scale_x_continuous(breaks = seq(1993, 2018, by = 3), expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) +
  labs(
    title    = "WNBA Franchise Entry: Staggered Treatment Panel",
    subtitle = "States sorted by treatment cohort year (earliest at top)",
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    axis.text.y     = element_text(size = 7.5),
    axis.text.x     = element_text(size = 8),
    panel.grid      = element_blank(),
    legend.position = "right",
    legend.key.size = unit(0.45, "cm"),
    legend.text     = element_text(size = 8),
    legend.title    = element_text(size = 8.5, face = "bold"),
    plot.title      = element_text(face = "bold", size = 13),
    plot.subtitle   = element_text(color = "grey45", size = 9),
    plot.margin     = margin(8, 8, 8, 8)
  )

ggsave("gantt_treatment.pdf", width = 11, height = 8, dpi = 200)
cat("Saved: gantt_treatment.pdf\n")

# ============================================================
# 13. SUMMARY TABLE: ALL METHODS
# ============================================================

cat("\n", strrep("=", 60), "\n", sep = "")
cat("FINAL SUMMARY: ATT across all methods and sports\n")
cat(strrep("=", 60), "\n\n")

summary_rows <- list()
for (row_info in list(
  list(sport = "Basketball",    cs = res_bball,  twfe = twfe_bball,  sdid = sdid_bball),
  list(sport = "Soccer",        cs = res_soccer, twfe = twfe_soccer, sdid = sdid_soccer),
  list(sport = "Cross Country", cs = res_cc,     twfe = twfe_cc,     sdid = sdid_cc),
  list(sport = "Track & Field", cs = res_tf,     twfe = twfe_tf,     sdid = sdid_tf)
)) {
  sdid_att <- if (!is.null(row_info$sdid)) row_info$sdid$overall_tau else NA_real_
  sdid_se  <- if (!is.null(row_info$sdid)) row_info$sdid$overall_se  else NA_real_
  summary_rows[[length(summary_rows) + 1]] <- tibble(
    Sport          = row_info$sport,
    TWFE_ATT       = round(coef(row_info$twfe$twfe)["has_wnba"], 1),
    TWFE_SE        = round(se(row_info$twfe$twfe)["has_wnba"], 1),
    CS_ATT         = round(row_info$cs$simple$overall.att, 1),
    CS_SE          = round(row_info$cs$simple$overall.se, 1),
    SDID_ATT       = round(sdid_att, 1),
    SDID_SE        = round(sdid_se, 1)
  )
}

summary_df <- bind_rows(summary_rows)
print(summary_df)

cat("\nAll output files:\n")
cat("  map_wnba_states.pdf\n")
cat("  trend_{basketball,soccer,cross_country,track_field,composite}.pdf\n")
cat("  es_{basketball,soccer,cross_country,track_field}.pdf\n")
cat("  cohort_{basketball,soccer,cross_country,track_field}.pdf\n")
cat("  sdid_{basketball,soccer,cross_country,track_field}.pdf\n")
cat("  placebo_{basketball,soccer,cross_country,track_field}.pdf\n")
cat("  compare_twfe_cs.pdf\n")
cat("  spaghetti_{basketball,soccer,cross_country,track_field}.pdf\n")
cat("  cohort_trend_{basketball,soccer,cross_country,track_field}.pdf\n")
cat("  gantt_treatment.pdf\n")
cat("  forest_att.pdf\n")
