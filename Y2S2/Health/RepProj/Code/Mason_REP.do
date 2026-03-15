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

local Tab2 = 1
local Tab3 = 1
local Tab4 = 1
local Tab5 = 1 // only observations, sample mean, and % with risky levels
local Tab6 = 1
local Tab7 = 1 
local Fig4 = 1 // insert vline at t = 1996, include additional subfigure for "at work" rather than "in labor force" -- figure 4 has 5 subfigures
local ARC  = 1 // Additional Robustness Checks - Footnote 12 (col1), Footnote 21 - diff years excluded (col2), Footnote 21 - years specified (col3)

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
  
  gen obsnum = _n //generating an observation number for each observation

  recode educ (1/2 = 0) (4=1), gen(college_edu) //reclassifying education such that college_edu = 1 if the woman has a degree and 0 if high school attainment was their highest level of education
 
  local tab2_vars "age working excel_vgood *_poor bad_* white_nh hispanic black_nh other income* incomemiss married div_sep_wid never_married" //creating a local variable to contain all relevant table variables

  sort college_edu //sort by college status so that i can then summarize by that classification
  by college_edu: sum `tab2_vars' if kids == 1 //summarize for women with only one child
  by college_edu: sum `tab2_vars' if kids > 1 //summarize for women with two or more children

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
  drop if kids==0 | kids == .
  drop if educ == 3
  drop if age < 21 | age > 40
  drop if fips > 56

  // Pre-Treatment Means

  sum working excel_vgood mental_poor phys_poor if year<1996 & twoplus_kids==1


  // Simple OLS DiD - working & Excellent/Very Good Health:

  reg working twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on LFPR
  estimates store working_simple
  
  reg excel_vgood twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on Good Health
  estimates store excel_simple

  nbreg mental_poor twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on Mental Health
  estimates store mental_simple

  nbreg phys_poor twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on Physical health
  estimates store phys_simple

  // Regression Adjusted DiD - Adding Controls

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg working dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health
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
  // Column 1 - DiD Results Full Sample With Dummy Controls

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg working dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health

  // Column 2 - State x Year FE added

  local X "i.race4 i.educ i.age i.month i.marital i.kids" // Control vector of dummies

  reg working dd_treatment fips#i.year `X' if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood dd_treatment fips#i.year `X' if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poor dd_treatment fips#i.year `X' if educ <= 2, cluster(fips) // Effect on Mental Health

  nbreg phys_poor dd_treatment fips#i.year `X' if educ <= 2, cluster(fips) // Effect on Physical health

  // Column 3 - Differencing by Amount of Children (2 vs 0)

  preserve
  drop if kids == 1

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg working dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health
  restore

  // Column 4 - Differentiating by Married
  preserve

  keep if marital == 1
  drop if kids == 0

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg working dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health
  restore

  // Column 5 - Differentiating by Single

  preserve

  keep if marital > 1
  drop if kids == 0

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg working dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health

  restore

  // Column 6 - Triple Diff
  preserve

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  drop if educ == 3 // drop some college
  gen hs_only = educ <= 2 // dummy for max of HS education 

  gen hs_expand = hs_only*eitc_expand // low educ x time interaction
  gen twokids_expand = twoplus_kids*eitc_expand // time x 2+ kids interaction
  gen hs_twokids = hs_only*twoplus_kids // low educ x 2+ kids interaction

  gen treatment = hs_only*eitc_expand*twoplus_kids

  reg working treatment `X', cluster(fips) // Effect on LFPR
  reg excel_vgood treatment `X', cluster(fips) // Effect on Good Health
  nbreg mental_poor treatment `X', cluster(fips) // Effect on Mental Health
  nbreg phys_poor treatment `X', cluster(fips) // Effect on Physical health

  restore
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
  reg total2 dd_treat twoplus_kids `X_dd' if highgrade<=2, robust // Effect on 2+ Risk Factors
  reg total3 dd_treat twoplus_kids `X_dd' if highgrade<=2, robust // Effect on 3+ Risk Factors

  poisson totalsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust // Poisson regression for count of risk factors

  // Column 2 - Triple Diff
  local X_ddd "i.year i.age i.race i.marital i.highgrade##i.year i.year##i.twoplus_kids i.highgrade##i.twoplus_kids" // control vector of dummies
  reg total1 ddd_treat `X_ddd', robust // Effect on 1+ Risk Factors
  reg total2 ddd_treat `X_ddd', robust // Effect on 2+ Risk Factors
  reg total3 ddd_treat `X_ddd', robust // Effect on 3+ Risk Factors

  poisson totalsum ddd_treat `X_ddd', robust // Poisson regression for count of risk factors

  /*
  // Column 3 - 2 kids vs 0 kids
  // First, drop 1 kid observations
  drop if kids == 1
  foreach param in total1 total2 total3 {
      reg `param' dd_treat `X_dd' if highgrade<=2 & twoplus_kids==1, robust
      estimates store `param'_kids
      reg `param' dd_treat `X_dd' if highgrade<=2 & kids==0, robust
      estimates store `param'_nokids
  }

  * Poisson
  poisson totalsum dd_treat `X_dd' if highgrade<=2 & twoplus_kids==1, robust
  estimates store totalsum_kids
  poisson totalsum dd_treat `X_dd' if highgrade<=2 & kids==0, robust
  estimates store totalsum_nokids

  * Compute and display differences
  foreach param in total1 total2 total3 totalsum {
      estimates restore `param'_kids
      scalar b_kids = _b[dd_treat]
      estimates restore `param'_nokids
      scalar b_nokids = _b[dd_treat]
      display "`param' DiD difference (kids - nokids): " b_kids - b_nokids
  }
  */
}

if `Tab7' {
  use `dataPath'nhanes/nhanescleaned.dta, clear

  local X_dd "i.year i.age i.marital i.race" // control vector of dummies
  local X_ddd "i.year i.age i.race i.marital i.highgrade##i.year i.year##i.twoplus_kids i.highgrade##i.twoplus_kids" // control vector of dummies

  // panel A. Metabolic Biomarkers
  local metab_markers "riskyglycatedhemoglobin riskyCholest riskyhdl anymetab" // list of dependent variables

  // Loop through markers and run DiD
  foreach m in `metab_markers' {
      reg `m' dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  }
  poisson metabsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust // Poisson regression for count of metabolic risk factors
  nbreg metabsum dd_treat `X_dd' if highgrade<=2, robust d(c) // Negative binomial for count of metabolic risk factors

  local cardio_markers "riskydiastolic riskysystolic riskypulse anycardio"

  foreach c in `cardio_markers' {
      reg `c' dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  }
  poisson cardiosum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust // Poisson regression for count of cardiovascular risk factors
  nbreg cardiosum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust d(c) // Negative binomial for count of cardiovascular risk factors

  local infl_markers "riskyAlbumin riskycrp anyinflamation"

  foreach i in `infl_markers' {
      reg `i' dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  }
  poisson inflsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust // Poisson regression for count of inflammation risk factors
  nbreg inflsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust d(c) // Negative binomial for count of inflammation risk factors

  // Col. 2 - Triple Diff
  preserve
  keep if kids > 0
  foreach m in `metab_markers' {
      reg `m' ddd_treat `X_ddd', robust
  }
  poisson metabsum ddd_treat `X_ddd', robust // Poisson regression for count of metabolic risk factors
  nbreg metabsum ddd_treat `X_ddd', robust d(c) // Negative binomial for count of metabolic risk factors

  foreach c in `cardio_markers' {
      reg `c' ddd_treat `X_ddd', robust
  }
  poisson cardiosum ddd_treat `X_ddd', robust // Poisson regression for count of cardiovascular risk factors
  nbreg cardiosum ddd_treat `X_ddd', robust d(c) // Negative binomial for count of cardiovascular risk factors 

  foreach i in `infl_markers' {
      reg `i' ddd_treat `X_ddd', robust
  }
  poisson inflsum ddd_treat `X_ddd', robust // Poisson regression for count of inflammation risk factors
  nbreg inflsum ddd_treat `X_ddd', robust d(c) // Negative binomial for count of inflammation risk factors
  restore
}

if `Fig4' {
  use `dataPath'BRFSS_Final_Data.dta, clear

  // Panel A - LFP %
  
  drop if kids == 0 | kids == .
  drop if educ == 3
  drop if fips > 56

  preserve
  keep if year >= 1993 & year <= 2001
  collapse (mean) inlf, by(year twoplus_kids)
  tsset twoplus_kids year

  local y0_min = 0.65 //matching 2+ yaxis
  local y0_max = 0.73
  local y1_min = 0.75 //matching 1 child yaxis
  local y1_max = 0.83


  twoway ///
      (tsline inlf if twoplus_kids==1, lcolor(black) lwidth(medium)) ///
      (tsline inlf if twoplus_kids==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
      , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
        xscale(range(1993 2001)) xlabel(1993(1)2001) ///
        yscale(range(`y0_min' `y0_max')) ylabel(`y0_min'(0.02)`y0_max') ///
        yscale(range(`y1_min' `y1_max') axis(2)) ylabel(`y1_min'(0.02)`y1_max', axis(2)) ///
        xline(1996, lcolor(red) lpattern(dash)) ///
        ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
        xtitle("Year") title("Panel A: % in labor force") ///
        name("Fig4_LaborForce", replace)
  restore

  preserve
  // Panel B - Excellent/Very Good Health %
  collapse (mean) excel_vgood, by(year twoplus_kids)
  tsset twoplus_kids year

  local y0_min = 0.48 //matching 2+ yaxis
  local y0_max = 0.60
  local y1_min = 0.48 //matching 1 child yaxis
  local y1_max = 0.60

  twoway ///
      (tsline excel_vgood if twoplus_kids==1, lcolor(black) lwidth(medium)) ///
      (tsline excel_vgood if twoplus_kids==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
      , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
        xscale(range(1993 2001)) xlabel(1993(1)2001) ///
        yscale(range(`y0_min' `y0_max')) ylabel(`y0_min'(0.02)`y0_max') ///
        yscale(range(`y1_min' `y1_max') axis(2)) ylabel(`y1_min'(0.02)`y1_max', axis(2)) ///
        xline(1996, lcolor(red) lpattern(dash)) ///
        ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
        xtitle("Year") title("Panel B: % in Excellent/Very Good Health") ///
        name("Fig4_ExcellentHealth", replace)
  restore

  // Panel C - Mental Health
  preserve
  collapse (mean) mental_poor, by(year twoplus_kids)
  tsset twoplus_kids year

  twoway ///
      (tsline mental_poor if twoplus_kids==1, lcolor(black) lwidth(medium)) ///
      (tsline mental_poor if twoplus_kids==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
      , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
        xscale(range(1993 2001)) xlabel(1993(1)2001) ///
        yscale(range(4.0,6.0)) ylabel(4(0.25)6) ///
        yscale(range(3.75,5.75) axis(2)) ylabel(3.75(0.25)5.75, axis(2)) ///
        xline(1996, lcolor(red) lpattern(dash)) ///
        ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
        xtitle("Year") title("Panel C: % in Poor Mental Health") ///
        name("Fig4_MentalHealth", replace)
  restore

  // Panel D - Physical Health
  preserve
  collapse (mean) phys_poor, by(year twoplus_kids)
  tsset twoplus_kids year


  twoway ///
      (tsline phys_poor if twoplus_kids==1, lcolor(black) lwidth(medium)) ///
      (tsline phys_poor if twoplus_kids==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
      , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
        xscale(range(1993 2001)) xlabel(1993(1)2001) ///
        yscale(range(2.0,3.50)) ylabel(2.00(0.25)3.50) ///
        yscale(range(2.25,3.75) axis(2)) ylabel(2.25(0.25)3.75, axis(2)) ///
        xline(1996, lcolor(red) lpattern(dash)) ///
        ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
        xtitle("Year") title("Panel D: % in Poor Physical Health") ///
        name("Fig4_PhysicalHealth", replace)
  restore

  preserve
  collapse (mean) working, by(year twoplus_kids)
  tsset twoplus_kids year
  local y0_min = 0.60 //matching 2+ yaxis
  local y0_max = 0.70
  local y1_min = 0.70 //matching 1 child yaxis
  local y1_max = 0.80
  twoway ///
      (tsline working if twoplus_kids==1, lcolor(black) lwidth(medium)) ///
      (tsline working if twoplus_kids==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
      , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
        xscale(range(1993 2001)) xlabel(1993(1)2001) ///
        xline(1996, lcolor(red) lpattern(dash)) ///
        ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
        xtitle("Year") title("Panel E: % at work") ///
        name("Fig4_Working", replace)
  restore
}

if `ARC' {
  use `dataPath'BRFSS_Final_Data.dta, clear

  drop if kids==0 | kids == .
  drop if educ == 3
  drop if age < 21 | age > 40
  drop if fips > 56

  // Additional Robustness Checks - Footnote 12 (col1), Footnote 21 - diff years excluded (col2), Footnote 21 - years specified (col3)

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  // Footnote 12 - Treatment in 1995 (rebates from 94 distributed)
  gen dd_treat_95 = (year == 1995)*twoplus_kids
  reg working dd_treat_95 twoplus_kids `X' if educ <= 2, cluster(fips) // Effect on LFPR
  reg excel_vgood dd_treat_95 twoplus_kids `X' if educ <= 2, cluster(fips) // Effect on Good Health
  nbreg mental_poor dd_treat_95 twoplus_kids `X' if educ <= 2, cluster(fips) // Effect on Mental Health
  nbreg phys_poor dd_treat_95 twoplus_kids `X' if educ <= 2, cluster(fips) // Effect on Physical health

  // Footnote 21 - Child Tax Credit - Exclude yearrs where CTC was in existence (1998-2001)
  preserve
  drop if year >= 1998
  reg working dd_treatment twoplus_kids eitc_expand `X' if educ <= 2, cluster(fips) // Effect on LFPR
  reg excel_vgood dd_treatment twoplus_kids eitc_expand `X' if educ <= 2, cluster(fips) // Effect on Good Health
  nbreg mental_poor dd_treatment twoplus_kids eitc_expand `X' if educ <= 2, cluster(fips) // Effect on Mental Health
  nbreg phys_poor dd_treatment twoplus_kids eitc_expand `X' if educ <= 2, cluster(fips) // Effect on Physical health
  restore
}
