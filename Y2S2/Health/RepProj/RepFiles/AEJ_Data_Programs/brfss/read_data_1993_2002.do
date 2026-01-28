# delimit ;

set more off;

set memory 500m;

infile using brfss2002.dct;
save brfss_data_2002, replace;
clear;

infile using brfss2001.dct;
save brfss_data_2001, replace;
clear;

infile using brfss2000.dct;
save brfss_data_2000, replace;
clear;

infile using brfss1999.dct;
save brfss_data_1999, replace;
clear;

infile using brfss1998.dct;
save brfss_data_1998, replace;
clear;

infile using brfss1997.dct;
save brfss_data_1997, replace;
clear;

infile using brfss1996.dct;
save brfss_data_1996, replace;
clear;

infile using brfss1995.dct;
save brfss_data_1995, replace;
clear;

infile using brfss1994.dct;
save brfss_data_1994, replace;
clear;

infile using brfss1993.dct;
save brfss_data_1993, replace;

append using brfss_data_1994;
save brfss_data_all_1, replace;

append using brfss_data_1995;
save brfss_data_all_1, replace;

append using brfss_data_1996;
save brfss_data_all_1, replace;

append using brfss_data_1997;
save brfss_data_all_1, replace;

append using brfss_data_1998;
save brfss_data_all_1, replace;

append using brfss_data_1999;
save brfss_data_all_1, replace;

append using brfss_data_2000;
save brfss_data_all_1, replace;

append using brfss_data_2001;
save brfss_data_all_1, replace;

append using brfss_data_2002;
save brfss_data_all_1, replace;

recode year 93=1993 94=1994 95=1995 96=1996 97=1997 98=1998 99=1999;

replace srhealth=. if srhealth>=6;

replace exercise=. if exercise>=7;

recode phys_poor 88=0;
replace phys_poor=. if phys_poor>=77;

recode mental_poor 88=0;
replace mental_poor=. if mental_poor>=77;

replace phys_act=. if phys_act>=9;
replace phys_act=. if phys_act<=0;

replace age=. if age<=09;

replace marital=. if marital>=9;

replace kids=. if kids>=99;
recode kids 88=0;
replace kids=3 if (kids>=3 & kids<=25);

replace kids_under_5=. if kids_under_5>=9;
replace kids5_12=. if kids5_12>=9;
replace kids13_17=. if kids13_17>=9;
recode kids_under_5 8=0;
recode kids5_12 8=0;
recode kids13_17 8=0;
gen kids1=kids_under_5+kids5_12+kids13_17;
replace kids1=3 if (kids1>=3 & kids1<=25);

replace kids=0 if kids1==0;
replace kids=1 if kids1==1;
replace kids=2 if kids1==2;
replace kids=3 if kids1==3;
drop kids1 kids_under_5 kids5_12 kids13_17;

replace educ=. if educ>=9;
recode educ 2=1 3=1 4=2 5=2 6=3;
label variable marital `"marital status 1=marr 2=widow 3=div 4=sep 5=nev mar 6=couple"';
label variable educ `"education, 1= <high school, 2= hs grad/some college 3= college grad "';
label variable phys_act `"activity level, 1=sedentary, 2=irregular, 3=regular, 4=vigorous"';
label variable kids `"# of kids in household, 3=3 or more"';

replace employ=. if employ>=9;

replace income93=. if income93>=8;
recode income93 2=1 3=1 4=2 5=3 6=4 7=5;
replace income94=. if income94>=9;
recode income94 2=1 3=1 4=2 5=3 6=4 7=5 8=5;
replace income94=1 if income93==1;
replace income94=2 if income93==2;
replace income94=3 if income93==3;
replace income94=4 if income93==4;
replace income94=5 if income93==5;
drop income93;
rename income94 income;
label variable income `"family income, 1= under 20k, 2= 20-25k, 3= 25-35k, 4= 35-50k, 5= 50k or more"';

replace weight=. if weight>=777;

replace county=. if county==777;
replace county=. if county==999;

replace smoke_status=. if smoke_status==9;
replace smoke93=. if smoke93==9;
replace smoke94=. if smoke94==9;
gen now_smoke=smoke_status;
recode now_smoke 4=0 3=0 2=1;
gen ever_smoke=smoke_status;
recode ever_smoke 4=0 3=1 2=1;
label variable now_smoke `"current smoker, 1=yes, 0=no"';
label variable ever_smoke `"ever smoked, 1=yes, 0=no"';
gen now_smoke4=smoke94;
recode now_smoke4 2=1 3=1 4=1 5=0 6=0;
gen ever_smoke4=smoke94;
recode ever_smoke4 2=1 3=1 4=1 5=1 6=0;
gen now_smoke3=smoke93;
recode now_smoke3 4=1 2=0 3=0;
gen ever_smoke3=smoke93;
recode ever_smoke3 4=1 2=1 3=0;
replace now_smoke=1 if now_smoke3==1;
replace now_smoke=1 if now_smoke4==1;
replace now_smoke=0 if now_smoke4==0;
replace now_smoke=0 if now_smoke3==0;
replace ever_smoke=0 if ever_smoke3==0;
replace ever_smoke=1 if ever_smoke3==1;
replace ever_smoke=0 if ever_smoke4==0;
replace ever_smoke=1 if ever_smoke4==1;
drop now_smoke3 now_smoke4 ever_smoke3 ever_smoke4 smoke94 smoke93 smoke_status;
replace race5=. if race5==9;
recode race5 3=4 5=3;
replace race8=. if race8>=9;
recode race8 4=3 5=3;
recode race8 6=4 7=4 8=4;
replace race4=1 if race5==1;
replace race4=2 if race5==2;
replace race4=3 if race5==3;
replace race4=4 if race5==4;
replace race4=1 if race8==1;
replace race4=2 if race8==2;
replace race4=3 if race8==3;
replace race4=4 if race8==4;
replace race4=. if race4==9;
label variable race4 `"race/ethnicity 1=w(NH), 2=b(NH), 3=Hispanic 4=other(NH)"';
drop race5 race8;

replace fruit_veggie=. if fruit_veggie==9;
label variable fruit_veggie `"fruit & veg per day, 1=<once or never, 2=1-2 times, 3=3-4 times, 4=5 or more times"';
label variable exercise `"exercise in past month, 1=yes, 0=no"';
recode exercise 2=0;
replace alcoholic=. if alcoholic==9;
recode alcoholic 1=0 2=1;
label variable alcoholic `"chronic drinking, 0=not at risk, 1=at risk"';
replace totaldrinks=. if totaldrinks==9999;
recode totaldrinks 8888=0;

replace height=. if height>=777;
recode height 20=200 21=201 22=202 23=203 24=204 25=205 26=206 27=207 28=208 29=209 30=300 31=301 32=302 33=303 34=304 35=305 36=306 37=307 38=308 39=309 40=400 41=401 42=402 43=403 44=404 45=405 46=406 47=407 48=408 49=409 50=500 51=501 52=502 53=503 54=504 55=505 56=506 57=507 58=508 59=509 60=600 61=601 62=602 63=603 64=604 65=605 66=606 67=607 68=608 69=609 70=700 71=701 72=702 73=703 74=704 75=705 76=706 77=707 78=708 79=709;

gen ft=int(height/100);
gen inches=height-100*ft;
gen height1=12*ft+inches;
drop height ft inches;
rename height1 height;
label variable height `"height in inches"';

gen bmi=703*weight/(height*height);
label variable bmi `"body mass index"';
replace bmi=. if bmi<=17.53976;
replace bmi=. if bmi>=42.96111;
save brfss_data_all_2, replace;


