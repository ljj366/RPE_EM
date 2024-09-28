libname inclab 'D:\Research\WB\RPE_EM\IncLab_data';
libname my 'D:\Research\WB\RPE_EM\data_code';

/********  This file computes 
1. value-weighted performance period from the vesting period in the relative table
and use fair value from grant table as weights 
2. Firms that use each other as peers;
3. Compute RPE pct and dummy without considering salary and bonus;
4. Compute RPE pct and dummy with salary and bonus;
5. Pct of RPE firms using peers
*******************/

/* create peer list with ticker and company name */
* Get peers;
proc sql;
    create table relpeer as select unique a.cik, b.fycompustat, a.peercik, a.peerTicker, a.peername
	from inclab.gpbarelpeer as a left join my.grant_fvj as b
	on a.grantid = b.grantid
	where a.cik~='' and peercik ~= .
    order by cik, fycompustat;
quit;

data relpeer; set relpeer; peercik2 = put(peercik,z10.);
drop peercik;
rename peercik2 = peercik;
run;

* Get ticker and company name for RPE firms from compayfy;
data companyfy; set inclab.companyfy; 
fycompustat = fiscalYear; /* use fiscalyear instead of fiscalyearend cause the former is fully available, while the latter not */
if fiscalmonth = 6 then fyCompustat=fyCompustat+1;/*Inclab defines fiscal year as calendar year -1 if fiscal year ends on or before July 10th; while compustat defines it as before June*/
run;

proc sql;
create table relpeer2 as select a.fycompustat, a.cik, b.Ticker, b.companyName, a.peercik, a.peerticker, a.peername
from relpeer as a left join companyfy as b
on a.cik=b.cik and a.fycompustat = b.fycompustat;

* check uniqueness by ticker and peerticker;
proc sql; 
create table temp as select *, count(*) as c from relpeer2
group by fycompustat, ticker, peerticker
order by c desc, fycompustat, ticker , peerticker; 
quit;

* drop duplicates;
proc sort data=relpeer2 nodup; by _all_; run;

data my.relpeer; set relpeer2; run;

/******** 1. compute value-weighted performance period ;**********/
data grant; set inclab.grant_fvj; run;

proc sql;
create table relgrant as select a.*, b.cik, b.fiscalyear, b.fycompustat, FV_w
from inclab.gpbarel as a left join inclab.grant_fvj as b
on a.grantid=b.grantid
order by fiscalyear, cik, grantid;
quit;

proc sql;
create table relgrant2 as select *, count(grantid) as numobj 
from relgrant
group by grantid;
quit;

data relgrant3; set relgrant2;
FV_obj = FV_w;
if numobj>1 then FV_obj = FV_w/numobj;
run;

proc sql;
create table temp as select fiscalyear, cik, sum(FV_obj* (vesthigh-vestlow) )/sum(FV_obj) as wperformanceperiod
from relgrant3
group by fiscalyear, cik
order by fiscalyear, cik;
quit;

proc means data = temp MEAN STD min max P1 P5 P25 P50 P75 P95 P99 max; 
class fiscalyear;
vars wperformanceperiod; output out=temp1;
run;


/************ 2. Firms that use each other as peers **************/
data relpeer; set inclab.gpbarelpeer; run;
proc sort data=relpeer nodupkey; by _all_; run;*0 duplicates;

* unique peers for each firm;
proc sql;
create table relpeer2 as select unique cik, peercik, peerticker, peername
from relpeer;
quit;

data relpeer2; set relpeer2; cik2= input(cik, Best.); run;

proc sql;
create table peertopeer as select a.*,b.peercik as peerofpeer
from relpeer2 as a left join relpeer2 as b
on a.peercik = b.cik2;
quit;

data temp1; set peertopeer; if cik2=peerofpeer; run; * 1847;
proc sort data=temp1 nodupkey; by cik2; run; *390 out of a total of 2097 firms use each other as peers. Among them, 1847/390=4.7 peers use the firm of interest as peers;


********** By years;
* get fyear from grant_fvj;
proc sql;
    create table relpeer as select unique a.cik, b.fycompustat, a.peercik
	from inclab.gpbarelpeer as a left join my.grant_fvj as b
	on a.grantid = b.grantid
	where a.cik~='' and peercik ~= .
    order by cik, fycompustat;
quit;

data relpeer; set relpeer; cik2 = input(cik, Best.); run;*change RPE cik to numberic to be consistent with peercik;

proc sql;
create table peertopeer as select a.*, b.peercik as peerofpeer
from relpeer as a left join relpeer as b
on a.peercik = b.cik2 and a.fycompustat = b.fycompustat;
quit;

data peertopeer; set peertopeer; if peerofpeer = cik2; run;

* nb of peers that peer back; *1515 out of 2476  = 61% firm-years have peers peered back;
proc sql;
create table pct_peerback as select cik, fycompustat, count(*) as N_peerback from peertopeer
group by cik, fycompustat
order by cik, fycompustat;
quit;

* nb of peers; 
proc sql; 
create table temp as select cik, fycompustat, count(*) as N_peers from relpeer
group by cik, fycompustat
order by cik, fycompustat;
quit;

* compute the pct ;
proc sql;
create table pct_peerback as select a.*, b.n_peerback, n_peerback/n_peers as pct_peerback
from temp as a left join pct_peerback as b
on a.cik=b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat;
quit;

data pct_peerback; set pct_peerback; if pct_peerback = . then pct_peerback = 0; run;

proc export data=pct_peerback outfile='D:\RPE\RPE_EM\data_code\pct_peerback.dta' replace;run;

/** Pct of peers using RPE **/
* get fyear from grant_fvj;
proc sql;
    create table relpeer as select unique a.cik, b.fycompustat, a.peercik
	from inclab.gpbarelpeer as a left join my.grant_fvj as b
	on a.grantid = b.grantid
	where a.cik~='' and peercik ~= .
    order by cik, fycompustat;
quit;

data relpeer; set relpeer; cik2 = input(cik, Best.); run;*change RPE cik to numberic to be consistent with peercik;

proc sql;
create table peertopeer as select a.*, b.peercik as peerofpeer
from relpeer as a left join relpeer as b
on a.peercik = b.cik2 and a.fycompustat = b.fycompustat;
quit;

data peertopeer; set peertopeer; if peerofpeer ~= .; run;

* nb of peers using RPE; *2099 out of 2476  = 85% firm-years have peers peered using RPE;
proc sql;
create table pct_peerRPE as select cik, fycompustat, count(distinct peercik) as N_peerRPE from peertopeer
group by cik, fycompustat
order by cik, fycompustat;
quit;

* nb of peers; 
proc sql; 
create table temp as select cik, fycompustat, count(*) as N_peers from relpeer
group by cik, fycompustat
order by cik, fycompustat;
quit;

* compute the pct ;
proc sql;
create table pct_peerRPE as select a.*, b.n_peerRPE, n_peerRPE/n_peers as pct_peerRPE
from temp as a left join pct_peerRPE as b
on a.cik=b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat;
quit;

data pct_peerRPE; set pct_peerRPE; if pct_peerRPE = . then pct_peerRPE = 0; run;

proc means data=PCT_PEERRPE mean median min max P1 P5 P10 P25 P75 P90 P95 P99 max;
VAR pct_peerRPE;
run;

proc export data=pct_peerRPE outfile='D:\RPE\RPE_EM\data_code\pct_peerRPE.dta' replace;run;


/************** 3. RPE Percentage and Dummy without considering salary and bonus ********************/
/* CIK and lpermno are one-to-many relation for a given year, except that 1 cik may have lpermno missing and available at the same year;
so we can conduct all firm-year analysis using cik-year;
* 1 permno for multiple ciks;
data temp; set my.grant_fvj;keep cik lpermno fiscalyear fycompustat; if lpermno~=.; run; 
proc sort data=temp nodupkey; by cik fiscalyear; run;
data temp0; set temp; run;
proc sort data=temp0 nodupkey dupout=temp1; by lpermno fiscalyear; run;
proc sql;create table temp2(where=(lpermno=13622 and fiscalyear=2012)) as select * from temp0;quit;
*1 cik for 1 lpermno, although 1 cik may have lpermno missing or available, making it look like corrresponding to 2 lpermnos;
data temp; set my.grant_fvj;keep cik lpermno fiscalyear; if lpermno~=.; run; 
proc sort data=temp nodupkey; by lpermno fiscalyear; run;
data temp0; set temp; run;
proc sort data=temp0 nodupkey dupout=temp1; by cik fiscalyear; run;
*/

/*282 cik-year sometimes have permno and sometimes not;
proc sql;
create table temp1 as select unique cik, fiscalyear, lpermno
from my.grant_fvj;
data temp1; set temp1; if lpermno=. then lpermno=0;run;
proc sql;
create table temp2 as select *, count(lpermno) as cc from temp1
group by cik, fiscalyear order by cik, fiscalyear; 
data temp3; set temp2; if cc>1;run;

* print out the 99 lpermnos corresponding to multiple ciks;
data temp; set my.grant_fvj;if lpermno~=.; run; 
proc sort data=temp nodupkey; by cik fiscalyear; run;
proc sql; create table temp0 as select *, count(cik) as cc from temp 
group by lpermno, fycompustat;quit;
data temp1; set temp0; if cc>1; run;
proc sort data=temp1; by lpermno fycompustat cik; run;
*/

* compute total fair value for each firm;
* 24073 firm-years;
data grant; set my.grant_fvj(where=(D_ADRs=0)); keep cik fycompustat grantid fv_w; run;

proc sort data=grant; by cik fycompustat; run;
proc means data=grant noprint;
vars fv_w;
by cik fycompustat;
output out=grant_firm sum=fv_firm; 
run;

* compute total RPE FV of each firm using RPEs from rel;
/* One-time check: diff in grants bw rel and relpeer;
data rel; set inclab.gpbarel; run;
data relpeer; set inclab.gpbarelpeer;run;

proc sort data=rel;by grantid; run; proc sort data=relpeer; by grantid; run;
data temp; merge rel(in=a) relpeer(in=b);by grantid;
d=0;
if a and not b then d=1;
if b and not a then d=-1;
run;

proc freq data=temp; table d; run;
*/
*5556 firm-years;
proc sql;
    create table temp as select unique a.grantid, b.cik, b.fycompustat, b.fv_w
	from inclab.gpbarel as a left join my.grant_fvj(where=(D_ADRs=0)) as b
	on a.grantid = b.grantid
    order by cik, fycompustat;
quit;

proc means data=temp noprint;
    vars fv_w;
    by cik fycompustat;
    output out=RPEgrant_firm sum=fv_RPE; 
run;

* compute RPE pct;
proc sql;
    create table rpepct as select a.cik, a.fycompustat, fv_RPE, fv_firm, fv_RPE/fv_firm as RPEpct
	from RPEgrant_firm as a left join grant_firm as b
	on a.cik=b.cik and a.fycompustat = b.fycompustat
	order by cik, fycompustat;
quit;

data rpepct; set rpepct; D_RPE=1; run;

data my.rpepct; set rpepct; run;

/************** 4. RPE Percentage and Dummy including salary and bonus ********************/

/***************** Data cleaning SumComp ************
Note: 
1. SumComp assigning 138 participantids to different people and I determine the right 
person by using the difference between stockawards reported in SumComp and total stock fair values
computed in grant_fvj; If the difference is the same, then choose the record with the highest total compensation.
2. All the participants in gpbagrant are included in SumComp.
*******************/
data comp; set inclab.sumcomp;run;
proc sort data=comp nodupkey; by _all_; run; * drop 12 duplicates;

/* 138 participantids are assigned to more than 1 person; Find the right person by matching stockaward $ value */
proc sql;
create table comp as select *, count(*) as count from comp
group by cik, participantid, fiscalyear
order by count;
quit;

data comp; set comp;
totalcomp2 = sum(salary,bonus,stockawards,optionawards,nonequitycomp,pensionnqdc,othercomp);
run;

* 77331 obs;
proc sql;
create table temp as select cik, fiscalyear,participantid,sum(FV_w) as FV_stock
from my.grant_fvj
where awardtype1 = 'stock'
group by cik, fiscalyear,participantid;
quit;

proc sql;
create table comp2 as select a.*, b.FV_stock 
from comp as a left join temp as b
on a.cik=b.cik and a.participantid=b.participantid and a.fiscalyear=b.fiscalyear;
quit;

data comp2; set comp2;
DiffStock = stockawards - FV_stock;
run;

data temp; set comp2; if count>1; DiffStockAbs = abs(Diffstock); run;

proc sort data=temp; by cik participantid fiscalyear DiffStockAbs descending totalComp2;run;

data temp0; set temp; 
by cik participantid fiscalyear DiffStockAbs descending totalcomp2;
if first.DiffStockAbs; run;

data temp1; set temp0;
by cik participantid fiscalyear DiffStockAbs;
if first.fiscalyear; run;

data comp; set comp2; if count=1;run;
proc datasets; append base=comp data=temp1 force;run;*136630+138;

data my.sumComp; set comp; run;

data comp; set comp; DiffPct = DiffStock/stockawards; run;

proc means data=comp mean median min max P1 P5 P10 P25 P75 P90 P95 P99 max;
VAR diffpct;
run;

* check whether participantids are the same at SumComp and grant tables;
* All individuals in grant table are included in SumComp;
proc sql; *125250;
create table temp0 as select unique cik, participantid, fiscalyear from my.grant_fvj;

proc sql; *136768;
create table temp1 as select unique cik, participantid, fiscalyear from comp;

proc sql; *125250;
create table temp2 as select a.* from temp0 as a left join temp1 as b
on a.cik=b.cik and a.participantid=b.participantid and a.fiscalyear=b.fiscalyear;


/******* Compute RPE pct with salary **********/
proc sql;
create table grant_salary as select a.*,b.salary,bonus,stockawards,optionawards,nonequitycomp,pensionnqdc,othercomp
from my.grant_fvj(where=(D_ADRs=0)) as a left join my.sumcomp as b
on a.cik=b.cik and a.participantid=b.participantid and a.fiscalyear=b.fiscalyear
order by cik, participantid, fiscalyear;
quit;

proc sql;
create table grant_salary as select *, count(*) as countofgrantforeachperson
from grant_salary 
group by cik, participantid, fiscalyear;
quit;

data my.grant_salary; set grant_salary; run;

* compute total compensation of each firm;
* 24073 firm-years;
*sum comp for each grant;
proc sql;
create table comp_firm as select  *,
sum( fv_w, 1/countofgrantforeachperson * sum(salary,bonus) ) as comp 
from my.grant_salary;
quit;

* sum comp for each firm-year;
proc sql;
create table comp_firm2 as select unique cik, fycompustat, sum(comp) as TotComp
from comp_firm
group by cik, fycompustat;
quit;

* compute total RPE FV of each firm using RPEs from rel;
/* One-time check: diff in grants bw rel and relpeer;
data rel; set inclab.gpbarel; run;
data relpeer; set inclab.gpbarelpeer;run;

proc sort data=rel;by grantid; run; proc sort data=relpeer; by grantid; run;
data temp; merge rel(in=a) relpeer(in=b);by grantid;
d=0;
if a and not b then d=1;
if b and not a then d=-1;
run;

proc freq data=temp; table d; run;
*/
*5556 firm-years excluding ADRs et al;
proc sql;
    create table temp as select unique a.grantid, b.cik, b.fycompustat, b.fv_w
	from inclab.gpbarel as a left join my.grant_fvj(where=(D_ADRs=0)) as b
	on a.grantid = b.grantid
    order by cik, fycompustat;
quit;

proc means data=temp noprint;
    vars fv_w;
    by cik fycompustat;
    output out=RPEgrant_firm sum=fv_RPE; 
run;

* compute firm RPE pct;
proc sql;
    create table rpepct as select b.cik, b.fycompustat, fv_RPE, TotComp, fv_RPE/TotComp as RPEpct
	from RPEgrant_firm as a right join comp_firm2 as b
	on a.cik=b.cik and a.fycompustat = b.fycompustat
	order by cik, fycompustat;
quit;

data rpepct; set rpepct; D_RPE=1; if rpepct <0 then D_RPE=0; run;


/************** CEO RPE Percentage *****************************/

/**Generate a CEO list from inclab.participantFY and correct the wrong CEOs.
Notice that I dropped the CEOs who have no grant info in inclab.grant_fvj.
Luckily, most grants can be merged. 
********************/

data parti; set inclab.participantfy; run;
proc sort data=parti nodupkey dupout=temp; by _all_; run;*54 out of 356432 duplicate;

data CEO; set parti; if currentCEO=1; run; * 25348;

*Number of CEOs per firm per fyear;
proc sql;
create table CEO as select *, count(*) as N_CEO from CEO /* 298 duplicates: some are wrong, some are co-CEOs*/
group by cik, fiscalyear
order by N_CEO;
quit;

data CEO; set CEO;
if fullname='Aaron J. Nahmad' and fiscalyear=2012 then delete;
if fullname='WILLIAM _ KAMER' and fiscalyear=2009 then delete;
run;

data temp; set ceo; if N_CEO > 1;run; *2%;

data my.CEO; set CEO; run;

/* 
proc sql;
create table CEOgrant as select a.*, b.grantid, grantdate, fycompustat,awardtype, performancetype, nonEquityThreshold,nonEquityTarget,nonEquityMax,equityThreshold,equityTarget,equityMax,
stockAward,optionAward,exercisePrice,expirationDate,performanceGrouping,vestingSchedule,grantDateFV,FV_w
from my.ceo as a left join my.grant_fvj as b
on a.cik=b.cik and a.participantid = b.participantid and a.fiscalyear=b.fiscalyear
order by cik, participantid, fiscalyear;
quit;

data temp; set ceogrant; if grantid=.;run;*2084/65319;

data temp0; set temp; if N_ceo > 1; run; * 109;

data my.CEOgrant; set ceogrant; if grantid ~=. ;run; *drop CEOs who do not have grants;

* Check how many firms are dropped after including CEO info;
proc sql;create table temp as select unique cik from my.grant_fvj; *2097 firms;
proc sql;create table temp as select unique cik, fiscalyear from my.grant_fvj; *24788 firm-year in total;
proc sql;create table temp0 as select unique fiscalyear, count(*) from temp group by fiscalyear;

proc sql;create table temp as select unique cik from my.ceogrant; *2072 firms;
proc sql;create table temp as select unique cik, fiscalyear from my.ceogrant; *23037 firm-year in total;
proc sql;create table temp0 as select unique fiscalyear, count(*) from temp group by fiscalyear;

* Missing FVs ;
proc sql;
create table temp as select unique cik, fiscalyear, sum(FV_w) as sum_FV 
from my.ceogrant
group by cik, fiscalyear;
data temp1; set temp; if sum_FV=.;run; *1919 / 23037 = 8%;

* 26% of firm-fiscalyear do not have fair value for all grants;
data temp0; set my.ceogrant;if FV_w=.;run;
proc sort data=temp0 nodupkey; by cik fiscalyear; run;*5947 / 23037 = 26%;

*/

/* CEO RPE pct */
proc sql;
create table ceo_grant as select a.*
from grant_salary as a join my.ceo as b 
on a.cik=b.cik and a.participantid = b.participantid and a.fiscalyear=b.fiscalyear
order by cik, participantid, fiscalyear;
quit;

* 22427 firm-year;
*sum comp for each grant;
proc sql;
create table CEOcomp_firm as select *,
sum( fv_w,1/countofgrantforeachperson * sum(salary,bonus) ) as comp 
from ceo_grant;
quit;

* sum comp for each firm-year;
proc sql;
create table CEOcomp_firm2 as select unique cik, fycompustat, sum(comp) as CEOTotComp, sum(fv_w) as CEOTotGrant
from CEOcomp_firm
group by cik, fycompustat;
quit;

* 5199 firm-years;
proc sql;
    create table temp as select unique a.grantid, b.cik, b.fycompustat, b.fv_w
	from inclab.gpbarel as a join CEO_GRANT as b
	on a.grantid = b.grantid
    order by cik, fycompustat;
quit;

proc means data=temp noprint;
    vars fv_w;
    by cik fycompustat;
    output out=CEORPEgrant_firm sum=CEOfv_RPE; 
run;

* compute RPE pct;
proc sql;
    create table CEOrpepct as select b.cik, b.fycompustat, CEOfv_RPE, CEOTotComp, CEOfv_RPE/CEOTotComp as CEORPEpct, CEOfv_RPE/CEOTotGrant as CEORPETotGrantpct
	from CEORPEgrant_firm as a right join CEOcomp_firm2 as b
	on a.cik=b.cik and a.fycompustat = b.fycompustat
	order by cik, fycompustat;
quit;

proc sort data=CEOrpepct; by fycompustat; run;
proc means data=CEOrpepct; var CEORPEpct CEORPETotGrantpct; by fycompustat; run;

data CEOrpepct; set CEOrpepct; D_CEORPE=1; if CEOrpepct <0 then D_CEORPE=0; run;

* Combine with firm rpepct; *24073;
proc sql;
create table rpepct2 as select a.*, b.CEOfv_RPE, CEOTotComp, CEORPEpct, D_CEORPE
from rpepct as a full join CEOrpepct as b
on a.cik=b.cik and a.fycompustat=b.fycompustat;
quit;

data temp; set rpepct2; if ceorpepct > rpepct; run;

proc means data=rpepct2 mean median std MIN P1 P5 P10 P90 P95 P99 MAX;
vars rpepct ceorpepct;
run;

data my.rpepct; set rpepct2; run;


/* Dummy ceorpepct if the ceo grant fv is incomplete */
*denote 1 if any fv in a grant misses fv;
proc sql;
create table temp as select unique *, 
max(missing(fv_w),missing(salary),missing(bonus)) as D_ceofvmissing
from ceo_grant
order by D_ceofvmissing desc;

* denote 1 if any grant is incomplete;
proc sql;
create table temp1 as select unique cik, fycompustat, max(D_ceofvmissing) as D_ceofvmissing
from temp
group by cik, fycompustat
order by D_ceofvmissing desc; *10696 / 22427=48% misses full info of ceo grant fv;

* combine with pct;
proc sql;
create table rpepct as select a.*, b.D_ceofvmissing 
from my.rpepct as a left join temp1 as b
on a.cik=b.cik and a.fycompustat=b.fycompustat;
quit;

data my.rpepct; set rpepct; run;

proc export data=my.rpepct outfile='D:\RPE\RPE_EM\data_code\rpepct.dta' replace;run;

* compute number of firms, pct of RPE usage, average RPE pct, average CEO RPE pct for each year;
data temp; set rpepct; if fycompustat>2005;run;
proc sql;create table temp1 as select unique fycompustat, count(*) as n_firms, sum(d_rpe)/count(*) as rpeusage, mean(rpepct) as rpepct, mean(CEORPEpct) as ceorpepct
from temp
group by fycompustat;
quit;

* plot pct of firms using RPE;
ods listing gpath='D:\Research\WB\RPE_EM\data_code\';
ods graphics / imagename="RPE usage" imagefmt=png noborder;
proc sgplot data=temp1;
  scatter x=fycompustat y=rpeusage;
  xaxis label="Year" values= (2006 to 2016 by 1) valueshint;
  yaxis label="RPE usage" ;
  run;

ods listing gpath='D:\Research\WB\RPE_EM\data_code\';
ods graphics / imagename="RPE pct in RPE firms" imagefmt=png noborder;
proc sgplot data=temp1;
  scatter x=fycompustat y=rpepct;
  xaxis label="Year" values= (2006 to 2016 by 1) valueshint;
  yaxis label="RPE usage" ;
  run;


/**** 5. Pct of RPE firms using peers ****/
proc sql;create table sum_relpeer as select unique cik, fycompustat, count(*) as N_peers 
from my.relpeer
group by cik, fycompustat
order by cik, fycompustat; 

proc sql; create table rpepct as select a.*,b.N_peers from my.rpepct(where=(d_rpe=1)) as a left join sum_relpeer as b
on a.cik=b.cik and a.fycompustat=b.fycompustat
order by cik, fycompustat;

data rpepct; set rpepct; d_peer=0; if N_peers~=. then d_peer=1; run;

proc sql;create table sum_rpepct as select unique fycompustat, mean(N_peers) as avg_N_peers, median(N_peers) as median_N_peers,sum(d_peer)/sum(d_rpe) as pct_peer_rpe 
from rpepct
group by fycompustat;
quit; 

proc means data=sum_rpepct(where=(fycompustat>2005)); var pct_peer_rpe; run;

