/************************************************************
* Author: Tate Mason - tate.mason@uga.edu                   *
* ------  University of Georgia - Health Economics II       *                                           *
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

local rootPath "/Schoolwork/Y2S2/Health/RepProj/"

local codePath "`rootPath'Code"
local outPath "`rootPath'Output"
local dataPath "`rootPath'Data"

cap log close

log using `outputPath'Mason_rep_log.txt, replace

/************************************************************
* (2) Loading in Data and Looking Around                    *
************************************************************/
