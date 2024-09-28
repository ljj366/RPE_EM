/************** EM of peers benchmarking back ******************/
use main_w.dta if fycompustat>2005, clear
encode cik, gen(cik_stata) //convert cik from char to num //
xtset cik_stata fycompustat  //specify panel format
gen yind = fycompustat*100 + ff12

merge 1:1 cik fycompustat using em_peerback.dta 
keep if _merge == 3 
drop _merge

merge 1:1 cik fycompustat using rpe_var_1st
drop if _merge ==2
drop _merge

		
*Firm+Year 		
areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_peerback i.fycompustat, a(cik) cl(cik_stata) 
outreg2 using D:\RPE\RPE_EM\data_code\Peerback_EM_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( bm size roa rety evol lvg med_dcamj med_dcamj_peerback ) replace ctitle(Peers benchmarking back) addtext(FE, Firm+Year)
		
areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_peerrpe i.fycompustat, a(cik) cl(cik_stata) 
outreg2 using D:\RPE\RPE_EM\data_code\Peerback_EM_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( bm size roa rety evol lvg med_dcamj med_dcamj_peerrpe ) append ctitle(Peers using RPE but not benchmarking back) addtext(FE, Firm+Year)

areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_peerback med_dcamj_peerrpe i.fycompustat, a(cik) cl(cik_stata) 
outreg2 using D:\RPE\RPE_EM\data_code\Peerback_EM_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( bm size roa rety evol lvg med_dcamj med_dcamj_peerback med_dcamj_peerrpe ) append ctitle(Horse-race) addtext(FE, Firm+Year)
		
* Industry*Year FE
areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_peerback, a(yind) cl(cik_stata) 
outreg2 using D:\RPE\RPE_EM\data_code\Peerback_EM_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( bm size roa rety evol lvg med_dcamj med_dcamj_peerback ) append ctitle(Peers benchmarking back) addtext(FE, Industry*Year)
		
areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_peerrpe, a(yind) cl(cik_stata) 
outreg2 using D:\RPE\RPE_EM\data_code\Peerback_EM_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( bm size roa rety evol lvg med_dcamj med_dcamj_peerrpe ) append ctitle(Peers using RPE but not benchmarking back) addtext(FE, Industry*Year)

areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_peerback med_dcamj_peerrpe , a(yind) cl(cik_stata) 
outreg2 using D:\RPE\RPE_EM\data_code\Peerback_EM_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( bm size roa rety evol lvg med_dcamj med_dcamj_peerback med_dcamj_peerrpe ) append ctitle(Horse-race) addtext(FE, Industry*Year)
		
* Industry+Year FE
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 med_dcamj med_dcamj_peerback i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Peerback_EM_reg_med.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		drop(i.fycompustat) replace ctitle(Peers benchmarking back) addtext(FE, Industry+Year)
		
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 med_dcamj med_dcamj_peerrpe i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Peerback_EM_reg_med.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		drop(i.fycompustat) append ctitle(Peers using RPE but not benchmarking back) addtext(FE, Industry+Year)

areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 med_dcamj med_dcamj_peerback med_dcamj_peerrpe i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Peerback_EM_reg_med.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		drop(i.fycompustat) append ctitle(Horse-race) addtext(FE, Industr+Year)	
		
		
* Industry+Year FE avg
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 avg_dcamj avg_dcamj_peerback i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Peerback_EM_reg_avg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		drop(i.fycompustat) replace ctitle(Peers benchmarking back) addtext(FE, Industry+Year)
		
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 avg_dcamj avg_dcamj_peerrpe i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Peerback_EM_reg_avg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		drop(i.fycompustat) append ctitle(Peers using RPE but not benchmarking back) addtext(FE, Industry+Year)

areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 avg_dcamj avg_dcamj_peerback avg_dcamj_peerrpe i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Peerback_EM_reg_avg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		drop(i.fycompustat) append ctitle(Horse-race) addtext(FE, Industr+Year)	
		
		
		
/************** Restatement peerback*****************/
use aq_peerback.dta if fycompustat>2005, replace
use aq_peerback2.dta if fycompustat>2005, replace

gen yind = fycompustat*100 + ff12 /*logit does not work when choosing ff48*/
keep if d_rpe == 1

* create restate dummies;
gen d_peerrestate = 0
replace d_peerrestate = 1 if restatepct > 0
gen d_restate_peerback = 0
replace d_restate_peerback = 1 if restatepct_peerback > 0 & restatepct_peerback ~=.
gen d_restate_peerrpe = 0
replace d_restate_peerrpe = 1 if restatepct_peerrpe > 0 & restatepct_peerrpe~=.

bysort fycompustat: gen N=_N /*total nb of firms each year */
bysort fycompustat: egen N_restate=sum(d_restate)  /*count nb of restated firms */

set seed 0271  // 1234 works only when not controlling for industry restatement
sort fycompustat cik //must sort this first, ow firms may change order when using runiform, making the results not replicable
by fycompustat: gen r=runiform()  if d_restate==0 /*create random variable*/


* Firm + Year FE
clogit d_restate bm size roa rety evol lvg d_peerrestate d_restate_peerback i.fycompustat if d_restate==1 | (r<= N_restate/N ), group(cik) cl(cik)
outreg2 using Peerback_restate_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate d_restate_peerback) adds("pseudo R-squared", e(r2_p)) replace addtext(FE, Firm+Year) ctitle(Peers benchmarking back) 

clogit d_restate bm size roa rety evol lvg d_peerrestate d_restate_peerrpe i.fycompustat if d_restate==1 | (r<= N_restate/N ), group(cik) cl(cik)
outreg2 using Peerback_restate_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate d_restate_peerrpe) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Firm+Year) ctitle(Peers using RPE but not benchmarking back) 

clogit d_restate bm size roa rety evol lvg d_peerrestate d_restate_peerback d_restate_peerrpe i.fycompustat if d_restate==1 | (r<= N_restate/N ), group(cik) cl(cik)
outreg2 using Peerback_restate_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate d_restate_peerback d_restate_peerrpe) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Firm+Year) ctitle(Horse-race)

* Industry * Year FE
logit d_restate bm size roa rety evol lvg d_peerrestate d_restate_peerback i.yind if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using Peerback_restate_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate d_restate_peerback) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry*Year) ctitle(Peers benchmarking back) 

logit d_restate bm size roa rety evol lvg d_peerrestate d_restate_peerrpe i.yind if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using Peerback_restate_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate d_restate_peerrpe) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry*Year) ctitle(Peers using RPE but not benchmarking back)
		
logit d_restate bm size roa rety evol lvg d_peerrestate d_restate_peerback d_restate_peerrpe i.yind if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using Peerback_restate_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate d_restate_peerback d_restate_peerrpe) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry*Year) ctitle(Horse-race)

* Industry + Year FE
logit d_restate bm size roa rety evol lvg d_peerrestate d_restate_peerback i.fycompustat i.ff12 if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using Peerback_restate_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate d_restate_peerback) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry+Year) ctitle(Peers benchmarking back) 

logit d_restate bm size roa rety evol lvg d_peerrestate d_restate_peerrpe  i.fycompustat i.ff12 if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using Peerback_restate_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate d_restate_peerrpe) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry+Year) ctitle(Peers using RPE but not benchmarking back)
		
logit d_restate bm size roa rety evol lvg d_peerrestate d_restate_peerback d_restate_peerrpe i.fycompustat i.ff12 if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using Peerback_restate_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate d_restate_peerback d_restate_peerrpe) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry+Year) ctitle(Horse-race)
		