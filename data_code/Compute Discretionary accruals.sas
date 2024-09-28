/*************************************************************************
Title:   Compute Earnings Management Based on Yore's Code
Author:  Jinjing Liu
Date:    1/9/2018
*************************************************************************/;
 
/*************************************************************************
BEGIN WORKSPACE CLEAN AND SETTINGS:
*************************************************************************/;
options errors=3 noovp;
options nocenter ps=max ls=78;
options mprint source nodate symbolgen macrogen;
options msglevel=i;
options validvarname=any;
Proc Datasets LIBRARY=WORK NOLIST KILL;
quit;

libname inclab 'D:\RPE_EM\IncLab_data';
libname compNA 'D:\Data\CompNA';
libname my 'D:\RPE\RPE_EM\data_code';

* for codes running on the server;
libname celim '/home/uga/celim';
libname compNA '/wrds/comp/sasdata/nam';

/* END WORKSPACE CLEAN AND SETTINGS */;
 
 
/*************************************************************************
BEGIN ASSEMBLE ESSENTIAL COMPUSTAT VARIABLES:
*************************************************************************/;
data EarningsManagement; set compNA.funda;
where INDFMT = 'INDL' AND DATAFMT = 'STD' AND POPSRC = 'D' AND CONSOL = 'C';
CYEAR = YEAR(DATADATE);
KEEP GVKEY CYEAR FYEAR SICH ACT AT CHE DLC DP LCT PPENT PPEGT RECT RECTR SALE;
run;

proc sql;
create table earningsmanagement as select a.*, b.sic
from EarningsManagement as a left join compNA.names as b
on a.gvkey=b.gvkey and year1 < cyear < year2;
run;

data earnginsmanagement; set earningsmanagement;
if missing(SIC) then SIC=SICH;
run;

proc sort data = EarningsManagement nodupkey;
by GVKEY FYEAR;
run;
/* END ASSEMBLE ESSENTIAL COMPUSTAT VARIABLES */;
 
 
 
/*************************************************************************
BEGIN CREATE EARNINGS MANAGEMENT VARIABLES:
*************************************************************************/;
data EarningsManagement; set EarningsManagement;
SIC2 = int(SIC/100);
 
* Create lags;
GVKEYtm1   = lag(GVKEY);
FYEARtm1   = lag(FYEAR);
ACTtm1     = lag(ACT);
ATtm1      = lag(AT);
CHEtm1     = lag(CHE);
DLCtm1     = lag(DLC);
LCTtm1     = lag(LCT);
PPEGTtm1   = lag(PPEGT);
PPENTtm1   = lag(PPENT);
RECTtm1    = lag(RECT);
RECTRtm1   = lag(RECTR);
SALEtm1    = lag(SALE);
 
if GVKEY ne GVKEYtm1 OR FYEAR ne (FYEARtm1+1) then do;
    ACTtm1    = .;
    ATtm1     = .;
    CHEtm1    = .;
    DLCtm1    = .;
    LCTtm1    = .;
    PPEGTtm1  = .;
    PPENTtm1  = .;
    RECTtm1   = .;
    RECTRtm1  = .;
    SALEtm1   = .;
end;
 
* Computation Variables;
ATtm1Inverse           = 1 / ATtm1;
ChgSALEdATtm1          = (SALE-SALEtm1) / ATtm1;
ChgRECTdATtm1          = (RECT-RECTtm1) / ATtm1;
ChgSALEmChgRECTdATtm1  = ((SALE-SALEtm1)-(RECT-RECTtm1))   / ATtm1;
ChgSALEmChgRECTRdATtm1 = ((SALE-SALEtm1)-(RECTR-RECTRtm1)) / ATtm1;
PPEGTdATtm1            = PPEGT/ATtm1; 
 
* Calculate Current Accruals as in Dechow, Sloan, and Sweeney (1995);
CADechowEtAl       = (ACT-ACTtm1)-(LCT-LCTtm1)
                     -(CHE-CHEtm1)+(DLC-DLCtm1)-DP;
CAdTAtm1DechowEtAl = CADechowEtAl/ATtm1;
 
run;

/* END CREATE EARNINGS MANAGEMENT VARIABLES */;
 
 
/*************************************************************************
BEGIN ESTIMATE NON-DISCRETIONARY ACCRUALS:
*************************************************************************/;

* Prepare Estimation of Non-Discretionary Accruals;
data EstimationInput; set EarningsManagement;
KEEP CYEAR SIC2 CAdTAtm1DechowEtAl ATtm1Inverse 
ChgSALEdATtm1 ChgSALEmChgRECTdATtm1 PPEGTdATtm1;
run;
proc sort data = EstimationInput;
by CYEAR SIC2;
run;

* Estimate Jones (1991) Non-Discretionary Current Accruals w/o Intercept;
proc reg data = EstimationInput 
noprint tableout edf outest = Jones1991Estimation;
by CYEAR SIC2;
model CAdTAtm1DechowEtAl = ATtm1Inverse ChgSALEdATtm1 PPEGTdATtm1 / noint;
quit;
data Jones1991Estimation; set Jones1991Estimation;
where _TYPE_ = 'PARMS';
Jones1991ATParm = ATtm1Inverse;
Jones1991SALEParm = ChgSALEdATtm1;
Jones1991PPEParm = PPEGTdATtm1;
Jones1991NumFirms = _EDF_ + _P_;
run;
* If one of 3 variables is missing for all firms in an industry, then make parameters missing;
data Jones1991Estimation; set Jones1991Estimation;
if _P_ < 3 then do;
	Jones1991ATParm = .;
	Jones1991SALEParm = .;
	Jones1991PPEParm = .;
end;
run;
data Jones1991Estimation; set Jones1991Estimation;
Jones1991NumFirmsLT10 = 0;
if Jones1991NumFirms < 10 then Jones1991NumFirmsLT10 = 1;
run;
data Jones1991Estimation; set Jones1991Estimation;
KEEP CYEAR SIC2 
Jones1991NumFirms Jones1991NumFirmsLT10 Jones1991ATParm Jones1991SALEParm Jones1991PPEParm;
run;

* Estimate Jones (1991) Non-Discretionary Current Accruals w/ Intercept;
proc reg data = EstimationInput 
noprint tableout edf outest = Jones1991EstimationInt;
by CYEAR SIC2;
model CAdTAtm1DechowEtAl = ATtm1Inverse ChgSALEdATtm1 PPEGTdATtm1;
quit;

data Jones1991EstimationInt; set Jones1991EstimationInt;
where _TYPE_ = 'PARMS';
Jones1991Intercept = Intercept;
Jones1991IntATParm = ATtm1Inverse;
Jones1991IntSALEParm = ChgSALEdATtm1;
Jones1991IntPPEParm= PPEGTdATtm1;
if _P_ < 4 then do;
	Jones1991Intercept = .;
	Jones1991IntATParm = .;
	Jones1991IntSALEParm = .;
	Jones1991IntPPEParm = .;
end;
KEEP CYEAR SIC2 
Jones1991Intercept Jones1991IntATParm 
Jones1991IntSALEParm Jones1991IntPPEParm;
run;

* Estimate Modified Jones (1991) Non-Discretionary Current Accruals w/o Intercept;
proc reg data = EstimationInput 
noprint tableout edf outest = ModJones1991Estimation;
by CYEAR SIC2;
model CAdTAtm1DechowEtAl = ATtm1Inverse ChgSALEmChgRECTdATtm1 PPEGTdATtm1 / noint;
quit;
data ModJones1991Estimation; set ModJones1991Estimation;
where _TYPE_ = 'PARMS';
ModJones1991ATParm = ATtm1Inverse;
ModJones1991SALERECParm = ChgSALEmChgRECTdATtm1;
ModJones1991PPEParm = PPEGTdATtm1;
ModJones1991NumFirms = _EDF_ + _P_;
if _P_ < 3 then do;
    ModJones1991ATParm = .;
	ModJones1991SALERECParm = .;
	ModJones1991PPEParm = .;
end;
ModJones1991NumFirmsLT10 = 0;
if ModJones1991NumFirms < 10 then ModJones1991NumFirmsLT10 = 1;
KEEP CYEAR SIC2 
ModJones1991NumFirms ModJones1991NumFirmsLT10 ModJones1991ATParm 
ModJones1991SALERECParm ModJones1991PPEParm;
run;

* Estimate Modified Jones (1991) Non-Discretionary Current Accruals w/ Intercept;
proc reg data = EstimationInput 
noprint tableout edf outest = ModJones1991EstimationInt;
by CYEAR SIC2;
model CAdTAtm1DechowEtAl = ATtm1Inverse ChgSALEmChgRECTdATtm1 PPEGTdATtm1;
quit;
data ModJones1991EstimationInt; set ModJones1991EstimationInt;
where _TYPE_ = 'PARMS';
ModJones1991Intercept = Intercept;
ModJones1991IntATParm = ATtm1Inverse;
ModJones1991IntSALERECParm = ChgSALEmChgRECTdATtm1;
ModJones1991IntPPEParm = PPEGTdATtm1;
if _P_ < 4 then do;
	ModJones1991Intercept = .;
	ModJones1991IntATParm = .;
	ModJones1991IntSALERECParm = .;
	ModJones1991IntPPEParm = .;
end;
KEEP CYEAR SIC2 
ModJones1991Intercept ModJones1991IntATParm
ModJones1991IntSALERECParm ModJones1991IntPPEParm;
run;

/* Combine estimations for importing and to save for archival purposes */
data EarningsManagementEstimations; set EstimationInput;
KEEP SIC2 CYEAR;
LABEL SIC2 = 'Two-Digit SIC Code'
	CYEAR = 'Calendar Year';
run; 
proc sort data = EarningsManagementEstimations nodupkey;
by CYEAR SIC2;
run;
proc sql;
create table EarningsManagementEstimations as
select a.*, 
b.Jones1991NumFirms, b.Jones1991NumFirmsLT10, b.Jones1991ATParm, b.Jones1991SALEParm, b.Jones1991PPEParm,
c.Jones1991Intercept, c.Jones1991IntATParm, c.Jones1991IntSALEParm, c.Jones1991IntPPEParm,
d.ModJones1991NumFirms, d.ModJones1991NumFirmsLT10, d.ModJones1991ATParm, d.ModJones1991SALERECParm, d.ModJones1991PPEParm,
e.ModJones1991Intercept, e.ModJones1991IntATParm, e.ModJones1991IntSALERECParm, e.ModJones1991IntPPEParm
from EarningsManagementEstimations as a 
LEFT JOIN Jones1991Estimation as b on a.CYEAR = b.CYEAR and a.SIC2 = b.SIC2
left join Jones1991EstimationInt as c on a.CYEAR = c.CYEAR and a.SIC2 = c.SIC2
LEFT JOIN ModJones1991Estimation as d on a.CYEAR = d.CYEAR and a.SIC2 = d.SIC2
LEFT JOIN ModJones1991EstimationInt as e on a.CYEAR = e.CYEAR and a.SIC2 = e.SIC2;
quit;
/* END ESTIMATE NON-DISCRETIONARY ACCRUALS */;
 
 
/*************************************************************************
BEGIN IMPORT ESTIMATIONS AND COMPUTE DISCRETIONARY ACCRUALS:
*************************************************************************/;
proc sql;
create table EarningsManagement as
select a.*,
b.Jones1991NumFirms, b.Jones1991NumFirmsLT10, b.Jones1991ATParm, 
b.Jones1991SALEParm, b.Jones1991PPEParm,
b.Jones1991Intercept, b.Jones1991IntATParm, b.Jones1991IntSALEParm, 
b.Jones1991IntPPEParm,
b.ModJones1991NumFirms, b.ModJones1991NumFirmsLT10, b.ModJones1991ATParm, 
b.ModJones1991SALERECParm, b.ModJones1991PPEParm,
b.ModJones1991Intercept, b.ModJones1991IntATParm, 
b.ModJones1991IntSALERECParm, b.ModJones1991IntPPEParm
from EarningsManagement as a LEFT JOIN EarningsManagementEstimations as b
on a.CYEAR = b.CYEAR and 
	a.SIC2 = b.SIC2;
quit;
data EarningsManagementFinal; set EarningsManagement;
TCAJones1991 = CAdTAtm1DechowEtAl;
NDCAJones1991 = (Jones1991ATParm * ATtm1Inverse)+ (Jones1991SALEParm * ChgSALEdATtm1)+ (Jones1991PPEParm * PPEGTdATtm1);
NDCAJones1991Int = Jones1991Intercept + (Jones1991IntATParm * ATtm1Inverse)+ (Jones1991IntSALEParm * ChgSALEdATtm1)+ (Jones1991IntPPEParm * PPEGTdATtm1);
DCAJones1991 = TCAJones1991 - NDCAJones1991;
DCAJones1991Int = TCAJones1991 - NDCAJones1991Int;

TCAModJones1991 = CAdTAtm1DechowEtAl;
NDCAModJones1991 = (ModJones1991ATParm * ATtm1Inverse)+ (ModJones1991SALERECParm * ChgSALEmChgRECTdATtm1)+ (ModJones1991PPEParm * PPEGTdATtm1);
NDCAModJones1991Int = ModJones1991Intercept + (ModJones1991IntATParm * ATtm1Inverse)+ (ModJones1991IntSALERECParm * ChgSALEmChgRECTdATtm1)+ (ModJones1991IntPPEParm * PPEGTdATtm1);
DCAModJones1991 = TCAModJones1991 - NDCAModJones1991;
DCAModJones1991Int = TCAModJones1991 - NDCAModJones1991Int;

KEEP GVKEY FYEAR 
CAdTAtm1DechowEtAl 
Jones1991NumFirms Jones1991NumFirmsLT10 TCAJones1991 NDCAJones1991 NDCAJones1991Int DCAJones1991 DCAJones1991Int
ModJones1991NumFirms ModJones1991NumFirmsLT10 TCAModJones1991 NDCAModJones1991 NDCAModJones1991Int DCAModJones1991 DCAModJones1991Int;
run;
data EarningsManagementFinal;
RETAIN GVKEY FYEAR CAdTAtm1DechowEtAl
Jones1991NumFirms Jones1991NumFirmsLT10 NDCAJones1991 NDCAJones1991Int DCAJones1991 DCAJones1991Int
ModJones1991NumFirms ModJones1991NumFirmsLT10 NDCAModJones1991 NDCAModJones1991Int DCAModJones1991 DCAModJones1991Int;
set EarningsManagementFinal;
if Jones1991NumFirmsLT10 = 0 and ModJones1991NumFirmsLT10=0;*remove 5\% if the number of firms<=10;
run;


/* WINSORIZE TOTAL, NONSIDCRETIONARY AND DISCRETIONARY ACCRUALS */;
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

%winsor( dsetin=EarningsManagementFinal, dsetout=EarningsManagementFinal2, byvar=fyear,
vars=CAdTAtm1DechowEtAl ndcajones1991 dcajones1991 ndcajones1991int dcajones1991int 
ndcamodjones1991 dcamodjones1991 ndcamodjones1991int dcamodjones1991int );

data earningsmanagementfinal2; set earningsmanagementfinal2;
rename 
CAdTAtm1DechowEtAl = CAdTAtm1DechowEtAl_w 
ndcajones1991 = ndcajones1991_w
dcajones1991 = dcajones1991_w
ndcajones1991int = ndcajones1991int_w
dcajones1991int = dcajones1991int_w 
ndcamodjones1991 = ndcamodjones1991_w
dcamodjones1991 = dcamodjones1991_w 
ndcamodjones1991int = ndcamodjones1991int_w
dcamodjones1991int = dcamodjones1991int_w; 
run;

* merge with unwinsorized;
proc sort data=my.earningsmanagementfinal nodupkey;
by GVKEY FYEAR;
run;

proc sort data=earningsmanagementfinal2 nodupkey;
by GVKEY FYEAR;
run;

data accruals;
merge my.earningsmanagementfinal earningsmanagementfinal2; 
by gvkey fyear;
run;


* get cik;
libname sr "D:\RPE\Systemic_Risk";

proc sql; create table accruals as select a.*, b.cik 
from my.accruals as a left join sr.funda_part as b
on a.gvkey = b.gvkey and a.fyear = b.fyear
order by cik, fyear;
quit;

data my.accruals; set accruals; run;

proc export data=my.accruals(where=(cik~='')) outfile='D:\RPE\RPE_EM\data_code\accruals.dta' replace;run;

* remove all labels if any;
proc datasets lib=my memtype=data;
    modify accruals;
	attrib _all_ label='';
run;




/*************************************************************************
BEGIN ANALYZE FINAL PANEL DATASET:
*************************************************************************/;
Proc Tabulate data = my.accruals(where=(Jones1991NumFirmsLT10 = 0 and ModJones1991NumFirmsLT10=0)) Format = 7.3;
Title "Earnings Management Descriptive Statistics";
Var CAdTAtm1DechowEtAl NDCAJones1991 NDCAJones1991Int DCAJones1991	DCAJones1991Int
	NDCAModJones1991	NDCAModJones1991Int DCAModJones1991	DCAModJones1991Int
    CAdTAtm1DechowEtAl_w NDCAJones1991_w NDCAJones1991Int_w DCAJones1991_w DCAJones1991Int_w
	NDCAModJones1991_w NDCAModJones1991Int_w DCAModJones1991_w	DCAModJones1991Int_w ;
Tables CAdTAtm1DechowEtAl NDCAJones1991	NDCAJones1991Int DCAJones1991	DCAJones1991Int
	NDCAModJones1991 NDCAModJones1991Int DCAModJones1991	DCAModJones1991Int
	CAdTAtm1DechowEtAl_w NDCAJones1991_w NDCAJones1991Int_w DCAJones1991_w DCAJones1991Int_w
	NDCAModJones1991_w NDCAModJones1991Int_w DCAModJones1991_w	DCAModJones1991Int_w,
N*F=7.0 NMISS*F=7.0 MEAN STD MIN Q1 MEDIAN Q3 MAX / RTSPACE=20;
KEYLABEL N	= 'N'
	NMISS	= 'Missing'
	Mean	= 'Mean'
	Median	= 'Median'
	Min	= 'Min'
	Max	= 'Max'
	STD	= 'Std Dev'
	Q1 = 'Q1'
	Q3 = 'Q3';
run;
/* END ANALYZE FINAL PANEL DATASET */;
 
 
/****************************************************************************
                  END OF COMPUTE EARNINGS MANAGEMENT VARIABLES
****************************************************************************/;
