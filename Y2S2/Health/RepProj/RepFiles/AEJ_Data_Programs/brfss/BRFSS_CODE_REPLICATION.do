* get DD and DDD estimates for longer post treatment time period;

# delimit ;
set more off;
set memory 500m;
set matsize 1000;

* Load BRFSS Data
use brfss_data_all_2;

* Restrict data to keep only the years 1993-2000;
drop if year<1993;
drop if year>2001;

* Restrict the data to only women;
drop if sex==1;

* Restrict the sample to those between the ages of 21 and 40;
drop if age>40; 
drop if age<21;

* Drop observations with a missing number of children, race, marital status, or educaitonal attainment;
drop if kids==.;
drop if race4==.;
drop if marital==.;
drop if educ==.;


* Dop areas that are not states;
drop if fips>56;

* Generate the EITC expansion variable for years that are greater than or equal to 1996;
gen eitc_expand=year>=1996;

* Create a dummy indicating families that have two or more kids;
gen twoplus_kids=kids>1;

* Generate our difference-in-differences interaction variable;
gen dd_treatment=twoplus_kids*eitc_expand;

* Create health and labor market outcomes for our analysis;
gen bad_mental_30=mental_poor>0;
replace bad_mental_30=. if mental_poor==.;

gen bad_phys_30=phys_poor>0;
replace bad_phys_30=. if phys_poor==.;

gen excel_vgood=srhealth<=2;
replace excel_vgood=. if srhealth==.;

gen working=employ<=2;
replace working=. if employ==.;

gen inlf=employ<=4;
gen at_work=employ<=2;


* Generate covariates for the regression models;
gen married=marital==1;
gen div_sep_wid=(marital==3|marital==2|marital==4);
gen never_married=marital==5;
gen white_nh=race==1;
gen black_nh=race==2;
gen hispanic=race==3;
gen other=race==4;
gen single=marital>1;

gen income1=income==1;
gen income2=income==2;
gen income3=income==3;
gen income4=income==4;
gen income5=income==5;
gen incomemiss=income==.;


* Create a consistent samples for our variables;
drop if excel_vgood==.;
*drop if bad_mental_30==.; 
drop if now_smoke==.;
*drop if bad_phys_30==.;


*Genreate the Results for Table 3 --- "Difference-in-Difference OLS and Negative Binomial Estimates Mothers Aged 21-40, 1993-2001 BRFSS";

preserve;

* drop families with no kids;

drop if kids==0;

* Generate pretreatment means;

sum inlf excel_vgood mental_poor phys_poor if year<1996 & twoplus_kids==1;

* The simple DD estimates;

reg inlf twoplus_kids eitc_expand dd_treatment  if educ<=2, cluster(fips);
reg excel_vgood twoplus_kids eitc_expand dd_treatment  if educ<=2, cluster(fips);
nbreg mental_poor twoplus_kids eitc_expand dd_treatment  if educ<=2, cluster(fips);
nbreg phys_poor twoplus_kids eitc_expand dd_treatment  if educ<=2, cluster(fips);

* Then Create the regresssion adjusted estimates

xi i.educ i.year i.kids i.educ i.race4 i.marital i.age i.fips i.month;

reg inlf _I* dd_treatment  if educ<=2, cluster(fips);
reg excel_vgood _I* dd_treatment  if educ<=2, cluster(fips);
nbreg mental_poor _I* dd_treatment  if educ<=2, cluster(fips);
nbreg phys_poor _I* dd_treatment  if educ<=2, cluster(fips);

restore;



*Generate the Results for Table 4 - "Robustness Tests, Women Aged 21-40, 1993-2001 BRFSS"

preserve

drop if kids==0;

* state by year results 

xi i.educ i.year*fips i.kids i.educ i.race4 i.marital i.age i.month;

reg inlf _I* dd_treatment  if educ<=2, cluster(fips);
reg excel_vgood _I* dd_treatment  if educ<=2, cluster(fips);
nbreg mental_poor _I* dd_treatment  if educ<=2, cluster(fips);
nbreg phys_poor _I* dd_treatment  if educ<=2, cluster(fips);


xi i.educ i.year i.kids i.educ i.race4 i.marital i.age i.fips i.month;

* single;
reg inlf _I* dd_treatment  if educ<=2 & marital>1, cluster(fips);
reg excel_vgood _I* dd_treatment  if educ<=2 & marital>1, cluster(fips);
nbreg mental_poor _I* dd_treatment  if educ<=2 & marital>1, cluster(fips);
nbreg phys_poor _I* dd_treatment  if educ<=2 & marital>1, cluster(fips);

* married;
reg inlf _I* dd_treatment  if educ<=2 & marital==1, cluster(fips);
reg excel_vgood _I* dd_treatment  if educ<=2 & marital==1, cluster(fips);
nbreg mental_poor _I* dd_treatment  if educ<=2 & marital==1, cluster(fips);
nbreg phys_poor _I* dd_treatment  if educ<=2 & marital==1, cluster(fips);


*DDD results;

*drop some college;

drop if educ==3;

* dummy for low_education;
gen loweduc=educ<=2;

* dummy for low educ time interaction;
gen loweduc_x_after=loweduc*eitc_expand;

* dummy for kids x time;
gen eitc_x_twoplus=eitc_expand*twoplus_kids;

* dummy for loweduc x 2kids;
gen loweduc_x_twokids=loweduc*twoplus_kids;

* dummy for treatment effect;
gen treatment=loweduc*eitc_expand*twoplus_kids;

xi i.educ i.year i.kids i.educ i.race4 i.marital i.age i.fips i.month;

reg inlf loweduc twoplus_kids eitc_expand loweduc_x_after eitc_x_twoplus loweduc_x_twokids treatment, cluster(fips);
reg excel_vgood loweduc twoplus_kids eitc_expand loweduc_x_after eitc_x_twoplus loweduc_x_twokids treatment, cluster(fips);

nbreg mental_poor loweduc twoplus_kids eitc_expand loweduc_x_after eitc_x_twoplus loweduc_x_twokids treatment, cluster(fips);
nbreg phys_poor loweduc twoplus_kids eitc_expand loweduc_x_after eitc_x_twoplus loweduc_x_twokids treatment, cluster(fips);

restore;

*Generate 2+ kids vs. no kids results;

preserve;

drop if kids==1;

xi i.educ i.year i.kids i.educ i.race4 i.marital i.age i.fips i.month;

reg inlf _I* dd_treatment  if educ<=2, cluster(fips);
reg excel_vgood _I* dd_treatment  if educ<=2, cluster(fips);
nbreg mental_poor _I* dd_treatment  if educ<=2, cluster(fips);
nbreg phys_poor _I* dd_treatment  if educ<=2, cluster(fips);

restore;









