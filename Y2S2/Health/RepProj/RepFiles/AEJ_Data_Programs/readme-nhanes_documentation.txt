This document outlines how to reproduce our estimates from the NHANES samples.  We used data from NHANES III, NHANES 1999/2000, 2001/2002, and 2003/2004.  We will refer to these as the NHANES 99, 01, 03 in the text below.  The data for each is available at the NCHS web site at http://www.cdc.gov/nchs/nhanes/nhanes_questionnaires.htm

The NHANES data comes in raw ASCII data files.  NCHS provides SAS code to read the data.  We use these programs essentially unedited then add some lines of code at the end fo the program to keep the variables we need.  We utilize three files:  the household adult file, the lab file and the examination file.

Initially, we read the data using three sas programs:

read_nhanes_iii_household.sas
read_nhanes_iii_lab.sas
read_nhanes_iii_exam.sas

These three programs produced SAS data sets and we use the SAS conversion program to turn these into STATA data sets.  These three datra sets are names adult_iii.dta, exam_iii.dta, and lab_iii.dta.

Next, run the program read_nhanes_iii_all_files.do that generates a STATA data set called nhanes_iii.dta.

The NHANES 99, 01 and 03 data is available for download in SAS transport data sets.  These data sets can be read directly into stata.  The NCHS carved up the data into many more data sets in these years so there are many more data sets to download.   The data sets needed  

NHANES 99		NHANES 01		NHANES 03		Content
demo			demo_b		demo_c		demographics
bmx			bmx_b			bmx_c			body measurement
bpq			bpq_b			bpq_c			blood pressure
bpx			bpx_b			bpx_c			blood pressure
rhq			rhq_b			rhq_c			reprod. health
lab10			l10_b			l10_c			glychohemoglobin
lab11			l11_b			l11_c			crp
lab13			l13_b			l13_c			LDL/HDL
lab13am		l13am_b		l13am_c		triglycerides
lab16			l16_b			l16_c			albumin
lab18									biochemistry
lab25			l25_b			l25_c			blood count
			l40_b			l40_c			biochemistry

There are three programs that read these data sets.  These are named

read_nhanes_99.do
read_nhanes_01.do
read_nhanes_03.do

These three programs produce three data sets names

nhanes99readyforstack.dta
nhanes01readyforstack.dta
nhanes03readyforstack.dta

Next, run the program stack_all.do that stacks the NHANES III, 99, 01 and 03 data sets into one STATA data set named nhanesallstacked.dta.  

The basic results for the NHANES samples contained in Tables 6-8 are contained in two programs

nhanes_basic_dd_results.do
nhanes_basic_ddd_results.do

The first one produces the difference-in-difference results (columns 1 and 3 in Tables 6 and 7), while the second one produces the estimates for the difference-in-difference-in-difference estimates in column 2 of the same tables.  

In the paper we note that the poisson model is censored in that counts are restricted to be 8 at most.  We have estmated a poisson that restricts the CDF to be only through 8.  That is however written in PROC IML in SAS.  To produce these results, run the STATA do file smaller_sample_for_censored_poisson.do, which constructs a STATA data file.  Convert that to a SAS data file then run the program nhanes_cen_poisson.sas.  
