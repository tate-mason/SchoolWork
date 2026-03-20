/************************************************************
* ARC.do                                                    *
* Additional Robustness Checks                              *
*                                                           *
* Args: 1 = dataPath, 2 = outPath                           *
*                                                           *
* Footnote 12 (Col 1): tests whether 1995 treatment drives  *
* results. Footnote 21 (Cols 2-3): excludes years where     *
* the Child Tax Credit was in existence. Writes ARC.tex.    *
************************************************************/

local dataPath "`1'"
local outPath  "`2'"

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

// Footnote 21 - Child Tax Credit - Exclude years where CTC was in existence (1998-2001)

// Matching Numbers - Drop final 2 years
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

// As described - Drop 3 years
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

local arc_b1_at_s = strtrim(string(scalar(arc_b1_at), "%9.3f"))
local arc_b1_ex_s = strtrim(string(scalar(arc_b1_ex), "%9.3f"))
local arc_b1_me_s = strtrim(string(scalar(arc_b1_me), "%9.3f"))
local arc_b1_ph_s = strtrim(string(scalar(arc_b1_ph), "%9.3f"))
local arc_b2_at_s = strtrim(string(scalar(arc_b2_at), "%9.3f"))
local arc_b2_ex_s = strtrim(string(scalar(arc_b2_ex), "%9.3f"))
local arc_b2_me_s = strtrim(string(scalar(arc_b2_me), "%9.3f"))
local arc_b2_ph_s = strtrim(string(scalar(arc_b2_ph), "%9.3f"))
local arc_b3_at_s = strtrim(string(scalar(arc_b3_at), "%9.3f"))
local arc_b3_ex_s = strtrim(string(scalar(arc_b3_ex), "%9.3f"))
local arc_b3_me_s = strtrim(string(scalar(arc_b3_me), "%9.3f"))
local arc_b3_ph_s = strtrim(string(scalar(arc_b3_ph), "%9.3f"))
local arc_p1_at_s = strtrim(string(scalar(arc_p1_at), "%9.3f"))
local arc_p1_ex_s = strtrim(string(scalar(arc_p1_ex), "%9.3f"))
local arc_p1_me_s = strtrim(string(scalar(arc_p1_me), "%9.3f"))
local arc_p1_ph_s = strtrim(string(scalar(arc_p1_ph), "%9.3f"))
local arc_p2_at_s = strtrim(string(scalar(arc_p2_at), "%9.3f"))
local arc_p2_ex_s = strtrim(string(scalar(arc_p2_ex), "%9.3f"))
local arc_p2_me_s = strtrim(string(scalar(arc_p2_me), "%9.3f"))
local arc_p2_ph_s = strtrim(string(scalar(arc_p2_ph), "%9.3f"))
local arc_p3_at_s = strtrim(string(scalar(arc_p3_at), "%9.3f"))
local arc_p3_ex_s = strtrim(string(scalar(arc_p3_ex), "%9.3f"))
local arc_p3_me_s = strtrim(string(scalar(arc_p3_me), "%9.3f"))
local arc_p3_ph_s = strtrim(string(scalar(arc_p3_ph), "%9.3f"))
local arc_se1_at_s = strtrim(string(scalar(arc_se1_at), "%9.3f"))
local arc_se1_ex_s = strtrim(string(scalar(arc_se1_ex), "%9.3f"))
local arc_se1_me_s = strtrim(string(scalar(arc_se1_me), "%9.3f"))
local arc_se1_ph_s = strtrim(string(scalar(arc_se1_ph), "%9.3f"))
local arc_se2_at_s = strtrim(string(scalar(arc_se2_at), "%9.3f"))
local arc_se2_ex_s = strtrim(string(scalar(arc_se2_ex), "%9.3f"))
local arc_se2_me_s = strtrim(string(scalar(arc_se2_me), "%9.3f"))
local arc_se2_ph_s = strtrim(string(scalar(arc_se2_ph), "%9.3f"))
local arc_se3_at_s = strtrim(string(scalar(arc_se3_at), "%9.3f"))
local arc_se3_ex_s = strtrim(string(scalar(arc_se3_ex), "%9.3f"))
local arc_se3_me_s = strtrim(string(scalar(arc_se3_me), "%9.3f"))
local arc_se3_ph_s = strtrim(string(scalar(arc_se3_ph), "%9.3f"))
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
