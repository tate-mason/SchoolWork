/************************************************************
* Extension.do                                              *
* Event Study - Reg-Adjusted DiD (Eq. 1)                  *
*                                                           *
* Args: 1 = dataPath, 2 = outPath                          *
*                                                           *
* Plots delta coefficients and 95% CIs relative to 1995    *
* for four main outcomes. Requires coefplot package.        *
************************************************************/

local dataPath "`1'"
local outPath  "`2'"

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
