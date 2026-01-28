*  This code can be used to generate the sample statistics in Table 1 of the draft.


drop if nchild==0
drop if age<21
drop if age>40
drop if sex==1
gen twoplus=nchild>=2
gen whitenh=race==100 & hispan==0
gen blacknh=race==200 & hispan==0
gen hispanic=hispan>0

gen hsorless=educ<=73

gen nohs=educ<72
gen college=educ>=111
gen post96=year>1996



gen EITC=eitcred>0


* Percentage Recieving the EITC, One Child, HS or Less
sum EITC if post96==1 & twoplus==0 & hsorless==1 [aw=wtsupp]
sum EITC if post96==0 & twoplus==0 & hsorless==1 [aw=wtsupp]

* Percentage Recieving the EITC, Two Children, HS or Less
sum EITC if post96==1 & twoplus==1 & hsorless==1 [aw=wtsupp]
sum EITC if post96==0 & twoplus==1 & hsorless==1 [aw=wtsupp]


* Amount of EITC Credit, Entire Population, One Child, HS or Less
sum eitcred if post96==1 & twoplus==0 & hsorless==1 [aw=wtsupp]
sum eitcred if post96==0 & twoplus==0 & hsorless==1 [aw=wtsupp]

* Amount of EITC Credit, Entire Population, Two Children, HS or Less
sum eitcred if post96==1 & twoplus==1 & hsorless==1 [aw=wtsupp]
sum eitcred if post96==0 & twoplus==1 & hsorless==1 [aw=wtsupp]


* Amount of EITC Credit, EITC Recipient Population, One Child, HS or Less
sum eitcred if post96==1 & twoplus==0 & hsorless==1 & EITC==1 [aw=wtsupp]
sum eitcred if post96==0 & twoplus==0 & hsorless==1 & EITC==1 [aw=wtsupp]

* Amount of EITC Credit, EITC Recipient Population, Two Children, HS or Less
sum eitcred if post96==1 & twoplus==1 & hsorless==1 & EITC==1  [aw=wtsupp]
sum eitcred if post96==0 & twoplus==1 & hsorless==1 & EITC==1 [aw=wtsupp]




*  Percentage Recieving the EITC, One Child, college
sum EITC if post96==1 & twoplus==0 & college==1 [aw=wtsupp]
sum EITC if post96==0 & twoplus==0 & college==1 [aw=wtsupp]

* Percentage Recieving the EITC, Two Children, college
sum EITC if post96==1 & twoplus==1 & college==1 [aw=wtsupp]
sum EITC if post96==0 & twoplus==1 & college==1 [aw=wtsupp]


* Amount of EITC Credit, Entire Population, One Child,college
sum eitcred if post96==1 & twoplus==0 & college==1 [aw=wtsupp]
sum eitcred if post96==0 & twoplus==0 & college==1 [aw=wtsupp]

* Amount of EITC Credit, Entire Population, Two Children, college
sum eitcred if post96==1 & twoplus==1 & college==1 [aw=wtsupp]
sum eitcred if post96==0 & twoplus==1 & college==1 [aw=wtsupp]


* Amount of EITC Credit, EITC Recipient Population, One Child, college
sum eitcred if post96==1 & twoplus==0 & college==1 & EITC==1 [aw=wtsupp]
sum eitcred if post96==0 & twoplus==0 & college==1 & EITC==1 [aw=wtsupp]

* Amount of EITC Credit, EITC Recipient Population, Two Children, college
sum eitcred if post96==1 & twoplus==1 & college==1 & EITC==1  [aw=wtsupp]
sum eitcred if post96==0 & twoplus==1 & college==1 & EITC==1 [aw=wtsupp]


