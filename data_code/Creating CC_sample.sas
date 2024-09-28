/*
The baseline dataset is "SEG_CUSTOMER" under /wrds/comp/sasdata/seghist .
It's a compustat dataset, so it has gvkey only. I start by adding the CCM permno (lpermno) to the dataset.
The CCM link file "CCMXPF_LINKTABLE" is under /wrds/crsp/sasdata/a_ccm .

As a result, CC-related variables will be saved at "s_c.segcus_sy8.";
s_c.segcus_sy8 is later merged on the main dataset in the code file "CC - Main".
*/

data CCMXPF_LINKTABLE; set raw.CCMXPF_LINKTABLE; run;
proc sort data=CCMXPF_LINKTABLE out=lnk; where LINKTYPE in ("LU", "LC", "LD", "LF", "LN", "LO", "LS", "LX");   by GVKEY LINKDT;
run;
proc sql;
  create table raw.ccm_segcus as select lnk.lpermno, a.gvkey, a.cnms, a.salecs, a.datadate
  from lnk, raw.seg_customer as a 
  where lnk.GVKEY = a.GVKEY and (lnk.LINKDT <= a.DATADATE or lnk.LINKDT = .B) and (a.DATADATE <= lnk.LINKENDDT or lnk.LINKENDDT = .E);
quit;

* Merge w/ supplier firm total sales (FUNDA) to calculate CC;
proc sql; create table segcus as select a.*, b.revt
from raw.ccm_segcus as a left join raw.funda_ccm as b
on a.lpermno = b.lpermno and a.datadate = b.datadate;
quit;

data segcus; set segcus; 
salecs_shr = salecs / revt;
salecs_shr_sq = salecs_shr * salecs_shr; 

if salecs < 0 then delete; if revt < 0 then delete; * DELETE negative salecs & revt;
run;

* Calculate sum(shares) and delete data w/ sum(shares) > 1 ;
proc sort data = segcus; by lpermno datadate; run;
proc means noprint data = segcus sum; by lpermno datadate; var salecs_shr;
output out = temp (drop=_type_ _freq_) sum(salecs_shr) = TSDEP; run; * Refer to the definition of TSDEP in Patatoukas (2012);
proc sort data = temp; by lpermno datadate; run;
data segcus; merge segcus temp; by lpermno datadate; if salecs=. then delete;
if TSDEP > 1 then delete; * it shouldn't exceed 1;
run;

* Create CC;
proc sort data = segcus; by lpermno datadate; run;
proc means noprint data = segcus n sum; by lpermno datadate; var salecs_shr_sq;
output out = temp (drop=_type_ _freq_) n(salecs_shr_sq) = NCUS  sum(salecs_shr_sq) = cc; run; * NCUS is created;

proc sort data = temp; by lpermno datadate; run;
data segcus; merge segcus temp; by lpermno datadate; if salecs=. then delete;
keep lpermno datadate cc NCUS cnms salecs_shr TSDEP;
run;
data segcus; set segcus;
SDEP = TSDEP / NCUS; * sales share per major customer as in Patatoukas (2012);
run;


* Use sort nodupkey to make the data at supplier-year level and ;
* Create chg_CC (segcus_SY8);
data segcus_sy8; set segcus; run; * just the dataset name change;
proc sort data = segcus_sy8 nodupkey; by lpermno datadate; run;

* Create l_cc and chg_cc;
proc sort data = segcus_sy8; by lpermno datadate; run;
data segcus_sy8; set segcus_sy8;
l_lpermno = lag(lpermno); l_cc = lag(cc);
if l_lpermno ^= lpermno then l_cc = .; if year(datadate) ^= year(lag(datadate)) + 1 then l_cc = .;
chg_cc = cc - l_cc; 
drop l_lpermno;
run;

* Add customer characteristics;
* To get customer characteristics, you have to utilize Lauren Cohen's supplier-customer matching data.
* The codes are in the code file "Cohen CC", and the dataset "cuschar_cohen" contains the customer characteristics data;
proc sql; create table segcus_sy8 as select a.*, b.*
from segcus_sy8 as a left join s_c.cuschar_cohen as b
on a.lpermno = b.permno and year(a.datadate) = b.srcyr and month(a.datadate) = b.srcfyr;
quit;
data segcus_sy8; set segcus_sy8; drop permno srcyr srcfyr; run;

data s_c.segcus_sy8; set segcus_sy8; run;
* supplier firm-year CC data w/ customer char. saved as "s_c.segcus_sy8";
