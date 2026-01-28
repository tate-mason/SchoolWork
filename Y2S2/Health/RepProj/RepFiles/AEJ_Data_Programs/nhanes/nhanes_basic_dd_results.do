# delimit ;
set more off;

log using nhanes_basic_dd_results.log, replace;

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

gen anymetab=metabsum>0;
replace anymetab=. if riskyglycatedhemoglobin==. | riskyCholest==. | riskyhdl==.;
gen anycardio=cardiosum>0;
replace anycardio=. if riskypulse==. | riskydiastolic==. | riskysystolic==.;
gen anyinflamation=inflsum>0;
replace anyinflamation=. if riskyAlbumin==. | riskycrp==.;

* this makes the data match between NHANES iii and other years;
replace crp=0.21 if crp<0.21;

gen total1=totalsum>0;
replace total1=. if totalsum==.;
gen total2=totalsum>1;
replace total2=. if totalsum==.;
gen total3=totalsum>2;
replace total3=. if totalsum==.;


drop if marital==.;
drop if age==.;
drop if race==.;
drop if highgrade==.;
drop if kids==.;




* get means for Table 5;
sum crp riskycrp albumin riskyAlbumin anyinflamation inflsum
diastolic riskydiastolic systolic riskysystolic pulse riskypulse anycardio cardiosum
cholesterol riskyCholest hdl riskyhdl glycatedhemoglobin riskyglycatedhemoglobin
anymetab metabsum totalsum total1 total2 total3 if  highgrade<=2;

* pre expansion means for treatment group;
* column means for Table 5 and Table 6;
sum riskyglycatedhemoglobin riskyCholest riskyhdl anymetab metabsum 
riskydiastolic riskysystolic riskypulse anycardio cardiosum
riskyAlbumin riskycrp anyinflamation inflsum totalsum total1-total3 if  highgrade<=2 & year==0 & two_plus_kids==1;


* get DD results for Table 6;
* Table 6 column 1;

xi i.race i.marital i.year i.age;

tab year if highgrade<=2;


* linear probabilities for first three models;
reg total1 _I* two_plus_kids treat   if  highgrade<=2, robust;
reg total2 _I* two_plus_kids treat   if  highgrade<=2, robust;
reg total3 _I* two_plus_kids treat   if  highgrade<=2, robust;

* row 4 poisson for total sum. right after, run negative binomial;
* to test for over dispersion;
poisson totalsum _I* two_plus_kids treat  if  highgrade<=2, robust;
nbreg totalsum _I* two_plus_kids treat  if  highgrade<=2, robust d(c);
  

* now get results for the DD estimates in Table 7 for the risky indicators;

* run linear probability models;

reg riskydiastolic _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskysystolic _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskycrp _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskypulse _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskyhdl _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskyCholest _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskyAlbumin _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskyglycatedhemoglobin _I* two_plus_kids treat   if  highgrade<=2, robust;
reg obese _I* two_plus_kids treat   if  highgrade<=2, robust;

* run the models having any risk;
reg anymetab _I* two_plus_kids treat   if  highgrade<=2, robust;
reg anycardio _I* two_plus_kids treat   if  highgrade<=2, robust;
reg anyinflamation _I* two_plus_kids treat   if  highgrade<=2, robust;

* run the poisson models for counts of risky measures;
poisson metabsum _I* two_plus_kids treat  if  highgrade<=2, robust;
poisson cardiosum _I* two_plus_kids treat  if  highgrade<=2, robust;
poisson inflsum _I* two_plus_kids treat  if  highgrade<=2, robust;

* run the negative binomials to check against overdispersion;
nbreg metabsum _I* two_plus_kids treat  if  highgrade<=2, robust d(c);
nbreg cardiosum _I* two_plus_kids treat  if  highgrade<=2, robust d(c);
nbreg inflsum _I* two_plus_kids treat  if  highgrade<=2, robust d(c);

clear;

* now -- generate estmates including moms without kids;
* this is for the final column of Tables 6 and 7;


use nhanesAllStacked_updated_april12;


# delimit ;

* delete males, keep people 21-40, drop all nonmerged;
drop if sex==1;
keep if age>=21&age<=40;

* keep only white, black, hispanics;
keep if race<=3;

* in nhanes III (year==0) no. of kids=familysize-1;
* for single women, familysize-2 for married;

gen kids=.;
replace kids=family_size-1 if marital>1&year==0;
replace kids=family_size-2 if marital==1&year==0;
replace kids=dmdhhsiz-1 if marital>1&year>0;
replace kids=dmdhhsiz-2 if marital==1&year>0;

tab year kids;

gen nohs=highgrade<=2;

* keep everyone now;
keep if kids==0 | kids>1;


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
 

gen optcholrat=cholesterol/hdl<=3.5;
gen riskycholrat=cholesterol/hdl>=5;

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

xi i.race i.marital i.year i.age;

sort year;


* linear probabilities for first three models;
reg total1 _I* two_plus_kids treat   if  highgrade<=2, robust;
reg total2 _I* two_plus_kids treat   if  highgrade<=2, robust;
reg total3 _I* two_plus_kids treat   if  highgrade<=2, robust;

* row 4 poisson for total sum. right after, run negative binomial;
* to test for over dispersion;
poisson totalsum _I* two_plus_kids treat  if  highgrade<=2, robust;
nbreg totalsum _I* two_plus_kids treat  if  highgrade<=2, robust d(c);
  

* now get results for the DD estimates in Table 7 for the risky indicators;

* run linear probability models;

reg riskydiastolic _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskysystolic _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskycrp _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskypulse _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskyhdl _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskyCholest _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskyAlbumin _I* two_plus_kids treat   if  highgrade<=2, robust;
reg riskyglycatedhemoglobin _I* two_plus_kids treat   if  highgrade<=2, robust;
reg obese _I* two_plus_kids treat   if  highgrade<=2, robust;

* run the models having any risk;
reg anymetab _I* two_plus_kids treat   if  highgrade<=2, robust;
reg anycardio _I* two_plus_kids treat   if  highgrade<=2, robust;
reg anyinflamation _I* two_plus_kids treat   if  highgrade<=2, robust;

* run the poisson models for counts of risky measures;
poisson metabsum _I* two_plus_kids treat  if  highgrade<=2, robust;
poisson cardiosum _I* two_plus_kids treat  if  highgrade<=2, robust;
poisson inflsum _I* two_plus_kids treat  if  highgrade<=2, robust;

* run the negative binomials to check against overdispersion;
nbreg metabsum _I* two_plus_kids treat  if  highgrade<=2, robust d(c);
nbreg cardiosum _I* two_plus_kids treat  if  highgrade<=2, robust d(c);
nbreg inflsum _I* two_plus_kids treat  if  highgrade<=2, robust d(c);

log close;




