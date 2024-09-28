/******* This file identifies the peers that are dropped in the last period
and computes the number of peers each RPE firm drops every year
********/

libname inclab 'F:\Data\Incentivelab\Original_Data';
libname my 'F:\Research\WB\RPE_EM\data_code';

* get peers;
* get fyear from grant_fvj;
proc sql;
    create table relpeer as select unique a.cik, b.fycompustat, a.peercik
	from inclab.gpbarelpeer as a left join my.grant_fvj as b
	on a.grantid = b.grantid
	where a.cik~='' and peercik ~= .
    order by cik, fycompustat;
quit;

/*
* identify dropped peers;
proc sql; create table droppedpeer as select *, max(fycompustat) as max_fycompustat
from relpeer
group by cik
order by cik, peercik, fycompustat desc;
quit;

data droppedpeer; set droppedpeer; 
d_drop = 1;
if cik ~= lag(cik) then d_drop = 0;
if fycompustat = max_fycompustat then d_drop = 0;*last yr RPE firm exists;
if cik = lag(cik) and fycompustat = lag(fycompustat)-1 and peercik=lag(peercik) then d_drop = 0;*repeated peers;
if fycompustat > 2005;
run;

* 34,413 RPE-peer-year obs;
* 2,226 RPE-year obs; 
* nb of peers each RPE firm drops every year;
proc sql;create table temp as select cik, fycompustat, sum(d_drop) as n_droppedpeer from droppedpeer 
group by cik, fycompustat;
quit;

* nb of RPE firms that drop peers each year;
proc sql;create table temp1 as select fycompustat, count(distinct cik) as n_RPE,sum(case when n_droppedpeer>0 then 1 else 0 end ) as n_drop
from temp 
group by fycompustat;
quit;

proc print data=temp1; run;


proc export data=droppedpeer outfile='D:\RPE\RPE_EM\data_code\droppedpeer.dta' replace;run;
*/


* update. previous codes include dropped firms over the history;
proc sql; create table droppeer as select *, 1 as d_peer 
from relpeer 
order by cik, peercik, fycompustat; 
quit;

* expand;
proc sql;
create table droppeer2 as
 select a.*, b.d_peer 
 from (select * from (select distinct cik, peercik from droppeer),(select distinct fycompustat from droppeer))     
 as a natural left join droppeer as b 
 where a.fycompustat > 2005
 order by cik, peercik, fycompustat;
quit; 

data droppeer3; set droppeer2; 
if lag(d_peer) =1 & d_peer =. then d_drop_last_yr = 1;
if lag(lag(d_peer)) =1 & lag(d_peer) =. & d_peer =. then d_drop_2yr = 1;
if lag(lag(lag(d_peer))) =1 & lag(lag(d_peer)) =. & lag(d_peer) =. & d_peer =. then d_drop_3yr = 1;
run;

* check whether a firm is dropped >=1 time;
proc sql; create table temp as select unique cik, peercik, fycompustat, d_drop_last_yr from droppeer3
where d_drop_last_yr =1; 
quit;

proc means data=temp N sum; var d_drop_last_yr; run;
* same as number of rows --> Each firm is dropped only once.

* nb of dropped peers last year for each firm;
proc sql; create table temp0 as select unique cik, fycompustat, count(*) as n_peers from relpeer
group by cik, fycompustat; quit;

proc sql; create table temp1 as select cik, fycompustat, count(*) as n_dropped_lyr from temp
group by cik, fycompustat; quit;

proc sql; create table temp2 as select a.*, n_dropped_lyr, n_dropped_lyr/n_peers as pct_dropped_lyr 
from temp0 as a left join temp1 as b
on a.cik=b.cik and a.fycompustat=b.fycompustat; quit;

data temp2; set temp2; if pct_dropped_lyr=. then pct_dropped_lyr=0; run;

proc means data=temp2; var pct_dropped_lyr n_dropped_lyr n_peers; run;
proc means data=temp2(where=(pct_dropped_lyr~=0)); var pct_dropped_lyr ; run;


proc export data=temp outfile='F:\Research\WB\RPE_EM\data_code\droppedpeer_last_yr.dta' replace;run;



data ttepm; set temp; if cik="0000216228" & fycompustat=2012; run;

