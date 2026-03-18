/************************************************************
* Tab5.do                                                   *
* Table 5 - NHANES Biomarker Descriptives                  *
*                                                           *
* Args: 1 = dataPath, 2 = outPath                          *
*                                                           *
* Loads the stacked NHANES data, constructs all biomarker   *
* risk indicators, writes Tab5.tex with obs/mean/% risky,   *
* and saves nhanescleaned.dta for use by Tab6 and Tab7.     *
************************************************************/

local dataPath "`1'"
local outPath  "`2'"

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

// Keep only mothers
drop if kids <= 0

// Treatment variables
gen twoplus_kids = kids > 1     // dummy for 2+ kids
gen eitc_expand  = year > 0     // post-expansion indicator
gen dd_treat     = eitc_expand * twoplus_kids  // DiD treatment
gen eitc_nohs    = eitc_expand * no_hs   // time x low-educ interaction
gen twoplus_nohs = twoplus_kids * no_hs  // 2+ kids x low-educ interaction
gen ddd_treat    = dd_treat * no_hs      // triple-diff treatment

// Biomarker cleaning (as done in replication package)
replace crp = . if crp == 88888 // missing value code for CRP

gen riskycrp                    = crp >= 0.3
replace riskycrp                = . if crp == .
replace riskypulse              = . if pulse == .
replace riskydiastolic          = . if diastolic == .
replace riskysystolic           = . if systolic == .
replace riskyhdl                = . if hdl == .
replace riskyCholest            = . if cholesterol == .
replace riskyAlbumin            = . if albumin == .
replace riskyglycatedhemoglobin = . if glycatedhemoglobin == .

// Composite risk indices
gen metabsum  = riskyglycatedhemoglobin + riskyCholest + riskyhdl
gen cardiosum = riskysystolic + riskydiastolic + riskypulse
gen inflsum   = riskycrp + riskyAlbumin
gen totalsum  = metabsum + cardiosum + inflsum

gen anymetab = metabsum > 0
replace anymetab = . if riskyglycatedhemoglobin == . | riskyCholest == . | riskyhdl == .
gen anycardio = cardiosum > 0
replace anycardio = . if riskypulse == . | riskydiastolic == . | riskysystolic == .
gen anyinflamation = inflsum > 0
replace anyinflamation = . if riskyAlbumin == . | riskycrp == .

replace crp = 0.21 if crp < 0.21 // bottom-code CRP to match across waves

gen total1 = totalsum > 0
replace total1 = . if totalsum == .
gen total2 = totalsum > 1
replace total2 = . if totalsum == .
gen total3 = totalsum > 2
replace total3 = . if totalsum == .

// Drop missings before saving cleaned file and computing descriptives
drop if marital == . | race == . | age == . | no_hs == . | kids == .

// Spot-check summaries
sum crp albumin inflsum anyinflamation if highgrad <= 2
sum diastolic systolic pulse cardiosum anycardio if highgrade <= 2
sum cholesterol hdl glycatedhemoglobin metabsum anymetab if highgrade <= 2
sum totalsum total1 total2 total3 if highgrade <= 2

// Save cleaned file for Tab6 and Tab7
save `dataPath'nhanes/nhanescleaned.dta, replace

// ---- Write Tab5 LaTeX ----

cap mkdir `outPath'Tables
file open tab5 using `outPath'Tables/Tab5.tex, write replace
file write tab5 "\begin{table}[htbp]" _n
file write tab5 "\centering" _n
file write tab5 "\caption{Table 5: Biomarkers for Mothers Aged 21--40 with a High School Education or Less, NHANES}" _n
file write tab5 "\begin{tabular}{lcccc}" _n
file write tab5 "\toprule" _n
file write tab5 "Biomarker & Obs & Mean & Risky level & \% Risky \\" _n
file write tab5 "\midrule" _n
file write tab5 "\multicolumn{5}{l}{\textit{Measures of inflammation}} \\" _n
file write tab5 "\addlinespace" _n

// CRP
sum crp if highgrade <= 2
local obs = strtrim(string(r(N),    "%9.0fc"))
local mn  = strtrim(string(r(mean), "%9.3f"))
sum riskycrp if highgrade <= 2
local pct = strtrim(string(r(mean), "%9.3f"))
file write tab5 "C-reactive protein (mg/Dl) & `obs' & `mn' & \$\geq\$ 0.3 mg/Dl & `pct' \\" _n

// Albumin
sum albumin if highgrade <= 2
local obs = strtrim(string(r(N),    "%9.0fc"))
local mn  = strtrim(string(r(mean), "%9.3f"))
sum riskyAlbumin if highgrade <= 2
local pct = strtrim(string(r(mean), "%9.3f"))
file write tab5 "Albumin (g/Dl) & `obs' & `mn' & \$<\$ 3.8 g/Dl & `pct' \\" _n

// Inflammation aggregate
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

// Diastolic
sum diastolic if highgrade <= 2
local obs = strtrim(string(r(N),    "%9.0fc"))
local mn  = strtrim(string(r(mean), "%9.3f"))
sum riskydiastolic if highgrade <= 2
local pct = strtrim(string(r(mean), "%9.3f"))
file write tab5 "Diastolic blood pressure (mmHg) & `obs' & `mn' & \$\geq\$ 140 mmHg & `pct' \\" _n

// Systolic
sum systolic if highgrade <= 2
local obs = strtrim(string(r(N),    "%9.0fc"))
local mn  = strtrim(string(r(mean), "%9.3f"))
sum riskysystolic if highgrade <= 2
local pct = strtrim(string(r(mean), "%9.3f"))
file write tab5 "Systolic blood pressure (mmHg) & `obs' & `mn' & \$\geq\$ 90 mmHg & `pct' \\" _n

// Pulse
sum pulse if highgrade <= 2
local obs = strtrim(string(r(N),    "%9.0fc"))
local mn  = strtrim(string(r(mean), "%9.3f"))
sum riskypulse if highgrade <= 2
local pct = strtrim(string(r(mean), "%9.3f"))
file write tab5 "Resting pulse (beats/min) & `obs' & `mn' & \$\geq\$ 90 BPM & `pct' \\" _n

// Cardiovascular aggregate
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

// Cholesterol
sum cholesterol if highgrade <= 2
local obs = strtrim(string(r(N),    "%9.0fc"))
local mn  = strtrim(string(r(mean), "%9.3f"))
sum riskyCholest if highgrade <= 2
local pct = strtrim(string(r(mean), "%9.3f"))
file write tab5 "Total cholesterol (mg/Dl) & `obs' & `mn' & \$\geq\$ 240 mg/Dl & `pct' \\" _n

// HDL
sum hdl if highgrade <= 2
local obs = strtrim(string(r(N),    "%9.0fc"))
local mn  = strtrim(string(r(mean), "%9.3f"))
sum riskyhdl if highgrade <= 2
local pct = strtrim(string(r(mean), "%9.3f"))
file write tab5 "HDL (mg/Dl) & `obs' & `mn' & \$<\$ 40 mg/Dl & `pct' \\" _n

// HbA1c
sum glycatedhemoglobin if highgrade <= 2
local obs = strtrim(string(r(N),    "%9.0fc"))
local mn  = strtrim(string(r(mean), "%9.3f"))
sum riskyglycatedhemoglobin if highgrade <= 2
local pct = strtrim(string(r(mean), "%9.3f"))
file write tab5 "Glycated hemoglobin (\%) & `obs' & `mn' & \$\geq\$ 6.4\% & `pct' \\" _n

// Metabolic aggregate
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
