
libname inclab 'E:\Data\Incentivelab\Original_Data';
libname my 'E:\Research\WB\RPE_EM\data_code';

data gpbarel; set inclab.gpbarel; run;

proc freq data=gpbarel; table metricType; run;

proc sql;
    create table rel as select unique a.cik, a.fiscalyear, a.grantid, b.metrictype, b.metric, b.metricother
	from inclab.gpbagrant as a left join gpbarel as b 
	on a.grantid = b.grantid ;
quit;

data rel; set rel; if metricType ~= ""; run;

proc sql;
    create table main_w2 as select unique a.*,  b.metrictype, b.metric, b.metricother
	from my.main_w as a left join rel as b 
	on a.cik=b.cik and a.fycompustat = b.fiscalyear ;
quit;

proc export data=main_w2 outfile='E:\Research\WB\RPE_EM\data_code\main_w_metritype.dta' replace;run;

