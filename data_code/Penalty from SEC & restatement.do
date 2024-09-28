
* get fyr for main

/* run SAS code below first 
data temp; set tmp1.funda_w; keep  cik cyear fyear fyr; if cik~=""; run;

proc sort data=temp; by cik fyear fyr; run;
data temp2; set temp; by cik fyear fyr; if last.fyr; if fyear >= 2005; run;
data temp2; set temp2; rename fyear=fycompustat; run;

proc export data=temp2 outfile= "F:\Research\WB\RPE_EM\data_code\funda_fyr.dta"; run;
*/

use main_w.dta if fycompustat>2005, clear

merge 1:1 cik fycompustat using funda_fyr
drop if _merge ==2
drop _merge
ren cyear close_year

merge 1:1 cik fycompustat using rpe_var_1st
drop if _merge ==2
drop _merge

encode cik, gen(cik_stata) //convert cik from char to num //

* identify firms with SEC inv in past 3 years
merge m:m gvkey close_year using SEC_investigation_o.dta
drop if _merge ==2
drop _merge

* create dummy for SEC inv year
sort cik fycompustat fyr
gen D_SEC_inv = 0
replace D_SEC_inv = 1 if close_date ~=. 
*replace D_SEC_inv = 1 if month(close_date) <= fyr & close_date ~=. 
*replace D_SEC_inv = 1 if cik==cik[_n-1] & month(close_date[_n-1]) > fyr[_n-1] & close_date[_n-1] ~=. /* D=1 for 1 yr later if fyr before June */

gen n_yr = close_year - open_year
sum n_yr

* D=1 for all years after open_year are investigated;
forvalues i=1/19{  /*19 is max of n_yr*/
	replace D_SEC_inv = 1 if cik==cik[_n+`i'] & close_year > open_year[_n+`i'] & n_yr[_n+`i']~=. & `i' <n_yr
}

/* D=1 for the year when open_year are before fyr ends;
forvalues i=0/19{
	replace D_SEC_inv = 1 if cik==cik[_n+`i'] & close_year == open_year[_n+`i'] & month(open_date[_n+`i']) <= fyr & n_yr[_n+`i']~=. 
}
*/

* create dummy for inv in past 3 yrs 
capture drop D_SEC_inv_past3yrs
gen D_SEC_inv_past3yrs = 0

forvalues i=1/3{
	replace D_SEC_inv_past3yrs = 1 if cik==cik[_n-`i'] & D_SEC_inv[_n-`i']==1 & fycompustat-fycompustat[_n-`i']<=3
}	

* if no obs before inv, then D=1
* bys cik: replace D_SEC_inv_past3yrs = 1 if _n==1 & D_SEC_inv==1 

* collapse to CIK-fycompustat level 
sort cik fycompustat D_SEC_inv_past3yrs
by cik fycompustat: keep if _n==_N

areg dcamj  attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_SEC_inv_past3yrs i.ff12, a( fycompustat) cl(cik_stata) 
outreg2 using cross_sec_var.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.ff12) addtext(FE, Industry+Year) 
	

***************************************************************************************
****************************    Restatement ***************************

use main_w, clear

merge 1:1 cik fycompustat using rpe_var_1st
drop if _merge ==2
drop _merge

* get peer restatement pct
merge 1:1 cik fycompustat using d_restate	
drop if _merge==2
drop _merge

* create dummy for restatement in past 3 yrs 
gen D_restate_past3yrs = 0

sort cik fycompustat
forvalues i=1/3{
	replace D_restate_past3yrs = 1 if cik==cik[_n-`i'] & d_restate[_n-`i']==1 & (fycompustat-fycompustat[_n-`i']) <=3
}

bys cik: replace D_restate_past3yrs = 1 if _n==1 & D_restate==1 

* At least one peer restated in past 3 years
forvalues i=1/3{
	replace D_restate_past3yrs = 1 if cik==cik[_n-`i'] & restatepct[_n-`i']>0 & (fycompustat-fycompustat[_n-`i']) <=3
}


areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_restate_past3yrs i.ff12 if fycompustat>2005, a(fycompustat) cl(cik) 
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop(i.ff12) replace ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 

	