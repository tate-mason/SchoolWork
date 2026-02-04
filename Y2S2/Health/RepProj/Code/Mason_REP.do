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

local Tab2 = 1
local Tab3 = 0
local Tab4 = 0
local Tab5 = 0 // only observations, sample mean, and % with risky levels
local Tab6 = 0
local Tab7 = 0 
local Fig4 = 0 // insert vline at t = 1996, include additional subfigure for "at work" rather than "in labor force" -- figure 4 has 5 subfigures
local ARC  = 0 // Additional Robustness Checks - Footnote 12 (col1), Footnote 21 - diff years excluded (col2), Footnote 21 - years specified (col3)

/************************************************************
* (4) Table 2 - Sample Characteristics                      *
************************************************************/

/************************************************************
* First, call the local which is switched "on". Then, I will*
* generate the sample statistics after subsetting the data  *
* to mothers aged 21-40 in the years 1993-1996 using the    *
* BRFSS dataset.                                            *
************************************************************/

if `Tab2' {
  drop if year < 1993 | year > 1996
  drop if age < 21 | age > 40
  drop if kids == 0
  drop if educ == 3
  drop if fips > 56
  gen obsnum = _n //generating an observation number for each observation

  recode educ (1/2 = 0) (4=1), gen(college_edu)

  local races "white_nh black_nh hispanic other"  // COME BACK TO THIS IT IS BROKEN
  foreach r of local races {
      by obsnum, sort: egen perc_`r' = pc(`r')
    }

  sort college_edu
  by college_edu: sum mean(age) perc_* working inlf excel_vgood mental_poor phys_poor if kids == 1
  by college_edu: sum inlf excel_vgood mental_poor phys_poor if kids > 1

  }



