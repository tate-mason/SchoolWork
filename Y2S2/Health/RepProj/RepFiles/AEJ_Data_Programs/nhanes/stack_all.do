*******************************************************************
*      EITC and Health Outcomes Using NHANES                      *
*      Ron Mariutto                                               *
*******************************************************************
*
*  This study uses two datasets, NHANES III and NHANES 99.
*  Each are constructed from multiple data sets separated 
*  by the topic of the variables, and merged by id number (SEQN).
*  This do file begins with NHANESIII and NHANES99, with all observations
*  and all variables (except the food diary) included.

clear

use nhanes_iii

append using nhanes99ReadyForStack
append using NHanes01readyforstack
append using NHanes03readyforstack


replace pir=. if pir==888888
*drop whratio

***********************


*Indicate year 0 as nhanes III and year 1 as  nhanes 99.  To instead have year 0 only in phase 1 of nhIII,
* then in an if statement, use "sdpphase!=2"


replace highgrade=. if highgrade>=88
replace systolic=. if systolic==888
replace diastolic=. if diastolic==0
replace pir=5 if pir>=5

sort year

*************************************************
*     Generate indicators for risky levels

* prepare biomarkers

	*replace smokperday=. if smokperday==88
	*replace smokperday=. if smokperday==140
	*replace diastolic=. if diastolic<=10
	*replace systolic=. if systolic<=10
	*replace diastolic=. if diastolic>160
	*replace systolic=. if systolic>240
	*replace cholesterol=. if cholesterol>600
	*whratio only exists in nh3
	*gen riskyWHratio=(whratio>.9 & whratio!=.) if sex==1
	*replace riskyWHratio=(whratio>.85 & whratio!=.) if sex==0

gen riskyAlbumin=(albumin<3.8 & albumin!=.) 
	*if albumin!=.
	*replace riskyAlbumin=0 if alb_blank_but_applicable==1
	
gen riskyCholest=(cholesterol>=240 & cholesterol!=.) 
	*if cholesterol!=.
	*replace riskyCholest=0 if chol_blank_but_applicable==1

gen riskyhdl=(hdl<40 & hdl!=.) 
	*if hdl!=.
	*replace riskyhdl=0 if hdl_blank_but_applicable==1

gen riskyglycatedhemoglobin=(glycatedhemoglobin>=6.4 & glycatedhemoglobin!=.) 
	*if glycatedhemoglobin!=.
	*replace riskyglycatedhemoglobin=0 if glychemo_blank_bt_applicable==1

gen riskypulse=(pulse>=90 & pulse!=.) 
	*if pulse!=.
	*replace riskypulse=0 if pulse_blank_but_applicable==1
	*replace riskypulse=0 if pulse_not_found==1
	
gen riskysystolic=(systolic>=140 & systolic!=.) 
	*if systolic!=.
	*replace riskysystolic=0 if systolic_blank_but_applicable==1

gen riskydiastolic=(diastolic>=90 & diastolic!=.) 
	*if diastolic!=.
	*replace riskydiastolic=0 if diastolic_blank_but_applicable==1

gen obese=(bmi>=30 & bmi!=.)

replace year=0 if sdpphase==2
sum risky* if year==0 
sum risky* if year==1 

save nhanesallstacked, replace




