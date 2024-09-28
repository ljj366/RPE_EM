/******* replace missing and unreasonable grantdate ********************/
/** We use 2 months after the start of the fiscal year to replace missing and abnormal grant dates
Abnormal grant dates refer to those being eariler than 90 days before the start of the fiscal year or later than 366 days after the 
start of the fiscal year.
***/

libname my 'D:\RPE\RPE_EM\data_code';
libname inclab 'D:\RPE_EM\IncLab_data';

data grant; set inclab.gpbagrant; if year(grantdate)=9999 then grantdate=.; run;

* get fiscalyearend from companyfy, correct the typos, and fill in missing values;
data companyfy; set inclab.companyfy;
if cik='0000004457' and fiscalyear=2015 then fiscalyearend=mdy(3,31,2016);
if cik='0000012659' and fiscalyear=2015 then fiscalyearend=mdy(4,30,2016);
if cik='0000091419' and fiscalyear=2015 then fiscalyearend=mdy(4,30,2016);
if cik='0000320187' and fiscalyear=2015 then fiscalyearend=mdy(5,31,2016);
if cik='0000780571' and fiscalyear=2015 then fiscalyearend=mdy(12,31,2015);
if cik='0000866374' and fiscalyear=2015 then fiscalyearend=mdy(3,31,2016);
if cik='0000886158' and fiscalyear=2015 then fiscalyearend=intnx('month',mdy(2,1,2016),0,'end');
if cik='0000910521' and fiscalyear=2015 then fiscalyearend=mdy(3,31,2016);
if cik='0000912463' and fiscalyear=2015 then fiscalyearend=mdy(1,31,2016);
if cik='0000929351' and fiscalyear=2015 then fiscalyearend=mdy(3,31,2016);
if cik='0001011006' and fiscalyear=2015 then fiscalyearend=mdy(12,31,2015);
if cik='0001032975' and fiscalyear=2015 then fiscalyearend=mdy(3,31,2016);
if cik='0001094739' and fiscalyear=2015 then fiscalyearend=mdy(4,30,2016);
if cik='0001355096' and fiscalyear=2015 then fiscalyearend=mdy(12,31,2015);
if cik='0001623613' and fiscalyear=2015 then fiscalyearend=mdy(12,31,2015);
if cik='0000851205' then fiscalyearend=mdy(12,31,fiscalyear);
run;

proc sql; 
create table grant2 as select a.*, b.ticker, b.companyname, cusip, fiscalyearend
from grant as a left join companyfy as b
on a.cik=b.cik and a.fiscalyear=b.fiscalyear;
quit;

proc print data=grant2;where fiscalyearend=.;run;

data grant2; set grant2;
fiscalyearstart = intnx('day',intnx('year',fiscalyearend,-1,'same'),1,'same');
format fiscalyearstart MMDDYY10.;
run;

/* find medium of the distance bw grantdate and start of fiscal year from available grantdate.
We created the beginning of fiscalyear first, then we found companyFY provides fiscalyearend. 
Results from fiscalyearstart generated from companyFY and cdate1 in the following is almost the same. 
Since grantdate is calendar date, we convert fiscal to calendar dates.
For firms ending before July, we use same fiscal year and month as starting date;
for firms ending after July, we use fiscal year -1 as starting date
e.g, fiscal year ending in dec, 2012, starts from dec, 2011 (calendar date); 
but fiscal year ending in feb, 2012 starts from feb, 2012 (calendar date)    */

data temp;
	set grant2;
	gdate = mdy(fiscalmonth,1,fiscalyear);
	stdate = intnx('year',gdate, -1,'same'); 
	cyear = fiscalyear; 
	if fiscalmonth<7 then cyear = cyear+1;
	cdate = mdy(fiscalmonth,1,cyear-1);*assumption: firms start from the beginning of fiscalmonth;
    * another assumption: firms end at the end of fiscalmonth, start from next month. 
     this results little diff in the medium, but less extreme values. 
     drop only 1.7% of inaccurate grantdates, while using 1st assumpution drops 7%;
	if fiscalmonth <12 then cdate1=mdy(fiscalmonth+1,1,cyear-1);
	else cdate1=mdy(1,1,cyear);*for firms ending at the end of dec, they start from Jan of next year;
	diff2 = grantdate - cdate;
	diff3 = grantdate - stdate;
	diff4 = grantdate - cdate1;
	diff5 = grantdate - fiscalyearstart;
	where grantdate ~=.;
run;

proc means data = temp MEAN P1 P5 P10 P25 P50 P75 P90 P99;
vars diff2 diff3 diff4 diff5;
run;

/* set unreasonable grantdate to missing */
data temp; set grant2;
/*
cyear = fiscalyear; 
if fiscalmonth<7 then cyear = cyear+1;
if fiscalmonth <12 then startdate=mdy(fiscalmonth+1,1,cyear-1);
else startdate=mdy(1,1,cyear);
format startdate MMDDYY10.;
dist = grantdate - startdate;
*/
dist = grantdate- fiscalyearstart;
run;

proc freq data=temp;
table dist/out=temp1;
run ;

proc sgplot data=temp1;
histogram dist / scale=percent;
run;

data grant2; set temp;
grantdate_missingD = 0;
if grantdate = . then grantdate_missingD = 1;

grantdate_inaccurateD = 0;
if dist < -90 and dist ~= . then  grantdate_inaccurateD = 1;* SAS assumes . < a number ;
if dist > 366 then  grantdate_inaccurateD = 1;
drop dist;
run;

proc freq data=grant2;where grantdate_missingD=0;table grantdate_inaccurateD;run;*1.75% inaccurate among all non-missing grantdates;

/* supplement missing and inaccurate grantdates with medium of number days bw start of fiscal year and available grantdates */

data grant3; set grant2;
grantdate_inclab = grantdate;
* if grantdate = . or grantdate_inaccurateD=1 then grantdate = intnx('month',mdy(fiscalmonth,01,cyear-1),3,'same');*medium dist bw startdate and grantdate is 60 days;
if grantdate = . or grantdate_inaccurateD=1 then grantdate = intnx('month',fiscalyearstart,2,'same');*medium dist bw fiscalyearstart and grantdate is 60 days;
format grantdate grantdate_inclab MMDDYY10.;
run;

proc print data=grant3(obs=30);where grantdate_inaccurateD=1;run;

* save ;
data my.grant_GrantdateMissingCorrected; set grant3; 
fyCompustat = year(fiscalyearend);
if month(fiscalyearend)<6 then fyCompustat=fyCompustat-1;
run;

