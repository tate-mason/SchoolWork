* this program estimates the censored poisson for the poisson;
* results from Table 6 using the total sum of risky conditions;
* as the outcome of interest.  the censored poisson portion;
* of the program is written in proc iml.  it can estimate either;
* a poisson or a censored poisson and it can do it with or without;
* weights.  For the proc iml component of the program, you need to actively;
* construct an intercept that we define below to equal c.  The weights 
* have to sum to the number of observations and if you are not using weights; 
* then set the weight equal to c which always equals 1;

libname out 'c:\bill\eitc\update_ron_data';

data one;
set out.data_for_sas;

* keep those with nonmissing sum scores;
if totalsum~=.;
if _Imarital_2~=.;
* construct an intercept;
c=1;

proc means data=one;
run;

* run a poisson -- compare with the results form STATA;
proc genmod data=one;
model totalsum=_Iyear_1 _Iyear_2 _Iyear_3 _Irace_2 _Irace_3
_Imarital_2 _Imarital_3 _Imarital_4 
_Iage_22 _Iage_23 _Iage_24 _Iage_25 _Iage_26 _Iage_27 _Iage_28 _Iage_29
 _Iage_30 _Iage_31 _Iage_32 _Iage_33 _Iage_34 _Iage_35 _Iage_36 _Iage_37 _Iage_38 _Iage_39 _Iage_40
two_plus_kids treat / dist=poisson;
run;


options ps=500;
PROC IML;


* THIS FUNCTION CALCULATES THE LOGLIKELIHOOD FUNCTION FOR A;
* NEGATIVE BINOMIAL.  THE INPUTS TO THE FUNCTION ARE X, BETA, AND Y;
* WHERE LAMBDA=EXP(X*BETA). FACTORIALS ARE EVALUATED VIA THE;
* GAMMA FUNCTION WHERE Y!=GAMMA(Y+1);
START LIKE(X,Y,BETA,WEIGHT,topcode,poisson);
n=nrow(x);
K=NCOL(X);
ylfact=log(gamma(y+1));
lambda=EXP(X*Beta);
ll1=-lambda+(x*beta)#y-ylfact;
ll2=ll1`*weight;
free ll1;
lltopcode=j(n,1,0);

if poisson=0 then do;
do i=1 to n;
li=lambda[i,];
do j=0 to topcode;
pij=(exp(-li)*(li**j))/gamma(j+1);
lltopcode[i,]=lltopcode[i,]+max(pij,1e-9);
end;
end;
like=ll2-log(lltopcode)`*weight;
end;

if poisson=1 then do;
like=ll2;
end;

RETURN(LIKE);
FINISH;



* THIS FUNCTION CALCULATES THE LOGLIKELIHOOD FUNCTION FOR A;
* NEGATIVE BINOMIAL.  THE INPUTS TO THE FUNCTION ARE X, BETA, AND Y;
* WHERE LAMBDA=EXP(X*BETA). FACTORIALS ARE EVALUATED VIA THE;
* GAMMA FUNCTION WHERE Y!=GAMMA(Y+1);
START LIKE(X,Y,BETA,WEIGHT,topcode,poisson);
n=nrow(x);
K=NCOL(X);
ylfact=log(gamma(y+1));
lambda=EXP(X*Beta);
ll1=-lambda+(x*beta)#y-ylfact;
ll2=ll1`*weight;
free ll1;
lltopcode=j(n,1,0);

if poisson=0 then do;
do i=1 to n;
li=lambda[i,];
do j=0 to topcode;
pij=(exp(-li)*(li**j))/gamma(j+1);
lltopcode[i,]=lltopcode[i,]+max(pij,1e-9);
end;
end;
like=ll2-log(lltopcode)`*weight;
end;

if poisson=1 then do;
like=ll2;
end;

RETURN(LIKE);
FINISH;



START GRADIENT(X,Y,BETA,WEIGHT,topcode,poisson);
n=nrow(x);
K=NCOL(X);
ylfact=log(gamma(y+1));
lambda=EXP(X*Beta);
y1=y-lambda;
grad1=(x#y1);

grad1a=grad1#weight;

grad2=j(n,k,0);

if poisson=0 then do;
hesssum=j(k,k,0);
do i=1 to n;
li=lambda[i,];
yi=y[i,];
xi=x[i,];
wi=weight[i,];
gsum=0;
lltopcode=0;
hessi=0;

do j=0 to topcode;
pij=(exp(-li)*(li**j))/gamma(j+1);
ggj=-li*pij+j*pij;
hhi=-li*pij-li*ggj+j*ggj;
hessi=hessi+hhi;
gsum=gsum+ggj;
lltopcode=lltopcode+max(pij,1e-9);
end;
hesssum=hesssum+xi`*xi*wi*((hessi/lltopcode)-hessi*hessi/(lltopcode**2));
grad2[i,]=grad2[i,]+xi*gsum/lltopcode; 
end;
grad2a=grad2#weight;
grad=(grad1a[+,]-grad2a[+,])`;
hess2=(lambda#x#weight)`*x + hesssum;
*print hess hess2;
GRAD1=GRAD`//HESS2;
end;

else if poisson=1 then do;
grad=grad1a[+,]`;
hess2=(lambda#x#weight)`*x;
GRAD1=GRAD`//HESS2;
end;

RETURN(GRAD1);
FINISH;




* THIS SUBROUTINE CLIMBS THE HILL WITH THE QUASI-NEWTON PROCEDURE;
START MAXLINK;
TIME1=TIME();          /*GET TIME WHEN PROGRAM STARTS*/
PRINT "#########################################";
PRINT "STARTING VALUES", BETA[R=XVARS];
PRINT "#########################################";
LOGLAST=-1E10;        /*LOGLAST IS THE VALUE OF LOGLIKE ON LAST ITER*/
CC=1e-9;              /*MIN CRIT FOR CONVERGENCE*/
CRIT=1;               /*CONVERGENCE CRITERIA FOR ITH ITER*/
MAXIT=500;             /*MAXIMUM NUMBER OF ITERATIONS*/
DO IT=1 TO MAXIT;     /*ITERATE TIL CRIT IS SMALL*/
LOGLI=LIKE(X,Y,BETA,WEIGHT,topcode,poisson);                 /*EVALUATE LIKELIHOOD*/
GRAD1=GRADIENT(X,Y,BETA,WEIGHT,topcode,poisson);              /*EVALUATE GRADIENT*/
GRAD=GRAD1[1,]`;                       /*EVALUATE HESSIAN*/
HESS=GRAD1[(2:(K+1)),(1:K)];
COV=INV(HESS);                       /*CALCULATE VAR-COV MATRIC*/
DIRECT=(COV*GRAD);                    /*CALCUTATE DIRECTION VECTOR*/
CRIT=ABS(GRAD`*COV*GRAD);             /*CHECK CONVERGENCE CRITERIA*/
PRINT "ITERATION=" IT;
PRINT "CRITERIA=" CRIT;
PRINT "LOGLIKELIHOOD=" LOGLI;
PRINT NAMES BETA GRAD DIRECT;         /*PRINT INFO FOR ITH ITERATION*/

IF CRIT<=CC THEN GOTO TEN;             /*IF NOT CONVERGED, MAKE STEP*/
*  THE T+1 VALUE OF BETA IS CALCULATED FROM THE ITERATIVE EQUATION
*  BETA(T+1) = BETA(T) + STEP*COV*GRAD.  STEP IS STEP LENGTH AND
*  COV*GRAD IS THE DIRECTIONAL VECTOR.  IF BETA(T+1) PRODUCES A VALUE;
*  OF THE LIKELIHOOD FUNCTION THAT IS SMALLER THAN THE PREVIOUS VALUE;
*  THEN THE STEP SIZE IS CUT IN HALF UNTIL THE LIKELIHOOD VALUE ;
*  INCREASES;

STEP=1;
B1=BETA;
BETA=B1 + STEP*DIRECT;
LOGLI=LIKE(X,Y,BETA,WEIGHT,topcode,poisson);
IF LOGLI>LOGLAST THEN GOTO TWELVE;
DO II=1 TO 20;
BETA=B1 + STEP*DIRECT;
LOGLI=LIKE(X,Y,BETA,WEIGHT,topcode,poisson);
IF LOGLI>LOGLAST THEN GOTO TWELVE;
STEP=.5*STEP;
END;
IF II>=20 THEN GOTO TWENTY;
TWELVE:
PRINT "STEP SIZE USED", STEP;
PRINT "************************************************";
END;


IF IT>=MAXIT THEN DO;
PRINT "====================================================================================";
PRINT "MAXIMUM NUMBER OF ITERATIONS OBTAINED.  CHECK RESULTS.  MODEL MAY NOT HAVE CONVERGED";
PRINT "====================================================================================";
END;



TEN:
*  ONCE THE ROUTINE CONVERGES, THE STANDARD ERRORS ARE CALCULATED;
*  AND THE RESULTS ARE PRINTED;
STD_ERR=SQRT(VECDIAG(COV));                 /*GET STANDARD ERRORS*/
T_RATIO=BETA/STD_ERR;                       /*CALCULATE T RATIOS*/
PROBT=1-PROBF(T_RATIO #T_RATIO,1,DOF);      /*CALCULATE PROB=0*/
PRINT "================FINAL RESULTS=====================";
PRINT "NUMBER OF INTERATION=" IT;
PRINT "FINAL VALUE OF CRITERIA, G'*INV(-H)*G=" CRIT;
PRINT "VALUE OF LOG LIKELIHOOD=" LOGLI;
PRINT "FINAL RESULTS",  NAMES BETA STD_ERR T_RATIO PROBT;
TIME2=TIME();
SECONDS=INTCK('SECOND',TIME1,TIME2);
PRINT "SECONDS TO CLIMB HILL=" SECONDS;
GOTO THIRTY;
TWENTY:
PRINT "AFTER 20 HALVINGS OF THE CORRECTION VECTOR -- THE LOGLIKELIHOOD FUNCTION DID NOT";
PRINT "IMPROVE.  MAXIMIZATION ABORTED";
THIRTY:
FINISH;




XVARS={'c' 
'_Iyear_1' '_Iyear_2' '_Iyear_3' '_Irace_2' '_Irace_3'
'_Imarital_2' '_Imarital_3' '_Imarital_4' 
'_Iage_22' '_Iage_23' '_Iage_24' '_Iage_25' '_Iage_26' '_Iage_27' '_Iage_28' '_Iage_29'
'_Iage_30' '_Iage_31' '_Iage_32' '_Iage_33' '_Iage_34' '_Iage_35' '_Iage_36' '_Iage_37' '_Iage_38' '_Iage_39' '_Iage_40'
'two_plus_kids' 'treat'}; 
YVAR={'totalsum'};
USE one;
READ ALL INTO X VAR XVARS;
READ ALL INTO Y VAR YVAR;
READ ALL INTO WEIGHT VAR{'c'};


* if poisson=1 then the model estimates a standard poisson.  If poisson=0;
* then it estimates the censored poisson.  when setting poisson=0;
* make sure you set the topcode amount;
poisson=0;
topcode=8;  * this topcodes the cdf;

beta=INV(X`*X)*X`*LOG(Y+1);

N=NROW(X);   PRINT "NUMBER OF OBSERVATIONS", N;
K=NCOL(X);   PRINT "NUMBER OF PARAMETERS", K;
DOF=N-K;     PRINT "DEGREES OF FREEDOM," DOF;
NAMES=XVARS`;

print "***************************************************************************************";
print "****************** results for totalsum *********************************************";
print "***************************************************************************************";

run maxlink;




