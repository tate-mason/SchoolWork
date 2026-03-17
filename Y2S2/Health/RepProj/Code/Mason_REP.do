/************************************************************
* Author: Tate Mason - tate.mason@uga.edu                   *
* ------  University of Georgia - Health Economics II       *
*                                                           *
*                                                           *
* Program: Mason_REP.do -                                   *
* -------                                                   *
*   .do file for replication of Evans, Garthwaite           *
*   "Giving Mom a Break"                                    *
*                                                           *
* Date: 01/29/2025                                          *
* ----                                                      *
************************************************************/

/************************************************************
* (1) Environment Setup                                     *
************************************************************/

#delimit cr // make carriage return the command delimiter
clear // clear data in memory
clear all // clear variables in memory
set more off // turn the "more" option for screen output off

set scheme s1color

local rootPath "~/Schoolwork/Y2S2/Health/RepProj/" // setting local file path

local codePath "`rootPath'Code/" // setting local code will be saved
local outPath "`rootPath'Output/" // setting where output will be saved
local dataPath "`rootPath'Data/" // setting where data will be saved to / sourced from

cap log close // close log capture at start to avoid errors

log using `outPath'Mason_rep_log.log, replace // specifying log file

/************************************************************
* (2) Loading in Data and Looking Around                    *
************************************************************/

use `dataPath'BRFSS_Final_Data.dta // call BRFSS data
summ * // get summary stats for all variables
tabstat income* educ  working

/************************************************************
* (3) Creating Local Variables for Functions (Switches)     *
************************************************************/

// Below I define a local switch for each part of the assignment. When set to 1, it will run, at 0, it is dormant

local Tab2 = 0
local Tab3 = 0
local Tab4 = 0
local Tab5 = 0 // only observations, sample mean, and % with risky levels
local Tab6 = 1
local Tab7 = 0 
local Fig4 = 0 // insert vline at t = 1996, include additional subfigure for "at work" rather than "in labor force" -- figure 4 has 5 subfigures
local ARC  = 0 // Additional Robustness Checks - Footnote 12 (col1), Footnote 21 - diff years excluded (col2), Footnote 21 - years specified (col3)
local Extension = 0

/************************************************************
* (4) Table 2 - Sample Characteristics                      *
************************************************************/

/************************************************************
* First, call the local ensuring it is switched "on", equal *
* to 1. Then, I will generate the sample statistics after   *
* subsetting the data to mothers aged 21-40 in the years    *
* 1993-1996 using the BRFSS dataset.                        *
************************************************************/

if `Tab2' {
  drop if year < 1993 | year > 1995
  drop if age < 21 | age > 40
  drop if kids == 0 | kids == .
  drop if educ == 3
  drop if fips > 56

  recode educ (1/2=0) (4=1), gen(college_edu)
  gen income_1t = income1 // income <20k
  gen income_2t = income2 + income3 // income b/w 20k and 50k
  gen income_3t = income4 + income5 // income greater than 50k
  
  // Variables and display labels
  local tab2_vars "age working white_nh hispanic black_nh other married div_sep_wid never_married income_1t income_2t income_3t incomemiss excel_vgood bad_mental_30 bad_phys_30 mental_poor phys_poor "
  local lab_age            "Average age"
  local lab_working        "\% currently employed"
  local lab_white_nh       "\% white, non-Hispanic"
  local lab_black_nh       "\% black, non-Hispanic"
  local lab_hispanic       "\% Hispanic"
  local lab_other          "\% other race"
  local lab_married        "\% married"
  local lab_div_sep_wid    "\% separated/divorced/widowed"
  local lab_never_married  "\% never married"
  local lab_income_1t        "\% \$<\$\$20K"
  local lab_income_2t      "\% \$\geq$ \$20k, $<$ \$50k"
  local lab_income_3t      "\% \$\geq$ \$50k"
  local lab_incomemiss     "\% income missing"
  local lab_excel_vgood    "\% excellent/very good health"
  local lab_bad_mental_30 "\% with any bad mental health days"
  local lab_bad_phys_30    "\% with any bad physical health days"
  local lab_mental_poor    "Number of bad mental health days"
  local lab_phys_poor      "Number of bad physical health days"

  file open tab2 using `outPath'Tables/Tab2.tex, write replace
  file write tab2 "\begin{table}[htbp]" _n
  file write tab2 "\centering" _n
  file write tab2 "\caption{Sample Characteristics, Mothers Aged 21--40, 1993--1996 BRFSS}" _n
  file write tab2 "\resizebox{\textwidth}{!}{%" _n
  file write tab2 "\begin{tabular}{lcccccc}" _n
  file write tab2 "\toprule" _n
  file write tab2 " & \multicolumn{3}{c}{\$\leq\$ High school education} & \multicolumn{3}{c}{College graduates} \\" _n
  file write tab2 "\cmidrule(lr){2-4}\cmidrule(lr){5-7}" _n
  file write tab2 "Variable & 1 child & 2+ kids & \$p\$-value & 1 child & 2+ kids & \$p\$-value \\" _n
  file write tab2 "\midrule" _n

  // Demographics
  foreach v in age working {
      sum `v' if college_edu == 0 & kids == 1
      local m_hs1 = strtrim(string(r(mean), "%9.3f"))
      sum `v' if college_edu == 0 & kids > 1
      local m_hs2 = strtrim(string(r(mean), "%9.3f"))
      ttest `v' if college_edu == 0, by(twoplus_kids)
      local p_hs  = strtrim(string(r(p), "%9.3f"))
      sum `v' if college_edu == 1 & kids == 1
      local m_col1 = strtrim(string(r(mean), "%9.3f"))
      sum `v' if college_edu == 1 & kids > 1
      local m_col2 = strtrim(string(r(mean), "%9.3f"))
      ttest `v' if college_edu == 1, by(twoplus_kids)
      local p_col  = strtrim(string(r(p), "%9.3f"))
      file write tab2 "`lab_`v'' & `m_hs1' & `m_hs2' & `p_hs' & `m_col1' & `m_col2' & `p_col' \\" _n
  }

  // Race
  file write tab2 "\addlinespace" _n
  file write tab2 "\multicolumn{7}{l}{\textit{Race}} \\" _n
  foreach v in white_nh black_nh hispanic other {
      sum `v' if college_edu == 0 & kids == 1
      local m_hs1 = strtrim(string(r(mean), "%9.3f"))
      sum `v' if college_edu == 0 & kids > 1
      local m_hs2 = strtrim(string(r(mean), "%9.3f"))
      ttest `v' if college_edu == 0, by(twoplus_kids)
      local p_hs  = strtrim(string(r(p), "%9.3f"))
      sum `v' if college_edu == 1 & kids == 1
      local m_col1 = strtrim(string(r(mean), "%9.3f"))
      sum `v' if college_edu == 1 & kids > 1
      local m_col2 = strtrim(string(r(mean), "%9.3f"))
      ttest `v' if college_edu == 1, by(twoplus_kids)
      local p_col  = strtrim(string(r(p), "%9.3f"))
      file write tab2 "`lab_`v'' & `m_hs1' & `m_hs2' & `p_hs' & `m_col1' & `m_col2' & `p_col' \\" _n
  }

  // Marital status
  file write tab2 "\addlinespace" _n
  file write tab2 "\multicolumn{7}{l}{\textit{Marital status}} \\" _n
  foreach v in married div_sep_wid never_married {
      sum `v' if college_edu == 0 & kids == 1
      local m_hs1 = strtrim(string(r(mean), "%9.3f"))
      sum `v' if college_edu == 0 & kids > 1
      local m_hs2 = strtrim(string(r(mean), "%9.3f"))
      ttest `v' if college_edu == 0, by(twoplus_kids)
      local p_hs  = strtrim(string(r(p), "%9.3f"))
      sum `v' if college_edu == 1 & kids == 1
      local m_col1 = strtrim(string(r(mean), "%9.3f"))
      sum `v' if college_edu == 1 & kids > 1
      local m_col2 = strtrim(string(r(mean), "%9.3f"))
      ttest `v' if college_edu == 1, by(twoplus_kids)
      local p_col  = strtrim(string(r(p), "%9.3f"))
      file write tab2 "`lab_`v'' & `m_hs1' & `m_hs2' & `p_hs' & `m_col1' & `m_col2' & `p_col' \\" _n
  }

  // Family income
  file write tab2 "\addlinespace" _n
  file write tab2 "\multicolumn{7}{l}{\textit{Family income}} \\" _n
  foreach v in income_1t income_2t income_3t incomemiss {
      sum `v' if college_edu == 0 & kids == 1
      local m_hs1 = strtrim(string(r(mean), "%9.3f"))
      sum `v' if college_edu == 0 & kids > 1
      local m_hs2 = strtrim(string(r(mean), "%9.3f"))
      ttest `v' if college_edu == 0, by(twoplus_kids)
      local p_hs  = strtrim(string(r(p), "%9.3f"))
      sum `v' if college_edu == 1 & kids == 1
      local m_col1 = strtrim(string(r(mean), "%9.3f"))
      sum `v' if college_edu == 1 & kids > 1
      local m_col2 = strtrim(string(r(mean), "%9.3f"))
      ttest `v' if college_edu == 1, by(twoplus_kids)
      local p_col  = strtrim(string(r(p), "%9.3f"))
      file write tab2 "`lab_`v'' & `m_hs1' & `m_hs2' & `p_hs' & `m_col1' & `m_col2' & `p_col' \\" _n
  }

  // Health outcomes
  file write tab2 "\addlinespace" _n
  file write tab2 "\multicolumn{7}{l}{\textit{Health outcome}} \\" _n
  foreach v in excel_vgood bad_mental_30 bad_phys_30 mental_poor phys_poor {
      sum `v' if college_edu == 0 & kids == 1
      local m_hs1 = strtrim(string(r(mean), "%9.3f"))
      sum `v' if college_edu == 0 & kids > 1
      local m_hs2 = strtrim(string(r(mean), "%9.3f"))
      ttest `v' if college_edu == 0, by(twoplus_kids)
      local p_hs  = strtrim(string(r(p), "%9.3f"))
      sum `v' if college_edu == 1 & kids == 1
      local m_col1 = strtrim(string(r(mean), "%9.3f"))
      sum `v' if college_edu == 1 & kids > 1
      local m_col2 = strtrim(string(r(mean), "%9.3f"))
      ttest `v' if college_edu == 1, by(twoplus_kids)
      local p_col  = strtrim(string(r(p), "%9.3f"))
      file write tab2 "`lab_`v'' & `m_hs1' & `m_hs2' & `p_hs' & `m_col1' & `m_col2' & `p_col' \\" _n
  }
  // Observation counts
  sum age if college_edu == 0 & kids == 1
  local n_hs1  = strtrim(string(r(N), "%9.0fc"))
  sum age if college_edu == 0 & kids > 1
  local n_hs2  = strtrim(string(r(N), "%9.0fc"))
  sum age if college_edu == 1 & kids == 1
  local n_col1 = strtrim(string(r(N), "%9.0fc"))
  sum age if college_edu == 1 & kids > 1
  local n_col2 = strtrim(string(r(N), "%9.0fc"))
  file write tab2 "\midrule" _n
  file write tab2 "Observations & `n_hs1' & `n_hs2' & & `n_col1' & `n_col2' & \\" _n
  file write tab2 "\bottomrule" _n
  file write tab2 "\end{tabular}}" _n
  file write tab2 "\begin{minipage}{\linewidth}" _n
  file write tab2 "\smallskip\footnotesize" _n
  file write tab2 "\textit{Notes:} The \$p\$-value tests equality of means across 1-child and 2+ child groups." _n
  file write tab2 "\end{minipage}" _n
  file write tab2 "\end{table}" _n
  file close tab2
}
/************************************************************
* (4) Table 3 - DiD OLS & Negative Binomial Estimates       *
************************************************************/

/************************************************************
* As above, call the local "Tab3", ensuring it is switched  *
* on (equal to 1). Then, I will estimate the OLS DiD model  *
* shown on page 268. Following that, I will estimate the    *
* negative binomial.                                        *
************************************************************/

if `Tab3' {
  use `dataPath'BRFSS_Final_Data.dta, clear
  drop if kids==0 | kids == .
  drop if educ == 3
  drop if age < 21 | age > 40
  drop if fips > 56

  // Pre-Treatment Means

  sum at_work excel_vgood mental_poor phys_poor if year<1996 & kids >= 2 & educ <= 2


  // Simple OLS DiD - working & Excellent/Very Good Health:

  reg at_work twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on LFPR
  estimates store working_simple
  
  reg excel_vgood twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on Good Health
  estimates store excel_simple

  nbreg mental_poor twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on Mental Health
  estimates store mental_simple

  nbreg phys_poor twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on Physical health
  estimates store phys_simple

  // Regression Adjusted DiD - Adding Controls

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg at_work dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  estimates store working_adj

  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health
  estimates store excel_adj

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health
  estimates store mental_adj

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health
  estimates store phys_adj

  // ---- Extract scalars for file write ----

  // Pre-expansion means for treatment group (2+ kids, educ<=2, pre-1996)
  foreach y in at_work excel_vgood mental_poor phys_poor {
      quietly sum `y' if year < 1996 & twoplus_kids == 1 & educ <= 2
      scalar premean_`y' = r(mean)
  }

  // Extract b, se, p for each outcome x spec
  // OLS: use e(df_r) for t-based p-value
  // nbreg: use normal approximation (z-stat)

  estimates restore working_simple
  scalar b_at_work_simple  = _b[dd_treatment]
  scalar se_at_work_simple = _se[dd_treatment]
  scalar p_at_work_simple  = 2*ttail(e(df_r), abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore working_adj
  scalar b_at_work_adj  = _b[dd_treatment]
  scalar se_at_work_adj = _se[dd_treatment]
  scalar p_at_work_adj  = 2*ttail(e(df_r), abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore excel_simple
  scalar b_excel_vgood_simple  = _b[dd_treatment]
  scalar se_excel_vgood_simple = _se[dd_treatment]
  scalar p_excel_vgood_simple  = 2*ttail(e(df_r), abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore excel_adj
  scalar b_excel_vgood_adj  = _b[dd_treatment]
  scalar se_excel_vgood_adj = _se[dd_treatment]
  scalar p_excel_vgood_adj  = 2*ttail(e(df_r), abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore mental_simple
  scalar b_mental_poor_simple  = _b[dd_treatment]
  scalar se_mental_poor_simple = _se[dd_treatment]
  scalar p_mental_poor_simple  = 2*normal(-abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore mental_adj
  scalar b_mental_poor_adj  = _b[dd_treatment]
  scalar se_mental_poor_adj = _se[dd_treatment]
  scalar p_mental_poor_adj  = 2*normal(-abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore phys_simple
  scalar b_phys_poor_simple  = _b[dd_treatment]
  scalar se_phys_poor_simple = _se[dd_treatment]
  scalar p_phys_poor_simple  = 2*normal(-abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore phys_adj
  scalar b_phys_poor_adj  = _b[dd_treatment]
  scalar se_phys_poor_adj = _se[dd_treatment]
  scalar p_phys_poor_adj  = 2*normal(-abs(_b[dd_treatment]/_se[dd_treatment]))

  // ---- Write Tab3 LaTeX ----

  cap mkdir `outPath'Tables

  local b_at_work_adj_s = strtrim(string(scalar(b_at_work_adj), "%9.4f"))
  local b_at_work_simple_s = strtrim(string(scalar(b_at_work_simple), "%9.4f"))
  local b_excel_vgood_adj_s = strtrim(string(scalar(b_excel_vgood_adj), "%9.4f"))
  local b_excel_vgood_simple_s = strtrim(string(scalar(b_excel_vgood_simple), "%9.4f"))
  local b_mental_poor_adj_s = strtrim(string(scalar(b_mental_poor_adj), "%9.4f"))
  local b_mental_poor_simple_s = strtrim(string(scalar(b_mental_poor_simple), "%9.4f"))
  local b_phys_poor_adj_s = strtrim(string(scalar(b_phys_poor_adj), "%9.4f"))
  local b_phys_poor_simple_s = strtrim(string(scalar(b_phys_poor_simple), "%9.4f"))
  local p_at_work_adj_s = strtrim(string(scalar(p_at_work_adj), "%9.4f"))
  local p_at_work_simple_s = strtrim(string(scalar(p_at_work_simple), "%9.4f"))
  local p_excel_vgood_adj_s = strtrim(string(scalar(p_excel_vgood_adj), "%9.4f"))
  local p_excel_vgood_simple_s = strtrim(string(scalar(p_excel_vgood_simple), "%9.4f"))
  local p_mental_poor_adj_s = strtrim(string(scalar(p_mental_poor_adj), "%9.4f"))
  local p_mental_poor_simple_s = strtrim(string(scalar(p_mental_poor_simple), "%9.4f"))
  local p_phys_poor_adj_s = strtrim(string(scalar(p_phys_poor_adj), "%9.4f"))
  local p_phys_poor_simple_s = strtrim(string(scalar(p_phys_poor_simple), "%9.4f"))
  local premean_at_work_s = strtrim(string(scalar(premean_at_work), "%9.4f"))
  local premean_excel_vgood_s = strtrim(string(scalar(premean_excel_vgood), "%9.4f"))
  local premean_mental_poor_s = strtrim(string(scalar(premean_mental_poor), "%9.4f"))
  local premean_phys_poor_s = strtrim(string(scalar(premean_phys_poor), "%9.4f"))
  local se_at_work_adj_s = strtrim(string(scalar(se_at_work_adj), "%9.4f"))
  local se_at_work_simple_s = strtrim(string(scalar(se_at_work_simple), "%9.4f"))
  local se_excel_vgood_adj_s = strtrim(string(scalar(se_excel_vgood_adj), "%9.4f"))
  local se_excel_vgood_simple_s = strtrim(string(scalar(se_excel_vgood_simple), "%9.4f"))
  local se_mental_poor_adj_s = strtrim(string(scalar(se_mental_poor_adj), "%9.4f"))
  local se_mental_poor_simple_s = strtrim(string(scalar(se_mental_poor_simple), "%9.4f"))
  local se_phys_poor_adj_s = strtrim(string(scalar(se_phys_poor_adj), "%9.4f"))
  local se_phys_poor_simple_s = strtrim(string(scalar(se_phys_poor_simple), "%9.4f"))
  file open tab3 using `outPath'Tables/Tab3.tex, write replace
  file write tab3 "\begin{table}[htbp]" _n
  file write tab3 "\centering" _n
  file write tab3 "\caption{Difference-in-Differences OLS and Negative Binomial Estimates \\ Mothers Aged 21--40, 1993--2001 BRFSS}" _n
  file write tab3 "\resizebox{\textwidth}{!}{%" _n
  file write tab3 "\begin{tabular}{lcccc}" _n
  file write tab3 "\toprule" _n
  file write tab3 " & Preexpansion & Estimation & \multicolumn{2}{c}{DiD estimates} \\" _n
  file write tab3 " & mean (treat.) & method & Simple & Reg. adjusted \\" _n
  file write tab3 "\cmidrule(lr){4-5}" _n

  // Row helper: writes b (se) [p] for two specs
  // At work
  file write tab3 "At work"
  file write tab3 " & `premean_at_work_s\'"
  file write tab3 " & OLS"
  file write tab3 " & `b_at_work_simple_s\'"
  file write tab3 " & `b_at_work_adj_s\' \\" _n
  file write tab3 " & & "
  file write tab3 " & (`se_at_work_simple_s\')"
  file write tab3 " & (`se_at_work_adj_s\') \\" _n
  file write tab3 " & & "
  file write tab3 " & [`p_at_work_simple_s\']"
  file write tab3 " & [`p_at_work_adj_s\'] \\" _n
  file write tab3 "\addlinespace" _n

  // Excellent/very good
  file write tab3 "Excellent/very good health?"
  file write tab3 " & `premean_excel_vgood_s\'"
  file write tab3 " & OLS"
  file write tab3 " & `b_excel_vgood_simple_s\'"
  file write tab3 " & `b_excel_vgood_adj_s\' \\" _n
  file write tab3 " & & "
  file write tab3 " & (`se_excel_vgood_simple_s\')"
  file write tab3 " & (`se_excel_vgood_adj_s\') \\" _n
  file write tab3 " & & "
  file write tab3 " & [`p_excel_vgood_simple_s\']"
  file write tab3 " & [`p_excel_vgood_adj_s\'] \\" _n
  file write tab3 "\addlinespace" _n

  // Mental poor
  file write tab3 "Number of bad mental health days in past month"
  file write tab3 " & `premean_mental_poor_s\'"
  file write tab3 " & Negative binomial"
  file write tab3 " & `b_mental_poor_simple_s\'"
  file write tab3 " & `b_mental_poor_adj_s\' \\" _n
  file write tab3 " & & "
  file write tab3 " & (`se_mental_poor_simple_s\')"
  file write tab3 " & (`se_mental_poor_adj_s\') \\" _n
  file write tab3 " & & "
  file write tab3 " & [`p_mental_poor_simple_s\']"
  file write tab3 " & [`p_mental_poor_adj_s\'] \\" _n
  file write tab3 "\addlinespace" _n

  // Physical poor
  file write tab3 "Number of bad physical health days in past month"
  file write tab3 " & `premean_phys_poor_s\'"
  file write tab3 " & Negative binomial"
  file write tab3 " & `b_phys_poor_simple_s\'"
  file write tab3 " & `b_phys_poor_adj_s\' \\" _n
  file write tab3 " & & "
  file write tab3 " & (`se_phys_poor_simple_s\')"
  file write tab3 " & (`se_phys_poor_adj_s\') \\" _n
  file write tab3 " & & "
  file write tab3 " & [`p_phys_poor_simple_s\']"
  file write tab3 " & [`p_phys_poor_adj_s\'] \\" _n

  file write tab3 "\bottomrule" _n
  file write tab3 "\end{tabular}}" _n
  file write tab3 "\begin{minipage}{\linewidth}" _n
  file write tab3 "\smallskip\footnotesize" _n
  file write tab3 "\textit{Notes:} Standard errors in parentheses; \$p\$-values in square brackets." _n
  file write tab3 " All standard errors allow for arbitrary correlations within state." _n
  file write tab3 " Regression-adjusted estimates include dummies for age, race, marital status," _n
  file write tab3 " number of children, month, year, and state of residence." _n
  file write tab3 "\end{minipage}" _n
  file write tab3 "\end{table}" _n
  file close tab3
}

/************************************************************
* (5) Table 4 - Robustness Tests                            *
************************************************************/

/************************************************************
* Call the `Tab4' local, allowing this section to run. Then,*
* I will run the robustness checks via sample differences   *
* and estimation techniques differing. Each portion will be *
* labeled to inform what operation is occurring             *
************************************************************/

if `Tab4' {
  use `dataPath'BRFSS_Final_Data.dta, clear

  // Column 1 - DiD Results Full Sample With Dummy Controls
  drop if kids == 0 | kids == .

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.year" // Control vector of dummies

  reg at_work dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  estimates store tab4c1_at_work

  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health
  estimates store tab4c1_excel

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health
  estimates store tab4c1_mental

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health
  estimates store tab4c1_phys

  // Column 2 - State x Year FE added

  local X "i.race4 i.educ i.age i.month i.marital i.kids" // Control vector of dummies

  reg at_work dd_treatment fips#i.year `X' if educ <= 2, cluster(fips) // Effect on LFPR
  estimates store tab4c2_at_work

  reg excel_vgood dd_treatment fips#i.year `X' if educ <= 2, cluster(fips) // Effect on Good Health
  estimates store tab4c2_excel

  nbreg mental_poor dd_treatment fips#i.year `X' if educ <= 2, cluster(fips) // Effect on Mental Health
  estimates store tab4c2_mental

  nbreg phys_poor dd_treatment fips#i.year `X' if educ <= 2, cluster(fips) // Effect on Physical health
  estimates store tab4c2_phys

  // Column 3 - Differencing by Amount of Children (2 vs 0)

  preserve
  drop if kids == 1

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg at_work dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  estimates store tab4c3_at_work

  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health
  estimates store tab4c3_excel

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health
  estimates store tab4c3_mental

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health
  estimates store tab4c3_phys
  restore

  // Column 4 - Differentiating by Married
  preserve

  keep if marital == 1
  drop if kids == 0

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg at_work dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  estimates store tab4c4_at_work

  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health
  estimates store tab4c4_excel

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health
  estimates store tab4c4_mental

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health
  estimates store tab4c4_phys
  restore

  // Column 5 - Differentiating by Single

  preserve

  keep if marital > 1
  drop if kids == 0

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg at_work dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  estimates store tab4c5_at_work

  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health
  estimates store tab4c5_excel

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health
  estimates store tab4c5_mental

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health
  estimates store tab4c5_phys

  restore

  // Column 6 - Triple Diff
  preserve

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year i.year##i.kids i.year##i.educ i.kids##i.educ" // Control vector of dummies

  drop if educ == 3 // drop some college
  drop if kids == 0 | kids == .
  gen hs_only = educ <= 2 // dummy for max of HS education 

  gen hs_expand = hs_only*eitc_expand // low educ x time interaction
  gen twokids_expand = twoplus_kids*eitc_expand // time x 2+ kids interaction
  gen hs_twokids = hs_only*twoplus_kids // low educ x 2+ kids interaction

  gen treatment = dd_treatment*hs_only 

  reg at_work treatment hs_expand twokids_expand hs_twokids `X', cluster(fips) // Effect on LFPR
  estimates store tab4c6_at_work

  reg excel_vgood treatment hs_expand twokids_expand hs_twokids `X', cluster(fips) // Effect on Good Health
  estimates store tab4c6_excel

  nbreg mental_poor treatment hs_expand twokids_expand hs_twokids `X', cluster(fips) // Effect on Mental Health
  estimates store tab4c6_mental

  nbreg phys_poor treatment hs_expand twokids_expand hs_twokids `X', cluster(fips) // Effect on Physical health
  estimates store tab4c6_phys

  restore

  // ---- Extract Tab4 scalars ----
  // Cols 1-5: dd_treatment; Col 6: treatment (triple diff)
  // OLS outcomes: at_work, excel  -> ttail p-value
  // nbreg outcomes: mental, phys  -> normal p-value

  foreach col in c1 c2 c3 c4 c5 {
      local tvar "dd_treatment"
      foreach y in at_work excel {
          estimates restore tab4`col'_`y'
          scalar b4_`col'_`y'  = _b[`tvar']
          scalar se4_`col'_`y' = _se[`tvar']
          scalar p4_`col'_`y'  = 2*ttail(e(df_r), abs(_b[`tvar']/_se[`tvar']))
      }
      foreach y in mental phys {
          estimates restore tab4`col'_`y'
          scalar b4_`col'_`y'  = _b[`tvar']
          scalar se4_`col'_`y' = _se[`tvar']
          scalar p4_`col'_`y'  = 2*normal(-abs(_b[`tvar']/_se[`tvar']))
      }
  }
  // Col 6 uses treatment variable
  foreach y in at_work excel {
      estimates restore tab4c6_`y'
      scalar b4_c6_`y'  = _b[treatment]
      scalar se4_c6_`y' = _se[treatment]
      scalar p4_c6_`y'  = 2*ttail(e(df_r), abs(_b[treatment]/_se[treatment]))
  }
  foreach y in mental phys {
      estimates restore tab4c6_`y'
      scalar b4_c6_`y'  = _b[treatment]
      scalar se4_c6_`y' = _se[treatment]
      scalar p4_c6_`y'  = 2*normal(-abs(_b[treatment]/_se[treatment]))
  }

  // ---- Write Tab4 LaTeX ----

  file open tab4 using `outPath'Tables/Tab4.tex, write replace
  file write tab4 "\begin{table}[htbp]" _n
  file write tab4 "\centering" _n
  file write tab4 "\caption{Robustness Tests, Women Aged 21--40, 1993--2001 BRFSS}" _n
  file write tab4 "\resizebox{\textwidth}{!}{%" _n
  file write tab4 "\begin{tabular}{lcccccc}" _n
  file write tab4 "\toprule" _n
  file write tab4 " & DD & DD state$\times$year & 2 vs 0 kids & DD married & DD single & DDD \\" _n
  file write tab4 "Outcome & Method & FE & & & & \\" _n
  file write tab4 "\midrule" _n

  // Helper macro: write one row of 6 cols
  // Usage: call for each outcome with its stored scalars
  // at_work
  file write tab4 "At work (OLS)"
  foreach col in c1 c2 c3 c4 c5 c6 {
      local val = strtrim(string(scalar(b4_`col'_at_work), "%9.4f"))
      file write tab4 " & `val'"
  }
  file write tab4 " \\" _n
  foreach col in c1 c2 c3 c4 c5 c6 {
      local val = strtrim(string(scalar(se4_`col'_at_work), "%9.4f"))
      file write tab4 " & (`val')"
  }
  file write tab4 " \\" _n
  foreach col in c1 c2 c3 c4 c5 c6 {
      local val = strtrim(string(scalar(p4_`col'_at_work), "%9.3f"))
      file write tab4 " & [`val']"
  }
  file write tab4 " \\" _n
  file write tab4 "\addlinespace" _n

  // excel_vgood
  file write tab4 "Exc./very good health (OLS)"
  foreach col in c1 c2 c3 c4 c5 c6 {
      local val = strtrim(string(scalar(b4_`col'_excel), "%9.4f"))
      file write tab4 " & `val'"
  }
  file write tab4 " \\" _n
  foreach col in c1 c2 c3 c4 c5 c6 {
      local val = strtrim(string(scalar(se4_`col'_excel), "%9.4f"))
      file write tab4 " & (`val')"
  }
  file write tab4 " \\" _n
  foreach col in c1 c2 c3 c4 c5 c6 {
      local val = strtrim(string(scalar(p4_`col'_excel), "%9.3f"))
      file write tab4 " & [`val']"
  }
  file write tab4 " \\" _n
  file write tab4 "\addlinespace" _n

  // mental
  file write tab4 "Bad mental health days (NegBin)"
  foreach col in c1 c2 c3 c4 c5 c6 {
      local val = strtrim(string(scalar(b4_`col'_mental), "%9.4f"))
      file write tab4 " & `val'"
  }
  file write tab4 " \\" _n
  foreach col in c1 c2 c3 c4 c5 c6 {
      local val = strtrim(string(scalar(se4_`col'_mental), "%9.4f"))
      file write tab4 " & (`val')"
  }
  file write tab4 " \\" _n
  foreach col in c1 c2 c3 c4 c5 c6 {
      local val = strtrim(string(scalar(p4_`col'_mental), "%9.3f"))
      file write tab4 " & [`val']"
  }
  file write tab4 " \\" _n
  file write tab4 "\addlinespace" _n

  // phys
  file write tab4 "Bad physical health days (NegBin)"
  foreach col in c1 c2 c3 c4 c5 c6 {
      local val = strtrim(string(scalar(b4_`col'_phys), "%9.4f"))
      file write tab4 " & `val'"
  }
  file write tab4 " \\" _n
  foreach col in c1 c2 c3 c4 c5 c6 {
      local val = strtrim(string(scalar(se4_`col'_phys), "%9.4f"))
      file write tab4 " & (`val')"
  }
  file write tab4 " \\" _n
  foreach col in c1 c2 c3 c4 c5 c6 {
      local val = strtrim(string(scalar(p4_`col'_phys), "%9.3f"))
      file write tab4 " & [`val']"
  }
  file write tab4 " \\" _n

  file write tab4 "\bottomrule" _n
  file write tab4 "\end{tabular}}" _n
  file write tab4 "\begin{minipage}{\linewidth}" _n
  file write tab4 "\smallskip\footnotesize" _n
  file write tab4 "\textit{Notes:} Standard errors in parentheses; \$p\$-values in square brackets." _n
  file write tab4 " All standard errors allow for arbitrary correlations within state." _n
  file write tab4 "\end{minipage}" _n
  file write tab4 "\end{table}" _n
  file close tab4
}

if `Tab5' {
  preserve
  // NHANES data load
  use `dataPath'nhanes/nhanesallstacked.dta, clear
  // Subset to mothers aged 21-40 with children under 18 and educ <= HS
  
  drop if age < 21 | age > 40
  drop if sex == 1

  // Keep only black, white, hisp mothers
  drop if race > 3 | race < 0

  // Coding for kids - normalize as best approximation
  gen kids = .
  replace kids = family_size-1 if marital>1 & year == 0
  replace kids = family_size-2 if marital == 1 & year == 0
  replace kids = dmdhhsiz-1 if marital > 1 & year > 0
  replace kids = dmdhhsiz-2 if marital == 1 & year > 0

  // Coding for education
  gen no_hs = highgrade <= 2

  // Keeping only mothers
  drop if kids <= 0

  
  gen twoplus_kids = kids > 1 // dummy for 2+ kids
  gen eitc_expand = year > 0  // dummy for post expansion years

  gen dd_treat = eitc_expand*twoplus_kids // DiD treatment variable

  gen eitc_nohs = eitc_expand*no_hs // time x no HS interaction
  gen twoplus_nohs = twoplus_kids*no_hs // 2+ kids x no HS interaction
  gen ddd_treat = dd_treat*no_hs // triple diff treatment variable

  local X "i.year i.age i.marital i.race" // control vector of dummies

  // Cleaning variables as done in replication package
  replace crp = . if crp == 88888 // missing value code for CRP

  gen riskycrp=crp>=0.3 // risky if CRP is above 0.3
  replace riskycrp = . if crp == . // missing if CRP is missing
  replace riskypulse = . if pulse == . // missing if pulse is missing
  replace riskydiastolic = . if diastolic == . // missing if diastolic is missing
  replace riskysystolic = . if systolic == . // missing if systolic is missing
  replace riskyhdl = . if hdl == . // missing if hdl is missing
  replace riskyCholest = . if cholesterol == . // missing if cholesterol is missing
  replace riskyAlbumin = . if albumin == . // missing if albumin is missing
  replace riskyglycatedhemoglobin = . if glycatedhemoglobin == . // missing if glycatedhemoglobin is missing
  

  gen metabsum = riskyglycatedhemoglobin + riskyCholest + riskyhdl // sum of metabolic risk factors
  gen cardiosum = riskysystolic+riskydiastolic+riskypulse // sum of cardiovascular risk factors
  gen inflsum = riskycrp + riskyAlbumin // sum of inflammation risk factors
  gen totalsum = metabsum+cardiosum+inflsum // sum of all risk factors

  gen anymetab = metabsum>0 // dummy for any metabolic risk factor
  replace anymetab = . if riskyglycatedhemoglobin == . | riskyCholest == . | riskyhdl == . // missing if any metabolic risk factor is missing
  gen anycardio = cardiosum > 0 // dummy for any cardiovascular risk factor
  replace anycardio = . if riskypulse == . | riskydiastolic == . | riskysystolic == . // missing if any cardiovascular risk factor is missing
  gen anyinflamation = inflsum > 0 // dummy for any inflammation risk factor
  replace anyinflamation = . if riskyAlbumin == . | riskycrp == . // missing if any inflammation risk factor is missing

  // Make data match across years
  replace crp = 0.21 if crp < 0.21

  gen total1 = totalsum>0 // dummy for 1+ risk factors
  replace total1 = . if totalsum == . // missing if total sum is missing
  gen total2 = totalsum > 1 // dummy for 2+ risk factors
  replace total2 = . if totalsum == . // missing if total sum is missing
  gen total3 = totalsum > 2 // dummy for 3+ risk factors
  replace total3 = . if totalsum == . // missing if total sum is missing

  // Table 5 - Descriptives

  // Drop missings
  drop if marital == . | race == . | age == . | no_hs == . | kids == . 

  // Inflammation Panel
  sum crp albumin inflsum anyinflamation if highgrad <= 2

  // Cardiovascular Panel
  sum diastolic systolic pulse cardiosum anycardio if highgrade <= 2

  // Metabolic Panel
  sum cholesterol hdl glycatedhemoglobin metabsum anymetab if highgrade <= 2

  // Total Risk Factors
  sum totalsum total1 total2 total3 if highgrade <= 2

  save `dataPath'nhanes/nhanescleaned.dta, replace

  file open tab5 using `outPath'Tables/Tab5.tex, write replace
  file write tab5 "\begin{table}[htbp]" _n
  file write tab5 "\centering" _n
  file write tab5 "\caption{Biomarkers for Mothers Aged 21--40 with a High School Education or Less, NHANES}" _n
  file write tab5 "\begin{tabular}{lcccc}" _n
  file write tab5 "\toprule" _n
  file write tab5 "Biomarker & Obs & Mean & Risky level & \% Risky \\" _n
  file write tab5 "\midrule" _n
  file write tab5 "\multicolumn{5}{l}{\textit{Measures of inflammation}} \\" _n
  file write tab5 "\addlinespace" _n

  // Inflammation panel
  // crp
  sum crp if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local mn  = strtrim(string(r(mean), "%9.3f"))
  sum riskycrp if highgrade <= 2
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "C-reactive protein (mg/Dl) & `obs' & `mn' & \$\geq\$ 0.3 mg/Dl & `pct' \\" _n

  sum albumin if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local mn  = strtrim(string(r(mean), "%9.3f"))
  sum riskyAlbumin if highgrade <= 2
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "Albumin (g/Dl) & `obs' & `mn' & \$<\$ 3.8 g/Dl & `pct' \\" _n

  sum inflsum if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local mn  = strtrim(string(r(mean), "%9.3f"))
  sum anyinflamation if highgrade <= 2
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "Number of risky inflammation conditions & `obs' & `mn' & & \\" _n
  file write tab5 "Any risky inflammation condition & `obs' & & & `pct' \\" _n

  file write tab5 "\midrule" _n
  file write tab5 "\multicolumn{5}{l}{\textit{Measures of cardiovascular conditions}} \\" _n
  file write tab5 "\addlinespace" _n

  // Cardiovascular panel
  sum diastolic if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local mn  = strtrim(string(r(mean), "%9.3f"))
  sum riskydiastolic if highgrade <= 2
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "Diastolic blood pressure (mmHg) & `obs' & `mn' & \$\geq\$ 140 mmHg & `pct' \\" _n

  sum systolic if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local mn  = strtrim(string(r(mean), "%9.3f"))
  sum riskysystolic if highgrade <= 2
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "Systolic blood pressure (mmHg) & `obs' & `mn' & \$\geq\$ 90 mmHg & `pct' \\" _n

  sum pulse if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local mn  = strtrim(string(r(mean), "%9.3f"))
  sum riskypulse if highgrade <= 2
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "Resting pulse (beats/min) & `obs' & `mn' & \$\geq\$ 90 BPM & `pct' \\" _n

  sum cardiosum if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local mn  = strtrim(string(r(mean), "%9.3f"))
  sum anycardio if highgrade <= 2
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "Number of risky cardiovascular conditions & `obs' & `mn' & & \\" _n
  file write tab5 "Any risky cardiovascular condition & `obs' & & & `pct' \\" _n

  file write tab5 "\midrule" _n
  file write tab5 "\multicolumn{5}{l}{\textit{Measures of metabolic conditions}} \\" _n
  file write tab5 "\addlinespace" _n

  // Metabolic panel
  sum cholesterol if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local mn  = strtrim(string(r(mean), "%9.3f"))
  sum riskyCholest if highgrade <= 2
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "Total cholesterol (mg/Dl) & `obs' & `mn' & \$\geq\$ 240 mg/Dl & `pct' \\" _n

  sum hdl if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local mn  = strtrim(string(r(mean), "%9.3f"))
  sum riskyhdl if highgrade <= 2
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "HDL (mg/Dl) & `obs' & `mn' & \$<\$ 40 mg/Dl & `pct' \\" _n

  sum glycatedhemoglobin if highgrade <= 2 // HbA1c - sum separately to avoid name length issues
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local mn  = strtrim(string(r(mean), "%9.3f"))
  sum riskyglycatedhemoglobin if highgrade <= 2
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "Glycated hemoglobin (\%) & `obs' & `mn' & \$\geq\$ 6.4\% & `pct' \\" _n

  sum metabsum if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local mn  = strtrim(string(r(mean), "%9.3f"))
  sum anymetab if highgrade <= 2
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "Number of risky metabolic conditions & `obs' & `mn' & & \\" _n
  file write tab5 "Any risky metabolic condition & `obs' & & & `pct' \\" _n

  file write tab5 "\midrule" _n
  file write tab5 "\multicolumn{5}{l}{\textit{Aggregate risks}} \\" _n
  file write tab5 "\addlinespace" _n

  // Aggregate panel
  sum totalsum if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local mn  = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "Number of risky conditions & `obs' & `mn' & & \\" _n

  sum total1 if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "One or more risky conditions & `obs' & & & `pct' \\" _n

  sum total2 if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "Two or more risky conditions & `obs' & & & `pct' \\" _n

  sum total3 if highgrade <= 2
  local obs = strtrim(string(r(N),    "%9.0fc"))
  local pct = strtrim(string(r(mean), "%9.3f"))
  file write tab5 "Three or more risky conditions & `obs' & & & `pct' \\" _n

  file write tab5 "\bottomrule" _n
  file write tab5 "\end{tabular}" _n
  file write tab5 "\begin{minipage}{\linewidth}" _n
  file write tab5 "\smallskip\footnotesize" _n
  file write tab5 "\textit{Notes:} Sample restricted to mothers aged 21--40 with a high school degree or less." _n
  file write tab5 " NHANES III, 1999/2000, 2001/2002, 2003/2004." _n
  file write tab5 "\end{minipage}" _n
  file write tab5 "\end{table}" _n
  file close tab5  
  restore
}

if `Tab6' {
  use `dataPath'nhanes/nhanescleaned.dta, clear
  *******************************
  * Pre- Treatment Means        *
  *******************************
  
  // Inflammation Panel
  sum crp albumin inflsum anyinflamation if highgrad <= 2 & year == 0 & twoplus_kids == 1

  // Cardiovascular Panel
  sum diastolic systolic pulse cardiosum anycardio if highgrade <= 2 & year == 0 & twoplus_kids == 1

  // Metabolic Panel
  sum cholesterol hdl glycatedhemoglobin metabsum anymetab if highgrade <= 2 & year == 0 & twoplus_kids == 1

  // Total Risk Factors
  sum totalsum total1 total2 total3 if highgrade <= 2 & year == 0 & twoplus_kids == 1

  *******************************
  * DiD Estimates               *
  ********************************

  local X_dd "i.year i.age i.marital i.race" // control vector of dummies

  tab year if highgrade <= 2

  // Column 1
  reg total1 dd_treat twoplus_kids `X_dd' if highgrade<=2, robust // Effect on 1+ Risk Factors
  estimates store tab6c1_total1

  reg total2 dd_treat twoplus_kids `X_dd' if highgrade<=2, robust // Effect on 2+ Risk Factors
  estimates store tab6c1_total2

  reg total3 dd_treat twoplus_kids `X_dd' if highgrade<=2, robust // Effect on 3+ Risk Factors
  estimates store tab6c1_total3

  poisson totalsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust // Poisson regression for count of risk factors
  estimates store tab6c1_totalsum

  // Column 2 - Triple Diff
  local X_ddd "i.year i.age i.race i.marital i.highgrade##i.year i.year##i.twoplus_kids i.highgrade##i.twoplus_kids" // control vector of dummies
  reg total1 ddd_treat `X_ddd', robust // Effect on 1+ Risk Factors
  estimates store tab6c2_total1

  reg total2 ddd_treat `X_ddd', robust // Effect on 2+ Risk Factors
  estimates store tab6c2_total2

  reg total3 ddd_treat `X_ddd', robust // Effect on 3+ Risk Factors
  estimates store tab6c2_total3

  poisson totalsum ddd_treat `X_ddd', robust // Poisson regression for count of risk factors
  estimates store tab6c2_totalsum

  // Two vs. No Kids

  preserve
  drop if kids == 1

  reg total1 dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab6c3_total1
  reg total2 dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab6c3_total2
  reg total3 dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab6c3_total3
  poisson totalsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab6c3_totalsum

  // All OLS -> ttail; Poisson -> normal z

  foreach param in total1 total2 total3 {
      estimates restore tab6c1_`param'
      scalar b6dd_`param'  = _b[dd_treat]
      scalar se6dd_`param' = _se[dd_treat]
      scalar p6dd_`param'  = 2*ttail(e(df_r), abs(_b[dd_treat]/_se[dd_treat]))

      estimates restore tab6c2_`param'
      scalar b6ddd_`param'  = _b[ddd_treat]
      scalar se6ddd_`param' = _se[ddd_treat]
      scalar p6ddd_`param'  = 2*ttail(e(df_r), abs(_b[ddd_treat]/_se[ddd_treat]))

      estimates restore tab6c3_`param'
      scalar b6kids_`param'  = _b[dd_treat]
      scalar se6kids_`param' = _se[dd_treat]
      scalar p6kids_`param'  = 2*ttail(e(df_r), abs(_b[dd_treat]/_se[dd_treat]))
  }
  // Poisson totalsum
  estimates restore tab6c1_totalsum
  scalar b6dd_totalsum  = _b[dd_treat]
  scalar se6dd_totalsum = _se[dd_treat]
  scalar p6dd_totalsum  = 2*normal(-abs(_b[dd_treat]/_se[dd_treat]))

  estimates restore tab6c2_totalsum
  scalar b6ddd_totalsum  = _b[ddd_treat]
  scalar se6ddd_totalsum = _se[ddd_treat]
  scalar p6ddd_totalsum  = 2*normal(-abs(_b[ddd_treat]/_se[ddd_treat]))

  estimates restore tab6c3_totalsum
  scalar b6kids_totalsum  = _b[dd_treat]
  scalar se6kids_totalsum = _se[dd_treat]
  scalar p6kids_totalsum  = 2*normal(-abs(_b[dd_treat]/_se[dd_treat]))

  // Pre-expansion means for treatment group
  foreach param in total1 total2 total3 totalsum {
      quietly sum `param' if year == 0 & twoplus_kids == 1 & highgrade <= 2
      scalar premean6_`param' = r(mean)
  }

  // ---- Write Tab6 LaTeX ----

  local b6dd_totalsum_s = strtrim(string(scalar(b6dd_totalsum), "%9.4f"))
  local b6ddd_totalsum_s = strtrim(string(scalar(b6ddd_totalsum), "%9.4f"))
  local b6kids_totalsum_s = strtrim(string(scalar(b6kids_totalsum), "%9.4f"))
  local p6dd_totalsum_s = strtrim(string(scalar(p6dd_totalsum), "%9.4f"))
  local p6ddd_totalsum_s = strtrim(string(scalar(p6ddd_totalsum), "%9.4f"))
  local p6kids_totalsum_s = strtrim(string(scalar(p6kids_totalsum), "%9.4f"))
  local premean6_totalsum_s = strtrim(string(scalar(premean6_totalsum), "%9.4f"))
  local se6dd_totalsum_s = strtrim(string(scalar(se6dd_totalsum), "%9.4f"))
  local se6ddd_totalsum_s = strtrim(string(scalar(se6ddd_totalsum), "%9.4f"))
  local se6kids_totalsum_s = strtrim(string(scalar(se6kids_totalsum), "%9.4f"))
  file open tab6 using `outPath'Tables/Tab6.tex, write replace
  file write tab6 "\begin{table}[htbp]" _n
  file write tab6 "\centering" _n
  file write tab6 "\caption{Regression-Adjusted DD and DDD Estimates for Effect of EITC Expansion on Allostatic Load, Women Aged 21--40}" _n
  file write tab6 "\begin{tabular}{lcccc}" _n
  file write tab6 "\toprule" _n
  file write tab6 " & Preexpansion mean & & & \\" _n
  file write tab6 "Outcome & (treatment group) & DD & DDD & Two Children vs. No Children \\" _n
  file write tab6 "\midrule" _n

  foreach param in total1 total2 total3 {
      if "`param'" == "total1" local outlabel "One or more risky conditions"
      if "`param'" == "total2" local outlabel "Two or more risky conditions"
      if "`param'" == "total3" local outlabel "Three or more risky conditions"
      local pm   = strtrim(string(scalar(premean6_`param'), "%9.3f"))
      local bdd  = strtrim(string(scalar(b6dd_`param'),    "%9.4f"))
      local bddd = strtrim(string(scalar(b6ddd_`param'),   "%9.4f"))
      local bkid = strtrim(string(scalar(b6kids_`param'),  "%9.4f"))
      local sedd = strtrim(string(scalar(se6dd_`param'),   "%9.4f"))
      local seddd= strtrim(string(scalar(se6ddd_`param'),  "%9.4f"))
      local sekid= strtrim(string(scalar(se6kids_`param'),  "%9.4f"))
      local pdd  = strtrim(string(scalar(p6dd_`param'),    "%9.3f"))
      local pddd = strtrim(string(scalar(p6ddd_`param'),   "%9.3f"))
      local pkid = strtrim(string(scalar(p6kids_`param'),   "%9.3f"))
      file write tab6 "`outlabel'"
      file write tab6 " & `pm'"
      file write tab6 " & `bdd'"
      file write tab6 " & `bddd' "
      file write tab6 " & `bkid' \\" _n
      file write tab6 " & "
      file write tab6 " & (`sedd')"
      file write tab6 " & (`seddd')"
      file write tab6 " & (`sekid') \\" _n
      file write tab6 " & "
      file write tab6 " & [`pdd']"
      file write tab6 " & [`pddd']"
      file write tab6 " & [`pkid'] \\" _n
      file write tab6 "\addlinespace" _n
  }

  file write tab6 "Poisson: total risky conditions"
  file write tab6 " & `premean6_totalsum_s\'"
  file write tab6 " & `b6dd_totalsum_s\'"
  file write tab6 " & `b6ddd_totalsum_s\'"
  file write tab6 " & `b6kids_totalsum_s\' \\" _n
  file write tab6 " & "
  file write tab6 " & (`se6dd_totalsum_s\')"
  file write tab6 " & (`se6ddd_totalsum_s\')"
  file write tab6 " & (`se6kids_totalsum_s\') \\" _n
  file write tab6 " & "
  file write tab6 " & [`p6dd_totalsum_s\']"
  file write tab6 " & [`p6ddd_totalsum_s\']"
  file write tab6 " & [`p6kids_totalsum_s\'] \\" _n

  file write tab6 "\bottomrule" _n
  file write tab6 "\end{tabular}" _n
  file write tab6 "\begin{minipage}{\linewidth}" _n
  file write tab6 "\smallskip\footnotesize" _n
  file write tab6 "\textit{Notes:} Standard errors in parentheses; \$p\$-values in square brackets." _n
  file write tab6 " All standard errors allow for arbitrary heteroskedasticity." _n
  file write tab6 "\end{minipage}" _n
  file write tab6 "\end{table}" _n
  file close tab6
}

if `Tab7' {
  use `dataPath'nhanes/nhanescleaned.dta, clear

  local X_dd "i.year i.age i.marital i.race" // control vector of dummies
  local X_ddd "i.year i.age i.race i.marital i.highgrade##i.year i.year##i.twoplus_kids i.highgrade##i.twoplus_kids" // control vector of dummies

  // panel A. Metabolic Biomarkers
  local metab_markers "riskyglycatedhemoglobin riskyCholest riskyhdl anymetab" // list of dependent variables

  // Loop through markers and run DiD
  reg riskyglycatedhemoglobin dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_hba1c
  reg riskyCholest dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_cholest
  reg riskyhdl dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_hdl
  reg anymetab dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_anymetab
  poisson metabsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_metabsum_pois
  nbreg metabsum dd_treat `X_dd' if highgrade<=2, robust d(c)
  estimates store tab7dd_metabsum_nb

  local cardio_markers "riskydiastolic riskysystolic riskypulse anycardio"

  reg riskydiastolic dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_diastolic
  reg riskysystolic dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_systolic
  reg riskypulse dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_pulse
  reg anycardio dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_anycardio
  poisson cardiosum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_cardiosum_pois
  nbreg cardiosum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust d(c)
  estimates store tab7dd_cardiosum_nb

  local infl_markers "riskyAlbumin riskycrp anyinflamation"

  reg riskyAlbumin dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_albumin
  reg riskycrp dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_crp
  reg anyinflamation dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_anyinfl
  poisson inflsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store tab7dd_inflsum_pois
  nbreg inflsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust d(c)
  estimates store tab7dd_inflsum_nb

  preserve
  keep if kids > 0
  reg riskyglycatedhemoglobin ddd_treat `X_ddd', robust
  estimates store tab7ddd_hba1c
  reg riskyCholest ddd_treat `X_ddd', robust
  estimates store tab7ddd_cholest
  reg riskyhdl ddd_treat `X_ddd', robust
  estimates store tab7ddd_hdl
  reg anymetab ddd_treat `X_ddd', robust
  estimates store tab7ddd_anymetab
  poisson metabsum ddd_treat `X_ddd', robust
  estimates store tab7ddd_metabsum_pois
  nbreg metabsum ddd_treat `X_ddd', robust d(c)
  estimates store tab7ddd_metabsum_nb

  reg riskydiastolic ddd_treat `X_ddd', robust
  estimates store tab7ddd_diastolic
  reg riskysystolic ddd_treat `X_ddd', robust
  estimates store tab7ddd_systolic
  reg riskypulse ddd_treat `X_ddd', robust
  estimates store tab7ddd_pulse
  reg anycardio ddd_treat `X_ddd', robust
  estimates store tab7ddd_anycardio
  poisson cardiosum ddd_treat `X_ddd', robust
  estimates store tab7ddd_cardiosum_pois
  nbreg cardiosum ddd_treat `X_ddd', robust d(c)
  estimates store tab7ddd_cardiosum_nb

  reg riskyAlbumin ddd_treat `X_ddd', robust
  estimates store tab7ddd_albumin
  reg riskycrp ddd_treat `X_ddd', robust
  estimates store tab7ddd_crp
  reg anyinflamation ddd_treat `X_ddd', robust
  estimates store tab7ddd_anyinfl
  poisson inflsum ddd_treat `X_ddd', robust
  estimates store tab7ddd_inflsum_pois
  nbreg inflsum ddd_treat `X_ddd', robust d(c)
  estimates store tab7ddd_inflsum_nb
  restore

  // ---- Extract Tab7 scalars ----
  // OLS rows: ttail p-value; Poisson/NB rows: normal z p-value

  // Panel A: Metabolic
  foreach m in hba1c cholest hdl anymetab {
      estimates restore tab7dd_`m'
      scalar b7dd_`m'  = _b[dd_treat]
      scalar se7dd_`m' = _se[dd_treat]
      scalar p7dd_`m'  = 2*ttail(e(df_r), abs(_b[dd_treat]/_se[dd_treat]))
      estimates restore tab7ddd_`m'
      scalar b7ddd_`m'  = _b[ddd_treat]
      scalar se7ddd_`m' = _se[ddd_treat]
      scalar p7ddd_`m'  = 2*ttail(e(df_r), abs(_b[ddd_treat]/_se[ddd_treat]))
  }
  foreach suf in metabsum_pois metabsum_nb {
      estimates restore tab7dd_`suf'
      scalar b7dd_`suf'  = _b[dd_treat]
      scalar se7dd_`suf' = _se[dd_treat]
      scalar p7dd_`suf'  = 2*normal(-abs(_b[dd_treat]/_se[dd_treat]))
      estimates restore tab7ddd_`suf'
      scalar b7ddd_`suf'  = _b[ddd_treat]
      scalar se7ddd_`suf' = _se[ddd_treat]
      scalar p7ddd_`suf'  = 2*normal(-abs(_b[ddd_treat]/_se[ddd_treat]))
  }

  // Panel B: Cardiovascular
  foreach c in diastolic systolic pulse anycardio {
      estimates restore tab7dd_`c'
      scalar b7dd_`c'  = _b[dd_treat]
      scalar se7dd_`c' = _se[dd_treat]
      scalar p7dd_`c'  = 2*ttail(e(df_r), abs(_b[dd_treat]/_se[dd_treat]))
      estimates restore tab7ddd_`c'
      scalar b7ddd_`c'  = _b[ddd_treat]
      scalar se7ddd_`c' = _se[ddd_treat]
      scalar p7ddd_`c'  = 2*ttail(e(df_r), abs(_b[ddd_treat]/_se[ddd_treat]))
  }
  foreach suf in cardiosum_pois cardiosum_nb {
      estimates restore tab7dd_`suf'
      scalar b7dd_`suf'  = _b[dd_treat]
      scalar se7dd_`suf' = _se[dd_treat]
      scalar p7dd_`suf'  = 2*normal(-abs(_b[dd_treat]/_se[dd_treat]))
      estimates restore tab7ddd_`suf'
      scalar b7ddd_`suf'  = _b[ddd_treat]
      scalar se7ddd_`suf' = _se[ddd_treat]
      scalar p7ddd_`suf'  = 2*normal(-abs(_b[ddd_treat]/_se[ddd_treat]))
  }

  // Panel C: Inflammation
  foreach i in albumin crp anyinfl {
      estimates restore tab7dd_`i'
      scalar b7dd_`i'  = _b[dd_treat]
      scalar se7dd_`i' = _se[dd_treat]
      scalar p7dd_`i'  = 2*ttail(e(df_r), abs(_b[dd_treat]/_se[dd_treat]))
      estimates restore tab7ddd_`i'
      scalar b7ddd_`i'  = _b[ddd_treat]
      scalar se7ddd_`i' = _se[ddd_treat]
      scalar p7ddd_`i'  = 2*ttail(e(df_r), abs(_b[ddd_treat]/_se[ddd_treat]))
  }
  foreach suf in inflsum_pois inflsum_nb {
      estimates restore tab7dd_`suf'
      scalar b7dd_`suf'  = _b[dd_treat]
      scalar se7dd_`suf' = _se[dd_treat]
      scalar p7dd_`suf'  = 2*normal(-abs(_b[dd_treat]/_se[dd_treat]))
      estimates restore tab7ddd_`suf'
      scalar b7ddd_`suf'  = _b[ddd_treat]
      scalar se7ddd_`suf' = _se[ddd_treat]
      scalar p7ddd_`suf'  = 2*normal(-abs(_b[ddd_treat]/_se[ddd_treat]))
  }

  // Pre-expansion means
  foreach v in riskyglycatedhemoglobin riskyCholest riskyhdl anymetab ///
               riskydiastolic riskysystolic riskypulse anycardio ///
               riskyAlbumin riskycrp anyinflamation {
      quietly sum `v' if year == 0 & twoplus_kids == 1 & highgrade <= 2
      scalar pm7_`v' = r(mean)
  }

  // ---- Write Tab7 LaTeX ----
  // Helper: writes b / (se) / [p] for dd and ddd

  local b7dd_albumin_s = strtrim(string(scalar(b7dd_albumin), "%9.4f"))
  local b7dd_anycardio_s = strtrim(string(scalar(b7dd_anycardio), "%9.4f"))
  local b7dd_anyinfl_s = strtrim(string(scalar(b7dd_anyinfl), "%9.4f"))
  local b7dd_anymetab_s = strtrim(string(scalar(b7dd_anymetab), "%9.4f"))
  local b7dd_cardiosum_pois_s = strtrim(string(scalar(b7dd_cardiosum_pois), "%9.4f"))
  local b7dd_cholest_s = strtrim(string(scalar(b7dd_cholest), "%9.4f"))
  local b7dd_crp_s = strtrim(string(scalar(b7dd_crp), "%9.4f"))
  local b7dd_diastolic_s = strtrim(string(scalar(b7dd_diastolic), "%9.4f"))
  local b7dd_hba1c_s = strtrim(string(scalar(b7dd_hba1c), "%9.4f"))
  local b7dd_hdl_s = strtrim(string(scalar(b7dd_hdl), "%9.4f"))
  local b7dd_inflsum_pois_s = strtrim(string(scalar(b7dd_inflsum_pois), "%9.4f"))
  local b7dd_metabsum_pois_s = strtrim(string(scalar(b7dd_metabsum_pois), "%9.4f"))
  local b7dd_pulse_s = strtrim(string(scalar(b7dd_pulse), "%9.4f"))
  local b7dd_systolic_s = strtrim(string(scalar(b7dd_systolic), "%9.4f"))
  local b7ddd_albumin_s = strtrim(string(scalar(b7ddd_albumin), "%9.4f"))
  local b7ddd_anycardio_s = strtrim(string(scalar(b7ddd_anycardio), "%9.4f"))
  local b7ddd_anyinfl_s = strtrim(string(scalar(b7ddd_anyinfl), "%9.4f"))
  local b7ddd_anymetab_s = strtrim(string(scalar(b7ddd_anymetab), "%9.4f"))
  local b7ddd_cardiosum_pois_s = strtrim(string(scalar(b7ddd_cardiosum_pois), "%9.4f"))
  local b7ddd_cholest_s = strtrim(string(scalar(b7ddd_cholest), "%9.4f"))
  local b7ddd_crp_s = strtrim(string(scalar(b7ddd_crp), "%9.4f"))
  local b7ddd_diastolic_s = strtrim(string(scalar(b7ddd_diastolic), "%9.4f"))
  local b7ddd_hba1c_s = strtrim(string(scalar(b7ddd_hba1c), "%9.4f"))
  local b7ddd_hdl_s = strtrim(string(scalar(b7ddd_hdl), "%9.4f"))
  local b7ddd_inflsum_pois_s = strtrim(string(scalar(b7ddd_inflsum_pois), "%9.4f"))
  local b7ddd_metabsum_pois_s = strtrim(string(scalar(b7ddd_metabsum_pois), "%9.4f"))
  local b7ddd_pulse_s = strtrim(string(scalar(b7ddd_pulse), "%9.4f"))
  local b7ddd_systolic_s = strtrim(string(scalar(b7ddd_systolic), "%9.4f"))
  local p7dd_albumin_s = strtrim(string(scalar(p7dd_albumin), "%9.4f"))
  local p7dd_anycardio_s = strtrim(string(scalar(p7dd_anycardio), "%9.4f"))
  local p7dd_anyinfl_s = strtrim(string(scalar(p7dd_anyinfl), "%9.4f"))
  local p7dd_anymetab_s = strtrim(string(scalar(p7dd_anymetab), "%9.4f"))
  local p7dd_cardiosum_pois_s = strtrim(string(scalar(p7dd_cardiosum_pois), "%9.4f"))
  local p7dd_cholest_s = strtrim(string(scalar(p7dd_cholest), "%9.4f"))
  local p7dd_crp_s = strtrim(string(scalar(p7dd_crp), "%9.4f"))
  local p7dd_diastolic_s = strtrim(string(scalar(p7dd_diastolic), "%9.4f"))
  local p7dd_hba1c_s = strtrim(string(scalar(p7dd_hba1c), "%9.4f"))
  local p7dd_hdl_s = strtrim(string(scalar(p7dd_hdl), "%9.4f"))
  local p7dd_inflsum_pois_s = strtrim(string(scalar(p7dd_inflsum_pois), "%9.4f"))
  local p7dd_metabsum_pois_s = strtrim(string(scalar(p7dd_metabsum_pois), "%9.4f"))
  local p7dd_pulse_s = strtrim(string(scalar(p7dd_pulse), "%9.4f"))
  local p7dd_systolic_s = strtrim(string(scalar(p7dd_systolic), "%9.4f"))
  local p7ddd_albumin_s = strtrim(string(scalar(p7ddd_albumin), "%9.4f"))
  local p7ddd_anycardio_s = strtrim(string(scalar(p7ddd_anycardio), "%9.4f"))
  local p7ddd_anyinfl_s = strtrim(string(scalar(p7ddd_anyinfl), "%9.4f"))
  local p7ddd_anymetab_s = strtrim(string(scalar(p7ddd_anymetab), "%9.4f"))
  local p7ddd_cardiosum_pois_s = strtrim(string(scalar(p7ddd_cardiosum_pois), "%9.4f"))
  local p7ddd_cholest_s = strtrim(string(scalar(p7ddd_cholest), "%9.4f"))
  local p7ddd_crp_s = strtrim(string(scalar(p7ddd_crp), "%9.4f"))
  local p7ddd_diastolic_s = strtrim(string(scalar(p7ddd_diastolic), "%9.4f"))
  local p7ddd_hba1c_s = strtrim(string(scalar(p7ddd_hba1c), "%9.4f"))
  local p7ddd_hdl_s = strtrim(string(scalar(p7ddd_hdl), "%9.4f"))
  local p7ddd_inflsum_pois_s = strtrim(string(scalar(p7ddd_inflsum_pois), "%9.4f"))
  local p7ddd_metabsum_pois_s = strtrim(string(scalar(p7ddd_metabsum_pois), "%9.4f"))
  local p7ddd_pulse_s = strtrim(string(scalar(p7ddd_pulse), "%9.4f"))
  local p7ddd_systolic_s = strtrim(string(scalar(p7ddd_systolic), "%9.4f"))
  local pm7_anycardio_s = strtrim(string(scalar(pm7_anycardio), "%9.4f"))
  local pm7_anyinflamation_s = strtrim(string(scalar(pm7_anyinflamation), "%9.4f"))
  local pm7_anymetab_s = strtrim(string(scalar(pm7_anymetab), "%9.4f"))
  local pm7_riskyAlbumin_s = strtrim(string(scalar(pm7_riskyAlbumin), "%9.4f"))
  local pm7_riskyCholest_s = strtrim(string(scalar(pm7_riskyCholest), "%9.4f"))
  local pm7_riskycrp_s = strtrim(string(scalar(pm7_riskycrp), "%9.4f"))
  local pm7_riskydiastolic_s = strtrim(string(scalar(pm7_riskydiastolic), "%9.4f"))
  local pm7_riskyglycatedhemoglobin_s = strtrim(string(scalar(pm7_riskyglycatedhemoglobin), "%9.4f"))
  local pm7_riskyhdl_s = strtrim(string(scalar(pm7_riskyhdl), "%9.4f"))
  local pm7_riskypulse_s = strtrim(string(scalar(pm7_riskypulse), "%9.4f"))
  local pm7_riskysystolic_s = strtrim(string(scalar(pm7_riskysystolic), "%9.4f"))
  local se7dd_albumin_s = strtrim(string(scalar(se7dd_albumin), "%9.4f"))
  local se7dd_anycardio_s = strtrim(string(scalar(se7dd_anycardio), "%9.4f"))
  local se7dd_anyinfl_s = strtrim(string(scalar(se7dd_anyinfl), "%9.4f"))
  local se7dd_anymetab_s = strtrim(string(scalar(se7dd_anymetab), "%9.4f"))
  local se7dd_cardiosum_pois_s = strtrim(string(scalar(se7dd_cardiosum_pois), "%9.4f"))
  local se7dd_cholest_s = strtrim(string(scalar(se7dd_cholest), "%9.4f"))
  local se7dd_crp_s = strtrim(string(scalar(se7dd_crp), "%9.4f"))
  local se7dd_diastolic_s = strtrim(string(scalar(se7dd_diastolic), "%9.4f"))
  local se7dd_hba1c_s = strtrim(string(scalar(se7dd_hba1c), "%9.4f"))
  local se7dd_hdl_s = strtrim(string(scalar(se7dd_hdl), "%9.4f"))
  local se7dd_inflsum_pois_s = strtrim(string(scalar(se7dd_inflsum_pois), "%9.4f"))
  local se7dd_metabsum_pois_s = strtrim(string(scalar(se7dd_metabsum_pois), "%9.4f"))
  local se7dd_pulse_s = strtrim(string(scalar(se7dd_pulse), "%9.4f"))
  local se7dd_systolic_s = strtrim(string(scalar(se7dd_systolic), "%9.4f"))
  local se7ddd_albumin_s = strtrim(string(scalar(se7ddd_albumin), "%9.4f"))
  local se7ddd_anycardio_s = strtrim(string(scalar(se7ddd_anycardio), "%9.4f"))
  local se7ddd_anyinfl_s = strtrim(string(scalar(se7ddd_anyinfl), "%9.4f"))
  local se7ddd_anymetab_s = strtrim(string(scalar(se7ddd_anymetab), "%9.4f"))
  local se7ddd_cardiosum_pois_s = strtrim(string(scalar(se7ddd_cardiosum_pois), "%9.4f"))
  local se7ddd_cholest_s = strtrim(string(scalar(se7ddd_cholest), "%9.4f"))
  local se7ddd_crp_s = strtrim(string(scalar(se7ddd_crp), "%9.4f"))
  local se7ddd_diastolic_s = strtrim(string(scalar(se7ddd_diastolic), "%9.4f"))
  local se7ddd_hba1c_s = strtrim(string(scalar(se7ddd_hba1c), "%9.4f"))
  local se7ddd_hdl_s = strtrim(string(scalar(se7ddd_hdl), "%9.4f"))
  local se7ddd_inflsum_pois_s = strtrim(string(scalar(se7ddd_inflsum_pois), "%9.4f"))
  local se7ddd_metabsum_pois_s = strtrim(string(scalar(se7ddd_metabsum_pois), "%9.4f"))
  local se7ddd_pulse_s = strtrim(string(scalar(se7ddd_pulse), "%9.4f"))
  local se7ddd_systolic_s = strtrim(string(scalar(se7ddd_systolic), "%9.4f"))
  file open tab7 using `outPath'Tables/Tab7.tex, write replace
  file write tab7 "\begin{table}[htbp]" _n
  file write tab7 "\centering" _n
  file write tab7 "\caption{Regression-Adjusted DD and DDD Estimates for Individual Biomarkers, Women Aged 21--40}" _n
  file write tab7 "\begin{tabular}{lccc}" _n
  file write tab7 "\toprule" _n
  file write tab7 " & Preexpansion mean & & \\" _n
  file write tab7 "Outcome & (treatment group) & DD & DDD \\" _n
  file write tab7 "\midrule" _n

  // Panel A
  file write tab7 "\multicolumn{4}{l}{\textit{Panel A. Metabolic biomarkers}} \\" _n
  file write tab7 "\addlinespace" _n

  // row macro: name premeanscalar ddscalar dddscalar
  // HbA1c
  file write tab7 "Risky glycated hemoglobin"
  file write tab7 " & `pm7_riskyglycatedhemoglobin_s\'"
  file write tab7 " & `b7dd_hba1c_s\'"
  file write tab7 " & `b7ddd_hba1c_s\' \\" _n
  file write tab7 " & & (`se7dd_hba1c_s\') & (`se7ddd_hba1c_s\') \\" _n
  file write tab7 " & & [`p7dd_hba1c_s\'] & [`p7ddd_hba1c_s\'] \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Risky total cholesterol"
  file write tab7 " & `pm7_riskyCholest_s\'"
  file write tab7 " & `b7dd_cholest_s\'"
  file write tab7 " & `b7ddd_cholest_s\' \\" _n
  file write tab7 " & & (`se7dd_cholest_s\') & (`se7ddd_cholest_s\') \\" _n
  file write tab7 " & & [`p7dd_cholest_s\'] & [`p7ddd_cholest_s\'] \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Risky HDL"
  file write tab7 " & `pm7_riskyhdl_s\'"
  file write tab7 " & `b7dd_hdl_s\'"
  file write tab7 " & `b7ddd_hdl_s\' \\" _n
  file write tab7 " & & (`se7dd_hdl_s\') & (`se7ddd_hdl_s\') \\" _n
  file write tab7 " & & [`p7dd_hdl_s\'] & [`p7ddd_hdl_s\'] \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Any risky metabolic condition"
  file write tab7 " & `pm7_anymetab_s\'"
  file write tab7 " & `b7dd_anymetab_s\'"
  file write tab7 " & `b7ddd_anymetab_s\' \\" _n
  file write tab7 " & & (`se7dd_anymetab_s\') & (`se7ddd_anymetab_s\') \\" _n
  file write tab7 " & & [`p7dd_anymetab_s\'] & [`p7ddd_anymetab_s\'] \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Poisson: number of risky metabolic conditions"
  file write tab7 " & & `b7dd_metabsum_pois_s\'"
  file write tab7 " & `b7ddd_metabsum_pois_s\' \\" _n
  file write tab7 " & & (`se7dd_metabsum_pois_s\') & (`se7ddd_metabsum_pois_s\') \\" _n
  file write tab7 " & & [`p7dd_metabsum_pois_s\'] & [`p7ddd_metabsum_pois_s\'] \\" _n

  // Panel B
  file write tab7 "\midrule" _n
  file write tab7 "\multicolumn{4}{l}{\textit{Panel B. Cardiovascular biomarkers}} \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Risky diastolic blood pressure"
  file write tab7 " & `pm7_riskydiastolic_s\'"
  file write tab7 " & `b7dd_diastolic_s\'"
  file write tab7 " & `b7ddd_diastolic_s\' \\" _n
  file write tab7 " & & (`se7dd_diastolic_s\') & (`se7ddd_diastolic_s\') \\" _n
  file write tab7 " & & [`p7dd_diastolic_s\'] & [`p7ddd_diastolic_s\'] \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Risky systolic blood pressure"
  file write tab7 " & `pm7_riskysystolic_s\'"
  file write tab7 " & `b7dd_systolic_s\'"
  file write tab7 " & `b7ddd_systolic_s\' \\" _n
  file write tab7 " & & (`se7dd_systolic_s\') & (`se7ddd_systolic_s\') \\" _n
  file write tab7 " & & [`p7dd_systolic_s\'] & [`p7ddd_systolic_s\'] \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Risky pulse"
  file write tab7 " & `pm7_riskypulse_s\'"
  file write tab7 " & `b7dd_pulse_s\'"
  file write tab7 " & `b7ddd_pulse_s\' \\" _n
  file write tab7 " & & (`se7dd_pulse_s\') & (`se7ddd_pulse_s\') \\" _n
  file write tab7 " & & [`p7dd_pulse_s\'] & [`p7ddd_pulse_s\'] \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Any risky cardiovascular condition"
  file write tab7 " & `pm7_anycardio_s\'"
  file write tab7 " & `b7dd_anycardio_s\'"
  file write tab7 " & `b7ddd_anycardio_s\' \\" _n
  file write tab7 " & & (`se7dd_anycardio_s\') & (`se7ddd_anycardio_s\') \\" _n
  file write tab7 " & & [`p7dd_anycardio_s\'] & [`p7ddd_anycardio_s\'] \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Poisson: number of risky cardiovascular conditions"
  file write tab7 " & & `b7dd_cardiosum_pois_s\'"
  file write tab7 " & `b7ddd_cardiosum_pois_s\' \\" _n
  file write tab7 " & & (`se7dd_cardiosum_pois_s\') & (`se7ddd_cardiosum_pois_s\') \\" _n
  file write tab7 " & & [`p7dd_cardiosum_pois_s\'] & [`p7ddd_cardiosum_pois_s\'] \\" _n

  // Panel C
  file write tab7 "\midrule" _n
  file write tab7 "\multicolumn{4}{l}{\textit{Panel C. Inflammation biomarkers}} \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Risky albumin"
  file write tab7 " & `pm7_riskyAlbumin_s\'"
  file write tab7 " & `b7dd_albumin_s\'"
  file write tab7 " & `b7ddd_albumin_s\' \\" _n
  file write tab7 " & & (`se7dd_albumin_s\') & (`se7ddd_albumin_s\') \\" _n
  file write tab7 " & & [`p7dd_albumin_s\'] & [`p7ddd_albumin_s\'] \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Risky C-reactive protein"
  file write tab7 " & `pm7_riskycrp_s\'"
  file write tab7 " & `b7dd_crp_s\'"
  file write tab7 " & `b7ddd_crp_s\' \\" _n
  file write tab7 " & & (`se7dd_crp_s\') & (`se7ddd_crp_s\') \\" _n
  file write tab7 " & & [`p7dd_crp_s\'] & [`p7ddd_crp_s\'] \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Any risky inflammatory condition"
  file write tab7 " & `pm7_anyinflamation_s\'"
  file write tab7 " & `b7dd_anyinfl_s\'"
  file write tab7 " & `b7ddd_anyinfl_s\' \\" _n
  file write tab7 " & & (`se7dd_anyinfl_s\') & (`se7ddd_anyinfl_s\') \\" _n
  file write tab7 " & & [`p7dd_anyinfl_s\'] & [`p7ddd_anyinfl_s\'] \\" _n
  file write tab7 "\addlinespace" _n

  file write tab7 "Poisson: number of risky inflammatory conditions"
  file write tab7 " & & `b7dd_inflsum_pois_s\'"
  file write tab7 " & `b7ddd_inflsum_pois_s\' \\" _n
  file write tab7 " & & (`se7dd_inflsum_pois_s\') & (`se7ddd_inflsum_pois_s\') \\" _n
  file write tab7 " & & [`p7dd_inflsum_pois_s\'] & [`p7ddd_inflsum_pois_s\'] \\" _n

  file write tab7 "\bottomrule" _n
  file write tab7 "\end{tabular}" _n
  file write tab7 "\begin{minipage}{\linewidth}" _n
  file write tab7 "\smallskip\footnotesize" _n
  file write tab7 "\textit{Notes:} Standard errors in parentheses; \$p\$-values in square brackets." _n
  file write tab7 " All standard errors allow for arbitrary heteroskedasticity." _n
  file write tab7 " DD covariates: dummies for age, race, marital status, and survey year." _n
  file write tab7 " DDD covariates add interactions between education$\times$year, kids$\times$year, and education$\times$kids." _n
  file write tab7 "\end{minipage}" _n
  file write tab7 "\end{table}" _n
  file close tab7
}

if `Fig4' {
  use `dataPath'BRFSS_Final_Data.dta, clear

  // Panel A - LFP %
  
  drop if kids == 0 | kids == .
  drop if educ == 3
  drop if fips > 56
  gen low_educ = educ <= 2
  gen treat = twoplus_kids*low_educ

  preserve
  keep if year >= 1993 & year <= 2001
  collapse (mean) inlf, by(year treat)
  tsset treat year

  local y0_min = 0.65 //matching 2+ yaxis
  local y0_max = 0.73
  local y1_min = 0.75 //matching 1 child yaxis
  local y1_max = 0.83


  twoway ///
      (tsline inlf if treat==1, lcolor(black) lwidth(medium)) ///
      (tsline inlf if treat==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
      , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
        xscale(range(1993 2001)) xlabel(1993(1)2001) ///
        yscale(range(`y0_min' `y0_max')) ylabel(`y0_min'(0.02)`y0_max') ///
        yscale(range(`y1_min' `y1_max') axis(2)) ylabel(`y1_min'(0.02)`y1_max', axis(2)) ///
        xline(1996, lcolor(red) lpattern(dash)) ///
        ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
        xtitle("Year") title("Panel A: % in labor force") ///
        name("Fig4_LaborForce", replace)
  graph export `output'Fig_LaborForce.pdf, replace
  restore

  preserve
  // Panel B - Excellent/Very Good Health %
  collapse (mean) excel_vgood, by(year treat)
  tsset treat year

  local y0_min = 0.48 //matching 2+ yaxis
  local y0_max = 0.60
  local y1_min = 0.48 //matching 1 child yaxis
  local y1_max = 0.60

  twoway ///
      (tsline excel_vgood if treat==1, lcolor(black) lwidth(medium)) ///
      (tsline excel_vgood if treat==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
      , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
        xscale(range(1993 2001)) xlabel(1993(1)2001) ///
        yscale(range(`y0_min' `y0_max')) ylabel(`y0_min'(0.02)`y0_max') ///
        yscale(range(`y1_min' `y1_max') axis(2)) ylabel(`y1_min'(0.02)`y1_max', axis(2)) ///
        xline(1996, lcolor(red) lpattern(dash)) ///
        ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
        xtitle("Year") title("Panel B: % in Excellent/Very Good Health") ///
        name("Fig4_ExcellentHealth", replace)
  graph export `output'Fig_ExcellentHealth.pdf, replace
  restore

  // Panel C - Mental Health
  preserve
  collapse (mean) mental_poor, by(year treat)
  tsset treat year

  twoway ///
      (tsline mental_poor if treat==1, lcolor(black) lwidth(medium)) ///
      (tsline mental_poor if treat==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
      , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
        xscale(range(1993 2001)) xlabel(1993(1)2001) ///
        yscale(range(4.0,6.0)) ylabel(4(0.25)6) ///
        yscale(range(3.75,5.75) axis(2)) ylabel(3.75(0.25)5.75, axis(2)) ///
        xline(1996, lcolor(red) lpattern(dash)) ///
        ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
        xtitle("Year") title("Panel C: % in Poor Mental Health") ///
        name("Fig4_MentalHealth", replace)
  graph export `output'Fig_MentalHealth.pdf, replace
  restore

  // Panel D - Physical Health
  preserve
  collapse (mean) phys_poor, by(year treat)
  tsset treat year


  twoway ///
      (tsline phys_poor if treat==1, lcolor(black) lwidth(medium)) ///
      (tsline phys_poor if treat==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
      , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
        xscale(range(1993 2001)) xlabel(1993(1)2001) ///
        yscale(range(2.0,3.50)) ylabel(2.00(0.25)3.50) ///
        yscale(range(2.25,3.75) axis(2)) ylabel(2.25(0.25)3.75, axis(2)) ///
        xline(1996, lcolor(red) lpattern(dash)) ///
        ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
        xtitle("Year") title("Panel D: % in Poor Physical Health") ///
        name("Fig4_PhysicalHealth", replace)
  graph export `output'Fig_PhysHealth.pdf, replace
  restore

  preserve
  collapse (mean) at_work, by(year treat)
  tsset treat year
  local y0_min = 0.60 //matching 2+ yaxis
  local y0_max = 0.70
  local y1_min = 0.70 //matching 1 child yaxis
  local y1_max = 0.80
  twoway ///
      (tsline at_work if treat==1, lcolor(black) lwidth(medium)) ///
      (tsline at_work if treat==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
      , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
        xscale(range(1993 2001)) xlabel(1993(1)2001) ///
        xline(1996, lcolor(red) lpattern(dash)) ///
        ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
        xtitle("Year") title("Panel E: % at work") ///
        name("Fig4_Working", replace)
  graph export `output'Fig_LF.pdf, replace
  restore

}

if `ARC' {
  use `dataPath'BRFSS_Final_Data.dta, clear

  drop if educ == 3
  drop if age < 21 | age > 40
  drop if fips > 56

  // Additional Robustness Checks - Footnote 12 (col1), Footnote 21 - diff years excluded (col2), Footnote 21 - years specified (col3)

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies
  local Y_1 "at_work excel_vgood" // list of dependent variables
  local Y_2 "mental_poor phys_poor"

  // Footnote 12 - Treatment in 1995 (rebates from 94 distributed)
  preserve
  drop if kids==0 | kids == .
  gen dd_treat_95 = (year == 1995)*twoplus_kids
  foreach y in `Y_1' {
      reg `y' dd_treat_95 `X', cluster(fips)
      estimates store footnote12_`y'
  }
  foreach y in `Y_2' {
      nbreg `y' dd_treat_95 `X', cluster(fips)
      estimates store footnote12_`y'
  }
  restore

  // Footnote 21 - Child Tax Credit - Exclude yearrs where CTC was in existence (1998-2001)
  preserve
  drop if year >= 2000
  foreach y in `Y_1' {
      reg `y' dd_treatment `X' if educ <= 2, cluster(fips)
      estimates store footnote21_2000_`y'
  }
  foreach y in `Y_2' {
      nbreg `y' dd_treatment `X' if educ <= 2, cluster(fips)
      estimates store footnote21_2000_`y'
  }
  restore

  preserve
  drop if year >= 1999
  foreach y in `Y_1' {
      reg `y' dd_treatment `X' if educ <= 2, cluster(fips)
      estimates store footnote21_1999_`y'
  }
  foreach y in `Y_2' {
      nbreg `y' dd_treatment `X' if educ <= 2, cluster(fips)
      estimates store footnote21_1999_`y'
  }
  restore

  // ---- Extract ARC scalars ----
  // Col 1: footnote12 uses dd_treat_95 (OLS: at_work/excel, nbreg: mental/phys)
  // Col 2: footnote21_2000, Col 3: footnote21_1999 — all use dd_treatment

  estimates restore footnote12_at_work
  scalar arc_b1_at   = _b[dd_treat_95]
  scalar arc_se1_at  = _se[dd_treat_95]
  scalar arc_p1_at   = 2*ttail(e(df_r), abs(_b[dd_treat_95]/_se[dd_treat_95]))

  estimates restore footnote21_2000_at_work
  scalar arc_b2_at   = _b[dd_treatment]
  scalar arc_se2_at  = _se[dd_treatment]
  scalar arc_p2_at   = 2*ttail(e(df_r), abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore footnote21_1999_at_work
  scalar arc_b3_at   = _b[dd_treatment]
  scalar arc_se3_at  = _se[dd_treatment]
  scalar arc_p3_at   = 2*ttail(e(df_r), abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore footnote12_excel_vgood
  scalar arc_b1_ex   = _b[dd_treat_95]
  scalar arc_se1_ex  = _se[dd_treat_95]
  scalar arc_p1_ex   = 2*ttail(e(df_r), abs(_b[dd_treat_95]/_se[dd_treat_95]))

  estimates restore footnote21_2000_excel_vgood
  scalar arc_b2_ex   = _b[dd_treatment]
  scalar arc_se2_ex  = _se[dd_treatment]
  scalar arc_p2_ex   = 2*ttail(e(df_r), abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore footnote21_1999_excel_vgood
  scalar arc_b3_ex   = _b[dd_treatment]
  scalar arc_se3_ex  = _se[dd_treatment]
  scalar arc_p3_ex   = 2*ttail(e(df_r), abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore footnote12_mental_poor
  scalar arc_b1_me   = _b[dd_treat_95]
  scalar arc_se1_me  = _se[dd_treat_95]
  scalar arc_p1_me   = 2*normal(-abs(_b[dd_treat_95]/_se[dd_treat_95]))

  estimates restore footnote21_2000_mental_poor
  scalar arc_b2_me   = _b[dd_treatment]
  scalar arc_se2_me  = _se[dd_treatment]
  scalar arc_p2_me   = 2*normal(-abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore footnote21_1999_mental_poor
  scalar arc_b3_me   = _b[dd_treatment]
  scalar arc_se3_me  = _se[dd_treatment]
  scalar arc_p3_me   = 2*normal(-abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore footnote12_phys_poor
  scalar arc_b1_ph   = _b[dd_treat_95]
  scalar arc_se1_ph  = _se[dd_treat_95]
  scalar arc_p1_ph   = 2*normal(-abs(_b[dd_treat_95]/_se[dd_treat_95]))

  estimates restore footnote21_2000_phys_poor
  scalar arc_b2_ph   = _b[dd_treatment]
  scalar arc_se2_ph  = _se[dd_treatment]
  scalar arc_p2_ph   = 2*normal(-abs(_b[dd_treatment]/_se[dd_treatment]))

  estimates restore footnote21_1999_phys_poor
  scalar arc_b3_ph   = _b[dd_treatment]
  scalar arc_se3_ph  = _se[dd_treatment]
  scalar arc_p3_ph   = 2*normal(-abs(_b[dd_treatment]/_se[dd_treatment]))

  // ---- Write ARC LaTeX ----

  local arc_b1_at_s = strtrim(string(scalar(arc_b1_at), "%9.4f"))
  local arc_b1_ex_s = strtrim(string(scalar(arc_b1_ex), "%9.4f"))
  local arc_b1_me_s = strtrim(string(scalar(arc_b1_me), "%9.4f"))
  local arc_b1_ph_s = strtrim(string(scalar(arc_b1_ph), "%9.4f"))
  local arc_b2_at_s = strtrim(string(scalar(arc_b2_at), "%9.4f"))
  local arc_b2_ex_s = strtrim(string(scalar(arc_b2_ex), "%9.4f"))
  local arc_b2_me_s = strtrim(string(scalar(arc_b2_me), "%9.4f"))
  local arc_b2_ph_s = strtrim(string(scalar(arc_b2_ph), "%9.4f"))
  local arc_b3_at_s = strtrim(string(scalar(arc_b3_at), "%9.4f"))
  local arc_b3_ex_s = strtrim(string(scalar(arc_b3_ex), "%9.4f"))
  local arc_b3_me_s = strtrim(string(scalar(arc_b3_me), "%9.4f"))
  local arc_b3_ph_s = strtrim(string(scalar(arc_b3_ph), "%9.4f"))
  local arc_p1_at_s = strtrim(string(scalar(arc_p1_at), "%9.4f"))
  local arc_p1_ex_s = strtrim(string(scalar(arc_p1_ex), "%9.4f"))
  local arc_p1_me_s = strtrim(string(scalar(arc_p1_me), "%9.4f"))
  local arc_p1_ph_s = strtrim(string(scalar(arc_p1_ph), "%9.4f"))
  local arc_p2_at_s = strtrim(string(scalar(arc_p2_at), "%9.4f"))
  local arc_p2_ex_s = strtrim(string(scalar(arc_p2_ex), "%9.4f"))
  local arc_p2_me_s = strtrim(string(scalar(arc_p2_me), "%9.4f"))
  local arc_p2_ph_s = strtrim(string(scalar(arc_p2_ph), "%9.4f"))
  local arc_p3_at_s = strtrim(string(scalar(arc_p3_at), "%9.4f"))
  local arc_p3_ex_s = strtrim(string(scalar(arc_p3_ex), "%9.4f"))
  local arc_p3_me_s = strtrim(string(scalar(arc_p3_me), "%9.4f"))
  local arc_p3_ph_s = strtrim(string(scalar(arc_p3_ph), "%9.4f"))
  local arc_se1_at_s = strtrim(string(scalar(arc_se1_at), "%9.4f"))
  local arc_se1_ex_s = strtrim(string(scalar(arc_se1_ex), "%9.4f"))
  local arc_se1_me_s = strtrim(string(scalar(arc_se1_me), "%9.4f"))
  local arc_se1_ph_s = strtrim(string(scalar(arc_se1_ph), "%9.4f"))
  local arc_se2_at_s = strtrim(string(scalar(arc_se2_at), "%9.4f"))
  local arc_se2_ex_s = strtrim(string(scalar(arc_se2_ex), "%9.4f"))
  local arc_se2_me_s = strtrim(string(scalar(arc_se2_me), "%9.4f"))
  local arc_se2_ph_s = strtrim(string(scalar(arc_se2_ph), "%9.4f"))
  local arc_se3_at_s = strtrim(string(scalar(arc_se3_at), "%9.4f"))
  local arc_se3_ex_s = strtrim(string(scalar(arc_se3_ex), "%9.4f"))
  local arc_se3_me_s = strtrim(string(scalar(arc_se3_me), "%9.4f"))
  local arc_se3_ph_s = strtrim(string(scalar(arc_se3_ph), "%9.4f"))
  file open tabarc using `outPath'Tables/ARC.tex, write replace
  file write tabarc "\begin{table}[htbp]" _n
  file write tabarc "\centering" _n
  file write tabarc "\caption{Additional Robustness Checks, Women Aged 21--40, 1993--2001 BRFSS}" _n
  file write tabarc "\begin{tabular}{lccc}" _n
  file write tabarc "\toprule" _n
  file write tabarc " & 1995 treatment & Excl.\ 2000+ & Excl.\ 1999+ \\" _n
  file write tabarc "Outcome & (Footnote 12) & (Footnote 21) & (Footnote 21) \\" _n
  file write tabarc "\midrule" _n

  // At work
  file write tabarc "At work (OLS)"
  file write tabarc " & `arc_b1_at_s\'"
  file write tabarc " & `arc_b2_at_s\'"
  file write tabarc " & `arc_b3_at_s\' \\" _n
  file write tabarc " & (`arc_se1_at_s\')"
  file write tabarc " & (`arc_se2_at_s\')"
  file write tabarc " & (`arc_se3_at_s\') \\" _n
  file write tabarc " & [`arc_p1_at_s\']"
  file write tabarc " & [`arc_p2_at_s\']"
  file write tabarc " & [`arc_p3_at_s\'] \\" _n
  file write tabarc "\addlinespace" _n

  // Excellent/very good
  file write tabarc "Exc./very good health (OLS)"
  file write tabarc " & `arc_b1_ex_s\'"
  file write tabarc " & `arc_b2_ex_s\'"
  file write tabarc " & `arc_b3_ex_s\' \\" _n
  file write tabarc " & (`arc_se1_ex_s\')"
  file write tabarc " & (`arc_se2_ex_s\')"
  file write tabarc " & (`arc_se3_ex_s\') \\" _n
  file write tabarc " & [`arc_p1_ex_s\']"
  file write tabarc " & [`arc_p2_ex_s\']"
  file write tabarc " & [`arc_p3_ex_s\'] \\" _n
  file write tabarc "\addlinespace" _n

  // Mental
  file write tabarc "Bad mental health days (NegBin)"
  file write tabarc " & `arc_b1_me_s\'"
  file write tabarc " & `arc_b2_me_s\'"
  file write tabarc " & `arc_b3_me_s\' \\" _n
  file write tabarc " & (`arc_se1_me_s\')"
  file write tabarc " & (`arc_se2_me_s\')"
  file write tabarc " & (`arc_se3_me_s\') \\" _n
  file write tabarc " & [`arc_p1_me_s\']"
  file write tabarc " & [`arc_p2_me_s\']"
  file write tabarc " & [`arc_p3_me_s\'] \\" _n
  file write tabarc "\addlinespace" _n

  // Physical
  file write tabarc "Bad physical health days (NegBin)"
  file write tabarc " & `arc_b1_ph_s\'"
  file write tabarc " & `arc_b2_ph_s\'"
  file write tabarc " & `arc_b3_ph_s\' \\" _n
  file write tabarc " & (`arc_se1_ph_s\')"
  file write tabarc " & (`arc_se2_ph_s\')"
  file write tabarc " & (`arc_se3_ph_s\') \\" _n
  file write tabarc " & [`arc_p1_ph_s\']"
  file write tabarc " & [`arc_p2_ph_s\']"
  file write tabarc " & [`arc_p3_ph_s\'] \\" _n

  file write tabarc "\bottomrule" _n
  file write tabarc "\end{tabular}" _n
  file write tabarc "\begin{minipage}{\linewidth}" _n
  file write tabarc "\smallskip\footnotesize" _n
  file write tabarc "\textit{Notes:} Standard errors in parentheses; \$p\$-values in square brackets." _n
  file write tabarc " All standard errors allow for arbitrary correlations within state." _n
  file write tabarc " Column 1 tests whether treatment in 1995 (rebates from tax year 1994) drives results." _n
  file write tabarc " Columns 2--3 exclude years where the Child Tax Credit was in existence." _n
  file write tabarc "\end{minipage}" _n
  file write tabarc "\end{table}" _n
  file close tabarc
}
// Event Study following reg-adj DiD (Eq. 1)
// - This section will implement the extension
// task. The code chunk will plot and save the
// delta coefficients and 95% C.I. for 4 main
// outcomes (working, excel/vgood, poor mental
// health, poor physical health).

if `Extension' {
  use `dataPath'BRFSS_Final_Data.dta, clear

  drop if kids == 0 | kids == .


  forvalues yr = 1993/2001 {
    gen delta_`yr' = (year==`yr')*twoplus_kids
  }
  replace delta_1995 = 0 // normalize pre-expansion year to 0
  

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies
  local delta "delta_*"

  foreach y in at_work excel_vgood mental_poor phys_poor {
      reg `y' `delta' `X' if educ <= 2, cluster(fips)
      estimates store ext_`y'
  }

  local title_at_work "At Work"
  local title_excel_vgood "Excellent/Very Good Health"
  local title_mental_poor "Poor Mental Health"
  local title_phys_poor "Poor Physical Health"

  foreach y in at_work excel_vgood mental_poor phys_poor {
      coefplot ext_`y', ///
          keep(`delta') ///
          coeflabels(delta_1993="1993" delta_1994="1994" delta_1995="1995" delta_1996="1996" ///
                    delta_1997="1997" delta_1998="1998" delta_1999="1999" ///
                    delta_2000="2000" delta_2001="2001") ///
          vertical yline(0) xline(3, lcolor(red) lpattern(dash)) ///
          title("`title_`y''") ///
          xtitle("Year") ytitle("Coefficient (relative to 1995)")
      graph export `outPath'Graphs/EventStudy_`y'.pdf, replace
  }
}
