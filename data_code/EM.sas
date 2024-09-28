/*************************************************************************
Title:   Compute other controlling variables and combine with accruals
Author:  Jinjing Liu
Date:    1/17/2018
Purpose: This file combines all variables and sorts firms into 5 portfilios based on dependent variables.
*************************************************************************/;

libname celim '/home/uga/celim';
libname compNA '/wrds/comp/sasdata/nam';

libname pension 'F:\Data\CompNA\pension';
libname link 'F:\Data\SAS linking data';
libname crsp 'F:\Data\CRSP';
libname comp 'E:\Data\CompNA';
libname sr 'F:\Research\WB\Systemic_Risk\Code and Data';

libname inclab 'E:\Data\Incentivelab\Original_Data';
libname my 'E:\Research\WB\RPE_EM\data_code';

/* create book equity */
data funda; set comp.funda; 
   where fyr>0 and at>0 and consol='C' and indfmt='INDL' and datafmt='STD' and popsrc='D'; 
   cyear=year(datadate); 
   /*to obtain shareholders equity, use stockholders equity, if not missing  */
   if not missing(SEQ) then SHE=SEQ;else
   /*if SEQ missing, use Total Common Equity plus Preferred Stock Par Value  */
   if nmiss(CEQ,PSTK)=0 then SHE=CEQ+PSTK;else
   /*if CEQ or PSTK is missing, use Total Assets-(Total Liabilities+Minority Interest), if all exist        */
   if nmiss(AT,LT)=0 then SHE=AT-sum(LT,MIB); 
   else SHE=.; 
  /*to obtain book equity,subtract from the shareholders' equity the preferred*/ 
  /*stock value,using redemption,liquididating or carrying value in that order*/
   /*if available*/ 
   PS = coalesce(PSTKRV,PSTKL,PSTK); *coalesce returns the first non-null or nonmissing value from a list of numeric arguments;
   BE0 = SHE-PS; 

   /* Other controlling variables */
   l_AT=lag(AT);
   if gvkey~=lag(gvkey) or year(datadate)> year(lag(datadate))+2 then l_AT = .;
   roa = ib / l_at;
   size = log(AT+1);
   /* Accounting data since calendar year 't-1'*/
   * if 1998 - 1<=cyear<= 2016;
   keep gvkey cyear fyear fyr cik BE0 at roa size indfmt consol datafmt popsrc datadate TXDITC; 
run; 


data eps; set comp.funda; 
   where fyr>0 and at>0 and consol='C' and indfmt='INDL' and datafmt='STD' and popsrc='D'; 
   cyear=year(datadate); 
   /*to obtain shareholders equity, use stockholders equity, if not missing  */
   if not missing(SEQ) then SHE=SEQ;else
   /*if SEQ missing, use Total Common Equity plus Preferred Stock Par Value  */
   if nmiss(CEQ,PSTK)=0 then SHE=CEQ+PSTK;else
   /*if CEQ or PSTK is missing, use Total Assets-(Total Liabilities+Minority Interest), if all exist        */
   if nmiss(AT,LT)=0 then SHE=AT-sum(LT,MIB); 
   else SHE=.; 

   eps = ni/csho;
   keep gvkey cyear fyear fyr cik EPSFI EPSFX EPSpi EPSPX eps ni CSHO;
   if fyear > 2004;
run;

proc export data=eps outfile='E:\Research\WB\RPE_EM\data_code\eps.dta' replace;run;


proc sql; 
    create table funda
    as select a.gvkey, a.cyear, a.fyear, a.fyr, a.cik, at, roa, size, 
		  case when missing(TXDITC)=0 and missing(PRBA)=0 then BE0+TXDITC-PRBA else BE0
		  end as BE
    from funda as a 
    left join pension.aco_pnfnda (keep=gvkey indfmt consol datafmt popsrc datadate prba) as b
    on a.gvkey=b.gvkey and a.indfmt=b.indfmt and a.consol=b.consol and a.datafmt=b.datafmt 
   and a.popsrc=b.popsrc and a.datadate=b.datadate;
quit;


/* Create Book to Market (BM) ratios in December using price from CRSP */
proc sql;
   create table comp_crsp	
   as select a.*, c.permno, b.lpermno, c.date, abs(prc*shrout) as MC, a.be/(calculated MC/1000) as BM, c.hsiccd
   from funda as a,
		link.CCMXPF_LNKHIST as b,		
		crsp.msf (where=( month(date)=12)) as c
	where a.gvkey=b.gvkey and linkprim in ('P','C') and LINKTYPE in ("LU", "LC", "LN", "LS") and
	(c.date >= b.linkdt or b.LINKDT = .B) and (c.date <= b.linkenddt or b.LINKENDDT = .E)
   and b.lpermno=c.permno and a.cyear = year(c.date) ;
quit;

data comp_crsp; set comp_crsp; if bm<0 then bm=.; if be<0 then be=.; run;

proc sort data=comp_crsp nodupkey; by _all_; run;

* the fundamental file is unique on gvkey-fyear level,
but has 3 duplicates on permno-fyear level caused by cyear or fyr, and all duplicates miss cik, so we delete the ones which do not have cik;
proc sort data=comp_crsp; by permno fyear cik; run;
data comp_crsp; set comp_crsp; by permno fyear cik; if last.fyear; run;

proc sort data=comp_crsp nodupkey; by gvkey fyear ; run; * no duplicates;

/* create FF12 industry */
data comp_crsp; set comp_crsp;
*1 NoDur  Consumer NonDurables -- Food, Tobacco, Textiles, Apparel, Leather, Toys;
         if hsiccd ge   0100 and hsiccd le  0999 	then FF12=1;
         if hsiccd ge   2000 and hsiccd le 	2399 	then FF12=1;
         if hsiccd ge   2700 and hsiccd le 	2749 	then FF12=1;
         if hsiccd ge   2770 and hsiccd le 	2799 	then FF12=1;
         if hsiccd ge   3100 and hsiccd le 	3199 	then FF12=1;
         if hsiccd ge   3940 and hsiccd le 	3989 	then FF12=1;
 *2 Durbl  Consumer Durables -- Cars, TVs, Furniture, Household Appliances;
        if hsiccd ge   2500 and hsiccd le   2519 	then FF12=2;
        if hsiccd ge   2590 and hsiccd le 	2599 	then FF12=2;
        if hsiccd ge   3630 and hsiccd le 	3659 	then FF12=2;
        if hsiccd ge   3710 and hsiccd le 	3711 	then FF12=2;
        if hsiccd ge   3714 and hsiccd le 	3714 	then FF12=2;
        if hsiccd ge   3716 and hsiccd le 	3716 	then FF12=2;
        if hsiccd ge   3750 and hsiccd le 	3751 	then FF12=2;
        if hsiccd ge   3792 and hsiccd le 	3792 	then FF12=2;
        if hsiccd ge   3900 and hsiccd le 	3939 	then FF12=2;
        if hsiccd ge   3990 and hsiccd le 	3999 	then FF12=2;
* 3 Manuf  Manufacturing -- Machinery, Trucks, Planes, Off Furn, Paper, Com Printing;
        if hsiccd ge    2520 and hsiccd le  2589    then FF12=3;
        if hsiccd ge    2600 and hsiccd le 	2699 	then FF12=3;
        if hsiccd ge    2750 and hsiccd le 	2769 	then FF12=3;
        if hsiccd ge    3000 and hsiccd le 	3099 	then FF12=3;
        if hsiccd ge    3200 and hsiccd le 	3569 	then FF12=3;
        if hsiccd ge    3580 and hsiccd le 	3629 	then FF12=3;
        if hsiccd ge    3700 and hsiccd le 	3709 	then FF12=3;
        if hsiccd ge    3712 and hsiccd le 	3713 	then FF12=3;
        if hsiccd ge    3715 and hsiccd le 	3715 	then FF12=3;
        if hsiccd ge    3717 and hsiccd le 	3749 	then FF12=3;
        if hsiccd ge    3752 and hsiccd le 	3791 	then FF12=3;
        if hsiccd ge    3793 and hsiccd le 	3799 	then FF12=3;
        if hsiccd ge    3830 and hsiccd le 	3839 	then FF12=3;
        if hsiccd ge    3860 and hsiccd le 	3899 	then FF12=3;
* 4 Enrgy  Oil, Gas, and Coal Extraction and Products;
        if hsiccd ge     1200 and hsiccd le 	1399 	then FF12=4;
        if hsiccd ge     2900 and hsiccd le 	2999 	then FF12=4;
* 5 Chems  Chemicals and Allied Products;
        if hsiccd ge     2800 and hsiccd le 	2829 	then FF12=5;
        if hsiccd ge     2840 and hsiccd le 	2899 	then FF12=5;
* 6 BusEq  Business Equipment -- Computers, Software, and Electronic Equipment;
        if hsiccd ge    3570 and hsiccd le 	3579 	then FF12=6;
        if hsiccd ge    3660 and hsiccd le 	3692 	then FF12=6;
        if hsiccd ge    3694 and hsiccd le 	3699 	then FF12=6;
        if hsiccd ge    3810 and hsiccd le 	3829 	then FF12=6;
        if hsiccd ge    7370 and hsiccd le 	7379 	then FF12=6;
* 7 Telcm  Telephone and Television Transmission;
         if hsiccd ge    4800 and hsiccd le 	4899 	then FF12=7;
* 8 Utils  Utilities;
         if hsiccd ge    4900 and hsiccd le 	4949 	then FF12=8;
* 9 Shops  Wholesale, Retail, and Some Services (Laundries, Repair Shops);
        if hsiccd ge    5000 and hsiccd le 	5999 	then FF12=9;
        if hsiccd ge    7200 and hsiccd le 	7299 	then FF12=9;
        if hsiccd ge    7600 and hsiccd le 	7699 	then FF12=9;
*10 Hlth   Healthcare, Medical Equipment, and Drugs;
         if hsiccd ge   2830 and hsiccd le 	2839 	then FF12=10;
         if hsiccd ge   3693 and hsiccd le 	3693 	then FF12=10;
         if hsiccd ge   3840 and hsiccd le 	3859 	then FF12=10;
         if hsiccd ge   8000 and hsiccd le 	8099 	then FF12=10;
*11 Money  Finance;
         if hsiccd ge   6000 and hsiccd le 	6999 	then FF12=11;
*12 Other  Other -- Mines, Constr, BldMt, Trans, Hotels, Bus Serv, Entertainment;
		 if hsiccd > .		and FF12 = .	then FF12=12;
drop hsiccd;
run;

/* Compute Annual Ret */
proc sql;
    create table prc as select permno, year(date) as cyear, exp(sum(log(1+ret)))-1 as rety
    from crsp.msf
    group by permno, cyear;
quit;

/* Compute Earnings Volatility from quartly earnings in the past 3 years*/
proc sql;
    create table ib as select gvkey, datadate, fyearq, fqtr, fyr, ibq/atq as ibq
	from compNA.fundq
	where fyearq >= 1998 - 1 and ibq ~= . and atq ~=. /*reduce duplicated controlling for non-missing ib*/
	order by gvkey, fyearq, fqtr;
quit;

data ib; set ib;
    dateq = yyq( fyearq, fqtr );
    format dateq yyqc.;
/*
    l_ibq= lag(ibq);
    if gvkey~=lag(gvkey) or fyearq > lag(fyearq)+2 then l_ibq = .;
    ib_growth= ibq/l_ibq - 1;
*/
run;

proc sort data=ib dupout=a nodupkey; by gvkey dateq; run;*815 dup out of 751647;

proc expand data = ib OUT = evol; 
	by gvkey;
	id dateq;
    convert ibq=evol / TRANSFORMOUT=(movstd 12 TRIMLEFT 8);
run;

/* keep only the lastest calendar year obs */
proc sort data=evol;
    by gvkey fyearq fyr;
run;

data evol; set evol;
    by gvkey fyearq fyr;
    if last.fyearq;
run;

/* merge BM, annual ret, and earnings volatility */
data funda; set sr.funda_part; run;
proc sort data=funda nodupkey; by gvkey fyear; run;

proc sql;
    create table indep as select a.*, b.rety, c.evol
	from funda as a left join prc as b 
	on a.permno = b.permno and a.cyear=b.cyear
	left join evol as c 
	on a.gvkey=c.gvkey and a.fyear=c.fyearq;
quit;

proc sql;
    create table indep2 as select a.*, b.lvg
	from indep as a left join sr.srisk_new as b
    on a.permno = b.permno and a.fyear = b.fyear 
	order by gvkey, fyear;
quit;

data my.indep; set indep2; run;
proc export data=my.indep outfile='indep.dta' replace;run;


proc sql;
    create table indep2 as select a.*, DCAJones1991_w,DCAJones1991int_w, DCAModJones1991_w, DCAModJones1991int_w
	from my.indep as a left join my.accruals as b
    on a.gvkey = b.gvkey and a.fyear = b.fyear 
	order by gvkey, fyear;
quit;

%winsor(dsetin=indep2, dsetout=indep_w, byvar=fyear,vars=bm roa evol rety, type=winsor, pctl=1 99);

data temp; set indep_w; if fyear > 2005; 
if sum(bm=., size=., roa=., evol=., rety=., lvg=., DCAJones1991_w=., DCAJones1991int_w=., DCAModJones1991_w=., DCAModJones1991int_w=.)=0;
run;

proc means data=temp n mean std P25 median P75;
    vars bm size roa evol rety lvg DCAJones1991_w DCAJones1991int_w DCAModJones1991_w DCAModJones1991int_w;
run;

* combine with executive comp;
data excomp; set "E:\Data\ExecuComp\AnnualCompensation";
keep gvkey  year;
if year > 2005;
run;
proc sort data=excomp nodupkey; by _all_; run;

proc sql;
create table temp1 as select a.* 
from temp as a join excomp as b
on a.gvkey = b.gvkey and a.fyear = b.year;
quit;

proc means data=temp1 n mean std P25 median P75;
    vars bm size roa evol rety lvg DCAJones1991_w DCAJones1991int_w DCAModJones1991_w DCAModJones1991int_w;
run;




/**************** Create peer earnings management ***************/
/**************
Compute the average or median of peer accruals for each firm 
****************/
proc sql;
    create table relpeer as select a.*, b.fycompustat, b.fv_w
	from inclab.gpbarelpeer as a left join my.grant_fvj as b
	on a.grantid = b.grantid
    order by cik, fycompustat;
quit;

data a; set relpeer; run;
proc sort data=a nodupkey; by cik fycompustat; run; * 2514 unique firm-fyear;

data relpeer; set relpeer; if not missing(peercik); run; * 2476 unique firm-fyear left;

proc sql; create table temp as select unique cik, fiscalYear from inclab.Comppeer; quit; /*11,038 unique firm-fyear*/

* obtain gvkey from funda;
* change cik in funda from numeric to character, the same type as peercik in relpeer;
data funda; set comp.funda; 
    cik2= input(cik, Best.);
	keep fyear gvkey cik cik2 tic conm; 
run;

proc sql; 
    create table relpeer2 as select a.*, b.gvkey as gvkeypeer, b.tic as ticpeer, b.conm as conmpeer
	from relpeer as a left join funda as b
	on a.peercik=b.cik2 and a.fycompustat=b.fyear
    order by fycompustat, cik, grantid;
quit;

proc sort data=relpeer2 nodupkey; by fycompustat cik grantid peercik;run;

data my.peerlist; set relpeer2; run;
proc export data=my.peerlist outfile='D:\RPE\RPE_EM\data_code\peerlist.dta' replace;run;


/* compute contemparenous peer accruals */
proc sql;
    create table relpeerem as select a.*, CAdTAtm1DechowEtAl_w, DCAJones1991_w,DCAJones1991int_w, DCAModJones1991_w, DCAModJones1991int_w
	from my.peerlist as a left join my.Accruals as b
	on a.gvkeypeer = b.gvkey and a.fycompustat = b.fyear
	order by cik, fycompustat, grantid, peercik;
quit;

* For computing equally weighted accruals, drop repeated peers since diff grants share many peers;
data relpeerem2; set relpeerem; drop grantid ticpeer conmpeer ;run;
proc sort data=relpeerem2 nodupkey; by cik fycompustat peercik;run;

proc means data = relpeerem2 noprint; 
    Vars CAdTAtm1DechowEtAl_w DCAJones1991_w DCAJones1991int_w DCAModJones1991_w DCAModJones1991int_w;
    by cik fycompustat ;
	output out=relpeerem3(drop=_type_ rename=(_freq_=N_peers)) mean(CAdTAtm1DechowEtAl_w)=avg_CAdTA mean(DCAJones1991_w)=avg_dcaj mean(DCAJones1991int_w) = avg_dcajint mean(dcamodjones1991_w)=avg_dcamj mean(dcamodjones1991int_w)=avg_dcamjint
    median(CAdTAtm1DechowEtAl_w)=med_CAdTA median(DCAJones1991_w)=med_dcaj median(DCAJones1991int_w) = med_dcajint median(dcamodjones1991_w)=med_dcamj median(dcamodjones1991int_w)=med_dcamjint;
run;*2055 non-missing cik-year-peercik;

proc means data = relpeerem2 noprint; 
    Vars CAdTAtm1DechowEtAl_w DCAJones1991_w DCAJones1991int_w DCAModJones1991_w DCAModJones1991int_w;
    by cik fycompustat ;
	output out=relpeeremP75(drop=_type_ rename=(_freq_=N_peers))  P75=  / autoname;
run;

proc export data=relpeeremP75 outfile='F:\Research\WB\RPE_EM\data_code\relpeeremP75.dta' replace;run;


/* compute lagged peer accruals */
proc sql;
    create table relpeerem_l as select a.*, CAdTAtm1DechowEtAl_w, DCAJones1991_w, DCAJones1991int_w, DCAModJones1991_w, DCAModJones1991int_w
	from relpeer2 as a left join my.Accruals as b
	on a.gvkeypeer = b.gvkey and a.fycompustat = b.fyear+1
	order by cik, fycompustat, grantid, peercik;
quit;

* For computing equally weighted accruals, drop repeated peers due to diff grants share many peers;
data relpeerem_l2; set relpeerem_l; drop grantid ticpeer conmpeer ;run;
proc sort data=relpeerem_l2 nodupkey; by cik fycompustat peercik;run;

proc means data = relpeerem_l2 noprint; 
    Vars CAdTAtm1DechowEtAl_w DCAJones1991_w DCAJones1991int_w DCAModJones1991_w DCAModJones1991int_w;
    by cik fycompustat ;
	output out=relpeerem_l3(drop=_type_ _freq_) mean(CAdTAtm1DechowEtAl_w)=avg_CAdTA_l mean(DCAJones1991_w)=avg_dcaj_l mean(DCAJones1991int_w) = avg_dcajint_l mean(dcamodjones1991_w)=avg_dcamj_l mean(dcamodjones1991int_w)=avg_dcamjint_l
    median(CAdTAtm1DechowEtAl_w)=med_CAdTA_l median(DCAJones1991_w)=med_dcaj_l median(DCAJones1991int_w) = med_dcajint_l median(dcamodjones1991_w)=med_dcamj_l median(dcamodjones1991int_w)=med_dcamjint_l;
run;

* merge comtemporaneous and lagged accruals;
proc sql;
    create table relpeerEMall as select a.*, avg_CAdTA_l, avg_dcaj_l, avg_dcajint_l, avg_dcamj_l, avg_dcamjint_l,
    med_CAdTA_l, med_dcaj_l, med_dcajint_l, med_dcamj_l, med_dcamjint_l
    from relpeerem3 as a join relpeerem_l3 as b
	on a.cik = b.cik and a.fycompustat=b.fycompustat
    order by cik, fycompustat;
quit;

/* get accruals for dependent var; */
proc sql; 
    create table relpeerEMall2 as select a.*, b.gvkey
	from relpeerEMall as a left join compna.funda as b
	on a.cik=b.cik and a.fycompustat=b.fyear
    order by cik, fycompustat
;
quit;

proc sort data=relpeerEMall2 nodupkey; by cik fycompustat; run;

proc sql;
    create table relpeerEMall3 as select a.*, 
    CAdTAtm1DechowEtAl as cadta, DCAJones1991 as dcaj, DCAJones1991int as dcajint, DCAModJones1991 as dcamj, DCAModJones1991int as dcamjint
	from relpeerEMall2 as a join my.Accruals as b
	on a.gvkey = b.gvkey and a.fycompustat = b.fyear
	order by cik, fycompustat;
quit;

data my.relpeerEM; set relpeeremall3; run;


/**** Merge accruals with other controlling vars ****/
proc sql;
    create table main as select a.*, bm, size, roa, evol, rety, FF12, permno
    from my.relpeerEM as a left join my.indep as b
	on a.gvkey = b.gvkey and a.fycompustat=b.fyear
    order by cik, fycompustat;
quit;

proc sort data=main nodupkey; by cik fycompustat; run;

proc sql;
    create table main2 as select a.*, 
	c.bm as bm_l, c.size as size_l, c.roa as roa_l, c.evol as evol_l, c.rety as rety_l
	from main as a left join indep as c 
	on a.gvkey = c.gvkey and a.fycompustat = c.fyear+1
    order by cik, fycompustat;
quit;

proc sort data=main2 nodupkey; by cik fycompustat; run;

data main3; set main2; if FF12~=11; run;

data my.main; set main3; run;

/** Summary Stat of all variables for RPE firms **/
proc means data=main3 mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max;
    vars bm size roa evol rety cadta dcaj dcajint dcamj dcamjint 
    avg_cadta avg_dcaj avg_dcajint avg_dcamj avg_dcamjint
	med_cadta med_dcaj med_dcajint med_dcamj med_dcamjint;
run;

/* winsorize */
%winsor(dsetin=my.main, dsetout=main_w, byvar=fycompustat,vars=bm roa evol rety bm_l roa_l evol_l rety_l, type=winsor, pctl=1 99);

data my.main_w; set main_w; run;

proc means data=main_w mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max;
    vars bm roa evol rety;
run;

/** Add industry accruals **/
* get FF12;
proc sql; 
    create table ind_accruals as select a.*, b.hsiccd
	from my.accruals as a left join my.indep as b
	on a.gvkey = b.gvkey and a.fyear=b.fyear
	order by gvkey, fyear;
quit;

proc sort data=ind_accruals nodupkey; by gvkey fyear; run;

proc sort data=ind_accruals; by FF12 fyear; run;
proc means data = ind_accruals noprint; 
    Vars CAdTAtm1DechowEtAl_w DCAJones1991_w DCAJones1991int_w DCAModJones1991_w DCAModJones1991int_w;
    by FF12 fyear;
	output out=ind2(drop=_type_) mean(CAdTAtm1DechowEtAl_w)=avg_CAdTA_FF12 mean(DCAJones1991_w)=avg_dcaj_FF12 mean(DCAJones1991int_w) = avg_dcajint_FF12 mean(dcamodjones1991_w)=avg_dcamj_FF12 mean(dcamodjones1991int_w)=avg_dcamjint_FF12
    median(CAdTAtm1DechowEtAl_w)=med_CAdTA_FF12 median(DCAJones1991_w)=med_dcaj_FF12 median(DCAJones1991int_w) = med_dcajint_FF12 median(dcamodjones1991_w)=med_dcamj_FF12 median(dcamodjones1991int_w)=med_dcamjint_FF12;
run;

data ind2; set ind2; if ff12 ~=.; run; 
proc export data=ind2 outfile='ind_accruals.dta' replace;run;

* merge with main_w;
proc sql;
    create table main_w2 as select a.*, avg_CAdTA_FF12, avg_dcaj_FF12, avg_dcajint_FF12, avg_dcamj_FF12, avg_dcamjint_FF12,
    med_CAdTA_FF12, med_dcaj_FF12, med_dcajint_FF12, med_dcamj_FF12, med_dcamjint_FF12
    from my.main_w as a left join ind2 as b
	on a.FF12 = b.FF12 and a.fycompustat = b.fyear
	order by cik, fycompustat;
quit;

proc sql;
    create table main_w3 as select a.*, 
    b.avg_CAdTA_FF12 as avg_CAdTA_FF12_l, b.avg_dcaj_FF12 as avg_dcaj_FF12_l, b.avg_dcajint_FF12 as avg_dcajint_FF12_l, b.avg_dcamj_FF12 as avg_dcamj_FF12_l, b.avg_dcamjint_FF12 as avg_dcamjint_FF12_l,
    b.med_CAdTA_FF12 as med_CAdTA_FF12_l, b.med_dcaj_FF12 as med_dcaj_FF12_l, b.med_dcajint_FF12 as med_dcajint_FF12_l, b.med_dcamj_FF12 as med_dcamj_FF12_l, b.med_dcamjint_FF12 as med_dcamjint_FF12_l
    from main_w2 as a left join ind2 as b
	on a.FF12 = b.FF12 and a.fycompustat = b.fyear +1
	order by cik, fycompustat;
quit;

* save;
data my.main_w; set main_w3; run;


/** Add firm lag accruals **/
proc sql;
    create table temp as select a.*, 
    CAdTAtm1DechowEtAl as cadta_l, DCAJones1991 as dcaj_l, DCAJones1991int as dcajint_l, DCAModJones1991 as dcamj_l, DCAModJones1991int as dcamjint_l
	from my.main_w as a left join my.Accruals as b
	on a.gvkey = b.gvkey and a.fycompustat = b.fyear+1
	order by cik, fycompustat;
quit;

data my.main_w; set temp; run;


/***** Add RPE pct ********/
/* compute total FV of each firm*/
data grant; set my.grant_fvj; keep cik fycompustat grantid fv_w; run;

proc sort data=grant; by cik fycompustat; run;
proc means data=grant noprint;
vars fv_w;
by cik fycompustat;
output out=grant_firm sum=fv_firm; run;

/* compute total RPE FV of each firm*/
proc sql;
    create table temp as select a.*, b.fycompustat, b.fv_w
	from inclab.gpbarelpeer as a left join my.grant_fvj as b
	on a.grantid = b.grantid
    order by cik, fycompustat;
quit;

proc sort data=temp nodupkey; by grantid; run;

proc sort data=temp; by cik fycompustat; run;
proc means data=temp noprint;
    vars fv_w;
    by cik fycompustat;
    output out=RPEgrant_firm sum=fv_RPE; 
run;

/* compute RPE pct */
proc sql;
    create table rpepct as select a.cik, a.fycompustat, fv_RPE, fv_firm, fv_RPE/fv_firm as RPEpct
	from RPEgrant_firm as a left join grant_firm as b
	on a.cik=b.cik and a.fycompustat = b.fycompustat
	order by cik, fycompustat;
quit;

* summary analysis;
proc sort data=rpepct; by fycompustat;run; 
proc means data= RPEpct mean median min max std P1 P5 P75 P99 noprint;
    VARS RPEpct ;
    by fycompustat;
    output out=temp(drop=_type_ ) mean(RPEpct)=m_pct median(rpEpct)=med_pct min(rpepct)=min_pct max(rpepct)=max_pct;
run;

proc sql;
    create table main_w as select a.*, b.RPEpct 
	from my.main_w as a left join RPEpct as b
	on a.cik=b.cik and a.fycompustat = b.fycompustat
	order by cik, fycompustat;
quit;

data my.main_w; set main_w; run;


/** Add accounting pct **/
proc sql;
    create table rel_fv as select a.*, b.cik, b.FV_w, b.fycompustat, b.fiscalyear
	from inclab.gpbarel as a left join my.grant_fvj as b
	on a.grantid = b.grantid
	order by cik, fycompustat, grantid, relid, periodid;
quit;

/* unique by grantid *
proc sql;
create table temp as select *, N(distinct grantid) as N
from rel_fv
group by grantid
order by cik, fycompustat, grantid, N;
quit;
*/

proc sql;
    create table rel_fv as select *, FV_w/sum(FV_w) as FV_pct
	from rel_fv
	group by cik, fycompustat
	order by cik, fycompustat;
quit;

proc export data=rel_fv(where=(relativeBenchmark="Peer Group")) outfile='E:\Research\WB\RPE_EM\data_code\rpegrant.dta' replace;run;

 

proc means data=rel_fv2 mean median STD min max P1 P5 P10 P25 P75 P90 P95 P99;
    vars FV_pct;
	output out=temp ;
run;

proc sql;
    create table rel_fv2 as select *, N(distinct relid) as N_obj
	from rel_fv
	group by grantid
	order by cik, fycompustat, grantid, relid, periodid;
quit;

proc sql;
    create table rel_fv3 as select *, N(relid) as N_period
	from rel_fv2
	group by relid
	order by cik, fycompustat, grantid, relid, periodid;
quit;

data rel_fv4; set rel_fv3;
    D_accounting=0;
    if metrictype='Accounting' then D_accounting=1;
    FV_ObjPeriod = FV_w /N_obj / N_period;
run;

proc sql;
    create table rel_fv5 as select cik, fycompustat, 
    sum( FV_objperiod * D_accounting) as FV_accounting, sum(FV_objperiod) as FV_RPE,
	sum(D_accounting) as N_accounting, count(*) as N
	from rel_fv4
	group by cik, fycompustat
	order by cik, fycompustat;
quit;

data rel_fv5; set rel_fv5;
AccountingPct =	FV_accounting / FV_RPE ;
AccountingPct_ew =	N_accounting / N ;
run;

data temp0; set rel_fv5; if fycompustat > 2005; run;

proc means data=temp0 mean median STD min max P1 P5 P10 P25 P75 P90 P95 P99;
    vars AccountingPct AccountingPct_ew;
	output out=temp ;
run;

* merge into main_w;
proc sql;
    create table main_w as select a.*, b.AccountingPct, AccountingPct_ew
	from my.main_w as a left join rel_fv5 as b
	on a.cik=b.cik and a.fycompustat=b.fycompustat
	order by cik, fycompustat;
quit;




data my.main_w; set main_w; run;

data main_w; set main_w; 
    D_accountingpct = 0; 
    if Accountingpct =1 then D_accountingpct = 1; 
	D_rpepct = 0; 
	if RPEpct > 0.5 then D_rpepct = 1;
run;


/* Add leverage */
proc contents data=sr.srisk_new; run;
data lvg; set sr.srisk_new; 
keep permno date datadate fyear me me_comp me_o lvg; 
run;

proc sql;
create table main_w as select a.*, b.me_o, b.lvg
from my.main_w as a left join lvg as b
on a.permno = b.permno and a.fycompustat = b.fyear 
order by cik, fycompustat;
quit;

/* add restate */
proc sql;
create table main_w as select a.*, (a.cik=b.cik) as D_restate
from my.main_w as a left join my.restate as b
on a.cik=b.cik and year(RES_BEGIN_DATE) <= a.fycompustat <= year(RES_end_DATE)
order by cik, fycompustat;

*one fiscal year could fall in several restate periods. Keep as long as it equals 1;
proc sort data=main_w; by cik fycompustat, D_restate; run;
data main_w; set main_w; by cik fycompustat D_restate; if last.D_restate; run;

proc freq data=main_w; table D_restate; run;



data my.main_w; set main_w; run;

proc export data=my.main_w outfile='D:\RPE\RPE_EM\data_code\main_w.dta' replace;run;



/* Add percentile target  */
proc sql;
    create table rel_fv as select a.*, b.cik, b.FV_w, b.fycompustat, b.fiscalyear
	from inclab.gpbarel as a left join my.grant_fvj as b
	on a.grantid = b.grantid
	order by cik, fycompustat, grantid, relid, periodid;
quit;

proc freq data=rel_fv; tables goaltarget; quit; /* 32% goals are negative. Why? */

data temp; set rel_fv; keep cik fycompustat goaltarget ; run;
proc sort data=temp nodupkeys; by cik fycompustat goaltarget; run; 
proc sql; create table temp2 as select cik, fycompustat, goaltarget, count(goaltarget) as n from temp group by cik, fycompustat; quit;
proc freq data=temp2; table n; quit; 
data temp3; set temp2; if n>1; run; /*75% firms have same target for all grants */

proc sql;
create table target2 as select cik, fycompustat, min(goalTarget) as target from rel_fv
group by cik, fycompustat;
quit;

proc export data=target2 outfile='F:\Research\WB\RPE_EM\data_code\D_target.dta' replace;run;

data temp; set rel_fv; if cik="0001168054"; run;

/*
cik          fyear  target percentile   14A
0000002488   2006   -9999.02         https://www.sec.gov/Archives/edgar/data/2488/000119312507054802/ddef14a.htm;
0000068505   2013    7               https://www.sec.gov/Archives/edgar/data/68505/000119312514107226/d689619ddef14a.htm
0001087423   2014    50              https://www.sec.gov/Archives/edgar/data/1087423/000119312514249099/d743610ddef14a.htm#toc743610_39 */




/* Add index target dummy */
proc sql;
    create table rel_fv as select a.*, b.cik, b.FV_w, b.fycompustat, b.fiscalyear
	from inclab.gpbarel as a left join my.grant_fvj as b
	on a.grantid = b.grantid
	order by cik, fycompustat, grantid, relid, periodid;
quit;

proc freq data = rel_fv(where=(cik ~= "")); table relativeBenchmark; quit;/*benchmark include NA, Other, Peer Group, S&P500 */
proc freq data = rel_fv(where=(cik ~= "")); table relativeBenchmarkother; quit;/*benchmark include NA, Other, Peer Group, S&P500 */

* get cik for firms using S&P500 or other (most are index);
proc sql; create table indexbench as select unique cik, fycompustat from rel_fv
where cik ~= "" and (relativeBenchmark ="S&P500" | relativeBenchmark ="Other")
order by cik, fycompustat;
quit;

* get indep var for firms using index benchmark;
proc sql;
create table indexbench as select *
from indexbench as a left join my.indep as b 
on a.cik=b.cik and a.fycompustat = b.fyear
order by cik, fycompustat;
quit;

* get cik and gvkey for S&p 500 constituents;
data funda; set comp.funda; 
   where fyr>0 and at>0 and consol='C' and indfmt='INDL' and datafmt='STD' and popsrc='D'
and cik ^= ""; 
   l_AT=lag(AT);
   if gvkey~=lag(gvkey) or year(datadate)> year(lag(datadate))+2 then l_AT = .;
   size = log(AT+1);
   l_size = log(l_at +1);
   keep gvkey fyear fyr cik datadate at l_at size l_size; 
run; 

proc sql;
   create table comp_crsp	
   as select a.*, c.permno, c.date, c.ret, abs(prc*shrout) as MC
   from funda as a,
		link.CCMXPF_LNKHIST as b,		
		crsp.msf (where=( month(date)=12)) as c
	where a.gvkey=b.gvkey and linkprim in ('P','C') and LINKTYPE in ("LU", "LC", "LN", "LS") and
	(c.date >= b.linkdt or b.LINKDT = .B) and (c.date <= b.linkenddt or b.LINKENDDT = .E)
   and b.lpermno=c.permno and year(a.datadate) = year(c.date) ;
quit;

proc sort data = comp_crsp; by cik datadate; run;
data comp_crsp; set comp_crsp; l_MC = lag(MC); if cik~=lag(cik) or year(datadate)~= year(lag(datadate))+1 then l_MC = .; run;

* get cik for sp500;
proc sql;
create table sp500 as select unique cik, fyear, gvkey, l_at, l_size, l_MC
from crsp.dsp500list as a inner join comp_crsp as b 
on a.permno = b.permno and b.date>=a.start and b.date <= a.ending
order by cik, fyear;
quit;

* get accruals;
proc sql;
create table sp500dam as select * from sp500 as b inner join my.accruals as c
on b.cik = c.cik and b.fyear = c.fyear
order by cik, fyear;
quit;

* compute med sp500 accruals;
proc sql;
create table sp500am as select unique fyear, median(dcamodjones1991_w) as med_dcamj, sum(dcamodjones1991_w*l_size)/sum(l_size) as wt_size_dcamj, 
sum(dcamodjones1991_w*l_at)/sum(l_at) as wt_at_dcamj, sum(dcamodjones1991_w*l_mc)/sum(l_mc) as wt_mc_dcamj, mean(dcamodjones1991_w) as avg_dcamj, count(*) as n_peers
from sp500dam 
group by fyear 
order by fyear;
quit;

proc sql;
create table sp500am as select *, wt_size_dcamj/std(wt_size_dcamj) as sd_wt_size_dcamj, wt_at_dcamj/std(wt_at_dcamj) as sd_wt_at_dcamj,
wt_mc_dcamj/std(wt_mc_dcamj) as sd_wt_mc_dcamj, med_dcamj/std(med_dcamj) as sd_med_dcamj, avg_dcamj/std(avg_dcamj) as sd_avg_dcamj
from sp500am ;
quit;

* get med index dam for firms using index benchmark;
proc sql;
create table indexbench2 as select *
from indexbench as a left join sp500am as b 
on a.fycompustat = b.fyear
order by cik, fycompustat;
quit;

* get dam for focal firms;
proc sql;
create table indexbench2 as select *
from indexbench2 as a left join my.accruals as b 
on a.cik=b.cik and a.fycompustat = b.fyear
order by cik, fycompustat;
quit;

proc export data=indexbench2 outfile='F:\Research\WB\RPE_EM\data_code\indexbench.dta' replace;run;



/******* Univariate analysis 
*this part sorts portfilios based on dependent variables and compute independent var for each portfolio;
%let temp_dat=my.main_w(where=(fycomustat>2005)); 
%let temp_dat=temp; 
%let rankvar=dcamj;
%let date1=fycompustat;

%let temp_dat=my.aq_main(where=( fyear>2005& d_rpe=1 )); 
%let rankvar=d_restate;
%let date1=fyear;

%let lag = 0;
data temp_dat;
    set &temp_dat;
    if &rankvar='.' then delete;
run;

proc sort data= temp_dat; by &date1 cik; run;

* sort stocks into 5 quintiles;
proc rank data = temp_dat out=statp group = 5;
    by &date1;
    var &rankvar;
    ranks q;
run;

proc sort data = statp; 
     by q &date1 cik; 
run;

* aggregate individual stock rets to portfolio ret;
proc means data=statp noprint;
    output out = p_sort
/*    mean(dcamj) = dcamj
	mean(med_dcamj) = med_dcamj 
    mean(d_restate) = d_restate
	mean(restatepct) = restatepct
	mean(bm) = bm
    mean(size)=size
	mean(roa) = roa
	mean(evol) = evol
	mean(rety)=rety
	mean(lvg)=lvg;
    by q &date1;
run;

* average of portfolio ret over time;
proc sort data=p_sort; by q &date1;run;
proc means data=p_sort noprint; output out=p_sort2
 *   mean(dcamj) = dcamj
*	mean(med_dcamj) = med_dcamj 
    mean(d_restate) = d_restate
	mean(restatepct) = restatepct
	mean(bm) = bm
    mean(size)=size
	mean(roa) = roa
	mean(evol) = evol
	mean(rety)=rety
	mean(lvg)=lvg;
    by q;
run;

data p_sort2; set p_sort2; q = q+1; run; *add 1 to the defaulted quintile no.

* calculate High-low;
proc sort data=p_sort; 
    by &date1 q; 
run;

proc transpose data=p_sort out=ret_diff prefix=q;
    by &date1; 
    id q;
    * var dcamj med_dcamj bm size roa evol rety lvg; 
    var d_restate restatepct bm size roa evol rety lvg;
run;
data ret_diff; 
    set ret_diff;
    * ret_diff=q4-q0; 
    ret_diff=q4-q2; *restate has only 2 states 
run;

*calculate t-stat;
proc sort data=ret_diff; by _name_ &date1; run;

options nonotes;
proc model data=ret_diff;
    parms a; exogenous ret_diff;
    instruments / intonly;
	by _name_;
    ret_diff=a;
    fit ret_diff / gmm kernel=(bart, %eval(&lag+1),0);
    ods output parameterestimates=para ;
quit;

data para;
    set para;
    keep _name_ estimate StdErr tValue; 
run;

proc transpose data=para out=para2;
    id _name_;
    var estimate StdErr tValue;
run;

data para3; set para2;
if _name_ = 'Estimate' then q='H-L';
if _name_ = 'StdErr' then q='Std';
if _name_ = 'tValue' then q='t';
drop _label_ _name_;
run;

data p_sort3;set p_sort2;drop _type_ _freq_; q2 = put(q,6.); drop q; rename q2=q; run;
proc append base=p_sort3 data = para3; run;

proc print data=p_sort3; run;


/********* Panel Reg ******

data main3; set my.main_w; if cmiss(of _all_) then delete; run; 

proc glm data=main3;
 *absorb cik ;/* controlling for the indiv effect, but not show related estimates; 
    class fycompustat cik;
    model dcaj = avg_dcaj bm_l size_l roa_l rety_l evol_l fycompustat cik/ solution; 
quit;

proc glm data=main3;
    class fycompustat FF12;
    model dcajint = avg_dcajint  fycompustat FF12 / solution; 
quit;

proc glm data=main3;
     class fycompustat FF12;
     model dcamj = avg_dcamj  fycompustat FF12 / solution; 
     ods output ParameterEstimates=glmp_a3;
quit;

proc print data=glmp_a3 noobs;
    var parameter estimate stderr tValue Probt;
run;

proc glm data=main3;
    class fycompustat FF12;
    model dcamjint = avg_dcamjint  fycompustat FF12 / solution; 
quit;

/* genmod can only culster at 1 dimension;
proc genmod data=main3;
 class FYCOMPUstat;
 model dcaj = avg_dcaj;
 repeated subject=fycompustat / type=ind; run;
quit;


proc surveyreg data=main3; 
cluster fycompustat FF12;
class FF12 ; 
model dcaj = avg_dcaj FF12/ noint solution; 
run;
*/




