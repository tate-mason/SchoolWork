/*******************************************
* Tate Mason - david.mason2@uga.edu        *
* Problem Set 2 - Data Work                *
* Began - Sep 9, 2024, Due - Sep 13, 2024  *
*******************************************/

/***********************
* 1. Setup             *
***********************/

		#delimit cr 		// make carriage return the command delimiter
		clear				//clear data in memory
		clear all			//clear all variables in memory
		set more off		//turn the "more" option for screen output off

		local rootPath "/Users/tate/Library/CloudStorage/Dropbox/Schoolwork/Macro1/ProblemSets/PS2"
		
		local codePath "`rootPath'/code/"
		local data "`rootPath'/Data/"
		local output "`rootPath'/Output/"
		

		set scheme white_tableau
		cap log close

local 3a = 0
local 3b = 0
local 3d = 1
local 3e = 1
/*************************
* 2. Question 3a         *
*************************/
/* Compute average savings rate (investment share of output) since 1990 */
  if `3a' {
    use "`data'pwt1001" //Load Dataset
    browse //Dumb check
    keep if year>=1990 //given
    collapse csh_i, by(countrycode)

    
    egen cc = group(countrycode)
    twoway scatter csh_i cc, xtitle(, color(white))xlab(,nogrid nolabels noticks) ytitle("Average Savings Rate") title("Average Savings Rate 1990-Present") //graphing
      graph export "`output'3a.png", replace //exporting
  }
/*************************
* 3. Question 3b         *
*************************/
/* Plot capital output against savings. using data from 2017
to measure the capital out ratio and the average savings rate 
from the previous question */
clear
 if `3b' {
    use "`data'pwt1001" //load dataset
    keep if year == 2017 //given

      browse
    
    gen co_ratio = rnna/rgdpna
      label var co_ratio "Capital-Output Ratio"
    collapse csh_i, by(year countrycode co_ratio ctfp)
      

    twoway scatter co_ratio csh_i, xtitle("Savings Rate") ytitle("Capital-Output Ratio")
      graph export "`output'3b.png", replace
    
    twoway scatter co_ratio csh_i if co_ratio<=5, xtitle("Savings Rate") ytitle("Capital-Output Ratio") ylab(0(0.5)5)
      graph export "`output'3b_1.png", replace
  }

/*************************
* 4. Question 3d         *
*************************/
/* Use B*TFP, alpha=1/3 to determine relative productivity of top and lower 20% of countries */
clear
  if `3d' {
    use "`data'pwt1001"
    gen co_ratio = rnna/rgdpna
      label var co_ratio "Capital-Output Ratio"
    gen y_pc = rgdpna/pop
    summ y_pc
    gen Z = (y_pc/(co_ratio)^(1/2))^(2/3)

    keep if year ==2017
    
    xtile percentile = Z, nq(5)
    gen poor20 = percentile == 1
    gen rich20 = percentile == 5
    
    sum Z if poor20==1
      local poor_Z = r(mean)
    sum Z if rich20==1
      local rich_Z = r(mean)

    local Z_ratio = `poor_Z'/`rich_Z'

    disp "Relative TFP is: `Z_ratio'"
    //
  }

/*************************
* 5. Question 3e         *
*************************/

/* Fraction of income differences attributed to Z vs s */

clear
  if `3e' {
    use "`data'pwt1001"
    
    keep if year >= 1990

    gen co_ratio = rnna/rgdpna
      label var co_ratio "Capital-Output Ratio"
    egen s = mean(csh_i)
    gen y_pc = rgdpna/pop
    gen Z = (y_pc/(co_ratio)^(1/2))^(2/3)
    
    xtile percentile = y_pc, nq(5)
    gen poor20 = percentile == 1
    gen rich20 = percentile == 5

    sum y_pc if poor20 == 1
      local poor_gdp_pc = r(mean)
    sum y_pc if rich20 == 1
      local rich_gdp_pc = r(mean)

    local inc_ratio = `poor_gdp_pc'/`rich_gdp_pc'
    disp `inc_ratio'
    local s_ratio = (s^((1/3)/(2/3)))/`inc_ratio'
    local Z_ratio = (Z/`inc_ratio')


    disp "The fraction of income which can be related to savings rate s is, `s_ratio'"
    disp "The fraction of income which can be related to TFP Z is, `Z_ratio'"
  }
