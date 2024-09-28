/*************************************************************************
Title:   Compute Earnings Management Variables
Author:  Adam Yore
Date:    08/10/2011
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
/* END WORKSPACE CLEAN AND SETTINGS */;
 
 
 
/*************************************************************************
BEGIN ASSEMBLE ESSENTIAL COMPUSTAT VARIABLES:
*************************************************************************/;
data EarningsManagement; set em.funda;
where INDFMT = 'INDL' AND DATAFMT = 'STD' AND POPSRC = 'D' AND CONSOL = 'C';
CYEAR = YEAR(DATADATE);
KEEP GVKEY CYEAR FYEAR SIC SICH ACT AT CHE DLC DP LCT PPENT PPEGT RECT RECTR SALE;
run;
data EarningsManagement; set EarningsManagement;
if MISSING(SIC) then SIC = SICH;
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
LABEL Jones1991NumFirms = 'Jones (1991) Model: Number of Firms in Estimation'
	Jones1991NumFirmsLT10 = 'Jones (1991) Model: Less than 10 Firms in Estimation'
	Jones1991ATParm = 'Jones (1991) Model: Inverse of Assets Parameter'
	Jones1991SALEParm = 'Jones (1991) Model: Chg Sales Parameter'
	Jones1991PPEParm = 'Jones (1991) Model: PP&E Parameter';
run;
data Jones1991Estimation; set Jones1991Estimation;
KEEP CYEAR SIC2 
Jones1991NumFirms Jones1991NumFirmsLT10 Jones1991ATParm
Jones1991SALEParm Jones1991PPEParm;
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
LABEL Jones1991Intercept = 'Jones (1991) Model w/ Intercept: Intercept Parameter'
	Jones1991IntATParm = 'Jones (1991) Model w/ Intercept: Inverse of Assets Parameter'
	Jones1991IntSALEParm = 'Jones (1991) Model w/ Intercept: Chg Sales Parameter'
	Jones1991IntPPEParm = 'Jones (1991) Model w/ Intercept: PP&E Parameter';
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
    ModJones1991ATParm      = .;
    ModJones1991SALERECParm = .;
    ModJones1991PPEParm     = .;
end;
ModJones1991NumFirmsLT10 = 0;
if ModJones1991NumFirms < 10 then ModJones1991NumFirmsLT10 = 1;
LABEL ModJones1991NumFirms = 'Modified Jones (1991) Model: Number of Firms in Estimation'
	ModJones1991NumFirmsLT10 = 'Modified Jones (1991) Model: Less than 10 Firms in Estimation'
	ModJones1991ATParm = 'Modified Jones (1991) Model: Inverse of Assets Parameter'
	ModJones1991SALERECParm = 'Modified Jones (1991) Model: Chg Sales less Chg Rec Parameter'
	ModJones1991PPEParm = 'Modified Jones (1991) Model: PP&E Parameter';
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
LABEL ModJones1991Intercept = 'Modified Jones (1991) Model w/ Intercept: Intercept Parameter'
	ModJones1991IntATParm = 'Modified Jones (1991) Model w/ Intercept: Inverse of Assets Parameter'
	ModJones1991IntSALERECParm = 'Modified Jones (1991) Model w/ Intercept: Chg Sales less Chg Rec Parameter'
	ModJones1991IntPPEParm = 'Modified Jones (1991) Model w/ Intercept: PP&E Parameter';
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
b.Jones1991NumFirms, b.Jones1991NumFirmsLT10, b.Jones1991ATParm, 
b.Jones1991SALEParm, b.Jones1991PPEParm
from EarningsManagementEstimations as a LEFT JOIN Jones1991Estimation as b
on a.CYEAR = b.CYEAR and 
	a.SIC2 = b.SIC2;
quit;
proc sql;
create table EarningsManagementEstimations as
select a.*, 
b.Jones1991Intercept, b.Jones1991IntATParm, 
b.Jones1991IntSALEParm, b.Jones1991IntPPEParm
from EarningsManagementEstimations as a LEFT JOIN Jones1991EstimationInt as b
on a.CYEAR = b.CYEAR and 
	a.SIC2 = b.SIC2;
quit;
proc sql;
create table EarningsManagementEstimations as
select a.*, 
b.ModJones1991NumFirms, b.ModJones1991NumFirmsLT10, b.ModJones1991ATParm, 
b.ModJones1991SALERECParm, b.ModJones1991PPEParm
from EarningsManagementEstimations as a LEFT JOIN ModJones1991Estimation as b
on a.CYEAR = b.CYEAR and 
	a.SIC2 = b.SIC2;
quit;
proc sql;
create table EarningsManagementEstimations as
select a.*, 
b.ModJones1991Intercept, b.ModJones1991IntATParm, 
b.ModJones1991IntSALERECParm, b.ModJones1991IntPPEParm
from EarningsManagementEstimations as a LEFT JOIN ModJones1991EstimationInt as b
on a.CYEAR = b.CYEAR and 
	a.SIC2 = b.SIC2;
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

LABEL CAdTAtm1DechowEtAl = 'Total Current Accruals - Dechow, Sloan, and Sweeney (1995)'
	TCAJones1991 = 'Total Current Accruals - Jones (1991) Model'
	NDCAJones1991 = 'Nondiscretionary Current Accruals - Jones (1991) Model'
	NDCAJones1991Int = 'Nondiscretionary Current Accruals - Jones (1991) Model w/ Intercept'
	DCAJones1991 = 'Discretionary Current Accruals - Jones (1991) Model'
	DCAJones1991Int = 'Discretionary Current Accruals - Jones (1991) Model w/ Intercept'
	TCAModJones1991 = 'Total Current Accruals - Modified Jones (1991) Model'
	NDCAModJones1991 = 'Nondiscretionary Current Accruals - Modified Jones (1991) Model'
	NDCAModJones1991Int = 'Nondiscretionary Current Accruals - Modified Jones (1991) Model w/ Intercept'
	DCAModJones1991 = 'Discretionary Current Accruals - Modified Jones (1991) Model'
	DCAModJones1991Int = 'Discretionary Current Accruals - Modified Jones (1991) Model w/ Intercept';

KEEP GVKEY FYEAR 
CAdTAtm1DechowEtAl 
Jones1991NumFirms Jones1991NumFirmsLT10 TCAJones1991 NDCAJones1991 NDCAJones1991Int DCAJones1991 DCAJones1991Int
ModJones1991NumFirms ModJones1991NumFirmsLT10 TCAModJones1991 NDCAModJones1991 NDCAModJones1991Int DCAModJones1991 DCAModJones1991Int;
run;
data EarningsManagementFinal;
RETAIN GVKEY FYEAR 
CAdTAtm1DechowEtAl
Jones1991NumFirms Jones1991NumFirmsLT10 TCAJones1991 NDCAJones1991 NDCAJones1991Int DCAJones1991 DCAJones1991Int
ModJones1991NumFirms ModJones1991NumFirmsLT10 TCAModJones1991 NDCAModJones1991 NDCAModJones1991Int DCAModJones1991 DCAModJones1991Int;
set EarningsManagementFinal;
run;
proc sort data = EarningsManagementFinal nodupkey;
by GVKEY FYEAR;
run;
data em.EarningsManagementFinal;
	set em.EarningsManagementFinal;
	if Jones1991NumFirmsLT10=1 then delete;
	if ModJones1991NumFirmsLT10=1 then delete;
run;
/* END IMPORT ESTIMATIONS AND COMPUTE DISCRETIONARY ACCRUALS */;

*Export and winsorize in stat;
proc export data=em.EarningsManagementFinal outfile='C:\Users\Shaun\dropbox\Xiao&Celim\RPE&EM\EM measures\jones_wrds.dta' replace;
run;
*Read winsorized stata file;
proc import out=em.EarningsManagementFinal datafile='C:\Users\Shaun\dropbox\Xiao&Celim\RPE&EM\EM measures\jones_wrds.dta'
	dbms=dta replace;
run;
*Rename winsorized variables;
data em.EarningsManagementFinal;
	set em.EarningsManagementFinal;
	drop cadtatm1dechowetal
		tcajones1991 ndcajones1991 ndcajones1991int dcajones1991 dcajones1991int
		tcamodjones1991 ndcamodjones1991 ndcamodjones1991int dcamodjones1991 dcamodjones1991int;
run;

data em.EarningsManagementFinal;
	set em.EarningsManagementFinal;
	rename
	wcadtatm1dechowetal=cadtatm1dechowetal
	wtcajones1991=tcajones1991
	wndcajones1991=ndcajones1991
	wndcajones1991int=ndcajones1991int
	wdcajones1991=dcajones1991
	wdcajones1991int=dcajones1991int
	wtcamodjones1991=tcamodjones1991
	wndcamodjones1991=ndcamodjones1991
	wndcamodjones1991int=ndcamodjones1991int
	wdcamodjones1991=dcamodjones1991
	wdcamodjones1991int=dcamodjones1991int;
run;

data em.EarningsManagementFinal;
	set em.EarningsManagementFinal;
LABEL CAdTAtm1DechowEtAl = 'Total Current Accruals - Dechow, Sloan, and Sweeney (1995)'
	TCAJones1991 = 'Total Current Accruals - Jones (1991) Model'
	NDCAJones1991 = 'Nondiscretionary Current Accruals - Jones (1991) Model'
	NDCAJones1991Int = 'Nondiscretionary Current Accruals - Jones (1991) Model w/ Intercept'
	DCAJones1991 = 'Discretionary Current Accruals - Jones (1991) Model'
	DCAJones1991Int = 'Discretionary Current Accruals - Jones (1991) Model w/ Intercept'
	TCAModJones1991 = 'Total Current Accruals - Modified Jones (1991) Model'
	NDCAModJones1991 = 'Nondiscretionary Current Accruals - Modified Jones (1991) Model'
	NDCAModJones1991Int = 'Nondiscretionary Current Accruals - Modified Jones (1991) Model w/ Intercept'
	DCAModJones1991 = 'Discretionary Current Accruals - Modified Jones (1991) Model'
	DCAModJones1991Int = 'Discretionary Current Accruals - Modified Jones (1991) Model w/ Intercept';
	drop wjones1991numfirms wjones1991numfirmslt10 wmodjones1991numfirms wmodjones1991numfirmslt10;
run;

/*************************************************************************
BEGIN ANALYZE FINAL PANEL DATASET:
*************************************************************************/;
Proc Tabulate data = em.EarningsManagementFinal Format = 7.3;
Title "Earnings Management Descriptive Statistics";
Var CAdTAtm1DechowEtAl 
	TCAJones1991	NDCAJones1991	NDCAJones1991Int
	DCAJones1991	DCAJones1991Int
	TCAModJones1991	NDCAModJones1991	NDCAModJones1991Int 
	DCAModJones1991	DCAModJones1991Int;
Tables CAdTAtm1DechowEtAl 
	TCAJones1991	NDCAJones1991	NDCAJones1991Int
	DCAJones1991	DCAJones1991Int
	TCAModJones1991	NDCAModJones1991 NDCAModJones1991Int
	DCAModJones1991	DCAModJones1991Int,
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
quit;
/* END ANALYZE FINAL PANEL DATASET */;
 
 
/****************************************************************************
                  END OF COMPUTE EARNINGS MANAGEMENT VARIABLES
****************************************************************************/;
