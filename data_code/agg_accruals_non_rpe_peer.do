cd "F:\Research\WB\RPE_EM\data_code"


/* create RPE and peer list 
use peerlist, clear

bys cik fycompustat: gen n=_n
keep if n==1
drop n
drop peercik
save rpe_list  

use peerlist, clear
drop cik
ren peercik cik
bys cik fycompustat: gen n=_n
keep if n==1
drop n
save peer_list
*/

use accruals ,clear

ren fyear fycompustat

sort cik fycompustat

merge 1:1 cik fycompustat using rpe_list

gen D_rpe = 0
replace D_rpe = 1 if _merge ~= 1

drop if _merge == 2
drop _merge

merge 1:1 cik fycompustat using peer_list

gen D_peer = 0
replace D_peer = 1 if _merge ~= 1

drop if _merge == 2
drop _merge

gen D_rpe_peer = 0
replace D_rpe_peer = 1 if D_rpe == 1 | D_peer == 1

keep if fycompustat > 2005
sum D_rpe_peer D_rpe D_peer

drop if D_rpe_peer == 1
drop D_rpe_peer D_rpe D_peer

collapse (median) med_dcaj_non_rpe_peer=dcajones1991_w med_dcajint_non_rpe_peer=dcajones1991int_w med_dcamj_non_rpe_peer=dcamodjones1991_w med_dcamjint_non_rpe_peer=dcamodjones1991int_w, /// 
by(fycompustat)

save accruals_non_rpe_peer ,replace
 