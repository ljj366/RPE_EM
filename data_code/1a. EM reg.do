ssc inst outreg2

clear
set more off

estimates table, star(.1 .05 .01) // change default star //

// read data//
cd "E:\Research\WB\RPE_EM\data_code"
use main_w.dta if fycompustat>2005, clear

encode cik, gen(cik_stata) //convert cik from char to num //

xtset cik_stata fycompustat  //specify panel format
gen yind = fycompustat*100 + ff12
		
//**** ind = contemporaneous avg of accruals, BM, SIZE, ROA, ANNUAL RET, EARNINGS VOLATILITY, clustered at firm level */
/* Alterative EM of controlling for Industry*Year FE */
/*
/* avg EM */
areg dcaj bm size roa rety evol lvg avg_dcaj , a(yind) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( avg_dcaj bm size roa rety evol lvg ) replace ctitle(Jones Accruals) addtext(FE, Industry*Year) 

areg dcajint bm size roa rety evol lvg avg_dcajint , a(yind) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( avg_dcajint bm size roa rety evol lvg ) append ctitle(Jones Accruals with int) addtext(FE, Industry*Year)  

areg dcamj bm size roa rety evol lvg avg_dcamj , a(yind) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( avg_dcamj bm size roa rety evol lvg ) append ctitle(Mod Jones Accruals) addtext(FE, Industry*Year)  

areg dcamjint bm size roa rety evol lvg  avg_dcamjint , a(yind) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( avg_dcamjint bm size roa rety evol lvg ) append ctitle(Mod Jones Accruals with int) addtext(FE, Industry*Year)  

/* Med EM */		
areg dcaj bm size roa rety evol lvg med_dcaj , a(yind) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( med_dcaj bm size roa rety evol lvg ) append ctitle(Jones Accruals) addtext(FE, Industry*Year) 

areg dcajint bm size roa rety evol lvg med_dcajint , a(yind) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( med_dcajint bm size roa rety evol lvg ) append ctitle(Jones Accruals with int) addtext(FE, Industry*Year)  

areg dcamj bm size roa rety evol lvg med_dcamj , a(yind) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( med_dcamj bm size roa rety evol lvg ) append ctitle(Mod Jones Accruals) addtext(FE, Industry*Year)  

areg dcamjint bm size roa rety evol lvg med_dcamjint, a(yind) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( med_dcamjint bm size roa rety evol lvg ) append ctitle(Mod Jones Accruals with int) addtext(FE, Industry*Year) 		


/* controlling for Industry + Year FE */
/* avg EM */
areg dcaj bm size roa rety evol lvg avg_dcaj i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( avg_dcaj bm size roa rety evol lvg ) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 

areg dcajint bm size roa rety evol lvg avg_dcajint i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( avg_dcajint bm size roa rety evol lvg ) append ctitle(Jones Accruals with int) addtext(FE, Industry+Year)  

areg dcamj bm size roa rety evol lvg avg_dcamj i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( avg_dcamj bm size roa rety evol lvg ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg dcamjint bm size roa rety evol lvg  avg_dcamjint i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( avg_dcamjint bm size roa rety evol lvg ) append ctitle(Mod Jones Accruals with int) addtext(FE, Industry+Year)  

/* Med EM */		
areg dcaj bm size roa rety evol lvg med_dcaj i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( med_dcaj bm size roa rety evol lvg ) append ctitle(Jones Accruals) addtext(FE, Industry+Year) 

areg dcajint bm size roa rety evol lvg med_dcajint i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( med_dcajint bm size roa rety evol lvg ) append ctitle(Jones Accruals with int) addtext(FE, Industry+Year)  

areg dcamj bm size roa rety evol lvg med_dcamj i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( med_dcamj bm size roa rety evol lvg ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg dcamjint bm size roa rety evol lvg med_dcamjint i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( med_dcamjint bm size roa rety evol lvg ) append ctitle(Mod Jones Accruals with int) addtext(FE, Industry+Year) 		
		
		
/* controlling for Firm + Year FE */
/* avg EM */
areg dcaj bm size roa rety evol lvg avg_dcaj i.fycompustat, a(cik) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( avg_dcaj bm size roa rety evol lvg ) append ctitle(Jones Accruals) addtext(FE, Firm+Year) 

areg dcajint bm size roa rety evol lvg avg_dcajint i.fycompustat, a(cik) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( avg_dcajint bm size roa rety evol lvg ) append ctitle(Jones Accruals with int) addtext(FE, Firm+Year)  

areg dcamj bm size roa rety evol lvg avg_dcamj i.fycompustat, a(cik) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( avg_dcamj bm size roa rety evol lvg ) append ctitle(Mod Jones Accruals) addtext(FE, Firm+Year)  

areg dcamjint bm size roa rety evol lvg  avg_dcamjint i.fycompustat, a(cik) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( avg_dcamjint bm size roa rety evol lvg ) append ctitle(Mod Jones Accruals with int) addtext(FE, Firm+Year)  

/* Med EM */		
areg dcaj bm size roa rety evol lvg med_dcaj i.fycompustat, a(cik) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( med_dcaj bm size roa rety evol lvg ) append ctitle(Jones Accruals) addtext(FE, Firm+Year) 

areg dcajint bm size roa rety evol lvg med_dcajint i.fycompustat, a(cik) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( med_dcajint bm size roa rety evol lvg ) append ctitle(Jones Accruals with int) addtext(FE, Firm+Year)  

areg dcamj bm size roa rety evol lvg med_dcamj i.fycompustat, a(cik) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( med_dcamj bm size roa rety evol lvg ) append ctitle(Mod Jones Accruals) addtext(FE, Firm+Year)  

areg dcamjint bm size roa rety evol lvg med_dcamjint  i.fycompustat, a(cik) cl(cik_stata) 
outreg2 using Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( med_dcamjint bm size roa rety evol lvg ) append ctitle(Mod Jones Accruals with int) addtext(FE, Firm+Year) 			
*/

		
/*************** Focus on Modified Jones Measure without Int  ***********************************/

* median em;

areg dcamj bm size roa rety evol lvg med_dcamj i.fycompustat if D_accounting==1, a(ff12) cl(cik_stata) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
	   keep( bm size roa rety evol lvg med_dcamj ) replace ctitle(Mod Jones Accruals) addtext(FE, Firm+Year)  

areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_ff12 i.fycompustat if D_accounting==1, a(ff12) cl(cik_stata) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
	   keep( bm size roa rety evol lvg med_dcamj med_dcamj_ff12) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg dcamj bm size roa rety evol lvg med_dcamj i.fycompustat if D_accounting==1, a(cik_stata) cl(cik_stata) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
	   keep( bm size roa rety evol lvg med_dcamj ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg dcamj bm size roa rety evol lvg med_dcamj if D_accounting==1, a(yind) cl(cik_stata) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
	   keep( bm size roa rety evol lvg med_dcamj ) append ctitle(Mod Jones Accruals) addtext(FE, Industry*Year)  

* Firm+Year FE
areg dcamj bm size roa rety evol lvg med_dcamj i.fycompustat, a(cik_stata) cl(cik_stata) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
	   keep( bm size roa rety evol lvg med_dcamj ) replace ctitle(Mod Jones Accruals) addtext(FE, Firm+Year)  
	   
areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_ff12 i.fycompustat, a(cik_stata) cl(cik_stata) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg med_dcamj med_dcamj_ff12) append ctitle(Mod Jones Accruals ) addtext(FE, Firm+Year)  
						
* Industry+Year FE
areg dcamj bm size roa rety evol lvg med_dcamj i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg med_dcamj ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  
		
areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_ff12 i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( bm size roa rety evol lvg med_dcamj med_dcamj_ff12) append ctitle(Mod Jones Accruals ) addtext(FE, Industry+Year) 	
		
* Industry*Year FE
areg dcamj bm size roa rety evol lvg med_dcamj , a(yind) cl(cik_stata) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg med_dcamj ) append ctitle(Mod Jones Accruals) addtext(FE, Industry*Year)  

		
/* use avg peer accruals*/	
* firm+year
areg dcamj bm size roa rety evol lvg avg_dcamj i.fycompustat, a(cik_stata) cl(cik_stata) 
outreg2 using avg_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) replace ctitle(Mod Jones Accruals) addtext(FE, Firm+Year)  

* industry + year
areg dcamj bm size roa rety evol lvg avg_dcamj i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using avg_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

* industry * year
areg dcamj bm size roa rety evol lvg avg_dcamj , a(yind) cl(cik_stata) 
outreg2 using avg_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry*Year)  

* firm + industry*year
areg dcamj bm size roa rety evol lvg avg_dcamj i.yind, a(cik_stata) cl(cik_stata) 
outreg2 using avg_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.yind ) append ctitle(Mod Jones Accruals) addtext(FE, Firm + Industry*Year)  

		
/** add industry EM;
industry*year FE absorbed when controlling for industry em;
*/
/* avg em; 
areg dcamj bm size roa rety evol lvg avg_dcamj avg_dcamj_ff12 i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using D:\RPE\RPE_EM\data_code\RegResults2.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg avg_dcamj avg_dcamj_ff12) replace ctitle(Mod Jones Accruals ) addtext(FE, Industry+Year) 


areg dcamj bm size roa rety evol lvg avg_dcamj avg_dcamj_ff12 i.fycompustat, a(cik_stata) cl(cik_stata) 
outreg2 using D:\RPE\RPE_EM\data_code\RegResults2.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)        ///
		keep( bm size roa rety evol lvg avg_dcamj avg_dcamj_ff12) append ctitle(Mod Jones Accruals ) addtext(FE, Firm+Year) 
*/		

/* add accruals of firms not RPE or peers */
merge m:1 fycompustat using accruals_non_rpe_peer		
drop _merge

areg dcamj bm size roa rety evol lvg med_dcamj_non_rpe_peer i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg med_dcamj_non_rpe_peer ) replace ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_non_rpe_peer i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg med_dcamj med_dcamj_non_rpe_peer) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg dcamj bm size roa rety evol lvg med_dcamj med_dcamj_ff12 med_dcamj_non_rpe_peer i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using temp.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg med_dcamj med_dcamj_ff12 med_dcamj_non_rpe_peer) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  
		
		
		

/* add rpepct among grants*/
/*
drop rpepct
merge 1:1 cik fycompustat using rpepct, keepusing (rpepct ceorpepct)
drop if _merge ==2
drop _merge
*/

sum rpepct,d 
capture drop d_rpepct
gen d_rpepct = 0
replace d_rpepct = 1 if rpepct > .079 /*5%*/

/*
sum ceorpepct, d
capture drop d_rpepct
gen d_rpepct = 0
replace d_rpepct = 1 if ceorpepct >= .25 /* 95% */
*/
	
* med;

areg dcamj bm size roa rety evol lvg c.med_dcamj##c.d_rpepct i.ff12, a(fycompustat) cl(cik_stata) 
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg c.med_dcamj##c.d_rpepct ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 

		* add nb of peers;
/*
areg dcamj bm size roa rety evol lvg c.avg_dcamj##c.n_peers, a(yind) cl(cik_stata) 
outreg2 using D:\RPE\RPE_EM\data_code\RegResults3.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(FE, Industry*Year) 
*/

sum n_peers, d		
capture drop D_n_peers
gen D_n_peers = 0
replace D_n_peers = 1 if n_peers >= 30 /*95% percentile, or 30*/
		
areg dcamj bm size roa rety evol lvg c.med_dcamj##c.D_n_peers i.ff12, a( fycompustat) cl(cik_stata) 
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep( bm size roa rety evol lvg c.med_dcamj##c.D_n_peers) append ctitle(Number of peers) addtext(FE, Industry+Year) 

		
		
* add max target goal
use main_w,clear
encode cik, gen(cik_stata) 

merge 1:1 cik fycompustat using relpeeremP75
keep if _merge ~= 2		
drop _merge	

merge m:1 cik fycompustat using D_target
keep if _merge ~= 2		
drop _merge		
sum target, d

gen target2 = target 
replace target2 = 0 if target < 0 
replace target2 = 1 if target >1 

sum target2, d
capture drop d_target
gen d_target = .
replace d_target = 0 if  target2 < .75 & target ~=.
replace d_target = 1 if target2 >=.75 & target ~=.

tab d_target

gen med_dcamj2 = med_dcamj
replace med_dcamj2 = dcamodjones1991_w_p75 if d_target == 1	

areg dcamj bm size roa rety evol lvg med_dcamj c.med_dcamj#c.target2 i.fycompustat if fycompustat>2005, a(ff12) cl(cik_stata) 		
outreg2 using F:\Research\WB\RPE_EM\data_code\Reg_diffEMs.xls, alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) replace ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 
		
areg dcamj bm size roa rety evol lvg med_dcamj c.med_dcamj#c.d_target i.fycompustat if fycompustat>2005, a(ff12) cl(cik_stata) 

areg dcamj c.d_target##c.(bm size roa rety evol lvg med_dcamj) i.fycompustat if fycompustat>2005, a(ff12) cl(cik_stata) 

areg dcamj bm size roa rety evol lvg med_dcamj c.med_dcamj i.fycompustat if fycompustat>2005 & d_target==0, a(ff12) cl(cik_stata) 
areg dcamj bm size roa rety evol lvg med_dcamj c.med_dcamj i.fycompustat if fycompustat>2005 & d_target==1, a(ff12) cl(cik_stata) 

		
areg dcamj bm size roa rety evol lvg med_dcamj2 c.med_dcamj2#c.d_target i.fycompustat if fycompustat>2005, a(ff12) cl(cik_stata) 
		
areg dcamj d_target##c.(bm size roa rety evol lvg med_dcamj2) i.fycompustat if fycompustat>2005, a(ff12) cl(cik_stata) 
	
preserve
bys cik: gen n=_n 
keep if n==1 & nmiss==0 & target < 0
keep cik fycompustat target
save Abtarget 
restore
		
* add accountingpct;
capture drop D_accounting
gen D_accounting = 0
replace D_accounting = 1 if accountingpct >0

areg dcamj bm size roa rety evol lvg c.med_dcamj i.fycompustat if D_accounting == 0, a(ff12) cl(cik_stata)
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep (bm size roa rety evol lvg c.med_dcamj) replace ctitle(Mod Jones Accruals) addtext(FE, Industry+Year, Sample, Price metrics) 
areg dcamj bm size roa rety evol lvg c.med_dcamj i.fycompustat if D_accounting == 1, a(ff12) cl(cik_stata)
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		keep (bm size roa rety evol lvg c.med_dcamj) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year, Sample, Accounting metrics) 		

		areg dcamj bm size roa rety evol lvg med_dcamj c.med_dcamj#c.D_accounting i.fycompustat, a(ff12) cl(cik_stata)
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop(i.fycompustat) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year, Sample, Full) 				
		
areg dcamj bm size roa rety evol lvg c.med_dcamj##c.D_accounting i.fycompustat, a(ff12) cl(cik_stata)
		
		
capture drop D_accounting
gen D_accounting = 0
replace D_accounting = .5 if accountingpct >0
replace D_accounting = 1 if accountingpct == 1

tab D_accounting
areg dcamj bm size roa rety evol lvg c.med_dcamj i.fycompustat if D_accounting == 0, a(ff12) cl(cik_stata)

areg dcamj bm size roa rety evol lvg c.med_dcamj i.fycompustat if D_accounting == .5, a(ff12) cl(cik_stata)

areg dcamj bm size roa rety evol lvg c.med_dcamj i.fycompustat if D_accounting == 1, a(ff12) cl(cik_stata)

		
		
** firms using S&P 500 benchmark;		
use indexbench, clear

ffind hsiccd, newvar(ff12) type(12)
merge m:1 ff12 fyear using ind_accruals
drop if _merge == 2

ren dcamodjones1991 dcamj
gen D_sp500 = 1
gen yind = fycompustat*100 + ff12

append using main_w
replace D_sp500 = 0 if D_sp500 == .

		
* med industry dam has a higher average than med peer dam and is fully absorbed when controlling for industry*year FE.		
areg dcamj bm size roa rety evol lvg  c.med_dcamj i.fycompustat  if D_sp500==1 & fycompustat > 2005, a(ff12) cl(cik)
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		replace ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year, Sample, Benchmark is S&P500 index) 
		
areg dcamj bm size roa rety evol lvg avg_dcamj i.fycompustat  if D_sp500==1 & fycompustat > 2005, a(ff12) cl(cik)		
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year, Sample, Benchmark is S&P500 index) 

areg dcamj bm size roa rety evol lvg  c.wt_mc_dcamj i.fycompustat  if D_sp500==1 & fycompustat > 2005, a(ff12) cl(cik)		
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year, Sample, Benchmark is S&P500 index) 

areg dcamj bm size roa rety evol lvg  c.wt_at_dcamj i.fycompustat  if D_sp500==1 & fycompustat > 2005, a(ff12) cl(cik)		
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year, Sample, Benchmark is S&P500 index) 
	
areg dcamj bm size roa rety evol lvg  sd_med_dcamj i.fycompustat  if D_sp500==1 & fycompustat > 2005, a(ff12) cl(cik)
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year, Sample, Benchmark is S&P500 index) 
		
areg dcamj bm size roa rety evol lvg sd_avg_dcamj i.fycompustat  if D_sp500==1 & fycompustat > 2005, a(ff12) cl(cik)		
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year, Sample, Benchmark is S&P500 index) 

areg dcamj bm size roa rety evol lvg  sd_wt_mc_dcamj i.fycompustat  if D_sp500==1 & fycompustat > 2005, a(ff12) cl(cik)		
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year, Sample, Benchmark is S&P500 index) 
		
areg dcamj bm size roa rety evol lvg  sd_wt_at_dcamj i.fycompustat  if D_sp500==1 & fycompustat > 2005, a(ff12) cl(cik)		
outreg2 using RegResults3.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year, Sample, Benchmark is S&P500 index) 
		
			
* add pct_peerback ; 	
merge 1:1 cik fycompustat using pct_peerback.dta /* all obs from master are merged */
keep if _merge ~= 2 /* drop RPE firms that are not in the master file */
drop _merge

gen lnpct_peerback = ln(1+pct_peerback)
areg dcamj bm size roa rety evol lvg c.avg_dcamj##c.lnpct_peerback, a(yind) cl(cik_stata) 

areg dcamj bm size roa rety evol lvg c.med_dcamj##c.lnpct_peerback, a(yind) cl(cik_stata) 


* add pct_peer using RPE; 	
merge 1:1 cik fycompustat using D:\RPE\RPE_EM\data_code\pct_peerRPE.dta /* all obs from master are merged */
keep if _merge == 3
drop _merge

gen lnpct_peerrpe = log(1+pct_peerrpe)
areg dcamj bm size roa rety evol lvg c.avg_dcamj##c.lnpct_peerrpe, a(yind) cl(cik_stata) 

areg dcamj bm size roa rety evol lvg c.med_dcamj##c.lnpct_peerrpe, a(yind) cl(cik_stata) 





/******************************************************************************************
*******************************************************************************************
*****   Regressions with controls from 1st stage  ********************
********************************************************************************************
******************************************************************************************/

use main_w.dta if fycompustat>2005, clear

encode cik, gen(cik_stata) //convert cik from char to num //

xtset cik_stata fycompustat  //specify panel format
gen yind = fycompustat*100 + ff12

merge 1:1 cik fycompustat using rpe_var_1st
drop if _merge ==2
drop _merge


/****** use avg peer accruals, main reg *******/	
* industry + year
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg avg_dcamj i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using avg_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) replace ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 avg_dcamj avg_dcamj_ff12 i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using avg_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  
		
* industry * year
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 avg_dcamj, a(yind) cl(cik_stata) 
outreg2 using avg_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat) append ctitle(Mod Jones Accruals) addtext(FE, Industry*Year)  

* firm+year
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 avg_dcamj i.fycompustat, a(cik_stata) cl(cik_stata) 
outreg2 using avg_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Firm+Year)  

* firm + industry*year
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 avg_dcamj i.yind, a(cik_stata) cl(cik_stata) 
outreg2 using avg_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.yind ) append ctitle(Mod Jones Accruals) addtext(FE, Firm + Industry*Year)  

 
/****** use med peer accruals, main reg - table 4*******/	
* industry + year
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 med_dcamj i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using med_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) replace ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 med_dcamj med_dcamj_ff12 i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using med_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  
		
* industry * year
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 med_dcamj, a(yind) cl(cik_stata) 
outreg2 using med_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat) append ctitle(Mod Jones Accruals) addtext(FE, Industry*Year)  

* firm+year
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 med_dcamj i.fycompustat, a(cik_stata) cl(cik_stata) 
outreg2 using med_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Firm+Year)  

* firm + industry*year
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 med_dcamj i.yind, a(cik_stata) cl(cik_stata) 
outreg2 using med_da.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.yind ) append ctitle(Mod Jones Accruals) addtext(FE, Firm + Industry*Year)  


		
		
		
		
		

/****** cross-sectional variations*******/	

/* RPE pct */
sum rpepct,d 
capture drop d_rpepct
gen d_rpepct = 0
replace d_rpepct = 1 if rpepct > .079 /*5%*/

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.d_rpepct i.ff12, a(fycompustat) cl(cik_stata) 
outreg2 using cross_sec_var.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.ff12 ) replace ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 
	
/* add min target goal of all RPE grants */
merge m:1 cik fycompustat using D_target
keep if _merge ~= 2		
drop _merge		
sum target, d

* winsorize target 
gen target2 = target if target ~=.
replace target2 = 0 if target < 0  & target ~=.
replace target2 = 1 if target >1 & target ~=.

sum target2, d
capture drop d_target
gen d_target = 0 if target2~=.
replace d_target = 1 if target2~=. & target2 >= .5 /*median*/

areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 med_dcamj c.med_dcamj##c.target2 i.fycompustat if fycompustat>2005, a(ff12) cl(cik_stata) 		
outreg2 using cross_sec_var.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 
	
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.d_target i.fycompustat if fycompustat>2005, a(ff12) cl(cik_stata) 		
outreg2 using cross_sec_var.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 


/* add nb of peers; */
sum n_peers, d		
capture drop D_n_peers
gen D_n_peers = 0
replace D_n_peers = 1 if n_peers >= 30 /*95% percentile, or 30*/
		
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 c.med_dcamj##c.D_n_peers i.ff12, a( fycompustat) cl(cik_stata) 
outreg2 using cross_sec_var.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.ff12 ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 
	

/** accounting metrics **/	
sum accountingpct, d
capture drop D_accounting
gen D_accounting = 0
replace D_accounting = 1 if accountingpct >0

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj i.fycompustat if D_accounting==1, a(ff12) cl(cik_stata) 
outreg2 using acc.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
	   drop(i.fycompustat) replace ctitle(Mod Jones Accruals) addtext(FE, Firm+Year)  

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj med_dcamj_ff12 i.fycompustat if D_accounting==1, a(ff12) cl(cik_stata) 
outreg2 using acc.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
	   drop(i.fycompustat) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj i.fycompustat if D_accounting==1, a(cik_stata) cl(cik_stata) 
outreg2 using acc.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
	   drop(i.fycompustat) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year)  

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj if D_accounting==1, a(yind) cl(cik_stata) 
outreg2 using acc.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
	   drop(i.fycompustat) append ctitle(Mod Jones Accruals) addtext(FE, Industry*Year)  
	
capture drop D_accounting
gen D_accounting = 0
replace D_accounting = .5 if accountingpct >0
replace D_accounting = 1 if accountingpct == 1

tab D_accounting
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj i.fycompustat if D_accounting == 0, a(ff12) cl(cik_stata)

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj i.fycompustat if D_accounting == .5, a(ff12) cl(cik_stata)

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj i.fycompustat if D_accounting == 1, a(ff12) cl(cik_stata)
	
	
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_accounting i.fycompustat if D_accounting ~= 0.5, a(ff12) cl(cik_stata)

egen nmiss = rowmiss(dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj D_accounting)

set seed 26
capture drop r d_r
gen r = runiform() 
replace r = 2 if D_accounting == 1
sort nmiss r 
gen d_r = (_n <= 255)  // 255 is nb of firms using accounting

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_accounting i.fycompustat if d_r==1 | r==2, a(ff12) cl(cik_stata)
outreg2 using acc.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) replace ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 


save "E:\Research\WB\RPE_EM\data_code\Accounting_Price_1to1"
	
	
	
	
		
** firms using S&P 500 benchmark; med_dcamj	varies at the year level since all firms benchmark s&p 500 index.
use indexbench, clear 

ffind hsiccd, newvar(ff12) type(12)
merge m:1 ff12 fyear using ind_accruals
drop if _merge == 2
drop _merge

ren dcamodjones1991 dcamj
gen D_sp500 = 1
gen yind = fycompustat*100 + ff12

merge 1:m cik fycompustat using var_1st
drop if _merge==2
drop _merge 

* med_dcamj is at year level, colinear with year FE
areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 c.med_dcamj i.fycompustat  if fycompustat > 2005, a(ff12) cl(cik)		
outreg2 using index_benchmark.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 

areg dcamj bm size roa rety evol lvg attm1inverse chgsaledattm1 ppegtdattm1 avg_dcamj i.fycompustat  if D_sp500==1 & fycompustat > 2005, a(ff12) cl(cik)		
outreg2 using index_benchmark.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year) 

areg dcamj bm size roa rety evol lvg  attm1inverse chgsaledattm1 ppegtdattm1 c.wt_mc_dcamj i.fycompustat  if D_sp500==1 & fycompustat > 2005, a(ff12) cl(cik)		
outreg2 using index_benchmark.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year) 

	
	
	
********* lagged dam    ******
sort cik_stata fycompustat 
gen abs_dcamj_l1 = abs(l.dcamj)
gen abs_dcamj_l2 = (abs(l.l.dcamj) + abs(l.dcamj))/2
	
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.abs_dcamj_l2 i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using eps_ldam.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		replace ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year) 
	
	
	
********* conditional on EPS ******
preserve
use eps, clear
ren cik peercik
ren eps peer_eps
ren epsfi peer_epsfi
ren epsfx peer_epsfx
ren epspi peer_epspi
ren epspx peer_epspx

ren eps_gr peer_eps_gr

keep if peercik ~= ""
ren fyear fycompustat

merge 1:m peercik fycompustat using peerlist.dta
drop if _merge ==1
drop _merge

collapse (median) peer_eps peer_epsfi peer_epsfx peer_epspi peer_epspx peer_eps_gr,by(cik fycompustat)

save temp, replace
restore

* get RPE firm's EPS
ren fycompustat fyear

merge 1:m cik fyear using eps, keepusing(eps epsfi epsfx epspi epspx eps_gr)
drop if _merge ==2
drop _merge

* merge with peers' median EPS
ren fyear fycompustat
merge 1:1 cik fycompustat using temp
drop if _merge ==2
drop _merge

gen abs_eps_diff = abs(eps-peer_eps)
sum abs_eps_diff,d
winsor2 abs_eps_diff, cuts(1 99) suffix(_w)

gen abs_epsfi_diff = abs(epsfi-peer_epsfi)
sum abs_epsfi_diff,d
winsor2 abs_epsfi_diff, cuts(1 99) suffix(_w)

gen abs_eps_gr_diff = abs(eps_gr-peer_eps_gr)
sum abs_eps_gr_diff,d

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.abs_eps_diff_w i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using eps_ldam.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year) 
				
				
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.abs_eps_gr_diff i.fycompustat, a(ff12) cl(cik_stata) 
	
		
egen  pct_eps = xtile(abs_eps_diff), by(fycompustat) nq(2)
gen d_5_eps = 0 if pct_eps ==1 & pct_eps ~=.
replace d_5_eps = 1 if pct_eps == 2 & pct_eps ~=.

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_5_eps##c.med_dcamj i.fycompustat if fycompustat>2005, a(ff12) cl(cik) 
outreg2 using eps_ldam.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year) 
	

egen  pct_eps_gr = xtile(abs_eps_gr_diff), by(fycompustat) nq(2)
gen d_5_eps_gr = 0 if pct_eps_gr ~=. & pct_eps_gr == 1
replace d_5_eps_gr = 1 if pct_eps_gr ~=. & pct_eps_gr == 2

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_25_eps##c.med_dcamj i.fycompustat if fycompustat>2005, a(ff12) cl(cik) 
outreg2 using eps_ldam.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_5_eps_gr##c.med_dcamj i.fycompustat if fycompustat>2005, a(ff12) cl(cik) 
outreg2 using eps_ldam.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.d_75_eps##c.med_dcamj i.fycompustat if fycompustat>2005, a(ff12) cl(cik) 
outreg2 using eps_ldam.xls, dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals) drop(i.fycompustat) addtext(FE, Industry+Year) 

		
********* conditional on ret ******
preserve
use indep, clear
ren cik peercik
ren roa peerroa
ren rety peerrety

keep if peercik ~= ""
ren fyear fycompustat

merge 1:m peercik fycompustat using peerlist.dta
drop if _merge ==1
drop _merge

collapse (median) peerroa peerrety, by(cik fycompustat)

save temp, replace
restore

* merge with peers' median rety
merge 1:1 cik fycompustat using temp
drop if _merge ==2
drop _merge

gen abs_roa_diff = abs(roa-peerroa)

gen abs_rety_diff = abs(rety-peerrety)


areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.abs_roa_diff i.fycompustat, a(ff12) cl(cik_stata) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.abs_rety_diff i.fycompustat, a(ff12) cl(cik_stata) 


egen  pct_rety = xtile(abs_rety_diff), by(fycompustat) nq(4)
gen d_5_rety = 0 if pct_rety ==1 & pct_rety ~=.
replace d_5_rety = 1 if pct_rety == 2 & pct_rety ~=.


areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.pct_rety i.fycompustat, a(ff12) cl(cik_stata) 


		