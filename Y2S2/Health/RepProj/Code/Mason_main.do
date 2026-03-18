/************************************************************
* Author: Tate Mason - tate.mason@uga.edu                   *
* ------  University of Georgia - Health Economics II       *
*                                                           *
* Program: Mason_main.do -                                  *
* -------                                                   *
*   Main runner for replication of Evans, Garthwaite        *
*   "Giving Mom a Break". Each section is a separate        *
*   do-file called below. Set the switch to 1 to run        *
*   that section, 0 to skip.                                *
*                                                           *
* Date: 01/29/2025                                          *
* ----                                                      *
************************************************************/

/************************************************************
* (1) Environment Setup                                     *
************************************************************/

#delimit cr
clear all
set more off
set scheme s1color

local rootPath "~/Schoolwork/Y2S2/Health/RepProj/"

local codePath "`rootPath'Code/"
local outPath  "`rootPath'Output/"
local dataPath "`rootPath'Data/"

cap log close
log using `outPath'Mason_rep_log.log, replace

/************************************************************
* (2) Switches for Running Individual Sections              *
************************************************************/

// Below I define a local switch for each section. If the 
// switch is equal to 1 it will run; at 0 it is dormant.

local Tab2     = 0
local Tab3     = 0
local Tab4     = 0
local Tab5     = 0 // descriptives only: obs, sample mean, % risky
local Tab6     = 0
local Tab7     = 0
local Fig4     = 1 // parallel trends; vline at 1996; 5 subfigures
local ARC      = 0 // robustness: Footnote 12 (col1), Footnote 21 (col2-3)
local Extension = 0 
/************************************************************
* (3) Section Calls                                         *
************************************************************/

if `Tab2'      do `codePath'Tab2.do      `dataPath' `outPath'
if `Tab3'      do `codePath'Tab3.do      `dataPath' `outPath'
if `Tab4'      do `codePath'Tab4.do      `dataPath' `outPath'
if `Tab5'      do `codePath'Tab5.do      `dataPath' `outPath'
if `Tab6'      do `codePath'Tab6.do      `dataPath' `outPath'
if `Tab7'      do `codePath'Tab7.do      `dataPath' `outPath'
if `Fig4'      do `codePath'Fig4.do      `dataPath' `outPath'
if `ARC'       do `codePath'ARC.do       `dataPath' `outPath'
if `Extension' do `codePath'Extension.do `dataPath' `outPath'

log close
