*************************************************************************
*Title:   Compute Dechow and Dichev’s (2002) accruals
*Date:    01/4/2024;
*************************************************************************;

libname compu 'E:\Data\CompNA';
libname my 'E:\Research\WB\RPE_EM\data_code';

/*************************************************************************
BEGIN ASSEMBLE ESSENTIAL COMPUSTAT VARIABLES:
*************************************************************************/;
data compu; set compu.funda;
where INDFMT = 'INDL' AND DATAFMT = 'STD' AND POPSRC = 'D' AND CONSOL = 'C';
CYEAR = YEAR(DATADATE);
KEEP GVKEY cik CYEAR FYEAR SICH AT oancf recch invch apalch txach aoloch;
run;

proc sort data = compu nodupkey;
by GVKEY FYEAR;
run;

%ff12(dsin = compu, dsout = compu2, sicvar=sich);
%ff48(dsin = compu2, dsout = compu2, sicvar=sich);

/* END ASSEMBLE ESSENTIAL COMPUSTAT VARIABLES */
  
/*************************************************************************
BEGIN CREATE EARNINGS MANAGEMENT VARIABLES:
*************************************************************************/;
data compu2; set compu2;
lagAT      = lag(AT);
if GVKEY ne lag(GVKEY) OR FYEAR ne (lag(FYEAR)+1) then do;
    lagAT     = .;
end;
run;

data compu2; set compu2;
avgta = (AT + lagAT)/2;
SIC2 = int(SICh/100);
ocf = oancf / avgta ;
dwc = -(recch + invch + apalch + txach + aoloch)/avgta;

lagocf = lag(ocf);
if GVKEY ne lag(GVKEY) OR FYEAR ne (lag(FYEAR)+1) then do;
    lagocf     = .;
end;
run;

proc sort data = compu2 nodupkey;
by GVKEY DESCENDING FYEAR;
run;

data compu3; set compu2; 
leadocf = lag(ocf);
if GVKEY ne lag(GVKEY) OR FYEAR ne (lag(FYEAR)-1) then do;
    leadocf     = .;
end;
run;

proc sort data = compu3 nodupkey;
by GVKEY FYEAR;
run;

/* END CREATE EARNINGS MANAGEMENT VARIABLES */;
 
/*****************************************
Trim or winsorize macro
* byvar = none for no byvar;
* type  = delete/winsor (delete will trim, winsor will winsorize;
*dsetin = dataset to winsorize/trim;
*dsetout = dataset to output with winsorized/trimmed values;
*byvar = subsetting variables to winsorize/trim on;
****************************************/;

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

%winsor( dsetin=compu3, dsetout=compu4, byvar=FYEAR,vars = lagocf ocf leadocf )

data temp; set compu4; 
rename fyear = fycompustat; 
keep gvkey cik fyear ocf lagocf leadocf;
if cik ~=. and ocf~=.;
run;

proc export data=temp outfile='E:\Research\WB\RPE_EM\data_code\DD_estimation_var_1st.dta' replace;
run;


/*************************************************************************
BEGIN ESTIMATE NON-DISCRETIONARY ACCRUALS:
*************************************************************************/;
* Prepare Estimation of Non-Discretionary Accruals;
proc sort data = compu4;
by FYEAR ff48;
run;
* Estimate  Accruals ;
proc reg data = compu4 
noprint tableout edf outest = DDestimation;
by FYEAR ff48;
model dwc = lagocf ocf leadocf ;
quit;

data DDestimation; set DDestimation;
where _TYPE_ = 'PARMS';
lagocfParm = lagocf;
ocfParm = ocf;
leadocfParm = leadocf;
NumFirms = _EDF_ + _P_;
run;
* If one of 3 variables is missing for all firms in an industry, then make parameters missing;
data DDestimation; set DDestimation;
if _P_ < 3 then do;
	lagocfParm = .;
	ocfParm = .;
	leadocfParm = .;
end;
run;

data DDestimation; set DDestimation;
D_NumFirms = 0;
if NumFirms < 20 then D_NumFirms = 1;
run;

data DDestimation; set DDestimation;
KEEP FYEAR ff48 
lagocfParm ocfParm leadocfParm NumFirms D_NumFirms;
run;

/* END ESTIMATE NON-DISCRETIONARY ACCRUALS */;

 
/*************************************************************************
BEGIN IMPORT ESTIMATIONS AND COMPUTE DISCRETIONARY ACCRUALS:
*************************************************************************/;
proc sql;
create table DDestimation2 as
select a.*, lagocfParm, ocfParm, leadocfParm, NumFirms, D_NumFirms
from compu4 as a LEFT JOIN DDestimation as b
on a.FYEAR = b.FYEAR and 
	a.ff48 = b.ff48;
quit;

data DDestimation2; set DDestimation2;
if FYEAR=. | GVKEY = . then delete; 
DDndc = (lagocfParm * lagocf)+ (ocfParm * ocf)+ (leadocfParm * leadocf);
DDdc = dwc - DDndc;

LABEL dwc = 'Change in Working capital - DD Model'
	DDndc = 'Nondiscretionary Accruals - DD model'
	DDdc = 'Discretionary Accruals - DD Model';

KEEP GVKEY FYEAR ff48 lagocf ocf leadocf lagocfParm ocfParm leadocfParm NumFirms D_NumFirms dwc DDndc DDdc;
run;

/* END IMPORT ESTIMATIONS AND COMPUTE DISCRETIONARY ACCRUALS */;

* winsorize DDdc at 1 and 99%;
proc means data=DDestimation2;
var DDndc DDdc;
quit;

%winsor(dsetin=DDestimation2, dsetout=DDestimation3, byvar=none,vars = DDdc);

proc means data=DDestimation3;
var DDdc;
quit;


/** calculate vol of residuals **/
proc sort data = DDestimation3; by GVKEY FYEAR; run;

* count non-missing dc;
data DDestimation3;
	set DDestimation3;
	if DDdc= . then ccount = 0; else ccount = 1; 
run;

proc expand data = DDestimation3 OUT = DDestimation4; 
	by GVKEY;
	id FYEAR;
 	convert DDdc=std_DDdc / TRANSFORMOUT=(movstd 5 TRIMLEFT 3);
 	convert ccount=tcount / TRANSFORMOUT=(movsum 5 TRIMLEFT 3);
run;

data DDestimation5; set DDestimation4; 
if DDdc=. then delete;
if tcount <3 then std_DDdc = .;
keep gvkey fyear DDdc std_DDdc NumFirms D_NumFirms tcount;
rename tcount = NumYearsforstd;
rename NumFirms = NumFirmsrunDDdc;
run;


data my.DDestimation; set DDestimation5; run;

*Export and winsorize in stat;
proc export data=DDestimation5 outfile='F:\Research\WB\RPE_EM\data_code\DD_estimation.dta' replace;
run;


