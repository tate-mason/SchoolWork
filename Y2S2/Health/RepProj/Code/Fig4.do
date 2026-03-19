/************************************************************
* Fig4.do                                                   *
* Figure 4 - Parallel Trends Plots                         *
*                                                           *
* Args: 1 = dataPath, 2 = outPath                          *
*                                                           *
* Plots mean outcomes by year for 2+ child (treated) and   *
* 1-child (control) low-education mothers. Vertical line   *
* at 1996. Five panels: LFP, exc/vgood health, mental      *
* health, physical health, at work.                         *
************************************************************/

local dataPath "`1'"
local outPath  "`2'"

use `dataPath'BRFSS_Final_Data.dta, clear // Load BRFSS data

// Panel A - LFP %

drop if kids == 0 | kids == .
drop if educ == 3
drop if fips > 56
gen low_educ = educ <= 2
gen treat = twoplus_kids*low_educ
keep if low_educ == 1          
keep if year >= 1993 & year <= 2001   // move this outside the Panel A preserve too

preserve
collapse (mean) inlf, by(year treat) // Recover average lfp by year and treatment status
tsset treat year // use year, given treatment, as time

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
graph export `outPath'Graphs/Fig_LaborForce.pdf, replace // saving graph
restore

preserve
// Panel B - Excellent/Very Good Health %
collapse (mean) excel_vgood, by(year treat) // Recover average E/VG health by year
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
graph export `outPath'Graphs/Fig_ExcellentHealth.pdf, replace // saving graph
restore

// Panel C - Mental Health
preserve
collapse (mean) mental_poor, by(year treat) // Get average rate of poor mental health
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
graph export `outPath'Graphs/Fig_MentalHealth.pdf, replace // save greaph
restore

// Panel D - Physical Health
preserve
collapse (mean) phys_poor, by(year treat) // Get average poor physical health by year
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
graph export `outPath'Graphs/Fig_PhysHealth.pdf, replace // save graph
restore

preserve
collapse (mean) at_work, by(year treat) // get mean at_work (variable used in regression)
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
graph export `outPath'Graphs/Fig_LF.pdf, replace // save graph
restore
