
ssc inst outreg2

clear
set more off

// read data//
use "D:\Dropbox\RPE_EM\Codes and Data\main_w.dta" if fycompustat>2005, clear

//convert cik from char to num //
encode cik, gen(cik_stata)

//**** controlling for firm fixed effect *****//
xtset cik_stata fycompustat  //specify panel format

gen yind = fycompustat*100 + ff12
/* ind = contemporaneous avg of accruals, controlling for year and firm effect, clustered at firm level */
areg dcaj avg_dcaj bm_l size_l roa_l rety_l evol_l i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		replace ctitle(Jones Accruals) addtext(Year FE, YES, Firm FE, NO, Industry FE, Yes) 

areg dcajint avg_dcajint bm_l size_l roa_l rety_l evol_l i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Jones Accruals with int) addtext(Year FE, YES, Firm FE, NO, Industry FE, Yes)

areg dcamj avg_dcamj bm_l size_l roa_l rety_l evol_l i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		 append ctitle(Mod Jones Accruals) addtext(Year FE, YES, Firm FE, NO, Industry FE, Yes) 

areg dcamjint avg_dcamjint bm_l size_l roa_l rety_l evol_l i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		 append ctitle(Mod Jones Accruals with int) addtext(Year FE, YES, Firm FE, NO, Industry FE, Yes)

/* ind = contemporaneous median accruals, controlling for year and firm effect, clustered at firm level */		
areg dcaj med_dcaj bm_l size_l roa_l rety_l evol_l i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		 append ctitle(Jones Accruals ) addtext(Year FE, YES, Firm FE, NO, Industry FE, Yes)

areg dcajint med_dcajint  bm_l size_l roa_l rety_l evol_l i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		 append ctitle(Jones Accruals  with int) addtext(Year FE, YES, Firm FE, NO, Industry FE, Yes)

areg dcamj med_dcamj bm_l size_l roa_l rety_l evol_l i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year FE, YES, Firm FE, NO, Industry FE, Yes)

areg dcamjint med_dcamjint bm_l size_l roa_l rety_l evol_l i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		 append ctitle(Mod Jones Accruals  with int) addtext(Year FE, YES, Firm FE, NO, Industry FE, Yes)

		 
		 
		 
		 
/****/




areg dcamj avg_dcamj bm_l size_l roa_l rety_l evol_l i.fycompustat, a(cik_stata) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults2.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		replace ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, YES, Year & Industry FE, NO, Year*Industry FE, NO)
		 
areg dcamj med_dcamj bm_l size_l roa_l rety_l evol_l i.fycompustat, a(cik_stata) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults2.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, YES, Year & Industry FE, NO, Year*Industry FE, NO)
		 		 
areg dcamj avg_dcamj bm_l size_l roa_l rety_l evol_l i.fycompustat, a(yind) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults2.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, NO, Year*Industry FE, YES)
		 
areg dcamj med_dcamj bm_l size_l roa_l rety_l evol_l i.fycompustat, a(yind) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults2.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, NO, Year*Industry FE, YES)	 


areg dcamj avg_dcamj avg_dcamj_ff12 bm_l size_l roa_l rety_l evol_l i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults2.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, YES, Year*Industry FE, NO)
		 
areg dcamj med_dcamj med_dcamj_ff12 bm_l size_l roa_l rety_l evol_l i.fycompustat, a(ff12) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults2.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, YES, Year*Industry FE, NO)	 

	 
		 
/**********/
gen drpe35 = 0
replace drpe35 = 1 if rpepct >0.35

gen drpe50 = 0
replace drpe50 = 1 if rpepct >0.50

gen dacct35 = 0
replace dacct35 = 1 if accountingpct>0.35

gen dacct50 = 0
replace dacct50 = 1 if accountingpct>=0.50

gen dacct100 = 0
replace dacct100 = 1 if accountingpct>=1


gen logrpepct = log(rpepct)
gen logacctpct = log(accountingpct+0.00000000001)
gen logacctpct2 = log(accountingpct_ew+0.00000000001)


areg dcamj c.avg_dcamj##c.logrpepct bm_l size_l roa_l rety_l evol_l , a(yind) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults3.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		replace ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, NO, Year*Industry FE, YES)
		 
areg dcamj c.med_dcamj##c.logrpepct bm_l size_l roa_l rety_l evol_l, a(yind) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults3.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, NO, Year*Industry FE, YES)	 		 
		 
		 
areg dcamj c.avg_dcamj##c.drpe35 bm_l size_l roa_l rety_l evol_l , a(yind) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults3.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, NO, Year*Industry FE, YES)
		 
areg dcamj c.med_dcamj##c.drpe35 bm_l size_l roa_l rety_l evol_l, a(yind) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults3.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, NO, Year*Industry FE, YES)	 		 
		 
	 
		 
areg dcamj c.avg_dcamj##c.logacctpct bm_l size_l roa_l rety_l evol_l , a(yind) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults3.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, NO, Year*Industry FE, YES)
		 
areg dcamj c.med_dcamj##c.logacctpct bm_l size_l roa_l rety_l evol_l, a(yind) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults3.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, NO, Year*Industry FE, YES)	 		 
		 	 

		 
areg dcamj c.avg_dcamj##c.dacct50 bm_l size_l roa_l rety_l evol_l , a(yind) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults3.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, NO, Year*Industry FE, YES)
		 
areg dcamj c.med_dcamj##c.dacct50 bm_l size_l roa_l rety_l evol_l, a(yind) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults3.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, NO, Year*Industry FE, YES)		


areg dcamj c.avg_dcamj##c.n_peers bm_l size_l roa_l rety_l evol_l , a(yind) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults3.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, NO, Year*Industry FE, YES)
		 
areg dcamj c.med_dcamj##c.n_peers bm_l size_l roa_l rety_l evol_l, a(yind) cl(cik_stata) 
outreg2 using "D:\Dropbox\RPE_EM\Analysis Results\RegResults3.xls", alpha(0.001, 0.01, 0.05) symbol(***, **, *)         ///
		append ctitle(Mod Jones Accruals ) addtext(Year & Firm FE, NO, Year & Industry FE, NO, Year*Industry FE, YES)		
		
		