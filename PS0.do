/*******************************************
* Tate Mason - david.mason2@uga.edu        *
* Problem Set 0 - Data Work                *
* Began - Aug 14, 2024, Due - Aug 23, 2024 *
*******************************************/

/***********************
* 1. Setup             *
***********************/

		#delimit cr 		// make carriage return the command delimiter
		clear				//clear data in memory
		clear all			//clear all variables in memory
		set more off		//turn the "more" option for screen output off

		local rootPath "/Users/tate/Library/CloudStorage/Dropbox/Schoolwork/Macro1/ProblemSets/PS0"
		
		local codePath "`rootPath'/code/"
		local data "`rootPath'/Data/"
		local output "`rootPath'/Output/"
		

		set scheme white_tableau
		cap log close

/***********************
* 2. Defining Switches *
***********************/

	local P2 = 0
	local P3 = 0
	local P4 = 1
	local P5 = 0
  local P6 = 0
  local P7 = 0 
	local P8 = 0

/**********************
* 3. Problem 2        *
**********************/

if `P2' {
	set fredkey 3937d3e1a400536de448b9415c9114d9, permanently
	

	//Part A
	import fred PCEND PCES GDP, clear
	//Formatting time
	keep if _n >= 233
	//Generating desired vars
	gen PCENDS = PCEND + PCES
    label var PCENDS "Consumption of non-durables and services"
	gen pce_percent_gdp = PCENDS/GDP
    label var pce_percent_gdp "Consumption of ND and S as % of GDP"
	//Graphics
	tsset daten
  #delimit ;
	tsline pce_percent_gdp, xtitle("Time") ytitle("Percentage of GDP")
  title("Consumption of Non-Durables and Services: % of GDP")
  ;
  #delimit cr
	  graph export "`output'graph2a.png", replace
	//Part B
	import fred PCEDG GPDI GDP, clear
	//Formatting time
	keep if _n >= 233
	//Generating desired vars
	gen PCEDGI = PCEDG + GPDI
    label var PCEDGI "Consumption of durables and investment"
	gen durinv_percent_gdp = PCEDGI/GDP
    label var durinv_percent_gdp "Consumption of dur and inv as % of GDP"
	//Graphics
	tsset daten
  #delimit ;
	tsline durinv_percent_gdp, xtitle("Time") ytitle("Percentage of GDP")
  title("Consumption of Durables and Investment: % of GDP")
  ;
  #delimit cr
	 graph export "`output'graph2b.png", replace
	//Part C
	import fred FGEXPND GDP, clear
	//Formatting time
	keep if _n >= 113
	//Generating desired var
	gen exp_percent_gdp = FGEXPND/GDP
    label var exp_percent_gdp "Government expenditure as % of GDP"
	//Graphics
	tsset daten
  #delimit ;
	tsline exp_percent_gdp, xtitle("Time") ytitle("Percentage of GDP")
  title("Government Expenditure: % of GDP")
  ;
  #delimit cr
	 graph export "`output'graph2c.png", replace
	//Part D
	import fred A576RC1 GDP, clear
	//Formatting time
	keep if _n >= 233
	//Generating desired var
	gen wage_percent_gdp = A576RC1/GDP
    label var wage_percent_gdp "Wage compensation as % of GDP"
	//Graphics
	tsset daten
  #delimit ;
	tsline wage_percent_gdp, xtitle("Time") ytitle("Percentage of GDP")
  title("Wage Compensation: % of GDP")
  ;
  #delimit cr
	 graph export "`output'graph2d.png", replace
	//Part E
	import fred K1WTOTL1ES000 GDP, clear
	//Formatting time
	keep if _n >= 134
	//Generating desired var
	gen cost_output = K1WTOTL1ES000/GDP
    label var cost_output "Capital-output ratio"
	//Graphics
	tsset daten
  #delimit ; 
	tsline cost_output, xtitle("Time") ytitle("Ratio")
  title("Capital-Output Ratio")
  ;
  #delimit cr
	 graph export "`output'graph2e.png", replace
	//Part F
	import excel "`data'A939RX0Q048SBEA.xls",firstrow clear
  //Formatting time
  keep if _n>=44
  //Graphics
  tsset observation_date
  #delimit ;
  tsline A939RX0Q048SBEA, xtitle("Time") ytitle("Growth Rate")
  title("Growth Rate of Real GDP per Capita")
  ;
  #delimit cr
    graph export "`output'graph2f.png", replace
	
	//Part G
	import excel "`data'PCESVA.xls", firstrow clear
  //Formatting tme
  keep if _n>=44
  //Generating desired var
  tsset observation_date
   #delimit ;
  tsline PCESVA, xtitle("Time") ytitle("Growth Rate")
  title("Growth Rate of Real Consumption per Capita")
  ;
  #delimit cr
  graph export "`output'graph2g.png", replace
}

/**********************
* 4. Problem 3        *
**********************/

if `P3' {
  set fredkey 3937d3e1a400536de448b9415c9114d9, permanently
  //Part A
  import fred A939RX0Q048SBEA, clear
  tsset daten
  gen rGDP_pc = log(A939RX0Q048SBEA)
  reg rGDP_pc daten
  predict dt_GDP, resid
    summ dt_GDP
  tsset daten
  tsline rGDP_pc || lfit rGDP_pc daten
    graph export "`output'3aa.png", replace
  tsline dt_GDP
    graph export "`output'3ab.png", replace
  //Part B
	import fred PCEND PCES, clear
  gen PCE_NDS = PCEND + PCES
  gen rPCE_NDS = log(PCE_NDS)
  reg rPCE_NDS daten
  predict dt_PCE_NDS, resid
    summ dt_PCE_NDS
  tsset daten
  tsline rPCE_NDS || lfit rPCE_NDS daten
    graph export "`output'3ba.png", replace
  tsline dt_PCE_NDS
    graph export "`output'3bb.png", replace
  //Part C
  import fred PCEDG GPDI, clear
  gen PCE_DGI = PCEDG + GPDI
  gen rPCE_DGI = log(PCE_DGI)
  reg rPCE_DGI daten
  predict dt_PCE_DGI, resid
  tsset daten
  tsline rPCE_DGI || lfit rPCE_DGI daten
    graph export "`output'3ca.png", replace 
  tsline dt_PCE_DGI
    graph export "`output'3cb.png", replace

  //Part D
  import fred POPTHM B4701C0A222NBEA, clear
  gen HRS_PC = B4701C0A222NBEA/POPTHM
  gen l_HPC = log(HRS_PC)
  reg l_HPC daten
  predict dt_HPC, resid
  tsset daten
  tsline l_HPC || lfit l_HPC daten
    graph export "`output'3da.png", replace
  tsline dt_HPC
    graph export "`output'3db.png", replace
  
  //Part E
  import fred CLF16OV B4701C0A222NBEA, clear
  gen HRS_PW = B4701C0A222NBEA/CLF16OV
  gen l_HPW = log(HRS_PW)
  reg l_HPW daten
  predict dt_HPW, resid
  tsset daten
  tsline l_HPW || lfit l_HPW daten
    graph export "`output'3ea.png", replace
  tsline dt_HPW
    graph export "`output'3eb.png", replace
}

/**********************
* 5. Problem 4        *
**********************/

if `P4' {
  set fredkey 3937d3e1a400536de448b9415c9114d9, permanently

  //Part A
  import fred EMRATIO, clear
  tsset daten
  tsline EMRATIO, xtitle(" ") ytitle("Employment-Population Ratio") title("Employment to Population Ratio")
    graph export "`output'4a.png", replace

  //Part B
  import fred GDPC1, clear 
  gen l_GDPC1 = log(GDPC1)
  tsset daten
  tsline l_GDPC1, xtitle(" ") ytitle("Real GDP (log)") title("Log of Real GDP")
    graph export "`output'4b.png", replace

  //Part C
  import fred A939RX0Q048SBEA GDPC1 PAYEMS, clear
  gen l_RGDPC = log(A939RX0Q048SBEA)
  gen RGDPW = (GDPC1/PAYEMS)*1000000
  gen l_RGDPW = log(RGDPW)
  tsset daten
  twoway line l_RGDPC daten || line l_RGDPW daten || lfit l_RGDPC daten || lfit l_RGDPW daten
    graph export "`output'4c.png",replace
  //Part D
  import fred GDPC1, clear
  gen l_GDPC1 = log(GDPC1)
  tsset daten
  keep if _n>=233
  tsline l_GDPC1, xtitle(" ") ytitle("Real GDP (log)") title("Log of Real GDP (Since 2005)") || lfit l_GDPC1 daten
    graph export "`output'4da.png", replace
  import fred A939RX0Q048SBEA GDPC1 PAYEMS, clear
  gen l_RGDPC = log(A939RX0Q048SBEA)
  gen RGDPW = (GDPC1/PAYEMS)*1000000
  gen l_RGDPW = log(RGDPW)
  keep if _n>=689
  tsset daten
  twoway line l_RGDPC daten || line l_RGDPW daten || lfit l_RGDPC daten || lfit l_RGDPW daten
    graph export "`output'4db.png", replace
}

/**********************
* 6. Problem 5        *
**********************/
if `P5' {
  //c
  import fred A576RC1 GDP, clear
  browse
  gen alpha = A576RC1/GDP
  mean alpha
  //.4599031
  //d
  import fred K1WTOTL1ES000 POPTHM B4701C0A222NBEA A576RC1 GDP, clear
  gen HRS_PC = B4701C0A222NBEA/POPTHM
  gen TFP = GDP/((K1WTOTL1ES000^0.4599031)*(HRS_PC^(1-0.4599031)))
  disp TFP
  //3.179566
  //e
  import fred A939RX0Q048SBEA K1WTOTL1ES000 POPTHM B4701C0A222NBEA A576RC1 GDP, clear
  gen HRS_PC = B4701C0A222NBEA/POPTHM
  gen TFP = GDP/((K1WTOTL1ES000^0.4599031)*(HRS_PC^(1-0.4599031)))
  tsset daten
  gen rGDP_pc = log(A939RX0Q048SBEA)
  reg rGDP_pc daten
  predict dt_GDP, resid
    summ dt_GDP
  gen l_TFP = log(TFP)
  reg l_TFP daten
    predict r_TFP, resid
    summ r_TFP
  tsset daten
  tsline l_TFP || lfit l_TFP daten
    graph export "`output'5e.png", replace
  tsline rGDP_pc r_TFP
    graph export "`output'5e2.png",replace
}
/**********************
* 7. Problem 6        *
**********************/

if `P6' {
 
  //Part A
  import delimited "`data'h_transpose.csv", clear
  browse
  tsset year
#delimit ; 
  tsline hgdp, xtitle(" ") ytitle("Percent of GDP") 
  title("Healthcare Expenditure as % of GDP")
  ;
#delimit cr
    graph export "`output'graph6.png",replace
}

/**********************
* 8. Problem 7        *
**********************/

if `P7' {
  import excel `data'PWT_DA_2019.XLSX, firstrow
  browse
//Part A
  gen output_norm = OutputsiderealGDPatcurrent/20566034
  gen cap_norm = CapitalstockatcurrentPPPsi/69059088
  gen alpha = 1/3
  gen l_output_norm = log(output_norm)
  gen l_cap_norm = log(cap_norm)
  gen cap_alpha = cap_norm^(alpha)
  gen l_cap_alpha = log(cap_alpha)
  scatter l_output_norm l_cap_norm || scatter l_cap_alpha l_cap_norm
    graph export "`output'7a.png",replace
//Part B
  gen TFP = l_output_norm/l_cap_alpha
  gen l_TFP = log(TFP)
  twoway line l_TFP l_output_norm
    graph export "`output'7b.png",replace
//Part C
  gen y = TFP*cap_alpha
  gen log_y = log(y)

  tabstat l_output_norm, s(variance)
  tabstat l_cap_alpha, s(variance)
  gen success_1 = .5618337/5.103276

  summ output_norm, detail
  summ cap_alpha, detail
  gen success_2 = ((0.4652415/.062057)/(.0590708/.000174))
  disp success_1
  disp success_2

    // Success 1: 0.9055637
    // Success 2: 1.1380625
}


/**********************
* 9. Problem 8        *
**********************/

if `P8' {
  import excel "~/Downloads/P_Data_Extract_From_World_Development_Indicators.xlsx", firstrow clear
    label var AFFVA "Agriculture"
    label var MANVA "Manufacturing"
    label var SERVVA "Service"
  tsset Time
  #delimit ;
  tsline AFFVA MANVA SERVVA, xtitle(" ") ytitle("Share of GDP") 
  title("Turkish Agriculture, Manufacturing, Service as % GDP") legend(ring(0) col(1))
  ;
  #delimit cr
    graph export "`output'p8.png", replace
}
