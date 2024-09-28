
**************************************************;
* This code sets up the treasury data
* and shows how an interploation can be done;
* Nov 16, 2017
**************************************************;





***merge in interest yield;
/*merge in interest rate and calculate spread*/
data treasurycrsp; set "D:\Dropbox\RPE_EM\Codes and Data\tfz_dly_ft";
where year(caldt)>=1980;
keep caldt rdcrspid tdyearstm tdytm;
run;

proc sort data=treasurycrsp nodup;
by caldt tdyearstm;
run;

data treasurycrsp2; set treasurycrsp;
tdyearstm = tdyearstm*360/365;
tdytm=tdytm/100;
run;

*Add  mat of 1000 equal to max mat for ease of calculations;
proc sql;
      create table temp
      as select distinct e.caldt, max(tdyearstm) as myearstm, tdyearstm, tdytm
      from  treasurycrsp2 as e
      group by e.caldt
      having myearstm = tdyearstm;
quit;

/*create a 1000 ttm t-bond for each treasury observation*/
data temp2; set temp;
tdyearstm = 1000;
drop myearstm;
run;

data treasurycrsp3; set treasurycrsp2 temp2;
run;

proc sort data = treasurycrsp3 nodup;
by caldt tdyearstm;
run;






*SAMPLE Interpolation



***merge in treasury yield;
proc sql;
      create table temp
      as select e.*, s.yearstm, s.ytm
      from traceyield as e
      left join treasurycrsp3 as s
      on e.trans_date = s.qdate and e.ttm>=s.yearstm
      order by idid, issue_id, trans_date, yearstm;
quit;

data temp2; set temp;
by idid issue_id trans_date yearstm;
if last.trans_date;
run;

proc sql;
      create table temp3
      as select e.*, s.yearstm as yearstm2, s.ytm as ytm2
      from temp2 as e
      left join treasurycrsp3 as s
      on e.trans_date = s.qdate and e.ttm<=s.yearstm
      order by idid, issue_id, trans_date, yearstm2;
quit;

data temp4; set temp3;
by idid issue_id trans_date yearstm2;
if first.trans_date;
run;

***linear intropolation;
data temp5; set temp4;
intyield=((ttm-yearstm)/(yearstm2-yearstm))*(ytm2-ytm)+ytm;
if ytm=. and ytm2 ~=. then intyield=ytm2;
run;

data temp6; set temp5;
if intyield ~=.;
spread=yield-intyield;
run;
