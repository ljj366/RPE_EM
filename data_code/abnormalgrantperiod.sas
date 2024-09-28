/************ This file finds out the grants with grant period less than performance period *********
According to the guide, it looks like the period given in inclab.gpbagrant is performance period + vesting period for each grant;
The period computed from Inclab.rel is the performance period for each objective;
So grant period is supposed to be not less than any of the performance period of all objectives for one grant.
However, we found some abnormalies as follows.
****************/

data grant; set inclab.gpbagrant; run;
proc sort data=grant; by grantid; run;

data rel; set inclab.gpbarel; run;

proc sql;
create table grantrel as select a.cik, a.grantid, a.fiscalyear, a.fiscalmonth, a.vestlowgrant, a.vesthighgrant,
b.relid, b.periodid, b.vestlow, b.vesthigh
from grant as a right join rel as b
on a.grantid=b.grantid
order by cik, grantid, fiscalyear;
quit;

data grantrel; set grantrel; 
D=0;
if vesthighgrant < vesthigh then D=1;
run;

proc sort data=grantrel; by descending D; run;

data temp; set grantrel; if D=1 and vesthighgrant ~=.; run;

proc print data=my.grant_fvj; where cik='0000004447' and fiscalyear=2011;run;

data my.AbnormalGrantperiod; set temp; run;
