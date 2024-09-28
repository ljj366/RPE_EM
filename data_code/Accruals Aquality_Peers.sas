libname my 'F:\Research\WB\RPE_EM\data_code';

/* get the peer list; */
data peerlist; set my.peerlist;
keep cik fycompustat peercik gvkeypeer;
run;

proc sort data=peerlist nodupkey; by _all_; run;

* merge with horizon data;
proc sql;
create table peerhe as select a.*, b.freq, b.horizon, range, bias, error, bias_prc, error_prc
from peerlist(where=(gvkeypeer~='')) as a left join my.he as b
on a.gvkeypeer=b.gvkey and a.fycompustat = b.announce_fyr;

* aggregate to cik-year level;
proc sql;
create table peerhe2 as select cik, fycompustat, 
mean(freq>0) as freqpct, mean(horizon) as peeravghorizon, median(horizon) as peermedhorizon,
mean(range) as peeravgrange, median(range) as peermedrange, 
mean(bias) as peeravgbias, median(bias) as peermedbias, 
mean(error) as peeravgerror, median(error) as peermederror,
mean(bias_prc) as peeravgbias_prc, median(bias_prc) as peermedbias_prc, 
mean(error_prc) as peeravgerror_prc, median(error_prc) as peermederror_prc
from peerhe 
group by cik, fycompustat
order by cik, fycompustat;

/* get restatement and ICW for peers */
* make format of cik consistent;
data aq_main; set my.aq_main; cik2=input( cik, best.);run;

proc sql;
create table peerrestate as select a.*, D_restate, icw
from peerlist(where=(peercik~=.)) as a left join aq_main as b
on a.peercik=b.cik2 and a.fycompustat=b.fycompustat
order by cik, fycompustat;

* aggregate to cik-year level;
proc sql;
create table peerrestate2 as select cik, fycompustat, mean(d_restate>0) as restatepct
from peerrestate
group by cik, fycompustat
order by cik, fycompustat;

proc sql;
create table peerrestate2 as select cik, fycompustat, mean(icw='N') as icwpct
from peerrestate
where icw='Y'|icw='N' 
group by cik, fycompustat
order by cik, fycompustat;

proc means data=peerrestate2; var icwpct; run;

* merge restate with other aq variables;
proc sql;
create table peerhe as select a.*, b.icwpct, /* b.restatepct */
from peerhe2 as a left join peerrestate2 as b
on a.cik = b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat;

proc means data=peerhe n mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max; 
var freqpct peeravghorizon peermedhorizon peeravgrange peermedrange
peeravgbias peermedbias peeravgerror peermederror
peeravgbias_prc peermedbias_prc peeravgerror_prc peermederror_prc
restatepct;
run;

data my.peerhe; set peerhe; run;

* merge with variables of RPE firms;
proc sql;
create table aq_main as select a.*, 
b.freqpct, peeravghorizon, peermedhorizon, 
peeravgrange, peermedrange,
peeravgbias, peermedbias, peeravgerror, peermederror,
peeravgbias_prc, peermedbias_prc, peeravgerror_prc, peermederror_prc,
b.restatepct 
from my.aq_main as a left join my.peerhe as b
on a.cik = b.cik and a.fycompustat=b.fycompustat;

* merge main file with peer ICW pct;
proc sql;
create table aq_main as select a.*, b.icwpct 
from my.aq_main as a left join peerrestate2 as b
on a.cik = b.cik and a.fycompustat=b.fycompustat;

data my.aq_main; set aq_main; run;

/** Add DD accruals quality revised on 1/45/2024 ***/
/***** Get each firm's DD aq without PPE and sales, revised on 1/5/2024 ******/
proc sql;
create table aq_main as select a.*, b.DDdc, std_DDdc, NumFirmsrunDDdc, NumYearsforstd
from my.aq_main as a left join my.DDestimation as b
on a.gvkey=b.gvkey and a.fycompustat=b.fyear
order by gvkey, fycompustat;
quit;

** Get peers' average DD accruals quality;
proc sql;
create table peerDDdc as select a.*, b.DDdc, std_DDdc 
from peerlist(where=(gvkeypeer~='')) as a left join my.DDestimation as b
on a.gvkeypeer=b.gvkey and a.fycompustat = b.fyear
where NumYearsforstd >=2 and NumFirmsrunDDdc >= 20;
quit;

* aggregate to cik-year level;
proc sql;
create table peerDDdc2 as select cik, fycompustat, 
mean(DDdc) as peeravgDDdc, median(DDdc) as peermedDDdc, 
mean(std_DDdc) as peeravgstd_DDdc, median(std_DDdc) as peermedstd_DDdc
from peerDDdc 
group by cik, fycompustat
order by cik, fycompustat;
quit;

* merge with other vars;
proc sql;
create table aq_main2 as select a.*, 
b.peeravgDDdc, peermedDDdc, peeravgstd_DDdc, peermedstd_DDdc
from aq_main as a left join peerDDdc2 as b
on a.cik = b.cik and a.fycompustat=b.fycompustat
order by cik, fycompustat;
quit;

proc export data=aq_main2 outfile='F:\Research\WB\RPE_EM\data_code\aq_main.dta' replace;run;


data temp; set aq_main; if fyear > 2005; 
if sum(bm=., size=., roa=., evol=., rety=., lvg=., freq, horizon,d_restate, DCAJones1991_w=., DCAJones1991int_w=., DCAModJones1991_w=., DCAModJones1991int_w=.)=0;
run;

proc means data=temp n mean std P25 median P75;
    vars bm size roa evol rety lvg freq horizon d_restate dcaj dcajint dcamj dcamjint;
run;
