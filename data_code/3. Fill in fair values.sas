libname inclab '/home/mcgill/ljj3202';

data grant; set inclab.grant_GrantdateMissingCorrected;
if grantdatefv = -9999 then grantdatefv = . ;
run;

/********* get lpermno and gvkey for each firm ********/
libname comp '/wrds/comp/sasdata/nam';
libname crsp '/wrds/crsp/sasdata/a_stock';
libname crspa '/wrds/crsp/sasdata/a_ccm';

* to save computing time, I merge price with cik-fy-grantdate, and then merge it with each grant;
* 39648 unique cik-fy-grantdate obs;
data nonoption; set grant; run;
proc sort data=nonoption nodupkey;by cik cusip ticker fycompustat grantdate; 
where awardtype not in ('Option','phantomOption','reloadOption','sarEquity','sarCash');
run;

data nonoption; set nonoption;
keep cik cusip ticker fiscalyearend fyCompustat grantdate;
run;

*************** Primary merge using cik ***********;
proc sql;
create table link as select a.gvkey, a.CIK, a.cusip, a.tic, a.fyear, a.datadate, b.lpermno, b.lpermco, b.linkdt, b.linkenddt 
from comp.funda as a, crspa.CCMXPF_LNKHIST as b 
where a.gvkey=b.gvkey and fyear>1996 and 
INDFMT = 'INDL' AND DATAFMT = 'STD' AND POPSRC = 'D' AND CONSOL = 'C' and /*constraints on comp.funda*/
linkprim in ('P','C') and linktype in ('LU','LC','LN','LS');/*restrictions on link*/
quit;

*merge non-option and link using fiscalyearend ;
proc sql;
create table merge as select a.*,b.lpermno, b.lpermco,b.datadate, b.gvkey, b.linkdt,b.linkenddt
/* ,grantdate-linkdt as diff1, linkedndt-grantdate as diff2 */
from nonoption as a left join link as b
on a.cik=b.cik and fyCompustat=fyear  
and (a.grantdate >= b.linkdt or b.LINKDT = .B) and 
(b.linkenddt >= a.grantdate or b.LINKENDDT = .E) /* grantdate of cik '0000316300', etc, is 1 day before linkdt*/
order by cik, fycompustat, grantdate;
quit;

* 333 out of 1989 cik not matched;
data temp; set merge; where lpermno=.;run;
proc sort data=temp nodupkey;by cik;run;

************ Secondary merge using CUSIP *************;
data merge2; set merge; 
cusip1=substr(cusip,1,6);
format cusip1 $6.;
run;

data merge_cikincomp; set merge2;
where lpermno=. and cusip1 ~=''; 
drop lpermno lpermco datadate gvkey linkdt linkenddt;
run;

data link; set link;
cusip1=substr(cusip,1,6);
format cusip1 $6.;
run;

proc sql; 
create table merge_bycusip as select a.*, b.lpermno, b.lpermco,b.datadate, b.gvkey, b.linkdt,b.linkenddt
from merge_cikincomp as a left join link as b
on a.cusip1=b.cusip1 and fyCompustat=fyear  
and (a.fiscalyearend >= b.linkdt or b.LINKDT = .B) and 
(b.linkenddt >= a.fiscalyearend or b.LINKENDDT = .E) 
order by cusip1, fycompustat, grantdate;
quit;

data temp1; set merge_cikincomp;run;
proc sort data=temp1 nodupkey; by cusip1; run;
data temp2; set merge_bycusip;run;
proc sort data=temp2 nodupkey; by cusip1; run;

* correct duplicates caused by matching;
data temp; set merge_bycusip;run;
proc sort data=temp nodupkey dupout=dup1;by cik fycompustat grantdate;run;*35 duplicates;
proc freq data=dup1; table cusip1; run;
proc sort data=dup1 nodupkey; by cusip1; run;
data dup2; set dup1; keep cusip1; run;
proc print data=merge_bycusip; where cusip1 in ('05946K','37045V','53071M','G5480U'); run;
data merge_bycusip2; set merge_bycusip;
if cusip1='05946K' and linkenddt = .E then delete;
if cusip1='37045V' and linkdt ~=mdy(1,31,1962) and cik='0000040730' then delete;
if cusip1='53071M' and linkdt ~= mdy(5,10,2006) then delete;
if cusip1='G5480U' and fycompustat=2015 and linkdt ~= mdy(7,2,2015) then delete;
run;

proc print data=merge_bycusip2;where cusip1='37045V';run;

* confirm no duplicates;
data temp; set merge_bycusip2;run;
proc sort data=temp nodupkey dupout=dup1;by cik fycompustat grantdate;run;

*237 cik still not matched;
data temp; set merge_bycusip2; where lpermno=.;run;
proc sort data=temp nodupkey;by cik;run;

data merge_bycusip3; set merge_bycusip2; 
mergeD=.;
if lpermno ~= . then mergeD=2;*D equals 2 if it's merged in secondary stage;
run;

* append primary and secondary results*;
data merge3; set merge2;
mergeD = .;
if lpermno ~=. then mergeD = 1;*D equals 1 if it's merged in 1st stage;
if lpermno=. and cusip~='' then delete;
run;

proc append base=merge3 data=merge_bycusip3;run;

************ Tertiary merge using ticker ***************;
data temp; set merge3; where mergeD=.; run; *1458 obs not merged;

data merge_incomp; set merge3; 
where mergeD=. and ticker~=''; 
drop lpermno lpermco datadate gvkey linkdt linkenddt;
run; *1339 have ticker;

proc sql; 
create table merge_bytic as select a.*, b.lpermno, b.lpermco,b.datadate, b.gvkey, b.linkdt,b.linkenddt
from merge_incomp as a left join link as b
on a.ticker=b.tic and fyCompustat=fyear  
and (a.fiscalyearend >= b.linkdt or b.LINKDT = .B) and 
(b.linkenddt >= a.fiscalyearend or b.LINKENDDT = .E)
order by ticker, fycompustat, grantdate;
quit;

*0 duplicates;
data temp; set merge_bytic;run;
proc sort data=temp nodupkey dupout=dup1;by cik fycompustat grantdate;run;

data temp; set merge_bytic; where lpermno=.;run;*1077 not merged;

* merge with primary and secondary results;
data merge_bytic2; set merge_bytic; 
if lpermno ~= . then mergeD=3;*D equals 3 if it's merged in 3rd stage;
run;

* append with primary and secondary results*;
data merge4; set merge3;
if lpermno=. and ticker~='' then delete;
run;

proc append base=merge4 data=merge_bytic2;run;

* 37023 merged by cik, 1167 by cusip, 262 by ticker, 1196 not merged;
proc freq data=merge4; table mergeD; run;

data inclab.merge_compustat_nonoption; set merge4;run;

********* merge with price *************;
proc sql;
create table merge_price as select a.*, abs(prc) as prc, date as crspdate, intck('day',date,grantdate) as daydiff
from inclab.merge_compustat_nonoption as a left join crsp.dsf as b
on a.lpermno= b.permno 
where (0<=calculated daydiff <= 7 or calculated daydiff=.)
and date>='01Jul1997'd and date<='31dec2016'd
/* and prc is not missing */
order by cik, lpermno, fycompustat, grantdate, daydiff; 
run;

data merge_price2(drop=crspdate); set merge_price;
by CIK lpermno fycompustat grantdate daydiff;
if first.grantdate;
run;

* most merged on daydiff=0,1,2. no merge from daydiff=7 till 10;
proc freq data=merge_price2; table daydiff;run;

** get price and lpermno for each grant ** ;
proc sql;
create table grant2 as select a.*, b.mergeD, b.prc, gvkey, lpermno, lpermco, LINKDT, LINKENDDT
from grant as a left join merge_price2 as b
on a.cik=b.cik and a.fycompustat=b.fycompustat and a.grantdate=b.grantdate;
run;

data nonoption; set grant2;
where awardtype not in ('Option','phantomOption','reloadOption','sarEquity','sarCash');
FV_w = .;
run;

** combine option and nonoption  **;
proc sql;
create table grant3 as select a.*, b.mergeD, b.prc, gvkey, lpermno, lpermco, LINKDT, LINKENDDT, b.FV_w
from grant as a right join inclab.optionfv as b
on a.grantid = b.grantid;
quit;

proc append base=grant3 data=nonoption; run;

********************* Fill in fair values ***************;
proc freq data=grant3;
where FV_w = .;
table awardtype;
run;

data grant4; set grant3;
if nonequitytarget=-9999 then nonequitytarget = .; 
if equitytarget = -9999 then equitytarget = .; 
if stockaward = -9999 then stockaward = .; 
run; 

* 99 obs have equitytarget and stockaward both available but not equal;
data temp; set grant4; 
if awardtype in ('phantomStock','rsu','stock') 
and stockaward ~= . and equitytarget ~= . and stockaward~=equitytarget; 
run;

data temp; set temp;
FV_1 = stockaward * prc; FV_2= equitytarget*prc; run;

proc print data=temp;run;

* 60 obs have stockaward and nonequity both available;
data temp1; set grant4; 
if awardtype in ('cashLong','cashShort','unitCash')
and nonequitytarget ~=. and stockaward ~=. ;
run;

data temp1; set temp1;
FV1 = stockaward * prc; run;

proc print data=temp1; run;

* fill in fv;
data grant5; set grant4;
if awardtype in ('cashLong','cashShort','unitCash') then FV_w = nonequitytarget;
if awardtype in ('cashLong','cashShort','unitCash') and nonequitytarget=. then FV_w = stockaward*prc;
if awardtype in ('phantomStock','rsu','stock')  and stockaward ~=. then FV_w=stockaward*prc;
if awardtype in ('phantomStock','rsu','stock')  and stockaward =. then FV_w = equitytarget*prc;
run;


* 15370 obs;
data temp; set grant5; where grantdatefv~=. and FV_w=.;run;

proc freq data=grant5;
where FV_w = .;
table awardtype;
run;

* save;
data inclab.grant_FVj; set grant5;run;


**************** correction for cik='0000851205', whose fiscalyearend is wrong**************************************; 
data temp; set inclab.grant_fvj(where=(cik='0000851205'));
fiscalyearend=mdy(12,31,fiscalyear);
fycompustat=year(fiscalyearend);
drop grantdate;
run;

data temp1; set inclab.gpbagrant; if cik='0000851205';
keep cik fiscalyear grantid grantdate;
run;


* get the original grantdate back;
proc sql;
create table cik851205 as select a.*,b.grantdate from temp as a  right join temp1 as b
on a.grantid=b.grantid;
quit;

*correct missing grantdate;
data cik851205; set cik851205;
grantdate_inaccurateD = 0;
if year(grantdate)=9999 then grantdate_missingD = 1;
fiscalyearstart = intnx('day',intnx('year',fiscalyearend,-1,'same'),1,'same');
if year(grantdate)=9999 then grantdate = intnx('month',fiscalyearstart,2,'same');
run;

* price option;
proc sql;
create table option as select CIK, fiscalyear, fiscalmonth, grantid, grantdate, awardtype, 
stockaward, optionaward, exerciseprice, expirationdate, fiscalyearstart, fiscalyearend, fycompustat, 
grantdate_missingD, grantdate_inaccurateD 
from cik851205
where awardtype in ('Option','phantomOption','reloadOption','sarEquity','sarCash');  
quit; 

data option2; set option;
if year(expirationdate)=9999 then expirationdate = .;
expirationdate_missingD=0;
if expirationdate=. then expirationdate_missingD=1;
optionterm = (expirationdate-grantdate)/365;
run; 

libname comp '/wrds/comp/sasdata/nam';
libname crsp '/wrds/crsp/sasdata/a_stock';
libname crspa '/wrds/crsp/sasdata/a_ccm';

proc sql;
create table link as select a.gvkey, a.CIK, a.cusip, a.tic, a.fyear, a.datadate, b.lpermno, b.lpermco, b.linkdt, b.linkenddt 
from comp.funda as a, crspa.CCMXPF_LNKHIST as b 
where a.gvkey=b.gvkey and fyear>1996 and 
INDFMT = 'INDL' AND DATAFMT = 'STD' AND POPSRC = 'D' AND CONSOL = 'C' and /*constraints on comp.funda*/
linkprim in ('P','C') and linktype in ('LU','LC','LN','LS');/*restrictions on link*/
quit;

proc sql;
create table merge as select a.*,b.lpermno, b.lpermco,b.datadate, b.gvkey, b.linkdt,b.linkenddt
/* ,grantdate-linkdt as diff1, linkedndt-grantdate as diff2 */
from option2 as a left join link as b
on a.cik=b.cik and fyCompustat=fyear  
and (a.fiscalyearend >= b.linkdt or b.LINKDT = .B) and 
(b.linkenddt >= a.fiscalyearend or b.LINKENDDT = .E) /* grantdate of cik '0000316300', etc, is 1 day before linkdt*/
order by cik, grantid, grantdate;
quit;

proc sql;
create table merge_price as select a.*, abs(prc) as prc, date as crspdate, intck('day',date,grantdate) as daydiff
from merge as a left join crsp.dsf as b
on a.lpermno= b.permno 
where (0<=calculated daydiff <= 7 or calculated daydiff=.)
and date>='01Jul1997'd and date<='31dec2016'd
/* and prc is not missing */
order by cik, lpermno, grantid, daydiff; 
quit;


data merge_price2(drop=crspdate); set merge_price;
by CIK lpermno grantid daydiff;
if first.grantid;
run;

* merge with sd;
proc sql; 
create table merge_price_sd as select a.*, b.std_ret_ann
from merge_price2 as a left join inclab.monthly_std as b 
on a.lpermno=b.permno and year(grantdate)=yr and month(grantdate)=mt
order by cik, lpermno, grantid;
run;

* merge with dy;
proc sql;
create table merge_price_sd_dy as select a.*, b.divy
from merge_price_sd as a left join inclab.div_yield as b
on a.lpermno=b.permno and year(grantdate)=b.year
order by cik, lpermno, grantid;
run;

* merge with treasury yield;
data treasurycrsp; set inclab.tfz_dly_ft;
where year(caldt)>=1996;
keep caldt rdcrspid tdyearstm tdytm;
run;

proc sort data=treasurycrsp nodupkey;
by caldt tdyearstm;
run;

data treasurycrsp2; set treasurycrsp;
tdyearstm = tdyearstm*360/365;
tdytm=tdytm/100;
run;

* caldt is not available from 2001/9/11 to 2001/9/20 (inclusive), 
so to match grants during this period, I use treasury rate on 2001/9/10. 
To reduce search complexity, I create several new rows for bonds;
%macro rep(start,end);

  %let start=%sysfunc(&start); * convert to sas date;
  %let end=%sysfunc(&end);

  %let l=%sysfunc(intck(day,&start,&end));
  %do i = 1 %to &l;
  data rep; set treasurycrsp2; 
    where caldt=mdy(9,10,2001);
    caldt = %sysfunc(intnx(day,&start,&i,b));
    RDCRSPID = .;
  run;

  proc append base=treasurycrsp2 data=rep;run;
  %end;
%mend;

%rep(start=mdy(9,10,2001),end=mdy(9,20,2001));

proc sql;
      create table temp
      as select distinct e.caldt, max(tdyearstm) as myearstm, tdyearstm, tdytm
      from  treasurycrsp2 as e
      group by e.caldt
      having myearstm = tdyearstm;
quit;

data temp2; set temp;
tdyearstm = 1000;
drop myearstm;
run;

data treasurycrsp3; set treasurycrsp2 temp2;
run;

proc sort data = treasurycrsp3 nodupkey;
by caldt tdyearstm;
run;

/* create a lower bounday for terms less than min years to maturity*/
proc sql;
      create table temp
      as select distinct e.caldt, min(tdyearstm) as myearstm, tdyearstm, tdytm
      from  treasurycrsp2 as e
      group by e.caldt
      having myearstm = tdyearstm;
quit;

data temp2; set temp;
tdyearstm = 0;
drop myearstm;
run;

data treasurycrsp4; set treasurycrsp3 temp2;
run;

proc sort data = treasurycrsp4 nodupkey;
by caldt tdyearstm;
run;

*** Linear Interpolation ***
*get lower boundary for each grantid;
proc sql;
      create table temp
      as select e.*, s.tdyearstm, s.tdytm, intck('day',grantdate,caldt) as daydiff1
      from merge_price_sd_dy as e
      left join treasurycrsp4 as s
      on (grantdate=caldt or grantdate=caldt+1 or grantdate=caldt+2) and e.optionterm>=s.tdyearstm
      order by cik, lpermno, grantid, grantdate, daydiff1, tdyearstm;
quit;

data temp2; set temp;
by cik lpermno grantid grantdate daydiff1 tdyearstm;
if last.grantdate;
run;

* get upper boundary for each grant;
proc sql;
      create table temp3
      as select e.*, s.tdyearstm as tdyearstm2, s.tdytm as tdytm2, grantdate-caldt as daydiff2
      from temp2 as e
      left join treasurycrsp4 as s
      on (caldt<= grantdate <= caldt+3) and e.optionterm<=s.tdyearstm
      order by cik, lpermno, grantid, grantdate, daydiff2, tdyearstm2;
quit;

data temp4; set temp3;
by cik lpermno grantid grantdate daydiff2 tdyearstm2;
if first.grantdate;
run;

*interpolation;
data temp5; set temp4;
intyield=((optionterm-tdyearstm)/(tdyearstm2-tdyearstm))*(tdytm2-tdytm)+tdytm;
if tdytm=. and tdytm2 ~=. then intyield=tdytm2;
run;

data temp6; set temp5;
if optionterm ~=. and intyield = .;run;

data option_merged; set temp5; 
drop tdyearstm tdyearstm2 tdytm tdytm2 daydiff1 daydiff2;
run;

* skip winsorization since all related variable are within winsorized area;
/*
proc sql;
create table option_merge2 as select a.*, b.optionaward from
option_merged as a left join grant as b
on a.grantid=b.grantid;
run;
*/

data optionfv; set option_merged;
FV_w = optionaward * blkshclprc(exerciseprice, optionterm, prc*exp((-divy)*optionterm), intyield, std_ret_ann);
run;

data optionfv2; set cik851205; 
drop prc gvkey lpermno lpermco LINKDT LINKENDDT FV_w;
run;

proc sql;
create table optionfv3 as select a.*, b.prc, gvkey, lpermno, lpermco, LINKDT, LINKENDDT, b.FV_w
from optionfv2 as a right join optionfv as b
on a.grantid = b.grantid;
quit;

/* replace info in optionfv */
data optionfv; set my.optionfv; run;

proc sql;
create table optionfv4 as select a.*,b.datadate, b.daydiff,b.divy,
b.expirationdate_missingD,b.intyield,b.optionterm,b.std_ret_ann
from optionfv3 as a left join option_merged as b
on a.grantid=b.grantid;
quit;

proc sql;
create table optionfv5 as select a.*,b.optionterm_inaccurateD,b.FV
from optionfv4 as a left join my.optionfv as b
on a.grantid=b.grantid;
quit;

data optionfv6; set optionfv5;
D_grantdatebeforepricedate = 0;
D_w = 0;
KtoS = exerciseprice/prc;
KtoS_w = KtoS;divy_w=divy;exerciseprice_w = exerciseprice;std_w=std;
cusip1 = substr(cusip,1,6);format cusip1 $6.;
run;

* diff in variables bw the two tables;
proc contents data=optionfv out=all(keep=name);run;
proc contents data=optionfv6 out=sub(keep=name);run;
data temp1; merge all(in=a) sub(in=b); by name; if a and not b; run;

data optionfv; set my.optionfv; where cik ~='0000851205'; run;
proc append base=optionfv data=optionfv6 force; run;

data my.optionfv; set optionfv; run;


** non-option;
data nonoption; set cik851205; if awardtype not in ('Option','phantomOption','reloadOption','sarEquity','sarCash');run;

data nonoption2; set nonoption; 
if nonequitytarget ~=. and nonequitytarget ~=-9999 then FV_w = nonequitytarget;
run;

data cik851205_2; set optionfv3 nonoption2; run;

* replace;
data grant_temp; set inclab.grant_fvj; if cik~='0000851205';run;
data grant2; set grant_temp cik851205_2; run;
data inclab.grant_fvj2; set grant2;run;


