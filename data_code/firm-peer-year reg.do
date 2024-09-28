cd "E:\Research\WB\RPE_EM\data_code"


*** abs diff in DAM ***
use indep, clear

merge 1:1 gvkey fyear using eps.dta

drop if _merge ==2 
drop _merge

drop if cik==""
ren fyear fycompustat 

* get RPE firms' controls from 1st stage
merge 1:1 cik fycompustat using rpe_var_1st
drop if _merge ==2
drop _merge

* get RPE firms' fundamentals;
merge 1:m cik fycompustat using peerlist.dta

drop if _merge ==1
drop _merge

*get RPE firms' accruals;
ren fycompustat fyear
merge m:m cik fyear using accruals.dta, keepusing(dcamodjones1991_w)
ren dcamodjones1991_w dcamj

drop if _merge ==2
drop _merge

* get peers' accruals;
preserve
use accruals, clear
ren cik peercik
ren dcamodjones1991_w peer_dcamj
save temp, replace
restore

merge m:m peercik fyear using temp.dta, keepusing(peer_dcamj)

drop if _merge ==2
drop _merge


ffind hsiccd, newvar(ff12) type(12)
gen yind = fyear*100 + ff12

gen diff_dcamj = dcamj - peer_dcamj
sum diff_dcamj, d
gen abs_diff_dcamj = abs(diff_dcamj)
sum abs_diff_dcamj, d
gen d_abs_diff_dcamj = 0
replace d_abs_diff_dcamj = 1 if abs_diff_dcamj < .069

egen  pct = xtile(peer_dcamj), by(cik fyear) nq(4)
gen d_25 = 0 if pct ~=.
replace d_25 = 1 if pct == 1
gen d_5 = 0 if pct ~=.
replace d_5 = 1 if pct == 2
gen d_75 = 0 if pct ~=.
replace d_75 = 1 if pct == 3

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg peer_dcamj i.fyear, a(cik) cl(cik) 
outreg2 using Firm_peer_year_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) replace ctitle(Jones Accruals) addtext(FE, Firm+Year) 
		
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg peer_dcamj , a(yind) cl(cik) 
outreg2 using Firm_peer_year_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry*Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg peer_dcamj i.fyear, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 


areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_abs_diff_dcamj##c.peer_dcamj i.fyear, a(cik) cl(cik) 
outreg2 using Firm_peer_year_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Firm + Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_abs_diff_dcamj##c.peer_dcamj, a(yind) cl(cik) 
outreg2 using Firm_peer_year_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry*Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_abs_diff_dcamj##c.peer_dcamj i.fyear, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 

		
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_25##c.peer_dcamj i.fyear, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_pct_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) replace ctitle(Jones Accruals) addtext(FE, Industry+Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_5##c.peer_dcamj i.fyear, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_pct_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_75##c.peer_dcamj i.fyear, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_pct_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 
		
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_25##c.peer_dcamj c.d_5##c.peer_dcamj c.d_75##c.peer_dcamj i.fyear, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_pct_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 


*** abs diff in EPS *****		
* get peers' eps;
preserve
use eps, clear
ren cik peercik
ren eps peer_eps
ren eps_gr peer_epsgr
keep if peercik ~= ""
save temp, replace
restore

merge m:m peercik fyear using temp.dta, keepusing(peer_eps peer_eps_gr)
drop if _merge ==2
drop _merge

gen diff_eps = eps - peer_eps
gen abs_diff_eps = abs(diff_eps)
sum abs_diff_eps,d

egen  pct_eps = xtile(diff_eps), by(cik fyear) nq(4)
gen d_25_eps = 0 if pct_eps ~=.
replace d_25_eps = 1 if pct_eps == 1
gen d_5_eps = 0 if pct_eps ~=.
replace d_5_eps = 1 if pct_eps == 2
gen d_75_eps = 0 if pct_eps ~=.
replace d_75_eps = 1 if pct_eps == 3


winsor2 diff_eps, cuts(1 99) suffix(_w)
gen abs_diff_eps_w = abs(diff_eps_w)
sum abs_diff_eps_w, d

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.peer_dcamj##c.abs_diff_eps i.fyear if fyear>2005, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_pct_eps.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) replace ctitle(Jones Accruals) addtext(FE, Industry+Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_25_eps##c.peer_dcamj i.fyear if fyear>2005, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_pct_eps.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_5_eps##c.peer_dcamj i.fyear if fyear>2005, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_pct_eps.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_75_eps##c.peer_dcamj i.fyear if fyear>2005, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_pct_eps.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_25_eps##c.peer_dcamj c.d_5_eps##c.peer_dcamj c.d_75_eps##c.peer_dcamj i.fyear if fyear>2005, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_pct_eps.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 

merge m:m cik fyear using eps.dta, keepusing(eps eps_gr)
drop if _merge == 2
drop _merge
		
gen diff_eps_gr = eps_gr - peer_epsgr
gen abs_diff_eps_gr = abs(diff_eps_gr)
sum abs_diff_eps,d

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.peer_dcamj##c.abs_diff_eps_gr i.fyear if fyear>2005, a(ff12) cl(cik) 


**** Rety and ROA *******

* get peers' info
use indep, clear
ren cik peercik
ren roa peerroa
ren rety peerrety

keep if peercik ~= ""
ren fyear fycompustat

keep peercik fycompustat peerroa peerrety

* get target firm's cik from peerlist
merge 1:m peercik fycompustat using peerlist.dta
drop if _merge ==1
drop _merge

* get target firm's fundamentals and 1st stage controls 
merge m:1 cik fycompustat using main_w.dta
drop if _merge ==1
drop _merge

merge m:1 cik fycompustat using rpe_var_1st
drop if _merge ==2
drop _merge

* get peers' accruals;
preserve
use accruals, clear
ren cik peercik
ren dcamodjones1991_w peer_dcamj
save temp, replace
restore

ren fycompustat fyear 

merge m:m peercik fyear using temp.dta, keepusing(peer_dcamj)
drop if _merge ==2
drop _merge

gen diff_roa = roa - peerroa
gen abs_diff_roa = abs(diff_roa)
sum abs_diff_roa,d

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.peer_dcamj##c.abs_diff_roa i.fyear if fyear>2005, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_rety.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) replace ctitle(Jones Accruals) addtext(FE, Industry+Year) 

gen diff_rety = rety - peerrety
gen abs_diff_rety = abs(diff_rety)
sum abs_diff_rety,d

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.peer_dcamj##c.abs_diff_rety i.fyear if fyear>2005, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_rety.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 

* firm - peer - year level for main table
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.peer_dcamj i.fyear if fyear>2005, a(ff12) cl(cik) 
outreg2 using Firm_peer_year_rety.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop (i.fyear) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 
		