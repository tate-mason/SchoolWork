
label define ER13001L  ///
       1 "Release number 1 - August 2001"  ///
       2 "Release number 2 - October 2001"  ///
       3 "Release number 3 - January 2002"  ///
       4 "Release number 4 - May 2008"  ///
       5 "Release number 5 - November 2013"  ///
       6 "Release number 6 - February 2014"  ///
       7 "Release number 7 - January 2016"  ///
       8 "Release number 8 - November 2017"  ///
       9 "Release number 9 - June 2023"

label define ER13011L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER13601L `n' "Actual number of weeks"  , modify
}
label define ER13601L       98 "DK"  , modify
label define ER13601L       99 "NA; refused"  , modify
label define ER13601L        0 "Inap.:  working now or only temporarily laid off; never worked; last worked before 1998; not out of labor force; did not report weeks missed"  , modify

label define ER14428L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER15937L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       8 "DK"  ///
       9 "NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or no education"

label define ER15952L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or no education; no college; completed less than one year"

label define ER15953L  ///
       1 "AA; Associate of Arts"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      98 "DK"  ///
      99 "NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or no education; no college; completed less than one year; no college degree"

label define ER17001L  ///
       1 "Release number 1 - November 2002"  ///
       2 "Release number 2 - May 2008"  ///
       3 "Release number 3 - November 2013"  ///
       4 "Release number 4 - February 2014"  ///
       5 "Release number 5 - January 2016"  ///
       6 "Release number 6 - November 2017"  ///
       7 "Release number 7 - June 2023"

label define ER17014L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER17375L `n' "Actual number of weeks"  , modify
}
label define ER17375L       98 "DK"  , modify
label define ER17375L       99 "NA; refused"  , modify
label define ER17375L        0 "Inap.:  not working for money now; not out of labor force; did not report weeks missed"  , modify

forvalues n = 1/52 {
    label define ER17657L `n' "Actual number of weeks"  , modify
}
label define ER17657L       98 "DK"  , modify
label define ER17657L       99 "NA; refused"  , modify
label define ER17657L        0 "Inap.:  working now or only temporarily laid off; never worked; last worked before 2000; not out of labor force; did not report weeks missed"  , modify

label define ER18579L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER19998L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       8 "DK"  ///
       9 "NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or no education"

label define ER20013L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or no education; no college; completed less than one year"

label define ER20014L  ///
       1 "AA; Associate of Arts"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      98 "DK"  ///
      99 "NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or no education; no college; completed less than one year; no college degree"

label define ER21001L  ///
       1 "Release number 1 - December 2004"  ///
       2 "Release number 2 - October 2005"  ///
       3 "Release number 3 - November 2005"  ///
       4 "Release number 4 - May 2008"  ///
       5 "Release number 5 - November 2013"  ///
       6 "Release number 6 - February 2014"  ///
       7 "Release number 7 - January 2016"  ///
       8 "Release number 8 - November 2017"  ///
       9 "Release number 9 - June 2023"

label define ER21018L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER21339L `n' "Actual number of weeks"  , modify
}
label define ER21339L       98 "DK"  , modify
label define ER21339L       99 "NA; refused"  , modify
label define ER21339L        0 "Inap.:  not out of the labor force (ER21336=5, 8, or 9); did not report in terms of weeks"  , modify

forvalues n = 1/52 {
    label define ER21589L `n' "Actual number of weeks"  , modify
}
label define ER21589L       98 "DK"  , modify
label define ER21589L       99 "NA; refused"  , modify
label define ER21589L        0 `"Inap.:  no wife/"wife" in FU (ER21019=0); not out of the labor force (ER21586=5, 8, or 9); did not report in terms of weeks"'  , modify

label define ER21948L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER23435L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       4 "College level only"  ///
       9 "NA; DK"  ///
       0 "Inap.:  educated outside the U.S. only or no education"

label define ER23450L  ///
       1 "Yes"  ///
       5 "No"  ///
       9 "NA; DK"  ///
       0 "Inap.:  educated outside the U.S. only or no education; no college; completed less than one year"

label define ER23451L  ///
       1 "AA; Associate of Arts"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      98 "DK"  ///
      99 "NA"  ///
       0 "Inap.:  educated outside the U.S. only or no education; no college; completed less than one year; no college degree"

label define ER25001L  ///
       1 "Release number 1, March 2007"  ///
       2 "Release number 2, May 2007"  ///
       3 "Release number 3, November 2013"  ///
       4 "Release number 4, February 2014"  ///
       5 "Release number 5, January 2016"  ///
       6 "Release number 6, November 2017"  ///
       7 "Release number 7, June 2023"

label define ER25018L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER25328L `n' "Actual number of weeks"  , modify
}
label define ER25328L       98 "DK"  , modify
label define ER25328L       99 "NA; refused"  , modify
label define ER25328L        0 "Inap.:  not out of the labor force (ER25325=5, 8, or 9); did not report in terms of weeks"  , modify

forvalues n = 1/52 {
    label define ER25586L `n' "Actual number of weeks"  , modify
}
label define ER25586L       98 "DK"  , modify
label define ER25586L       99 "NA; refused"  , modify
label define ER25586L        0 `"Inap.:  no wife/"wife" in FU (ER25019=0); not out of the labor force (ER25583=5, 8, or 9); did not report in terms of weeks"'  , modify

label define ER25929L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER27402L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       4 "College level only"  ///
       9 "NA; DK"  ///
       0 "Inap.:  educated outside the U.S. only or no education"

label define ER27417L  ///
       1 "Yes"  ///
       5 "No"  ///
       9 "NA; DK"  ///
       0 "Inap.:  educated outside the U.S. only or no education; no college; completed less than one year"

label define ER27418L  ///
       1 "AA; Associate of Arts"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      98 "DK"  ///
      99 "NA"  ///
       0 "Inap.:  educated outside the U.S. only or no education; no college; completed less than one year; no college degree"

label define ER36001L  ///
       1 "Release number 1, June 2009"  ///
       2 "Release number 2, October 2009"  ///
       3 "Release number 3, January 2012"  ///
       4 "Release number 4, December 2013"  ///
       5 "Release number 5, February 2014"  ///
       6 "Release number 6, January 2016"  ///
       7 "Release number 7, November 2017"  ///
       8 "Release number 8, June 2023"

label define ER36018L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER36333L `n' "Actual number of weeks"  , modify
}
label define ER36333L       98 "DK"  , modify
label define ER36333L       99 "NA; refused"  , modify
label define ER36333L        0 "Inap.: not out of the labor force (ER36330=5, 8, or 9); did not report in terms of weeks"  , modify

forvalues n = 1/52 {
    label define ER36591L `n' "Actual number of weeks"  , modify
}
label define ER36591L       98 "DK"  , modify
label define ER36591L       99 "NA; refused"  , modify
label define ER36591L        0 `"Inap.: no wife/"wife" in FU (ER36019=0); not out of the labor force (ER36588=5, 8, or 9); did not report in terms of weeks"'  , modify

label define ER36947L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER40574L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       4 "College level only"  ///
       9 "NA; DK"  ///
       0 "Inap.: educated outside the U.S. only or no education"

label define ER40589L  ///
       1 "Yes"  ///
       5 "No"  ///
       9 "NA; DK"  ///
       0 "Inap.: educated outside the U.S. only or no education; no college; completed less than one year"

label define ER40590L  ///
       1 "AA; Associate of Arts"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      98 "DK"  ///
      99 "NA"  ///
       0 "Inap.: educated outside the U.S. only or no education; no college; completed less than one year; no college degree"

label define ER42001L  ///
       1 "Release number 1, July 2011"  ///
       2 "Release number 2, November 2013"  ///
       3 "Release number 3, February 2014"  ///
       4 "Release number 4, January 2016"  ///
       5 "Release number 5, November 2017"  ///
       6 "Release number 6, June 2023"

label define ER42018L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER42360L `n' "Actual number of weeks"  , modify
}
label define ER42360L       98 "DK"  , modify
label define ER42360L       99 "NA; refused"  , modify
label define ER42360L        0 "Inap.:  not out of the labor force (ER42357=5, 8, or 9); did not report in terms of weeks"  , modify

forvalues n = 1/52 {
    label define ER42612L `n' "Actual number of weeks"  , modify
}
label define ER42612L       98 "DK"  , modify
label define ER42612L       99 "NA; refused"  , modify
label define ER42612L        0 `"Inap.:  no wife/"wife" in FU (ER42019=0) (ER42019=0); not out of the labor force (ER42609=5, 8, or 9); did not report in terms of weeks"'  , modify

label define ER42938L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER46552L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       4 "College level only"  ///
       9 "DK; NA"  ///
       0 "Inap.:  educated outside the U.S. only or no education"

label define ER46567L  ///
       1 "Yes"  ///
       5 "No"  ///
       9 "DK; NA"  ///
       0 "Inap.:  educated outside the U.S. only or no education; no college; completed less than one year"

label define ER46568L  ///
       1 "AA; Associate of Arts"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      98 "DK"  ///
      99 "NA"  ///
       0 "Inap.:  educated outside the U.S. only or no education; no college; completed less than one year; no college degree"

label define ER47301L  ///
       1 "Release number 1, July 2013"  ///
       2 "Release number 2, November 2013"  ///
       3 "Release number 3, February 2014"  ///
       4 "Release number 4, January 2016"  ///
       5 "Release number 5, November 2017"  ///
       6 "Release number 6, June 2023"

label define ER47318L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER47673L `n' "Actual number of weeks"  , modify
}
label define ER47673L       98 "DK"  , modify
label define ER47673L       99 "NA; refused"  , modify
label define ER47673L        0 "Inap.:  did not report in terms of weeks; not out of the labor force (ER47670=5); NA, DK, RF whether out of labor force (ER47670=8 or 9)"  , modify

forvalues n = 1/52 {
    label define ER47930L `n' "Actual number of weeks"  , modify
}
label define ER47930L       98 "DK"  , modify
label define ER47930L       99 "NA; refused"  , modify
label define ER47930L        0 `"Inap.: did not report in terms of weeks; no Wife/"Wife" in FU (ER47319=0); not out of the labor force (ER47927=5); NA, DK, RF whether out of labor force (ER47927=8 or 9)"'  , modify

label define ER48260L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER51913L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       4 "College level only"  ///
       8 "DK"  ///
       9 "NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER51912=2 or 5); NA, RF where Head received education (ER51912=9)"

label define ER51928L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER51912=2 or 5); NA, RF where Head received education (ER51912=9); did not attend college (ER51924=5); NA, DK, RF whether attended college (ER51924=8 or 9); completed less than one year of college (ER51927=0)"

label define ER51929L  ///
       1 "AA; Associate of Arts"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      98 "DK"  ///
      99 "NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER51912=2 or 5); NA, RF where Head received education (ER51912=9); did not attend college (ER51924=5); NA, DK, RF whether attended college (ER51924=8 or 9); completed less than one year of college (ER51927=0); did not receive a college degree (ER51928=5); NA, DK, RF whether received a college degree (ER51928=8 or 9)"

label define ER53001L  ///
       1 "Release number 1, May 2015"  ///
       2 "Release number 2, January 2016"  ///
       3 "Release number 3, November 2017"  ///
       4 "Release number 4, June 2023"

label define ER53018L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER53373L `n' "Actual number of weeks"  , modify
}
label define ER53373L       98 "DK"  , modify
label define ER53373L       99 "NA; refused"  , modify
label define ER53373L        0 "Inap.:  did not report in terms of weeks; not out of the labor force (ER53370=5); DK, NA, or RF whether out of labor force (ER53370=8 or 9)"  , modify

forvalues n = 1/52 {
    label define ER53636L `n' "Actual number of weeks"  , modify
}
label define ER53636L       98 "DK"  , modify
label define ER53636L       99 "NA; refused"  , modify
label define ER53636L        0 `"Inap.: did not report in terms of weeks; no Wife/"Wife" in FU (ER54305=5); not out of the labor force (ER53633=5); DK, NA, or RF whether out of labor force (ER53633=8 or 9)"'  , modify

label define ER53954L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER57669L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       4 "College level only"  ///
       9 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER57668=2 or 5); NA, RF where Head received education (ER57668=9)"

label define ER57684L  ///
       1 "Yes"  ///
       5 "No"  ///
       9 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER57668=2 or 5); NA, RF where Head received education (ER57668=9); did not attend college (ER57680=5); DK, NA, or RF whether attended college (ER57680=8 or 9); completed less than one year of college (ER57683=0)"

label define ER57685L  ///
       1 "AA; Associate of Arts"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      98 "DK"  ///
      99 "NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER57668=2 or 5); NA, RF where Head received education (ER57668=9); did not attend college (ER57680=5); DK, NA, or RF whether attended college (ER57680=8 or 9); completed less than one year of college (ER57683=0); did not receive a college degree (ER57684=5); DK, NA, or RF whether received a college degree (ER57684=8 or 9)"

label define ER60001L  ///
       1 "Release number 1, May 2017"  ///
       2 "Release number 2, June 2023"

label define ER60018L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER60388L `n' "Actual number of weeks"  , modify
}
label define ER60388L       98 "DK"  , modify
label define ER60388L       99 "NA; refused"  , modify
label define ER60388L        0 "Inap.:  did not report in terms of weeks; not out of the labor force (ER60385=5); DK, NA, or RF whether out of labor force (ER60385=8 or 9)"  , modify

forvalues n = 1/52 {
    label define ER60651L `n' "Actual number of weeks"  , modify
}
label define ER60651L       98 "DK"  , modify
label define ER60651L       99 "NA; refused"  , modify
label define ER60651L        0 "Inap.: did not report in terms of weeks; no Spouse/Partner in FU (ER61347=5); not out of the labor force (ER60648=5); DK, NA, or RF whether out of labor force (ER60648=8 or 9)"  , modify

label define ER61013L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER64821L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       4 "College level only"  ///
       9 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER64820=2 or 5); NA or RF where Head received education (ER64820=9)"

label define ER64836L  ///
       1 "Yes"  ///
       5 "No"  ///
       9 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER64820=2 or 5); NA or RF where Head received education (ER64820=9); did not attend college (ER64832=5); DK, NA, or RF whether attended college (ER64832=9); completed less than one year of college (ER64835=0)"

label define ER64837L  ///
       1 "Associate of Arts; AA"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      99 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER64820=2 or 5); NA or RF where Head received education (ER64820=9); did not attend college (ER64832=5); DK, NA, or RF whether attended college (ER64832=9); completed less than one year of college (ER64835=0); did not receive a college degree (ER64836=5); DK, NA, or RF whether received a college degree (ER64836=9)"

label define ER66001L  ///
       1 "Release number 1, February 2019"  ///
       2 "Release number 2, August 2019"  ///
       3 "Release number 3, June 2023"

label define ER66018L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER66391L `n' "Actual number of weeks"  , modify
}
label define ER66391L       98 "DK"  , modify
label define ER66391L       99 "NA; refused"  , modify
label define ER66391L        0 "Inap.:  did not report in terms of weeks; not out of the labor force (ER66388=5); DK, NA, or RF whether out of labor force (ER66388=8 or 9)"  , modify

forvalues n = 1/52 {
    label define ER66666L `n' "Actual number of weeks"  , modify
}
label define ER66666L       98 "DK"  , modify
label define ER66666L       99 "NA; refused"  , modify
label define ER66666L        0 "Inap.:  did not report in terms of weeks; not out of the labor force (ER66663=5); DK, NA, or RF whether out of labor force (ER66663=8 or 9); no Spouse/Partner in FU (ER67399=5)"  , modify

label define ER67065L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER70755L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       4 "College level only"  ///
       9 "DK; NA; refused"  ///
       0 "Inap.:  no Spouse/Partner in FU (ER67399=5); educated outside the U.S. only or had no education (ER70754=2 or 5); NA or RF where Spouse/Partner received education (ER70754=9)"

label define ER70908L  ///
       1 "Yes"  ///
       5 "No"  ///
       9 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER70892=2 or 5); NA or RF where Reference Person received education (ER70892=9); did not attend college (ER70904=5); DK, NA, or RF whether attended college (ER70904=9); completed less than one year of college (ER70907=0)"

label define ER70909L  ///
       1 "Associate of Arts; AA"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      99 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER70892=2 or 5); NA or RF where Reference Person received education (ER70892=9); did not attend college (ER70904=5); DK, NA, or RF whether attended college (ER70904=9); completed less than one year of college (ER70907=0); did not receive a college degree (ER70908=5); DK, NA, or RF whether received a college degree (ER70908=9)"

label define ER72001L  ///
       1 "Release number 1, March 2021"

label define ER72018L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER72391L `n' "Actual number of weeks"  , modify
}
label define ER72391L       98 "DK"  , modify
label define ER72391L       99 "NA; refused"  , modify
label define ER72391L        0 "Inap.:  did not report in terms of weeks; not out of the labor force (ER72388=5); DK, NA, or RF whether out of labor force (ER72388=8 or 9)"  , modify

forvalues n = 1/52 {
    label define ER72668L `n' "Actual number of weeks"  , modify
}
label define ER72668L       98 "DK"  , modify
label define ER72668L       99 "NA; refused"  , modify
label define ER72668L        0 "Inap.:  did not report in terms of weeks; not out of the labor force (ER72665=5); DK, NA, or RF whether out of labor force (ER72665=8 or 9); no Spouse/Partner in FU (ER73422=5)"  , modify

label define ER73088L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER76763L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       4 "College level only"  ///
       9 "DK; NA; refused"  ///
       0 "Inap.:  no Spouse/Partner in FU (ER73422=5); educated outside the U.S. only or had no education (ER76762=2 or 5); NA or RF where Spouse/Partner received education (ER76762=9)"

label define ER76923L  ///
       1 "Yes"  ///
       5 "No"  ///
       9 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER76907=2 or 5); NA or RF where Reference Person received education (ER76907=9); did not attend college (ER76919=5); DK, NA, or RF whether attended college (ER76919=9); completed less than one year of college (ER76922=0)"

label define ER76924L  ///
       1 "Associate of Arts; AA"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      99 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER76907=2 or 5); NA or RF where Reference Person received education (ER76907=9); did not attend college (ER76919=5); DK, NA, or RF whether attended college (ER76919=9); completed less than one year of college (ER76922=0); did not receive a college degree (ER76923=5); DK, NA, or RF whether received a college degree (ER76923=9)"

label define ER78001L  ///
       1 "Release number 1, June 2023"  ///
       2 "Release number 2, October 2023"  ///
       3 "Release number 3, May 2025"

label define ER78018L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER78430L `n' "Actual number of weeks"  , modify
}
label define ER78430L       98 "DK"  , modify
label define ER78430L       99 "NA; refused"  , modify
label define ER78430L        0 "Inap.:  did not report in terms of weeks; not out of the labor force (ER78427=5); DK, NA, or RF whether out of labor force (ER78427=8 or 9)"  , modify

forvalues n = 1/52 {
    label define ER78744L `n' "Actual number of weeks"  , modify
}
label define ER78744L       98 "DK"  , modify
label define ER78744L       99 "NA; refused"  , modify
label define ER78744L        0 "Inap.:  did not report in terms of weeks; not out of the labor force (ER78741=5); DK, NA, or RF whether out of labor force (ER78741=8 or 9); no Spouse/Partner in FU (ER79524=5)"  , modify

label define ER79165L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER81028L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       4 "College level only"  ///
       9 "DK; NA; refused"  ///
       0 "Inap.:  no Spouse/Partner in FU (ER79524=5); educated outside the U.S. only or had no education (ER81027=2 or 5); NA or RF where Spouse/Partner received education (ER81027=9)"

label define ER81170L  ///
       1 "Yes"  ///
       5 "No"  ///
       9 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER81154=2 or 5); NA or RF where Reference Person received education (ER81154=9); did not attend college (ER81166=5); DK, NA, or RF whether attended college (ER81166=9); completed less than one year of college (ER81169=0)"

label define ER81171L  ///
       1 "Associate of Arts; AA"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      99 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER81154=2 or 5); NA or RF where Reference Person received education (ER81154=9); did not attend college (ER81166=5); DK, NA, or RF whether attended college (ER81166=9); completed less than one year of college (ER81169=0); did not receive a college degree (ER81170=5); DK, NA, or RF whether received a college degree (ER81170=9)"

label define ER82001L  ///
       1 "Release number 1, May 2025"

label define ER82019L  ///
       1 "Male"  ///
       2 "Female"

forvalues n = 1/52 {
    label define ER82417L `n' "Actual number of weeks"  , modify
}
label define ER82417L       98 "DK"  , modify
label define ER82417L       99 "NA; refused"  , modify
label define ER82417L        0 "Inap.:  did not report in terms of weeks; not out of the labor force (ER82414=5); DK, NA, or RF whether out of labor force (ER82414=8 or 9)"  , modify

forvalues n = 1/52 {
    label define ER82736L `n' "Actual number of weeks"  , modify
}
label define ER82736L       98 "DK"  , modify
label define ER82736L       99 "NA; refused"  , modify
label define ER82736L        0 "Inap.:  did not report in terms of weeks; not out of the labor force (ER82733=5); DK, NA, or RF whether out of labor force (ER82733=8 or 9); no Spouse/Partner in FU (ER83493=5)"  , modify

label define ER83140L  ///
       1 "Yes"  ///
       5 "No"  ///
       8 "DK"  ///
       9 "NA; refused"

label define ER85005L  ///
       1 "Graduated from high school"  ///
       2 "Got a GED"  ///
       3 "Neither"  ///
       4 "College level only"  ///
       9 "DK; NA; refused"  ///
       0 "Inap.:  no Spouse/Partner in FU (ER83493=5); educated outside the U.S. only or had no education (ER85004=2 or 5); NA or RF where Spouse/Partner received education (ER85004=9)"

label define ER85147L  ///
       1 "Yes"  ///
       5 "No"  ///
       9 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER85131=2 or 5); NA or RF where Reference Person received education (ER85131=9); did not attend college (ER85143=5); DK, NA, or RF whether attended college (ER85143=9); completed less than one year of college (ER85146=0)"

label define ER85148L  ///
       1 "Associate of Arts; AA"  ///
       2 "Bachelor of Arts/Science/Letters; BA; BS"  ///
       3 "Master of Arts/Science; MA; MS; MBA"  ///
       4 "Doctorate; Ph.D. (except codes 5 and 6)"  ///
       5 "LLB; JD (law degrees)"  ///
       6 "MD; DDS; DVM; DO (medical degrees)"  ///
       8 "Honorary degree"  ///
      97 "Other"  ///
      99 "DK; NA; refused"  ///
       0 "Inap.:  educated outside the U.S. only or had no education (ER85131=2 or 5); NA or RF where Reference Person received education (ER85131=9); did not attend college (ER85143=5); DK, NA, or RF whether attended college (ER85143=9); completed less than one year of college (ER85146=0); did not receive a college degree (ER85147=5); DK, NA, or RF whether received a college degree (ER85147=9)"

label values ER13001    ER13001L
label values ER13011    ER13011L
label values ER13601    ER13601L
label values ER14428    ER14428L
label values ER15937    ER15937L
label values ER15952    ER15952L
label values ER15953    ER15953L
label values ER17001    ER17001L
label values ER17014    ER17014L
label values ER17375    ER17375L
label values ER17657    ER17657L
label values ER18579    ER18579L
label values ER19998    ER19998L
label values ER20013    ER20013L
label values ER20014    ER20014L
label values ER21001    ER21001L
label values ER21018    ER21018L
label values ER21339    ER21339L
label values ER21589    ER21589L
label values ER21948    ER21948L
label values ER23435    ER23435L
label values ER23450    ER23450L
label values ER23451    ER23451L
label values ER25001    ER25001L
label values ER25018    ER25018L
label values ER25328    ER25328L
label values ER25586    ER25586L
label values ER25929    ER25929L
label values ER27402    ER27402L
label values ER27417    ER27417L
label values ER27418    ER27418L
label values ER36001    ER36001L
label values ER36018    ER36018L
label values ER36333    ER36333L
label values ER36591    ER36591L
label values ER36947    ER36947L
label values ER40574    ER40574L
label values ER40589    ER40589L
label values ER40590    ER40590L
label values ER42001    ER42001L
label values ER42018    ER42018L
label values ER42360    ER42360L
label values ER42612    ER42612L
label values ER42938    ER42938L
label values ER46552    ER46552L
label values ER46567    ER46567L
label values ER46568    ER46568L
label values ER47301    ER47301L
label values ER47318    ER47318L
label values ER47673    ER47673L
label values ER47930    ER47930L
label values ER48260    ER48260L
label values ER51913    ER51913L
label values ER51928    ER51928L
label values ER51929    ER51929L
label values ER53001    ER53001L
label values ER53018    ER53018L
label values ER53373    ER53373L
label values ER53636    ER53636L
label values ER53954    ER53954L
label values ER57669    ER57669L
label values ER57684    ER57684L
label values ER57685    ER57685L
label values ER60001    ER60001L
label values ER60018    ER60018L
label values ER60388    ER60388L
label values ER60651    ER60651L
label values ER61013    ER61013L
label values ER64821    ER64821L
label values ER64836    ER64836L
label values ER64837    ER64837L
label values ER66001    ER66001L
label values ER66018    ER66018L
label values ER66391    ER66391L
label values ER66666    ER66666L
label values ER67065    ER67065L
label values ER70755    ER70755L
label values ER70908    ER70908L
label values ER70909    ER70909L
label values ER72001    ER72001L
label values ER72018    ER72018L
label values ER72391    ER72391L
label values ER72668    ER72668L
label values ER73088    ER73088L
label values ER76763    ER76763L
label values ER76923    ER76923L
label values ER76924    ER76924L
label values ER78001    ER78001L
label values ER78018    ER78018L
label values ER78430    ER78430L
label values ER78744    ER78744L
label values ER79165    ER79165L
label values ER81028    ER81028L
label values ER81170    ER81170L
label values ER81171    ER81171L
label values ER82001    ER82001L
label values ER82019    ER82019L
label values ER82417    ER82417L
label values ER82736    ER82736L
label values ER83140    ER83140L
label values ER85005    ER85005L
label values ER85147    ER85147L
label values ER85148    ER85148L
