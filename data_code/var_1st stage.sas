libname compNA 'E:\Data\CompNA';
libname em 'E:\Research\WB\RPE_EM\data_code';

/*************************************************************************
BEGIN ASSEMBLE ESSENTIAL COMPUSTAT VARIABLES:
*************************************************************************/;
data EarningsManagement; set compNA.funda;
where INDFMT = 'INDL' AND DATAFMT = 'STD' AND POPSRC = 'D' AND CONSOL = 'C';
CYEAR = YEAR(DATADATE);
KEEP GVKEY CYEAR FYEAR SICH ACT AT CHE DLC DP LCT PPENT PPEGT RECT RECTR SALE cik;
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
Get controls in DA
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
 
run;
/* end controls in 1st stage */

/**********************
Limit to RPE firms
**************************************/
proc sql;
create table rpe_controls_1st as select a.cik, a.fyCompustat, b.ATtm1, ATtm1Inverse, ChgSALEdATtm1, PPEGTdATtm1, sic2 
from  em.rpe as a left join EarningsManagement as b
on a.cik=b.cik and a.fyCompustat = b.fyear
order by cik, fyCompustat;
quit;


proc export data=rpe_controls_1st outfile = 'rpe_var_1st.dta'; run;

/** save 1st stage vars for all firms, used for firms benchmarking S&P100**/
data var_1st; set EarningsManagement; keep cik fyear ATtm1 ATtm1Inverse ChgSALEdATtm1 PPEGTdATtm1 sic2; rename fyear = fycompustat; if cik^= ""; run;


proc export data=var_1st outfile = 'var_1st.dta'; run;

