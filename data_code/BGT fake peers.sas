
/* get peers with BGT approach on SAS studio */
libname my '/home/sfu/denizsfu';
libname comp '/wrds/comp/sasdata/nam';
libname crsp '/wrds/crsp/sasdata/a_stock';
*libname link '/wrds/crsp/sasdata/a_ccm';
* get cik from funda for crsp ret ;
data funda; set comp.funda; 
   where fyr>0 and at>0 and consol='C' and indfmt='INDL' and datafmt='STD' and popsrc='D'
and cik ^= ""; 
   cyear=year(datadate);    
   keep gvkey cyear fyear fyr cik datadate; 
run; 

proc sql;
   create table comp_crsp	
   as select a.*, c.permno, c.date, c.ret,  int(hsiccd/100) as sic2
   from funda as a,
		my.CCMXPF_LNKHIST as b,		
		crsp.dsf (where=( month(date)=12)) as c
	where a.gvkey=b.gvkey and linkprim in ('P','C') and LINKTYPE in ("LU", "LC", "LN", "LS") and
	(c.date >= b.linkdt or b.LINKDT = .B) and (c.date <= b.linkenddt or b.LINKENDDT = .E)
   and b.lpermno=c.permno and a.cyear = year(c.date) ;
quit;

* get ret and sic2 for RPE firms;
proc sql;
create table rpe as select unique cik, fycompustat
from my.relpeer 
group by cik, fycompustat
order by cik, fycompustat;
quit;

proc sql;
create table rpe as select a.cik, a.fycompustat, cyear, fyr
from rpe as a left join funda as b
on a.cik = b.cik and a.fycompustat = b.fyear
order by cik, fycompustat;

data rpe; set rpe; 
cym = intnx('month', mdy(fyr,1,cyear), 0,'end');
if missing(cym) then cym = intnx('month', mdy(12,1,fycompustat), 0,'end');*assuming fyr ends in dec if missing;
format cym MMDDYY10.; 
run;

* ret are lagged by 3 months to avoid look-ahead bias, following BGT;
proc sql;
create table rpe_ret as select a.*, b.date, b.ret, b.sic2
from rpe as a left join comp_crsp as b
on a.cik = b.cik and intnx('month',cym, -3,'same') >= b.date and b.date > intnx('year',intnx('month',cym, -3,'same'), -6,'same')
order by cik, fycompustat, date;
quit;

* get potentil peers in the same SIC2 and their ret in the past 6 years;
proc sql;
create table rpe_fakep as select a.*, b.cik as cik_fakep, b.ret as ret_fakep 
from rpe_ret as a left join comp_crsp as b
on a.sic2 = b.sic2 and a.date = b.date
order by cik,  cik_fakep, fycompustat, date;
quit;

proc sql;
create table rpe_fakep as select *, count(*) as n from rpe_fakep
where ret ~=. and ret_fakep ~=.
group by cik, fycompustat, cik_fakep;
quit;
proc summary data=rpe_fakep; var n; output out=temp;run;
proc print data=temp;

* compute cor;
proc corr data=rpe_fakep(where=(n>100)) OUTP = my.corr;
by cik fycompustat cik_fakep ;
var ret ret_fakep;
run; 

* get corr;
data corr; set my.corr; keep if _type_ ="CORR"; drop _type_  _name_; run;
proc sort data=corr2; by cik fycompustat cik_fakep; quit;
data corr2; set corr2; if mod(_n_,2) eq 0; obs = _n_; run; /*get corr*/

data corr2; set corr2; rename ret=cor; if cik=cik_fakep then delete; run; /*drop cor bw cik and themselves*/
data corr2; set corr2; drop obs ret_fakep; run;

* remove actual peers;
proc sql;
create table corr3 as select a.*, b.peercik from corr2 as a left join my.relpeer as b
on a.cik = b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat, cik_fakep, peercik;
quit;

data corr3; set corr3; if cik_fakep = peercik then delete; run;

data corr3; set corr3; drop peercik; run;
proc sort data=corr3 nodupkey; by cik fycompustat cik_fakep; quit;

* count nb of fake peers per RPE firm;
proc sql; create table corr4 as select *,count(*) as n_fakep from corr3 
group by cik, fycompustat;
quit;

data corr4; set corr4; if cor=. then delete; run;
proc freq data=corr4; table n_fakep; run;
proc means data=corr4; var cor; quit;

data my.corr; set corr4; run;

/****** 1. select peers in the portfolio with highest cor with RPE firms. Nb of peers can differ from nb of actual peers; ***/

proc rank data=my.corr out=temp descending;
by cik fycompustat;
var cor;
ranks n_rank;
run;

* form 50 portfolios with 1-50 firms and compute cor;
%macro t;
%do n = 1 %to 50;
data P&n; set temp; *create portfolio n containing n firms with highest cor;
	if (n_rank > &n) then delete; 
run;

proc sql; * get RPE firm ret;
create table pret&n as select a.*, b.date, b.ret
from P&n as a left join comp_crsp as b
on a.cik = b.cik and b.fyear < a.fycompustat and b.fyear>=a.fycompustat-6
order by cik, fycompustat, date, cik_fakep;
quit;

proc sql; * get fake peer ret;
create table pret&n as select a.*,  b.ret as peerret
from pret&n as a left join comp_crsp as b
on a.cik_fakep = b.cik and a.date=b.date
order by cik, fycompustat, date, cik_fakep;
quit;

* compute portfolio ret;
proc sql;
create table pret&n as select unique cik, fycompustat, date, ret, mean(peerret) as pret from pret&n
group by cik, fycompustat, date;
quit;

proc corr data=pret&n OUTP = cor&n;
by cik fycompustat ;
var ret pret;
run; 
data cor&n; set cor&n; if _type_ ="CORR"; drop _type_  _name_; run;
proc sort data=cor&n; by cik fycompustat; quit;
data cor&n; set cor&n; if mod(_n_,2) eq 0; obs = _n_; rename ret=cor&n; run; /*get corr*/
data cor&n; set cor&n; keep cik fycompustat cor&n; run; 

%end;
%mend t;

%t;

* combine portfolios;
data tempcor; set cor1; run;
%macro choose_p;
%do n = 2 %to 50;
proc sql; 
create table tempcor as select * from tempcor as a full join cor&n as b
on a.cik=b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat;
quit;
%end;
%mend choose_p;

%choose_p;

data my.temp; set tempcor; run;

data tempcor; set my.temp; *determine n with hightes cor with RPE firm;
array values cor1-cor50;
largest = max(of values[*]);
index    = whichn(largest, of values[*]);
run;

proc sql;
create table BGTpeer as select a.index, b.*
from tempcor as a right join temp as b
on a.cik = b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat, cor desc;
quit;

data BGTpeer; set BGTpeer; if n_rank <= index; rename index = n_selectedpeers; run; *BGT peer list;

data my.BGTpeers; set BGTpeer; run;

/*** Require peers having dam and then choose peers. This results only slightly more observations but does not make results better ***/
*Require peers having DAM and get rank by cik fycompustat cor;
proc sql;
create table fakep2 as select a.*,b.dcajones1991_w
from my.corr as a inner join my.accruals as b
on a.cik_fakep = b.cik and a.fycompustat = b.fyear
order by cik, fycompustat;
quit;

data fakep2; set fakep2; if dcajones1991_w=. then delete; run;

proc rank data=fakep2 out=temp descending;
by cik fycompustat;
var cor;
ranks n_rank;
run;

* get cor bw focal firms and 50 portfolios using macro;
%t;

* choose portfolio;
data tempcor; set cor1; run;
%choose_p;

data my.temp; set tempcor; run;

data tempcor; set my.temp; *determine n with hightes cor with RPE firm;
array values cor1-cor50;
largest = max(of values[*]);
index    = whichn(largest, of values[*]);
run;

proc sql;
create table BGTpeer as select a.index, b.*
from tempcor as a right join temp as b
on a.cik = b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat, cor desc;
quit;

data BGTpeer; set BGTpeer; if n_rank <= index; rename index = n_firmsinportfolio; run; *BGT peer list;

data my.BGTpeers2; set BGTpeer; run;


******* 3. Select same nb of peers as actual peers;
* get nb of peers;
proc sql; create table nb_peers as select unique cik, fycompustat, count(*) as n_peers 
from my.relpeer 
group by cik, fycompustat
order by cik, fycompustat;
quit;

* merge nb of peers with cor;
proc sql;
create table fakep as select a.*, b.n_peers 
from my.corr as a left join nb_peers as b
on a.cik=b.cik and a.fycompustat = b.fycompustat
order by cik, fycompustat, cor desc; 
quit;

data temp; set fakep; if n_peers > n_fakep; run;/*there are firms with insufficient fake peers*/

* rank fake peers with cor;
proc rank data=fakep out=n_rank descending;
by cik fycompustat;
var cor;
ranks n_rank;
run;

data temp; set n_rank; 
if (n_rank <= n_peers) | (n_peers > n_fakep);
run;

data my.BGTpeers; set temp; keep cik fycompustat cik_fakep cor n_rank; run;

*Require peers having DAM;
proc sql;
create table fakep2 as select a.*,b.dcajones1991_w
from fakep as a inner join my.accruals as b
on a.cik_fakep = b.cik and a.fycompustat = b.fyear
order by cik, fycompustat;
quit;

data fakep2; set fakep2; if dcajones1991_w=. then delete; run;

* rank fake peers with cor;
proc rank data=fakep2 out=n_rank descending;
by cik fycompustat;
var cor;
ranks n_rank;
run;

data temp; set n_rank; 
if (n_rank <= n_peers) | (n_peers > n_fakep);
run;

data my.BGTpeers; set temp; keep cik fycompustat cik_fakep cor n_rank; run;










/* get DAM for BGT peers on local computer */
libname my 'F:\Research\WB\RPE_EM\data_code';

proc export data=my.BGTpeers2 outfile='F:\Research\WB\RPE_EM\data_code\BGTpeers2.dta' replace;run;



