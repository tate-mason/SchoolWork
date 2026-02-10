
 clear
 
 import delimited "HW2_P1.csv"
 
 rename v1 attend4yr
 rename v3 parentBA
 rename v4 GPA
 rename v5 dist4yr_minus_dist2yr
 drop v2
 
 logit attend4yr i.parentBA GPA dist4
 est store m1
 
 margins, dydx(parentBA)
 est restore m1
 margins if parentBA==1, dydx(parentBA)
 
 
 probit attend4yr i.parentBA GPA dist4 
 margins, dydx(parentBA)
