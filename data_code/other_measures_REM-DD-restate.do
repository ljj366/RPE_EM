
**********************  Part I: REM ******************************
/* merge data 
use rem.dta, clear

ren *, lower

keep if cik ~= ""
encode cik, gen(cik_stata)
xtset cik_stata fyear

gen invat_l = 1/at_l

xtreg discexp discexp_l invat_l sales, fe

predict res_discexp, residuals
bys cik: egen mres_discexp = mean(res_discexp)
gen AbnDisx = -(res_discexp - mres_discexp)

xtreg prod prod_l invat_l sales salesgr salesgr_l, fe

predict res_prod, residuals
bys cik: egen mres_prod = mean(res_prod)
gen AbnProd = -(res_prod - mres_prod)

egen RM = rowtotal(AbnDisx AbnProd)

ren fyear fycompustat

save Abnrem, replace

* merge with peers
ren cik peercik 
merge 1:m peercik fycompustat using peerlist
drop if _merge == 1
drop _merge

collapse (median) med_AbnProd = AbnProd med_AbnDisx = AbnDisx med_RM = RM, by(cik fycompustat)
save peerrem, replace
*/

use peerrem,clear

merge 1:m cik fycompustat using Abnrem, keepusing(AbnDisx AbnProd RM discexp_l invat_l sales prod_l invat_l sales salesgr salesgr_l)
keep if _merge == 3
drop _merge

ren fycompustat fyear
merge 1:m cik fyear using indep
keep if _merge == 3
drop _merge

encode cik, gen(cik_stata)
ren  fyear fycompustat
ffind hsiccd, newvar(ff12) type(12)
gen yind = fycompustat * 100 + ff12

areg AbnDisx discexp_l invat_l sales bm size roa rety evol lvg med_AbnDisx i.fycompustat if fycompustat > 2005, a(ff12) cl(cik_stata) 
outreg2 using other_measure.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		replace ctitle(Abnormal Discretionary Expenses) drop(i.fycompustat) addtext(FE, Industry+Year) 

areg AbnProd prod_l invat_l sales salesgr salesgr_l bm size roa rety evol lvg med_AbnProd i.fycompustat if fycompustat > 2005 , a(ff12) cl(cik_stata) 
outreg2 using other_measure.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Abnormal Production Costs) drop(i.fycompustat) addtext(FE, Industry+Year) 

areg RM discexp_l invat_l sales prod_l invat_l sales salesgr salesgr_l bm size roa rety evol lvg med_RM i.fycompustat if fycompustat > 2005 & AbnDisx~=. & AbnProd~=., a(ff12) cl(cik_stata) 
outreg2 using other_measure.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Abnormal Real Earnings Management) drop(i.fycompustat) addtext(FE, Industry+Year) 
		
		
/**************** Part II: DD accruals and restatement *************************************************/
use aq_main.dta if fycompustat>2005, clear
keep if D_rpe == 1
ren BM bm

merge 1:1 cik fycompustat using DD_estimation_var_1st
drop if _merge ==2
drop _merge

gen yind = fycompustat*100 + ff12


preserve
use DD_estimation,clear

merge 1:1 gvkey fyear using indep, keepusing( hsiccd) /*get hsiccd*/
keep if _merge ==3 
drop _merge

ffind hsiccd, newvar(ff12) type(12)

collapse (median) std_DDdc_med_ind = std_DDdc,by(ff12 fyear)
ren fyear fycompustat 

save temp, replace 

restore 

merge m:1 ff12 fycompustat using temp
drop if _merge ==2 
drop _merge


areg std_DDdc lagocf ocf leadocf bm size roa rety evol lvg  peermedstd_DDdc i.fycompustat if NumYearsforstd >2, a(ff12) cl(cik) 	
outreg2 using dd_measure.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		replace ctitle(DD accruals) drop(i.fycompustat) addtext(FE, Industry+Year) 

areg std_DDdc lagocf ocf leadocf bm size roa rety evol lvg  peermedstd_DDdc std_DDdc_med_ind i.fycompustat if NumYearsforstd >2, a(ff12) cl(cik) 	
outreg2 using dd_measure.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(DD accruals) drop(i.fycompustat) addtext(FE, Industry+Year) 
		
		
areg std_DDdc lagocf ocf leadocf bm size roa rety evol lvg  peermedstd_DDdc if NumYearsforstd >2, a(yind) cl(cik) 
outreg2 using dd_measure.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(DD accruals) drop(i.fycompustat) addtext(FE, Industry*Year) 

areg std_DDdc lagocf ocf leadocf bm size roa rety evol lvg  peermedstd_DDdc i.fycompustat if NumYearsforstd >2, a(cik) cl(cik) 
outreg2 using dd_measure.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(DD accruals) drop(i.fycompustat) addtext(FE, Firm+Year) 

*areg std_DDdc lagocf ocf leadocf bm size roa rety evol lvg  peermedstd_DDdc i.yind if NumYearsforstd >2, a(cik) cl(cik) 
*outreg2 using dd_measure.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
*		append ctitle(DD accruals) drop(i.fycompustat) addtext(FE, Firm+Industry*Year) 
		
		
		
* 1:1 match for non-restated 
ren D_restate d_restate
		
gen d_peerrestate = 0
replace d_peerrestate = 1 if restatepct > 0

bysort fycompustat: gen N=_N /*total nb of firms each year */
bysort fycompustat: egen N_restate=sum(d_restate)  /*count nb of restated firms */

capture drop r
set seed 0272  // 0272
sort fycompustat cik //must sort this first, ow firms may change order when using runiform, making the results not replicable
by fycompustat: gen r=runiform()  if d_restate==0 /*create random variable*/


merge 1:1 cik fycompustat using var_1st
drop if _merge ==2
drop _merge

logit d_restate attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg d_peerrestate i.ff12 i.fycompustat if d_restate==1 | (r<= N_restate/N ), cl(cik) 
outreg2 using other_measure.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Restatement Dummy) drop(i.fycompustat i.ff12) addtext(FE, Industry+Year) 
		
		
