This document outlines how to reproduce our estimates from the BRFSS samples.  We used data from the 1993-2002 BRFSS.  The 1993 data was the first year where we could estimate the number or children in the household. 

The data for each is available at the CDC web site at http://www.cdc.gov/brfss/annual_data/annual_data.htm#2001

The BRFSS data comes in flat ASCII data files.  To read the data into STATA, we constructed a data dictionary for every year.  These files are named brfssyyyy.dct where yyyy is the appropriate year. 

The program that reads the all years of data into one data data file is named read_data_1993_2002.do.

The program that generates all the BRFSS results in the paper is named BRFSS_CODE_REPLICATION.do.

