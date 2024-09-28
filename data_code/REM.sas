libname my '/home/sfu/denizsfu';
libname comp '/wrds/comp/sasdata/nam';
libname crsp '/wrds/crsp/sasdata/a_stock';

data rem; set comp.funda;
where INDFMT = 'INDL' AND DATAFMT = 'STD' AND POPSRC = 'D' AND CONSOL = 'C';
CYEAR = YEAR(DATADATE);
KEEP GVKEY CIK CYEAR FYEAR SICH AT XAD RDIP XSGA SALE COGS INVCH;
run;

proc sort data = rem nodupkey;
by GVKEY FYEAR;
run;

* Create lags;
data rem; set rem;
GVKEY_l  = lag(GVKEY);
FYEAR_l  = lag(FYEAR);
AT_l     = lag(AT);
SICH_l   = lag(SICH);
AT_l     = lag(AT);
SALE_l   = lag(SALE);
if GVKEY ne GVKEY_l OR FYEAR ne (FYEAR_l+1) then do;
AT_l     = .;
SICH_l   = .;
AT_l     = .;
SALE_l   = .;
end;
run; 

data rem; set rem;
DiscExp = (XAD + RDIP + XSGA)/AT_l;
Sales = Sale / AT_l;
Prod = (COGS + INVCH) / AT_l;
Salesgr = (Sale - Sale_l) / AT_l;
DiscExp_l = lag(DiscExp);
Prod_l = lag(Prod);
Salesgr_l = lag(Salesgr);
if GVKEY ne GVKEY_l OR FYEAR ne (FYEAR_l+1) then do;
DiscExp_l = .;
Prod_l    = .;
Salesgr_l = .;
end;
run; 

data rem; set rem; drop GVKEY_l FYEAR_l; run; 

PROC EXPORT DATA= rem FILE="/home/sfu/denizsfu/rem.dta"; quit;
