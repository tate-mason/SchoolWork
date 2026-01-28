# delimit ;
set more off;

log using nhanes_stacked_ddd_results.log, replace;

* just a note -- all_in_live_births in nhanes III has;
* data for all adults.  in nhanes 99, 01 and 03, it only;
* has data for females;


use nhanesAllStacked;

* delete males, keep people 21-40, drop all nonmerged;
drop if sex==1;
keep if age>=21&age<=40;

* keep only white, black, hispanics;
keep if race<=3;

* in nhanes III (year==0) no. of kids=familysize=1;
* for single women, familysize=2 for married;

gen kids=.;
replace kids=family_size-1 if marital>1&year==0;
replace kids=family_size-2 if marital==1&year==0;
replace kids=dmdhhsiz-1 if marital>1&year>0;
replace kids=dmdhhsiz-2 if marital==1&year>0;

tab year kids;

gen nohs=highgrade<=2;

* keep families with kids;
keep if kids>0;

* check the distribution of children by year in the sample;
tab kids year, row column;


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


gen anymetab=metabsum>0;
replace anymetab=. if riskyglycatedhemoglobin==. | riskyCholest==. | riskyhdl==.;
gen anycardio=cardiosum>0;
replace anycardio=. if riskypulse==. | riskydiastolic==. | riskysystolic==.;
gen anyinflamation=inflsum>0;
replace anyinflamation=. if riskyAlbumin==. | riskycrp==.;

* this makes crp comparable across NHANES data sets;
replace crp=0.21 if crp<0.21;

drop if marital==.;
drop if age==.;
drop if race==.;
drop if highgrade==.;
drop if kids==.;


gen total1=totalsum>0;
replace total1=. if totalsum==.;
gen total2=totalsum>1;
replace total2=. if totalsum==.;
gen total3=totalsum>2;
replace total3=. if totalsum==.;


* generate dummy for 2+ kids;
gen two_plus_kids=kids>1;

* generate dummy for post eitc change period;
gen eitc_expand=year>0;

* generate treatment dummy;
gen dd_treat=eitc_expand*two_plus_kids;
gen loweduc= highgrade<=2;
gen eitc_loweduc=eitc_expand*loweduc;
gen twoplus_low=two_plus_kids*loweduc;
gen ddd_treat=dd_treat*loweduc;


xi i.race i.marital i.year i.age i.highgrade*i.year i.year*i.two_plus_kids i.highgrade*i.two_plus_kids;


* generate results for Table 6 -- DDD estimates -- column (2);
* linear probability models;
reg total1 _I* ddd_treat, robust;
reg total2 _I* ddd_treat, robust;
reg total3 _I* ddd_treat, robust;

* run poisson for total counts of risky activities;
* run neg binomial right after to check for over dispersion;
poisson totalsum _I* ddd_treat, robust;
nbreg totalsum _I* ddd_treat, robust d(c);


* run risky models -- these are estimates for column (2) Table 6;
reg riskydiastolic _I* ddd_treat, robust;
reg riskysystolic _I* ddd_treat, robust;
reg riskycrp _I* ddd_treat, robust;
reg riskypulse _I* ddd_treat, robust;
reg riskyhdl _I* ddd_treat, robust;
reg riskyCholest _I* ddd_treat, robust;
reg riskyAlbumin _I* ddd_treat, robust;
reg riskyglycatedhemoglobin _I* ddd_treat, robust;
reg obese _I* ddd_treat, robust;

* check results for any coditions across groups;
reg anymetab _I* ddd_treat, robust;
reg anycardio _I* ddd_treat, robust;
reg anyinflamation _I* ddd_treat, robust;


* run the poissons for counts of conditions;
poisson metabsum _I* ddd_treat, robust;
poisson cardiosum _I* ddd_treat, robust;
poisson inflsum _I* ddd_treat, robust;

* run negative binomials to check for over dispersion;
nbreg metabsum _I* ddd_treat, robust d(c);
nbreg cardiosum _I* ddd_treat, robust d(c);
nbreg inflsum _I* ddd_treat, robust d(c) iter(100);
log close;
