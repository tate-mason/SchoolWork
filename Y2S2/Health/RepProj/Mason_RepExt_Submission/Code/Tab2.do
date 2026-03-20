/************************************************************
* Tab2.do                                                   *
* Table 2 - Sample Characteristics                          *
*                                                           *
* Args: 1 = dataPath, 2 = outPath                          *
*                                                           *
* Sample: mothers aged 21-40, 1993-1995 BRFSS.             *
* Reports means by education x kids group with t-test       *
* p-values for 1-child vs 2+ child equality.               *
************************************************************/

local dataPath "`1'"
local outPath  "`2'"

use `dataPath'BRFSS_Final_Data.dta, clear

drop if year < 1993 | year > 1995
drop if age < 21 | age > 40
drop if kids == 0 | kids == .
drop if educ == 3
drop if fips > 56

recode educ (1/2=0) (4=1), gen(college_edu)
gen income_1t = income1
gen income_2t = income2 + income3 + income4
gen income_3t = income5

// Variables and display labels
local tab2_vars "age working white_nh hispanic black_nh other married div_sep_wid never_married income_1t income_2t income_3t incomemiss excel_vgood bad_mental_30 bad_phys_30 mental_poor phys_poor"
local lab_age            "Average age"
local lab_working        "\% currently employed"
local lab_white_nh       "\% white, non-Hispanic"
local lab_black_nh       "\% black, non-Hispanic"
local lab_hispanic       "\% Hispanic"
local lab_other          "\% other race"
local lab_married        "\% married"
local lab_div_sep_wid    "\% separated/divorced/widowed"
local lab_never_married  "\% never married"
local lab_income_1t      "\% $<$\$20K"
local lab_income_2t      "\% $\geq$\$20k, \textless{}\$50K"
local lab_income_3t      "\% $\geq$ \$50k"
local lab_incomemiss     "\% income missing"
local lab_excel_vgood    "\% excellent/very good health"
local lab_bad_mental_30  "\% with any bad mental health days"
local lab_bad_phys_30    "\% with any bad physical health days"
local lab_mental_poor    "Number of bad mental health days"
local lab_phys_poor      "Number of bad physical health days"

cap mkdir `outPath'Tables
file open tab2 using `outPath'Tables/Tab2.tex, write replace
file write tab2 "\begin{table}[htbp]" _n
file write tab2 "\centering" _n
file write tab2 "\caption{Table 2: Sample Characteristics, Mothers Aged 21--40, 1993--1996 BRFSS}" _n
file write tab2 "\resizebox{\textwidth}{!}{%" _n
file write tab2 "\begin{tabular}{lcccccc}" _n
file write tab2 "\toprule" _n
file write tab2 " & \multicolumn{3}{c}{\$\leq\$ High school education} & \multicolumn{3}{c}{College graduates} \\" _n
file write tab2 "\cmidrule(lr){2-4}\cmidrule(lr){5-7}" _n
file write tab2 "Variable & 1 child & 2+ kids & \$p\$-value & 1 child & 2+ kids & \$p\$-value \\" _n
file write tab2 "\midrule" _n

// Demographics
foreach v in age working {
    sum `v' if college_edu == 0 & kids == 1
    local m_hs1 = strtrim(string(r(mean), "%9.1f"))
    sum `v' if college_edu == 0 & kids > 1
    local m_hs2 = strtrim(string(r(mean), "%9.1f"))
    reg `v' twoplus_kids if college_edu == 0, vce(cluster fips)
    local p_hs = strtrim(string(r(table)[4,1], "%9.3f")) // p-value for HS_edu
    sum `v' if college_edu == 1 & kids == 1
    local m_col1 = strtrim(string(r(mean), "%9.1f"))
    sum `v' if college_edu == 1 & kids > 1
    local m_col2 = strtrim(string(r(mean), "%9.1f"))
    reg `v' twoplus_kids if college_edu == 1, vce(cluster fips)
    local p_col = strtrim(string(r(table)[4,1], "%9.3f")) // p-value for college_edu
    file write tab2 "`lab_`v'' & `m_hs1' & `m_hs2' & `p_hs' & `m_col1' & `m_col2' & `p_col' \\" _n
}

// Race
file write tab2 "\addlinespace" _n
file write tab2 "\multicolumn{7}{l}{\textit{Race}} \\" _n
foreach v in white_nh black_nh hispanic other {
    sum `v' if college_edu == 0 & kids == 1
    local m_hs1 = strtrim(string(r(mean), "%9.3f"))
    sum `v' if college_edu == 0 & kids > 1
    local m_hs2 = strtrim(string(r(mean), "%9.3f"))
    reg `v' twoplus_kids if college_edu == 0, vce(cluster fips)
    local p_hs = strtrim(string(r(table)[4,1], "%9.3f"))
    sum `v' if college_edu == 1 & kids == 1
    local m_col1 = strtrim(string(r(mean), "%9.3f"))
    sum `v' if college_edu == 1 & kids > 1
    local m_col2 = strtrim(string(r(mean), "%9.3f"))
    reg `v' twoplus_kids if college_edu == 1, vce(cluster fips)
    local p_col = strtrim(string(r(table)[4,1], "%9.3f"))
    file write tab2 "`lab_`v'' & `m_hs1' & `m_hs2' & `p_hs' & `m_col1' & `m_col2' & `p_col' \\" _n
}

// Marital status
file write tab2 "\addlinespace" _n
file write tab2 "\multicolumn{7}{l}{\textit{Marital status}} \\" _n
foreach v in married div_sep_wid never_married {
    sum `v' if college_edu == 0 & kids == 1
    local m_hs1 = strtrim(string(r(mean), "%9.3f"))
    sum `v' if college_edu == 0 & kids > 1
    local m_hs2 = strtrim(string(r(mean), "%9.3f"))
    reg `v' twoplus_kids if college_edu == 0, vce(cluster fips)
    local p_hs = strtrim(string(r(table)[4,1], "%9.3f"))
    sum `v' if college_edu == 1 & kids == 1
    local m_col1 = strtrim(string(r(mean), "%9.3f"))
    sum `v' if college_edu == 1 & kids > 1
    local m_col2 = strtrim(string(r(mean), "%9.3f"))
    reg `v' twoplus_kids if college_edu == 1, vce(cluster fips)
    local p_col = strtrim(string(r(table)[4,1], "%9.3f"))
    file write tab2 "`lab_`v'' & `m_hs1' & `m_hs2' & `p_hs' & `m_col1' & `m_col2' & `p_col' \\" _n
}

// Family income
file write tab2 "\addlinespace" _n
file write tab2 "\multicolumn{7}{l}{\textit{Family income}} \\" _n
foreach v in income_1t income_2t income_3t incomemiss {
    sum `v' if college_edu == 0 & kids == 1
    local m_hs1 = strtrim(string(r(mean), "%9.3f"))
    sum `v' if college_edu == 0 & kids > 1
    local m_hs2 = strtrim(string(r(mean), "%9.3f"))
    reg `v' twoplus_kids if college_edu == 0, vce(cluster fips)
    local p_hs = strtrim(string(r(table)[4,1], "%9.3f"))
    sum `v' if college_edu == 1 & kids == 1
    local m_col1 = strtrim(string(r(mean), "%9.3f"))
    sum `v' if college_edu == 1 & kids > 1
    local m_col2 = strtrim(string(r(mean), "%9.3f"))
    reg `v' twoplus_kids if college_edu == 1, vce(cluster fips)
    local p_col = strtrim(string(r(table)[4,1], "%9.3f"))
    file write tab2 "`lab_`v'' & `m_hs1' & `m_hs2' & `p_hs' & `m_col1' & `m_col2' & `p_col' \\" _n
}

// Health outcomes
file write tab2 "\addlinespace" _n
file write tab2 "\multicolumn{7}{l}{\textit{Health outcome}} \\" _n
foreach v in excel_vgood bad_mental_30 bad_phys_30 mental_poor phys_poor {
    sum `v' if college_edu == 0 & kids == 1
    local m_hs1 = strtrim(string(r(mean), "%9.3f"))
    sum `v' if college_edu == 0 & kids > 1
    local m_hs2 = strtrim(string(r(mean), "%9.3f"))
    reg `v' twoplus_kids if college_edu == 0, vce(cluster fips)
    local p_hs = strtrim(string(r(table)[4,1], "%9.3f"))
    sum `v' if college_edu == 1 & kids == 1
    local m_col1 = strtrim(string(r(mean), "%9.3f"))
    sum `v' if college_edu == 1 & kids > 1
    local m_col2 = strtrim(string(r(mean), "%9.3f"))
    reg `v' twoplus_kids if college_edu == 1, vce(cluster fips)
    local p_col = strtrim(string(r(table)[4,1], "%9.3f"))
    file write tab2 "`lab_`v'' & `m_hs1' & `m_hs2' & `p_hs' & `m_col1' & `m_col2' & `p_col' \\" _n
}

// Observation counts
sum age if college_edu == 0 & kids == 1
local n_hs1  = strtrim(string(r(N), "%9.0fc"))
sum age if college_edu == 0 & kids > 1
local n_hs2  = strtrim(string(r(N), "%9.0fc"))
sum age if college_edu == 1 & kids == 1
local n_col1 = strtrim(string(r(N), "%9.0fc"))
sum age if college_edu == 1 & kids > 1
local n_col2 = strtrim(string(r(N), "%9.0fc"))
file write tab2 "\midrule" _n
file write tab2 "Observations & `n_hs1' & `n_hs2' & & `n_col1' & `n_col2' & \\" _n
file write tab2 "\bottomrule" _n
file write tab2 "\end{tabular}}" _n
file write tab2 "\begin{minipage}{\linewidth}" _n
file write tab2 "\smallskip\footnotesize" _n
file write tab2 "\textit{Notes:} The p-value is for the test of the null hypothesis that the means across the samples are the same. The test is"
file write tab2 "performed allowing for an arbitrary correlation for observations within a state." _n
file write tab2 "\end{minipage}" _n
file write tab2 "\end{table}" _n
file close tab2
