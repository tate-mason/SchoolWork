# WNBA_proj.R
# Effect of a WNBA Team on Girls' Sports Participation
# Data: master_scraped.csv  (51 states x 26 academic years, wide format)
# Design: Callaway-Sant'Anna (2021) staggered DiD

library(tidyverse)
library(ggplot2)
library(did)
library(RColorBrewer)

# ============================================================
# 1. LOAD & CLEAN
# ============================================================

df_wide <- read_csv("../Data/master_scraped.csv")

# Map academic year label -> start year integer (used for C-S tname/gname)
year_map <- c(
  "1993-94"=1993,"1994-95"=1994,"1995-96"=1995,"1996-97"=1996,
  "1997-98"=1997,"1998-99"=1998,"1999-00"=1999,"2000-01"=2000,
  "2001-02"=2001,"2002-03"=2002,"2003-04"=2003,"2004-05"=2004,
  "2005-06"=2005,"2006-07"=2006,"2007-08"=2007,"2008-09"=2008,
  "2009-10"=2009,"2010-11"=2010,"2011-12"=2011,"2012-13"=2012,
  "2013-14"=2013,"2014-15"=2014,"2015-16"=2015,"2016-17"=2016,
  "2017-18"=2017,"2018-19"=2018
)

df_wide <- df_wide %>%
  mutate(year = year_map[year])

# ============================================================
# 2. WNBA TEAM -> STATE FIRST-TREATMENT YEAR
# ============================================================

# Each state mapped to the first calendar year any franchise operated there.
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
    first_treat = replace_na(first_treat, 0L),  # 0 = never treated (CS convention)
    has_wnba    = as.integer(first_treat > 0 & year >= first_treat),
    state_id    = as.integer(factor(state))
  )

cat("=== Panel structure ===\n")
cat("States:", n_distinct(df$state), "| Years:", n_distinct(df$year),
    "| Rows:", nrow(df), "\n")
cat("Perfectly balanced:", nrow(df) == n_distinct(df$state) * n_distinct(df$year), "\n\n")

# ============================================================
# 3. DATA FACTS
# ============================================================

cat("=== Missing values by sport ===\n")
df %>%
  summarise(across(c(basketball, cross_country, soccer, track_field),
                   ~ sum(is.na(.)))) %>%
  print()
# Note: South Dakota soccer is missing in 20 of 26 years (sport not tracked
# historically); it drops from the soccer DiD when we enforce complete series.
# DC is entirely missing in 2018-19 and drops from all DiDs.

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
    basketball    = mean(basketball,    na.rm = TRUE),
    cross_country = mean(cross_country, na.rm = TRUE),
    soccer        = mean(soccer,        na.rm = TRUE),
    track_field   = mean(track_field,   na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\n=== Treatment cohort sizes ===\n")
df %>%
  distinct(state, first_treat) %>%
  count(first_treat) %>%
  mutate(label = ifelse(first_treat == 0, "Never treated",
                        paste0("First treated: ", first_treat))) %>%
  select(label, n) %>%
  print()
#
## ============================================================
## 4. MAP: STATES WITH WNBA TEAMS (colour = first-treatment cohort)
##    Untreated states are grey and NOT shown in the legend.
## ============================================================
#
#cohort_years <- sort(unique(team_state$first_treat))
#n_cohorts    <- length(cohort_years)
#cohort_pal   <- setNames(brewer.pal(n_cohorts, "Set1"), as.character(cohort_years))
#
#map_state_info <- team_state %>%
#  mutate(state_lower = tolower(state))
#
#us_states <- map_data("state")
#map_df    <- us_states %>%
#  left_join(map_state_info, by = c("region" = "state_lower"))
#
#map_plot <- ggplot() +
#  geom_polygon(                          # never-treated: grey, no legend entry
#    data  = filter(map_df, is.na(first_treat)),
#    aes(x = long, y = lat, group = group),
#    fill  = "grey85", color = "white", linewidth = 0.25
#  ) +
#  geom_polygon(                          # treated: colour by cohort year
#    data  = filter(map_df, !is.na(first_treat)),
#    aes(x = long, y = lat, group = group, fill = factor(first_treat)),
#    color = "white", linewidth = 0.25
#  ) +
#  scale_fill_manual(
#    values = cohort_pal,
#    name   = "First WNBA\nteam year",
#    labels = as.character(cohort_years)
#  ) +
#  coord_fixed(1.3) +
#  labs(
#    title    = "States That Ever Had a WNBA Franchise (1997-2018)",
#    subtitle = "Grey = never-treated control states  |  Colour = treatment cohort year"
#  ) +
#  theme_void() +
#  theme(
#    plot.title      = element_text(hjust = 0.5, size = 13, face = "bold"),
#    plot.subtitle   = element_text(hjust = 0.5, size = 9, color = "grey40"),
#    legend.position = "right",
#    legend.key.size = unit(0.5, "cm"),
#    legend.text     = element_text(size = 9),
#    legend.title    = element_text(size = 9, face = "bold")
#  )
#
#print(map_plot)
#ggsave("map_wnba_states.pdf", map_plot, width = 9, height = 5.5, dpi = 200)
#cat("Saved: map_wnba_states.pdf\n")
#
## ============================================================
## 5. RAW TREND PLOTS (treated vs. never-treated, by sport)
## ============================================================
#
#plot_trend <- function(sport_col, sport_label, data = df) {
#  data %>%
#    filter(!is.na(.data[[sport_col]])) %>%
#    mutate(group = ifelse(first_treat > 0,
#                          "WNBA state (ever-treated)", "Never-treated")) %>%
#    group_by(group, year) %>%
#    summarise(mean_part = mean(.data[[sport_col]], na.rm = TRUE), .groups = "drop") %>%
#    ggplot(aes(x = year, y = mean_part, color = group, linetype = group)) +
#    geom_line(linewidth = 1.0) +
#    geom_point(size = 1.8) +
#    scale_color_manual(values = c("WNBA state (ever-treated)" = "#E41A1C",
#                                  "Never-treated"             = "#377EB8")) +
#    labs(
#      title = paste0("Girls' ", sport_label, ": Mean Participation by Group"),
#      x = "Year", y = "Mean participants", color = "", linetype = ""
#    ) +
#    theme_minimal(base_size = 12) +
#    theme(legend.position = "bottom")
#}
#
#ggsave("trend_basketball.pdf",   plot_trend("basketball",    "Basketball"),   width=8, height=5, dpi=200)
#ggsave("trend_soccer.pdf",       plot_trend("soccer",        "Soccer"),       width=8, height=5, dpi=200)
#ggsave("trend_cross_country.pdf",plot_trend("cross_country", "Cross Country"),width=8, height=5, dpi=200)
#ggsave("trend_track_field.pdf",  plot_trend("track_field",   "Track & Field"),width=8, height=5, dpi=200)
#cat("Saved trend plots.\n")
#
## ============================================================
## 6. CALLAWAY-SANT'ANNA DiD
## ============================================================
## control_group = "nevertreated": uses the 33 never-treated states.
## Cleaner assumption than "notyetreated" given we have a large clean control pool.
##
## Balance enforcement: for each sport, drop any state whose outcome is
## missing in at least one year, then check that the remaining panel
## is still balanced (every state x every year present).
#
#run_cs <- function(yname, sport_label, data = df,
#                   min_e = -5, max_e = 8) {
#
#  cat("\n", strrep("=", 60), "\n", sep = "")
#  cat("Sport:", sport_label, "\n")
#  cat(strrep("=", 60), "\n")
#
#  n_all_years <- n_distinct(data$year)
#
#  df_sp <- data %>%
#    filter(!is.na(.data[[yname]])) %>%
#    group_by(state) %>%
#    filter(n_distinct(year) == n_all_years) %>%
#    ungroup() %>%
#    mutate(state_id = as.integer(factor(state))) %>%
#    as.data.frame()
#
#  cat("States:", n_distinct(df_sp$state),
#      "| Years:", n_distinct(df_sp$year),
#      "| Rows:", nrow(df_sp), "\n")
#  cat("Never-treated:",
#      sum(df_sp$first_treat[!duplicated(df_sp$state_id)] == 0), "states\n")
#  cat("Treatment cohorts:\n")
#  df_sp %>% distinct(state_id, first_treat) %>% count(first_treat) %>% print()
#
#  # ---- C-S estimation ----
#  cs <- att_gt(
#    yname         = yname,
#    tname         = "year",
#    idname        = "state_id",
#    gname         = "first_treat",
#    data          = df_sp,
#    control_group = "nevertreated",
#    est_method    = "reg",
#    panel         = TRUE,
#    clustervars   = "state_id"
#  )
#
#  cat("\n--- Group-time ATT(g,t) ---\n")
#  print(summary(cs))
#
#  agg_simple <- aggte(cs, type = "simple")
#  cat("\n--- Overall ATT (simple) ---\n")
#  print(summary(agg_simple))
#
#  agg_group  <- aggte(cs, type = "group")
#  cat("\n--- ATT by cohort ---\n")
#  print(summary(agg_group))
#
#  agg_dyn    <- aggte(cs, type = "dynamic", min_e = min_e, max_e = max_e)
#  cat("\n--- Dynamic ATT (event study) ---\n")
#  print(summary(agg_dyn))
#
#  # Event-study plot
#  es_plot <- ggdid(agg_dyn) +
#    geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
#    labs(
#      title    = paste0("Event Study: Girls' ", sport_label, " Participation"),
#      subtitle = "Callaway-Sant'Anna (2021) | Never-treated control | 95% uniform CB",
#      x        = "Event time (years relative to first WNBA franchise)",
#      y        = "ATT (participants)"
#    ) +
#    theme_minimal(base_size = 12) +
#    theme(plot.title = element_text(face = "bold"),
#          panel.grid.minor = element_blank())
#
#  ggsave(paste0("es_", yname, ".pdf"), es_plot, width = 9, height = 5.5, dpi = 200)
#  cat("Saved: es_", yname, ".pdf\n", sep = "")
#
#  # Cohort ATT plot
#  grp_plot <- ggdid(agg_group) +
#    geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
#    labs(
#      title    = paste0("ATT by Cohort: Girls' ", sport_label),
#      subtitle = "Callaway-Sant'Anna (2021) | Never-treated control",
#      x        = "Treatment cohort", y = "ATT (participants)"
#    ) +
#    theme_minimal(base_size = 12) +
#    theme(plot.title = element_text(face = "bold"))
#
#  ggsave(paste0("cohort_", yname, ".pdf"), grp_plot, width = 8, height = 5, dpi = 200)
#  cat("Saved: cohort_", yname, ".pdf\n", sep = "")
#
#  invisible(list(cs = cs, simple = agg_simple, group = agg_group, dynamic = agg_dyn))
#}
#
#res_bball  <- run_cs("basketball",    "Basketball")
#res_soccer <- run_cs("soccer",        "Soccer")
#res_cc     <- run_cs("cross_country", "Cross Country")
#res_tf     <- run_cs("track_field",   "Track & Field")
#
## ============================================================
## 7. FOREST PLOT: OVERALL ATTs ACROSS SPORTS
## ============================================================
#
#extract_att <- function(res, label) {
#  s <- res$simple
#  tibble(
#    Sport  = label,
#    ATT    = s$overall.att,
#    SE     = s$overall.se,
#    CI_lo  = s$overall.att - 1.96 * s$overall.se,
#    CI_hi  = s$overall.att + 1.96 * s$overall.se,
#    p_val  = 2 * pnorm(-abs(s$overall.att / s$overall.se))
#  )
#}
#
#att_table <- bind_rows(
#  extract_att(res_bball,  "Basketball"),
#  extract_att(res_soccer, "Soccer"),
#  extract_att(res_cc,     "Cross Country"),
#  extract_att(res_tf,     "Track & Field")
#)
#
#cat("\n", strrep("=", 60), "\n", sep = "")
#cat("SUMMARY: Overall ATT by Sport (Callaway-Sant'Anna)\n")
#cat(strrep("=", 60), "\n")
#print(att_table, digits = 3)
#
#forest_plot <- ggplot(att_table,
#                      aes(x = ATT, y = fct_reorder(Sport, ATT))) +
#  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
#  geom_errorbarh(aes(xmin = CI_lo, xmax = CI_hi),
#                 height = 0.2, linewidth = 0.8, color = "#333333") +
#  geom_point(size = 4, color = "#E41A1C") +
#  labs(
#    title    = "Overall ATT: Effect of WNBA Franchise on Girls' Participation",
#    subtitle = "Callaway-Sant'Anna (2021) | Never-treated control | 95% CI",
#    x        = "ATT (participants)", y = NULL
#  ) +
#  theme_minimal(base_size = 12) +
#  theme(plot.title       = element_text(face = "bold"),
#        panel.grid.minor = element_blank())
#
#print(forest_plot)
#ggsave("forest_att.pdf", forest_plot, width = 8, height = 4, dpi = 200)
#cat("Saved: forest_att.pdf\n")
#
#cat("\n--- All output files ---\n")
#cat("  map_wnba_states.pdf\n")
#cat("  trend_{basketball,soccer,cross_country,track_field}.pdf\n")
#cat("  es_{basketball,soccer,cross_country,track_field}.pdf\n")
#cat("  cohort_{basketball,soccer,cross_country,track_field}.pdf\n")
#cat("  forest_att.pdf\n")
#
## descriptives.R
## Three descriptive visualisations for the WNBA / girls' sports project
##   1. Indexed spaghetti plots (participation = 100 in 1993, per sport)
##   2. Cohort-stratified indexed trend lines
##   3. Treatment timing Gantt diagram
##
## Data: master_scraped.csv  (51 states x 26 years, wide format)
#
#library(tidyverse)
#library(ggplot2)
#library(RColorBrewer)
#
## ============================================================
## 0. LOAD & SETUP
## ============================================================
#
#df_wide <- read_csv("../Data/master_scraped.csv")
#
#year_map <- c(
#  "1993-94"=1993,"1994-95"=1994,"1995-96"=1995,"1996-97"=1996,
#  "1997-98"=1997,"1998-99"=1998,"1999-00"=1999,"2000-01"=2000,
#  "2001-02"=2001,"2002-03"=2002,"2003-04"=2003,"2004-05"=2004,
#  "2005-06"=2005,"2006-07"=2006,"2007-08"=2007,"2008-09"=2008,
#  "2009-10"=2009,"2010-11"=2010,"2011-12"=2011,"2012-13"=2012,
#  "2013-14"=2013,"2014-15"=2014,"2015-16"=2015,"2016-17"=2016,
#  "2017-18"=2017,"2018-19"=2018
#)
#
#team_state <- tribble(
#  ~state,            ~first_treat,
#  "New York",        1997, "Texas",           1997, "North Carolina",  1997,
#  "Arizona",         1997, "Ohio",            1997, "California",      1997,
#  "Utah",            1997, "Virginia",        1998, "Michigan",        1998,
#  "Florida",         1999, "Minnesota",       1999, "Oregon",          2000,
#  "Indiana",         2000, "Washington",      2000, "Connecticut",     2003,
#  "Illinois",        2006, "Georgia",         2008, "Oklahoma",        2010
#)
#
#df <- df_wide %>%
#  mutate(year = year_map[year]) %>%
#  left_join(team_state, by = "state") %>%
#  mutate(
#    first_treat  = replace_na(first_treat, 0L),
#    treat_group  = ifelse(first_treat > 0, "WNBA state", "Never treated"),
#    cohort_label = case_when(
#      first_treat == 0    ~ "Never treated",
#      TRUE                ~ paste0("Cohort: ", first_treat)
#    )
#  )
#
## ---- Fix known data anomalies before indexing ----
## Massachusetts soccer 2003: clear entry error (~42k vs ~12k every other year)
#df <- df %>%
#  mutate(soccer = if_else(state == "Massachusetts" & year == 2003, NA_real_, soccer))
#
## Pennsylvania cross country doubles permanently from 2008 — likely a
## reporting methodology change (added indoor XC). We flag but do NOT impute;
## the index will capture the jump honestly. Users should be aware.
#
## ============================================================
## 1. INDEXED SPAGHETTI PLOTS
## ============================================================
## Each state indexed to 100 in 1993. Bold group means overlaid.
## Never-treated = blue, treated = red; individual lines are thin & transparent.
#
#make_spaghetti <- function(sport_col, sport_label) {
#
#  # Base-year values (1993)
#  base_vals <- df %>%
#    filter(year == 1993) %>%
#    select(state, base = all_of(sport_col))
#
#  df_idx <- df %>%
#    filter(!is.na(.data[[sport_col]])) %>%
#    left_join(base_vals, by = "state") %>%
#    filter(!is.na(base), base > 0) %>%
#    mutate(idx = (.data[[sport_col]] / base) * 100)
#
#  # Group means of the index
#  grp_means <- df_idx %>%
#    group_by(treat_group, year) %>%
#    summarise(mean_idx = mean(idx, na.rm = TRUE), .groups = "drop")
#
#  pal <- c("WNBA state" = "#C82929", "Never treated" = "#377EB8")
#
#  ggplot() +
#    # Individual state lines — thin, semi-transparent
#    geom_line(
#      data = df_idx,
#      aes(x = year, y = idx, group = state, color = treat_group),
#      linewidth = 0.28, alpha = 0.28
#    ) +
#    # Bold group means
#    geom_line(
#      data = grp_means,
#      aes(x = year, y = mean_idx, color = treat_group),
#      linewidth = 1.4
#    ) +
#    geom_point(
#      data = grp_means,
#      aes(x = year, y = mean_idx, color = treat_group),
#      size = 2, shape = 21, fill = "white", stroke = 1.2
#    ) +
#    # Reference line at 100
#    geom_hline(yintercept = 100, linetype = "dashed",
#               color = "grey50", linewidth = 0.5) +
#    # WNBA founding year
#    geom_vline(xintercept = 1997, linetype = "dotted",
#               color = "grey40", linewidth = 0.6) +
#    annotate("text", x = 1997.3, y = Inf, label = "WNBA founded",
#             hjust = 0, vjust = 1.4, size = 2.8, color = "grey40") +
#    scale_color_manual(values = pal, name = NULL) +
#    scale_x_continuous(breaks = seq(1993, 2018, by = 5)) +
#    scale_y_continuous(labels = function(x) paste0(x)) +
#    labs(
#      title    = paste0("Girls' ", sport_label, ": Participation Index (1993 = 100)"),
#      subtitle = "Thin lines = individual states  |  Bold lines = group means",
#      x = NULL, y = "Index (1993 = 100)"
#    ) +
#    theme_minimal(base_size = 12) +
#    theme(
#      legend.position   = "bottom",
#      panel.grid.minor  = element_blank(),
#      plot.title        = element_text(face = "bold", size = 13),
#      plot.subtitle     = element_text(color = "grey45", size = 9)
#    )
#}
#
#p_sp_bball  <- make_spaghetti("basketball",    "Basketball")
#p_sp_soccer <- make_spaghetti("soccer",        "Soccer")
#p_sp_cc     <- make_spaghetti("cross_country", "Cross Country")
#p_sp_tf     <- make_spaghetti("track_field",   "Track & Field")
#
#ggsave("spaghetti_basketball.pdf",    p_sp_bball,  width=9, height=5.5, dpi=200)
#ggsave("spaghetti_soccer.pdf",        p_sp_soccer, width=9, height=5.5, dpi=200)
#ggsave("spaghetti_cross_country.pdf", p_sp_cc,     width=9, height=5.5, dpi=200)
#ggsave("spaghetti_track_field.pdf",   p_sp_tf,     width=9, height=5.5, dpi=200)
#cat("Saved spaghetti plots.\n")
#
## ============================================================
## 2. COHORT-STRATIFIED INDEXED TRENDS  (Basketball as main outcome)
## ============================================================
## One line per treatment cohort + one line for never-treated.
## Same 1993 = 100 normalisation. Shows whether cohorts look parallel pre-entry.
#
#cohort_palette <- c(
#  "Never treated" = "#333333",
#  "Cohort: 1997"  = "#E41A1C",
#  "Cohort: 1998"  = "#FF7F00",
#  "Cohort: 1999"  = "#4DAF4A",
#  "Cohort: 2000"  = "#984EA3",
#  "Cohort: 2003"  = "#377EB8",
#  "Cohort: 2006"  = "#A65628",
#  "Cohort: 2008"  = "#F781BF",
#  "Cohort: 2010"  = "#999999"
#)
#
#make_cohort_trend <- function(sport_col, sport_label) {
#
#  base_vals <- df %>%
#    filter(year == 1993) %>%
#    select(state, base = all_of(sport_col))
#
#  df_idx <- df %>%
#    filter(!is.na(.data[[sport_col]])) %>%
#    left_join(base_vals, by = "state") %>%
#    filter(!is.na(base), base > 0) %>%
#    mutate(idx = (.data[[sport_col]] / base) * 100)
#
#  cohort_means <- df_idx %>%
#    group_by(cohort_label, year) %>%
#    summarise(mean_idx = mean(idx, na.rm = TRUE), .groups = "drop") %>%
#    mutate(
#      is_never  = cohort_label == "Never treated",
#      lwd       = if_else(is_never, 1.5, 1.0),
#      alpha_val = if_else(is_never, 1.0, 0.85)
#    )
#
#  # Entry year markers: vertical tick per cohort at their first_treat year
#  entry_marks <- team_state %>%
#    mutate(cohort_label = paste0("Cohort: ", first_treat)) %>%
#    distinct(cohort_label, first_treat)
#
#  ggplot(cohort_means,
#         aes(x = year, y = mean_idx, color = cohort_label,
#             linewidth = I(lwd), alpha = I(alpha_val))) +
#    geom_line() +
#    geom_point(data = filter(cohort_means, is_never),
#               size = 1.8, shape = 21, fill = "white", stroke = 1.1) +
#    geom_hline(yintercept = 100, linetype = "dashed",
#               color = "grey60", linewidth = 0.5) +
#    scale_color_manual(values = cohort_palette, name = "Group") +
#    scale_x_continuous(breaks = seq(1993, 2018, by = 3)) +
#    labs(
#      title    = paste0("Girls' ", sport_label,
#                        ": Indexed Trends by Treatment Cohort (1993 = 100)"),
#      subtitle = paste0("Each coloured line = mean across states in that cohort",
#                        "  |  Black = never-treated mean"),
#      x = NULL, y = "Index (1993 = 100)"
#    ) +
#    theme_minimal(base_size = 12) +
#    theme(
#      legend.position  = c(0.14, 0.76),
#      legend.background = element_rect(fill = "white", color = NA),
#      legend.key.size  = unit(0.45, "cm"),
#      legend.text      = element_text(size = 8),
#      legend.title     = element_text(size = 8, face = "bold"),
#      panel.grid.minor = element_blank(),
#      plot.title       = element_text(face = "bold", size = 12),
#      plot.subtitle    = element_text(color = "grey45", size = 8.5)
#    )
#}
#
#p_coh_bball  <- make_cohort_trend("basketball",    "Basketball")
#p_coh_soccer <- make_cohort_trend("soccer",        "Soccer")
#p_coh_cc     <- make_cohort_trend("cross_country", "Cross Country")
#p_coh_tf     <- make_cohort_trend("track_field",   "Track & Field")
#
#ggsave("cohort_trend_basketball.pdf",    p_coh_bball,  width=9, height=5.5, dpi=200)
#ggsave("cohort_trend_soccer.pdf",        p_coh_soccer, width=9, height=5.5, dpi=200)
#ggsave("cohort_trend_cross_country.pdf", p_coh_cc,     width=9, height=5.5, dpi=200)
#ggsave("cohort_trend_track_field.pdf",   p_coh_tf,     width=9, height=5.5, dpi=200)
#cat("Saved cohort trend plots.\n")
#
## ============================================================
## 3. TREATMENT TIMING GANTT
## ============================================================
## States on y-axis, years on x-axis. Pre-treatment = light grey,
## treated period = cohort colour, never-treated = white with grey border.
## States sorted by first_treat year, then alphabetically within cohort.
#
#all_years <- sort(unique(df$year))
#
#gantt_df <- df %>%
#  distinct(state, first_treat) %>%
#  arrange(first_treat, state) %>%
#  mutate(
#    state = factor(state, levels = rev(unique(state))),  # top = first treated
#    cohort_label = case_when(
#      first_treat == 0 ~ "Never treated",
#      TRUE             ~ as.character(first_treat)
#    )
#  )
#
## Expand to one row per state x year
#gantt_long <- gantt_df %>%
#  crossing(year = all_years) %>%
#  mutate(
#    status = case_when(
#      first_treat == 0               ~ "Never treated",
#      year >= first_treat            ~ as.character(first_treat),
#      TRUE                           ~ "Pre-treatment"
#    )
#  )
#
## Colour scale: cohort years get distinct colours; pre/never get neutrals
#cohort_years  <- sort(unique(team_state$first_treat))
#cohort_fills  <- setNames(brewer.pal(length(cohort_years), "Set1"),
#                          as.character(cohort_years))
#status_fills  <- c(
#  cohort_fills,
#  "Pre-treatment" = "grey88",
#  "Never treated" = "grey96"
#)
#
## Legend order: cohort years first, then pre/never
#legend_order <- c(as.character(cohort_years), "Pre-treatment", "Never treated")
#
#ggplot(gantt_long,
#       aes(x = year, y = state, fill = factor(status, levels = legend_order))) +
#  geom_tile(color = "white", linewidth = 0.25) +
#  scale_fill_manual(
#    values = status_fills,
#    name   = "Status",
#    breaks = legend_order,
#    labels = c(paste0("Treated ", cohort_years), "Pre-treatment", "Never treated")
#  ) +
#  scale_x_continuous(
#    breaks = seq(1993, 2018, by = 3),
#    expand = c(0, 0)
#  ) +
#  scale_y_discrete(expand = c(0, 0)) +
#  labs(
#    title    = "WNBA Franchise Entry: Staggered Treatment Panel",
#    subtitle = "States sorted by treatment cohort year (earliest at top)",
#    x = NULL, y = NULL
#  ) +
#  theme_minimal(base_size = 10) +
#  theme(
#    axis.text.y      = element_text(size = 7.5),
#    axis.text.x      = element_text(size = 8),
#    panel.grid       = element_blank(),
#    legend.position  = "right",
#    legend.key.size  = unit(0.45, "cm"),
#    legend.text      = element_text(size = 8),
#    legend.title     = element_text(size = 8.5, face = "bold"),
#    plot.title       = element_text(face = "bold", size = 13),
#    plot.subtitle    = element_text(color = "grey45", size = 9),
#    plot.margin      = margin(8, 8, 8, 8)
#  )
#
#ggsave("gantt_treatment.pdf", width = 11, height = 8, dpi = 200)
#cat("Saved: gantt_treatment.pdf\n")
#
#cat("\nAll descriptive outputs:\n")
#cat("  spaghetti_{basketball,soccer,cross_country,track_field}.png\n")
#cat("  cohort_trend_{basketball,soccer,cross_country,track_field}.png\n")
#cat("  gantt_treatment.png\n")
