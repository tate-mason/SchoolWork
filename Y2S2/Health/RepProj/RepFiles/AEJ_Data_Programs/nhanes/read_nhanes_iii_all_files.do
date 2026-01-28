*******************************************************************
*      EITC and Health Outcomes Using NHANES                      *
*      Ron Mariutto                                               *
*******************************************************************
*
*  This study uses two datasets, NHANES III and NHANES 99.
*  Each are constructed from multiple data sets separated 
*  by the topic of the variables, and merged by id number (SEQN).
*  This do file begins with NHANESIII and NHANES99, with all observations
*  and all variables (except the food diary) included

use exam_iii
sort seqn
save, replace
clear

use lab_iii
sort seqn
save, replace
clear

use adult_iii
sort seqn 
merge 1:1 seqn using lab_iii
drop _merge
save work1, replace

sort seqn 
merge 1:1 seqn using exam_iii
drop _merge
save work1, replace


*************************************
*   Part 1.   Prepare NHANES III     
*************************************                            


*In NHANESIII, we have the true family code, in NHANES99, this will be estimated.
  gen familycode_actual=dmpfseq

*We focus our attention on two races
  gen race=dmaracer
      label define racelabel 1 "white, nonhisp" 2 "black, nonhisp" 3 "hispanic" 4 "other" 
      label values race racelabel

*Ensure that in the adult sample, there are 9401Males/10649Females
  tab hssex if hsageir>=17
  gen sex=1 if hssex==1
      replace sex=0 if hssex==2
      label variable sex "sex"
      label define sexlabel 1 "male" 0 "female"
      label values sex sexlabel

*Age in years
  gen age= hsageir 
      replace age=hsageir/12 if hsageu==1
      label variable age "age in yrs"
      

*Married (and spouse lives in house).
    gen marital=1 if hfa12==1 
        replace marital=2 if hfa12==4
        replace marital=3 if hfa12==7
        replace marital=4 if hfa12==5 |hfa12==6
        label define married 1 "married" 2 "widow" 3 "nvrmarried" 4 "divor/separ"
        label values marital married


* Recode highest grade completed 
    gen highgrade=0 if hfa8r<9
        replace highgrade=1 if hfa8r==9 | hfa8r==10 | hfa8r==11 
        replace highgrade=2 if hfa8r==12 
        replace highgrade=3 if hfa8r==13 | hfa8r==14 | hfa8r==15
        replace highgrade=4 if hfa8r==16 | hfa8r==17
        replace highgrade=88 if hfa8r==88
        replace highgrade=99 if hfa8r==99
        label define school 0 "less than HS 9th grade" 1 "HS no diploma" 2 "hs grad and GED" 3 "some coll" 4 "coll grad" 88 "Blank but applicable" 99 "Do not know"
        label values highgrade school

*Rename PSU and strata vars
    	rename sdppsu6 psu
        	label variable psu "pseudo primary sampling units"
    	rename sdpstra6 strata

*Lab results
	gen triglycerides=tgp
		label variable triglycerides "serum triglyceride mg/dL"
		replace triglycerides=. if triglycerides>=8888
    		gen trigly_blank_but_applicable=(tgp==8888)

	gen glycatedhemoglobin=ghp
		label variable glycatedhemoglobin "glycated hemoglobin: (%)"
		replace glycatedhemoglobin=. if glycatedhemoglobin>600
		gen glychemo_blank_bt_applicable=(ghp==8888)

	gen albumin=amp
		label variable albumin "serum albumin (g/dL)"
		replace albumin=. if albumin>=888
		gen alb_blank_but_applicable=(amp==888)

	gen  cholesterol=tcp
		label variable cholesterol "serum cholesterol (mg/dL)"
		replace cholesterol=. if cholesterol>=888
		gen chol_blank_but_applicable=(tcp==888)
	
	gen hdl=hdp
		label variable hdl "serum HDL (mg/dL)"
		replace hdl=. if hdl >=888
		gen hdl_blank_but_applicable=(hdp==888)

*ldl is missing when triglycerides>400mg/dL since the Friedman equation no longer holds
*at these extreme values
	gen ldl=lcp
		label variable ldl "serum LDL (mg/dL)"
		replace ldl=. if ldl>=888
		gen ldl_blank_but_applicable=(lcp==888)
		
	*C-reactive protein (variable name: crp)
		label variable crp "C-reactive protein(mg/dL)"	

       * fibrinogen
       gen fibrinogen=fbp
       replace fibrinogen=. if fibrinogen>=8888
       label var fibrinogen "fibrinogen (md/dL)"	
		
		
*Hemoglobin not comparable to nhanes I and nhanesII due to a different method used 
	gen hemoglobin=hgp
		label variable hemoglobin "hemoglobin (g/dL)"
		replace hemoglobin=. if hemoglobin>=88888
		gen hemo_blank_but_applicable=(hgp==88888)

	gen sample_me_wts= wtpfex6 
	label variable sample_me_wts "Sample weights - total mec examined"

	gen sample_wts=wtpfqx6
	label variable sample_wts "Sample weights - full sample"

	gen family_size=hsfsizer
	label var family_size "Family size"

	
	

	gen pulse= haza5r 
		replace pulse=. if pulse>=888 | pulse==0
		gen pulse_blank_but_applicable=(haza5r==888)
		gen pulse_not_found=(haza5r==0)
		
	gen diastolic= haza8ak5 
		replace diastolic=. if diastolic>=888 | diastolic==0
		gen diastolic_blank_but_applicable=(haza8ak5==888)
	
	gen systolic= haza8ak1 
		replace systolic=. if systolic>888 | systolic==0
		gen systolic_blank_but_applicable=(haza8ak1==888)


	gen howishealth= hab1
		label define howfeels 1 "excellent" 2 "very good" 3 "good" 4 "fair" 5 "poor"
		label values  howishealth howfeels

	gen pir= dmppir 

	gen totfaminc= hff19r if hff19r==0
		replace totfaminc=1000*(hff19r-.5) if hff19r>=1 & hff19r<=20
		replace totfaminc=5000*(hff19r-21)+22500 if hff19r>=21 & hff19r<=27
		*replace totfaminc=. if totfaminc==88| totfaminc==99
		*replace totfaminc=1 if totfaminc<=5
		*replace totfaminc=2 if totfaminc>=6& totfaminc<=10
		*replace totfaminc=3 if totfaminc>=11 & totfaminc<=15
		*replace totfaminc=4 if totfaminc>=16 & totfaminc<=20
		*replace totfaminc=5 if totfaminc==21
		*replace totfaminc=6 if totfaminc==22 | totfaminc==23
		*replace totfaminc=7 if totfaminc==24 | totfaminc==25
		*replace totfaminc=8 if totfaminc==26 | totfaminc==27
		gen faminc_blnk_bt_applicble=(hff19r==88)

	gen weightKG= bmpwt 
		*replace weightKG=weightKG/100
		replace weightKG=. if weightKG>800

	gen heightM=bmpht
		replace heightM=heightM/100
		replace heightM=. if heightM>3
		label variable heightM "height in meters"

	gen bmi=bmpbmi
		*gen bmi=(weightKG/heightM^2)
		replace bmi=. if bmi==8888
		label variable bmi "bmi=weightKG/heightM^2"
		

	gen whratio= bmpwhr 

	gen nhanes="nhiiiphase1" if sdpphase==1
	replace nhanes="nhiiiphase2" if sdpphase==2

	gen taking_bp_med=hae5a
		label var taking_bp_med "1=taking blood pressure meds, 2=no"

	gen taking_chol_med=hae9d
		label var taking_chol_med "1=taking chol medicine, 2=no"
	gen year=0


# delimit ;
keep sample_me_wts sample_wts nhanes whratio bmi heightM 
weightKG faminc_blnk_bt_applicble totfaminc pir howishealth crp
systolic_blank_but_applicable systolic diastolic_blank_but_applicable diastolic pulse 
hemoglobin 
ldl hdl cholesterol albumin glycatedhemoglobin triglycerides 
taking_bp_med taking_chol_med fibrinogen
highgrade marital age sex race family_size sdpphase seqn psu strata year;

