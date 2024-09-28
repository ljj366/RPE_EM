/**** This file computes the avg/median of the peers that
1) benchmark the RPE firms back and 
2) use RPE but do not benchmark back
*********/

libname inclab 'D:\RPE\RPE_EM\IncLab_data';
libname my 'D:\RPE\RPE_EM\data_code';

* get RPE list;
proc sql;
    create table relpeer as select unique a.cik, b.fycompustat, a.peercik
	from inclab.gpbarelpeer as a left join my.grant_fvj as b
	on a.grantid = b.grantid
	where a.cik~='' and peercik ~= .
    order by cik, fycompustat;
quit;

data relpeer; set relpeer; cik2 = input(cik, Best.); run;*change RPE cik to numberic to be consistent with peercik;

* get peers' peers;
proc sql;
create table peertopeer as select a.*, b.peercik as peerofpeer
from relpeer as a left join relpeer as b
on a.peercik = b.cik2 and a.fycompustat = b.fycompustat;
quit;

* create peerback and peer using RPE dummies;
data peertopeer; set peertopeer; 
d_peerback=0; 
if peerofpeer = cik2 then D_peerback=1; 
d_peerrpe = 0;
if peerofpeer ~= . & peerofpeer ~= cik2 then d_peerrpe = 1;
drop cik2;
run;

*if any peer of the peers equals RPE firm, then d_peerback=1. If peers have any peer, then it uses RPE;
proc sort data=peertopeer; by cik fycompustat peercik descending d_peerback descending d_peerrpe; run;
data peertopeer2; set peertopeer; by cik fycompustat peercik descending d_peerback descending d_peerrpe; if first.peercik; run;
data peertopeer2; set peertopeer2; drop peerofpeer; run; 
data my.peertopeer; set peertopeer2; run;

proc export data=my.peertopeer outfile="peertopeer.dta"; quit;

* compute nb of peers;
proc sql;
create table n_peers as select cik, fycompustat, count(peercik) as n_peers, sum(d_peerback) as n_peerback, sum(d_peerrpe) as n_peerrpe
from my.peertopeer
group by cik, fycompustat;
quit;

proc means data=n_peers mean median std min max;
    vars n_peers n_peerback n_peerrpe;
run;


******************** for accruals ************************;
* merge with accruals;
data accruals; set my.accruals; cik2=input(cik,Best.); run;

proc sql;
    create table peerEM as select a.*, CAdTAtm1DechowEtAl_w, DCAJones1991_w,DCAJones1991int_w, DCAModJones1991_w, DCAModJones1991int_w
	from peertopeer2 as a left join Accruals as b
	on a.peercik = b.cik2 and a.fycompustat = b.fyear
	order by cik, fycompustat, peercik;
quit;

* compute agg accruals for peers benchmarking back and peers using rpe;
proc sort data=peerem; by cik fycompustat d_peerback d_peerrpe; run;
proc means data = peerem noprint; 
    Vars CAdTAtm1DechowEtAl_w DCAJones1991_w DCAJones1991int_w DCAModJones1991_w DCAModJones1991int_w;
    by cik fycompustat d_peerback d_peerrpe;
	output out=peerem2(drop=_type_ rename=(_freq_=N_peers)) mean(CAdTAtm1DechowEtAl_w)=avg_CAdTA mean(DCAJones1991_w)=avg_dcaj mean(DCAJones1991int_w) = avg_dcajint mean(dcamodjones1991_w)=avg_dcamj mean(dcamodjones1991int_w)=avg_dcamjint
    median(CAdTAtm1DechowEtAl_w)=med_CAdTA median(DCAJones1991_w)=med_dcaj median(DCAJones1991int_w) = med_dcajint median(dcamodjones1991_w)=med_dcamj median(dcamodjones1991int_w)=med_dcamjint;
run;

data my.relpeerem_group; set peerem2; run; 

* merge with main file;
proc sql;
create table em_group as select a.*, b.avg_dcamj as avg_dcamj_peerback, b.med_dcamj as med_dcamj_peerback
from my.main_w as a left join peerem2(where=(d_peerback=1)) as b
on a.cik=b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat;
 
proc sql;
create table em_group2 as select a.*, b.avg_dcamj as avg_dcamj_peerrpe, b.med_dcamj as med_dcamj_peerrpe
from em_group as a left join peerem2(where=(d_peerrpe=1)) as b
on a.cik=b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat;

data em_group3; set em_group2; 
if avg_dcamj_peerback=. then avg_dcamj_peerback=0;
if med_dcamj_peerback=. then med_dcamj_peerback=0;
if avg_dcamj_peerrpe=. then avg_dcamj_peerrpe=0;
if med_dcamj_peerrpe=. then med_dcamj_peerrpe=0;
run;

proc export data=em_group3 outfile='D:\RPE\RPE_EM\data_code\em_peerback.dta' replace;run;



/***** Compute restetement pct for different groups ****/
* merge with accruals;
data aq_main; set my.aq_main; cik2=input(cik,Best.); run;

proc sql;
    create table peerEM as select a.*, d_restate
	from my.peertopeer as a left join aq_main as b
	on a.peercik = b.cik2 and a.fycompustat = b.fycompustat
	order by cik, fycompustat, peercik;
quit;

* compute restate pct for peers benchmarking back and peers using rpe;
proc sort data=peerem; by cik fycompustat d_peerback d_peerrpe; run;
proc means data = peerem noprint; 
    Vars d_restate;
    by cik fycompustat d_peerback d_peerrpe;
	output out=peerem2(drop=_type_ rename=(_freq_=N_peers)) mean(d_restate)=restatepct;
run;

* merge with main file;
proc sql;
create table em_group as select a.*, b.restatepct as restatepct_peerback
from aq_main as a left join peerem2(where=(d_peerback=1)) as b
on a.cik=b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat;
 
proc sql;
create table em_group2 as select a.*, b.restatepct as restatepct_peerrpe
from em_group as a left join peerem2(where=(d_peerrpe=1)) as b
on a.cik=b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat;

data em_group3; set em_group2; 
if restatepct_peerback=. then restatepct_peerback=0;
if restatepct_peerrpe=. then restatepct_peerrpe=0;
run;

proc export data=em_group3 outfile='D:\RPE\RPE_EM\data_code\aq_peerback.dta' replace;run;


* compute nb of peers doing restate for each category and restate pct for each category;
*total nb of peers doing restatement;
proc sql;
create table peerem2 as select cik, fycompustat, count(*) as n_peers, sum(d_peerback) as n_peerback, sum(d_peerrpe) as n_peerrpe,
sum(d_restate) as n_restate,sum(d_peerback*d_restate) as n_restate_peerback,sum(d_peerrpe*d_restate) as n_restate_peerrpe
from peerem 
group by cik, fycompustat;

data peerem2; set peerem2; 
peerbackpct = n_peerback/n_peers;
peerrpepct = n_peerrpe/n_peers;
restatepct_peerback = n_restate_peerback/n_restate;
restatepct_peerrpe = n_restate_peerrpe/n_restate;
if restatepct_peerback=. then restatepct_peerback=0;
if restatepct_peerrpe=. then restatepct_peerrpe=0;
run;

proc means data=peerem2 n mean median std min P5 P10 P90 P95 max;
vars peerbackpct peerrpepct restatepct_peerback restatepct_peerrpe;
run;

proc sql;
create table aq_peerback2 as select a.*, b.n_peers,b.peerbackpct, peerrpepct,restatepct_peerback,restatepct_peerrpe
from my.aq_main as a left join peerem2 as b
on a.cik=b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat;

proc export data=aq_peerback2 outfile='D:\RPE\RPE_EM\data_code\aq_peerback2.dta' replace;run;







