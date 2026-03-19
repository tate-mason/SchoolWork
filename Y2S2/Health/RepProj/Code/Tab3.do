/************************************************************
* Tab3.do                                                   *
* Table 3 - DiD OLS & Negative Binomial Estimates          *
*                                                           *
* Args: 1 = dataPath, 2 = outPath                          *
*                                                           *
* Estimates simple and regression-adjusted DiD for LFPR,   *
* excellent/very good health, and mental/physical health    *
* days using the 1993-2001 BRFSS. OLS for binary outcomes, *
* negative binomial for count outcomes.                     *
************************************************************/

local dataPath "`1'"
local outPath  "`2'"

use `dataPath'BRFSS_Final_Data.dta, clear // call BRFSS data

// subset to mothers with low education between 21 and 40 in relevant states
drop if kids == 0 | kids == .
drop if educ == 3
drop if age < 21 | age > 40
drop if fips > 56

// Pre-Treatment Means
sum at_work excel_vgood mental_poor phys_poor if year < 1996 & kids >= 2 & educ <= 2

// Simple OLS DiD
reg at_work twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on LFPR
estimates store working_simple

reg excel_vgood twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on Good Health
estimates store excel_simple

nbreg mental_poor twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on Mental Health
estimates store mental_simple

nbreg phys_poor twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on Physical health
estimates store phys_simple

// Regression Adjusted DiD - Adding Controls
local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // control vector of dummies

reg at_work dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
estimates store working_adj

reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health
estimates store excel_adj

nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health
estimates store mental_adj

nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health
estimates store phys_adj

// ---- Extract scalars ----
// Pre-expansion means for treatment group (2+ kids, educ<=2, pre-1996)
foreach y in at_work excel_vgood mental_poor phys_poor {
    quietly sum `y' if year < 1996 & twoplus_kids == 1 & educ <= 2
    scalar premean_`y' = r(mean)
}

// OLS: use e(df_r) for t-based p-value; nbreg: normal approximation (z-stat)
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

local b_at_work_adj_s         = strtrim(string(scalar(b_at_work_adj),         "%9.3f"))
local b_at_work_simple_s      = strtrim(string(scalar(b_at_work_simple),      "%9.3f"))
local b_excel_vgood_adj_s     = strtrim(string(scalar(b_excel_vgood_adj),     "%9.3f"))
local b_excel_vgood_simple_s  = strtrim(string(scalar(b_excel_vgood_simple),  "%9.3f"))
local b_mental_poor_adj_s     = strtrim(string(scalar(b_mental_poor_adj),     "%9.3f"))
local b_mental_poor_simple_s  = strtrim(string(scalar(b_mental_poor_simple),  "%9.3f"))
local b_phys_poor_adj_s       = strtrim(string(scalar(b_phys_poor_adj),       "%9.3f"))
local b_phys_poor_simple_s    = strtrim(string(scalar(b_phys_poor_simple),    "%9.3f"))
local p_at_work_adj_s         = strtrim(string(scalar(p_at_work_adj),         "%9.3f"))
local p_at_work_simple_s      = strtrim(string(scalar(p_at_work_simple),      "%9.3f"))
local p_excel_vgood_adj_s     = strtrim(string(scalar(p_excel_vgood_adj),     "%9.3f"))
local p_excel_vgood_simple_s  = strtrim(string(scalar(p_excel_vgood_simple),  "%9.3f"))
local p_mental_poor_adj_s     = strtrim(string(scalar(p_mental_poor_adj),     "%9.3f"))
local p_mental_poor_simple_s  = strtrim(string(scalar(p_mental_poor_simple),  "%9.3f"))
local p_phys_poor_adj_s       = strtrim(string(scalar(p_phys_poor_adj),       "%9.3f"))
local p_phys_poor_simple_s    = strtrim(string(scalar(p_phys_poor_simple),    "%9.3f"))
local premean_at_work_s       = strtrim(string(scalar(premean_at_work),       "%9.3f"))
local premean_excel_vgood_s   = strtrim(string(scalar(premean_excel_vgood),   "%9.3f"))
local premean_mental_poor_s   = strtrim(string(scalar(premean_mental_poor),   "%9.3f"))
local premean_phys_poor_s     = strtrim(string(scalar(premean_phys_poor),     "%9.3f"))
local se_at_work_adj_s        = strtrim(string(scalar(se_at_work_adj),        "%9.3f"))
local se_at_work_simple_s     = strtrim(string(scalar(se_at_work_simple),     "%9.3f"))
local se_excel_vgood_adj_s    = strtrim(string(scalar(se_excel_vgood_adj),    "%9.3f"))
local se_excel_vgood_simple_s = strtrim(string(scalar(se_excel_vgood_simple), "%9.3f"))
local se_mental_poor_adj_s    = strtrim(string(scalar(se_mental_poor_adj),    "%9.3f"))
local se_mental_poor_simple_s = strtrim(string(scalar(se_mental_poor_simple), "%9.3f"))
local se_phys_poor_adj_s      = strtrim(string(scalar(se_phys_poor_adj),      "%9.3f"))
local se_phys_poor_simple_s   = strtrim(string(scalar(se_phys_poor_simple),   "%9.3f"))

file open tab3 using `outPath'Tables/Tab3.tex, write replace
file write tab3 "\begin{table}[htbp]" _n
file write tab3 "\centering" _n
file write tab3 "\caption{Table 3: Difference-in-Differences OLS and Negative Binomial Estimates \\ Mothers Aged 21--40, 1993--2001 BRFSS}" _n
file write tab3 "\resizebox{\textwidth}{!}{%" _n
file write tab3 "\begin{tabular}{lcccc}" _n
file write tab3 "\toprule" _n
file write tab3 " & Preexpansion & Estimation & \multicolumn{2}{c}{DiD estimates} \\" _n
file write tab3 " & mean (treat.) & method & Simple & Reg. adjusted \\" _n
file write tab3 "\cmidrule(lr){4-5}" _n

// At work
file write tab3 "At work"
file write tab3 " & `premean_at_work_s\' & OLS & `b_at_work_simple_s\' & `b_at_work_adj_s\' \\" _n
file write tab3 " & & & (`se_at_work_simple_s\') & (`se_at_work_adj_s\') \\" _n
file write tab3 " & & & [`p_at_work_simple_s\'] & [`p_at_work_adj_s\'] \\" _n
file write tab3 "\addlinespace" _n

// Excellent/very good
file write tab3 "Excellent/very good health?"
file write tab3 " & `premean_excel_vgood_s\' & OLS & `b_excel_vgood_simple_s\' & `b_excel_vgood_adj_s\' \\" _n
file write tab3 " & & & (`se_excel_vgood_simple_s\') & (`se_excel_vgood_adj_s\') \\" _n
file write tab3 " & & & [`p_excel_vgood_simple_s\'] & [`p_excel_vgood_adj_s\'] \\" _n
file write tab3 "\addlinespace" _n

// Mental poor
file write tab3 "Number of bad mental health days in past month"
file write tab3 " & `premean_mental_poor_s\' & Negative binomial & `b_mental_poor_simple_s\' & `b_mental_poor_adj_s\' \\" _n
file write tab3 " & & & (`se_mental_poor_simple_s\') & (`se_mental_poor_adj_s\') \\" _n
file write tab3 " & & & [`p_mental_poor_simple_s\'] & [`p_mental_poor_adj_s\'] \\" _n
file write tab3 "\addlinespace" _n

// Physical poor
file write tab3 "Number of bad physical health days in past month"
file write tab3 " & `premean_phys_poor_s\' & Negative binomial & `b_phys_poor_simple_s\' & `b_phys_poor_adj_s\' \\" _n
file write tab3 " & & & (`se_phys_poor_simple_s\') & (`se_phys_poor_adj_s\') \\" _n
file write tab3 " & & & [`p_phys_poor_simple_s\'] & [`p_phys_poor_adj_s\'] \\" _n

file write tab3 "\bottomrule" _n
file write tab3 "\end{tabular}}" _n
file write tab3 "\begin{minipage}{\linewidth}" _n
file write tab3 "\smallskip\footnotesize" _n
file write tab3 "\textit{Notes:} Standard errors are reported in parentheses and p-values on the test of the null that the coefficient is zero "
file write tab3 "are reported in square brackets. All standard errors allow for arbitrary correlations between observations within the "
file write tab3 "same state. Other covariates in the difference-in-differences model include: Complete set of dummies for age, race, "
file write tab3 "marital status, and number of children for the respondent, plus a complete set of dummies for the month of survey, "
file write tab3 "year of survey, and state of residence." _n
file write tab3 " All standard errors allow for arbitrary correlations within state." _n
file write tab3 " Regression-adjusted estimates include dummies for age, race, marital status," _n
file write tab3 " number of children, month, year, and state of residence." _n
file write tab3 "\end{minipage}" _n
file write tab3 "\end{table}" _n
file close tab3
