use "E:\Research\WB\RPE_EM\data_code\rpegrant.dta" ,clear

ren *, lower

merge m:1 cik fycompustat using main_w

keep if _merge == 3
drop _merge


merge m:1 cik fycompustat using rpe_var_1st
keep if _merge == 3
drop _merge

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj i.fycompustat if metrictype == "Accounting", a(ff12) cl(cik)

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj i.fycompustat if metrictype == "Stock Price", a(ff12) cl(cik)


capture drop D_acc
gen D_acc = 0 if metrictype == "Stock Price" 
replace D_acc = 1 if metrictype == "Accounting"

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_acc i.fycompustat, a(ff12) cl(cik) 
outreg2 using acct_grant.xls, label dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) replace ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 


replace metric = "Stock Price" if  metrictype == "Stock Price"
capture drop metric_stata
encode metric, gen(metric_stata)

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##i.metric_stata i.fycompustat if metrictype ~= "Stock Price", a(ff12) cl(cik)
esttab using acct_grant.doc, label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
drop(*.fycompustat) stats(fixed N r2) replace

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj c.med_dcamj#i.metric_stata i.fycompustat, a(ff12) cl(cik)
outreg2 using acct_grant.xls, fvlabel dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 

		
gen D_earnings = 1 if inlist(metric, "EBIT","EBT","EPS","Earnings") | inlist(metric,"Profit Margin","ROA","ROE","ROIC","Vague")

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj c.med_dcamj#i.D_acc i.fycompustat if D_earnings ==1 | metrictype == "Stock Price" [aweight = fv_pct], a(ff12) cl(cik)

capture drop D_metric
gen D_metric = 0 if inlist(metric, "Customer Satisfaction","EBITDA","EVA","Operating Income","Operational","Sales","Same store sales") 
replace D_metric = 0 if inlist(metric,"ROA","ROE","Other", "ROI") 
replace D_metric = 2 if inlist(metric, "EBIT","EBT","EPS","Earnings") | inlist(metric,"Profit Margin","ROIC","Vague")

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##i.D_metric i.fycompustat [aweight = fv_pct], a(ff12) cl(cik)
outreg2 using "E:\Research\WB\RPE_EM\data_code\acc.xls", dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 
		
replace D_metric = 3 if metrictype=="Stock Price"
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##i.D_metric i.fycompustat [aweight = fv_pct], a(ff12) cl(cik)
outreg2 using "E:\Research\WB\RPE_EM\data_code\acc.xls", dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 


capture drop D_metric
gen D_metric = 0 if inlist(metric, "Customer Satisfaction","EBITDA","EVA","Operating Income","Operational")
replace D_metric = 1 if inlist(metric,"Sales","Same store sales") 
replace D_metric = 2 if inlist(metric,"Other") & strpos(metricother, "Cost")
replace D_metric = 3 if inlist(metric,"ROA","ROE","ROI","Vague") |(inlist(metric,"Other") & !strpos(metricother, "Cost"))
replace D_metric = 4 if inlist(metric, "EBIT","EBT","EPS","Earnings") | inlist(metric,"Profit Margin","ROIC")
		
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##i.D_metric i.fycompustat [aweight = fv_pct], a(ff12) cl(cik)
outreg2 using "E:\Research\WB\RPE_EM\data_code\acc.xls", dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 
		
		
* aggregate to firm level
preserve
replace fv_pct = ceil(fv_pct * 100)

collapse dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj ff12 D_acc ///
if D_earnings ==1 | metrictype == "Stock Price" [fw=fv_pct], by (cik fycompustat)

capture drop D_accounting
gen D_accounting = 0 if D_acc == 0
replace D_accounting = 1 if D_acc > 0

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_accounting i.fycompustat, a(ff12) cl(cik) 

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj i.fycompustat if D_accounting==0, a(ff12) cl(cik) 
areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj i.fycompustat if D_accounting==1, a(ff12) cl(cik) 

restore


gen D_sales = 1 if metric == "Sales" | metric =="Same store sales" | metric =="Cashflow" | metric=="Customer Satisfaction" | metric=="Other"
gsort cik fycompustat -D_sales
by cik fycompustat: replace D_sales = D_sales[_n-1] if missing(D_sales)
		
collapse dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj ff12 D_acc if missing(D_sales), by (cik fycompustat)

capture drop D_accounting
gen D_accounting = 0
replace D_accounting = .5 if D_acc >0 & D_acc < 1
replace D_accounting = 1 if D_acc == 1

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_accounting i.fycompustat if D_accounting ~=.5, a(ff12) cl(cik) 


gsort cik fycompustat -D_metric
by cik fycompustat: replace D_metric = D_metric[_n-1] if missing(D_metric)

preserve
collapse dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg med_dcamj ff12 D_acc if D_metric ==2 | metrictype == "Stock Price", by (cik fycompustat)

capture drop D_accounting
gen D_accounting = 0
replace D_accounting = .5 if D_acc >0 & D_acc < 1
replace D_accounting = 1 if D_acc == 1

areg dcamj attm1inverse chgsaledattm1 ppegtdattm1 bm size roa rety evol lvg c.med_dcamj##c.D_accounting i.fycompustat if D_accounting ~=.5, a(ff12) cl(cik) 
outreg2 using "E:\Research\WB\RPE_EM\data_code\acc.xls", dec(3) alpha(0.01, 0.05, 0.1) symbol(***, **, *)         ///
		drop( i.fycompustat ) append ctitle(Mod Jones Accruals) addtext(FE, Industry+Year) 
restore
