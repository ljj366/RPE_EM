
libname inclab 'E:\Experience\World_bank\RPE_EM\Raw_data\IncLab_N';

/*** SUMM STAT OF GRANT DATA ***/
data grant; set inclab.gpbagrant; if grantdatefv =-9999 then grantdatefv=.; run;

/** check the percentage of fv of rel, abs/rel, and time vesting performances across years **/
* sum grantfv for each fiscal year and performance type;
proc summary data=grant nway;
var grantdatefv;
class fiscalyear performancetype;
output out=temp1 sum=grantfv_y;
run;

* compute total fv for each fiscal year and percentage of each performace type;
proc sql;
create table perfpercentage_y as select fiscalyear, performancetype, grantfv_y, sum(grantfv_y) as grant_sum, grantfv_y/sum(grantfv_y) as grant_perc_y from temp1
group by fiscalyear;
quit;

* transpose data ;
proc sort data=perfpercentage_y;
by performancetype;
run;

proc transpose data=perfpercentage_y out=temp1;
by performancetype;
var grant_perc_y;
id fiscalyear;
run;

proc transpose data=temp1 out=temp2;
id performancetype;
run;

data perfpercentage_y2; 
attrib
fiscalyear length=4 format = Best4.
Rel length=4 format=Best4.
AbsRel length=4 format=Best4.
Abs length=4 format=Best4.
Time length=4 format=Best4.;
set temp2;
fiscalyear = scan(_name_, 1, "_", 's');
drop _name_;
run;

data relativebenchmark_firm_freq_y2;
retain fiscalyear Peer_Group S_P500 Other NA;
format Peer_Group S_P500 Other NA percent10.2;
set out;
run;

proc print data=perfpercentage_y2; run;

/* Frequency of each performance type;
ods output onewayfreqs=performancetype_freq_y;
proc freq data=grant;
by fiscalYear;
table performanceType;
run;
ods output close;
*/


/*** SUMM STAT OF REL DATA ***/
/* input rel data and define performance period in the rel dataset*/
data rel; 
set inclab.gpbarel; 
performanceperiod = vestHigh - vestLow;
run;

/* link grant and rel data, since rel does not have fiscal year */

/* check uniqueness of grantid. It is a unique key for the dataset, but avoid running this code since it's time-expensive;
proc sort data=grant NODUPKEY; 
by grantid;
run;
*/

proc sql;
create table rel2 as select fiscalyear, CIK, b.* from grant as a join rel as b
on a.grantid=b.grantid;
quit;

/** at the grantid level 
The following percentages can be calculated at the grantid level or firm level. 
Since grantid is unique, the total percentage sums to 1; but each firm may have
several grantid and correspond to multiple choices, so total percentage may not sum to 1 
if computed at the firm level.
**/

/* percentage of each relative benchmark */
proc sort data=rel2;by fiscalyear;run;

ods output onewayfreqs=relativebenchmark_freq_y;
proc freq data=rel2;
by fiscalYear;
table relativebenchmark;
run;
ods output close;

* transpose;
proc sort data=relativebenchmark_freq_y;by relativebenchmark;run;

proc transpose data=relativebenchmark_freq_y out=temp1;
by relativebenchmark;
var percent;
id fiscalyear;
run;

proc transpose data=temp1 out=temp2;
id relativebenchmark;
run;

data relativebenchmark_freq_y2; 
retain fiscalyear Peer_Group S_P500 Other NA;
set temp2;
fiscalyear = scan(_name_, 1, "_", 's');
drop _name_;
run;

proc print data=relativebenchmark_freq_y2; run;


/* percentage of metric type, i.e., accounting or stock price */
proc sort data=rel2;by fiscalyear;run;

proc freq data=rel2;
by fiscalYear;
table metrictype/out=metrictype_freq_y;
run;

* transpose;
proc sort data=metrictype_freq_y;by metrictype;run;

proc transpose data=metrictype_freq_y out=temp1;
by metrictype;
var percent;
id fiscalyear;
run;

proc transpose data=temp1 out=temp2;
id metrictype;
run;

data metrictype_freq_y2; 
retain fiscalyear Accounting Stock_price Other;
set temp2;
fiscalyear = scan(_name_, 1, "_", 's');
drop _name_;
run;

proc print data=metrictype_freq_y2; run;


/* summ stat of performance period */
proc means data=rel2;
var performanceperiod;
class fiscalyear;
output out = relperformancepriod_y(drop=_type_ _freq_) mean=avg;
run;

data relperformancepriod_y2; 
set relperformancepriod_y;
if fiscalyear ne .;
length avg 4;
run;

proc print data = relperformancepriod_y2;run;

/* percentage of performance period falling between intervals */
proc sql;
create table temp as select fiscalyear,grantid,
    case 
	when performanceperiod = . then 'NA'
	when performanceperiod <= 12 then  'lq1y'
	when 12<performanceperiod <=2*12 then  'bw1and2y'
	when 2*12<performanceperiod <=3*12 then  'bw2and3y'
	when 3*12<performanceperiod <=4*12 then  'bw3and4y'
	else 'h4y'
end as ppinterval 
from rel2;
quit;


proc freq data=temp;
by fiscalYear;
table ppinterval/out=performanceperiodinterval_y;
run;

* transpose;
proc sort data=performanceperiodinterval_y;by ppinterval;run;

proc transpose data=performanceperiodinterval_y out=temp1;
by ppinterval;
var percent;
id fiscalyear;
run;

proc transpose data=temp1 out=temp2;
id ppinterval;
run;

data performanceperiodinterval_y2; 
retain fiscalyear lq1y bw1and2y bw2and3y bw3and4y h4y;
set temp2;
fiscalyear = scan(_name_, 1, "_", 's');
drop _name_;
run;

proc print data=performanceperiodinterval_y2; run;


/** On the firm level **/
proc sort data=rel2; by fiscalyear CIK;run;

proc freq data=rel2;
by fiscalYear CIK;
table relativebenchmark/out=temp;
run;

proc sql;
create table temp1 as select fiscalyear, relativeBenchmark, count(CIK) as count from temp
group by fiscalyear, relativebenchmark;
quit;

proc sort data=temp out=firmnb_y nodupkey; by fiscalyear CIK;run;

proc sql;
create table temp2 as select fiscalyear, count(CIK) as count_sum from firmnb_y
group by fiscalyear;
quit;

proc sql;
create table relativebenchmark_firm_freq_y as select a.fiscalyear, relativebenchmark, count/count_sum as perc from temp1 as a left join temp2 as b
on a.fiscalyear = b.fiscalyear;
quit;

proc print data=relativebenchmark_firm_freq_y;run;

* transpose;
/* this function transposes long data to wide by yy and byvar; */
%macro mytranspose(mydata, yy, byvar,var);
*%let mydata=relativebenchmark_firm_freq_y;
*%let yy = fiscalyear;
*%let byvar = relativebenchmark;
*%let var = perc;

proc sort data=&mydata;
by &byvar;
run;

proc transpose data=&mydata out=temp1;
by &byvar;
var &var;
id &yy;
run;

proc transpose data=temp1 out=temp2;
id &byvar;
run;

data out; 
set temp2;
fiscalyear = input( scan(_name_, 1, "_", 's'), 4. );
drop _name_;
run;
%mend mytranspose;

%mytranspose(relativebenchmark_firm_freq_y,fiscalyear,relativebenchmark,perc);

data relativebenchmark_firm_freq_y2;
retain fiscalyear Peer_Group S_P500 Other NA;
format Peer_Group S_P500 Other NA percent10.2;
set out;
run;

proc print data=relativebenchmark_firm_freq_y2; 
run;

/* compute the average of each firm's perfromancetype ratio */ 
proc sort data=grant; by fiscalyear CIK; run;

proc means data =grant;
* proc means data =grant(where=(performancetype='Rel')); *if only consider RPE firms;
var grantdatefv;
class fiscalyear CIK performancetype;
output out=temp1 sum=grantfv;
run;

proc sql;
create table temp2 as select fiscalyear, CIK, sum(grantfv) as grantfv_sum from temp1
where grantfv >= 0
group by fiscalyear, CIK;
quit;

proc sql;
create table temp3 as select a.fiscalyear, a.CIK, performancetype, a.grantfv/b.grantfv_sum as perc from temp1 as a left join temp2 as b
on a.fiscalyear = b.fiscalyear and a.CIK=b.CIK;
quit;

proc means data=temp3;
class fiscalyear performancetype;
var perc;
output out=avg_performancetype mean=avg;
run;

*transpose ;
proc sort data=avg_performancetype;by performancetype;run;

proc transpose data=avg_performancetype out=temp1;
by performancetype;
var avg;
id fiscalyear;
run;

proc transpose data=temp1 out=temp2;
id performancetype;
run;

data avg_performancetype_y2; 
retain fiscalyear Rel AbsRel Abs Time;
set temp2;
fiscalyear = scan(_name_, 1, "_", 's');
drop _name_;
run;

proc print data=avg_performancetype_y2; run;

/* compute the average of each firm's awardtype ratio */ 
proc sort data=grant; by fiscalyear CIK; run;

proc means data =grant;
var grantdatefv;
class fiscalyear CIK awardtype;
output out=temp1 sum=grantfv;
run;

proc sql;
create table temp2 as select fiscalyear, CIK, sum(grantfv) as grantfv_sum from temp1
where grantfv >= 0
group by fiscalyear, CIK;
quit;

proc sql;
create table temp3 as select a.fiscalyear, a.CIK, awardtype, a.grantfv/b.grantfv_sum as perc from temp1 as a left join temp2 as b
on a.fiscalyear = b.fiscalyear and a.CIK=b.CIK;
quit;

proc means data=temp3;
class fiscalyear awardtype;
var perc;
output out=avg_awardtype_y mean=avg;
run;

*transpose ;
proc sort data=avg_awardtype_y;by awardtype;run;

proc transpose data=avg_awardtype_y out=temp1;
by awardtype;
var avg;
id fiscalyear;
run;

proc transpose data=temp1 out=temp2;
id awardtype;
run;

data avg_awardtype_y2; 
retain fiscalyear Option cashLong cashShort phantomStock rsu sarEquity unitCash;
set temp2;
fiscalyear = scan(_name_, 1, "_", 's');
drop _name_;
run;

proc print data=avg_awardtype_y2; run;



%let wrds=wrds-cloud.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

/* Frequency of award type */
rsubmit;
libname inclab '/home/mcgill/ljj3202';

data grant; set inclab.gpbagrant; if grantdatefv<0 then grantdatefv = .; run;

/*pct of award type for all firms;
proc sort data=grant;
by fiscalyear CIK;
run;

proc freq data=grant;
by fiscalYear CIK;
table awardtype/out=temp;
run;
*/

*pct of award type for RPE firms only;

proc sort data=grant(where=(performancetype='Rel'));
by fiscalyear CIK;
run;

proc freq data=grant(where=(performancetype='Rel'));
by fiscalYear CIK;
table awardtype/out=temp;
run;

proc sql;
create table temp1 as select fiscalyear, awardtype, count(CIK) as count from temp
group by fiscalyear, awardtype;
quit;

proc sort data=temp out=firmnb_y nodupkey; by fiscalyear CIK;run;

proc sql;
create table temp2 as select fiscalyear, count(CIK) as count_sum from firmnb_y
group by fiscalyear;
quit;

proc sql;
create table awardtype_firm_freq_y as select a.fiscalyear, awardtype, count/count_sum as perc from temp1 as a left join temp2 as b
on a.fiscalyear = b.fiscalyear;
quit;

*transpose;
proc sort data=awardtype_firm_freq_y;
by awardtype;
run;

proc transpose data=awardtype_firm_freq_y out=temp1;
by awardtype;
var perc;
id fiscalyear;
run;

proc transpose data=temp1 out=temp2;
id awardtype;
run;

data out; 
set temp2;
fiscalyear = input( scan(_name_, 1, "_", 's'), 4. );
drop _name_;
run;

proc download data=out;
run;
endrsubmit;

proc export 
data = out
outfile = 'E:\Experience\World_bank\RPE_EM\data_code\awardtype_freq_y.csv' 
DBMS = csv
replace;
run;



/************************************ Using Estimated Fair Values **************************************/
/* this function transposes long data to wide by yy and byvar; */
%macro mytranspose(mydata, yy, byvar,var);

proc sort data=&mydata;
by &byvar;
run;

proc transpose data=&mydata out=temp1;
by &byvar;
var &var;
id &yy;
run;

proc transpose data=temp1 out=temp2;
id &byvar;
run;

data out; 
set temp2;
fiscalyear = input( scan(_name_, 1, "_", 's'), 4. );
drop _name_;
run;

%mend mytranspose;

data grant5; set inclab.grant_FVj; run;

* check diff in fair vaules for each performance type;
data temp1; set inclab.grant_fvj; where FV_w ~=.; run;*289558 obs;
data temp2; set inclab.grant_fvj; where grantdatefv ~=.; run;*186984 obs;

proc summary data=temp1 nway;
var FV_w;
class performancetype;
output out=temp1(rename=(_freq_=N)) sum=grantfv;
run;

proc sql;
create table perfpercentage as select performancetype, N, grantfv/sum(grantfv) as grant_perc, grantfv, sum(grantfv) as grant_sum from temp1;
quit;

proc print data=perfpercentage;run;

proc summary data=temp2 nway;
var grantdatefv;
class performancetype;
output out=temp1(rename=(_freq_=N)) sum=grantfv;
run;

proc sql;
create table perfpercentage as select performancetype, N, grantfv/sum(grantfv) as grant_perc, grantfv, sum(grantfv) as grant_sum from temp1;
quit;

proc print data=perfpercentage;run;

* check diff in FV for each award type;
data temp1; set inclab.grant_fvj; where FV_w ~=.; run;*289558 obs;
data temp2; set inclab.grant_fvj; where grantdatefv ~=.; run;*186984 obs;

proc summary data=temp1 nway;
var FV_w;
class awardtype;
output out=temp(rename=(_freq_=N)) sum=grantfv;
run;

proc sql;
create table perfpercentage as select awardtype, N, grantfv/sum(grantfv) as grant_perc, grantfv, sum(grantfv) as grant_sum from temp;
quit;

proc print data=perfpercentage;run;

proc summary data=temp2 nway;
var grantdatefv;
class awardtype;
output out=temp(rename=(_freq_=N)) sum=grantfv;
run;

proc sql;
create table perfpercentage as select awardtype, N, grantfv/sum(grantfv) as grant_perc, grantfv, sum(grantfv) as grant_sum from temp;
quit;

proc print data=perfpercentage;run;


/* compute the percentage of fv for each performance type across years */
* sum grantfv for each fiscal year and performance type across firms;
proc summary data=grant5 nway;
var FV_w;
class fiscalyear performancetype;
output out=temp1 sum=grantfv_y;
run;

* compute total fv for each fiscal year and percentage of each performace type;
proc sql;
create table perfpercentage_y as select fiscalyear, performancetype, grantfv_y, sum(grantfv_y) as grant_sum, grantfv_y/sum(grantfv_y) as grant_perc_y from temp1
group by fiscalyear;
quit;

* transpose data ;
%mytranspose(perfpercentage_y, fiscalyear, performancetype,grant_perc_y);

data perfpercentage_y2; 
attrib
fiscalyear length=4 format = Best4.
Rel length=4 format=Best4.
AbsRel length=4 format=Best4.
Abs length=4 format=Best4.
Time length=4 format=Best4.;
set temp2;
fiscalyear = scan(_name_, 1, "_", 's');
drop _name_;
run;

proc print data=perfpercentage_y2; run;


/* compute the average of each firm's perfromancetype ratio */ 
proc sort data=grant; by fiscalyear CIK; run;

proc means data =grant;
* proc means data =grant(where=(performancetype='Rel')); *if only consider RPE firms;
var FV_w;
class fiscalyear CIK performancetype;
output out=temp1 sum=grantfv;
run;

proc sql;
create table temp2 as select fiscalyear, CIK, sum(grantfv) as grantfv_sum from temp1
where grantfv >= 0
group by fiscalyear, CIK;
quit;

proc sql;
create table temp3 as select a.fiscalyear, a.CIK, performancetype, a.grantfv/b.grantfv_sum as perc from temp1 as a left join temp2 as b
on a.fiscalyear = b.fiscalyear and a.CIK=b.CIK;
quit;

proc means data=temp3;
class fiscalyear performancetype;
var perc;
output out=avg_performancetype mean=avg;
run;

*transpose ;
proc sort data=avg_performancetype;by performancetype;run;

proc transpose data=avg_performancetype out=temp1;
by performancetype;
var avg;
id fiscalyear;
run;

proc transpose data=temp1 out=temp2;
id performancetype;
run;

data avg_performancetype_y2; 
retain fiscalyear Rel AbsRel Abs Time;
set temp2;
fiscalyear = scan(_name_, 1, "_", 's');
drop _name_;
run;

proc print data=avg_performancetype_y2; run;


/* compute the average of each firm's awardtype ratio */ 
proc sort data=grant5; by fiscalyear CIK; run;

proc means data =grant5 noprint;
var FV_w;
class fiscalyear CIK awardtype;
output out=temp1 sum=grantfv;
run;

proc sql;
create table temp2 as select fiscalyear, CIK, sum(grantfv) as grantfv_sum from temp1
where grantfv >= 0
group by fiscalyear, CIK;
quit;

proc sql;
create table temp3 as select a.fiscalyear, a.CIK, awardtype, a.grantfv/b.grantfv_sum as perc from temp1 as a left join temp2 as b
on a.fiscalyear = b.fiscalyear and a.CIK=b.CIK;
quit;

proc means data=temp3 noprint;
class fiscalyear awardtype;
var perc;
output out=avg_awardtype_y mean=avg;
run;

*transpose ;
proc sort data=avg_awardtype_y;by awardtype;run;

proc transpose data=avg_awardtype_y out=temp1;
by awardtype;
var avg;
id fiscalyear;
run;

proc transpose data=temp1 out=temp2;
id awardtype;
run;

data avg_awardtype_y2; 
retain fiscalyear Option phantomOption Reloadoption sarCash sarEquity stock rsu phantomStock cashLong cashShort unitCash;
set temp2;
fiscalyear = scan(_name_, 1, "_", 's');
drop _name_;
run;

proc print data=avg_awardtype_y2; run;

/********** RPE usage ************************/
proc sql;
create table temp as select fiscalyear, count(distinct cik) as nbfirms
from grant5
group by fiscalyear;
run;

proc sql;
create table temp1 as select fiscalyear, count(distinct cik) as nbfirms
from grant5
where performancetype in ('Rel','AbsRel')
group by fiscalyear;
run;

proc sql;
create table temp2 as select a.fiscalyear, a.nbfirms as N, b.nbfirms/a.nbfirms as RPEpct
from temp as a join temp1 as b
on a.fiscalyear=b.fiscalyear;
run;

proc print data=temp2; run;



/************************************ Sub-sample, using Estimated Fair Values **************************************/
data grant; set inclab.grant_FVj3; if fycompustat > 2005 and FV_w ~=. ; run;

* RPE firm pct;
proc sql;
create table temp as select fycompustat, count(distinct cik) as Tnb, 
count(distinct (case when performancetype in ('Rel') then cik end)) as nb_R,
count(distinct case when performancetype in ('Rel','AbsRel') then cik end) as nb_RA, 
calculated nb_R/calculated Tnb as pct_RPE,
calculated nb_RA/calculated Tnb as pct_RA
from grant
group by fycompustat;
quit;

proc print data=temp;run;

* PRE grant pct;
proc sql;
create table temp as select fycompustat, count(distinct grantid) as Tnb, 
count(distinct (case when performancetype in ('Rel') then grantid end)) as nb_R,
count(distinct case when performancetype in ('Rel','AbsRel') then grantid end) as nb_RA, 
calculated nb_R/calculated Tnb as pct_RPE,
calculated nb_RA/calculated Tnb as pct_RA
from grant
group by fycompustat;
quit;

proc print data=temp;run;

/* PRE pct of compensation; */
proc sql;
create table temp as select cik, fycompustat, FV_w, performancetype,
count(distinct (case when performancetype in ('Rel') then cik end)) as count_RPE,
count(distinct (case when performancetype in ('Rel','AbsRel') then cik end)) as count_RA
from grant
group by cik, fycompustat
order by cik, fycompustat, grantid;
run;

proc sql;
create table RPE1 as select cik, fycompustat, performancetype,sum(FV_w) as FV
from temp
where count_RPE > 0 
group by cik, fycompustat, performancetype
order by cik, fycompustat;
run;

proc sql;
create table RPE2 as select cik, fycompustat, performancetype, FV, sum(FV) as sum, FV/sum(FV) as pctcomp
from RPE1
group by cik, fycompustat
order by cik, fycompustat;
run;

proc sort data=RPE2; by fycompustat; run;

*for Rel only;
proc means data=RPE2(where = (performancetype='Rel')) ; 
by fycompustat; 
var pctcomp; output out=PRE_compensation mean=;
run;

proc print data=PRE_compensation;run;

* for Rel + AbsRel;
proc sql; 
create table RA as select cik, fycompustat, sum(pctcomp) as pct_RA
from RPE2
where performancetype in ('Rel','AbsRel')
group by cik, fycompustat
order by fycompustat;
run;

proc means data=RA ; 
by fycompustat; 
var pct_RA; output out=RA_compensation mean=;
run;

proc print data=RA_compensation; run;

* using original fair value;
data fv_o; set grant; 
fv_filled = grantdatefv; 
if fv_filled = . and nonequitytarget ~=. then fv_filled = nonequitytarget;
*if fv_filled = . and equitytarget ~=. then fv_filled = equitytarget * prc;
if fv_filled =. then delete;
run;

proc sql;
create table temp as select cik, fycompustat, FV_filled, performancetype,
count(distinct (case when performancetype in ('Rel') then cik end)) as count_RPE,
count(distinct (case when performancetype in ('Rel','AbsRel') then cik end)) as count_RA
from fv_o
group by cik, fycompustat
order by cik, fycompustat, grantid;
run;

proc sql;
create table RPE1 as select cik, fycompustat, performancetype,sum(FV_filled) as FV
from temp
where count_RPE > 0 
group by cik, fycompustat, performancetype
order by cik, fycompustat;
quit;

proc sql;
create table RPE2 as select cik, fycompustat, performancetype, FV, sum(FV) as sum, FV/sum(FV) as pctcomp
from RPE1
group by cik, fycompustat
order by cik, fycompustat;
run;

proc sort data=RPE2; by fycompustat; run;

* Rel;
proc means data=RPE2(where = (performancetype='Rel')) ; 
by fycompustat; 
var pctcomp; output out=PRE_compensation mean=;
run;

proc print data=PRE_compensation;run;

*Rel +AbsRel;
proc sql; 
create table RA as select cik, fycompustat, sum(pctcomp) as pct_RA
from RPE2
where performancetype in ('Rel','AbsRel')
group by cik, fycompustat
order by fycompustat;
run;

proc means data=RA ; 
by fycompustat; 
var pct_RA; output out=RA_compensation mean=;
run;

proc print data=RA_compensation; run;



/* stock vs accounting; */
proc sql;
create table rel2 as select CIK, fiscalyear,fycompustat, FV_w, b.* 
from grant as a join inclab.gpbarel as b
on a.grantid=b.grantid;
quit;

proc sort data=rel2; run;
proc freq data=rel2;
table metrictype/out=metrictype_freq;
run;

proc print data=metrictype_freq;run;

/* performance period */
data rel2; set rel2; performanceperiod = vestHigh - vestLow;run;

proc sql;
create table temp as select grantid, fycompustat,
    case 
	when performanceperiod = . then 'NA'
	when performanceperiod <= 12 then  'lq1y'
	when 12<performanceperiod <=2*12 then  'bw1and2y'
	when 2*12<performanceperiod <=3*12 then  'bw2and3y'
	when 3*12<performanceperiod <=4*12 then  'bw3and4y'
	else 'h4y'
end as ppinterval 
from rel2;
quit;

proc freq data=temp;
by fycompustat;
table ppinterval/out=performanceperiodinterval_y;
run;

* transpose;
proc sort data=performanceperiodinterval_y;by ppinterval;run;

proc transpose data=performanceperiodinterval_y out=temp1;
by ppinterval;
var percent;
id fycompustat;
run;

proc transpose data=temp1 out=temp2;
id ppinterval;
run;

data performanceperiodinterval_y2; 
retain fycompustat lq1y bw1and2y bw2and3y bw3and4y h4y;
set temp2;
fycompustat = scan(_name_, 1, "_", 's');
drop _name_;
run;

proc print data=performanceperiodinterval_y2; run;

data temp1; set grant5; where FV_w ~=.; run;*290550 obs;
data temp2; set grant5; where grantdatefv ~=.; run;*186984 obs;

proc summary data=temp1 nway;
var FV_w;
class performancetype;
output out=temp1(rename=(_freq_=N)) sum=grantfv;
run;

proc sql;
create table perfpercentage as select performancetype, N, grantfv/sum(grantfv) as grant_perc, grantfv, sum(grantfv) as grant_sum from temp1;
quit;

proc print data=perfpercentage;run;

proc summary data=temp2 nway;
var grantdatefv;
class performancetype;
output out=temp1(rename=(_freq_=N)) sum=grantfv;
run;

proc sql;
create table perfpercentage as select performancetype, N, grantfv/sum(grantfv) as grant_perc, grantfv, sum(grantfv) as grant_sum from temp1;
quit;

proc print data=perfpercentage;run;

/* CEO's RPE pct of total compenstation; */

* merge with participant file ;

*repair sas file;
proc datasets library=inclab;
repair participantfy;
quit;

data participantfy; set inclab.participantfy; run;

*3603;
data temp; set participantfy; 
where currentCEO ~= 1 and (rolecode1='CEO' or rolecode2='CEO' OR rolecode3='CEO' or rolecode4='CEO'); 
run;

* 140 ;
data temp; set participantfy; 
where currentCEO = 1 and (rolecode1~='CEO' and rolecode2~='CEO' and rolecode3~='CEO' and rolecode4~='CEO'); 
run;


/* grant for CEOs only */
proc sql;
create table grant_participant as select a.*
from grant as a join participantfy as b
on a.cik=b.cik and a.participantid = b.participantid and a.fiscalyear=b.fiscalyear 
where currentceo = 1
order by cik, fiscalyear, participantid;
run;

data ceo; set grant_participant; run;*63268;
proc sort data=ceo nodupkey dupout=dup1; by grantid; run; *43 duplicates deleted;

data ceo_sub; set ceo; where fycompustat>2005 and fv_w ~=.; run;

proc sql;
create table temp as select cik, fycompustat, FV_w, performancetype,
count(distinct (case when performancetype in ('Rel') then cik end)) as count_RPE,
count(distinct (case when performancetype in ('Rel','AbsRel') then cik end)) as count_RA
from ceo_sub
group by cik, fycompustat
order by cik, fycompustat, grantid;
run;

proc sql;
create table RPE1 as select cik, fycompustat, performancetype,sum(FV_w) as FV
from temp
where count_RPE > 0 
group by cik, fycompustat, performancetype
order by cik, fycompustat;
quit;

proc sql;
create table RPE2 as select cik, fycompustat, performancetype, FV, sum(FV) as sum, FV/sum(FV) as pctcomp
from RPE1
group by cik, fycompustat
order by cik, fycompustat;
run;

proc sort data=RPE2; by fycompustat; run;

* Rel;
proc means data=RPE2(where = (performancetype='Rel')) ; 
by fycompustat; 
var pctcomp; output out=PRE_compensation mean=;
run;

proc print data=PRE_compensation;run;

*Rel +AbsRel;
proc sql; 
create table RA as select cik, fycompustat, sum(pctcomp) as pct_RA
from RPE2
where performancetype in ('Rel','AbsRel')
group by cik, fycompustat
order by fycompustat;
run;

proc means data=RA ; 
by fycompustat; 
var pct_RA; output out=RA_compensation mean=;
run;

proc print data=RA_compensation; run;


/**** number of peers that are dropped or added; ****/
data relpeer; set my.relpeer; run;
proc sort data=relpeer; by cik peercik fycompustat; run;
data relpeer; set relpeer; d_add=0;if cik=lag(cik) and peercik~=lag(peercik) then d_add=1; run;

proc sort data=relpeer; by cik peercik descending fycompustat; run;
data relpeer; set relpeer; d_drop=0;if cik=lag(cik) and peercik~=lag(peercik) then d_drop=1; run;

proc sql;create table relpeer2 as select *,min(fycompustat) as start_fycompustat, max(fycompustat) as end_fycompustat
from relpeer 
group by cik
order by cik; 
quit;

data relpeer2; set relpeer2; 
if fycompustat=start_fycompustat then d_add=0;
if fycompustat=end_fycompustat then d_drop=0;
run;

proc sort data=relpeer2; by cik peercik fycompustat; run;

proc sql;create table nb_changepeers as select unique cik, fycompustat, count(*) as N_peers, sum(d_add)/count(*) as pct_add, sum(d_drop)/count(*) as pct_drop, 1-sum( (1-d_add)*(1-d_drop) )/count(*) as pct_add_drop
from relpeer2
group by cik, fycompustat
order by cik, fycompustat;

proc sql;create table nb_changepeers2 as select unique fycompustat, mean(N_peers) as avg_n_peers, mean(pct_add_drop) as avg_pct_add_drop, median(pct_add_drop) as median_pct_add_drop
from nb_changepeers
group by fycompustat;

proc means data=nb_changepeers2; var avg_pct_add_drop avg_n_peers; run;
