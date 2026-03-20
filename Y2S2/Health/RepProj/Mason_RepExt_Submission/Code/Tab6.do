/************************************************************
* Tab6.do                                                   *
* Table 6 - NHANES DD/DDD: Allostatic Load Aggregates      *
*                                                           *
* Args: 1 = dataPath, 2 = outPath                          *
*                                                           *
* Loads nhanescleaned.dta (produced by Tab5.do) and the    *
* stacked NHANES file. Estimates DD (Col 1), DDD (Col 2),  *
* and 2+ vs 0 kids (Col 3) for aggregate allostatic load   *
* outcomes. Writes Tab6.tex.                                *
************************************************************/

local dataPath "`1'"
local outPath  "`2'"


/************************************************************
* Load the cleaned NHANES data and estimate DD and DDD      *
* models for the allostatic load aggregate outcomes. A      *
* third column uses the stacked NHANES dataset to compare   *
* women with 2+ children to women with 0 children,         *
* paralleling the analogous robustness column in Table 4.   *
************************************************************/
use `dataPath'nhanes/nhanescleaned.dta, clear

// Inflammation Panel
sum crp albumin inflsum anyinflamation if highgrad <= 2 & year == 0 & twoplus_kids == 1

// Cardiovascular Panel
sum diastolic systolic pulse cardiosum anycardio if highgrade <= 2 & year == 0 & twoplus_kids == 1

// Metabolic Panel
sum cholesterol hdl glycatedhemoglobin metabsum anymetab if highgrade <= 2 & year == 0 & twoplus_kids == 1

// Total Risk Factors
sum totalsum total1 total2 total3 if highgrade <= 2 & year == 0 & twoplus_kids == 1

// ---- DD and DDD Estimates ----

local X_dd  "i.year i.age i.marital i.race"                                              // DD control vector
local X_ddd "i.year i.age i.race i.marital i.highgrade##i.year i.year##i.twoplus_kids i.highgrade##i.twoplus_kids" // DDD control vector

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
drop if kids == 1 | kids == .


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
    sum `param' if year == 0 & twoplus_kids == 1 & highgrade <= 2
    scalar premean6_`param' = r(mean)
}

// ---- Write Tab6 LaTeX ----

local b6dd_totalsum_s = strtrim(string(scalar(b6dd_totalsum), "%9.3f"))
local b6ddd_totalsum_s = strtrim(string(scalar(b6ddd_totalsum), "%9.3f"))
local b6kids_totalsum_s = strtrim(string(scalar(b6kids_totalsum), "%9.3f"))
local p6dd_totalsum_s = strtrim(string(scalar(p6dd_totalsum), "%9.3f"))
local p6ddd_totalsum_s = strtrim(string(scalar(p6ddd_totalsum), "%9.3f"))
local p6kids_totalsum_s = strtrim(string(scalar(p6kids_totalsum), "%9.3f"))
local premean6_totalsum_s = strtrim(string(scalar(premean6_totalsum), "%9.3f"))
local se6dd_totalsum_s = strtrim(string(scalar(se6dd_totalsum), "%9.3f"))
local se6ddd_totalsum_s = strtrim(string(scalar(se6ddd_totalsum), "%9.3f"))
local se6kids_totalsum_s = strtrim(string(scalar(se6kids_totalsum), "%9.3f"))
file open tab6 using `outPath'Tables/Tab6.tex, write replace
file write tab6 "\begin{table}[htbp]" _n
file write tab6 "\centering" _n
file write tab6 "\caption{Table 6: Regression-Adjusted DD and DDD Estimates for Effect of EITC Expansion on Allostatic Load, Women Aged 21--40}" _n
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
    local bdd  = strtrim(string(scalar(b6dd_`param'),    "%9.3f"))
    local bddd = strtrim(string(scalar(b6ddd_`param'),   "%9.3f"))
    local bkid = strtrim(string(scalar(b6kids_`param'),  "%9.4f"))
    local sedd = strtrim(string(scalar(se6dd_`param'),   "%9.3f"))
    local seddd= strtrim(string(scalar(se6ddd_`param'),  "%9.3f"))
    local sekid= strtrim(string(scalar(se6kids_`param'),  "%9.3f"))
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
file write tab6 "\textit{Notes:} Standard errors are reported in parentheses and p-values on the test of the null that the coefficient is zero are "
file write tab6 "reported in square brackets. All standard errors allow for arbitrary form of heteroskedasticity. Other covariates in "
file write tab6 "the DD model include: complete set of dummies for age, race, marital status, and the year of survey. Other covari"
file write tab6 "ates in the DDD model include: complete set of dummies for age, race, marital status, education, plus interactions "
file write tab6 "between the education and the year effects, the number of children and the year effect, the education and number "
file write tab6 "of children effects. \\" _n
file write tab6 "\end{minipage}" _n
file write tab6 "\end{table}" _n
file close tab6
