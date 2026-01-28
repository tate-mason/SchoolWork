# delimit ;
set more off;


* just a note -- all_in_live_births in nhanes III has;
* data for all adults.  in nhanes 99, 01 and 03, it only;
* has data for females;


use nhanesAllStacked;


* delete males, keep people 21-40, drop all nonmerged;
drop if sex==1;
keep if age>=21&age<=40;

* keep only white, black, hispanics;
keep if race<=3 & race>0;

* in nhanes III (year==0) no. of kids=familysize=1;
* for single women, familysize=2 for married;

gen kids=.;
replace kids=family_size-1 if marital>1&year==0;
replace kids=family_size-2 if marital==1&year==0;
replace kids=dmdhhsiz-1 if marital>1&year>0;
replace kids=dmdhhsiz-2 if marital==1&year>0;

gen nohs=highgrade<=2;

* keep families with kids;
keep if kids>0;

* check the distribution of children by year in the sample;
tab kids year, row column;

* generate dummy for 2+ kids;
gen two_plus_kids=kids>1;

* generate dummy for post eitc change period;
gen eitc_expand=year>0;

* generate treatment dummy;
gen treat=eitc_expand*two_plus_kids;

gen loweduc= highgrade<=2;
gen eitc_loweduc=eitc_expand*loweduc;
gen twoplus_low=two_plus_kids*loweduc;
gen ddd_treat=treat*loweduc;



*generate a bunch of dummy variables as covariates;
xi i.race i.marital i.year i.age;

* fix up the crp variable;
replace crp=. if crp==88888;

* generate riskycrp indicator;
gen riskycrp=crp>=0.3;
replace riskycrp=. if crp==.;
replace riskypulse=. if pulse==.;
replace riskydiastolic=. if diastolic==.;
replace riskysystolic=. if systolic==.;
replace riskyhdl=. if hdl==.;
replace riskyCholest=. if cholesterol==.;
replace riskyAlbumin=. if albumin==.;
replace riskyglycatedhemoglobin=. if glycatedhemoglobin==.;
 

gen metabsum = riskyglycatedhemoglobin + riskyCholest + riskyhdl;
gen cardiosum = riskysystolic+riskydiastolic+riskypulse;
gen inflsum = riskycrp + riskyAlbumin;
gen totalsum=metabsum+cardiosum+inflsum;

keep if highgrade<=2;

keep metabsum cardiosum inflsum totalsum _I* two_plus_kids treat;




