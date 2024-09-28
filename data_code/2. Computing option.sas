
libname inclab '/home/mcgill/ljj3202';

/************* Deal with missing and inaccurate expirationdate *********/

proc sql;
create table option as select CIK, fiscalyear, fiscalmonth, grantid, grantdate, awardtype, stockaward, optionaward, exerciseprice, expirationdate, fiscalyearstart, fiscalyearend, fycompustat, grantdate_missingD, grantdate_inaccurateD
from my.grant_GrantdateMissingCorrected 
where awardtype in ('Option','phantomOption','reloadOption','sarEquity','sarCash');   * 118787 out of 352506 observations fall in this type;
quit; 

data option2; set option;
if year(expirationdate)=9999 then expirationdate = .;*107 out of 118787 are 9999;

expirationdate_missingD=0;
if expirationdate=. then expirationdate_missingD=1;

optionterm = (expirationdate-grantdate)/365;
run; 

data temp; set option; if expirationdate=.;run; *2592 expirationdates, i.e., 2%, unavailable among 118787 observations;
data temp; set option; if expirationdate=. or exerciseprice=. ;run;*2830 unavailable;
data temp; set option; if optionaward=. or exerciseprice=. ;run; *5971 among 116195 unavailable, only 200+ due to missing exerciseprice;

/* inaccurate optionterm */
proc freq data=option2; table optionterm; run;
proc print data=option2; where optionterm <= 0 and optionterm ~=. ;run;
proc print data=option2; where optionterm >90 ;run;

data option3; set option2; 
yy = year(expirationdate);
mm = month(expirationdate);
dd = day(expirationdate);

if yy=6006 then yy=2006;
if yy=2103 then yy=2013;
if yy=2121 then yy=2021;
if yy=2104 then yy=2014;
if yy=5011 then yy=2011;
if yy=5016 then yy=2016;
if yy=2109 then yy=2019;
expirationdate1 = mdy(mm,dd,yy);
format expirationdate1 MMDDYY10.;
drop yy mm dd expirationdate optionterm;
rename expirationdate1 = expirationdate;
run;

data option4; set option3;
optionterm_inaccurateD = 0;
if optionterm <1 and optionterm ~=. then optionterm_inaccurateD = 1;
if optionterm <1 and optionterm ~= . then optionterm = 1;
run;

proc freq data=option4; table optionterm; run;

/******************************Link tables *********************************************/

/*
proc sql;
create table div as select date, permno, distcd, divamt from crsp.dse
where substr(put(distcd,6.),1,1) ='1';
quit;
*/

* get CIK from compustat;
libname comp '/wrds/comp/sasdata/nam';
libname crsp '/wrds/crsp/sasdata/a_stock';
libname crspa '/wrds/crsp/sasdata/a_ccm';

libname crsp 'D:\Data\CRSP';
libname comp 'D:\Data\CompNA';
libname crspa 'D:\Data\SAS linking data';

****************** merge grant and compustat *********************************; 
*************** Primary merge using cik ***********;
proc sql;
create table link as select a.gvkey, a.CIK, a.cusip, a.tic, a.fyear, a.datadate, b.lpermno, b.lpermco, b.linkdt, b.linkenddt 
from comp.funda as a, crspa.CCMXPF_LNKHIST as b 
where a.gvkey=b.gvkey and fyear>1996 and 
INDFMT = 'INDL' AND DATAFMT = 'STD' AND POPSRC = 'D' AND CONSOL = 'C' and /*constraints on comp.funda*/
linkprim in ('P','C') and linktype in ('LU','LC','LN','LS');/*restrictions on link*/
quit;

/* one to one bw gvkey and cik; 
data link1; set link;run;
proc sort data=link1 nodupkey;where cik~='';by cik fyear linkdt;run;
proc sort data=link1 nodupkey dupout=dup1;by gvkey fyear linkdt;run;

data link1; set link;run;
proc sort data=link1 nodupkey;where cik~='';by gvkey;run;
proc sort data=link1 nodupkey dupout=dup1;by cik fyear linkdt;run;
*/

*merge option and link using fiscalyearend instead of grantdate since many of the latter is approximated, using fiscalyearend also reduces unmatched numbers;
data option4; set inclab.option4;run;
proc print data=option4; where grantdate_missingD=0;run;*85513 out of 118787 grantdates are original;

proc sql;
create table merge as select a.*,b.lpermno, b.lpermco,b.datadate, b.gvkey, b.linkdt,b.linkenddt
/* ,grantdate-linkdt as diff1, linkedndt-grantdate as diff2 */
from option4 as a left join link as b
on a.cik=b.cik and fyCompustat=fyear  
and (a.fiscalyearend >= b.linkdt or b.LINKDT = .B) and 
(b.linkenddt >= a.fiscalyearend or b.LINKENDDT = .E) /* grantdate of cik '0000316300', etc, is 1 day before linkdt*/
order by cik, grantid, grantdate;
quit;

* 8630 observations, i.e., 304 cik do not have lpermno;
data temp; set merge; where lpermno=.;run;
proc sort data=temp nodupkey;by cik;run;


/* when dates used bw linkdt and linkenddt are not the same, delete the duplicates
* get id that duplicates;
data temp; set merge;run;
proc sort data=temp nodupkey dupout=dup;by grantid;run;*389 duplicates for grantid;
proc sort data=dup nodupkey; by grantid;run;
data dup; set dup; keep grantid; run;

proc sql;
create table temp as select a.* ,b.grantid as grantid_temp 
from merge as a left join dup as b
on a.grantid = b.grantid;
quit;

data temp2; set temp;
if grantid_temp^=. and (grantdate >= linkdt or LINKDT = .B) and 
(linkenddt >= grantdate or LINKENDDT = .E) then D=0; else D=1;
if grantid_temp^=. and D=1 then delete;
run; 

data merge2; set merge;
exactmerge = 0; 
by CIK grantid grantdate diff1 diff2;
if (diff1>=0 or diff1=.) and (diff2>=0 or diff2=.) then exactmerge=1;
else if diff1<0 and diff2>=0 and diff1~=. and diff2~=. and last.diff1 then exactmerge=2;
else if diff1>=0 and diff2<0 and diff1~=. and diff2~=. and last.diff2 then exactmerge=2;
run;

0000875159
0001017008
0001038914
0001166691

proc print data=merge2; where exactmerge in (1,2);run;
*/
libname inclab 'D:\RPE_EM\IncLab_data';


************ Secondary merge using CUSIP *************;
*cik is unique identifier, cusip is not, but does not change before or after merge, while cik does not;
data temp; set inclab.companyfy;where cusip ~='';cusip1=substr(cusip,1,6);format cusip1 $6.; run;*25315 out of 25384 obs have cusip;
proc sort data=temp nodupkey; by cik fiscalyear; run;*0 duplicates;
proc sort data=temp nodupkey dupout=dup1; by cusip fiscalyear;run;*27 duplicates, many due to 1 cusip corresponding to several cik, e.g., cusip='03999V93','04418610'; 
proc sort data=temp nodupkey dupout=dup2; by cusip1 fiscalyear;run;*24 duplicates, but caused by only 2 cusip1, i.e, '37045V' and '910047', which may refer to different companies;

data temp; set merge2; where lpermno=.;run; *8630 missing;
proc sort data=temp nodupkey;by cik;run;

data merge2; set merge; 
cusip1=substr(cusip,1,6);
format cusip1 $6.;
run;

data merge_cikincomp; set merge2;
where lpermno=. and cusip1 ~=''; 
drop lpermno lpermco datadate gvkey linkdt linkenddt;
run;*8281 out of 8630 obs have cusip;

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
order by cusip1, grantid, grantdate;
quit;

data temp1; set merge_cikincomp;run;
proc sort data=temp1 nodupkey; by cusip1; run;
data temp2; set merge_bycusip;run;
proc sort data=temp2 nodupkey; by cusip1; run;

* correct duplicates caused by matching;
data temp; set merge_bycusip;run;
proc sort data=temp nodupkey dupout=dup1;by grantid;run;*222 duplicates;
proc freq data=dup1; table cusip1; run;
proc sort data=dup1 nodupkey; by cusip1; run;
data dup2; set dup1; keep cusip1; run;
proc print data=merge_bycusip; where cusip1 in ('05946K','37045V','53071M','832914','G5480U'); run;
data merge_bycusip2; set merge_bycusip;
if cusip1='05946K' and linkenddt = .E then delete;*use tic to decide;
if cusip1='37045V' and linkdt ~=mdy(1,31,1962) then delete;*cik=40730 is the only one whose cik is not in link file;
if cusip1='53071M' and linkdt ~= mdy(5,10,2006) then delete;*use tic = QCVA;
if cusip1='832914' and linkenddt ~= mdy(9,29,2000) then delete;*use company name;
if cusip1='G5480U' and fiscalyear=2015 and linkdt ~= mdy(7,2,2015) then delete;*two firms use this cusip1, but the other has matched cik, so this belongs to tic=LILA, beginning from 2015;
run;

*3669 obs, i.e., 198 firms, still not matched;
data temp; set merge_bycusip2; where lpermno=.;run;
proc sort data=temp nodupkey;by cik;run;

data merge_bycusip3; set merge_bycusip2; drop mergebycikD;
mergeD=.;
if lpermno ~= . then mergeD=2;*D equals 2 if it's merged in secondary stage;
run;

* append primary and secondary results*;
data merge3; set merge2;drop mergebycikD;
mergeD = .;
if lpermno ~=. then mergeD = 1;*D equals 1 if it's merged in 1st stage;
if lpermno=. and cusip~='' then delete;
run;

proc append base=merge3 data=merge_bycusip3;run;

************ Tertiary merge using ticker ***************;
data temp; set merge3; where mergeD=.; run; *4018 obs not merged;

data merge_incomp; set merge3; 
where mergeD=. and ticker~=''; 
drop lpermno lpermco datadate gvkey linkdt linkenddt;
run;*3546 obs have ticker;

proc sql; 
create table merge_bytic as select a.*, b.lpermno, b.lpermco,b.datadate, b.gvkey, b.linkdt,b.linkenddt
from merge_incomp as a left join link as b
on a.ticker=b.tic and fyCompustat=fyear  
and (a.fiscalyearend >= b.linkdt or b.LINKDT = .B) and 
(b.linkenddt >= a.fiscalyearend or b.LINKENDDT = .E)
order by ticker, grantid, grantdate;
quit;

*no duplicates;
data temp; set merge_bytic;run;
proc sort data=temp nodupkey dupout=dup1;by grantid;run;

data temp; set merge_bytic; where lpermno=.;run;*2880 not merged;

* merge with primary and secondary results;
data merge_bytic2; set merge_bytic; 
if lpermno ~= . then mergeD=3;*D equals 3 if it's merged in 3rd stage;
run;

* append with primary and secondary results*;
data merge4; set merge3;
if lpermno=. and ticker~='' then delete;
run;

proc append base=merge4 data=merge_bytic2;run;

* 10157 merged by cik, 4612 by cusip, 666 by ticker, 3352 not merged;
proc freq data=merge4; table mergeD; run;

* save;
data inclab.merge_grantcompustat; set merge4; run;



************************* merge with price from CRSP *****************;
proc sql;
create table merge_price as select a.*, abs(prc) as prc, date as crspdate, intck('day',date,grantdate) as daydiff
from inclab.merge_grantcompustat as a left join crsp.dsf as b
on a.lpermno= b.permno 
where (0<=calculated daydiff <= 7 or calculated daydiff=.)
and date>='01Jul1997'd and date<='31dec2016'd
/* and prc is not missing */
order by cik, lpermno, grantid, daydiff; 
run;

data merge_price2(drop=crspdate); set merge_price;
by CIK lpermno grantid daydiff;
if first.grantid;
run;

* most merged on daydiff=0,1,2. no merge from daydiff=7 till 10;
proc freq data=merge_price2; table daydiff;run;

* find grantid and cik that are not merged;
data temp1; set merge_price2; run;
data temp2; set inclab.merge_grantcompustat;run; 
proc sort data=temp2;by cik lpermno grantid;run;
* 5658 unmatched;
data temp3; merge temp1(in=a) temp2(in=b);
by cik lpermno grantid;
if b and not a;
run;

* add permno not matched back to grant data;
data unmatchedpermno; set temp3(where=(lpermno=.));run;
proc append base=merge_price2 data=unmatchedpermno; run;

* 2306 not missing lpermno but unmatched;
data temp4; set temp3(where=(lpermno~=.));
proc sort data=temp4 nodupkey;by cik lpermno;run;

* deal with the 2306 obs with price unmatched but permno matched;
data unmatchedprice; set temp3(where=(lpermno~=.));
drop prc daydiff;
run;

proc sql;
create table unmatchedprice1 as select a.*, abs(prc) as prc, date as crspdate, intck('day',date,grantdate) as daydiff
from unmatchedprice as a left join crsp.dsf as b
on a.lpermno= b.permno 
where date>='01Jul1997'd and date<='31dec2016'd
order by cik, lpermno, grantid, daydiff; 
quit;

* find the closest crspdate to grantdate;
data unmatchedprice2; set unmatchedprice1;
absdaydiff = abs(daydiff);
run;

proc sort data=unmatchedprice2; by cik lpermno grantid absdaydiff;run;

data unmatchedprice3; set unmatchedprice2;
by CIK lpermno grantid absdaydiff;
if first.grantid;
run;

data temp; set unmatchedprice3; if daydiff>0;run;*decide the sign;

proc freq data=unmatchedprice3;
table absdaydiff;
run;

*only 2 grants' price dates are before grantdate;
proc sort data=unmatchedprice2; by cik lpermno grantid daydiff;run;

data temp1; set unmatchedprice2;
by CIK lpermno grantid daydiff;
if last.grantid;
run;

proc freq data=temp1; table daydiff;run;

*add 432 obs whose price available within 10 days of grantdate into the matched dataset;
data unmatchedprice4; set unmatchedprice3;
D_grantdatebeforepricedate = 0;
if absdaydiff > 10 then prc = .;
if absdaydiff <= 10 then D_grantdateafterpricedate = 1; 
drop absdaydiff crspdate;
run;

data merge_price2; set merge_price2; D_grantdatebeforepricedate=0;run;

proc append base=merge_price2 data=unmatchedprice4; run;


************************* merge with standard deviation *****************;
proc sql; 
create table merge_price_sd as select a.*, b.std_ret_ann
from merge_price2 as a left join inclab.monthly_std as b 
on a.lpermno=b.permno and year(grantdate)=yr and month(grantdate)=mt
order by cik, lpermno, grantid;
run;

************************* merge with yield *****************;
proc sql;
create table merge_price_sd_dy as select a.*, b.divy
from merge_price_sd as a left join inclab.div_yield as b
on a.lpermno=b.permno and year(grantdate)=b.year
order by cik, lpermno, grantid;
run;

************************* merge with treasury rate *****************;

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

proc print data=treasurycrsp2;where mdy(9,9,2001)<=caldt<mdy(9,22,2001);run;

/* create an uppper boundary for terms longer than max years to maturity */
*for terms longer than the available tdyearstm, use the max of tdytm and assume its tdyearstm is 1000;
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

* winsorize;
/*****************************************
Trim or winsorize macro
* byvar = none for no byvar;
* type  = delete/winsor (delete will trim, winsor will winsorize;
*dsetin = dataset to winsorize/trim;
*dsetout = dataset to output with winsorized/trimmed values;
*byvar = subsetting variables to winsorize/trim on;
****************************************/
  
%macro winsor(dsetin=, dsetout=, byvar=none, vars=, type=winsor, pctl=1 99);
  
%if &dsetout = %then %let dsetout = &dsetin;
     
%let varL=;
%let varH=;
%let xn=1;
  
%do %until ( %scan(&vars,&xn)= );
    %let token = %scan(&vars,&xn);
    %let varL = &varL &token.L;
    %let varH = &varH &token.H;
    %let xn=%EVAL(&xn + 1);
%end;
  
%let xn=%eval(&xn-1);
  
data xtemp;
    set &dsetin;
    run;
  
%if &byvar = none %then %do;
  
    data xtemp;
        set xtemp;
        xbyvar = 1;
        run;
  
    %let byvar = xbyvar;
  
%end;
  
proc sort data = xtemp;
    by &byvar;
    run;
  
proc univariate data = xtemp noprint;
    by &byvar;
    var &vars;
    output out = xtemp_pctl PCTLPTS = &pctl PCTLPRE = &vars PCTLNAME = L H;
    run;
  
data &dsetout;
    merge xtemp xtemp_pctl;
    by &byvar;
    array trimvars{&xn} &vars;
    array trimvarl{&xn} &varL;
    array trimvarh{&xn} &varH;
  
    do xi = 1 to dim(trimvars);
  
        %if &type = winsor %then %do;
            if not missing(trimvars{xi}) then do;
              if (trimvars{xi} < trimvarl{xi}) then trimvars{xi} = trimvarl{xi};
              if (trimvars{xi} > trimvarh{xi}) then trimvars{xi} = trimvarh{xi};
            end;
        %end;
  
        %else %do;
            if not missing(trimvars{xi}) then do;
              if (trimvars{xi} < trimvarl{xi}) then delete;
              if (trimvars{xi} > trimvarh{xi}) then delete;
            end;
        %end;
  
    end;
    drop &varL &varH xbyvar xi;

    run;
  
%mend winsor;

* check extreme values of K/S, volatility and dividend yield, and decide what to winsorize;
data option_merged; set option_merged;
KtoS = exerciseprice / prc;
run;

proc univariate data=option_merged;
var KtoS divy std_ret_ann optionterm intyield;
run;
 
%winsor(dsetin=option_merged, dsetout=option_merged_w1,vars=KtoS, byvar=fyCompustat,pctl=5 95);
%winsor(dsetin=option_merged_w1, dsetout=option_merged_w2,vars=divy, byvar=fyCompustat,pctl=1 99);
%winsor(dsetin=option_merged_w2, dsetout=option_merged_w3,vars=std_ret_ann, byvar=fyCompustat,pctl=0.5 99.5);

proc sql; 
create table option_merged2 as select a.*, b.KtoS as KtoS_w, b.divy as divy_w, b.std_ret_ann as std_w
from option_merged as a left join option_merged_w3 as b
on a.grantid=b.grantid;
quit;

data option_merged3; set option_merged2;
D_w = 0;
if KtoS ~= KtoS_w or divy ~= divy_w or std_ret_ann ~= std_w then D_w =1;
exerciseprice_w = KtoS_w * prc;
run;

data temp; set option_merged3; where D_w=1; run;*12889 winsorized;

data inclab.option_merged_all; set option_merged3; run;


/********************************* Pricing Options **************************************/
* 10961 missing, optionaward, exerciseprice and optionterm cause 7997 missing, price and volatility cause 3133;
data temp; set option_merged3;
if optionaward =. or exerciseprice<=0 or optionterm=. or prc=. or std_ret_ann=.;
run;

* 10934 missing thanks to winsorize exerciseprice equal to 0;
data temp; set option_merged3;
if optionaward =. or exerciseprice_w<=0 or optionterm=. or prc=. or std_ret_ann=.;
run;

* price option;
data optionfv; set inclab.option_merged_all;
FV = optionaward * blkshclprc(exerciseprice, optionterm, prc*exp((-divy)*optionterm), intyield, std_ret_ann);
FV_w = optionaward * blkshclprc(exerciseprice_w, optionterm, prc*exp((-divy_w)*optionterm), intyield, std_w);
run;

/* optionaward is only available for awardtype = 'option', 'phantomOption', or 'reloadOption', get stockaward/equitytarget to fill in other option types */
proc freq data=inclab.gpbagrant(where=(optionaward~=.));table awardtype; run;

/* get stockaward for pricing sarCash and sarEquity, 4478 grants; */
data sar; set optionfv; where awardtype in ('sarCash','sarEquity');run;*stockaward available only for sar among options;
data grant; set inclab.grant_GrantdateMissingCorrected;
if grantdatefv = -9999 then grantdatefv = . ;
run;

proc sql; 
create table sar2 as select a.*, b.stockaward
from sar as a left join grant as b
on a.grantid=b.grantid;
quit;

* 4075 filled in;
data sar2; set sar2; 
if stockaward=-9999 then stockaward=.;
FV = stockaward * blkshclprc(exerciseprice, optionterm, prc*exp((-divy)*optionterm), intyield, std_ret_ann);
FV_w = stockaward * blkshclprc(exerciseprice_w, optionterm, prc*exp((-divy_w)*optionterm), intyield, std_w);
run;

data option1; set optionfv; where awardtype not in ('sarCash','sarEquity'); run;

data optionfv; set option1 sar2(drop=stockaward);run;

/* get equitytarget for non-available optionaward, 6104 grants; */
data eq; set optionfv; where optionaward=.;run;

proc sql; 
create table eq2 as select a.*, b.equitytarget
from eq as a left join grant as b
on a.grantid=b.grantid;
run;

* 1162 filled in;
data eq2; set eq2; 
if equitytarget=-9999 then equitytarget=.;
FV = equitytarget * blkshclprc(exerciseprice, optionterm, prc*exp((-divy)*optionterm), intyield, std_ret_ann);
FV_w = equitytarget * blkshclprc(exerciseprice_w, optionterm, prc*exp((-divy_w)*optionterm), intyield, std_w);
run;

data option2; set optionfv; where optionaward ~= .; run;

data optionfv; set option2 eq2(drop=equitytarget);run;


data inclab.optionfv; set optionfv;run;

* compare with Mete's;
data metefv; set inclab.data_grant_value; where grantid ~=. ;run;* read 35823 obs;
/* proc sort data=metefv nodupkey dupout=dup; by grantid; run;*no duplicates;
data temp; set metefv;where value_grantdate=.;run;*1506 obs miss value_grantdate; */

proc sql;
create table optionfv_compare as select a.cik, a.grantid, a.grantdate, a.fiscalyearend, a.fv, a.fv_w, 
b.value_grantdate, c.grantdatefv
from optionfv as a left join metefv as b 
on a.grantid=b.grantid
left join inclab.gpbagrant as c on a.grantid = c.grantid;
quit;

data optionfv_compare; set optionfv_compare;
if grantdatefv = -9999 then grantdatefv = . ;
diff_original_j = grantdatefv - fv; 
diff_original_jw = grantdatefv - fv_w;
diff_original_mete = grantdatefv - value_grantdate;
pdiff_original_j = diff1/grantdatefv;
pdiff_original_jw = diff2/grantdatefv;
pdiff_original_mete = diff3/grantdatefv;
run;

proc means data=optionfv_compare N mean median std min max P1 P5 P10 P25 P75 P90 P95 P99;
var diff_original_j diff_original_jw diff_original_mete; output out=temp;
run;

data temp; set optionfv_compare; where value_grantdate ~= .; run;
proc means data=temp N mean median std min max P1 P5 P10 P25 P75 P90 P95 P99;
var diff_original_j diff_original_jw diff_original_mete; output out=temp;
run;

proc means data=optionfv_compare N mean median std min max P1 P5 P10 P25 P75 P90 P95 P99;
var pdiff_original_j pdiff_original_jw pdiff_original_mete; output out=temp;
run;

data temp; set optionfv_compare; where value_grantdate ~= .; run;
proc means data=temp N mean median std min max P1 P5 P10 P25 P75 P90 P95 P99;
var pdiff_original_j pdiff_original_jw pdiff_original_mete; output out=temp;
run;

data inclab.optionfv_compare; set optionfv_compare;run;

