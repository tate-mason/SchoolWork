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

local Tab2 = 0
local Tab3 = 0
local Tab4 = 1
local Tab5 = 0 // only observations, sample mean, and % with risky levels
local Tab6 = 0
local Tab7 = 0 
local Fig4 = 0 // insert vline at t = 1996, include additional subfigure for "at work" rather than "in labor force" -- figure 4 has 5 subfigures
local ARC  = 0 // Additional Robustness Checks - Footnote 12 (col1), Footnote 21 - diff years excluded (col2), Footnote 21 - years specified (col3)

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


  recode educ (1/2 = 0) (4=1), gen(college_edu) //reclassifying education such that college_edu = 1 if the woman has a degree and 0 if high school attainment was their highest level of education

  // Pre-Treatment Means

  sum inlf excel_vgood mental_poor phys_poor if year<1996 & twoplus_kids==1


  // Simple OLS DiD - inLF & Excellent/Very Good Health:

  reg inlf twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poor twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on Mental Health

  nbreg phys_poor twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips) // Effect on Physical health

  // Regression Adjusted DiD - Adding Controls

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg inlf dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poord d_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health

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

  reg inlf dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health

  // Column 2 - State x Year FE added

  local X "i.race4 i.educ i.age i.month i.marital i.kids" // Control vector of dummies

  reg inlf dd_treatment fips#i.year `X' if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood dd_treatment fips#i.year `X' if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poor dd_treatment fips#i.year `X' if educ <= 2, cluster(fips) // Effect on Mental Health

  nbreg phys_poor dd_treatment fips#i.year `X' if educ <= 2, cluster(fips) // Effect on Physical health

  // Column 3 - Differencing by Amount of Children (2 vs 0)

  preserve
  drop if kids == 1

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg inlf dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health
  restore

  // Column 4 - Differentiating by Married
  preserve

  keep if marital == 1
  drop if kids == 0

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg inlf dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health
  restore

  // Column 5 - Differentiating by Single

  preserve

  keep if marital > 1
  drop if kids == 0

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year" // Control vector of dummies

  reg inlf dd_treatment `X' if educ <= 2, cluster(fips) // Effect on LFPR
  
  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Good Health

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Mental Health

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips) // Effect on Physical health

  restore
}
