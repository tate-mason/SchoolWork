/************************************************************
* Tab4.do                                                   *
* Table 4 - Robustness Tests                                *
*                                                           *
* Args: 1 = dataPath, 2 = outPath                          *
*                                                           *
* Six robustness columns: (1) baseline DD, (2) state x year *
* FE, (3) 2 vs 0 kids, (4) married subsample, (5) single   *
* subsample, (6) triple diff (DDD).                         *
************************************************************/

local dataPath "`1'"
local outPath  "`2'"

use `dataPath'BRFSS_Final_Data.dta, clear // load BRFSS data

// Column 1 - DiD Results Full Sample With Dummy Controls
drop if kids == 0 | kids == . // subset to only mothers

local X "i.race4 i.educ i.age i.month i.marital i.kids i.year" // control vector of dummies

reg at_work dd_treatment `X' if educ <= 2, cluster(fips)   // Effect on LFPR
estimates store tab4c1_at_work
reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health
estimates store tab4c1_excel
nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health
estimates store tab4c1_mental
nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips)   // Effect on Physical health
estimates store tab4c1_phys

// Column 2 - State x Year FE added
local X "i.race4 i.educ i.age i.month i.marital i.kids" // control vector without year FE (absorbed by state x year)

reg at_work dd_treatment fips#i.year `X' if educ <= 2, cluster(fips)
estimates store tab4c2_at_work
reg excel_vgood dd_treatment fips#i.year `X' if educ <= 2, cluster(fips)
estimates store tab4c2_excel
nbreg mental_poor dd_treatment fips#i.year `X' if educ <= 2, cluster(fips)
estimates store tab4c2_mental
nbreg phys_poor dd_treatment fips#i.year `X' if educ <= 2, cluster(fips)
estimates store tab4c2_phys

// Column 3 - Differencing by Amount of Children (2 vs 0)
use `dataPath'BRFSS_Final_Data.dta, clear
preserve
drop if kids == 1 // exclude mothers with one child

local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // control vector of dummies

reg at_work dd_treatment `X' if educ <= 2, cluster(fips)
estimates store tab4c3_at_work
reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips)
estimates store tab4c3_excel
nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips)
estimates store tab4c3_mental
nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips)
estimates store tab4c3_phys
restore

// Column 4 - Differentiating by Married
preserve
keep if marital == 1 // keep only married women
drop if kids == 0 // keep only mothers

local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // control vector of dummies

reg at_work dd_treatment `X' if educ <= 2, cluster(fips)
estimates store tab4c4_at_work
reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips)
estimates store tab4c4_excel
nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips)
estimates store tab4c4_mental
nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips)
estimates store tab4c4_phys
restore

// Column 5 - Differentiating by Single
preserve
keep if marital > 1 // keep women with status not equal to married
drop if kids == 0 // keep only mothers

local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // control vector of dummies

reg at_work dd_treatment `X' if educ <= 2, cluster(fips)
estimates store tab4c5_at_work
reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips)
estimates store tab4c5_excel
nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips)
estimates store tab4c5_mental
nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips)
estimates store tab4c5_phys
restore

// Column 6 - Triple Diff
preserve
local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year i.year##i.kids i.year##i.educ i.kids##i.educ"

drop if educ == 3 // drop some college
drop if kids == 0 | kids == . // drop non-mothers
gen hs_only = educ <= 2 // dummy for max of HS education

gen hs_expand    = hs_only * eitc_expand    // low educ x time interaction
gen twokids_expand = twoplus_kids * eitc_expand // time x 2+ kids interaction
gen hs_twokids   = hs_only * twoplus_kids   // low educ x 2+ kids interaction
gen treatment    = dd_treatment * hs_only   // triple-diff treatment

reg at_work treatment hs_expand twokids_expand hs_twokids `X', cluster(fips)
estimates store tab4c6_at_work
reg excel_vgood treatment hs_expand twokids_expand hs_twokids `X', cluster(fips)
estimates store tab4c6_excel
nbreg mental_poor treatment hs_expand twokids_expand hs_twokids `X', cluster(fips)
estimates store tab4c6_mental
nbreg phys_poor treatment hs_expand twokids_expand hs_twokids `X', cluster(fips)
estimates store tab4c6_phys
restore

// ---- Extract Tab4 scalars ----
// Cols 1-5: treatment variable is dd_treatment
// Col 6: treatment variable is treatment (triple diff)
// OLS outcomes (at_work, excel): ttail p-value
// nbreg outcomes (mental, phys): normal approximation p-value

foreach col in c1 c2 c3 c4 c5 {
    foreach y in at_work excel {
        estimates restore tab4`col'_`y'
        scalar b4_`col'_`y'  = _b[dd_treatment]
        scalar se4_`col'_`y' = _se[dd_treatment]
        scalar p4_`col'_`y'  = 2*ttail(e(df_r), abs(_b[dd_treatment]/_se[dd_treatment]))
    }
    foreach y in mental phys {
        estimates restore tab4`col'_`y'
        scalar b4_`col'_`y'  = _b[dd_treatment]
        scalar se4_`col'_`y' = _se[dd_treatment]
        scalar p4_`col'_`y'  = 2*normal(-abs(_b[dd_treatment]/_se[dd_treatment]))
    }
}

// Col 6 uses the triple-diff treatment variable
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
file write tab4 "\caption{Table 4: Robustness Tests, Women Aged 21--40, 1993--2001 BRFSS}" _n
file write tab4 "\resizebox{\textwidth}{!}{%" _n
file write tab4 "\begin{tabular}{lcccccc}" _n
file write tab4 "\toprule" _n
file write tab4 " & DD & DD state\$\times\$year & 2 vs 0 kids & DD married & DD single & DDD \\" _n
file write tab4 "Outcome & Method & FE & & & & \\" _n
file write tab4 "\midrule" _n

// At work
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
    local val = strtrim(string(scalar(p4_`col'_at_work), "%9.4f"))
    file write tab4 " & [`val']"
}
file write tab4 " \\" _n
file write tab4 "\addlinespace" _n

// Excellent/very good
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
    local val = strtrim(string(scalar(p4_`col'_excel), "%9.4f"))
    file write tab4 " & [`val']"
}
file write tab4 " \\" _n
file write tab4 "\addlinespace" _n

// Mental health
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
    local val = strtrim(string(scalar(p4_`col'_mental), "%9.4f"))
    file write tab4 " & [`val']"
}
file write tab4 " \\" _n
file write tab4 "\addlinespace" _n

// Physical health
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
    local val = strtrim(string(scalar(p4_`col'_phys), "%9.4f"))
    file write tab4 " & [`val']"
}
file write tab4 " \\" _n

file write tab4 "\bottomrule" _n
file write tab4 "\end{tabular}}" _n
file write tab4 "\begin{minipage}{\linewidth}" _n
file write tab4 "\smallskip\footnotesize" _n
file write tab4 "\textit{Notes:} Standard errors are reported in parentheses and p-values on the test of the null that the coefficient is zero "
file write tab4 "are reported in square brackets. All standard errors allow for arbitrary correlations between observations within the "
file write tab4 "same state. Other covariates in the difference-in-differences model include: complete set of dummies for age, race, "
file write tab4 "marital status, and number of children for the respondent, plus a complete set of dummies for the month of survey, "
file write tab4 "year of survey, and state of residence. Other covariates in the difference-in-difference-in-differences model include: "
file write tab4 "Complete set of dummies for age, race, marital status, education, and number of children for the respondent; a com"
file write tab4 "plete set of dummies for the month of survey, year of survey, state of residence, plus interactions between the edu"
file write tab4 "cation and the year effects, the number of children and the year effect, the education and number of children effects." _n
file write tab4 "\end{minipage}" _n
file write tab4 "\end{table}" _n
file close tab4
