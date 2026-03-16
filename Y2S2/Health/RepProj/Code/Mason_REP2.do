/************************************************************
* Author: Tate Mason - tate.mason@uga.edu                   *
* ------  University of Georgia - Health Economics II       *
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

#delimit cr
clear
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
* (2) Loading in Data and Looking Around                    *
************************************************************/

use `dataPath'BRFSS_Final_Data.dta
summ *
tabstat income* educ working

/************************************************************
* (3) Switches                                              *
************************************************************/

local Tab2 = 1
local Tab3 = 1
local Tab4 = 1
local Tab5 = 1
local Tab6 = 1
local Tab7 = 1
local Fig4 = 1
local ARC  = 1

/************************************************************
* (4) Table 2 - Sample Characteristics                      *
************************************************************/

if `Tab2' {
  drop if year < 1993 | year > 1995
  drop if age < 21 | age > 40
  drop if kids == 0 | kids == .
  drop if educ == 3
  drop if fips > 56

  gen obsnum = _n

  recode educ (1/2 = 0) (4=1), gen(college_edu)

  local tab2_vars "age working excel_vgood *_poor bad_* white_nh hispanic black_nh other income* incomemiss married div_sep_wid never_married"

  sort college_edu
  by college_edu: sum `tab2_vars' if kids == 1
  by college_edu: sum `tab2_vars' if kids > 1
}

/************************************************************
* (5) Table 3 - DiD OLS & Negative Binomial Estimates       *
************************************************************/

if `Tab3' {
  drop if kids==0 | kids == .
  drop if educ == 3
  drop if age < 21 | age > 40
  drop if fips > 56

  // Pre-Treatment Means
  sum at_work excel_vgood mental_poor phys_poor if year<1996 & kids >= 2 & educ <= 2

  // Simple OLS DiD
  reg at_work twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips)
  estimates store t3_simple_at_work

  reg excel_vgood twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips)
  estimates store t3_simple_excel_vgood

  nbreg mental_poor twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips)
  estimates store t3_simple_mental_poor

  nbreg phys_poor twoplus_kids eitc_expand dd_treatment if educ <= 2, cluster(fips)
  estimates store t3_simple_phys_poor

  // Regression Adjusted DiD
  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year"

  reg at_work dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t3_adj_at_work

  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t3_adj_excel_vgood

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t3_adj_mental_poor

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t3_adj_phys_poor

  // Export - one panel per outcome
  foreach y in at_work excel_vgood mental_poor phys_poor {
    esttab t3_simple_`y' t3_adj_`y' ///
      using `outPath'Tables/Tab3_`y'.tex, replace ///
      se label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
      keep(dd_treatment twoplus_kids eitc_expand) ///
      order(dd_treatment twoplus_kids eitc_expand) ///
      mtitles("Simple DiD" "Adjusted DiD") ///
      alignment(D{.}{.}{-1})
  }
}

/************************************************************
* (6) Table 4 - Robustness Tests                            *
************************************************************/

if `Tab4' {
  drop if kids == 0 | kids == .

  // Col 1 - Full sample, dummy controls (no state FE)
  local X "i.race4 i.educ i.age i.month i.marital i.kids i.year"

  reg at_work dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c1_at_work

  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c1_excel_vgood

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c1_mental_poor

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c1_phys_poor

  // Col 2 - State x Year FE
  local X "i.race4 i.educ i.age i.month i.marital i.kids"

  reg at_work dd_treatment fips#i.year `X' if educ <= 2, cluster(fips)
  estimates store t4_c2_at_work

  reg excel_vgood dd_treatment fips#i.year `X' if educ <= 2, cluster(fips)
  estimates store t4_c2_excel_vgood

  nbreg mental_poor dd_treatment fips#i.year `X' if educ <= 2, cluster(fips)
  estimates store t4_c2_mental_poor

  nbreg phys_poor dd_treatment fips#i.year `X' if educ <= 2, cluster(fips)
  estimates store t4_c2_phys_poor

  // Col 3 - 2+ vs 0 kids
  preserve
  drop if kids == 1
  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year"

  reg at_work dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c3_at_work

  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c3_excel_vgood

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c3_mental_poor

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c3_phys_poor
  restore

  // Col 4 - Married only
  preserve
  keep if marital == 1
  drop if kids == 0
  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year"

  reg at_work dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c4_at_work

  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c4_excel_vgood

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c4_mental_poor

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c4_phys_poor
  restore

  // Col 5 - Single only
  preserve
  keep if marital > 1
  drop if kids == 0
  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year"

  reg at_work dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c5_at_work

  reg excel_vgood dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c5_excel_vgood

  nbreg mental_poor dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c5_mental_poor

  nbreg phys_poor dd_treatment `X' if educ <= 2, cluster(fips)
  estimates store t4_c5_phys_poor
  restore

  // Col 6 - Triple Diff
  preserve
  drop if educ == 3
  drop if kids == 0 | kids == .
  gen hs_only = educ <= 2
  gen hs_expand    = hs_only*eitc_expand
  gen twokids_expand = twoplus_kids*eitc_expand
  gen hs_twokids   = hs_only*twoplus_kids
  gen treatment    = dd_treatment*hs_only

  local X "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year i.year##i.kids i.year##i.educ i.kids##i.educ"

  reg at_work treatment hs_expand twokids_expand hs_twokids `X', cluster(fips)
  estimates store t4_c6_at_work

  reg excel_vgood treatment hs_expand twokids_expand hs_twokids `X', cluster(fips)
  estimates store t4_c6_excel_vgood

  nbreg mental_poor treatment hs_expand twokids_expand hs_twokids `X', cluster(fips)
  estimates store t4_c6_mental_poor

  nbreg phys_poor treatment hs_expand twokids_expand hs_twokids `X', cluster(fips)
  estimates store t4_c6_phys_poor
  restore

  // Export - one panel per outcome
  foreach y in at_work excel_vgood mental_poor phys_poor {
    esttab t4_c1_`y' t4_c2_`y' t4_c3_`y' t4_c4_`y' t4_c5_`y' t4_c6_`y' ///
      using `outPath'Tables/Tab4_`y'.tex, replace ///
      se label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
      keep(dd_treatment treatment) ///
      order(dd_treatment treatment) ///
      mtitles("No State FE" "State×Year FE" "2+ vs 0 Kids" "Married" "Single" "Triple Diff") ///
      alignment(D{.}{.}{-1})
  }
}

/************************************************************
* (7) Table 5 - NHANES Descriptives                         *
************************************************************/

if `Tab5' {
  preserve
  use `dataPath'nhanes/nhanesallstacked.dta, clear

  drop if age < 21 | age > 40
  drop if sex == 1
  drop if race > 3 | race < 0

  gen kids = .
  replace kids = family_size-1 if marital>1 & year == 0
  replace kids = family_size-2 if marital == 1 & year == 0
  replace kids = dmdhhsiz-1 if marital > 1 & year > 0
  replace kids = dmdhhsiz-2 if marital == 1 & year > 0

  gen no_hs = highgrade <= 2
  drop if kids <= 0

  gen twoplus_kids = kids > 1
  gen eitc_expand  = year > 0
  gen dd_treat     = eitc_expand*twoplus_kids
  gen eitc_nohs    = eitc_expand*no_hs
  gen twoplus_nohs = twoplus_kids*no_hs
  gen ddd_treat    = dd_treat*no_hs

  replace crp = . if crp == 88888
  gen riskycrp = crp>=0.3
  replace riskycrp = . if crp == .
  replace riskypulse = . if pulse == .
  replace riskydiastolic = . if diastolic == .
  replace riskysystolic  = . if systolic == .
  replace riskyhdl = . if hdl == .
  replace riskyCholest = . if cholesterol == .
  replace riskyAlbumin = . if albumin == .
  replace riskyglycatedhemoglobin = . if glycatedhemoglobin == .

  gen metabsum  = riskyglycatedhemoglobin + riskyCholest + riskyhdl
  gen cardiosum = riskysystolic+riskydiastolic+riskypulse
  gen inflsum   = riskycrp + riskyAlbumin
  gen totalsum  = metabsum+cardiosum+inflsum

  gen anymetab = metabsum>0
  replace anymetab = . if riskyglycatedhemoglobin==. | riskyCholest==. | riskyhdl==.
  gen anycardio = cardiosum > 0
  replace anycardio = . if riskypulse==. | riskydiastolic==. | riskysystolic==.
  gen anyinflamation = inflsum > 0
  replace anyinflamation = . if riskyAlbumin==. | riskycrp==.

  replace crp = 0.21 if crp < 0.21

  gen total1 = totalsum>0
  replace total1 = . if totalsum == .
  gen total2 = totalsum > 1
  replace total2 = . if totalsum == .
  gen total3 = totalsum > 2
  replace total3 = . if totalsum == .

  drop if marital==. | race==. | age==. | no_hs==. | kids==.

  sum crp albumin inflsum anyinflamation if highgrade <= 2
  sum diastolic systolic pulse cardiosum anycardio if highgrade <= 2
  sum cholesterol hdl glycatedhemoglobin metabsum anymetab if highgrade <= 2
  sum totalsum total1 total2 total3 if highgrade <= 2

  save `dataPath'nhanes/nhanescleaned.dta, replace
  restore
}

/************************************************************
* (8) Table 6 - NHANES DiD Estimates                        *
************************************************************/

if `Tab6' {
  use `dataPath'nhanes/nhanescleaned.dta, clear

  // Pre-treatment means
  sum crp albumin inflsum anyinflamation if highgrade <= 2 & year == 0 & twoplus_kids == 1
  sum diastolic systolic pulse cardiosum anycardio if highgrade <= 2 & year == 0 & twoplus_kids == 1
  sum cholesterol hdl glycatedhemoglobin metabsum anymetab if highgrade <= 2 & year == 0 & twoplus_kids == 1
  sum totalsum total1 total2 total3 if highgrade <= 2 & year == 0 & twoplus_kids == 1

  local X_dd  "i.year i.age i.marital i.race"
  local X_ddd "i.year i.age i.race i.marital i.highgrade##i.year i.year##i.twoplus_kids i.highgrade##i.twoplus_kids"

  tab year if highgrade <= 2

  // Col 1 - DiD
  foreach y in total1 total2 total3 {
    reg `y' dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
    estimates store t6_c1_`y'
  }
  poisson totalsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store t6_c1_totalsum

  // Col 2 - Triple Diff
  foreach y in total1 total2 total3 {
    reg `y' ddd_treat `X_ddd', robust
    estimates store t6_c2_`y'
  }
  poisson totalsum ddd_treat `X_ddd', robust
  estimates store t6_c2_totalsum

  // Export
  foreach y in total1 total2 total3 totalsum {
    esttab t6_c1_`y' t6_c2_`y' ///
      using `outPath'Tables/Tab6_`y'.tex, replace ///
      se label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
      keep(dd_treat ddd_treat) ///
      order(dd_treat ddd_treat) ///
      mtitles("DiD" "Triple Diff") ///
      alignment(D{.}{.}{-1})
  }
}

/************************************************************
* (9) Table 7 - NHANES Biomarker Estimates                  *
************************************************************/

if `Tab7' {
  use `dataPath'nhanes/nhanescleaned.dta, clear

  local X_dd  "i.year i.age i.marital i.race"
  local X_ddd "i.year i.age i.race i.marital i.highgrade##i.year i.year##i.twoplus_kids i.highgrade##i.twoplus_kids"

  local metab_markers "riskyglycatedhemoglobin riskyCholest riskyhdl anymetab"
  local metab_tags    "glychgb cholest hdl anymetab"
  local cardio_markers "riskydiastolic riskysystolic riskypulse anycardio"
  local cardio_tags    "diastolic systolic pulse anycardio"
  local infl_markers  "riskyAlbumin riskycrp anyinflamation"
  local infl_tags     "albumin crp anyinflamation"

  // Col 1 - DiD
  local n=1
  foreach m in `metab_markers' {
    local tag : word `n' of `metab_tags'
    reg `m' dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
    estimates store t7_c1_`tag'
    local ++n
  }
  poisson metabsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store t7_c1_metabsum
  nbreg metabsum dd_treat `X_dd' if highgrade<=2, robust d(c)
  estimates store t7_c1_metabsum_nb

  local n=1
  foreach c in `cardio_markers' {
    local tag : word `n' of `cardio_tags'
    reg `c' dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
    estimates store t7_c1_`tag'
    local ++n
  }
  poisson cardiosum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store t7_c1_cardiosum
  nbreg cardiosum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust d(c)
  estimates store t7_c1_cardiosum_nb

  local n=1
  foreach i in `infl_markers' {
    local tag : word `n' of `infl_tags'
    reg `i' dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
    estimates store t7_c1_`tag'
    local ++n
  }
  poisson inflsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust
  estimates store t7_c1_inflsum
  nbreg inflsum dd_treat twoplus_kids `X_dd' if highgrade<=2, robust d(c)
  estimates store t7_c1_inflsum_nb

  // Col 2 - Triple Diff
  preserve
  keep if kids > 0

  local n=1
  foreach m in `metab_markers' {
    local m_tag : word `n' of `metab_tags'
    reg `m' ddd_treat `X_ddd', robust
    estimates store t7_c2_`tag'
    local ++n
  }
  poisson metabsum ddd_treat `X_ddd', robust
  estimates store t7_c2_metabsum
  nbreg metabsum ddd_treat `X_ddd', robust d(c)
  estimates store t7_c2_metabsum_nb

  foreach c in `cardio_markers' {
    local c_tag : word `n' of `cardio_tags'
    reg `c' ddd_treat `X_ddd', robust
    estimates store t7_c2_`tag'
    local ++n
  }
  poisson cardiosum ddd_treat `X_ddd', robust
  estimates store t7_c2_cardiosum
  nbreg cardiosum ddd_treat `X_ddd', robust d(c)
  estimates store t7_c2_cardiosum_nb

  foreach i in `infl_markers' {
    local i_tag : word `n' of `infl_tags'
    reg `i' ddd_treat `X_ddd', robust
    estimates store t7_c2_`tag'
    local ++n
  }
  poisson inflsum ddd_treat `X_ddd', robust
  estimates store t7_c2_inflsum
  nbreg inflsum ddd_treat `X_ddd', robust d(c)
  estimates store t7_c2_inflsum_nb
  restore

  // Export - Panel A: Metabolic
  esttab t7_c1_glychgb t7_c2_glychgb ///
         t7_c1_cholest t7_c2_cholest ///
         t7_c1_hdl t7_c2_hdl ///
         t7_c1_anymetab t7_c2_anymetab ///
         t7_c1_metabsum_nb t7_c2_metabsum_nb ///
    using `outPath'Tables/Tab7_metabolic.tex, replace ///
    se label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
    keep(dd_treat ddd_treat) order(dd_treat ddd_treat) ///
    mgroups("Glycated Hgb" "Cholesterol" "HDL" "Any Metab" "Count (NB)", ///
            pattern(1 0 1 0 1 0 1 0 1 0)) ///
    mtitles("DiD" "DDD" "DiD" "DDD" "DiD" "DDD" "DiD" "DDD" "DiD" "DDD") ///
    alignment(D{.}{.}{-1})

  // Export - Panel B: Cardiovascular
  esttab t7_c1_riskydiastolic t7_c2_riskydiastolic ///
         t7_c1_riskysystolic t7_c2_riskysystolic ///
         t7_c1_riskypulse t7_c2_riskypulse ///
         t7_c1_anycardio t7_c2_anycardio ///
         t7_c1_cardiosum_nb t7_c2_cardiosum_nb ///
    using `outPath'Tables/Tab7_cardiovascular.tex, replace ///
    se label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
    keep(dd_treat ddd_treat) order(dd_treat ddd_treat) ///
    mgroups("Diastolic" "Systolic" "Pulse" "Any Cardio" "Count (NB)", ///
            pattern(1 0 1 0 1 0 1 0 1 0)) ///
    mtitles("DiD" "DDD" "DiD" "DDD" "DiD" "DDD" "DiD" "DDD" "DiD" "DDD") ///
    alignment(D{.}{.}{-1})

  // Export - Panel C: Inflammation
  esttab t7_c1_riskyAlbumin t7_c2_riskyAlbumin ///
         t7_c1_riskycrp t7_c2_riskycrp ///
         t7_c1_anyinflamation t7_c2_anyinflamation ///
         t7_c1_inflsum_nb t7_c2_inflsum_nb ///
    using `outPath'Tables/Tab7_inflammation.tex, replace ///
    se label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
    keep(dd_treat ddd_treat) order(dd_treat ddd_treat) ///
    mgroups("Albumin" "CRP" "Any Inflam." "Count (NB)", ///
            pattern(1 0 1 0 1 0 1 0)) ///
    mtitles("DiD" "DDD" "DiD" "DDD" "DiD" "DDD" "DiD" "DDD") ///
    alignment(D{.}{.}{-1})
}

/************************************************************
* (10) Figure 4 - Parallel Trends                           *
************************************************************/

if `Fig4' {
  use `dataPath'BRFSS_Final_Data.dta, clear

  drop if kids == 0 | kids == .
  drop if educ == 3
  drop if fips > 56
  gen low_educ = educ <= 2
  gen treat = twoplus_kids*low_educ

  // Panel A - LFP
  preserve
  keep if year >= 1993 & year <= 2001
  collapse (mean) inlf, by(year treat)
  tsset treat year

  local y0_min = 0.65
  local y0_max = 0.73
  local y1_min = 0.75
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
      xtitle("Year") title("Panel A: % in labor force")
  graph export `outPath'Graphs/Fig4_LaborForce.pdf, replace
  restore

  // Panel B - Excellent/Very Good Health
  preserve
  keep if year >= 1993 & year <= 2001
  collapse (mean) excel_vgood, by(year treat)
  tsset treat year

  local y0_min = 0.48
  local y0_max = 0.60
  local y1_min = 0.48
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
      xtitle("Year") title("Panel B: % in Excellent/Very Good Health")
  graph export `outPath'Graphs/Fig4_ExcellentHealth.pdf, replace
  restore

  // Panel C - Mental Health
  preserve
  keep if year >= 1993 & year <= 2001
  collapse (mean) mental_poor, by(year treat)
  tsset treat year

  twoway ///
    (tsline mental_poor if treat==1, lcolor(black) lwidth(medium)) ///
    (tsline mental_poor if treat==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
    , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
      xscale(range(1993 2001)) xlabel(1993(1)2001) ///
      yscale(range(4.0 6.0)) ylabel(4(0.25)6) ///
      yscale(range(3.75 5.75) axis(2)) ylabel(3.75(0.25)5.75, axis(2)) ///
      xline(1996, lcolor(red) lpattern(dash)) ///
      ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
      xtitle("Year") title("Panel C: % in Poor Mental Health")
  graph export `outPath'Graphs/Fig4_MentalHealth.pdf, replace
  restore

  // Panel D - Physical Health
  preserve
  keep if year >= 1993 & year <= 2001
  collapse (mean) phys_poor, by(year treat)
  tsset treat year

  twoway ///
    (tsline phys_poor if treat==1, lcolor(black) lwidth(medium)) ///
    (tsline phys_poor if treat==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
    , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
      xscale(range(1993 2001)) xlabel(1993(1)2001) ///
      yscale(range(2.0 3.50)) ylabel(2.00(0.25)3.50) ///
      yscale(range(2.25 3.75) axis(2)) ylabel(2.25(0.25)3.75, axis(2)) ///
      xline(1996, lcolor(red) lpattern(dash)) ///
      ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
      xtitle("Year") title("Panel D: % in Poor Physical Health")
  graph export `outPath'Graphs/Fig4_PhysHealth.pdf, replace
  restore

  // Panel E - At Work
  preserve
  keep if year >= 1993 & year <= 2001
  collapse (mean) at_work, by(year treat)
  tsset treat year

  local y0_min = 0.60
  local y0_max = 0.70
  local y1_min = 0.70
  local y1_max = 0.80

  twoway ///
    (tsline at_work if treat==1, lcolor(black) lwidth(medium)) ///
    (tsline at_work if treat==0, lcolor(gs8) lwidth(medium) yaxis(2)) ///
    , legend(label(1 "Moms with 2+ children") label(2 "Moms with 1 child")) ///
      xscale(range(1993 2001)) xlabel(1993(1)2001) ///
      yscale(range(`y0_min' `y0_max')) ylabel(`y0_min'(0.02)`y0_max') ///
      yscale(range(`y1_min' `y1_max') axis(2)) ylabel(`y1_min'(0.02)`y1_max', axis(2)) ///
      xline(1996, lcolor(red) lpattern(dash)) ///
      ytitle("Moms with 2+ children") ytitle("Moms with 1 child", axis(2)) ///
      xtitle("Year") title("Panel E: % at work")
  graph export `outPath'Graphs/Fig4_AtWork.pdf, replace
  restore
}

/************************************************************
* (11) Additional Robustness Checks                         *
************************************************************/

if `ARC' {
  use `dataPath'BRFSS_Final_Data.dta, clear

  drop if educ == 3
  drop if age < 21 | age > 40
  drop if fips > 56

  local X  "i.race4 i.educ i.age i.month i.marital i.kids i.fips i.year"
  local Y_1 "at_work excel_vgood"
  local Y_2 "mental_poor phys_poor"

  // Footnote 12 - Treatment in 1995
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

  // Footnote 21 - Exclude 2000+
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

  // Footnote 21 - Exclude 1999+
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

  // Export - one panel per outcome
  foreach y in at_work excel_vgood mental_poor phys_poor {
    esttab footnote12_`y' footnote21_2000_`y' footnote21_1999_`y' ///
      using `outPath'Tables/ARC_`y'.tex, replace ///
      se label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
      keep(dd_treat_95 dd_treatment) ///
      order(dd_treat_95 dd_treatment) ///
      mtitles("1995 Treatment" "Excl. 2000+" "Excl. 1999+") ///
      alignment(D{.}{.}{-1})
  }
}
