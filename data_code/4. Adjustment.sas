/******************  Adjustments  ******************;
This file 1) identifies common shares; 
2) adjusts splitted shares; 
3) check the percentage of abnormal K/S ratio if we use orginal date instead of corrected one
******/

libname crsp 'D:\Data\CRSP';
libname inclab 'D:\RPE_EM\IncLab_data';
libname my 'D:\RPE_EM\data_code';

/**** Non-common shares *****/
*identify non-common shares in option;
proc sql;
create table optionfv2 as select a.*,b.shrcd
from my.optionfv as a left join crsp.msenames as b
on a.lpermno = b.permno and a.datadate < b.nameendt and a.datadate > b.NAMEDT;
quit;

data my.optionfv; set optionfv2; 
D_ADRs = 1;
* if shrcd in (10,11) then D_ADRs=0; *107946 common shares out of 118787 grants;
if shrcd in (10,11,12,18) then D_ADRs=0; *117350 out of 118787 grants;
run; 

proc freq data=optionfv;
table shrcd;
run;

proc sql;
create table temp0 as select *, count(*) as N
from optionfv;
quit;

proc sql;
create table temp1 as select distinct shrcd, count(*) as N_shrcd, count(*)/N as shrcd_pct
from temp0
group by shrcd;
quit;

* identify non-common shares for all grants;
proc sql;
create table temp0 as select a.*,b.shrcd
from my.grant_fvj as a left join crsp.msenames as b
on a.lpermno = b.permno and a.grantdate < b.nameendt and a.grantdate > b.NAMEDT;
quit;

data my.grant_fvj; set temp0; 
D_ADRs = 1;
* if shrcd in (10,11) then D_ADRs=0;  * 290618 common shares out of 335417;
if shrcd in (10,11,12,18) or shrcd =. then D_ADRs=0;*328200;
run;

proc sql;
create table temp0 as select *, count(*) as N
from grant_fvj(where=(fycompustat>2005));
quit;

proc sql;
create table temp1 as select distinct shrcd, count(*) as N_shrcd, count(*)/N as shrcd_pct
from temp0
group by shrcd;
quit;


/**** Split *****/
/*
data split; set crsp.dseall;
where distcd=5523 and 
1998<=year(date)<=2016 and facshr>=0.25
and shrcd in (10,11);
keep permno date facshr;
run;
*/

/* Adjust Split for Options */
data companyfy; set inclab.companyfy;run;
proc sort data=companyfy; by cik fiscalyear;run;
data companyfy; set companyfy;
facshr2 = ( 1/lag(splitAdjustmentFactor) - 1/splitAdjustmentFactor ) * splitAdjustmentFactor;
*if fiscalyear ~= 1+lag(fiscalyear) or cik~=lag(cik) then facshr2 = .;*SAS takes a combination of '~' and 'or' as and;
if fiscalyear ~= 1+lag(fiscalyear) then facshr2 = .;
if cik~=lag(cik) then facshr2 = .;
run;

proc sql;
create table optionfv as select a.*, b.filingDate,b.splitAdjustmentFactor,b.facshr2
from my.optionfv as a left join companyfy as b
on a.cik=b.cik and a.fiscalyear=b.fiscalyear;
quit;

/* compare factor compusted from IncLab with CRSP;
data temp; set optionfv; if facshr2=0 then facshr2 = .; run;
proc sort data=temp nodupkey; by cik fiscalyear grantdate; run; *29,003; 

data temp0; set temp; if facshr2=. and splitadjustmentfactor~=.;run;

data temp0; *62, all before 2006;
retain cik lpermno fiscalyear grantdate filingDate facshr facshr2 splitAdjustmentFactor; 
set temp; 
keep cik lpermno fiscalyear grantdate filingDate facshr facshr2 splitAdjustmentFactor; 
if abs(facshr-facshr2) > .1;
run;

data temp1; *497;
retain cik lpermno fiscalyear grantdate filingDate facshr facshr2 splitAdjustmentFactor; 
set temp; 
keep cik lpermno fiscalyear grantdate filingDate facshr facshr2 splitAdjustmentFactor; 
if facshr2 ~=. and facshr=.;
run;

PROC print data=optionfv;where cik='0000711065' and fiscalyear=1999;run;
proc print data=optionfv; where cik='0000022356' and fiscalyear=2014; run;
proc print data=optionfv; where cik='0000879101' and fiscalyear=2001; run;
proc print data=optionfv; where cik='0000004962' and fiscalyear=2000; run;
proc print data=my.grant_fvj;where cik='0000915389' and fiscalyear=2011;run;
proc print data=temp; where cik='0000915389' and fiscalyear=2011;run;
*/

/*
proc sql;
create table optionfv2 as select a.*, b.FACSHR, b.date
from optionfv as a left join split as b
on a.lpermno=b.permno and a.grantdate < b.date < a.filingdate;
quit; 

proc sort data=optionfv2; by cik grantid date; run;

data optionfv3; set optionfv2;
by cik grantid date;
if first.grantid;
run;
*/

* Don't get SAS confused by renaming and using new variables in 1 data step;
data optionfv; set optionfv; 
drop facshr date D_split prc_split;
rename facshr2 = facshr;
run;

data optionfv; set optionfv;
D_split=1;
if (facshr =. or facshr =0) then D_split=0;
prc_split = prc / (1+facshr);
run;

proc sql;
create table optionfv2 as select a.*,b.stockaward, b.equitytarget
from optionfv as a left join my.grant_fvj as b
on a.grantid=b.grantid
order by cik, fiscalyear, grantid;
quit;

*exerciseprice is adjusted based on KtoS. Here, we use original exerciseprice and adjusted price;
data optionfv2; set optionfv2;
if D_split=1 then
FV_w = optionaward * blkshclprc(exerciseprice, optionterm, prc_split*exp((-divy_w)*optionterm), intyield, std_w);
if D_split=1 and stockaward ~=-9999 and awardtype in ('sarCash','sarEquity') then 
FV_w = stockaward * blkshclprc(exerciseprice, optionterm, prc_split*exp((-divy_w)*optionterm), intyield, std_w);
if D_split=1 and optionaward =. and stockaward =. and equitytarget ~=-9999 then
FV_w = equitytarget * blkshclprc(exerciseprice, optionterm, prc_split*exp((-divy_w)*optionterm), intyield, std_w);
run;

data my.optionfv; set optionfv2; run;


/* Analysis on the impact of splits */
data temp0; set optionfv; if facshr=. and splitadjustmentfactor~=.;run; *7%;

* 7150 grants split, i.e, 6%;
proc means data=optionfv(where=(D_ADRs=0)) sum; 
vars D_split;
run;

* 5988 out of 7950 splitted grants in the money;
data temp0; set optionfv; if D_ADRs=0 and D_split=1 and KtoS<1 and KtoS~=.; run;

* 10649 deep in the money;
data temp1; set optionfv; if D_ADRs=0 and D_split=0 and KtoS<1/1.2 and KtoS~=.; run;

* 2.2% unsplitted grants deep in the money after 2005;
data temp1; set optionfv; if D_ADRs=0 and D_split=0 and KtoS<1/1.2 and KtoS~=. and fycompustat>2005; run;
data temp1; set optionfv; if D_ADRs=0 and D_split=0 and  fycompustat>2005; run;

/** For splitted deep in money options, set prc to strike;
data optionfv4; set optionfv4;
prc_split = .; 
if D_ADRs=0 and D_split=1 and KtoS<1/1.2 and KtoS ~=. then prc_split = exerciseprice_w;
run;

data optionfv5; set optionfv4; 
if D_ADRs=0 and D_split=1 and KtoS<1/1.2 and KtoS ~=.  then 
FV = optionaward * blkshclprc(exerciseprice, optionterm, prc_split*exp((-divy)*optionterm), intyield, std_ret_ann);
if D_ADRs=0 and D_split=1 and KtoS<1/1.2 and KtoS ~=.  then 
FV_w = optionaward * blkshclprc(exerciseprice_w, optionterm, prc_split*exp((-divy_w)*optionterm), intyield, std_w);
run;

data my.optionfv; set optionfv5; run;

data temp; set optionfv; where fycompustat >2005; run;*50819;
data temp0; set temp; where KtoS<1/1.2 and KtoS ~= .;run;*2133;
data temp0; set temp; where KtoS<1/1.2 and KtoS ~= . and grantdate_missingD=1;run;*50;
data temp0; set temp; where KtoS<1/1.2 and KtoS ~= . and D_ADRs=1;run;*270;
data temp0; set temp; where KtoS<1/1.2 and KtoS ~= . and grantdate_inaccurateD=1;run;*143;
data temp0; set temp; where KtoS<1/1.2 and KtoS ~= . and D_split=1;run;*1076;

proc sort data=temp; by KtoS; run;
*/

/* Adjust Split for grant */
proc sql;
create table grant as select a.*, b.filingDate, b.splitAdjustmentFactor,b.facshr2
from my.grant_fvj as a left join companyfy as b
on a.cik=b.cik and a.fiscalyear=b.fiscalyear;
quit;

/*
proc sql;
create table grant2 as select a.*, b.FACSHR, b.date
from grant as a left join split as b
on a.lpermno=b.permno and a.grantdate < b.date < a.filingdate;
quit; 

proc sort data=grant2; by cik grantid date; run;

data grant3; set grant2;
by cik grantid date;
if first.grantid;
run;
*/

data grant; set grant; 
rename facshr2 = facshr;
if optionaward = -9999 then optionaward =.;
if stockaward = -9999 then stockaward =.;
if equitytarget = -9999 then equitytarget =.;
if nonequitytarget = -9999 then nonequitytarget =.;
run;

* get option inputs;
proc sql;
create table grant2 as select a.*,b.std_w, divy_w, intyield, KtoS, exerciseprice_w,optionterm
from grant as a left join my.optionfv as b
on a.grantid = b.grantid;
quit;

data grant3; set grant2; 
D_split=1;
if facshr =. or facshr =0 then D_split=0;
prc_split = prc / (1+facshr);
run;

data grant4; set grant3;
if D_split=1 and awardtype in ('Option','phantomOption','reloadOption','sarEquity','sarCash') then
FV_w = optionaward * blkshclprc(exerciseprice, optionterm, prc_split*exp((-divy_w)*optionterm), intyield, std_w);
if D_split=1 and stockaward ~=. and awardtype in ('sarCash','sarEquity') then 
FV_w = stockaward * blkshclprc(exerciseprice, optionterm, prc_split*exp((-divy_w)*optionterm), intyield, std_w);
if D_split=1 and awardtype in ('Option','phantomOption','reloadOption','sarEquity','sarCash') 
and optionaward =. and stockaward =. and equitytarget ~=. then
FV_w = equitytarget * blkshclprc(exerciseprice, optionterm, prc_split*exp((-divy_w)*optionterm), intyield, std_w);
if D_split=1 and awardtype in ('cashLong','cashShort','unitCash') and nonequitytarget=. then FV_w = stockaward*prc_split;
if D_split=1 and awardtype in ('phantomStock','rsu','stock')  and stockaward ~=. then FV_w=stockaward*prc_split;
if D_split=1 and awardtype in ('phantomStock','rsu','stock')  and stockaward =. then FV_w = equitytarget*prc_split;
run;

* 49 grants miss awardtype, but do not have anything to estimate FV either;
data grant4; set grant4; 
if awardtype in ('Option','phantomOption','reloadOption','sarEquity','sarCash') then awardtype1='option';
if awardtype in ('cashLong','cashShort','unitCash') then awardtype1='cash';
if awardtype in ('phantomStock','rsu','stock') then awardtype1='stock';
run;

data my.grant_fvj; set grant4;run;
data my.grant_fvj; set my.grant_fvj; if FV_w <0 then FV_w = .; run;

* 15009 splits;
proc means data=grant4(where=(D_ADRs=0)) sum; 
vars D_split;
run;









/***  use Inclab grantdate instead of corrected grantdate; ***/
data optionfv; set my.optionfv;run;

data temp; set optionfv; where exerciseprice ~=. and grantdate_inaccurateD=1; run;

proc sort data=temp nodupkey; by cik grantdate prc; run;

data temp0; set temp; keep cik lpermno grantid grantdate fycompustat exerciseprice prc KtoS; run;

proc sql;
create table temp1 as select a.*, b.grantdate_inclab
from temp0 as a left join my.grant_grantdatemissingcorrected as b
on a.grantid=b.grantid
order by cik, lpermno, grantdate;
quit;

libname crsp 'D:\Data\CRSP';
proc sql;
create table temp2 as selct a.*, abs(b.prc) as prc_inclab 
from temp1 as a left join crsp.dsf_o as b
on lpermno = permno and grantdate_inclab=date
order by cik, lpermno, grantdate;
quit;

data temp3; set temp2; KtoS_new = exerciseprice/prc_inclab; 
D_inclabGrantdatehigherKtoS=0;if KtoS_new>KtoS then D_inclabGrantdatehigherKtoS=1;
D_inclabGrantdateKtoSg1 = 0; if KtoS_new>KtoS and KtoS<1 then D_inclabGrantdateKtoSg1 = 1;
run;

* using Inclab grantdate to merge price makes 46% of 463 grants a higher KtoS, among which, 91% for increasing KtoS <1;
proc sql; create table temp4 as select sum(D_inclabGrantdateKtoSg1) as sub, 
sum(D_inclabGrantdatehigherKtoS) as sum_D, count(*) as N, 
calculated sub/ calculated sum_D, calculated sum_D/ calculated N
from temp3; run;

data my.KtoS_IncLabGrantdate; set temp3; run;
