---
title: "Problem Set 3: RDD Paper Reviews"
author: "Tate Mason"
---

# Problem Set 3: RDD Paper Reviews
Due: 11:59 PM on Sunday, November 9, 2025

## Paper 1: "Do School Entry Laws Affect Educational Attainment and Labor Market Outcomes? Evidence from the U.S." by Dobkin and Ferreira (2010)"

### Question 1:
What is the research question?

Dobkin and Ferreira investigate whether school entry laws, which determine the age at which children can start school, have significant effects on educational attainment and subsequent labor market outcomes in the United States.

### Question 2:
Why is it important to answer this question?

This is an important question because education attainment is tightly interwoven with social and economic mobility. Having a basis with which we can test a policy's validity is very useful.

### Question 3:
What are key endogeneity concerns?

Chiefly, there should be concern that parents will select into a state with laws which best suit their needs. For many, school is childcare, and thus if they move to California, which allows for 4 year olds to enroll as long as they turn 5 by Dec. 2, they can access that care earlier. Further, this illuminates a story of individuals who may have less resources, thus necessitating children to, potentially, need to leave schooling to join the workforce early. These are two examples, but I am sure more exist.

### Question 4: 
Argument for RDD relevance, and supporting evidence?

This is relevant since, if one is born before the cutoff date, at least some parents will enroll their child into school. This is supported by later tables which break the results out by race, from which they infer that black and hispanic parents are using school as a substitute for childcare.

### Question 5:
Argument for RDD validity, and supporting evidence?

This is valid since, firstly, one's birth date has no bearing on adult labor/education outcomes through any channel other than by school entry date. Thus, units born Dec. 2 and Dec. 3 should have no systematic differences aside from their birthdays. Further, it is valid because one cannot choose their birth date exactly, satisfying random assignment.

### Question 6:
Argument for RDD monotonicity, and supporting evidence?

The RDD is monotonic because if someone is born before the cutoff date, the likelihood of enrollment increases. This is easy to rationalize, unless someone has outlier reasons to hold their child out of school, they will enroll them once they are of the appropriate age.

### Question 7:
RDD estimates LATE, can 1 and 2 hold for LATE instead of ATE?

Yes, since we assume away defiers, this holds for the LATE since all agents comply. One cannot defy by enrolling when ineligible, thus we only see the LATE.

### Question 8:
Criticism of validity and monotonicity?

Validity could be challenged by parents planning their birth into a window to maximize probability of having a child able to enter school at 4 (in CA). Monotonicity is more difficult here, but perhaps there are parents who systematically delay school enrollment for their child for some unobserved reason, thus violating monotonicity.

### Question 9:
Additional evidence to assuage concerns in (8)?

I think these concerns are a bit fringe, and honestly were difficult to come up with. Perhaps a distribution of birth dates would have been good for the validity criticism.

### Question 10:
Strongest part of the paper?

I think this paper's strength lies in the simplicity of its instrument. As seen in Angrist and Krueger, birth time is a great instrument. Dobkin and Ferreira contribute cleverly by leveraging policy heterogeneity around school enrollment. It is easy to understand and relatively strong.

### Question 11:
Weakest part of the paper?

I think this paper is weak in its lack of splitting out of groups. It would be good to see by more than the racial and educational attainment groups. More income based cuts would have been good i.e. poverty line closeness, housing situation etc.


## Paper 2: "Randomized Experiments from Non-Random Selection in U.S. House Elections - Lee (2007)"

### Question 1:
What is the research question?

How does election to the US House of Representatives in period $t-1$ impact one's chance to be re-elected in period $t$? In other words, how does what Lee terms "incumbency advantage" affect election results?

### Question 2:
Why is it important to answer this question?

This question is important given the impact US elections have on day-to-day life. If opponents of incumbents have the knowledge of their disadvantage, should it exist, they can alter their campaign to better put their message forth.

### Question 3:
What are key endogeneity concerns?

The primary one is some sort of societal shifter in a place, which leads to an endogenous boost in win probability for an incumbent of a certain party.

### Question 4: 
Argument for RDD relevance, and supporting evidence?

Relevance can be seen via the probability of becoming a candidate again, with those who win in their previous election running again at a high probability. Fig 3(a) shows this.

### Question 5:
Argument for RDD validity, and supporting evidence?

The RDD is valid since there is no manipulation possible. The author describes that, in the aggregate, the vote is almost like a coin toss. Thus, there is no fine manipulation. Also, voters are likely not systematically different from one period to the next.

### Question 6:
Argument for RDD monotonicity, and supporting evidence?

If a politician won and is now an incumbent candidate, their probability of reelection in the proceeding election increases. This is supported by fig. 2(a), showing the large discontinuity in probability of re-election.

### Question 7:
RDD estimates LATE, can 1 and 2 hold for LATE instead of ATE?

Yes, there is no defiance. Since if one loses they are necessarily not an incumbent, while if someone wins, they do not opt out.

### Question 8:
Criticism of validity and monotonicity?

Validity can be challenged by a shifting voting base. For instance, if there is mass migration into a district because of that candidate, validity is violated. Monotonicity is challenged if there were politicians who choose to abstain from the next election, though this does not happen.

### Question 9:
Additional evidence to assuage concerns in (8)?

Fig 3(a) for monotonicity. Validity is unlikely to occur, and thus does not warrant defense.


### Question 10:
Strongest part of the paper?

Guide on RDD at the start.

### Question 11:
Weakest part of the paper?

Brevity of actual experiment. Ended wanting more analysis, though the point of the paper was to showcase the methodology.

## Paper 3: "The Deterrence Effect of Prison: Dynamic Theory and Evidence - Lee and McCrary (2016)"

### Question 1:
What is the research question?

How does the change in criminal sanctions occurring before and after an individual's 18th birthday affect recidivism rates? 

### Question 2:
Why is it important to answer this question?

This is an important question given the societal cost of crime and incarceration. Gaining insight into how sentencing affects criminal behavior can aid in the design of more effective criminal justice policies.

### Question 3:
What are key endogeneity concerns?

A key concern is the manipulation of behavior around the age cutoff. Chiefly, an individual may partake in less risky behavior as their 18th birthday approaches to avoid harsher penalties, which could confound the results.

### Question 4: 
Argument for RDD relevance, and supporting evidence?

Relevance is shown via the significant increase in the probability of being charged as an adult once an individual turns 18, as well as receiving sentencing to adult prison. These are shown in figures 2(a) and 2(b).

### Question 5:
Argument for RDD validity, and supporting evidence?

The RDD is valid because individuals cannot finely manipulate either their birth date or the timing of sentencing around their birthday. While one could attempt to rush/delay sentencing, there is much beureaucracy involved, making precise manipulation unlikely. Further, there is no reason to believe that individuals just below and just above the age cutoff differ systematically in unobserved characteristics affecting recidivism. Figure 1(a) and 1(b) support this, showing no discontinuities in probability of arrest at 17 or 19. 


### Question 6:
Argument for RDD monotonicity, and supporting evidence?

Monotonicity holds because individuals sentenced just after their 18th birthday are more likely to receive adult sanctions compared to those sentenced just before turning 18. This is supported by the clear discontinuities in figures 2(a) and 2(b), indicating that turning 18 increases the likelihood of adult charges and sentencing.


### Question 7:
RDD estimates LATE, can 1 and 2 hold for LATE instead of ATE?

Yes, since there are no defiers in this context. An individual cannot choose to be sentenced as a juvenile if they are sentenced after turning 18, and vice versa. Thus, the LATE applies to compliers who are affected by the age cutoff.


### Question 8:
Criticism of validity and monotonicity?

Validity could be challenged if individuals chose to alter their behavior around their 18th birthday in ways that affect recidivism, such as avoiding risky activities. Figure 4 shows a decrease in numbers of arrests leading up to one's 18th birthday, corroborating this is a real concern. Monotonicity could be questioned if there were individuals who, despite being sentenced after turning 18, received juvenile sanctions due to mitigating circumstances, though this is unlikely to occur.


### Question 9:
Additional evidence to assuage concerns in (8)?

The concern around monotonicity is minimal given the legal structure. For validity, the authors actually do a good job showing the main source of variation comes from the sentencing change at age 18, not from other behavioral changes. This is shown via the lack of discontinuities in arrests for index crimes (3(a)).


### Question 10:
Strongest part of the paper?

The strongest part of the paper is its application of a clear and well-defined RDD to a significant policy question, along with robust data analysis which lends itself to credible inference.

### Question 11:
Weakest part of the paper?

The weakest part of the paper is the limited ability to generalize findings beyond the specific context of age-based sentencing, as well as potential unobserved behavioral changes around the cutoff that may not be fully accounted for.

## Paper 4: "Using Maimonides' Rule to Estimate the Effect of Class Size on Student Achievement - Angrist and Lavy (1999)"

### Question 1:
What is the research question?

How does class size affect student achievement in primary schools in Israel,as measured by standardized test scores?

### Question 2:
Why is it important to answer this question?

Education policy is a critical area of public policy, thus understanding the impact of class sizes on student outcomes can inform decisions on resource allocation and educational strategies. The Israeli context provides a unique setting due to Maimonides' Rule, which creates exogenous variation in class sizes.

### Question 3:
What are key endogeneity concerns?

A key concern is manipulation on the parent side, with parents potentially choosing school districts based on anticipated class sizes. However, the authors argue that this is unlikely due to law around school assignments and the relative rarity of private school attendance.


### Question 4: 
Argument for RDD relevance, and supporting evidence?

Relevance is established through Maimonides' Rule, which mandates that class sizes cannot exceed 40 students. This creates a discontinuity in class sizes at enrollment thresholds (multiples of 40). The authors provide evidence of this discontinuity in class sizes in Figure 1, showing a clear jump in average class size at these thresholds. Besides multiples of 40, the class sizes grow roughly linearly with enrollment.


### Question 5:
Argument for RDD validity, and supporting evidence?

The RDD is valid because the assignment of students to classes based on enrollment thresholds is exogenous. Students cannot manipulate their enrollment numbers to influence class sizes, as these are determined by overall school enrollment. There is difficulty in manipulation, as discussed in (3).

### Question 6:
Argument for RDD monotonicity, and supporting evidence?

Monotonicity holds because as enrollment increases past the thresholds set by Maimonides' Rule, class sizes increase for all students. There are no students who would experience a decrease in class size as enrollment crosses these thresholds. This is supported by the consistent increase in class sizes observed in Figure 1 at the enrollment cutoffs.


### Question 7:
RDD estimates LATE, can 1 and 2 hold for LATE instead of ATE?

Yes, since there are no defiers in this context. Students cannot choose to be in smaller classes when enrollment exceeds the threshold, thus the LATE applies to compliers affected by the class size changes at the cutoffs.


### Question 8:
Criticism of validity and monotonicity?

Validity is challenged by the fact that the schools with larger enrollment are located in larger cities, which likely have unobserved characteristics affecting student achievement. Monotonicity could be questioned if there were schools that, despite increased enrollment, managed to keep class sizes small through additional resources or policies, though this is unlikely given the strictness of Maimonides' Rule.

### Question 9:
Additional evidence to assuage concerns in (8)?

The authors argue that their design reduces bias from unobserved school characteristics and reduces within school bias, by controlling for school fixed effects and other covariates. This helps address the validity concern. For monotonicity, the legal structure of Maimonides' Rule makes it unlikely that schools can deviate from the class size increases dictated by enrollment thresholds. That said, their main argument is the relative rarity of alternatives. Giving some sort of evidence on this would have been nice.


### Question 10:
Strongest part of the paper?

The strongest part of the paper is its innovative use of Maimonides' Rule to create a natural experiment for studying the effects of class size on student achievement. The clear discontinuities in class sizes at enrollment thresholds provide a robust basis for causal inference. It is an early and influential paper in the RDD literature, to the extreme that they refer to the mechanism as IV. This implementation is easy to interpret, and thus lays a strong foundation for future work.

### Question 11:
Weakest part of the paper?

The weakest part of the paper is the potential for unobserved confounding factors related to school location and characteristics that may not be fully accounted for, which could bias the estimated effects of class size on student achievement. I also think more could have been shown on the rarity of alternatives to attending these public schools, as this is a key assumption for their identification strategy.
