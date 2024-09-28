/*************************************************************************
Title:   Compute Accurals Quality
Author:  Jinjing Liu
Date:    11/16/2022
Purpose: This file computes
1. freq, i.e., number of forecasts a company made for each fiscal year;
2. horizon, bias, accuracy, range for each prediction year;
Note that the year making announcement may have prediction for several years;
3. number of analysts for each calendar year;
4. restate to indicate if a frim in a fiscal year is restated or not 
5. Internal control weakness
6. Accruals quality from Dechow-Dichev (2002)
Variables computed from 1-3 are merged together since they are all from IBES.
*************************************************************************/;

libname my 'D:\World_bank_research\RPE_EM\data_code';
libname IBES 'F:\Data\IBES';
libname comp 'F:\Data\CompNA';
libname inclab 'D:\RPE\RPE_EM\IncLab_data';
libname shared 'D:\RPE\freq used vars';
libname audit 'F:\Data\AuditAnalytics';

libname celim '/home/uga/celim';
libname comp '/wrds/comp/sasdata/nam';

options nolabel; * show variable name instead of lable;

/* Check the guidance data */
data guidance; set ibes.ibesyear;
if  measure='EPS';
run;

proc sql;
create table temp as select *, count(*) as c
from guidance
group by ibes_tkr, prd_yr, prd_mon, announce_dt
order by c desc, ibes_tkr, prd_yr, prd_mon, announce_dt, mod_dt,activation_dt;

/** guidance is uniquely determined by ibes_tkr, prd_yr, prd_mon, announce_dt, mod_dt and activation_dt.
announce_dt is announced by company, mod_dt and activiation_dt are given by TR;
Most are uniquely determnied by ibes_tkr, prd_yr, prd_mon, announce_dt, except for 162 obs out of 75902. 
Given tkr, prd_yr, announce_dt, most estimates are the same, so we use the obs activated and modified the latest. **/

proc sort data=guidance; by ibes_tkr prd_yr prd_mon announce_dt mod_dt activation_dt; run;
data guidance2; set guidance; 
by ibes_tkr prd_yr prd_mon announce_dt mod_dt activation_dt;
if last.announce_dt;
announce_fyr = year(announce_date);
if eefymo <=5 then announce_fyr=announce_fyr-1;
run;

/* 1. compute freq, the number of forecasts in each fiscal year; */
proc sql;
create table freq as select unique ibes_tkr, announce_fyr, count(*) as freq from guidance2
group by ibes_tkr, announce_fyr
order by ibes_tkr, announce_fyr;
quit;

proc freq data=freq; table freq; run;


/* 2.1 compute horizon*/
data horizon; set guidance2; 
horizon = intnx('month',mdy(prd_mon,1,prd_yr), 0,'end')-announce_date;
run;

proc means data=horizon mean median min P5 P10 P25 P75 P90 P95 max ; var horizon; run;


/* 2.2-2.4 compute error from unadjusted actuals */
data actualu; set ibes.ibesactu_epsus;
if PDICITY='ANN' & measure='EPS';
run;

/* actualu is uniquely determined by ticker, pends, and currency;
proc sql;
create table temp as select *, count(*) as c
from actualu
group by ticker, PENDS, CURR_ACT
order by c desc, ticker, pends;
*/

* merge actual earnings with forecast;
proc sql;
create table he as select a.*, b.pends, b.ANNDATS as reportdate, b.VALUE
from horizon as a left join actualu as b
on a.ibes_tkr=b.TICKER and a.prd_yr=year(pends) and a.prd_mon = month(pends) and a.currency=b.curr_act
;

proc freq data=he; table range_desc; run;

data he2; set he; 
val_med = median(val_1,val_2); 
if range_desc=1 then bias = (value - val_med)/abs(value);*when range_desc=1, ibes provides two estimates and we use the median;
if range_desc=2 then bias = (value - val_1)/abs(value);*when range_desc=2, there is only 1 estimate;
error = abs(bias); 
if range_desc=1 then range = (val_2-val_1)/abs(val_med);*range is only meaningful when ibes provides a range of the estimate;
run;


/*merge with price; */
* get the file linking gvkey with ibtic;
data ibtic; set comp.security; 
keep gvkey ibtic dldtei; run;

proc sort data=ibtic nodupkey; by _all_; run;

data ibtic; set ibtic; if ibtic ~= ''; run;

* one gvkey may have multiple ibtic;
proc sql;create table temp as select *,count(*) as c from ibtic
group by gvkey
order by c desc, gvkey, ibtic, dldtei;

* prcc_f is unique for fyear, but not for cyear;
data prc; set comp.funda; 
if fyr>0 and at>0 and consol='C' and indfmt='INDL' and datafmt='STD' and popsrc='D'; 
keep gvkey cik fyear fyr PRCC_F;
run;

data he2; set he2; prd_fyr = prd_yr; if eefymo<6 then prd_fyr=prd_fyr-1;run;

* get price at the beginning of forecasting period;
proc sql;
create table he3 as select a.*, b.gvkey, b.dldtei, c.cik, c.prcc_f
from he2 as a left join ibtic as b
on a.ibes_tkr = b.ibtic 
left join prc as c
on b.gvkey = c.gvkey and a.prd_fyr = c.fyear+1
order by gvkey, ibes_tkr, prd_yr, prd_mon;
quit;

data he3; set he3; 
if range_desc=1 then bias_prc = (value - val_med)/abs(prcc_f);
if range_desc=2 then bias_prc = (value - val_1)/abs(prcc_f);
error_prc = abs(bias_prc); 
run;

* merge freq with horizon;
proc sql;
create table aq as select a.ibes_tkr, gvkey, prd_yr, prd_fyr, prd_mon, eefymo, announce_dt, announce_date, a.announce_fyr, currency, diff_code, mean_at_date, status_flag, guidance_code, 
val_1, val_2, val_med, range_desc, pends, reportdate, value as val_actual, prcc_f, dldtei, 
a.freq, horizon,range, bias,error, bias_prc, error_prc
from freq as a full join he3 as b
on a.ibes_tkr=b.ibes_tkr and a.announce_fyr=b.announce_fyr;
quit;

proc means data=aq n mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max; 
var freq horizon bias accuracy range bias_prc accuracy_prc; 
run;


/** 3 compute number of analysts; **/
data numest; set ibes.ibesstatsum_epsus; 
keep ticker STATPERS FPEDATS numest;
if measure='EPS' and FPI=1;
run;

proc sort data=numest nodupkey; by _all_; run;*there are duplicates due to multiple currency;

* numest is defined as the nb of analysts forecasting the current fiscal year in the month cloest to but preceding the annual earnings announcement;
proc sql;create table temp as select a.*,b.STATPERS,b.numest 
from aq as a left join numest as b 
on a.ibes_tkr=b.ticker and a.prd_yr = year(b.fpedats) and statpers <= reportdate
order by ibes_tkr, announce_dt, prd_yr, prd_mon, reportdate, statpers;

data aq2; set temp; 
by ibes_tkr announce_dt prd_yr prd_mon reportdate statpers;
if last.reportdate; 
run;

proc means data=aq2 n mean median std MIN P5 P10 P25 P75 P90 P95 MAX; var numest;run;

data my.he_org; set aq2; run;

/* compute avg number of analysts for each calendar year;
proc sql;
create table numest2 as select unique ticker, year(statpers) as announce_cyr, mean(numest) as n_analysts
from numest 
group by year(statpers);

proc means data=numest2(where=(1988<=announce_cyr<=2002)) n mean median std MIN P5 P10 P25 P75 P90 P95 MAX; var n_analysts;run;

* create announce calendar year for merging;
data aq2; set aq; 
announce_cyr=announce_fyr;
if eefymo <=5 then announce_cyr=announce_cyr+1;
run;

* merge nb of analysts with other accrual quality variables. Left join since there are much more obs for n_analysts;
proc sql;
create table aq3 as select a.*, b.n_analysts 
from aq2 as a left join numest2 as b
on a.ibes_tkr=b.ticker and a.announce_cyr=b.announce_cyr;

data my.horizon; set aq3; run;

*/


/** collapse to firm announce_fyr level; **/
* drop unreasonable horizons;
data aq2; set my.he_org; if horizon >= 0 & horizon <366; run;*change obs nb from 73423 to 66721;

proc sort data=aq2; by ibes_tkr announce_fyr horizon; run;

data aq3; set aq2; 
by ibes_tkr announce_fyr horizon; 
if first.announce_fyr;
run;*leaving only 20658 obs;

data my.he; set aq3; run;

%winsor(dsetin=aq3, dsetout=he_w, byvar=none, vars=freq range bias error bias_prc error_prc numest, type=winsor, pctl=1 99);

proc means data=he_w n mean median std MIN P1 P5 P10 P25 P75 P90 P95 P99 MAX; 
var freq horizon range bias error bias_prc error_prc numest;
run;


/*** 4. compute restate; ****/
data restate; set audit.AAauditnonreli; run;

proc sql;create table restate2 as select unique company_fkey as cik, best_edgar_ticker as AA_ticker,RES_BEGIN_DATE, RES_end_DATE,RES_CLER_ERR
from restate;

data restate2; set restate2; mm=intck('month',RES_BEGIN_DATE,RES_end_DATE)+1; run;

proc means data=restate2 mean median std MIN P5 P10 P25 P75 P90 P95 MAX; var mm;run;

*drop if restatemnts arise from clerical errors;
data restate3; set restate2; if RES_CLER_ERR=0; drop RES_CLER_ERR; run;

data my.restate; set restate3; run;

/**** 5. Internal control weakness ****/
data icw; set audit.AAauditsox404; 
keep COMPANY_FKEY FY_IC_OP IC_IS_EFFECTIVE AUDITOR_FKEY IC_OP_TYPE IS_NTH_RESTATE; 
run;

proc sql;
create table t as select *, count(unique IC_IS_EFFECTIVE)
from icw
group by COMPANY_FKEY, FY_IC_OP;

* limit to management report;
data icw2; set icw; if IC_OP_TYPE='m'; run;

* IC_IS_EFFECTIVE is not unique on firm-year level. choose N once it appears;
proc sort data=icw2; by company_fkey fy_ic_op descending ic_is_effective; run;
data icw3; set icw2; 
by company_fkey fy_ic_op descending ic_is_effective; 
if first.fy_ic_op;
run;

data icw3; set icw3; 
rename company_fkey = cik
       fy_ic_op = fyear
       ic_is_effective = icw;
keep company_fkey fy_ic_op ic_is_effective;
run;

proc freq data=icw3(where=(fyear>2004)); 
table icw;
run;

data my.icw; set icw3; run;


/******* 6. compute AQ following Dechow-Dichev (2002); ****/
data accrual; set comp.funda;
where INDFMT = 'INDL' AND DATAFMT = 'STD' AND POPSRC = 'D' AND CONSOL = 'C';
CYEAR = YEAR(DATADATE);
KEEP GVKEY FYEAR SICH AT RECCH /*account receivables*/ INVCH /*inventory*/ APALCH/*Accounts Payable*/  TXACH/*taxes payable*/ AOLOCH/*other assets*/ SALE PPENT OANCF;
if AT ~=.; 
run;

proc sort data = accrual nodupkey;
by GVKEY FYEAR;
run;

* compute diff in working capital and sales, PPE, following Demerjian et al. 'Managerial ability and earings quality', 2013 ;
data accrual; set accrual;
WC = -(RECCH + INVCH + APALCH + TXACH + AOLOCH); /*wrong here: the components are changes already */
if gvkey = lag(gvkey) & fyear = lag(fyear)+1 then do;
    avgAT = (AT+lag(AT))/2;
    diffWC = ( WC - lag(WC) )/avgAT;
    diffSale = (Sale - lag(Sale) )/avgAT;
end;
PPE = PPENT / avgAT;
CFO = OANCF / avgAT;
run;

* create Cash Flow in the past and future;
data accrual; set accrual;
if gvkey = lag(gvkey) & fyear = lag(fyear)+1 then CFO_lag = lag(CFO);
run;

proc sort data = accrual nodupkey;
by GVKEY descending FYEAR;
run;

data accrual; set accrual;
if gvkey = lag(gvkey) & fyear = lag(fyear)-1 then CFO_fut = lag(CFO);
run;

* Create FF48. use sic when sich is missing;
proc sql;
create table accrual2 as select a.*, b.sic
from accrual as a left join comp.names as b
on a.gvkey=b.gvkey and year1 < fyear < year2;
run;

data accrual2; set accrual2;
if missing(SICH) then SICH=SIC;
run;

proc means data=accrual2 n mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max; 
var diffWC CFO_lag CFO CFO_fut diffSale PPE;
run;


* generate FF48 using the ff48 macro under CEO_worker_pay; 
%ff48(dsin=accrual2, dsout=accrual3, sicvar=sich, varname=ff48);

proc freq data=accrual3; table ff48;run;

data my.aq_data; set accrual3; run;

* winsorize;
%winsor(dsetin=accrual3, dsetout=aq_data_w, byvar=none, vars=diffWC CFO_lag CFO CFO_fut diffSale PPE, type=winsor, pctl=1 99);


* Compute the loadings for each FF48 and YEAR;
proc sort data=aq_data_w; by fyear ff48;run;

proc reg data = aq_data_w 
noprint tableout edf outest = aq_reg;
by fyear ff48;
model diffWC = CFO_lag CFO CFO_fut diffSale PPE;
quit;

data aq_reg; set aq_reg;
where _TYPE_ = 'PARMS';
NumFirms = _EDF_ + _P_;
run;

* If one of the regressand is missing for all firms in an industry, then delete;
* If number of firms in an industry is less than 20, also delete;
data aq_reg; set aq_reg;
if _P_ < 5 then delete;
if NumFirms < 20 then delete;
run;


data aq_reg; set aq_reg;
rename CFO_lag = coef_CFO_lag
       CFO = coef_CFO
       CFO_fut = coef_CFO_fut
       diffSale = coef_diffSale
       PPE = coef_PPE;
run;

data aq_reg; set aq_reg;
keep fyear ff48 intercept coef_CFO_lag coef_CFO coef_CFO_fut coef_diffSale coef_PPE NumFirms;
run;

proc means data=aq_reg n mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max; 
var intercept coef_CFO_lag coef_CFO coef_CFO_fut coef_diffSale coef_PPE NumFirms; run;

* Join the estimates with firm-level vars;
proc sql;
create table aq as select a.*, 
b.intercept, coef_CFO_lag, coef_CFO, coef_CFO_fut, coef_diffSale, coef_PPE, NumFirms
from aq_data_w as a left join aq_reg as b 
on a.fyear=b.fyear and a.ff48=b.ff48;
quit;

data aq; set aq;
if res ~=. then d = 1 ;
res = diffWC - intercept - CFO_lag*coef_CFO_lag - CFO*coef_CFO - CFO_fut*coef_CFO_fut - diffSale*coef_diffSale - PPE*coef_PPE;
run;

* compute aq as std of residuals in the past 4 years;
proc sort data = aq; by gvkey fyear; run;
proc expand data = aq OUT = aq2; 
	by gvkey;
	id fyear;
 	convert res = aq / TRANSFORMOUT=(movstd 4 TRIMLEFT 2);
 	convert d = n_res / TRANSFORMOUT=(movsum 4 TRIMLEFT 2);
run;

data aq3; set aq2; 
fyear = fyear + 1; 
keep gvkey fyear aq n_res;
if n_res > 1; 
run;

data my.aq; set aq3; run;

proc means data=aq3 n mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max; 
var aq; run;


/***** Merge all datasets ****/
* merge RPE firms with horizon et al;
proc sql;
create table aq_main as select *
from comp.funda_computed as a left join he_w(where=(gvkey~='')) as b
on a.gvkey=b.gvkey and a.fyear=b.announce_fyr
order by gvkey, fyear;

/* merge with restate */
*drop obs without cik;
data aq_main; set aq_main; if cik ~= '';run;

proc sql;
create table aq_main2 as select a.*, (a.cik=b.cik) as D_restate
from aq_main as a left join my.restate as b
on a.cik=b.cik and year(RES_BEGIN_DATE) <= a.fyear <= year(RES_end_DATE)
order by cik, fyear;

*one fiscal year could fall in several restate periods. Keep as long as it equals 1;
proc sort data=aq_main2; by gvkey fyear D_restate; run;
data aq_main2; set aq_main2; by gvkey fyear D_restate; if last.fyear; run;

/* merge with ICW */
proc sql;
create table aq_main as select a.*, b.icw
from my.aq_main as a left join my.icw as b
on a.cik = b.cik and a.fycompustat = b.fyear;

proc freq data=aq_main(where=(fycompustat>2005));
table icw;
run;

data my.aq_main; set aq_main; run;


/* merge with accruals quality */
*winsorize aq;
%winsor(dsetin=my.aq, dsetout=aq_w, byvar=none, vars=aq, type=winsor, pctl=1 99);

proc sql; *367862;
create table aq_main3 as select a.*, aq
from aq_main2 as a left join aq_w as b
on a.gvkey=b.gvkey and a.fyear=b.fyear
order by gvkey, fyear;

/* identify RPE firms; */
proc sql;
create table aq_main4 as select a.*, (case when a.cik=b.cik then 1 else 0 end) as D_rpe
from aq_main3 as a left join my.rpe as b
on a.cik = b.cik and a.fyear=b.fycompustat
order by d_rpe, gvkey, fyear;

* add debt lvg and earnings vol;
proc sql;
create table aq_main5 as select a.*,b.dlvg, b.evol
from aq_main4 as a left join comp.funda_computed as b
on a.gvkey = b.gvkey and a.fyear=b.fyear;

* add ret and vol;
proc sql;
create table aq_main6 as select a.*,b.rety, b.std_ret_ann
from aq_main5 as a left join shared.crsp_computed as b
on a.permno = b.permno and a.cyear = b.cyear;

* add company age;
proc sql; 
create table aq_main7 as select a.*, fyear-year(b.namedt) as age_co
from aq_main6 as a left join paygap.age_co as b
on a.permno=b.permno
order by gvkey, fyear;
quit;

proc means data=aq_main7 n mean median std min P1 P5 P10 P90 P95 P99 max; 
var size bm roa age_co evol lvg dlvg rety std_ret_ann;
run;

*winsorize controls;
%winsor(dsetin=aq_main7, dsetout=aq_main8, byvar=none, vars=size bm roa age_co evol lvg dlvg rety std_ret_ann, type=winsor, pctl=1 99);

* add FF12 & FF48 classifications;
proc sql;
create table aq_main9 as select a.*, b.sich, b.d_sichmissinghsiccdnot, b.ff12,b.ff48
from aq_main8 as a left join comp.funda_computed as b
on a.gvkey = b.gvkey and a.fyear=b.fyear;

* add lagged var;
*lagged fundamentals;
proc sql;
create table aq_main10 as select a.*, b.at as at_lag, b.roa as roa_lag, b.size as size_lag,
b.capxAT as capxat_lag, b.rd as rd_lag, b.be as be_lag, b.mc as mc_lag, b.bm as bm_lag, b.q as q_lag,
b.lvg as lvg_lag, b.dlvg as dlvg_lag, b.evol as evol_lag
from aq_main9 as a left join comp.funda_computed as b
on a.gvkey = b.gvkey and a.fyear=b.fyear+1
order by d_rpe;

* lagged company age;
data aq_main10; set aq_main10; age_co_lag = age_co-1;run;

* lagged numest;
proc sql;
create table aq_main11 as select a.*,b.numest as numest_lag
from aq_main10 as a left join my.he as b
on a.ibes_tkr=b.ibes_tkr and a.fyear=b.announce_fyr+1
order by d_rpe;

* lagged ret and vol;
proc sql;
create table aq_main12 as select a.*,b.rety as rety_lag, b.std_ret_ann as std_ret_ann_lag
from aq_main11 as a left join shared.crsp_computed as b
on a.permno = b.permno and a.cyear = b.cyear+1;

*lagged rpe dummy;
proc sql;
create table aq_main13 as select a.*, (case when a.cik=b.cik then 1 else 0 end) as D_rpe_lag
from aq_main12 as a left join my.rpe as b
on a.cik = b.cik and a.fyear=b.fycompustat+1;


proc means data=aq_main13 n mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max; 
var size_lag bm_lag roa_lag age_co_lag evol_lag lvg_lag dlvg_lag rety_lag std_ret_ann_lag;
run;

*winsorize lagged var;
%winsor(dsetin=aq_main13, dsetout=aq_main14, byvar=none, vars=size_lag bm_lag roa_lag age_co_lag evol_lag lvg_lag dlvg_lag rety_lag std_ret_ann_lag, type=winsor, pctl=1 99);

/** Identify S&P 1500 firms **/
* a firm is considered as a member of SP1500 if its fiscalyear end is within the range in SP1500 list;
proc sql;
    create table aq_main as select a.*, c.conm as sp1500
	from aq_main13 as a 
	left join 'F:\Data\CompNA\Index_constituents\SP1500_constituents' as c
	on a.gvkey = c.gvkey and mdy(fyr,1,cyear) > c.from and ( mdy(fyr,1,cyear) <= c.thru | c.thru =.)
	order by gvkey, fyear, fyr, sp1500;
quit;

* the from-thru period in sp1500 is not exlusive. we assume the firm is in sp1500 as long as it falls in any period;
data aq_main2; set aq_main; by gvkey fyear fyr sp1500; if last.fyr; run;


data my.aq_main; set aq_main2; rename fyear = fycompustat; run;

proc export data=my.aq_main outfile='D:\RPE\RPE_EM\data_code\aq_main.dta' replace;run;


proc sort data=my.aq_main; by d_rpe; run;
proc means data=my.aq_main(where=(ibes_tkr~='')) n mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max; 
by d_rpe; 
var freq horizon range bias error bias_prc error_prc numest d_restate aq
size bm roa age_co evol lvg dlvg rety std_ret_ann;
run;

proc means data=my.aq_main n mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max; 
by d_rpe; 
var aq;
run;






