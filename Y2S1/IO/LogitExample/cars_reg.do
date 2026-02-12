cd "~/Dropbox/teaching/UGA Grad IO/"
clear

use "Data/cars.dta", clear
/*
/*Some models apear twice. Create the weighted average of price and characteristics */
egen QUANTITY2=sum(QUANTITY), by(FIRM BRAND MODEL YEAR)
egen PRICE2=sum(PRICE*QUANTITY/QUANTITY2), by(FIRM BRAND MODEL YEAR)
egen HP2=sum(HP*QUANTITY/QUANTITY2), by(FIRM BRAND MODEL YEAR)
egen LENGTH2=sum(LENGTH*QUANTITY/QUANTITY2), by(FIRM BRAND MODEL YEAR)
egen WIDTH2=sum(WIDTH*QUANTITY/QUANTITY2), by(FIRM BRAND MODEL YEAR)
egen SIZE2=sum(SIZE*QUANTITY/QUANTITY2), by(FIRM BRAND MODEL YEAR)
egen WEIGHT2=sum( WEIGHT*QUANTITY/QUANTITY2), by(FIRM BRAND MODEL YEAR)
egen FUEL2=sum(FUEL*QUANTITY/QUANTITY2), by(FIRM BRAND MODEL YEAR)
egen MPG2=sum(MPG*QUANTITY/QUANTITY2), by(FIRM BRAND MODEL YEAR)

collapse (mean) QUANTITY2 PRICE2 HP2 LENGTH2 WIDTH2 SIZE2 WEIGHT2 FUEL2 MPG2 FUELPRICE (max) SEGMENT, by(ORIG FIRM_ID FIRM BRAND MODEL YEAR)

rename QUANTITY2 QUANTITY
rename PRICE2 PRICE	
rename HP2 HP
rename LENGTH2 LENGTH
rename WIDTH2 WIDTH
rename SIZE2 SIZE
rename WEIGHT2 WEIGHT
rename FUEL2 FUEL
rename MPG2 MPG
*/


/*Generate Steel Data*/
gen steel_price=.

replace steel_price=1.00 if YEAR==1995
replace steel_price=1.012 if YEAR==1996
replace steel_price=1.020 if YEAR==1997
replace steel_price=1.006 if YEAR==1998
replace steel_price=0.995 if YEAR==1999
replace steel_price=1.028 if YEAR==2000

egen brand_id=group(BRAND)
egen model_id=group(MODEL)

outsheet CODE-FIRM_ID YEAR-steel_price brand_id model_id using "Data/cars2.csv", replace comma
outsheet using "Data/cars.csv", replace comma

/*Generate Market Size*/
/*average inside share is about 10% throught this time period */
egen totQ=sum(QUANTITY)

gen M=totQ/(6*.1)

/*Generate Market Shares*/
gen sj=QUANTITY/M

egen inside_share=sum(sj), by(YEAR)

gen s0=1-inside_share

/*Generate Instrument*/

gen iv1=SIZE*steel_price
gen iv2=WEIGHT*steel_price

/*Generate variable*/
gen DV=log(sj)-log(s0) /*dependant variable (y in the slides)*/

/*characteristics */
gen non_euro=ORIG>1

gen small=SEGMENT==1
gen compact=SEGMENT==2
gen sedan=SEGMENT==3
gen luxery=SEGMENT==4
gen mini=SEGMENT==5

/* local list of characteristics */
local chars "HP MPG FUEL non_euro small sedan luxery mini"

/*Run OLS Model*/
reg DV `chars' PRICE

local alpha1=_b[PRICE]

/*calcualte elasticity and generate a histogram*/
gen oelas1=`alpha1'*PRICE*(1-sj)

hist oelas1, percent bin(30) xtitle("Elasticity") graphregion(color(white)) fcolor(gs10) lcolor(gs2) xline(-1)


/*Run 2SLS Model*/
ivreg DV `chars' (PRICE = iv1), first

local alpha2=_b[PRICE]

/*calcualte elasticity and generate a histogram*/
gen oelas2=`alpha2'*PRICE*(1-sj)

hist oelas2, percent bin(30) xtitle("Elasticity") graphregion(color(white)) fcolor(gs10) lcolor(gs2) xline(-1)

/* elasticity distributions */
summ oelas1, det
summ oelas2, det
/*************************************/
/*************************************/
/*************************************/
/*************************************/
*NESTED LOGIT*

/*generate conditional shares*/
egen total_seg_sales=sum(QUANTITY), by(YEAR SEGMENT)
gen sjg=QUANTITY/total_seg_sales
gen log_sjg=log(sjg)

/*gen instrument for conditional share*/
gen dum=1
egen iv3=sum(dum), by(YEAR SEGMENT)
drop dum

/* local list of characteristics */
local chars "HP MPG FUEL non_euro"

/*run model without IV for conditional share*/
ivreg DV `chars' sjg (PRICE = iv1), first

/*run model with IV for conditional share*/
ivreg DV `chars' (PRICE log_sjg = iv1 iv3), first

local alpha3=_b[PRICE]
local sig1=_b[log_sjg]

/*calcualte elasticity and generate a histogram*/
gen oelas3=`alpha3'*1/(1-`sig1')*PRICE*(1-`sig1'*sjg-1*(1-`sig1')*sj)

hist oelas3, percent bin(30) xtitle("Elasticity") graphregion(color(white)) fcolor(gs10) lcolor(gs2) xline(-1)

summ oelas3, det
/*generate the top 5 cars for each segement and merge it back in and only keep the top 5 of each segment*/
preserve
egen tot_sales=sum(QUANTITY), by(SEGMENT BRAND MODEL CODE)
contract tot_sales SEGMENT BRAND MODEL CODE
egen rank_sales_seg=rank(tot_sales), by(SEGMENT) field 
keep if rank_sales_seg<=5
save "Data/top5_seg.dta", replace
restore

merge m:1 BRAND MODEL CODE using "Data/top5_seg.dta"
keep if _merge==3

/*create two data sets of shares prices, etc, so that i can match each car up with each other car*/
preserve
keep BRAND MODEL YEAR sj sjg PRICE SEGMENT CODE
rename BRAND BRAND2
rename MODEL MODEL2
rename SEGMENT SEGMENT2
rename CODE CODE1
rename sj sj2
rename sjg sjg2
rename PRICE PRICE2
save "Data/temp.dta", replace
restore

keep BRAND MODEL YEAR sj sjg PRICE  SEGMENT CODE
rename BRAND BRAND1
rename MODEL MODEL1
rename SEGMENT SEGMENT1
rename CODE CODE2
rename sj sj1
rename sjg sjg1
rename PRICE PRICE1

/*create pairs of each car with each car*/
joinby YEAR using "Data/temp.dta"


/*elasticities for model 1. OLS MN Logit */
gen elas=`alpha1'*(1-sj1)*PRICE1 if BRAND1==BRAND2 & MODEL1==MODEL2 & CODE1==CODE2
replace elas=-1*`alpha1'*(sj2)*PRICE2 if BRAND1!=BRAND2 | MODEL1!=MODEL2 | CODE1~=CODE2

/*average across years*/
egen ave_elas1=mean(elas), by(BRAND1 MODEL1 BRAND2 MODEL2 CODE1 CODE2)
egen ave_s11=mean(sj1), by(BRAND1 MODEL1 BRAND2 MODEL2 CODE1 CODE2)
egen ave_s21=mean(sj2), by(BRAND1 MODEL1 BRAND2 MODEL2 CODE1 CODE2)

/*elasticities for model 1. IV MN Logit */
gen elas2=`alpha2'*(1-sj1)*PRICE1 if BRAND1==BRAND2 & MODEL1==MODEL2 & CODE1==CODE2
replace elas2=-1*`alpha2'*(sj2)*PRICE2 if BRAND1!=BRAND2 | MODEL1!=MODEL2| CODE1~=CODE2

/*average across years*/
egen ave_elas2=mean(elas2), by(BRAND1 MODEL1 BRAND2 MODEL2 CODE1 CODE2)

/*elasticities for model 1. IV NESTED Logit */
gen elas3=`alpha3'*1/(1-`sig1')*(1-`sig1'*sjg1-(1-`sig1')*sj1)*PRICE1 if BRAND1==BRAND2 & MODEL1==MODEL2 & CODE1==CODE2
replace elas3=-1*`alpha3'*(sj2)*(sj1+`sig1'/(1-`sig1')*sjg1)*PRICE2/sj1 if (BRAND1!=BRAND2 | MODEL1!=MODEL2 | CODE1~=CODE2) & SEGMENT1==SEGMENT2 
replace elas3=-1*`alpha3'*(sj2)*PRICE2 if (BRAND1!=BRAND2 | MODEL1!=MODEL2| CODE1~=CODE2) & SEGMENT1!=SEGMENT2 

/*average across years*/
egen ave_elas3=mean(elas3), by(BRAND1 MODEL1 BRAND2 MODEL2  CODE1 CODE2)

/*collapse the data to only the averages across years */
contract BRAND1 MODEL1 SEGMENT1 CODE1 ave_s1 BRAND2 MODEL2 SEGMENT2 CODE2 ave_elas* ave_s2
sort BRAND1 MODEL1 ave_elas1 SEGMENT1 



