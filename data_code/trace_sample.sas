
/*
data trace;
	set trace.trace;
	cusip6=substr(cusip_id,1,9);
	if year(trd_exctn_dt)=2002 and month(trd_exctn_dt)=7;
	keep cusip6 trd_exctn_dt;
run;

proc sort data=trace nodup;
	by cusip6 trd_exctn_dt;
run;

proc sort data=trace nodupkey;
	by cusip6;
run;

proc sql;
	create table temp as
	select distinct trd_rpt_efctv_dt, count(distinct cusip_id) as count
	from trace.masterfile
	group by trd_rpt_efctv_dt;
quit;

*/

proc sql;
	create table temp as
	select distinct trd_rpt_efctv_dt, count(distinct cusip_id) as N_date1
	from trace.masterfile
	group by trd_rpt_efctv_dt;
quit;

proc sql;
	create table temp1 as
	select distinct cusip_id, min(trd_exctn_dt) as firstdate
	from trace.trace
	group by cusip_id;
quit;

proc sql;
	create table temp1 as
	select distinct firstdate format MMDDYY10., count(distinct cusip_id) as N_date2
	from temp1
	group by firstdate;
quit;

proc sql;
	create table temp as
	select a.trd_rpt_efctv_dt as date, a.N_date1, b.N_date2
	from temp as a
	left join temp1 as b
	on a.trd_rpt_efctv_dt=b.firstdate;
quit;

proc export data=temp outfile="D:\Dropbox\research\trace\first date.xlsx"
			dbms=xlsx replace;
run;

***************************************************************************************************************;

proc sql;
	create table temp as
	select distinct cusip_id, min(trd_exctn_dt) as firstdate format MMDDYY10.
	from trace.trace
	group by cusip_id;
quit;

data temp;
	set temp;
	where firstdate="01Jul2002"d and cusip_id ne "";
run;

proc sql;	
	create table temp1 as
	select a.*, b.offering_amt
	from temp as a
	left join fisd.bondissues as b
	on a.cusip_id=b.complete_cusip;
quit;

data temp2;
	set temp1;
	if offering_amt<1000000 and offering_amt ne .;
run;

proc sql;
	create table temp1 as
	select a.*, b.rating_date, b.rating_type, b.rating
	from temp1 as a
	left join fisd.bondratings as b
	on a.cusip_id=b.complete_cusip
	order by a.cusip_id, b.rating_date;
quit;

*Match TRACE treatment to GVKEY;

data trace;
	set trace.masterfile;
	keep cusip_id trd_rpt_efctv_dt;
	/*trd_rpt_efctv_dt="01Jul2002"d;*/
	where cusip_id ne "";
run;

proc sort data=trace nodup;
	by cusip_id trd_rpt_efctv_dt;
run;

proc sql;
	create table temp as
	select a.*, b.permno
	from trace as a
	left join crsp.msenames as b
	on substr(a.cusip_id,1,6)=substr(b.ncusip,1,6)
	and b.NAMEDT<=a.trd_rpt_efctv_dt<=b.NAMEENDT;
quit;

data temp;
	set temp;
	if permno ne .;
	drop cusip_id;
run;

proc sort data=temp nodup;
	by permno trd_rpt_efctv_dt;
run;

proc sql;
	create table trace as
	select a.trd_rpt_efctv_dt, b.gvkey, 1 as trace
	from temp as a
	left join crsp.CCMXPF_LNKHIST as b
	on a.permno=b.lpermno
		and (b.linkdt<=a.trd_rpt_efctv_dt or b.linkdt = .B)
		and (a.trd_rpt_efctv_dt<=b.linkenddt or b.linkenddt = .E)
	where b.linktype='LU' or b.linktype='LC' or b.linktype='LS';
quit;

proc sort data=trace nodup;
	by gvkey;
run;

********************************************************************************************;

*Match earnings guidance to GVKEY;

proc sql;
	create table temp as
	select b.permno, a.prd_yr
	from trace_md.dhgdet_040915 as a
	left join ibes.ibcrsphist as b
	on a.ibes_tkr=b.TICKER
	and b.SDATE<=a.announce_date<=b.EDATE
	where b.SCORE=1;
quit;

proc sql;
	create table temp as
	select distinct permno, prd_yr, count(permno) as count
	from temp
	group by permno, prd_yr;
quit;

proc sql;
	create table temp as
	select b.gvkey, a.*
	from temp as a
	left join crsp.CCMXPF_LNKHIST as b
	on a.permno=b.lpermno
		and (year(b.linkdt)<=a.prd_yr or b.linkdt = .B)
		and (a.prd_yr<=year(b.linkenddt) or b.linkenddt = .E)
	where b.linktype='LU' or b.linktype='LC' or b.linktype='LS';
quit;

proc sort data=temp nodup;
	by gvkey permno prd_yr;
run;

proc sql;
	create table temp as
	select distinct gvkey, prd_yr as year, sum(count) as freq
	from temp
	group by gvkey, prd_yr;
quit;

proc sql;
	create table compustat as
	select a.gvkey, a.fyear as year, a.sich, a.OIBDP/a.AT as earn, log(a.AT) as size, (a.DLC+a.DLTT)/a.AT as lev, (a.AT-a.CEQ+a.PRCC_F*a.CSHO)/a.AT as mb, b.freq
	from comp.funda as a
	left join temp as b
	on a.gvkey=b.gvkey
	and a.fyear=b.year
	where a.CONSOL='C' and a.INDFMT='INDL' and a.DATAFMT='STD' and a.POPSRC='D' and a.CURCD='USD';
quit;

data compustat;
	set compustat;
	if freq=. then issue=0; else issue=1;
	if freq=. then freq=0;
	where nmiss(sich,earn,size,lev,mb)=0;
run;

**************************************************************************************************************************************************;

*Identify companies with outstanding bond on 07/01/2002 from FISD;

data temp;
	set fisd.bondissues;
	keep issuer_cusip offering_date maturity;
	where offering_date<"01Jul2002"d and maturity>"01Jul2002"d;
run;

proc sql;
	create table temp as
	select distinct issuer_cusip, min(offering_date) as firstdate format=MMDDYY10., max(maturity) as lastdate format=MMDDYY10.
	from temp
	group by issuer_cusip;
quit;

proc sql;
	create table temp as
	select a.gvkey, b.firstdate, b.lastdate
	from comp.funda as a
	left join temp as b
	on substr(a.CUSIP,1,6)=b.issuer_cusip
	where a.fyear=2002 and a.CONSOL='C' and a.INDFMT='INDL' and a.DATAFMT='STD' and a.POPSRC='D' and a.CURCD='USD';
quit;

proc sql;
	create table fisd as
	select distinct gvkey, min(firstdate) as firstdate format=MMDDYY10., max(lastdate) as lastdate format=MMDDYY10.
	from temp
	group by gvkey;
quit;

************************************************************************************************************************************************;

proc sql;
	create table temp as
	select a.*, b.trace, c.*
	from compustat as a
	left join trace as b
	on a.gvkey=b.gvkey
	left join fisd as c
	on a.gvkey=c.gvkey
	order by a.gvkey, a.year;
quit;

data reg;
	set temp;
	if trace=. then trace=0;
	if year>=2002 then after=1; else after=0;
	firstyear=year(firstdate);
	lastyear=year(lastdate);
	gvkeyn=input(gvkey,6.);
run;

data trace_md.reg;
	set reg;
run;

**************************************************************************************;

proc export outfile="X:\research\trace\data\reg.dta"
			data=trace_md.reg dbms=dta replace;
run;


**************************************************************************************;

*Quarterly version;

proc sql;
	create table temp as
	select b.permno, yyq(year(a.announce_date),qtr(a.announce_date)) as qtr format YYMMDD10.
	from trace_md.dhgdet_040915 as a
	left join ibes.ibcrsphist as b
	on a.ibes_tkr=b.TICKER
	and b.SDATE<=a.announce_date<=b.EDATE
	where b.SCORE=1;
quit;

proc sql;
	create table temp as
	select distinct permno, qtr, count(permno) as count
	from temp
	group by permno, qtr;
quit;

proc sql;
	create table temp as
	select b.gvkey, a.*
	from temp as a
	left join crsp.CCMXPF_LNKHIST as b
	on a.permno=b.lpermno
		and (b.linkdt<=a.qtr or b.linkdt = .B)
		and (a.qtr<=b.linkenddt or b.linkenddt = .E)
	where b.linktype='LU' or b.linktype='LC' or b.linktype='LS';
quit;

proc sort data=temp nodup;
	by gvkey permno qtr;
run;

proc sql;
	create table temp as
	select distinct gvkey, qtr, sum(count) as freq
	from temp
	group by gvkey, qtr;
quit;

proc sql;
	create table compustat_qtr as
	select a.gvkey, a.datadate, a.OIBDPQ/a.ATQ as earn, log(a.ATQ) as size, (a.DLCQ+a.DLTTQ)/a.ATQ as lev, (a.ATQ-a.CEQQ+a.PRCCQ*a.CSHOQ)/a.ATQ as mb, b.freq
	from comp.fundq as a
	left join temp as b
	on a.gvkey=b.gvkey
	and year(a.datadate)=year(b.qtr) and qtr(a.datadate)=qtr(b.qtr)
	where a.CONSOL='C' and a.INDFMT='INDL' and a.DATAFMT='STD' and a.POPSRC='D';
quit;

proc sql;
	create table compustat_qtr as
	select a.*, b.sich
	from compustat_qtr as a
	left join comp.funda as b
	on a.gvkey=b.gvkey
	and year(a.datadate)=year(b.datadate)
	where b.CURCD='USD';
quit;

proc sort data=compustat_qtr nodupkey;
	by gvkey datadate;
run;

data compustat_qtr;
	set compustat_qtr;
	if freq=. then issue=0; else issue=1;
	if freq=. then freq=0;
	where nmiss(sich,earn,size,lev,mb)=0;
run;

********************************************************************************;

proc sql;
	create table temp as
	select a.*, b.trace, c.*
	from compustat_qtr as a
	left join trace as b
	on a.gvkey=b.gvkey
	left join fisd as c
	on a.gvkey=c.gvkey
	order by a.gvkey, a.datadate;
quit;

data reg_qtr;
	set temp;
	if trace=. then trace=0;
	if datadate>"01Jul2002"d then after=1; else after=0;
	firstyear=year(firstdate);
	lastyear=year(lastdate);
	gvkeyn=input(gvkey,6.);
	year=year(datadate);
run;

data trace_md.reg_qtr;
	set reg_qtr;
run;


data temp;
	set reg_qtr;
	if 1998<=year<=2006 and firstyear<=1998 and lastyear>=2006;
run;

data temp;
	set temp;
	if trace=1;
run;

**************************************************************************************;

proc export outfile="X:\research\trace\data\reg_qtr.dta"
			data=trace_md.reg_qtr dbms=dta replace;
run;


