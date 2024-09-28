ssc install psmatch2, replace

/* Prepare data 
* compute nb of actual peers;
cd "D:\RPE\RPE_EM\data_code"
use D:\RPE\RPE_EM\data_code\PSM.dta, replace
collapse (sum) n_peers=d_actualpeer, by (cik fycompustat)
save "D:\RPE\RPE_EM\data_code\n_peers.dta",replace

use D:\RPE\RPE_EM\data_code\PSM.dta, replace

merge m:1 cik fycompustat using D:\RPE\RPE_EM\data_code\n_peers.dta
drop _merge

*drop at size bm ret_ann std_ann beta ratings ior hhi at_other size_other bm_other ret_ann_other std_ann_other beta_other ratings_other ior_other hhi_other
*drop n_corr hsiccd sic2 ff48 sp500 sp1500 splticrm hsiccd_other sic2_other ff48_other sp500_other sp1500_other splticrm_other
drop min_peersize cik_other2 cym

save "D:\RPE\RPE_EM\data_code\PSM.dta", replace

/* create lagged cor;
sort cik cik_other fycompustat 
by cik: g corr_lag = corr[_n-1] if fycompustat==fycompustat[_n-1]+1 & cik_other==cik_other[_n-1]
*/

/*** pre-examine how many cik-fyear will remian ****/
use D:\RPE\RPE_EM\data_code\PSM.dta, replace

* check nb of missing values for each variable:
*mdesc

egen nmiss = rowmiss( corr_lag sizediff_lag bmdiff_lag retdiff_lag stddiff_lag betadiff_lag ratingdiff_lag iordiff_lag hhidiff_lag same_sic2_lag same_sp500_lag same_sp1500_lag)

keep if nmiss==0 & d_actualpeer == 0

save "D:\RPE\RPE_EM\data_code\temp.dta", replace 

use D:\RPE\RPE_EM\data_code\accruals.dta, replace
gen cik_other = cik
gen fycompustat = fyear
keep cik_other fycompustat cadtatm1dechowetal_w dcajones1991_w dcajones1991int_w dcamodjones1991_w dcamodjones1991int_w

merge 1:m cik_other fycompustat using D:\RPE\RPE_EM\data_code\temp.dta /*16,503 merged */
keep if _merge == 3 

collapse (median) med_cadta_fake=cadtatm1dechowetal_w med_dcaj_fake=dcajones1991_w med_dcajint_fake=dcajones1991int_w med_dcamj_fake=dcamodjones1991_w med_dcamjint_fake=dcamodjones1991int_w ///
(mean) avg_cadta_fake=cadtatm1dechowetal_w avg_dcaj_fake=dcajones1991_w avg_dcajint_fake=dcajones1991int_w avg_dcamj_fake=dcamodjones1991_w avg_dcamjint_fake=dcamodjones1991int_w ///
, by(cik fycompustat)

save "D:\RPE\RPE_EM\data_code\temp.dta",replace

use D:\RPE\RPE_EM\data_code\main_w.dta if fycompustat>2005, replace /*1693*/
merge 1:1 cik fycompustat using D:\RPE\RPE_EM\data_code\temp.dta /*1113 merged and 580 not merged*/

**** Get accruals for peers ****
use accruals.dta, replace
gen cik_other = cik
gen fycompustat = fyear
keep cik_other fycompustat dcamodjones1991_w 

merge 1:m cik_other fycompustat using PSM.dta 
keep if _merge == 3 
drop if dcamodjones1991_w == .
rename dcamodjones1991_w dcamodjones1991_w_other
save PSM_accruals.dta, replace

*/
/**** End of pre-examinination **/
***************************************************

cd "F:\Research\WB\RPE_EM\data_code"

use PSM_accruals.dta, replace
* use PSM_accruals.dta, replace // for restatement

* sum size_other_lag if d_actualpeer == 1 //get min size of peers: .1397619
keep if size_other_lag >  .1397619 // limit size of non-selected peers 

replace hhidiff_lag = 0 if hhidiff_lag == .
replace iordiff_lag = 0 if iordiff_lag == .

* fill in missing corr with median;
*collapse (median) corr_median=corr_lag /* .3, by(cik fycompustat) not work since some loose cor with all firms */

replace corr_lag = .3 if corr_lag == . 

gen sic1_lag = int(sic2_lag/10)
gen sic1_other_lag = int(sic2_other_lag/10)
gen same_sic1_lag = 0
replace same_sic1_lag = 1 if sic1_lag == sic1_other_lag

gen abssizediff_lag = abs(sizediff_lag)
gen absbmdiff_lag = abs(bmdiff_lag) 
gen absstddiff_lag  = abs(stddiff_lag)
gen abshhidiff_lag = abs(hhidiff_lag)
gen absroadiff_lag = abs(roadiff_lag)
gen absretdiff_lag = abs(retdiff_lag)
gen absbetadiff_lag = abs(betadiff_lag)
gen absratingdiff_lag = abs(ratingdiff_lag)
gen absiordiff_lag = abs(iordiff_lag)

/***** Select peers or skip to use full sample *****/
* exclude firms missing characteristics
egen nmiss = rowmiss( corr_lag sizediff_lag bmdiff_lag retdiff_lag stddiff_lag hhidiff_lag roadiff_lag same_sic2_lag same_sp500_lag same_sp1500_lag) 
keep if nmiss == 0
* for limited variables
egen nmiss = rowmiss( corr_lag sizediff_lag  same_sic2_lag same_sp500_lag same_sp1500_lag)
keep if nmiss == 0
 
/* drop non-peers that do not have complete info for the regression; 
foreach v of var corr_lag sizediff_lag bmdiff_lag retdiff_lag stddiff_lag betadiff_lag ratingdiff_lag iordiff_lag hhidiff_lag same_sic2_lag same_sp500_lag same_sp1500_lag { 
	drop if ( missing(`v') & d_actualpeer == 0 )
}
*/

set seed 1234
bysort cik fycompustat: gen r = runiform() if nmiss==0
replace r = 2 if d_actualpeer == 1 | nmiss ~= 0
sort cik fycompustat r
bysort cik fycompustat: gen d_r = _n <= (n_peers) // or 3*n_peers if use 3:1 ratio

* 88 + 5,569 obs cannot find a match and will randomly choose actual peers or firms with incompleteinfo;
replace d_r = 0 if d_actualpeer == 1 /*actual peers cannot be included */
replace d_r = 0 if nmiss ~= 0 /*incomplete firms cannot be included */

* full sample, full var;
logit d_actualpeer corr_lag sizediff_lag bmdiff_lag retdiff_lag stddiff_lag betadiff_lag  iordiff_lag hhidiff_lag roadiff_lag same_sic1_lag same_sp500_lag same_sp1500_lag i.sic1_lag i.fycompustat 
outreg2 using reg_logit.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
	    replace ctitle(Full sample & all variables)  

* 1:1 sample, full var
logit d_actualpeer corr_lag sizediff_lag bmdiff_lag retdiff_lag stddiff_lag betadiff_lag  iordiff_lag hhidiff_lag roadiff_lag same_sic1_lag same_sp500_lag same_sp1500_lag i.sic1_lag i.fycompustat ///
if d_r==1 | d_actualpeer==1
outreg2 using reg_logit.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
	    append ctitle(1:1 sample & full variables)

* 1:1 sample, selected var		
logit d_actualpeer corr_lag sizediff_lag same_sic1_lag same_sp500_lag same_sp1500_lag i.sic1_lag i.fycompustat ///
if d_r==1 | d_actualpeer==1 
outreg2 using reg_logit.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
	    append ctitle(1:1 sample & selected variables)
	
/* LR test*/	
logit d_actualpeer corr_lag sizediff_lag bmdiff_lag retdiff_lag stddiff_lag betadiff_lag  iordiff_lag hhidiff_lag roadiff_lag same_sic1_lag same_sp500_lag same_sp1500_lag i.sic1_lag i.fycompustat ///
if d_r==1 | d_actualpeer==1
estimates store full 

* 1:1 sample, selected var		
logit d_actualpeer corr_lag sizediff_lag same_sic1_lag same_sp500_lag same_sp1500_lag i.sic1_lag i.fycompustat ///
if e(sample) & (d_r==1 | d_actualpeer==1) 
estimates store restricted

lrtest full restricted		


		
predict pscore, pr

g double g = fycompustat* real(cik) + pscore /* all pscore <1 */
* fycompustat*10000000 

psmatch2 d_actualpeer, pscore(g) noreplacement

g pair = _id if _treated==0
replace pair = _n1 if _treated==1
bysort pair: egen paircount = count(pair)
gsort + cik -paircount + pair - _treated

keep if paircount == 2 & _treated == 0 /* 19,494 fake peers  */


* save "psm2.dta", replace 

* teffects psmatch  (size_other) (d_actualpeer sizediff bmdiff retdiff stddiff betadiff ratingdiff iordiff hhidiff same_sic2 same_sp500 same_sp1500), gen(stub)

collapse (median)  med_dcamj_fake=dcamodjones1991_w (mean) avg_dcamj_fake=dcamodjones1991_w, by(cik fycompustat)
/*
collapse (median) med_cadta_fake=cadtatm1dechowetal_w med_dcaj_fake=dcajones1991_w med_dcajint_fake=dcajones1991int_w med_dcamj_fake=dcamodjones1991_w med_dcamjint_fake=dcamodjones1991int_w ///
(mean) avg_cadta_fake=cadtatm1dechowetal_w avg_dcaj_fake=dcajones1991_w avg_dcajint_fake=dcajones1991int_w avg_dcamj_fake=dcamodjones1991_w avg_dcamjint_fake=dcamodjones1991int_w ///
, by(cik fycompustat)
*/

save "med_avg_accruals_fakedpeer.dta",replace

save "med_avg_accruals_fakedpeer_fullAll.dta",replace
save "med_avg_accruals_fakedpeer_1to1Full.dta",replace
save "med_avg_accruals_fakedpeer_fullLarge.dta",replace
save "med_avg_accruals_fakedpeer_3to1Large.dta",replace



*** Get restate pct for peers ***

/* obtain restate dummy, run for one time
use aq_main.dta if fycompustat>2005, clear
keep cik fycompustat d_restate
*create cik_other for merging d_restate to peers/counterfactual peers 
gen cik_other = cik

* check uniqueness
by cik fycompustat, sort: gen t = _n
tab t 
drop t

save d_restate.dta, replace
*/
* Compute % of peers that restate
use psm2.dta, replace
merge m:1 cik_other fycompustat using d_restate.dta
keep if _merge==3

collapse (median) restatepct_fake=d_restate, by(cik fycompustat)

save restatepct_fakedpeer.dta, replace

save restatepct_fakedpeer_FullAll.dta, replace
save restatepct_fakedpeer_1to1Full.dta, replace
save restatepct_fakedpeer_1to1Large.dta, replace


**** Merge with other variables and run regressions
* for accruals;
use main_w.dta if fycompustat>2005, replace /*1693*/
merge 1:1 cik fycompustat using rpe_var_1st
drop if _merge ==2
drop _merge

* 
merge 1:1 cik fycompustat using med_avg_accruals_fakedpeer.dta 
merge 1:1 cik fycompustat using med_avg_accruals_fakedpeer_FullAll.dta /*1594 merged*/
merge 1:1 cik fycompustat using med_avg_accruals_fakedpeer_1to1Full.dta /*1592 merged*/
merge 1:1 cik fycompustat using med_avg_accruals_fakedpeer_1to1Large.dta /*1592 merged*/

keep if _merge == 3
drop _merge

gen yind = fycompustat*100 + ff12
encode cik, gen(cik_stata) //convert cik from char to num //
xtset cik_stata fycompustat  //specify panel format

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj med_dcamj_fake i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using PSM_reg_med.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop(i.fycompustat) append ctitle(Mod Jones Accruals ) addtext(FE, Industry+Year) 
		
		
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg avg_dcamj avg_dcamj_fake i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using PSM_reg_avg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop(i.fycompustat) append ctitle(Mod Jones Accruals ) addtext(FE, Industry+Year) 
		
		
areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_fake i.fycompustat, a(cik) cl(cik_stata) 
outreg2 using PSM_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg med_dcamj med_dcamj_fake) append ctitle(Mod Jones Accruals ) addtext(FE, Firm+Year) 
		
areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_fake, a(yind) cl(cik_stata) 
outreg2 using PSM_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg med_dcamj med_dcamj_fake) append ctitle(Mod Jones Accruals ) addtext(FE, Industry*Year) 	
		

	
* dropped peers
use main_w.dta if fycompustat>2005, replace
merge 1:1 cik fycompustat using med_avg_accruals_droppedpeer_last_yr.dta /* orignial paper used med_avg_accruals_droppedpeer with all dropped peers. Codes for getting med dropped peer accruals are at the end. */
keep if _merge ~= 2
drop _merge

merge 1:1 cik fycompustat using rpe_var_1st
drop if _merge ==2
drop _merge

tabstat n_droppedpeer if med_dcamj_dropped ~= ., stat( mean median sd) /*nb of dropped peers */
 
* 0 for RPE firms that did not drop peers;
replace avg_dcamj_dropped =0 if avg_dcamj_dropped == .
replace med_dcamj_dropped =0 if med_dcamj_dropped == .

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj med_dcamj_dropped i.fycompustat, a(ff12) cl(cik) 
outreg2 using PSM_reg_med.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop(i.fycompustat) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 

		

		


** peers' peers ***
use main_w.dta if fycompustat>2005, replace
encode cik, gen(cik_stata)

merge 1:1 cik fycompustat using peerpeerem.dta 
keep if _merge ~= 2		
drop _merge

merge 1:1 cik fycompustat using rpe_var_1st
drop if _merge ==2
drop _merge
		
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj med_dcamj_peerpeer i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using PSM_reg_med.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop(i.fycompustat) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 

		
** BGT peers **
* get accruals for fake peers;
use accruals.dta, replace
gen cik_fakep = cik
gen fycompustat = fyear
keep cik_fakep fycompustat cadtatm1dechowetal_w dcajones1991_w dcajones1991int_w dcamodjones1991_w dcamodjones1991int_w

merge 1:m cik_fakep fycompustat using BGTpeers.dta 
keep if _merge == 3 

* get median DAM for each RPE firm
collapse (median) med_cadta_fake=cadtatm1dechowetal_w med_dcaj_fake=dcajones1991_w med_dcajint_fake=dcajones1991int_w med_dcamj_fake=dcamodjones1991_w med_dcamjint_fake=dcamodjones1991int_w ///
(mean) avg_cadta_fake=cadtatm1dechowetal_w avg_dcaj_fake=dcajones1991_w avg_dcajint_fake=dcajones1991int_w avg_dcamj_fake=dcamodjones1991_w avg_dcamjint_fake=dcamodjones1991int_w ///
, by(cik fycompustat)

save med_dcamj_BGTpeers, replace

* get other controls for RPE firm
merge 1:1 cik fycompustat using main_w.dta
drop if _merge == 1
drop _merge

merge 1:1 cik fycompustat using rpe_var_1st
drop if _merge ==2
drop _merge

encode cik, gen(cik_stata)
gen yind = fycompustat * 100 + ff12

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj med_dcamj_fake i.fycompustat if fycompustat > 2005, a(ff12) cl(cik_stata)
outreg2 using PSM_reg_med.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         /// 
		drop(i.fycompustat) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 
		
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj_ff12 med_dcamj med_dcamj_fake i.fycompustat if fycompustat > 2005, a(ff12) cl(cik_stata)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         /// 
		append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj med_dcamj_fake i.fycompustat if fycompustat > 2005, a(yind) cl(cik_stata)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         /// 
		append ctitle(Mod Jones Accruals) addtext(FE, Industry*Year) 

		
*** Correlations among different peers ***	
use main_w, replace
merge 1:1 cik fycompustat using med_avg_accruals_fakedpeer_FullAll.dta
rename med_dcamj_fake med_dcamj_fake1
drop _merge

merge 1:1 cik fycompustat using med_avg_accruals_fakedpeer_1to1Full.dta
rename med_dcamj_fake med_dcamj_fake2
drop _merge

merge 1:1 cik fycompustat using med_avg_accruals_fakedpeer_1to1Large.dta
rename med_dcamj_fake med_dcamj_fake3
drop _merge

merge 1:1 cik fycompustat using med_avg_accruals_droppedpeer.dta
drop _merge

merge 1:1 cik fycompustat using peerpeerem.dta 
drop _merge
	
*merge 1:1 cik fycompustat using em_peerback.dta 
*drop _merge

merge 1:m cik fycompustat using med_dcamj_BGTpeers.dta 
drop _merge


cor dcamj med_dcamj med_dcamj_ff12 med_dcamj_fake1 med_dcamj_fake2 med_dcamj_fake3 med_dcamj_dropped med_dcamj_peerpeer  med_dcamj_fake		
pwcorr dcamj med_dcamj_dropped med_dcamj_peerpeer  
	
	
	
	
	
	
	
* for restatement;
use aq_main.dta if fycompustat>2005, replace 
keep if d_rpe == 1

* limit to 1:1 sample before dropping obs after merging, in case rv are assigned to different obs
set seed 0271  
sort fycompustat cik 
by fycompustat: gen r=runiform()  if d_restate==0 

bysort fycompustat: gen N=_N /*total nb of firms each year */
bysort fycompustat: egen N_restate=sum(d_restate)  /*count nb of restated firms */

merge 1:1 cik fycompustat using restatepct_fakedpeer.dta /*2053 merged and 114 not merged*/
merge 1:1 cik fycompustat using restatepct_fakedpeer_Fullall.dta /*2053 merged and 114 not merged*/
merge 1:1 cik fycompustat using restatepct_fakedpeer_Fulllarge.dta /*2053 merged and 114 not merged*/
merge 1:1 cik fycompustat using restatepct_fakedpeer_3to1large.dta /*2053 merged and 114 not merged*/
merge 1:1 cik fycompustat using restatepct_fakedpeer_1to1large.dta /*2053 merged and 114 not merged*/

keep if _merge ~= 2
gen yind = fycompustat*100 + ff12

gen d_peerrestate = 0
replace d_peerrestate = 1 if restatepct > 0
gen d_peerrestate_fake = 0
replace d_peerrestate_fake = 1 if restatepct_fake > 0

clogit d_restate bm size roa rety evol lvg d_peerrestate d_peerrestate_fake i.fycompustat if d_restate==1 | (r<= N_restate/N ), group(cik) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         /// /*restored in sheet Fakedpeers using 1to1 sample of AQ_RegResults.xls*/
		keep( bm size roa rety evol lvg d_peerrestate d_peerrestate_fake) adds("pseudo R-squared", e(r2_p)) append ctitle(Restatement) addtext(FE, Firm+Year) 

logit d_restate bm size roa rety evol lvg d_peerrestate d_peerrestate_fake i.yind if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg d_peerrestate d_peerrestate_fake) adds("pseudo R-squared", e(r2_p)) append ctitle(Restatement) addtext(FE, Industry*Year) 		
		
logit d_restate bm size roa rety evol lvg d_peerrestate d_peerrestate_fake i.fycompustat i.ff12 if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg d_peerrestate d_peerrestate_fake) adds("pseudo R-squared", e(r2_p)) append ctitle(Restatement) addtext(FE, Industry+Year) 		

		
* dropped peers
drop _merge
merge 1:1 cik fycompustat using restate_droppedpeer.dta 

keep if _merge ~= 2

gen d_restate_dropped = 0
replace d_restate_dropped = 1 if restate_dropped > 0


clogit d_restate bm size roa rety evol lvg d_peerrestate d_restate_dropped i.fycompustat if d_restate==1 | (r<= N_restate/N ), group(cik) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg d_peerrestate d_restate_dropped) adds("pseudo R-squared", e(r2_p)) append ctitle(Restatement) addtext(FE, Firm+Year) 

logit d_restate bm size roa rety evol lvg d_peerrestate d_restate_dropped i.yind if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg d_peerrestate d_restate_dropped) adds("pseudo R-squared", e(r2_p)) append ctitle(Restatement) addtext(FE, Industry*Year) 		
		
logit d_restate bm size roa rety evol lvg d_peerrestate d_restate_dropped i.fycompustat i.ff12 if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg d_peerrestate d_restate_dropped) adds("pseudo R-squared", e(r2_p)) append ctitle(Restatement) addtext(FE, Industry+Year) 		
	
		
		
		
/*		
areg d_restate bm size roa rety evol lvg d_peerrestate d_peerrestate_fake i.ff12, a(fycompustat) cl(cik) 
outreg2 using PSM_restateReg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg d_peerrestate d_peerrestate_fake) replace ctitle(Restate OLS) addtext(FE, Industry+Year) 

areg d_restate bm size roa rety evol lvg d_peerrestate d_peerrestate_fake, a(yind) cl(cik) 
outreg2 using PSM_restateReg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg d_peerrestate d_peerrestate_fake) append ctitle(Restate OLS) addtext(FE, Industry*Year) 		


logit d_restate bm size roa rety evol lvg d_peerrestate d_peerrestate_fake i.fycompustat i.ff12, cl(cik) 
outreg2 using PSM_restateReg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg d_peerrestate d_peerrestate_fake) adds("pseudo R-squared", e(r2_p)) append ctitle(Restate Logit) addtext(FE, Industry+Year) 

logit d_restate bm size roa rety evol lvg d_peerrestate d_peerrestate_fake i.yind, cl(cik) 
outreg2 using PSM_restateReg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg d_peerrestate d_peerrestate_fake) adds("pseudo R-squared", e(r2_p)) append ctitle(Restate Logit) addtext(FE, Industry*Year) 		
		
*/
		
		
		
/************ Dropped peers **********************************/
**** Data Preparation ****
/*Get accruals for dropped peers
use accruals.dta, replace
gen peercik = real(cik) /*create peercik to match with the master file*/
gen fycompustat = fyear /*create fycompustat to match with the master file*/
keep peercik fycompustat cadtatm1dechowetal_w dcajones1991_w dcajones1991int_w dcamodjones1991_w dcamodjones1991int_w

merge 1:m peercik fycompustat using droppedpeer_last_yr.dta 
keep if _merge == 3 
keep if d_drop == 1 /*3874*/

collapse (count) n_droppedpeer=d_drop_last_yr (median) med_cadta_dropped=cadtatm1dechowetal_w med_dcaj_dropped=dcajones1991_w med_dcajint_dropped=dcajones1991int_w med_dcamj_dropped=dcamodjones1991_w med_dcamjint_dropped=dcamodjones1991int_w ///
(mean) avg_cadta_dropped=cadtatm1dechowetal_w avg_dcaj_dropped=dcajones1991_w avg_dcajint_dropped=dcajones1991int_w avg_dcamj_dropped=dcamodjones1991_w avg_dcamjint_dropped=dcamodjones1991int_w ///
, by(cik fycompustat) /*773*/

save med_avg_accruals_droppedpeer_last_yr.dta,replace
*/

/*Get restatement for dropped peers
use aq_main.dta, replace
gen peercik = real(cik) /*create peercik to match with the master file*/
keep peercik fycompustat d_restate

merge 1:m peercik fycompustat using D:\RPE\RPE_EM\data_code\droppedpeer.dta 
keep if _merge == 3 
keep if d_drop == 1 /*4161*/

collapse (mean) restate_dropped=d_restate, by(cik fycompustat) /*825*/

save "restate_droppedpeer.dta",replace
*/


	

