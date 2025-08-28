cd "C:\Users\es44276\Dropbox\Teaching\Ph.D Health Course\Stata_Sim"


clear all
*Get the number of raw applications
set obs 20000

*Simulate out different variables that are needed
gen Health_i=runiform()
gen epsilon_Hosp_i=runiform()
gen nu_i=rnormal()

*Generate the hospitalization variable
** Important that Hosp_i is correlated with Health_i; when they are the omitted variable is an issue
gen Hosp_i=(.5*epsilon_Hosp_i-Health_i>0)

** When uncorrelated, the omitted variable is not an issue
*gen Hosp_i=(.5*epsilon_Hosp_i>.25)

*generate the true parameters
gen beta_1=-.65
gen beta_2=-.1

gen beta_0=.4

*Generate the true model:
gen P_i=beta_0+beta_1*Health_i + beta_2*Hosp_i+ .3*nu_i

label variable Health_i "Prior Health Status"
label variable Hosp_i "1(Hospitalized)"
label variable P_i "Probability of Dying"

*Save the main data
*save "ConfoundingData.dta", replace

*Get summary stats and make table
 sum P_i Health_i Hosp_i
eststo tabsumstats: quietly estpost sum P_i Health_i Hosp_i

esttab tabsumstats , ///
	fragment eqlabels(none) cells("mean(fmt(%5.2f)) sd(fmt(%5.2f)) min(fmt(%5.2f)) max(fmt(%5.2f))"  )  ///
	nonumbers label replace

esttab tabsumstats using "Tab_sumstats.tex", ///
	fragment eqlabels(none) cells("mean(fmt(%5.2f)) sd(fmt(%5.2f)) min(fmt(%5.2f)) max(fmt(%5.2f))"  )  ///
	nonumbers label replace
	
*Run regressions and make table
** We are able to recover the true parameters if we include health status
reg P_i Health_i Hosp_i

eststo with_health: quietly: reg P_i Health_i Hosp_i

** But if health status is unobservable, then the sign on hospitalization flips
*** Going to the hospital makes you more likely to die
reg P_i Hosp_i
eststo omitted_var: quietly: reg P_i Hosp_i

esttab omitted_var with_health, se label ///
nobaselevels b(3) fragment noomitted  replace

esttab omitted_var with_health using "Regression_Table.tex" , se label ///
nobaselevels b(3) fragment noomitted  replace nomtitles

