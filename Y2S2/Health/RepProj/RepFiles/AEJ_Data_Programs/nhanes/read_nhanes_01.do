* read data from the nhanes 01 survey.  all the original data 
* is in sas transport format and downloaded dircetly from the 
* NCHS data set.  All data is merged by seqn 

import sasxport demo_b 
sort seqn 
save work1, replace 
clear 

import sasxport bmx_b 
sort seqn 
merge 1:1 seqn using work1 
drop _merge 
sort seqn 
save work1, replace 
clear 

import sasxport bpq_b 
sort seqn 
merge 1:1 seqn using work1 
drop _merge 
sort seqn 
save work1, replace 
clear 

import sasxport bpx_b 
sort seqn 
merge 1:1 seqn using work1 
drop _merge 
sort seqn 
save work1, replace 
clear 

import sasxport l10_b 
sort seqn 
merge 1:1 seqn using work1 
drop _merge 
sort seqn 
save work1, replace 
clear 

import sasxport l11_b 
sort seqn 
merge 1:1 seqn using work1 
drop _merge 
sort seqn 
save work1, replace 
clear 

import sasxport l13_b 
sort seqn 
merge 1:1 seqn using work1 
drop _merge 
sort seqn 
save work1, replace 
clear 

import sasxport l13am_b 
sort seqn 
merge 1:1 seqn using work1 
drop _merge 
sort seqn 
save work1, replace 
clear 

import sasxport l16_b 
sort seqn 
merge 1:1 seqn using work1 
drop _merge 
sort seqn 
save work1, replace 
clear 

import sasxport l25_b 
sort seqn 
merge 1:1 seqn using work1 
drop _merge 
sort seqn 
save work1, replace 
clear 

import sasxport l40_b 
sort seqn 
merge 1:1 seqn using work1 
drop _merge 
sort seqn 
save work1, replace 
clear 

import sasxport rhq_b 
sort seqn 
merge 1:1 seqn using work1 
drop _merge 
sort seqn 
save work1, replace 

**************************************
*       Bring in Nhanes01            *
*         Add set up to match        *      
**************************************

clear
use work1

	gen race=ridreth2
      label define racelabel 1 "white, nonhisp" 2 "black, nonhisp" 3 "hispanic" 4 "other" 
      label values race racelabel

	gen sex=1 if riagendr==1
		replace sex=0 if riagendr==2
		label variable sex "sex"
		label define sexlabel 1 "male" 0 "female"
		label values sex sexlabel

	gen age= ridageyr
		label variable age "age in yrs"


	gen marital=1 if dmdmartl==1 
		replace marital=2 if dmdmartl==2
		replace marital=3 if dmdmartl==5 |dmdmartl==6
		replace marital=4 if dmdmartl==3 |dmdmartl==4
		label define married 1 "married" 2 "widow" 3 "nvrmarried" 4 "divor/separ"
		label values marital married

	gen highgrade=0 if dmdeduc2==1
		replace highgrade=1 if dmdeduc2==2
		replace highgrade=2 if dmdeduc2==3
		replace highgrade=3 if dmdeduc2==4
		replace highgrade=4 if dmdeduc2==5
		label define school 0 "less than HS 9th grade" 1 "HS no diploma" 2 "hs grad and GED" 3 "some coll" 4 "coll grad" 
		label values highgrade school

	rename sdmvpsu psu
		label variable psu "pseudo primary sampling units"

	rename sdmvstra strata

	gen triglycerides=lbxtr
		label variable triglycerides "serum triglyceride mg/dL"
	replace triglycerides=. if triglycerides>=8888


	gen glycatedhemoglobin=lbxgh
		label variable glycatedhemoglobin "glycated hemoglobin: (%)"
		replace glycatedhemoglobin=. if glycatedhemoglobin>600

	gen albumin= lbxsal 
		label variable albumin "serum albumin (g/dL)"


	gen cholesterol= lbxtc 
		label variable cholesterol "serum cholesterol (mg/dL)"
	
	gen hdl= lbdhdl 
		label variable hdl "serum HDL (g/dL)"


	gen ldl= lbdldl 
		label variable ldl "serum LDL (g/dl)"
		
	gen crp = lbxcrp
		label variable crp "C-reactive protein(mg/dL)"


	gen hemoglobin= lbxhgb 
		label variable hemoglobin "hemoglobin (g/dl)"


	gen sample_wts=wtmec2yr 
		label variable sample_wts "fullsample 2yrMecExamWt-nh99"

	gen pulse= bpxpls 

	gen systolic= bpxsy1   

	gen diastolic= bpxdi1 

	
	gen pir= indfmpir 
		label variable pir "poverty income ratio"
		
	gen totfaminc= 5000*(indfminc-1) +2500 if indfmpir<=5
		replace totfaminc=5000*(indfminc-6)+30000 if indfmpir>=6 & indfmpir<=8
		replace totfaminc=55000 if indfminc>=9&indfminc<=11
		replace totfaminc=10000 if indfminc==13
	
	gen weightKG= bmxwt 
		*replace weightKG=weightKG/100
		replace weightKG=. if weightKG>800

	gen heightM= bmxht  
		replace heightM=. if heightM==8888
		replace heightM=heightM/100
		label variable heightM "height in meters"

	gen bmi=bmxbmi
		*gen bmi=(weightKG/heightM^2)
		label variable bmi "bmi=weightKG/heightM^2"

	*gen bpmeds=mcq110
		*label variable bpmeds "on BP meds"

	gen nhanes="nh01" 


	gen year=2	
	
	gen live_births=rhd170


#delimit ;
keep year sample nhanes  bmi heightM crp
weightKG totfaminc pir systolic  diastolic  pulse hemoglobin ldl  hdl  cholesterol
sample_wts albumin  glycatedhemoglobin  triglycerides highgrade marital age sex race seqn live_births psu dmdhhsiz; 
sort seqn;
save nhanes01readyforstack, replace;








