/* This file computes the effect of peers' dam before and when the focal firm adopts RPE.
The peer list the focal firm used 1st when it adopts RPE is assumed as potential firms before it adopts RPE. 
We exclude peers using RPE as they might mimic the focal firm.
The peer list the focal firm used the last time before it quits RPE is assumed as potential firms after.
We get the potental peers and compute med dam before and after the focal firm adopts RPE and then merge them with data when the focal firm uses RPE.
If the contagion effect is through RPE, the coefficient on potential peers before the focal firm uses RPE should be insignificant.
But we find the coefficient is least significant only in the year before it uses RPE.
Restricting the year RPE firms adopt RPE after 2006 (SEC mandate year) does not help but reduce sample size.
*/


use peertopeer, clear

* get peers in the 1st year
sort cik fycompustat
by cik: gen peer_1styr = _n if _n==1
by cik fycompustat: carryforward peer_1styr, replace
gen RPE_begfyr = fycompustat if peer_1styr == 1
by cik: carryforward RPE_begfyr,replace

* get peers in last year
gsort cik - fycompustat peercik
by cik: gen peer_lastyr = _n if _n==1
sort cik fycompustat peercik
by cik fycompustat: carryforward peer_lastyr, replace
gen RPE_endfyr = fycompustat if peer_lastyr == 1
gsort cik - fycompustat peercik
by cik: carryforward RPE_endfyr,replace

sort cik fycompustat
keep if peer_1styr==1 | peer_lastyr == 1 /*keep only 1st and last year obs*/

drop if d_peerback == 1 | d_peerrpe == 1 /* drop peer using RPE  */

* expand to 1998-2016
gen str10 peercik0 = string(peercik,"%010.0f")
gen temp = cik + peercik0
encode temp, gen(temp0) 
tsset temp0 fycompustat
tsfill, full
by temp0: carryforward temp, replace
gsort temp0 -fycompustat
by temp0: carryforward temp, replace

gen cik_temp = substr(temp, 1,10)
gen peercik_temp = substr(temp,11,20)

replace cik = cik_temp if cik==""
drop peercik
gen peercik = peercik_temp 

gsort cik - fycompustat peercik
by cik: carryforward RPE_endfyr,replace
by cik: carryforward RPE_begfyr,replace

sort cik fycompustat peercik
by cik: carryforward RPE_begfyr, replace
by cik: carryforward RPE_endfyr,replace

* keep if RPE_begfyr > 2006 /*keep only RPE firms that adopt RPE after 2006 */

* get DAM for peers
drop cik
rename peercik_temp cik
rename fycompustat fyear
merge m:1 cik fyear using accruals.dta, keepusing(cadtatm1dechowetal_w dcajones1991_w dcajones1991int_w dcamodjones1991_w dcamodjones1991int_w)
drop cik
rename cik_temp cik
rename (cadtatm1dechowetal_w dcajones1991_w dcajones1991int_w dcamodjones1991_w dcamodjones1991int_w) (cadtatm1dechowetal_w_peers dcajones1991_w_peers dcajones1991int_w_peers dcamodjones1991_w_peers dcamodjones1991int_w_peers)
keep if _merge ~= 2
drop _merge

* get DAM for RPE firm 
merge m:1 cik fyear using accruals, keepusing(cadtatm1dechowetal dcajones1991 dcajones1991int dcamodjones1991 dcamodjones1991int)
rename (cadtatm1dechowetal dcajones1991 dcajones1991int dcamodjones1991 dcamodjones1991int) (cadta dcaj dcajint dcamj dcamjint)
keep if _merge ~= 2
drop _merge

* drop RPE period;
keep if fyear > RPE_endfyr | fyear < RPE_begfyr

* collapse 
collapse (median) med_cadta=cadtatm1dechowetal_w_peers med_dcaj=dcajones1991_w_peers med_dcajint=dcajones1991int_w_peers med_dcamj=dcamodjones1991_w_peers med_dcamjint=dcamodjones1991int_w_peers ///
(mean) avg_cadta=cadtatm1dechowetal_w avg_dcaj=dcajones1991_w_peers avg_dcajint=dcajones1991int_w_peers avg_dcamj=dcamodjones1991_w_peers avg_dcamjint=dcamodjones1991int_w_peers ///
, by(cik fyear cadta dcaj dcajint dcamj dcamjint RPE_begfyr RPE_endfyr)

* merge with other controls
merge 1:m cik fyear using indep
drop if _merge == 2
drop _merge
gen D_before = 1 if fyear < RPE_begfyr
gen D_after = 1 if fyear > RPE_endfyr
gen D_before_after = 1

* create ff12
ffind hsiccd, newvar(ff12) type(12)

* merge with industry accruals;
merge m:m ff12 fyear using ind_accruals
drop if _merge == 2
drop _merge

ren fyear fycompustat

save RPE_before_after.dta, replace

use RPE_before_after.dta, clear

append using main_w

merge 1:1 cik fycompustat using var_1st
drop if _merge ==2
drop _merge

encode cik,gen(cik_stata)
gen yind = fycompustat*100 + ff12
sort cik fycompustat

bys cik: carryforward RPE_begfyr,replace
gen Tr_yr = fycompustat - RPE_begfy /*years from adopting RPE*/

gen D_RPE = 0
replace D_RPE = 1 if Tr_yr >= 0

xtset cik_stata fycompustat
gen diff_dcamj = dcamj - l.dcamj
gen diff_bm = bm - l.bm
gen diff_size = size - l.size
gen diff_roa = roa - l.roa
gen diff_rety = rety - l.rety
gen diff_evol = evol - l.evol
gen diff_lvg = lvg - l.lvg
gen diff_med_dcamj = med_dcamj - l.med_dcamj

sort cik fycompustat
by cik: gen ddiff_dcamj = dcamj - dcamj[_n-2]
by cik: gen ddiff_bm = bm - bm[_n-2]
by cik: gen ddiff_size = size - size[_n-2]
by cik: gen ddiff_roa = roa - roa[_n-2]
by cik: gen ddiff_rety = rety - rety[_n-2]
by cik: gen ddiff_evol = evol - evol[_n-2]
by cik: gen ddiff_lvg = lvg - lvg[_n-2]
by cik: gen ddiff_med_dcamj = med_dcamj - med_dcamj[_n-2]

/* unbalanced did
areg dcamj bm size roa rety evol lvg  D_RPE##c.med_dcamj i.fycompustat if fycompustat>2005 & ((Tr_yr ==1) | Tr_yr ==-1), a(cik) cl(cik_stata)
outreg2 using Did_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		replace ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Firm+Year) 
*/

/* 		
* t+1 - (t-1)
reg ddiff_dcamj ddiff_bm ddiff_size ddiff_roa ddiff_rety ddiff_evol ddiff_lvg ddiff_med_dcamj if fycompustat>2005 & Tr_yr ==1,  vce(cl cik_stata)
outreg2 using Did_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		replace ctitle(Diff in Mod Jones Accruals) drop(i.fycompustat)  

areg ddiff_dcamj ddiff_bm ddiff_size ddiff_roa ddiff_rety ddiff_evol ddiff_lvg ddiff_med_dcamj if fycompustat>2005 & Tr_yr ==1, a(ff12) cl(cik_stata)
outreg2 using Did_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Diff in Mod Jones Accruals) drop(i.fycompustat)  

* balanced did
* get balanced list
preserve
egen nmiss1 = rowmiss(ddiff_dcamj ddiff_bm ddiff_size ddiff_roa ddiff_rety ddiff_evol ddiff_lvg ddiff_med_dcamj) 
keep if fycompustat>2005 & Tr_yr ==1 & nmiss1 == 0
keep cik fycompustat 
save cik_balanced_did,replace
restore 
preserve
use cik_balanced_did, clear
append using cik_balanced_did
sort cik fycompustat
bys cik: gen temp=_n
replace fycompustat = fycompustat - 2 if temp==1
drop temp
save cik_balanced_did, replace
restore

merge 1:1 cik fycompustat using cik_balanced_did 

areg dcamj bm size roa rety evol lvg  c.D_RPE##c.med_dcamj i.fycompustat if fycompustat>2005 & _merge == 3 & (Tr_yr ==-1 | Tr_yr ==1), a(cik) cl(cik_stata)
outreg2 using Did_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		replace ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Firm+Year) 

	
*/

gen yTryr = ff12*10000 + Tr_yr

gen D_b3 = 0
replace D_b3 = 1 if Tr_yr >= -3

gen D_b5 = 0
replace D_b5 = 1 if Tr_yr >= -5

gen D_b6 = 0
replace D_b6 = 1 if Tr_yr >= -6

areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 c.D_RPE##c.med_dcamj i.fycompustat if fycompustat>2005 & ((Tr_yr ==1) | Tr_yr ==-1), a(cik) cl(cik_stata)
outreg2 using Did_reg_med.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		replace ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Firm + Year, Sample, Treated) 
		
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 c.D_b3##c.med_dcamj i.fycompustat if fycompustat>2005 & ((Tr_yr ==-2) | Tr_yr ==-4), a(cik_stata) cl(cik_stata)
outreg2 using Did_reg_med.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Firm + Year, Sample, Counter-factual) 
		
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 c.D_b5##c.med_dcamj i.fycompustat if fycompustat>2005 & ((Tr_yr ==-4) | Tr_yr ==-6), a(cik_stata) cl(cik_stata)
outreg2 using Did_reg_med.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Firm + Year, Sample, Counter-factual) 
		
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 D_RPE##c.med_dcamj i.fycompustat i.yTryr if fycompustat>2005 & ((Tr_yr ==1) | Tr_yr ==-1), a(cik) cl(cik_stata)
outreg2 using Did_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat i.yTryr) addtext(FE, Firm + Year + Industry*Treatment year) 
		
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 D_b3##c.med_dcamj i.fycompustat i.yTryr if fycompustat>2005 & ((Tr_yr ==-2) | Tr_yr ==-4), a(cik) cl(cik_stata)
outreg2 using Did_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat i.yTryr) addtext(FE, Firm + Year + Industry*Treatment year) 

areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 D_b5##c.med_dcamj i.fycompustat i.yTryr if fycompustat>2005 & ((Tr_yr ==-6) | Tr_yr ==-4), a(cik) cl(cik_stata)
outreg2 using Did_reg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat i.yTryr) addtext(FE, Firm + Year + Industry*Treatment year) 

		
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 c.D_RPE##c.avg_dcamj i.fycompustat if fycompustat>2005 & ((Tr_yr ==1) | Tr_yr ==-1), a(cik) cl(cik_stata)
outreg2 using Did_reg_avg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		replace ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Firm + Year, Sample, Treated) 
		
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 c.D_b3##c.avg_dcamj i.fycompustat if fycompustat>2005 & ((Tr_yr ==-2) | Tr_yr ==-4), a(cik_stata) cl(cik_stata)
outreg2 using Did_reg_avg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Firm + Year, Sample, Counter-factual) 
		
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 c.D_b5##c.avg_dcamj i.fycompustat if fycompustat>2005 & ((Tr_yr ==-4) | Tr_yr ==-6), a(cik_stata) cl(cik_stata)
outreg2 using Did_reg_avg.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Firm + Year, Sample, Counter-factual) 
