cd "D:\World_bank_research\RPE_EM\data_code" /*please change to your directory */

**** create counterfactuals  ************* 

/* select firms from the same size,roa,FF12 group.  
* get the list of nonrestated firms within the same size-ROA group as the restated firms
use aq_main.dta if fycompustat>2005, clear
keep if d_rpe == 1 

* control for size & ROA 
egen sizeq = xtile(size), by(fycompustat) p(50) // p(25(25)75)
egen roaq = xtile(roa), by(fycompustat) p(50) // p(25(25)75)

* expand the data
preserve 
keep cik fycompustat d_restate sizeq roaq ff12
rename cik cik_other
rename d_restate d_restate_other
rename sizeq sizeq_other
rename roaq roaq_other
rename ff12 ff12_other
save other1.dta,replace
restore 

keep if d_restate == 1 //find counterfactuals for restated firms only
joinby fycompustat using other1.dta
drop if d_restate_other == 1 | cik_other == cik
gen same_q = 1 if sizeq == sizeq_other & roaq == roaq_other & ff12==ff12_other
drop if same_q ~= 1

keep cik_other fycompustat
rename cik_other cik
duplicates drop

* obtain characteristics of selected nonrestated firms
merge 1:1 cik fycompustat using aq_main
keep if _merge == 3
drop _merge
save size_roa_peers.dta, replace 

* merge restate firms with non-restated firms in the same size-roa goupr
use aq_main.dta if fycompustat>2005, clear
keep if d_rpe == 1 & d_restate == 1
append using size_roa_peers
*/

use aq_main.dta if fycompustat>2005, clear
keep if d_rpe == 1 

* select non-stated firms by year
bysort fycompustat: gen N=_N /*total nb of firms each year */
bysort fycompustat: egen N_restate=sum(d_restate)  /*count nb of restated firms */

set seed 0271  // 1234 works only when not controlling for industry restatement
sort fycompustat cik //must sort this first, ow firms may change order when using runiform, making the results not replicable
by fycompustat: gen r=runiform()  if d_restate==0 /*create random variable*/

gen d_peerrestate = 0
replace d_peerrestate = 1 if restatepct > 0

bysort fycompustat ff12: egen restatepct_ff12yr = mean(d_restate)

logit d_restate bm size roa rety evol lvg d_peerrestate i.ff12 i.fycompustat if d_restate==1 | (r<= N_restate/N ), cl(cik) 

logit d_restate bm size roa rety evol lvg d_peerrestate restatepct_ff12yr i.ff12 i.fycompustat if d_restate==1 | (r<=N_restate/N), cl(cik)  

predict pscore, pr

/* 1) 1:1 matching
gen double g = fycompustat* real(cik) + pscore /* all pscore <1, so adding them up could uniquely identify each obs */

psmatch2 d_restate, pscore(g) noreplacement

* select firms with the highest score 
g pair = _id if _treated==0
replace pair = _n1 if _treated==1
bysort pair: egen paircount = count(pair)
gsort + cik -paircount + pair - _treated

keep if (paircount == 2 & _treated == 0) | d_restate == 1 /* keep firms with the highest score and restated firms */
*/

** 2) 1:n matching
egen sizeq = xtile(size), by(fycompustat) p(25(25)75)
egen roaq = xtile(roa), by(fycompustat) p(25(25)75)

* expand the data
preserve 
keep cik fycompustat d_restate sizeq roaq pscore
rename cik cik_other
rename d_restate d_restate_other
rename sizeq sizeq_other
rename roaq roaq_other
rename pscore pscore_other
save other.dta,replace
restore 

keep if d_restate == 1 //find counterfactuals for restated firms only
joinby fycompustat using other.dta
drop if d_restate_other == 1 | cik_other == cik
gen same_q = 1 if sizeq == sizeq_other & roaq == roaq_other
bys cik fycompustat: gen ssame_q = sum(same_q) // check if we have enough firms to choose for each restate firm-year, but this code generates the sum from 0 till the total nb, so we need the next line
bys cik fycompustat: egen ssame_q2 = max(ssame_q)
gen diffpscore = abs(pscore - pscore_other)

drop if same_q ~= 1 //drop if not in the same quintile
bys fycompustat cik_other (diffpscore): gen dup=_n //drop the firms that are counted more than once
drop if dup > 1
drop dup
drop if ssame_q2 < 10 //gurantee enough firms to choose from

bys cik fycompustat (diffpscore): gen n=_n //diffpscore is sorted, but not used for computing the summary by group
keep if n <= 10 //only select from closest 10 firms
bys cik fycompustat: gen r2=runiform()
bys cik fycompustat: gen N_peers = _N
keep if r2 <= 3 / N_peers

* get the counterfactures' characteristics  
keep cik_other fycompustat
rename cik_other cik
merge 1:1 cik fycompustat using aq_main
keep if _merge == 3
drop _merge
save other_char.dta, replace 

* merge restate firms with counterfactuals
use aq_main.dta if fycompustat>2005, clear
keep if d_rpe == 1 & d_restate == 1
append using other_char

gen d_peerrestate = 0
replace d_peerrestate = 1 if restatepct > 0

* regressions;
logit d_restate bm size roa rety evol lvg d_peerrestate i.ff12 i.fycompustat, cl(cik) 

