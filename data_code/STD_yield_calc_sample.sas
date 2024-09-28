



************************************************************;
* This code computes monthly rolling std deviation and 
* annual div yield from CRSP daily file
* For the code to run, first the daily file must be 
* downloaded with RET and RETX variables
* Nov 16, 2017
************************************************************;



data crsp;
	set "C:\Users\danginer\Downloads\crsp_daily";
run;

data crsp;
	set crsp;
	if ret= . then ccount = 0; else ccount = 1; 
	rdiv = ret-retx;
run;

data crsp;
	set crsp;
	drop retx;
run;

proc sql;
	create table "D:\Dropbox\RPE_EM\Codes and Data\div_yield"
	as select distinct permno, year(date) as year, exp(sum(log(1+rdiv)))-1 as divy 
	from crsp
	group by permno, year(date);
run;

proc sort data = crsp; by permno date; run;
proc expand data = crsp OUT = crsp; 
	by permno;
	id date;
 	convert ret=std_ret / TRANSFORMOUT=(movstd 756 TRIMLEFT 252);
 	convert ccount=tcount / TRANSFORMOUT=(movsum 756 TRIMLEFT 252);
run;

data crsp2; set crsp;
mt =month(date);
yr =year(date);
drop ccount rdiv ret;
run;

proc sort data=crsp2;
by permno yr mt date;
run;

*keep the last trading day of a month;
data "D:\Dropbox\RPE_EM\Codes and Data\monthly_std"; 
set crsp2;
by permno yr mt date;
if last.mt;
run;

data "D:\Dropbox\RPE_EM\Codes and Data\monthly_std"; 
set "D:\Dropbox\RPE_EM\Codes and Data\monthly_std";
std_ret_ann = std_ret*sqrt(252);
run;



