libname my 'F:\Research\WB\RPE_EM\data_code';

/* change CIK --> peerCIK, peerCIK -> peerpeerCIK */
data peerlist; set my.peerlist; keep CIK peerCIK fyCompustat; run;

data peerlist; set peerlist; peerCIK_temp = input( cik, best.); peerpeerCIK = input( peercik, best.); run;

data peerlist; set peerlist; drop cik peercik; rename peerCIK_temp = peerCIK; run;

/* Find peers' peers */
proc sql;
create table peerpeerlist as select a.*, b.peerpeercik 
from my.peerlist as a left join peerlist as b 
on a.peercik = b.peercik and a.fycompustat = b.fycompustat; 
quit; 

* drop missing peerpeercik and dupliates;
data peerpeerlist2; set peerpeerlist; keep cik  fycompustat peerpeercik; if peerpeercik ~=.; run; 
proc sort data=peerpeerlist2 nodupkeys; by cik fycompustat peerpeercik; run;

* count nb of peers' peers for each RPE firm;
proc sql;
create table temp as select cik, fycompustat, count(peerpeercik) as n_peerpeer
from peerpeerlist2
group by cik, fycompustat;
quit;

** compute peers' peers discretionary accruals; **
* get peers' peers' gvkey from funda;
data funda; set comp.funda; 
    cik2= input(cik, Best.);
	keep fyear gvkey cik cik2 tic conm; 
run;

proc sql; 
    create table peerpeerlist2 as select a.*, b.gvkey as gvkeypeerpeer
	from peerpeerlist2 as a left join funda as b
	on a.peerpeercik=b.cik2 and a.fycompustat=b.fyear
    order by fycompustat, cik;
quit;

* remove duplicates;
proc sort data=peerpeerlist2 nodupkeys; by _all_; run;
data my.peerpeerlist; set peerpeerlist2; run;

* compute peers' peers' DAM;
proc sql;
    create table peerpeerem as select a.*, CAdTAtm1DechowEtAl_w, DCAJones1991_w,DCAJones1991int_w, DCAModJones1991_w, DCAModJones1991int_w
	from peerpeerlist2 as a left join my.Accruals as b
	on a.gvkeypeerpeer = b.gvkey and a.fycompustat = b.fyear
	order by cik, fycompustat, peerpeercik;
quit;

proc means data = peerpeerem noprint; 
    Vars CAdTAtm1DechowEtAl_w DCAJones1991_w DCAJones1991int_w DCAModJones1991_w DCAModJones1991int_w;
    by cik fycompustat ;
	output out=peerpeerem2(drop=_type_ rename=(_freq_=N_peerpeers)) mean(CAdTAtm1DechowEtAl_w)=avg_CAdTA_peerpeer mean(DCAJones1991_w)=avg_dcaj_peerpeer mean(DCAJones1991int_w) = avg_dcajint_peerpeer mean(dcamodjones1991_w)=avg_dcamj_peerpeer mean(dcamodjones1991int_w)=avg_dcamjint_peerpeer
    median(CAdTAtm1DechowEtAl_w)=med_CAdTA_peerpeer median(DCAJones1991_w)=med_dcaj_peerpeer median(DCAJones1991int_w) = med_dcajint_peerpeer median(dcamodjones1991_w)=med_dcamj_peerpeer median(dcamodjones1991int_w)=med_dcamjint_peerpeer;
run;

proc export data=peerpeerem2 outfile='F:\Research\WB\RPE_EM\data_code\peerpeerem.dta' replace;run;

