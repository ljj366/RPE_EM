/* The following code is run in wrds SASStudio. Define the library location in wrds first. */
libname inclab '/home/mcgill/ljj3202';

/* print out the observations whose vesting period ends before performance period */

data grant; set inclab.gpbagrant; if grantdatefv<0 then grantdatefv = .; vestingperiod=vesthighgrant-vestlowgrant; run;

data rel; 
set inclab.gpbarel; 
performanceperiod = vestHigh - vestLow;
run;

proc sql;
create table rel2 as select fiscalyear, CIK, vesthighgrant, b.vesthigh from grant as a join rel as b
on a.grantid=b.grantid;
quit;

proc print data = rel2;
where vesthighgrant < vesthigh;
run;


/*** Missing values of fair value ***/

libname inclab '/home/mcgill/ljj3202';

data grant; set inclab.gpbagrant; if grantdatefv<0 then grantdatefv = .; run;
data grant_fvmissing; set grant; if grantdatefv = .; run;

/* compute the nb of missing fv each year */
proc sort data=grant_fvmissing;by fiscalyear;run;

data temp; 
set grant_fvmissing; 
by fiscalyear;
if first.fiscalyear then count=0; 
count +1;
if last.fiscalyear then output;
keep fiscalyear count;
run;

/* check nb of observations that other variables can approximate */
data temp; set grant; where grantdatefv=. and nonequitytarget>=0; run;
data temp; set grant; where grantdatefv=. and equitytarget>=0; run;
data temp; set grant; where grantdatefv=. and stockaward >=0; run;

/* check nb of observations for which nonequitytarget can replace missing fv */
data temp; 
set grant_fvmissing; 
where nonequitytarget > 0;
by fiscalyear;
if first.fiscalyear then count=0; 
count +1;
if last.fiscalyear then output;
keep fiscalyear count;
run;

/* missing value for each awardtype*/
proc sort data=grant_fvmissing;by fiscalyear awardtype;run;

proc freq data=grant_fvmissing; 
by fiscalyear awardtype;
table grantdatefv/out=temp;
run;

* transpose ;
proc sort data=temp;by awardtype;run;

proc transpose data=temp out=temp1;
by awardtype;
var count;
id fiscalyear;
run;

proc transpose data=temp1 out=temp2;
id awardtype;
run;

data awardtype_y; 
retain fiscalyear ;
set temp2;
fiscalyear = scan(_name_, 1, "_", 's');
drop _name_;
run;

proc print data=awardtype_y; run;