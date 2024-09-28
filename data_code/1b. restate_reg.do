
/********************** Part I: Full sample ***********************************/
* read data
cd "D:\World_bank_research\RPE_EM\data_code"
use aq_main.dta if fycompustat>2005, clear

ren D_restate d_restate
g sic2 = int(sich/100)
gen yind = fycompustat*100 + ff12 /*logit does not work when choosing ff48*/
gen lnmc = log(mc)
gen lnmc_lag = log(mc_lag)
gen lnhorizon = log(horizon)

/*obtain the industry-year avg restate */
bysort fycompustat ff12: egen restatepct_ff12yr = mean(d_restate)
gen d_restateminusff12 = d_restate - restatepct_ff12yr
* compute peer restatement subtracted by industry-year FE;
g peercik = real(cik)
keep cik fycompustat peercik d_restateminusff12
save temp.dta, replace

use peerlist.dta, replace
destring peercik, replace force 
merge m:1 peercik fycompustat using temp.dta
keep if _merge == 3
collapse (mean) avgpeerrestateminusff12=d_restateminusff12 ///
         (median) medpeerrestateminusff12 = d_restateminusff12, by (cik fycompustat)
save temp.dta, replace

use aq_main.dta if fycompustat>2005, clear
merge 1:1 cik fycompustat using temp.dta
g sic2 = int(sich/100)
bysort fycompustat ff12: egen restatepct_ff12yr = mean(d_restate)
gen d_restateminusff12 = d_restate - restatepct_ff12yr

keep if d_rpe == 1
logit d_restateminusff12 bm size roa rety evol lvg  avgpeerrestateminusff12
reg d_restateminusff12 bm size roa rety evol lvg  avgpeerrestateminusff12

/*score restatement */
* get the peerlist;
use peerlist.dta, replace
keep cik peercik fycompustat
* keep unique peers;
unab vlist : _all
sort `vlist'
quietly by `vlist':  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
save peerlist.dta, replace

* obtain score for peers;
use aq_main.dta if fycompustat>2005, clear
logit d_restate bm size roa rety evol lvg 
predict pscore, pr
g peercik = real(cik)
save peerscore.dta,replace

use peerlist.dta
merge m:1 peercik fycompustat using peerscore /*peerlist must be master file, ow cik would be the one in peerlist and equals peercik*/
keep if _merge == 3 
keep cik peercik fycompustat pscore 
collapse (mean) avgrestate = pscore (median) medrestate=pscore, by(cik fycompustat)
save peerscore.dta, replace

* keep only SP1500 firms if it is for the whole sample regression;
keep if !missing(sp1500)
tab d_rpe /*10:1 for Non-RPE : RPE*/

* regressions used for final;
* industry+year fe
areg freq bm size roa rety evol lvg d_rpe i.ff12, a(fycompustat) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) replace addtext(FE, Industry+Year) 

areg lnhorizon bm size roa rety evol lvg d_rpe i.ff12, a(fycompustat) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry+Year) 

areg range bm size roa rety evol lvg d_rpe i.ff12, a(fycompustat) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry+Year) 

areg bias bm size roa rety evol lvg d_rpe i.ff12, a(fycompustat) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry+Year) 

areg error bm size roa rety evol lvg d_rpe i.ff12, a(fycompustat) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry+Year) 

areg bias_prc bm size roa rety evol lvg d_rpe i.ff12, a(fycompustat) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry+Year) 

areg error_prc bm size roa rety evol lvg d_rpe i.ff12, a(fycompustat) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry+Year) 

areg aq bm size roa rety evol lvg d_rpe i.ff12, a(fycompustat) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry+Year) 

logit d_restate bm size roa rety evol lvg d_rpe i.ff12 i.fycompustat, cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry+Year) 



/***************************************************************************** 
***********************  Part II: RPE and their peers **********************************************************/
cd "D:\World_bank_research\RPE_EM\data_code"
use aq_main.dta if fycompustat>2005, clear
ren D_rpe d_rpe
ren D_restate d_restate
keep if d_rpe == 1

gen yind = fycompustat*100 + ff12 
gen lnhorizon = log(horizon)
gen lnmc = log(mc)
gen lnmc_lag = log(mc_lag)

* RPE firms that have done a restatement at least once;
bysort cik: egen everrestate = mean(d_restate)
bysort cik: egen everpeerrestate = mean(restatepct)

merge 1:1 cik fycompustat using rpe_var_1st
drop if _merge ==2
drop _merge

gen d_peerrestate = 0
replace d_peerrestate = 1 if restatepct > 0

gen d_icw = 0 if icw=="Y"
replace d_icw=1 if icw=="N"

encode cik, gen(cik_stata)

/* select non-stated firms randomly 
set seed 08060304
gen r = runiform() if everrestate==0 /*generate random variables */
*/

**** reduce non-stated firms, skip to regression if using all RPE firms ***
*select non-stated firms by year 
* select non-stated firms by year
bysort fycompustat: gen N=_N /*total nb of firms each year */
bysort fycompustat: egen N_restate=sum(d_restate)  /*count nb of restated firms */

set seed 0271  // 1234 works only when not controlling for industry restatement
sort fycompustat cik //must sort this first, ow firms may change order when using runiform, making the results not replicable
by fycompustat: gen r=runiform()  if d_restate==0 /*create random variable*/

bysort fycompustat ff12: egen restatepct_ff12yr = mean(d_restate)

merge 1:1 cik fycompustat using var_1st
drop if _merge ==2
drop _merge


/* summary stat
tabstat d_peerrestate bm size roa evol rety lvg if d_restate==0 & r<= N_restate/N
tabstat d_peerrestate bm size roa evol rety lvg if d_restate==1 

foreach i of var d_peerrestate bm size roa evol rety lvg{
ttest `i' if d_restate==1 | (r<= N_restate/N ), by(d_restate)
}
*/

* Industry+Year FE
logit d_restate bm size roa rety evol lvg d_peerrestate i.ff12 i.fycompustat if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) /// transfered to AQ_RegResults
keep( bm size roa rety evol lvg d_peerrestate) adds("pseudo R-squared", e(r2_p)) replace addtext(FE, Industry+Year) ctitle(Restatement)

logit d_restate bm size roa rety evol lvg d_peerrestate restatepct_ff12yr i.ff12 i.fycompustat if d_restate==1 | (r<=N_restate/N), cl(cik)  
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate restatepct_ff12yr) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry+Year) ctitle(Restatement)

* Industry*Year FE
logit d_restate bm size roa rety evol lvg d_peerrestate i.yind if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry*Year) ctitle(Restatement)



*** regressions;
set matsize 4500
clogit d_restate bm size roa rety evol lvg d_peerrestate i.fycompustat, group(cik) cl(cik)
outreg2 using Reg_restate.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate) adds("pseudo R-squared", e(r2_p)) replace addtext(FE, Firm+Year) ctitle(Restatement)

logit d_restate bm size roa rety evol lvg d_peerrestate i.yind, cl(cik) 
outreg2 using Reg_restate.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry*Year) ctitle(Restatement)

logit d_restate bm size roa rety evol lvg d_peerrestate i.ff12 i.fycompustat, cl(cik) 
outreg2 using Reg_restate.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)  ///
keep( bm size roa rety evol lvg d_peerrestate) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry+Year) ctitle(Restatement)


* add industry restatement pct;
bysort fycompustat ff12: egen restatepct_ff12yr = mean(d_restate)

clogit d_restate bm size roa rety evol lvg d_peerrestate restatepct_ff12yr i.fycompustat, group(cik) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg d_peerrestate restatepct_ff12yr) adds("pseudo R-squared", e(r2_p)) replace addtext(FE, Firm+Year) ctitle(Restatement)

* add a dummy indicating whether the industry's restatepct in a year is higher than avg;
bys ff12: egen restatepct_ff12 = mean(d_restate)
gen restatepct_ff12higheravg = restatepct_ff12yr - restatepct_ff12
gen d_restatepct_ff12higheravg = 0
replace d_restatepct_ff12higheravg = 1 if restatepct_ff12higheravg > 0

* add interactions with other variables for restatement
* get rpe pct from main_w;
merge 1:1 cik fycompustat using main_w.dta 
replace rpepct = 0 if rpepct ==.
replace accountingpct=0 if accountingpct==.

* RPE pct
gen d_rpepct35 = 0
replace d_rpepct35 = 1 if rpepct > .35 & rpepct ~=.
logit d_restate bm size roa rety evol lvg c.d_peerrestate##c.d_rpepct35 i.ff12 i.fycompustat, cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)  ///
keep( bm size roa rety evol lvg c.d_peerrestate##c.d_rpepct35) adds("pseudo R-squared", e(r2_p)) replace addtext(FE, Industry+Year)

logit d_restate bm size roa rety evol lvg c.d_peerrestate##c.d_rpepct35 i.yind, cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg c.d_peerrestate##c.d_rpepct35) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry*Year)

* accounting pct	
logit d_restate bm size roa rety evol lvg c.d_peerrestate##c.accountingpct i.ff12 i.fycompustat, cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)  ///
keep( bm size roa rety evol lvg c.d_peerrestate##c.accountingpct) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry+Year)

logit d_restate bm size roa rety evol lvg c.d_peerrestate##c.accountingpct i.yind, cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg c.d_peerrestate##c.accountingpct) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry*Year)
restore 

* nb of peers
logit d_restate bm size roa rety evol lvg c.d_peerrestate##c.n_peers i.ff12 i.fycompustat, cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)  ///
keep( bm size roa rety evol lvg c.d_peerrestate##c.n_peers) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry+Year)

logit d_restate bm size roa rety evol lvg c.d_peerrestate##c.n_peers i.yind, cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
keep( bm size roa rety evol lvg c.d_peerrestate##c.n_peers) adds("pseudo R-squared", e(r2_p)) append addtext(FE, Industry*Year)




*** Other accruals quality measures;
* Firm + Year FE
areg freq bm size roa rety evol lvg freqpct i.fycompustat, a(cik) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) replace addtext(FE, Firm+Year) 

areg lnhorizon bm size roa rety evol lvg peermedhorizon i.fycompustat, a(cik) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Firm+Year) 

areg range bm size roa rety evol lvg peermedrange i.fycompustat, a(cik) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Firm+Year) 

areg bias bm size roa rety evol lvg peermedbias i.fycompustat, a(cik) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Firm+Year) 

areg error bm size roa rety evol lvg peermederror i.fycompustat, a(cik) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Firm+Year) 

areg bias_prc bm size roa rety evol lvg peermedbias_prc i.fycompustat, a(cik) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Firm+Year) 

areg error_prc bm size roa rety evol lvg peermederror_prc i.fycompustat, a(cik) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Firm+Year) 

logit d_icw bm size roa rety evol lvg icwpct i.fycompustat i.cik_stata, cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
	keep( bm size roa rety evol lvg icwpct) append addtext(FE, Firm+Year) 

logit d_restate bm size roa rety evol lvg d_peerrestate i.fycompustat i.cik_stata, cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
	keep( bm size roa rety evol lvg d_peerrestate) append addtext(FE, Firm+Year) 

areg std_DDdc bm size roa rety evol lvg peeravgstd_DDdc i.fycompustat if NumYearsforstd >2, a(cik) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
	keep( bm size roa rety evol lvg peeravgstd_DDdc) replace addtext(FE, Firm+Year) 
	
* Industry + Year FE
areg freq attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg freqpct i.fycompustat, a(ff12) cl(cik) 
outreg2 using vol_forecasting.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) replace ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg horizon attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg peermedhorizon i.fycompustat, a(ff12) cl(cik)
outreg2 using vol_forecasting.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg range attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg peermedrange i.fycompustat, a(ff12) cl(cik)
outreg2 using vol_forecasting.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg bias attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg peermedbias i.fycompustat, a(ff12) cl(cik)

areg error attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg peermederror i.fycompustat, a(ff12) cl(cik)

areg bias_prc attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg peermedbias_prc i.fycompustat, a(ff12) cl(cik)
outreg2 using vol_forecasting.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg error_prc attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg peermederror_prc i.fycompustat, a(ff12) cl(cik)
outreg2 using vol_forecasting.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  


logit d_icw bm size roa rety evol lvg icwpct i.fycompustat i.ff12, cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
	keep( bm size roa rety evol lvg icwpct) append addtext(FE, Industry+Year) 
	
logit d_restate bm size roa rety evol lvg d_peerrestate i.fycompustat i.ff12, cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
	keep( bm size roa rety evol lvg d_peerrestate) append addtext(FE, Industry+Year)

areg std_DDdc bm size roa rety evol lvg peeravgstd_DDdc i.fycompustat if NumYearsforstd >2, a(ff12) cl(cik) 	
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
	keep( bm size roa rety evol lvg peeravgstd_DDdc) append addtext(FE, Industry+Year)



* Industry * Year FE
areg freq bm size roa rety evol lvg freqpct, a(yind) cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry*Year) 

areg lnhorizon bm size roa rety evol lvg peermedhorizon, a(yind) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry*Year) 

areg range bm size roa rety evol lvg peermedrange, a(yind) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry*Year)

areg bias bm size roa rety evol lvg peermedbias, a(yind) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry*Year)

areg error bm size roa rety evol lvg peermederror , a(yind) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry*Year)

areg bias_prc bm size roa rety evol lvg peermedbias_prc , a(yind) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry*Year)

areg error_prc bm size roa rety evol lvg peermederror_prc, a(yind) cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry*Year)

logit d_icw bm size roa rety evol lvg icwpct i.yind, cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) ///
	keep( bm size roa rety evol lvg icwpct) append addtext(FE, Industry*Year)

logit d_restate bm size roa rety evol lvg d_peerrestate i.yind, cl(cik)
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) ///
	keep( bm size roa rety evol lvg d_peerrestate) symbol(***, **, *) append addtext(FE, Industry*Year)

areg std_DDdc bm size roa rety evol lvg peeravgstd_DDdc if NumYearsforstd >2, a(yind) cl(cik) 	
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) ///
	keep( bm size roa rety evol lvg peeravgstd_DDdc) symbol(***, **, *) append addtext(FE, Industry*Year)


* reduce sample size for ICW
* select non-stated firms by year
bysort fycompustat: gen N=_N /*total nb of firms each year */
bysort fycompustat: egen N_restate=sum(d_icw)  /*count nb of restated firms */

set seed 0271  // 1234 works only when not controlling for industry restatement
sort fycompustat cik //must sort this first, ow firms may change order when using runiform, making the results not replicable
by fycompustat: gen r=runiform()  if d_icw==0 /*create random variable*/

gen d_peericwpct = 0
replace d_peericwpct = 1 if icwpct >0 

logit d_restate bm size roa rety evol lvg d_peericwpct i.ff12 i.fycompustat
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) replace addtext(FE, Industry+Year)

logit d_restate bm size roa rety evol lvg d_peericwpct i.ff12 i.fycompustat if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry+Year)



/******** When there exists fully prediction problem *****
* solution 1: change some values
preserve
replace d_restate=0 if real(gvkey) == 10801 & fycompustat==2012
logit d_restate bm size roa rety evol lvg d_peerrestate i.fycompustat i.ff12, cl(cik) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) append addtext(FE, Industry+Year)

* solution2: use other models. logit doesn't return coef of peer state since the latter fully predicts RPE firm dummy. need to use nl instead;
logit d_restate restatepct i.ff12 i.fycompustat, cl(cik) 

* nl only works when all variables are non-missing;
egen nmiss = rowmiss(bm size roa rety evol lvg)
keep if nmiss==0 

nl (d_restate = 1/exp(-1*{b0}-{b1}*d_peerrestate-{b2}*size))

* create dummies for industry and year FE;
forvalues n=1/11 {
    gen d_ff12_`n' = 0
    replace d_ff12_`n' = 1 if ff12 == `n'
}

forvalues n=2006/2015 {
    gen fycompustat_`n' = 0
    replace fycompustat_`n' = 1 if fycompustat == `n'
}

* create industry*year dummy;
forvalues i=2006/2016 {
    forvalues j=1/12{
	    gen yind_`i'_`j' = 0
		replace yind_`i'_`j' = 1 if fycompustat == `i' & ff12 == `j'
	}   
}

nl (d_restate = 1/exp(-1*{b0}-{b1}*bm-{b2}*size-{b3}*roa-{b4}*rety-{b5}*evol-{b6}*lvg-{b7}*d_peerrestate + {_Ib: d_ff12_1-d_ff12_11 fycompustat_2006-fycompustat_2015})), cl(cik)
outreg2 using temp1.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *) replace addtext(FE, Industry*Year)

* compute McFadden's pseudo-R square
nl (d_restate = 1/exp(-1*{b0}-{b1}*bm-{b2}*size-{b3}*roa-{b4}*rety-{b5}*evol-{b6}*lvg-{b7}*d_peerrestate + {_Ib: d_ff12_1-d_ff12_11 fycompustat_2006-fycompustat_2015}))
estimates store full  
nl (d_restate = 1/exp(-1*{b0}))
estimate store cons 

lrtest full cons, stats /* lrtest doesnot work with clustering */

nl (d_restate = 1/exp(-1*{b0}-{b1}*bm-{b2}*size-{b3}*roa-{b4}*rety-{b5}*evol-{b6}*lvg-{b7}*d_peerrestate + {_Ib: yind_2006_1-yind_2016_11})), cl(cik)
*/
