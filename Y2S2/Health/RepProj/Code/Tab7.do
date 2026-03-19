/************************************************************
* Tab7.do                                                   *
* Table 7 - NHANES DD/DDD: Individual Biomarkers           *
*                                                           *
* Args: 1 = dataPath, 2 = outPath                          *
*                                                           *
* Loads nhanescleaned.dta (produced by Tab5.do) and the    *
* stacked NHANES file. Estimates DD (Col 1), DDD (Col 2),  *
* and 2+ vs 0 kids (Col 3) for each individual biomarker   *
* across metabolic, cardiovascular, and inflammation        *
* panels. Writes Tab7.tex.                                  *
************************************************************/

local dataPath "`1'"
local outPath  "`2'"


/************************************************************
* Table 7 estimates individual biomarker effects of the     *
* EITC expansion. Three specifications are reported:        *
*   Col 1 (DD):  2+ vs 1 child in nhanescleaned.dta         *
*   Col 2 (DDD): triple-diff adding education interaction   *
*   Col 3:       2+ vs 0 children using stacked NHANES data *
************************************************************/

use `dataPath'nhanes/nhanescleaned.dta, clear // load NHANES data (cleaned in tab5 section)

// Set locals for vectors of controls
local X_dd  "i.year i.age i.marital i.race"                                              // DD control vector
local X_ddd "i.year i.age i.race i.marital i.highgrade##i.year i.year##i.twoplus_kids i.highgrade##i.twoplus_kids" // DDD control vector

// ---- Column 1: DD (2+ kids vs 1 kid, low-educ sample) ----

// Panel A - Metabolic biomarkers
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

// Panel B - Cardiovascular biomarkers
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

// Panel C - Inflammation biomarkers
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

// ---- Column 2: DDD (triple-diff adding education interaction) ----

preserve
drop if kids == 0 // subset to only mothers

// Panel A - Metabolic biomarkers
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

// Panel B - Cardiovascular biomarkers
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

// Panel C - Inflammation biomarkers
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

// ---- Column 3: DD on stacked data, 2+ kids vs 0 kids ----

preserve
use `dataPath'nhanes/nhanesallstacked.dta, clear

// Sample restrictions: women aged 21-40, black/white/hispanic only
drop if age < 21 | age > 40
drop if sex == 1
drop if race > 3 | race < 0

// Approximate children in household (family size minus adults)
gen kids = .
replace kids = family_size-1 if marital > 1 & year == 0 // NHANES III: single-adult household
replace kids = family_size-2 if marital == 1 & year == 0 // NHANES III: two-adult household
replace kids = dmdhhsiz-1    if marital > 1 & year > 0   // later waves: single-adult
replace kids = dmdhhsiz-2    if marital == 1 & year > 0  // later waves: two-adult

// Education indicator (no high school or less)
gen no_hs = highgrade <= 2

// Drop 1-child mothers so the comparison is 2+ vs 0
drop if kids == 1 | kids == .

// Treatment variables
gen twoplus_kids = kids > 1       // treated group: 2+ children
gen eitc_expand  = year > 0       // post-expansion indicator

gen dd_treat     = eitc_expand * twoplus_kids // DiD: post x 2+ kids
gen eitc_nohs    = eitc_expand * no_hs        // time x low-educ interaction
gen twoplus_nohs = twoplus_kids * no_hs       // 2+ kids x low-educ interaction
gen ddd_treat    = dd_treat * no_hs           // triple-diff treatment

// Biomarker cleaning (identical to Tab5/Tab6 stacked-data block)
replace crp = . if crp == 88888 // missing value code in NHANES
gen riskycrp                   = crp >= 0.3
replace riskycrp               = . if crp == .
replace riskypulse             = . if pulse == .
replace riskydiastolic         = . if diastolic == .
replace riskysystolic          = . if systolic == .
replace riskyhdl               = . if hdl == .
replace riskyCholest           = . if cholesterol == .
replace riskyAlbumin           = . if albumin == .
replace riskyglycatedhemoglobin = . if glycatedhemoglobin == .

// Composite risk indices
gen metabsum  = riskyglycatedhemoglobin + riskyCholest + riskyhdl
gen cardiosum = riskysystolic + riskydiastolic + riskypulse
gen inflsum   = riskycrp + riskyAlbumin
gen totalsum  = metabsum + cardiosum + inflsum

gen anymetab     = metabsum > 0
replace anymetab = . if riskyglycatedhemoglobin == . | riskyCholest == . | riskyhdl == .
gen anycardio     = cardiosum > 0
replace anycardio = . if riskypulse == . | riskydiastolic == . | riskysystolic == .
gen anyinflamation     = inflsum > 0
replace anyinflamation = . if riskyAlbumin == . | riskycrp == .

replace crp = 0.21 if crp < 0.21 // bottom-code CRP to match cleaned file

// Panel A - Metabolic biomarkers
reg riskyglycatedhemoglobin dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_hba1c
reg riskyCholest dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_cholest
reg riskyhdl dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_hdl
reg anymetab dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_anymetab
poisson metabsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_metabsum_pois

// Panel B - Cardiovascular biomarkers
reg riskydiastolic dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_diastolic
reg riskysystolic dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_systolic
reg riskypulse dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_pulse
reg anycardio dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_anycardio
poisson cardiosum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_cardiosum_pois

// Panel C - Inflammation biomarkers
reg riskyAlbumin dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_albumin
reg riskycrp dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_crp
reg anyinflamation dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_anyinfl
poisson inflsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
estimates store tab7kids_inflsum_pois
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

// ---- Extract scalars: Col 3 (2+ vs 0 kids) ----
// OLS outcomes use ttail; Poisson uses normal z

foreach m in hba1c cholest hdl anymetab {
    estimates restore tab7kids_`m'
    scalar b7kids_`m'  = _b[dd_treat]
    scalar se7kids_`m' = _se[dd_treat]
    scalar p7kids_`m'  = 2*ttail(e(df_r), abs(_b[dd_treat]/_se[dd_treat]))
}
foreach suf in metabsum_pois {
    estimates restore tab7kids_`suf'
    scalar b7kids_`suf'  = _b[dd_treat]
    scalar se7kids_`suf' = _se[dd_treat]
    scalar p7kids_`suf'  = 2*normal(-abs(_b[dd_treat]/_se[dd_treat]))
}
foreach c in diastolic systolic pulse anycardio {
    estimates restore tab7kids_`c'
    scalar b7kids_`c'  = _b[dd_treat]
    scalar se7kids_`c' = _se[dd_treat]
    scalar p7kids_`c'  = 2*ttail(e(df_r), abs(_b[dd_treat]/_se[dd_treat]))
}
foreach suf in cardiosum_pois {
    estimates restore tab7kids_`suf'
    scalar b7kids_`suf'  = _b[dd_treat]
    scalar se7kids_`suf' = _se[dd_treat]
    scalar p7kids_`suf'  = 2*normal(-abs(_b[dd_treat]/_se[dd_treat]))
}
foreach i in albumin crp anyinfl {
    estimates restore tab7kids_`i'
    scalar b7kids_`i'  = _b[dd_treat]
    scalar se7kids_`i' = _se[dd_treat]
    scalar p7kids_`i'  = 2*ttail(e(df_r), abs(_b[dd_treat]/_se[dd_treat]))
}
foreach suf in inflsum_pois {
    estimates restore tab7kids_`suf'
    scalar b7kids_`suf'  = _b[dd_treat]
    scalar se7kids_`suf' = _se[dd_treat]
    scalar p7kids_`suf'  = 2*normal(-abs(_b[dd_treat]/_se[dd_treat]))
}

// Pre-expansion means
foreach v in riskyglycatedhemoglobin riskyCholest riskyhdl anymetab ///
             riskydiastolic riskysystolic riskypulse anycardio ///
             riskyAlbumin riskycrp anyinflamation {
    quietly sum `v' if year == 0 & twoplus_kids == 1 & highgrade <= 2
    scalar pm7_`v' = r(mean)
}

// ---- Write Tab7 LaTeX ----
// Scalar-to-local conversion: dd, ddd, and kids (Col3) for all biomarkers

// Col 1 (DD) coefficients
local b7dd_hba1c_s           = strtrim(string(scalar(b7dd_hba1c),           "%9.3f"))
local b7dd_cholest_s         = strtrim(string(scalar(b7dd_cholest),         "%9.3f"))
local b7dd_hdl_s             = strtrim(string(scalar(b7dd_hdl),             "%9.3f"))
local b7dd_anymetab_s        = strtrim(string(scalar(b7dd_anymetab),        "%9.3f"))
local b7dd_metabsum_pois_s   = strtrim(string(scalar(b7dd_metabsum_pois),   "%9.3f"))
local b7dd_diastolic_s       = strtrim(string(scalar(b7dd_diastolic),       "%9.3f"))
local b7dd_systolic_s        = strtrim(string(scalar(b7dd_systolic),        "%9.3f"))
local b7dd_pulse_s           = strtrim(string(scalar(b7dd_pulse),           "%9.3f"))
local b7dd_anycardio_s       = strtrim(string(scalar(b7dd_anycardio),       "%9.3f"))
local b7dd_cardiosum_pois_s  = strtrim(string(scalar(b7dd_cardiosum_pois),  "%9.3f"))
local b7dd_albumin_s         = strtrim(string(scalar(b7dd_albumin),         "%9.3f"))
local b7dd_crp_s             = strtrim(string(scalar(b7dd_crp),             "%9.3f"))
local b7dd_anyinfl_s         = strtrim(string(scalar(b7dd_anyinfl),         "%9.3f"))
local b7dd_inflsum_pois_s    = strtrim(string(scalar(b7dd_inflsum_pois),    "%9.3f"))

// Col 1 (DD) standard errors
local se7dd_hba1c_s          = strtrim(string(scalar(se7dd_hba1c),          "%9.3f"))
local se7dd_cholest_s        = strtrim(string(scalar(se7dd_cholest),        "%9.3f"))
local se7dd_hdl_s            = strtrim(string(scalar(se7dd_hdl),            "%9.3f"))
local se7dd_anymetab_s       = strtrim(string(scalar(se7dd_anymetab),       "%9.3f"))
local se7dd_metabsum_pois_s  = strtrim(string(scalar(se7dd_metabsum_pois),  "%9.3f"))
local se7dd_diastolic_s      = strtrim(string(scalar(se7dd_diastolic),      "%9.3f"))
local se7dd_systolic_s       = strtrim(string(scalar(se7dd_systolic),       "%9.3f"))
local se7dd_pulse_s          = strtrim(string(scalar(se7dd_pulse),          "%9.3f"))
local se7dd_anycardio_s      = strtrim(string(scalar(se7dd_anycardio),      "%9.3f"))
local se7dd_cardiosum_pois_s = strtrim(string(scalar(se7dd_cardiosum_pois), "%9.3f"))
local se7dd_albumin_s        = strtrim(string(scalar(se7dd_albumin),        "%9.3f"))
local se7dd_crp_s            = strtrim(string(scalar(se7dd_crp),            "%9.3f"))
local se7dd_anyinfl_s        = strtrim(string(scalar(se7dd_anyinfl),        "%9.3f"))
local se7dd_inflsum_pois_s   = strtrim(string(scalar(se7dd_inflsum_pois),   "%9.3f"))

// Col 1 (DD) p-values
local p7dd_hba1c_s           = strtrim(string(scalar(p7dd_hba1c),           "%9.3f"))
local p7dd_cholest_s         = strtrim(string(scalar(p7dd_cholest),         "%9.3f"))
local p7dd_hdl_s             = strtrim(string(scalar(p7dd_hdl),             "%9.3f"))
local p7dd_anymetab_s        = strtrim(string(scalar(p7dd_anymetab),        "%9.3f"))
local p7dd_metabsum_pois_s   = strtrim(string(scalar(p7dd_metabsum_pois),   "%9.3f"))
local p7dd_diastolic_s       = strtrim(string(scalar(p7dd_diastolic),       "%9.3f"))
local p7dd_systolic_s        = strtrim(string(scalar(p7dd_systolic),        "%9.3f"))
local p7dd_pulse_s           = strtrim(string(scalar(p7dd_pulse),           "%9.3f"))
local p7dd_anycardio_s       = strtrim(string(scalar(p7dd_anycardio),       "%9.3f"))
local p7dd_cardiosum_pois_s  = strtrim(string(scalar(p7dd_cardiosum_pois),  "%9.3f"))
local p7dd_albumin_s         = strtrim(string(scalar(p7dd_albumin),         "%9.3f"))
local p7dd_crp_s             = strtrim(string(scalar(p7dd_crp),             "%9.3f"))
local p7dd_anyinfl_s         = strtrim(string(scalar(p7dd_anyinfl),         "%9.3f"))
local p7dd_inflsum_pois_s    = strtrim(string(scalar(p7dd_inflsum_pois),    "%9.3f"))

// Col 2 (DDD) coefficients
local b7ddd_hba1c_s          = strtrim(string(scalar(b7ddd_hba1c),          "%9.3f"))
local b7ddd_cholest_s        = strtrim(string(scalar(b7ddd_cholest),        "%9.3f"))
local b7ddd_hdl_s            = strtrim(string(scalar(b7ddd_hdl),            "%9.3f"))
local b7ddd_anymetab_s       = strtrim(string(scalar(b7ddd_anymetab),       "%9.3f"))
local b7ddd_metabsum_pois_s  = strtrim(string(scalar(b7ddd_metabsum_pois),  "%9.3f"))
local b7ddd_diastolic_s      = strtrim(string(scalar(b7ddd_diastolic),      "%9.3f"))
local b7ddd_systolic_s       = strtrim(string(scalar(b7ddd_systolic),       "%9.3f"))
local b7ddd_pulse_s          = strtrim(string(scalar(b7ddd_pulse),          "%9.3f"))
local b7ddd_anycardio_s      = strtrim(string(scalar(b7ddd_anycardio),      "%9.3f"))
local b7ddd_cardiosum_pois_s = strtrim(string(scalar(b7ddd_cardiosum_pois), "%9.3f"))
local b7ddd_albumin_s        = strtrim(string(scalar(b7ddd_albumin),        "%9.3f"))
local b7ddd_crp_s            = strtrim(string(scalar(b7ddd_crp),            "%9.3f"))
local b7ddd_anyinfl_s        = strtrim(string(scalar(b7ddd_anyinfl),        "%9.3f"))
local b7ddd_inflsum_pois_s   = strtrim(string(scalar(b7ddd_inflsum_pois),   "%9.3f"))

// Col 2 (DDD) standard errors
local se7ddd_hba1c_s          = strtrim(string(scalar(se7ddd_hba1c),          "%9.3f"))
local se7ddd_cholest_s        = strtrim(string(scalar(se7ddd_cholest),        "%9.3f"))
local se7ddd_hdl_s            = strtrim(string(scalar(se7ddd_hdl),            "%9.3f"))
local se7ddd_anymetab_s       = strtrim(string(scalar(se7ddd_anymetab),       "%9.3f"))
local se7ddd_metabsum_pois_s  = strtrim(string(scalar(se7ddd_metabsum_pois),  "%9.3f"))
local se7ddd_diastolic_s      = strtrim(string(scalar(se7ddd_diastolic),      "%9.3f"))
local se7ddd_systolic_s       = strtrim(string(scalar(se7ddd_systolic),       "%9.3f"))
local se7ddd_pulse_s          = strtrim(string(scalar(se7ddd_pulse),          "%9.3f"))
local se7ddd_anycardio_s      = strtrim(string(scalar(se7ddd_anycardio),      "%9.3f"))
local se7ddd_cardiosum_pois_s = strtrim(string(scalar(se7ddd_cardiosum_pois), "%9.3f"))
local se7ddd_albumin_s        = strtrim(string(scalar(se7ddd_albumin),        "%9.3f"))
local se7ddd_crp_s            = strtrim(string(scalar(se7ddd_crp),            "%9.3f"))
local se7ddd_anyinfl_s        = strtrim(string(scalar(se7ddd_anyinfl),        "%9.3f"))
local se7ddd_inflsum_pois_s   = strtrim(string(scalar(se7ddd_inflsum_pois),   "%9.3f"))

// Col 2 (DDD) p-values
local p7ddd_hba1c_s          = strtrim(string(scalar(p7ddd_hba1c),          "%9.3f"))
local p7ddd_cholest_s        = strtrim(string(scalar(p7ddd_cholest),        "%9.3f"))
local p7ddd_hdl_s            = strtrim(string(scalar(p7ddd_hdl),            "%9.3f"))
local p7ddd_anymetab_s       = strtrim(string(scalar(p7ddd_anymetab),       "%9.3f"))
local p7ddd_metabsum_pois_s  = strtrim(string(scalar(p7ddd_metabsum_pois),  "%9.3f"))
local p7ddd_diastolic_s      = strtrim(string(scalar(p7ddd_diastolic),      "%9.3f"))
local p7ddd_systolic_s       = strtrim(string(scalar(p7ddd_systolic),       "%9.3f"))
local p7ddd_pulse_s          = strtrim(string(scalar(p7ddd_pulse),          "%9.3f"))
local p7ddd_anycardio_s      = strtrim(string(scalar(p7ddd_anycardio),      "%9.3f"))
local p7ddd_cardiosum_pois_s = strtrim(string(scalar(p7ddd_cardiosum_pois), "%9.3f"))
local p7ddd_albumin_s        = strtrim(string(scalar(p7ddd_albumin),        "%9.3f"))
local p7ddd_crp_s            = strtrim(string(scalar(p7ddd_crp),            "%9.3f"))
local p7ddd_anyinfl_s        = strtrim(string(scalar(p7ddd_anyinfl),        "%9.3f"))
local p7ddd_inflsum_pois_s   = strtrim(string(scalar(p7ddd_inflsum_pois),   "%9.3f"))

// Col 3 (2+ vs 0 kids) coefficients
local b7kids_hba1c_s           = strtrim(string(scalar(b7kids_hba1c),           "%9.3f"))
local b7kids_cholest_s         = strtrim(string(scalar(b7kids_cholest),         "%9.3f"))
local b7kids_hdl_s             = strtrim(string(scalar(b7kids_hdl),             "%9.3f"))
local b7kids_anymetab_s        = strtrim(string(scalar(b7kids_anymetab),        "%9.3f"))
local b7kids_metabsum_pois_s   = strtrim(string(scalar(b7kids_metabsum_pois),   "%9.3f"))
local b7kids_diastolic_s       = strtrim(string(scalar(b7kids_diastolic),       "%9.3f"))
local b7kids_systolic_s        = strtrim(string(scalar(b7kids_systolic),        "%9.3f"))
local b7kids_pulse_s           = strtrim(string(scalar(b7kids_pulse),           "%9.3f"))
local b7kids_anycardio_s       = strtrim(string(scalar(b7kids_anycardio),       "%9.3f"))
local b7kids_cardiosum_pois_s  = strtrim(string(scalar(b7kids_cardiosum_pois),  "%9.3f"))
local b7kids_albumin_s         = strtrim(string(scalar(b7kids_albumin),         "%9.3f"))
local b7kids_crp_s             = strtrim(string(scalar(b7kids_crp),             "%9.3f"))
local b7kids_anyinfl_s         = strtrim(string(scalar(b7kids_anyinfl),         "%9.3f"))
local b7kids_inflsum_pois_s    = strtrim(string(scalar(b7kids_inflsum_pois),    "%9.3f"))

// Col 3 (2+ vs 0 kids) standard errors
local se7kids_hba1c_s          = strtrim(string(scalar(se7kids_hba1c),          "%9.3f"))
local se7kids_cholest_s        = strtrim(string(scalar(se7kids_cholest),        "%9.3f"))
local se7kids_hdl_s            = strtrim(string(scalar(se7kids_hdl),            "%9.3f"))
local se7kids_anymetab_s       = strtrim(string(scalar(se7kids_anymetab),       "%9.3f"))
local se7kids_metabsum_pois_s  = strtrim(string(scalar(se7kids_metabsum_pois),  "%9.3f"))
local se7kids_diastolic_s      = strtrim(string(scalar(se7kids_diastolic),      "%9.3f"))
local se7kids_systolic_s       = strtrim(string(scalar(se7kids_systolic),       "%9.3f"))
local se7kids_pulse_s          = strtrim(string(scalar(se7kids_pulse),          "%9.3f"))
local se7kids_anycardio_s      = strtrim(string(scalar(se7kids_anycardio),      "%9.3f"))
local se7kids_cardiosum_pois_s = strtrim(string(scalar(se7kids_cardiosum_pois), "%9.3f"))
local se7kids_albumin_s        = strtrim(string(scalar(se7kids_albumin),        "%9.3f"))
local se7kids_crp_s            = strtrim(string(scalar(se7kids_crp),            "%9.3f"))
local se7kids_anyinfl_s        = strtrim(string(scalar(se7kids_anyinfl),        "%9.3f"))
local se7kids_inflsum_pois_s   = strtrim(string(scalar(se7kids_inflsum_pois),   "%9.3f"))

// Col 3 (2+ vs 0 kids) p-values
local p7kids_hba1c_s           = strtrim(string(scalar(p7kids_hba1c),           "%9.3f"))
local p7kids_cholest_s         = strtrim(string(scalar(p7kids_cholest),         "%9.3f"))
local p7kids_hdl_s             = strtrim(string(scalar(p7kids_hdl),             "%9.3f"))
local p7kids_anymetab_s        = strtrim(string(scalar(p7kids_anymetab),        "%9.3f"))
local p7kids_metabsum_pois_s   = strtrim(string(scalar(p7kids_metabsum_pois),   "%9.3f"))
local p7kids_diastolic_s       = strtrim(string(scalar(p7kids_diastolic),       "%9.3f"))
local p7kids_systolic_s        = strtrim(string(scalar(p7kids_systolic),        "%9.3f"))
local p7kids_pulse_s           = strtrim(string(scalar(p7kids_pulse),           "%9.3f"))
local p7kids_anycardio_s       = strtrim(string(scalar(p7kids_anycardio),       "%9.3f"))
local p7kids_cardiosum_pois_s  = strtrim(string(scalar(p7kids_cardiosum_pois),  "%9.3f"))
local p7kids_albumin_s         = strtrim(string(scalar(p7kids_albumin),         "%9.3f"))
local p7kids_crp_s             = strtrim(string(scalar(p7kids_crp),             "%9.3f"))
local p7kids_anyinfl_s         = strtrim(string(scalar(p7kids_anyinfl),         "%9.3f"))
local p7kids_inflsum_pois_s    = strtrim(string(scalar(p7kids_inflsum_pois),    "%9.3f"))

// Pre-expansion means (treatment group: 2+ kids, low educ, pre-expansion wave)
local pm7_riskyglycatedhemoglobin_s = strtrim(string(scalar(pm7_riskyglycatedhemoglobin), "%9.3f"))
local pm7_riskyCholest_s            = strtrim(string(scalar(pm7_riskyCholest),            "%9.3f"))
local pm7_riskyhdl_s                = strtrim(string(scalar(pm7_riskyhdl),                "%9.3f"))
local pm7_anymetab_s                = strtrim(string(scalar(pm7_anymetab),                "%9.3f"))
local pm7_riskydiastolic_s          = strtrim(string(scalar(pm7_riskydiastolic),          "%9.3f"))
local pm7_riskysystolic_s           = strtrim(string(scalar(pm7_riskysystolic),           "%9.3f"))
local pm7_riskypulse_s              = strtrim(string(scalar(pm7_riskypulse),              "%9.3f"))
local pm7_anycardio_s               = strtrim(string(scalar(pm7_anycardio),               "%9.3f"))
local pm7_riskyAlbumin_s            = strtrim(string(scalar(pm7_riskyAlbumin),            "%9.3f"))
local pm7_riskycrp_s                = strtrim(string(scalar(pm7_riskycrp),                "%9.3f"))
local pm7_anyinflamation_s          = strtrim(string(scalar(pm7_anyinflamation),          "%9.3f"))

// ---- Write Tab7 LaTeX ----

file open tab7 using `outPath'Tables/Tab7.tex, write replace
file write tab7 "\begin{table}[htbp]" _n
file write tab7 "\centering" _n
file write tab7 "\caption{Table 7: Regression-Adjusted DD and DDD Estimates for Individual Biomarkers, Women Aged 21--40}" _n
file write tab7 "\small" _n
file write tab7 "\begin{tabular}{p{5.5cm}cccc}" _n
file write tab7 "\toprule" _n
file write tab7 " & Preexpansion mean & & & Two Children vs. \\" _n
file write tab7 "Outcome & (treatment group) & DD & DDD & No Children \\" _n
file write tab7 "\midrule" _n

// ---- Panel A: Metabolic biomarkers ----
file write tab7 "\multicolumn{5}{l}{\textit{Panel A. Metabolic biomarkers}} \\" _n
file write tab7 "\addlinespace" _n

// HbA1c
file write tab7 "Risky glycated hemoglobin"
file write tab7 " & `pm7_riskyglycatedhemoglobin_s\'"
file write tab7 " & `b7dd_hba1c_s\'"
file write tab7 " & `b7ddd_hba1c_s\'"
file write tab7 " & `b7kids_hba1c_s\' \\" _n
file write tab7 " & & (`se7dd_hba1c_s\') & (`se7ddd_hba1c_s\') & (`se7kids_hba1c_s\') \\" _n
file write tab7 " & & [`p7dd_hba1c_s\'] & [`p7ddd_hba1c_s\'] & [`p7kids_hba1c_s\'] \\" _n
file write tab7 "\addlinespace" _n

// Total cholesterol
file write tab7 "Risky total cholesterol"
file write tab7 " & `pm7_riskyCholest_s\'"
file write tab7 " & `b7dd_cholest_s\'"
file write tab7 " & `b7ddd_cholest_s\'"
file write tab7 " & `b7kids_cholest_s\' \\" _n
file write tab7 " & & (`se7dd_cholest_s\') & (`se7ddd_cholest_s\') & (`se7kids_cholest_s\') \\" _n
file write tab7 " & & [`p7dd_cholest_s\'] & [`p7ddd_cholest_s\'] & [`p7kids_cholest_s\'] \\" _n
file write tab7 "\addlinespace" _n

// HDL
file write tab7 "Risky HDL"
file write tab7 " & `pm7_riskyhdl_s\'"
file write tab7 " & `b7dd_hdl_s\'"
file write tab7 " & `b7ddd_hdl_s\'"
file write tab7 " & `b7kids_hdl_s\' \\" _n
file write tab7 " & & (`se7dd_hdl_s\') & (`se7ddd_hdl_s\') & (`se7kids_hdl_s\') \\" _n
file write tab7 " & & [`p7dd_hdl_s\'] & [`p7ddd_hdl_s\'] & [`p7kids_hdl_s\'] \\" _n
file write tab7 "\addlinespace" _n

// Any metabolic
file write tab7 "Any risky metabolic condition"
file write tab7 " & `pm7_anymetab_s\'"
file write tab7 " & `b7dd_anymetab_s\'"
file write tab7 " & `b7ddd_anymetab_s\'"
file write tab7 " & `b7kids_anymetab_s\' \\" _n
file write tab7 " & & (`se7dd_anymetab_s\') & (`se7ddd_anymetab_s\') & (`se7kids_anymetab_s\') \\" _n
file write tab7 " & & [`p7dd_anymetab_s\'] & [`p7ddd_anymetab_s\'] & [`p7kids_anymetab_s\'] \\" _n
file write tab7 "\addlinespace" _n

// Poisson count
file write tab7 "Poisson: number of risky metabolic conditions"
file write tab7 " & "
file write tab7 " & `b7dd_metabsum_pois_s\'"
file write tab7 " & `b7ddd_metabsum_pois_s\'"
file write tab7 " & `b7kids_metabsum_pois_s\' \\" _n
file write tab7 " & & (`se7dd_metabsum_pois_s\') & (`se7ddd_metabsum_pois_s\') & (`se7kids_metabsum_pois_s\') \\" _n
file write tab7 " & & [`p7dd_metabsum_pois_s\'] & [`p7ddd_metabsum_pois_s\'] & [`p7kids_metabsum_pois_s\'] \\" _n

// ---- Panel B: Cardiovascular biomarkers ----
file write tab7 "\midrule" _n
file write tab7 "\multicolumn{5}{l}{\textit{Panel B. Cardiovascular biomarkers}} \\" _n
file write tab7 "\addlinespace" _n

// Diastolic
file write tab7 "Risky diastolic blood pressure"
file write tab7 " & `pm7_riskydiastolic_s\'"
file write tab7 " & `b7dd_diastolic_s\'"
file write tab7 " & `b7ddd_diastolic_s\'"
file write tab7 " & `b7kids_diastolic_s\' \\" _n
file write tab7 " & & (`se7dd_diastolic_s\') & (`se7ddd_diastolic_s\') & (`se7kids_diastolic_s\') \\" _n
file write tab7 " & & [`p7dd_diastolic_s\'] & [`p7ddd_diastolic_s\'] & [`p7kids_diastolic_s\'] \\" _n
file write tab7 "\addlinespace" _n

// Systolic
file write tab7 "Risky systolic blood pressure"
file write tab7 " & `pm7_riskysystolic_s\'"
file write tab7 " & `b7dd_systolic_s\'"
file write tab7 " & `b7ddd_systolic_s\'"
file write tab7 " & `b7kids_systolic_s\' \\" _n
file write tab7 " & & (`se7dd_systolic_s\') & (`se7ddd_systolic_s\') & (`se7kids_systolic_s\') \\" _n
file write tab7 " & & [`p7dd_systolic_s\'] & [`p7ddd_systolic_s\'] & [`p7kids_systolic_s\'] \\" _n
file write tab7 "\addlinespace" _n

// Pulse
file write tab7 "Risky pulse"
file write tab7 " & `pm7_riskypulse_s\'"
file write tab7 " & `b7dd_pulse_s\'"
file write tab7 " & `b7ddd_pulse_s\'"
file write tab7 " & `b7kids_pulse_s\' \\" _n
file write tab7 " & & (`se7dd_pulse_s\') & (`se7ddd_pulse_s\') & (`se7kids_pulse_s\') \\" _n
file write tab7 " & & [`p7dd_pulse_s\'] & [`p7ddd_pulse_s\'] & [`p7kids_pulse_s\'] \\" _n
file write tab7 "\addlinespace" _n

// Any cardiovascular
file write tab7 "Any risky cardiovascular condition"
file write tab7 " & `pm7_anycardio_s\'"
file write tab7 " & `b7dd_anycardio_s\'"
file write tab7 " & `b7ddd_anycardio_s\'"
file write tab7 " & `b7kids_anycardio_s\' \\" _n
file write tab7 " & & (`se7dd_anycardio_s\') & (`se7ddd_anycardio_s\') & (`se7kids_anycardio_s\') \\" _n
file write tab7 " & & [`p7dd_anycardio_s\'] & [`p7ddd_anycardio_s\'] & [`p7kids_anycardio_s\'] \\" _n
file write tab7 "\addlinespace" _n

// Poisson count
file write tab7 "Poisson: number of risky cardiovascular conditions"
file write tab7 " & "
file write tab7 " & `b7dd_cardiosum_pois_s\'"
file write tab7 " & `b7ddd_cardiosum_pois_s\'"
file write tab7 " & `b7kids_cardiosum_pois_s\' \\" _n
file write tab7 " & & (`se7dd_cardiosum_pois_s\') & (`se7ddd_cardiosum_pois_s\') & (`se7kids_cardiosum_pois_s\') \\" _n
file write tab7 " & & [`p7dd_cardiosum_pois_s\'] & [`p7ddd_cardiosum_pois_s\'] & [`p7kids_cardiosum_pois_s\'] \\" _n

// ---- Panel C: Inflammation biomarkers ----
file write tab7 "\midrule" _n
file write tab7 "\multicolumn{5}{l}{\textit{Panel C. Inflammation biomarkers}} \\" _n
file write tab7 "\addlinespace" _n

// Albumin
file write tab7 "Risky albumin"
file write tab7 " & `pm7_riskyAlbumin_s\'"
file write tab7 " & `b7dd_albumin_s\'"
file write tab7 " & `b7ddd_albumin_s\'"
file write tab7 " & `b7kids_albumin_s\' \\" _n
file write tab7 " & & (`se7dd_albumin_s\') & (`se7ddd_albumin_s\') & (`se7kids_albumin_s\') \\" _n
file write tab7 " & & [`p7dd_albumin_s\'] & [`p7ddd_albumin_s\'] & [`p7kids_albumin_s\'] \\" _n
file write tab7 "\addlinespace" _n

// CRP
file write tab7 "Risky C-reactive protein"
file write tab7 " & `pm7_riskycrp_s\'"
file write tab7 " & `b7dd_crp_s\'"
file write tab7 " & `b7ddd_crp_s\'"
file write tab7 " & `b7kids_crp_s\' \\" _n
file write tab7 " & & (`se7dd_crp_s\') & (`se7ddd_crp_s\') & (`se7kids_crp_s\') \\" _n
file write tab7 " & & [`p7dd_crp_s\'] & [`p7ddd_crp_s\'] & [`p7kids_crp_s\'] \\" _n
file write tab7 "\addlinespace" _n

// Any inflammatory
file write tab7 "Any risky inflammatory condition"
file write tab7 " & `pm7_anyinflamation_s\'"
file write tab7 " & `b7dd_anyinfl_s\'"
file write tab7 " & `b7ddd_anyinfl_s\'"
file write tab7 " & `b7kids_anyinfl_s\' \\" _n
file write tab7 " & & (`se7dd_anyinfl_s\') & (`se7ddd_anyinfl_s\') & (`se7kids_anyinfl_s\') \\" _n
file write tab7 " & & [`p7dd_anyinfl_s\'] & [`p7ddd_anyinfl_s\'] & [`p7kids_anyinfl_s\'] \\" _n
file write tab7 "\addlinespace" _n

// Poisson count
file write tab7 "Poisson: number of risky inflammatory conditions"
file write tab7 " & "
file write tab7 " & `b7dd_inflsum_pois_s\'"
file write tab7 " & `b7ddd_inflsum_pois_s\'"
file write tab7 " & `b7kids_inflsum_pois_s\' \\" _n
file write tab7 " & & (`se7dd_inflsum_pois_s\') & (`se7ddd_inflsum_pois_s\') & (`se7kids_inflsum_pois_s\') \\" _n
file write tab7 " & & [`p7dd_inflsum_pois_s\'] & [`p7ddd_inflsum_pois_s\'] & [`p7kids_inflsum_pois_s\'] \\" _n

file write tab7 "\bottomrule" _n
file write tab7 "\end{tabular}" _n
file write tab7 "\begin{minipage}{\linewidth}" _n
file write tab7 "\smallskip\footnotesize" _n
file write tab7 "\textit{Notes:} Standard errors are reported in parentheses and p-values on the test of the null that the coefficient is zero are "
file write tab7 "reported in square brackets. All standard errors allow for arbitrary form of heteroskedasticity. Other covariates in "
file write tab7 "the DD model include: complete set of dummies for age, race, marital status, and the year of survey. Other covari"
file write tab7 "ates in the DDD model include: complete set of dummies for age, race, marital status, education, plus interactions "
file write tab7 "between the education and the year effects, the number of children and the year effect, the education and number "
file write tab7 "of children effects. \\" _n
file write tab7 "\end{minipage}" _n
file write tab7 "\end{table}" _n
file close tab7
