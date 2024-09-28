cd "E:/Research/WB/RPE_EM/data_code"

******* 1. Prepare data: compute RPE firms' earnings surprise and its volatility *****
use "F:\Data\freq used vars\sue", clear

* let's forget other vars like sue1 or sue2, which causes data not uniquely determined by cik year;
keep gvkey cik fyearq fqtr fyr conm rdq actual sue3_medest sue3_meanest

* remove duplicates;
unab vlist : _all
sort `vlist'
quietly by `vlist':  gen dup = _N
drop if dup > 1
drop dup

* the data now is uniquely determined by cik fyearq fqtr fyr;
bys cik fyearq fqtr fyr: gen dup = _N if cik~="" & sue3_medest~=.
tab dup
sort dup cik fyearq fqtr fyr
br if dup >1 & dup ~=.
drop dup

ren fyearq fycompustat

* get and keep RPE firms' sue 
merge m:1 cik fycompustat using rpe_list
keep if _merge == 3 
drop _merge 

* unique by cik year-quarter; 
bys cik fycompustat fqtr : gen dup = _N if sue3_medest~=.
br if dup >1 & dup ~=.
drop dup

**** compute earnings volatility in past 3 years, i.e., 12 quarters.
*** and adjust standard deviation by the square root of (n-1)/n 
*** where n is the number of nonmissing observations used to calculate the standard deviation
gen fyearqr = yq(fycompustat, fqtr)
destring cik, gen(cik_ds)

* settings;
ssc inst tsegen
tsset cik_ds fyearqr

* compute vol of shoci in median estimate;
tsegen sue3_medest_vol = rowsd(L(1/12).sue3_medest)
tsegen sue3_n = rownonmiss(L(1/12).sue3_medest)
replace sue3_medest_vol = sue3_medest_vol*sqrt((sue3_n-1)/sue3_n)

tsegen sue3_meanest_vol = rowsd(L(1/12).sue3_meanest)
replace sue3_meanest_vol = sue3_meanest_vol*sqrt((sue3_n-1)/sue3_n)

* compute vol of actual earnings;
tsegen actual_vol = rowsd(L(1/12).actual)
tsegen actual_n = rownonmiss(L(1/12).actual)
replace actual_vol = actual_vol*sqrt((actual_n-1)/actual_n)

save rpe_sue



******* 2. Prepare data: compute Peer firms' earnings surprise and its volatility *****
use "E:\Data\freq used vars\sue", clear

* let's forget other vars like sue1 or sue2, which causes data not uniquely determined by cik year;
keep gvkey cik fyearq fqtr fyr conm rdq actual sue3_medest sue3_meanest

* remove duplicates;
unab vlist : _all
sort `vlist'
quietly by `vlist':  gen dup = _N
drop if dup > 1
drop dup

* the data now is uniquely determined by cik fyearq fqtr fyr;
bys cik fyearq fqtr fyr: gen dup = _N if cik~="" & sue3_medest~=.
tab dup
sort dup cik fyearq fqtr fyr
br if dup >1 & dup ~=.
drop dup

ren fyearq fycompustat
ren cik peercik  /*check name to get peers' cik*/

* get and keep RPE firms' sue 
merge m:m peercik fycompustat using peerlist
keep if _merge == 3 
drop _merge 

**** compute earnings volatility in past 3 years, i.e., 12 quarters.
*** and adjust standard deviation by the square root of (n-1)/n 
*** where n is the number of nonmissing observations used to calculate the standard deviation

* settings;
* keep only peercik year-qtr as tsset requires uniqueness
keep peercik fycompustat fqtr fyr actual sue3_medest sue3_meanest
bys peercik fycompustat fqtr fyr actual sue3_medest sue3_meanest: gen dup=_N
drop if dup >1
drop dup

gen fyearqr = yq(fycompustat, fqtr)
destring peercik, gen(peercik_ds)

ssc inst tsegen
tsset peercik_ds fyearqr

* compute vol of shoci in median estimate;
tsegen sue3_medest_vol = rowsd(L(1/12).sue3_medest)
tsegen sue3_n = rownonmiss(L(1/12).sue3_medest)
replace sue3_medest_vol = sue3_medest_vol*sqrt((sue3_n-1)/sue3_n)

tsegen sue3_meanest_vol = rowsd(L(1/12).sue3_meanest)
replace sue3_meanest_vol = sue3_meanest_vol*sqrt((sue3_n-1)/sue3_n)

* compute vol of actual earnings;
tsegen actual_vol = rowsd(L(1/12).actual)
tsegen actual_n = rownonmiss(L(1/12).actual)
replace actual_vol = actual_vol*sqrt((actual_n-1)/actual_n)

ren sue3_medest_vol peer_sue3_medest_vol
ren sue3_n peer_sue3_n
ren sue3_meanest_vol peer_sue3_meanest_vol
ren actual_vol peer_actual_vol
ren actual_n peer_actual_n

ren actual peer_actual
ren sue3_medest peer_sue3_medest
ren sue3_meanest peer_sue3_meanest

drop peercik_ds fycompustat fqtr

save peer_sue, replace


* compute the median level of peer firm earnings surprise;
use peerlist, clear
merge m:m peercik fycompustat using peer_sue 
collapse (median) peer_actual peer_sue3_medest peer_sue3_meanest peer_sue3_medest_vol peer_sue3_meanest_vol peer_actual_vol, by(cik fyearqr)

* merge with RPE firms' earnings surprise
merge 1:1 cik fyearqr using rpe_sue
keep if _merge == 3
drop _merge

save rpe_peermed_sue


****** 3. Merge wt annual controls ****
use rpe_peermed_sue,clear
ren fycompustat fyear
drop _merge

/*
merge m:m cik fyear using indep.dta
drop if _merge == 2
drop _merge

* run ffind function in freq first;
ffind hsiccd, newvar(ff12) type(12)

************ 4a. Regressions using earnings surprise: relation bw focal firm and peers' earnings surprise ***********

** Now test relation bw RPE and peers' contagion. Use Actual-estimated earnings as proxy for manapulation.
reghdfe sue3_medest peer_sue3_medest bm size roa rety evol lvg if fqtr==4 & fyear>2005, a(fyear ff12) cl(cik_ds) 

sum sue3_medest  if fqtr==4 & fyear>2005, d
gen D_sue_extreme = 0
replace D_sue_extreme = 1 if sue3_medest>0.005 | sue3_medest<-.002 | peer_sue3_medest>.003|peer_sue3_medest<-.0012

reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fqtr==4 & fyear>2005, a(fyear ff12) cl(cik_ds)
 
* relation is stronger when earnings surprise is small; 
reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_sue_extreme==1, a(fyear ff12) cl(cik_ds) 
reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_sue_extreme==0, a(fyear ff12) cl(cik_ds) 

reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fyear>2005 & D_sue_extreme==1, a(fyear ff12) cl(cik_ds) 
reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fyear>2005 & D_sue_extreme==0, a(fyear ff12) cl(cik_ds) 

* not work
reghdfe sue3_meanest c.peer_sue3_meanest bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_sue_extreme==1, a(fyear ff12) cl(cik_ds) 
reghdfe sue3_meanest c.peer_sue3_meanest bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_sue_extreme==0, a(fyear ff12) cl(cik_ds) 

* standardized earnings surprise not work
gen sue3_medest_sd = sue3_medest/sue3_medest_vol
gen peer_sue3_medest_sd = peer_sue3_medest/peer_sue3_medest_vol

reghdfe sue3_medest_sd c.peer_sue3_medest_sd bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_sue_extreme==1, a(fyear ff12) cl(cik_ds) 
reghdfe sue3_medest_sd c.peer_sue3_medest_sd bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_sue_extreme==0, a(fyear ff12) cl(cik_ds) 

sum peer_sue3_medest_vol if fqtr==4 & fyear>2005, d
gen D_peer_sue3_medest_vol = 0 
replace D_peer_sue3_medest_vol = 1 if peer_sue3_medest_vol > .012 

reghdfe sue3_medest_sd c.peer_sue3_medest_sd bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_peer_sue3_medest_vol==1, a(fyear ff12) cl(cik_ds) 
reghdfe sue3_medest_sd c.peer_sue3_medest_sd bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_peer_sue3_medest_vol==0, a(fyear ff12) cl(cik_ds) 

* check whether relation is stronger when own earnings are more volatile;
sum actual_vol if fqtr==4 & fyear>2005, d
gen D_actual_vol = 0 
replace D_actual_vol = 1 if peer_actual_vol < 0.045 & peer_actual_vol~=.

* stronger relation when own earnings vol is high
reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_actual_vol==1, a(fyear ff12) cl(cik_ds) 
reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_actual_vol==0, a(fyear ff12) cl(cik_ds) 

* check whether relation is stronger when peer earnings are more volatile;
sum peer_actual_vol if fqtr==4 & fyear>2005, d
gen D_peer_actual_vol = 0 
replace D_peer_actual_vol = 1 if peer_actual_vol < .1 & peer_actual_vol~=.

* stronger relation when peer earnings vol is high --> higher chance to win;
reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_peer_actual_vol==1, a(fyear ff12) cl(cik_ds) 
reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_peer_actual_vol==0, a(fyear ff12) cl(cik_ds) 

*or combine own earnings vol and peer earnings vol;
reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fqtr==4 & fyear>2005 & (D_peer_actual_vol==1 | D_actual_vol==1), a(fyear ff12) cl(cik_ds)
reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fqtr==4 & fyear>2005 & !(D_peer_actual_vol==1 | D_actual_vol==1), a(fyear ff12) cl(cik_ds)



* check whether relation is stronger when peer earnings management are more volatile;
sum peer_sue3_medest_vol if fqtr==4 & fyear>2005, d
gen D_peer_sue3_medest_vol = 0 
replace D_peer_sue3_medest_vol = 1 if peer_sue3_medest_vol < 0.00074 & peer_sue3_medest_vol~=.

* stronger relation when peer vol is high --> higher chance to win;
reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_peer_sue3_medest_vol==1, a(fyear ff12) cl(cik_ds) 
reghdfe sue3_medest c.peer_sue3_medest bm size roa rety evol lvg if fqtr==4 & fyear>2005 & D_peer_sue3_medest_vol==0, a(fyear ff12) cl(cik_ds) 
*/

************ 4b. Regressions using discretionary accruals: examine whether earnings surprise reduce contagion ***********
* merge with dac;
ren fyear fycompustat
merge m:1 cik fycompustat using main_w
drop _merge

merge m:1 cik fycompustat using rpe_var_1st
drop if _merge ==2
drop _merge

ren fycompustat fyear

sum sue3_medest  if fqtr==4 & fyear>2005, d
capture drop D_sue_extreme
gen D_sue_extreme = 0
replace D_sue_extreme = 1 if sue3_medest ~=. & (sue3_medest>.027 | sue3_medest< -.027 ) 
replace D_sue_extreme = 1 if sue3_medest ~=. & (sue3_medest>.005 | sue3_medest< -.002) /*use 10% on each side*/

reghdfe dcamj bm size roa rety evol lvg c.med_dcamj  if fqtr==4 & fyear > 2005 & D_sue_extreme==1, a(ff12 fyear) cl(cik_ds)
reghdfe dcamj bm size roa rety evol lvg c.med_dcamj  if fqtr==4 & fyear > 2005 & D_sue_extreme==0, a(ff12 fyear) cl(cik_ds)

reghdfe dcamj bm size roa rety evol lvg c.med_dcamj##c.D_sue_extreme  if fqtr==4 & fyear > 2005 , a(ff12 fyear) cl(cik_ds)


sum sue3_meanest  if fqtr==4 & fyear>2005, d
*sum peer_sue3_meanest, d
capture drop D_sue_extreme
gen D_sue_extreme = 0
replace D_sue_extreme = 1 if  (sue3_meanest>.01 | sue3_meanest< -.0062 ) 

reghdfe dcamj bm size roa rety evol lvg c.med_dcamj##c.D_sue_extreme  if fqtr==4 & fyear > 2005 , a(ff12 fyear) cl(cik_ds)
	
	
gen sue3_medest_sd = sue3_medest/sue3_medest_vol
gen peer_sue3_medest_sd = peer_sue3_medest/peer_sue3_medest_vol

sum sue3_medest_sd if fqtr==4 & fyear>2005, d
sum peer_sue3_medest_sd if fqtr==4 & fyear>2005, d
pctile pct = sue3_medest_sd, nq(41) /*get 2.5% & 97.5%-quintile */
capture drop D_sue3_sd_extreme
gen D_sue3_sd_extreme = 0
replace D_sue3_sd_extreme = 1 if (sue3_medest_sd>=6.36 | sue3_medest_sd< -3.2) & sue3_medest_sd ~=.
replace D_sue3_sd_extreme = 1 if (sue3_medest_sd>=.42+2*14 | sue3_medest_sd< .42-2*14) & sue3_medest_sd ~=. /* 1 std */

areg dcamj bm size roa rety evol lvg c.med_dcamj##c.D_sue3_sd_extreme i.ff12 if fqtr==4 & fyear > 2005 , a( fyear) cl(cik_ds)
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop(i.ff12) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 
		
keep if fqtr==4 & fyear>2005
capture drop sd_sue_med_yr mean_sue_med_yr
bys fyear: egen sd_sue_med_yr = sd(sue3_medest)	
bys fyear: egen mean_sue_med_yr = mean(sue3_medest)	
capture drop D_sue3_extreme
gen D_sue3_extreme = 0
replace D_sue3_extreme = 1 if  abs(sue3_medest - mean_sue_med_yr) > 2*sd_sue_med_yr
		
reghdfe dcamj bm size roa rety evol lvg c.med_dcamj##c.D_sue3_extreme  if fqtr==4 & fyear > 2005 , a(ff12 fyear) cl(cik_ds)



/* 5%-quintile at firm-year level */	
capture drop pct	
egen pct = xtile(sue3_medest), by(fyear) n(20)
capture drop D_sue3_extreme
gen D_sue3_extreme = 0
replace D_sue3_extreme = 1 if (pct==1 | pct==20) 
	
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_sue3_extreme i.ff12 if fqtr==4 & fyear > 2005 , a( fyear) cl(cik_ds)
outreg2 using Earnings_surprise.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop(i.ff12) replace ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 

/* 10%-quintile */		
capture drop pct	
egen pct = xtile(sue3_medest), by(fyear) n(10)
capture drop D_sue3_extreme
gen D_sue3_extreme = 0
replace D_sue3_extreme = 1 if (pct==1 | pct==10) 
	
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_sue3_extreme i.ff12 if fqtr==4 & fyear > 2005 , a( fyear) cl(cik_ds)
outreg2 using Earnings_surprise.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop(i.ff12) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 
	
************ 4b-2. Examine whether reporting before vs after most peers affects impact of earnings surprise on contagion 
************ using DD accruals and Real earnings management instead of jones ****************
ren fyear fycompustat

merge m:1 cik fycompustat using aq_main.dta
drop if _merge ==2
drop _merge 

ren fycompustat fyear

areg std_DDdc  bm size roa rety evol lvg c.peermedstd_DDdc##c.D_sue3_extreme i.ff12 if fqtr==4 & fyear > 2005 , a( fyear) cl(cik_ds)

ren fyear fycompustat
merge m:m cik fycompustat using Abnrem, keepusing(AbnDisx AbnProd RM)
drop if _merge ==2
drop _merge 

merge m:1 cik fycompustat using peerrem
drop if _merge ==2
drop _merge 

ren fycompustat fyear	

areg RM  bm size roa rety evol lvg c.med_RM##c.D_sue3_extreme i.ff12 if fqtr==4 & fyear > 2005 , a( fyear) cl(cik_ds)
	
	
************ 4c. Examine whether reporting before vs after most peers affects impact of earnings surprise on contagion ***********
	
*** merge with reporting timing
ren fyear fycompustat
merge m:1 cik fycompustat using Relpeer_RD_pct 
drop if _merge == 2
drop _merge 
ren fycompustat fyear

areg dcamj bm size roa rety evol lvg c.med_dcamj##c.D_sue3_extreme i.ff12 if rd_late_pct == 0 & fqtr==4 & fyear > 2005 , a( fyear) cl(cik_ds)

sum rd_late_pct ,d 
capture drop d_rd_late
gen d_rd_late = 0 
replace d_rd_late = 1 if rd_late_pct >= .52

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_sue3_extreme i.ff12 if d_rd_late == 0 & fqtr==4 & fyear > 2005 , a( fyear) cl(cik_ds)
outreg2 using report_late.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop(i.ff12) replace ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 
	
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_sue3_extreme i.ff12 if d_rd_late == 1 & fqtr==4 & fyear > 2005 , a( fyear) cl(cik_ds)
outreg2 using report_late.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop(i.ff12) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_sue3_extreme c.med_dcamj##c.D_sue3_extreme##c.d_rd_late i.ff12 if   fqtr==4 & fyear > 2005 , a( fyear) cl(cik_ds)

outreg2 using report_late.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop(i.ff12) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 
		

		