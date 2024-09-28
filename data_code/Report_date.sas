libname EM "E:\Research\WB\RPE_EM\data_code";
libname comp "E:/Data/CompNA";

/* Obtain report date of annual report from quarterly reports */
data compu_q; set "E:/Data/CompNA/fundq";
keep gvkey cik datadate rdq fyearq /*fyr*/ ; 
rename fyearq = fyCompustat; 
if fqtr=4; run;

* drop complete duplicates;
proc sort data=compu_q out=rd nodup;
by gvkey datadate rdq;
run;

/* check def of fyearq 
data rd2; set rd;
fyCompustat = year(datadate);
if fyr <6 then fyCompustat=fyCompustat-1;
run;

data temp; set rd2; if fycompustat ~= fyearq; run;
*/

/* check duplicates at firm-date level;
proc sql;create table rd as select *, count(*) as ObservationCount from rd where rdq ~=.
group by gvkey, datadate
order by gvkey, datadate;
quit; 

proc freq data=rd;
    tables ObservationCount / nocum nocol;
run;

data RD; set rd; drop ObservationCount; run;
*/


/* merge with RPE data */
* get RD of focal firms;
proc sql; create table Relpeer_RD as select 
a.*, b.rdq as rd from EM.Relpeer as a 
left join RD as b 
on a.cik = b.cik and a.fycompustat = b.fycompustat;
quit;

* get rd for peer firms;
proc sql; create table Relpeer_RD as select 
a.*, b.rdq as peer_rd from Relpeer_RD as a 
left join RD as b 
on a.peercik = b.cik and a.fycompustat = b.fycompustat;
quit;

data Relpeer_RD; set Relpeer_RD; label peer_rd = "Report Date of Peers"; run;

data EM.Relpeer_RD; set Relpeer_RD; run;

proc sql; create table Relpeer_RD_pct as select cik, fycompustat,  (sum(case when rd >= peer_rd then 1 else 0 end)) as rd_late, count(*) as nb_peers, calculated rd_late/ calculated nb_peers as rd_late_pct
from EM.Relpeer_RD
group by cik, fycompustat
order by cik, fycompustat;
quit;

proc export data=Relpeer_RD_pct outfile='E:\Research\WB\RPE_EM\data_code\Relpeer_RD_pct.dta' replace;run;


proc univariate data=Relpeer_RD_pct;
  var rd_late_pct;
  histogram / normal kernel;
run;

ods listing gpath='E:\Research\WB\RPE_EM';
ods graphics / imagename="RD_late_pct_HignBin" imagefmt=png;
proc sgplot data=Relpeer_RD_pct;
histogram rd_late_pct / binwidth=0.1 binstart=0 showbins  /* scale = count */;  /* center first bin at 0 */
density  rd_late_pct;
*xaxis values=(0 to 1 by .1);
xaxis label="Percentage of peers reporting later than target firms";
run;


/* number of days */
proc sql; create table Relpeer_RD_days as select *, (peer_rd -rd)/5 as rd_days_late
from EM.Relpeer_RD
order by cik, fycompustat;
quit;

proc freq data=Relpeer_RD_days;
tables rd_days_late;
run;

ods listing gpath='E:/Research/WB/RPE_EM/';
ods graphics / imagename="RD_days_late" imagefmt=png;
proc sgplot data=Relpeer_RD_days;
histogram rd_days_late / showbins  /* scale = count */;  /* center first bin at 0 */
density  rd_days_late;
xaxis label="Days of peers reporting later than target firms";
run;

/* median days of being late per focal year*/
proc sql; create table Relpeer_RD_med_days as select cik, fycompustat,  median((peer_rd -rd)/5) as rd_days_late
from Relpeer_RD
group by cik, fycompustat
order by cik, fycompustat;
quit;

proc freq data=Relpeer_RD_med_days;
tables rd_days_late;
run;

ods listing gpath='F:/Research/WB/RPE_EM/';
ods graphics / imagename="RD_med_days_late" imagefmt=png;
*ODS LISTING CLOSE; 
proc sgplot data=Relpeer_RD_med_days;
histogram rd_days_late / showbins  /* scale = count */;  /* center first bin at 0 */
density  rd_days_late;
xaxis label="Median days of peers reporting later than focal firms";
run;

/* avg days of being late per focal year*/
proc sql; create table Relpeer_RD_mean_days as select cik, fycompustat,  mean((peer_rd -rd)/5) as rd_days_late
from Relpeer_RD
group by cik, fycompustat
order by cik, fycompustat;
quit;

proc freq data=Relpeer_RD_mean_days;
tables rd_days_late;
run;

ods listing gpath='F:/Research/WB/RPE_EM/';
ods graphics / imagename="RD_mean_days_late" imagefmt=png;
*ODS LISTING CLOSE; 
proc sgplot data=Relpeer_RD_mean_days;
histogram rd_days_late / showbins  /* scale = count */;  /* center first bin at 0 */
density  rd_days_late;
xaxis label="Average days of peers reporting later than focal firms";
run;
