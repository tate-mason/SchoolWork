/************************************************************
* Extension.do                                              *
* Event Study - Reg-Adjusted DiD (Eq. 1)                    *
*                                                           *
* Args: 1 = dataPath, 2 = outPath                           *
*                                                           *
* Plots delta coefficients and 95% CIs relative to 1995     *
* for four main outcomes. Requires coefplot package.        *
************************************************************/

local dataPath "`1'"
local outPath  "`2'"

use `dataPath'BRFSS_Final_Data.dta, clear

drop if kids == 0 | kids == .
drop if age > 40 | age < 21


forvalues yr = 1993/2001 {
  gen delta_`yr' = (year==`yr')*twoplus_kids
}
replace delta_1995 = 0 // normalize pre-expansion year to 0


local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year"
local delta "delta_*"

local title_working     "At Work"
local title_excel_vgood "Excellent/Very Good Health"
local title_mental_poor "Poor Mental Health"
local title_phys_poor   "Poor Physical Health"

foreach y in working excel_vgood mental_poor phys_poor {

    * ── Event study regression ──────────────────────────────
    reg `y' `delta' twoplus_kids `X' if educ <= 2, cluster(fips)
    estimates store ext_`y'

    matrix b = e(b)[1, 1..8]
    matrix V = e(V)[1..8, 1..8]

    * ── Verify index positions (uncomment first time) ───────
    * matrix list e(b)
    * delta_1993=1, delta_1994=2, delta_1996=3, ..., delta_2001=8
    * delta_1995 is zeroed out and dropped from e(b)
    * twoplus_kids=9, then covariates

    * ── HonestDiD sensitivity table ─────────────────────────
    * pre(1/2)  = delta_1993, delta_1994
    * post(3/8) = delta_1996 through delta_2001
    honestdid, b(b) vcov(V) numpre(3) mvec(0.5(0.5)2) ///
        coefplot ///
        xtitle("Mbar") ytitle("95% Robust CI") ///
        title("HonestDiD: `title_`y''")

    graph export `outPath'Graphs/HonestDiD_`y'.pdf, replace

    * ── Save sensitivity table ──────────────────────────────
    matrix honest_`y' = r(HonestDiDTable)
}

* ── Display all sensitivity tables ─────────────────────────
foreach y in working excel_vgood mental_poor phys_poor {
    di _n "=== HonestDiD results: `title_`y'' ==="
    matrix list honest_`y'
}

* ── Original event study coefplots ─────────────────────────
foreach y in working excel_vgood mental_poor phys_poor {
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
