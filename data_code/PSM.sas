libname inclab 'D:\Research\WB\RPE_EM\IncLab_data';
libname my 'D:\Research\WB\RPE_EM\data_code';
libname freq 'D:\Research\WB\freq used vars';
libname temp 'F:\Experience\World_bank';

libname crsp 'E:\Data\CRSP';
libname compNA 'E:\Data\CompNA';
libname ratings 'E:\Data\CompNA\rating';

/**** Get fundamentals for all firms; ****/
data funda; set 'D:\RPE\Systemic_Risk\funda_part'; drop roa; run;*254633;

data funda; set funda; 
cym = mdy(fyr,1,cyear); format cym MMDDYY10.; 
if cik ~= '';
run;

proc sort data=funda nodupkey; by cik fyear; run; * no duplicates;

data sp500; set 'E:\Data\CompNA\Index_constituents\SP500_constituents'; run;

proc sql;
    create table funda2 as select a.*, b.conm as sp500
	from funda as a left join 'E:\Data\CompNA\Index_constituents\SP500_constituents' as b
	on a.gvkey = b.gvkey and cym > b.from and (cym <= b.thru | b.thru =.)
	order by gvkey, fyear, fyr, sp500;
quit;

* the from-thru period in sp500 is not exlusive. assume the firm is in sp500 as long as it falls in any period;
data funda2; set funda2; by gvkey fyear fyr sp500; if last.fyr; run;

proc sql;
    create table funda2 as select a.*, c.conm as sp1500
	from funda2 as a 
	left join 'E:\Data\CompNA\Index_constituents\SP1500_constituents' as c
	on a.gvkey = c.gvkey and cym > c.from and (cym <= c.thru | c.thru =.)
	order by gvkey, fyear, fyr, sp1500;
quit;

data funda2; set funda2; by gvkey fyear fyr sp1500; if last.fyr; run;

data funda2; set funda2; if cik~='';
label sp500 = 'S&P500'
sp1500 = 'S&P1500';
run;

* combine with rating;
proc sql;
    create table funda3 as select a.*, b.splticrm
	from funda2 as a left join ratings.Adsprate_updated as b
	on a.gvkey = b.gvkey and cyear=year(datadate) and fyr=month(datadate)
	order by gvkey, fyear, fyr;
quit;

data funda3; set funda3; 
if splticrm in ('D','SD') then ratings=1;
if splticrm = 'C' then ratings=2;
if splticrm = 'CC' then ratings=3;
if splticrm = 'CCC-' then ratings=4;
if splticrm = 'CCC' then ratings=5;
if splticrm = 'CCC+' then ratings=6;
if splticrm = 'B-' then ratings=7;
if splticrm = 'B' then ratings=8;
if splticrm = 'B+' then ratings=9;
if splticrm = 'BB-' then ratings=10;
if splticrm = 'BB' then ratings=11;
if splticrm = 'BB+' then ratings=12;
if splticrm = 'BBB-' then ratings=13;
if splticrm = 'BBB' then ratings=14;
if splticrm = 'BBB+' then ratings=15;
if splticrm = 'A-' then ratings=16;
if splticrm = 'A' then ratings=17;
if splticrm = 'A+' then ratings=18;
if splticrm = 'AA-' then ratings=19;
if splticrm = 'AA' then ratings=20;
if splticrm = 'AA+' then ratings=21;
if splticrm = 'AAA' then ratings=22;
run;

*industry classification;
data funda3; set funda3;
sic2 = int(HSICCD/100);
* 1 Agric  Agriculture;
          if hsiccd ge 0100 and hsiccd le 0199  then FF48='AGRIC';
          if hsiccd ge 0200 and hsiccd le 0299  then FF48='AGRIC';
          if hsiccd ge 0700 and hsiccd le 0799  then FF48='AGRIC';
          if hsiccd ge 0910 and hsiccd le 0919  then FF48='AGRIC';
          if hsiccd ge 2048 and hsiccd le 2048  then FF48='AGRIC';

* 2 Food   Food Products;
          if hsiccd ge 2000 and hsiccd le 2009  then FF48='FOOD';
          if hsiccd ge 2010 and hsiccd le 2019  then FF48='FOOD';
          if hsiccd ge 2020 and hsiccd le 2029  then FF48='FOOD';
          if hsiccd ge 2030 and hsiccd le 2039  then FF48='FOOD';
          if hsiccd ge 2040 and hsiccd le 2046  then FF48='FOOD';
          if hsiccd ge 2050 and hsiccd le 2059  then FF48='FOOD';
          if hsiccd ge 2060 and hsiccd le 2063  then FF48='FOOD';
          if hsiccd ge 2070 and hsiccd le 2079  then FF48='FOOD';
          if hsiccd ge 2090 and hsiccd le 2092  then FF48='FOOD';
          if hsiccd ge 2095 and hsiccd le 2095  then FF48='FOOD';
          if hsiccd ge 2098 and hsiccd le 2099  then FF48='FOOD';

* 3 Soda   Candy & Soda;
          if hsiccd ge 2064 and hsiccd le 2068  then FF48='SODA';
          if hsiccd ge 2086 and hsiccd le 2086  then FF48='SODA';
          if hsiccd ge 2087 and hsiccd le 2087  then FF48='SODA';
          if hsiccd ge 2096 and hsiccd le 2096  then FF48='SODA';
          if hsiccd ge 2097 and hsiccd le 2097  then FF48='SODA';

* 4 Beer   Beer & Liquor;
          if hsiccd ge 2080 and hsiccd le 2080  then FF48='BEER';
          if hsiccd ge 2082 and hsiccd le 2082  then FF48='BEER';
          if hsiccd ge 2083 and hsiccd le 2083  then FF48='BEER';
          if hsiccd ge 2084 and hsiccd le 2084  then FF48='BEER';
          if hsiccd ge 2085 and hsiccd le 2085  then FF48='BEER'; 

* 5 Smoke  Tobacco Products;
          if hsiccd ge 2100 and hsiccd le 2199  then FF48='SMOKE'; 

* 6 Toys   Recreation;
          if hsiccd ge 0920 and hsiccd le 0999  then FF48='TOYS'; 
          if hsiccd ge 3650 and hsiccd le 3651  then FF48='TOYS'; 
          if hsiccd ge 3652 and hsiccd le 3652  then FF48='TOYS';
          if hsiccd ge 3732 and hsiccd le 3732   then FF48='TOYS';
          if hsiccd ge 3930 and hsiccd le 3931   then FF48='TOYS';
          if hsiccd ge 3940 and hsiccd le 3949   then FF48='TOYS';

* 7 Fun    Entertainment;
          if hsiccd ge 7800 and hsiccd le 7829   then FF48='FUN';
          if hsiccd ge  7830 and hsiccd le 7833   then FF48='FUN';
          if hsiccd ge 7840 and hsiccd le 7841   then FF48='FUN';
          if hsiccd ge 7900 and hsiccd le 7900   then FF48='FUN';
          if hsiccd ge 7910 and hsiccd le 7911   then FF48='FUN';
          if hsiccd ge 7920 and hsiccd le 7929   then FF48='FUN';
          if hsiccd ge 7930 and hsiccd le 7933   then FF48='FUN';
          if hsiccd ge 7940 and hsiccd le 7949   then FF48='FUN';
          if hsiccd ge 7980 and hsiccd le 7980   then FF48='FUN';
          if hsiccd ge 7990 and hsiccd le 7999   then FF48='FUN';

* 8 Books  Printing and Publishing;
          if hsiccd ge 2700 and hsiccd le 2709   then FF48='BOOKS';
          if hsiccd ge 2710 and hsiccd le 2719   then FF48='BOOKS';
          if hsiccd ge 2720 and hsiccd le 2729   then FF48='BOOKS';
          if hsiccd ge 2730 and hsiccd le 2739   then FF48='BOOKS';
          if hsiccd ge 2740 and hsiccd le 2749   then FF48='BOOKS';
          if hsiccd ge 2770 and hsiccd le 2771   then FF48='BOOKS';
          if hsiccd ge 2780 and hsiccd le 2789   then FF48='BOOKS';
          if hsiccd ge 2790 and hsiccd le 2799   then FF48='BOOKS';

* 9 Hshld  Consumer Goods;
          if hsiccd ge 2047 and hsiccd le 2047   then FF48='HSHLD';
          if hsiccd ge 2391 and hsiccd le 2392   then FF48='HSHLD';
          if hsiccd ge 2510 and hsiccd le 2519   then FF48='HSHLD';
          if hsiccd ge 2590 and hsiccd le 2599   then FF48='HSHLD';
          if hsiccd ge 2840 and hsiccd le 2843   then FF48='HSHLD';
          if hsiccd ge 2844 and hsiccd le 2844   then FF48='HSHLD';
          if hsiccd ge 3160 and hsiccd le 3161   then FF48='HSHLD';
          if hsiccd ge 3170 and hsiccd le 3171   then FF48='HSHLD';
          if hsiccd ge 3172 and hsiccd le 3172   then FF48='HSHLD';
          if hsiccd ge 3190 and hsiccd le 3199   then FF48='HSHLD';
          if hsiccd ge 3229 and hsiccd le 3229   then FF48='HSHLD';
          if hsiccd ge 3260 and hsiccd le 3260   then FF48='HSHLD';
          if hsiccd ge 3262 and hsiccd le 3263   then FF48='HSHLD';
          if hsiccd ge 3269 and hsiccd le 3269   then FF48='HSHLD';
          if hsiccd ge 3230 and hsiccd le 3231   then FF48='HSHLD';
          if hsiccd ge 3630 and hsiccd le 3639   then FF48='HSHLD';
          if hsiccd ge 3750 and hsiccd le 3751   then FF48='HSHLD';
          if hsiccd ge 3800 and hsiccd le 3800   then FF48='HSHLD';
          if hsiccd ge 3860 and hsiccd le 3861   then FF48='HSHLD';
          if hsiccd ge 3870 and hsiccd le 3873   then FF48='HSHLD';
          if hsiccd ge 3910 and hsiccd le 3911   then FF48='HSHLD';
          if hsiccd ge 3914 and hsiccd le 3914   then FF48='HSHLD';
          if hsiccd ge 3915 and hsiccd le 3915   then FF48='HSHLD';
          if hsiccd ge 3960 and hsiccd le 3962   then FF48='HSHLD';
          if hsiccd ge 3991 and hsiccd le 3991   then FF48='HSHLD';
          if hsiccd ge 3995 and hsiccd le 3995   then FF48='HSHLD';

*10 Clths  Apparel;
          if hsiccd ge 2300 and hsiccd le 2390   then FF48='CLTHS';
          if hsiccd ge 3020 and hsiccd le 3021   then FF48='CLTHS';
          if hsiccd ge 3100 and hsiccd le 3111   then FF48='CLTHS';
          if hsiccd ge 3130 and hsiccd le 3131   then FF48='CLTHS';
          if hsiccd ge 3140 and hsiccd le 3149   then FF48='CLTHS';
          if hsiccd ge 3150 and hsiccd le 3151   then FF48='CLTHS';
          if hsiccd ge 3963 and hsiccd le 3965   then FF48='CLTHS';

*11 Hlth   Healthcare;
          if hsiccd ge 8000 and hsiccd le 8099   then FF48='HLTH';

*12 MedEq  Medical Equipment;
          if hsiccd ge 3693 and hsiccd le 3693   then FF48='MEDEQ';
          if hsiccd ge 3840 and hsiccd le 3849   then FF48='MEDEQ';
          if hsiccd ge 3850 and hsiccd le 3851   then FF48='MEDEQ';

*13 Drugs  Pharmaceutical Products;
          if hsiccd ge 2830 and hsiccd le 2830   then FF48='DRUGS';
          if hsiccd ge 2831 and hsiccd le 2831   then FF48='DRUGS';
          if hsiccd ge 2833 and hsiccd le 2833   then FF48='DRUGS';
          if hsiccd ge 2834 and hsiccd le 2834   then FF48='DRUGS';
          if hsiccd ge 2835 and hsiccd le 2835   then FF48='DRUGS';
          if hsiccd ge 2836 and hsiccd le 2836   then FF48='DRUGS';

*14 Chems  Chemicals;
          if hsiccd ge 2800 and hsiccd le 2809   then FF48='CHEM';
          if hsiccd ge 2810 and hsiccd le 2819   then FF48='CHEM';
          if hsiccd ge 2820 and hsiccd le 2829   then FF48='CHEM';
          if hsiccd ge 2850 and hsiccd le 2859   then FF48='CHEM';
          if hsiccd ge 2860 and hsiccd le 2869   then FF48='CHEM';
          if hsiccd ge 2870 and hsiccd le 2879   then FF48='CHEM';
          if hsiccd ge 2890 and hsiccd le 2899   then FF48='CHEM';

*15 Rubbr  Rubber and Plastic Products;
          if hsiccd ge 3031 and hsiccd le 3031   then FF48='RUBBR';
          if hsiccd ge 3041 and hsiccd le 3041   then FF48='RUBBR';
          if hsiccd ge 3050 and hsiccd le 3053   then FF48='RUBBR';
          if hsiccd ge 3060 and hsiccd le 3069   then FF48='RUBBR';
          if hsiccd ge 3070 and hsiccd le 3079   then FF48='RUBBR';
          if hsiccd ge 3080 and hsiccd le 3089   then FF48='RUBBR';
          if hsiccd ge 3090 and hsiccd le 3099   then FF48='RUBBR';

*16 Txtls  Textiles;
          if hsiccd ge 2200 and hsiccd le 2269   then FF48='TXTLS';
          if hsiccd ge 2270 and hsiccd le 2279   then FF48='TXTLS';
          if hsiccd ge 2280 and hsiccd le 2284   then FF48='TXTLS';
          if hsiccd ge 2290 and hsiccd le 2295   then FF48='TXTLS';
          if hsiccd ge 2297 and hsiccd le 2297   then FF48='TXTLS';
          if hsiccd ge 2298 and hsiccd le 2298   then FF48='TXTLS';
          if hsiccd ge 2299 and hsiccd le 2299   then FF48='TXTLS';
          if hsiccd ge 2393 and hsiccd le 2395   then FF48='TXTLS';
          if hsiccd ge 2397 and hsiccd le 2399   then FF48='TXTLS';

*17 BldMt  Construction Materials;
          if hsiccd ge 0800 and hsiccd le 0899   then FF48='BLDMT';
          if hsiccd ge 2400 and hsiccd le 2439   then FF48='BLDMT';
          if hsiccd ge 2450 and hsiccd le 2459   then FF48='BLDMT';
          if hsiccd ge 2490 and hsiccd le 2499   then FF48='BLDMT';
          if hsiccd ge 2660 and hsiccd le 2661   then FF48='BLDMT';
          if hsiccd ge 2950 and hsiccd le 2952   then FF48='BLDMT';
          if hsiccd ge 3200 and hsiccd le 3200   then FF48='BLDMT';
          if hsiccd ge 3210 and hsiccd le 3211   then FF48='BLDMT';
          if hsiccd ge 3240 and hsiccd le 3241   then FF48='BLDMT';
          if hsiccd ge 3250 and hsiccd le 3259   then FF48='BLDMT';
          if hsiccd ge 3261 and hsiccd le 3261   then FF48='BLDMT';
          if hsiccd ge 3264 and hsiccd le 3264   then FF48='BLDMT';
          if hsiccd ge 3270 and hsiccd le 3275   then FF48='BLDMT';
          if hsiccd ge 3280 and hsiccd le 3281   then FF48='BLDMT';
          if hsiccd ge 3290 and hsiccd le 3293   then FF48='BLDMT';
          if hsiccd ge 3295 and hsiccd le 3299   then FF48='BLDMT';
          if hsiccd ge 3420 and hsiccd le 3429   then FF48='BLDMT';
          if hsiccd ge 3430 and hsiccd le 3433   then FF48='BLDMT';
          if hsiccd ge 3440 and hsiccd le 3441   then FF48='BLDMT';
          if hsiccd ge 3442 and hsiccd le 3442   then FF48='BLDMT';
          if hsiccd ge 3446 and hsiccd le 3446   then FF48='BLDMT';
          if hsiccd ge 3448 and hsiccd le 3448   then FF48='BLDMT';
          if hsiccd ge 3449 and hsiccd le 3449   then FF48='BLDMT';
          if hsiccd ge 3450 and hsiccd le 3451   then FF48='BLDMT';
          if hsiccd ge 3452 and hsiccd le 3452   then FF48='BLDMT';
          if hsiccd ge 3490 and hsiccd le 3499   then FF48='BLDMT';
          if hsiccd ge 3996 and hsiccd le 3996   then FF48='BLDMT';

*18 Cnstr  Construction;
          if hsiccd ge 1500 and hsiccd le 1511   then FF48='CNSTR';
          if hsiccd ge 1520 and hsiccd le 1529   then FF48='CNSTR';
          if hsiccd ge 1530 and hsiccd le 1539   then FF48='CNSTR';
          if hsiccd ge 1540 and hsiccd le 1549   then FF48='CNSTR';
          if hsiccd ge 1600 and hsiccd le 1699   then FF48='CNSTR';
          if hsiccd ge 1700 and hsiccd le 1799   then FF48='CNSTR';

*19 Steel  Steel Works Etc;
          if hsiccd ge 3300 and hsiccd le 3300   then FF48='STEEL';
          if hsiccd ge 3310 and hsiccd le 3317   then FF48='STEEL';
          if hsiccd ge 3320 and hsiccd le 3325   then FF48='STEEL';
          if hsiccd ge 3330 and hsiccd le 3339   then FF48='STEEL';
          if hsiccd ge 3340 and hsiccd le 3341   then FF48='STEEL';
          if hsiccd ge 3350 and hsiccd le 3357   then FF48='STEEL';
          if hsiccd ge 3360 and hsiccd le 3369   then FF48='STEEL';
          if hsiccd ge 3370 and hsiccd le 3379   then FF48='STEEL';
          if hsiccd ge 3390 and hsiccd le 3399   then FF48='STEEL';

*20 FabPr  Fabricated Products;
          if hsiccd ge 3400 and hsiccd le 3400   then FF48='FABPR';
          if hsiccd ge 3443 and hsiccd le 3443   then FF48='FABPR';
          if hsiccd ge 3444 and hsiccd le 3444   then FF48='FABPR';
          if hsiccd ge 3460 and hsiccd le 3469   then FF48='FABPR';
          if hsiccd ge 3470 and hsiccd le 3479   then FF48='FABPR';

*21 Mach   Machinery;
          if hsiccd ge 3510 and hsiccd le 3519   then FF48='MACH';
          if hsiccd ge 3520 and hsiccd le 3529   then FF48='MACH';
          if hsiccd ge 3530 and hsiccd le 3530   then FF48='MACH';
          if hsiccd ge 3531 and hsiccd le 3531   then FF48='MACH';
          if hsiccd ge 3532 and hsiccd le 3532   then FF48='MACH';
          if hsiccd ge 3533 and hsiccd le 3533   then FF48='MACH';
          if hsiccd ge 3534 and hsiccd le 3534   then FF48='MACH';
          if hsiccd ge 3535 and hsiccd le 3535   then FF48='MACH';
          if hsiccd ge 3536 and hsiccd le 3536   then FF48='MACH';
          if hsiccd ge 3538 and hsiccd le 3538   then FF48='MACH';
          if hsiccd ge 3540 and hsiccd le 3549   then FF48='MACH';
          if hsiccd ge 3550 and hsiccd le 3559   then FF48='MACH';
          if hsiccd ge 3560 and hsiccd le 3569   then FF48='MACH';
          if hsiccd ge 3580 and hsiccd le 3580   then FF48='MACH';
          if hsiccd ge 3581 and hsiccd le 3581   then FF48='MACH';
          if hsiccd ge 3582 and hsiccd le 3582   then FF48='MACH';
          if hsiccd ge 3585 and hsiccd le 3585   then FF48='MACH';
          if hsiccd ge 3586 and hsiccd le 3586   then FF48='MACH';
          if hsiccd ge 3589 and hsiccd le 3589   then FF48='MACH';
          if hsiccd ge 3590 and hsiccd le 3599   then FF48='MACH';

*22 ElcEq  Electrical Equipment;
          if hsiccd ge 3600 and hsiccd le 3600   then FF48='ELCEQ';
          if hsiccd ge 3610 and hsiccd le 3613   then FF48='ELCEQ';
          if hsiccd ge 3620 and hsiccd le 3621   then FF48='ELCEQ';
          if hsiccd ge 3623 and hsiccd le 3629   then FF48='ELCEQ';
          if hsiccd ge 3640 and hsiccd le 3644   then FF48='ELCEQ';
          if hsiccd ge 3645 and hsiccd le 3645   then FF48='ELCEQ'; 
          if hsiccd ge 3646 and hsiccd le 3646   then FF48='ELCEQ';
          if hsiccd ge 3648 and hsiccd le 3649   then FF48='ELCEQ';
          if hsiccd ge 3660 and hsiccd le 3660   then FF48='ELCEQ';
          if hsiccd ge 3690 and hsiccd le 3690   then FF48='ELCEQ';
          if hsiccd ge 3691 and hsiccd le 3692   then FF48='ELCEQ';
          if hsiccd ge 3699 and hsiccd le 3699   then FF48='ELCEQ';

*23 Autos  Automobiles and Trucks;
          if hsiccd ge 2296 and hsiccd le 2296   then FF48='AUTOS';
          if hsiccd ge 2396 and hsiccd le 2396   then FF48='AUTOS';
          if hsiccd ge 3010 and hsiccd le 3011   then FF48='AUTOS';
          if hsiccd ge 3537 and hsiccd le 3537   then FF48='AUTOS';
          if hsiccd ge 3647 and hsiccd le 3647   then FF48='AUTOS';
          if hsiccd ge 3694 and hsiccd le 3694   then FF48='AUTOS';
          if hsiccd ge 3700 and hsiccd le 3700   then FF48='AUTOS';
          if hsiccd ge 3710 and hsiccd le 3710   then FF48='AUTOS';
          if hsiccd ge 3711 and hsiccd le 3711   then FF48='AUTOS';
          if hsiccd ge 3713 and hsiccd le 3713   then FF48='AUTOS';
          if hsiccd ge 3714 and hsiccd le 3714   then FF48='AUTOS';
          if hsiccd ge 3715 and hsiccd le 3715   then FF48='AUTOS';
          if hsiccd ge 3716 and hsiccd le 3716   then FF48='AUTOS';
          if hsiccd ge 3792 and hsiccd le 3792   then FF48='AUTOS';
          if hsiccd ge 3790 and hsiccd le 3791   then FF48='AUTOS';
          if hsiccd ge 3799 and hsiccd le 3799   then FF48='AUTOS';

*24 Aero   Aircraft;
          if hsiccd ge 3720 and hsiccd le 3720   then FF48='AERO';
          if hsiccd ge 3721 and hsiccd le 3721   then FF48='AERO';
          if hsiccd ge 3723 and hsiccd le 3724   then FF48='AERO';
          if hsiccd ge 3725 and hsiccd le 3725   then FF48='AERO';
          if hsiccd ge 3728 and hsiccd le 3729   then FF48='AERO';

*25 Ships  Shipbuilding, Railroad Equipment;
          if hsiccd ge 3730 and hsiccd le 3731   then FF48='SHIPS';
          if hsiccd ge 3740 and hsiccd le 3743   then FF48='SHIPS';

*26 Guns   Defense;
          if hsiccd ge 3760 and hsiccd le 3769   then FF48='GUNS';
          if hsiccd ge 3795 and hsiccd le 3795   then FF48='GUNS';
          if hsiccd ge 3480 and hsiccd le 3489   then FF48='GUNS';

*27 Gold   Precious Metals;
          if hsiccd ge 1040 and hsiccd le 1049   then FF48='GOLD';

*28 Mines  Non and hsiccd le Metallic and Industrial Metal Mining;;
          if hsiccd ge 1000 and hsiccd le 1009   then FF48='MINES';
          if hsiccd ge 1010 and hsiccd le 1019   then FF48='MINES';
          if hsiccd ge 1020 and hsiccd le 1029   then FF48='MINES';
          if hsiccd ge 1030 and hsiccd le 1039   then FF48='MINES';
          if hsiccd ge 1050 and hsiccd le 1059   then FF48='MINES';
          if hsiccd ge 1060 and hsiccd le 1069   then FF48='MINES';
          if hsiccd ge 1070 and hsiccd le 1079   then FF48='MINES';
          if hsiccd ge 1080 and hsiccd le 1089   then FF48='MINES';
          if hsiccd ge 1090 and hsiccd le 1099   then FF48='MINES';
          if hsiccd ge 1100 and hsiccd le 1119   then FF48='MINES';
          if hsiccd ge 1400 and hsiccd le 1499   then FF48='MINES';

*29 Coal   Coal;
          if hsiccd ge 1200 and hsiccd le 1299   then FF48='COAL';

*30 Oil    Petroleum and Natural Gas;
          if hsiccd ge 1300 and hsiccd le 1300   then FF48='OIL';
          if hsiccd ge 1310 and hsiccd le 1319   then FF48='OIL';
          if hsiccd ge 1320 and hsiccd le 1329   then FF48='OIL';
          if hsiccd ge 1330 and hsiccd le 1339   then FF48='OIL';
          if hsiccd ge 1370 and hsiccd le 1379   then FF48='OIL';
          if hsiccd ge 1380 and hsiccd le 1380   then FF48='OIL';
          if hsiccd ge 1381 and hsiccd le 1381   then FF48='OIL';
          if hsiccd ge 1382 and hsiccd le 1382   then FF48='OIL';
          if hsiccd ge 1389 and hsiccd le 1389   then FF48='OIL';
          if hsiccd ge 2900 and hsiccd le 2912   then FF48='OIL';
          if hsiccd ge 2990 and hsiccd le 2999   then FF48='OIL';

*31 Util   Utilities;
          if hsiccd ge 4900 and hsiccd le 4900   then FF48='UTIL';
          if hsiccd ge 4910 and hsiccd le 4911   then FF48='UTIL';
          if hsiccd ge 4920 and hsiccd le 4922   then FF48='UTIL';
          if hsiccd ge 4923 and hsiccd le 4923   then FF48='UTIL';
          if hsiccd ge 4924 and hsiccd le 4925   then FF48='UTIL';
          if hsiccd ge 4930 and hsiccd le 4931   then FF48='UTIL';
          if hsiccd ge 4932 and hsiccd le 4932   then FF48='UTIL';
          if hsiccd ge 4939 and hsiccd le 4939   then FF48='UTIL';
          if hsiccd ge 4940 and hsiccd le 4942   then FF48='UTIL';

*32 Telcm  Communication;
          if hsiccd ge 4800 and hsiccd le 4800   then FF48='TELCM';
          if hsiccd ge 4810 and hsiccd le 4813   then FF48='TELCM';
          if hsiccd ge 4820 and hsiccd le 4822   then FF48='TELCM';
          if hsiccd ge 4830 and hsiccd le 4839   then FF48='TELCM';
          if hsiccd ge 4840 and hsiccd le 4841   then FF48='TELCM';
          if hsiccd ge 4880 and hsiccd le 4889   then FF48='TELCM';
          if hsiccd ge 4890 and hsiccd le 4890   then FF48='TELCM';
          if hsiccd ge 4891 and hsiccd le 4891   then FF48='TELCM';
          if hsiccd ge 4892 and hsiccd le 4892   then FF48='TELCM';
          if hsiccd ge 4899 and hsiccd le 4899   then FF48='TELCM';

*33 PerSv  Personal Services;
          if hsiccd ge 7020 and hsiccd le 7021   then FF48='PERSV';
          if hsiccd ge 7030 and hsiccd le 7033   then FF48='PERSV';
          if hsiccd ge 7200 and hsiccd le 7200   then FF48='PERSV';
          if hsiccd ge 7210 and hsiccd le 7212   then FF48='PERSV';
          if hsiccd ge 7214 and hsiccd le 7214   then FF48='PERSV';
          if hsiccd ge 7215 and hsiccd le 7216   then FF48='PERSV';
          if hsiccd ge 7217 and hsiccd le 7217   then FF48='PERSV';
          if hsiccd ge 7219 and hsiccd le 7219   then FF48='PERSV';
          if hsiccd ge 7220 and hsiccd le 7221   then FF48='PERSV';
          if hsiccd ge 7230 and hsiccd le 7231   then FF48='PERSV';
          if hsiccd ge 7240 and hsiccd le 7241   then FF48='PERSV';
          if hsiccd ge 7250 and hsiccd le 7251   then FF48='PERSV';
          if hsiccd ge 7260 and hsiccd le 7269   then FF48='PERSV';
          if hsiccd ge 7270 and hsiccd le 7290   then FF48='PERSV';
          if hsiccd ge 7291 and hsiccd le 7291   then FF48='PERSV';
          if hsiccd ge 7292 and hsiccd le 7299   then FF48='PERSV';
          if hsiccd ge 7395 and hsiccd le 7395   then FF48='PERSV';
          if hsiccd ge 7500 and hsiccd le 7500   then FF48='PERSV';
          if hsiccd ge 7520 and hsiccd le 7529   then FF48='PERSV';
          if hsiccd ge 7530 and hsiccd le 7539   then FF48='PERSV';
          if hsiccd ge 7540 and hsiccd le 7549   then FF48='PERSV';
          if hsiccd ge 7600 and hsiccd le 7600   then FF48='PERSV';
          if hsiccd ge 7620 and hsiccd le 7620   then FF48='PERSV';
          if hsiccd ge 7622 and hsiccd le 7622   then FF48='PERSV';
          if hsiccd ge 7623 and hsiccd le 7623   then FF48='PERSV';
          if hsiccd ge 7629 and hsiccd le 7629   then FF48='PERSV';
          if hsiccd ge 7630 and hsiccd le 7631   then FF48='PERSV';
          if hsiccd ge 7640 and hsiccd le 7641   then FF48='PERSV';
          if hsiccd ge 7690 and hsiccd le 7699   then FF48='PERSV';
          if hsiccd ge 8100 and hsiccd le 8199   then FF48='PERSV';
          if hsiccd ge 8200 and hsiccd le 8299   then FF48='PERSV';
          if hsiccd ge 8300 and hsiccd le 8399   then FF48='PERSV';
          if hsiccd ge 8400 and hsiccd le 8499   then FF48='PERSV';
          if hsiccd ge 8600 and hsiccd le 8699   then FF48='PERSV';
          if hsiccd ge 8800 and hsiccd le 8899   then FF48='PERSV';
          if hsiccd ge 7510 and hsiccd le 7515   then FF48='PERSV';

*34 BusSv  Business Services;
          if hsiccd ge 2750 and hsiccd le 2759   then FF48='BUSSV';
          if hsiccd ge 3993 and hsiccd le 3993   then FF48='BUSSV';
          if hsiccd ge 7218 and hsiccd le 7218   then FF48='BUSSV';
          if hsiccd ge 7300 and hsiccd le 7300   then FF48='BUSSV';
          if hsiccd ge 7310 and hsiccd le 7319   then FF48='BUSSV';
          if hsiccd ge 7320 and hsiccd le 7329   then FF48='BUSSV';
          if hsiccd ge 7330 and hsiccd le 7339   then FF48='BUSSV';
          if hsiccd ge 7340 and hsiccd le 7342   then FF48='BUSSV';
          if hsiccd ge 7349 and hsiccd le 7349   then FF48='BUSSV';
          if hsiccd ge 7350 and hsiccd le 7351   then FF48='BUSSV';
          if hsiccd ge 7352 and hsiccd le 7352   then FF48='BUSSV';
          if hsiccd ge 7353 and hsiccd le 7353   then FF48='BUSSV';
          if hsiccd ge 7359 and hsiccd le 7359   then FF48='BUSSV';
          if hsiccd ge 7360 and hsiccd le 7369   then FF48='BUSSV';
          if hsiccd ge 7370 and hsiccd le 7372   then FF48='BUSSV';
          if hsiccd ge 7374 and hsiccd le 7374   then FF48='BUSSV';
          if hsiccd ge 7375 and hsiccd le 7375   then FF48='BUSSV';
          if hsiccd ge 7376 and hsiccd le 7376   then FF48='BUSSV';
          if hsiccd ge 7377 and hsiccd le 7377   then FF48='BUSSV';
          if hsiccd ge 7378 and hsiccd le 7378   then FF48='BUSSV';
          if hsiccd ge 7379 and hsiccd le 7379   then FF48='BUSSV';
          if hsiccd ge 7380 and hsiccd le 7380   then FF48='BUSSV';
          if hsiccd ge 7381 and hsiccd le 7382   then FF48='BUSSV';
          if hsiccd ge 7383 and hsiccd le 7383   then FF48='BUSSV';
          if hsiccd ge 7384 and hsiccd le 7384   then FF48='BUSSV';
          if hsiccd ge 7385 and hsiccd le 7385   then FF48='BUSSV';
          if hsiccd ge 7389 and hsiccd le 7390   then FF48='BUSSV';
          if hsiccd ge 7391 and hsiccd le 7391   then FF48='BUSSV';
          if hsiccd ge 7392 and hsiccd le 7392   then FF48='BUSSV';
          if hsiccd ge 7393 and hsiccd le 7393   then FF48='BUSSV';
          if hsiccd ge 7394 and hsiccd le 7394   then FF48='BUSSV';
          if hsiccd ge 7396 and hsiccd le 7396   then FF48='BUSSV';
          if hsiccd ge 7397 and hsiccd le 7397   then FF48='BUSSV';
          if hsiccd ge 7399 and hsiccd le 7399   then FF48='BUSSV';
          if hsiccd ge 7519 and hsiccd le 7519   then FF48='BUSSV';
          if hsiccd ge 8700 and hsiccd le 8700   then FF48='BUSSV';
          if hsiccd ge 8710 and hsiccd le 8713   then FF48='BUSSV';
          if hsiccd ge 8720 and hsiccd le 8721   then FF48='BUSSV';
          if hsiccd ge 8730 and hsiccd le 8734   then FF48='BUSSV';
          if hsiccd ge 8740 and hsiccd le 8748   then FF48='BUSSV';
          if hsiccd ge 8900 and hsiccd le 8910   then FF48='BUSSV';
          if hsiccd ge 8911 and hsiccd le 8911   then FF48='BUSSV';
          if hsiccd ge 8920 and hsiccd le 8999   then FF48='BUSSV';
          if hsiccd ge 4220 and hsiccd le 4229  then FF48='BUSSV';

*35 Comps  Computers;
          if hsiccd ge 3570 and hsiccd le 3579   then FF48='COMPS';
          if hsiccd ge 3680 and hsiccd le 3680   then FF48='COMPS';
          if hsiccd ge 3681 and hsiccd le 3681   then FF48='COMPS';
          if hsiccd ge 3682 and hsiccd le 3682   then FF48='COMPS';
          if hsiccd ge 3683 and hsiccd le 3683   then FF48='COMPS';
          if hsiccd ge 3684 and hsiccd le 3684   then FF48='COMPS';
          if hsiccd ge 3685 and hsiccd le 3685   then FF48='COMPS';
          if hsiccd ge 3686 and hsiccd le 3686   then FF48='COMPS';
          if hsiccd ge 3687 and hsiccd le 3687   then FF48='COMPS';
          if hsiccd ge 3688 and hsiccd le 3688   then FF48='COMPS';
          if hsiccd ge 3689 and hsiccd le 3689   then FF48='COMPS';
          if hsiccd ge 3695 and hsiccd le 3695   then FF48='COMPS';
          if hsiccd ge 7373 and hsiccd le 7373   then FF48='COMPS';

*36 Chips  Electronic Equipment;
          if hsiccd ge 3622 and hsiccd le 3622   then FF48='CHIPS';
          if hsiccd ge 3661 and hsiccd le 3661   then FF48='CHIPS';
          if hsiccd ge 3662 and hsiccd le 3662   then FF48='CHIPS';
          if hsiccd ge 3663 and hsiccd le 3663   then FF48='CHIPS';
          if hsiccd ge 3664 and hsiccd le 3664   then FF48='CHIPS';
          if hsiccd ge 3665 and hsiccd le 3665   then FF48='CHIPS';
          if hsiccd ge 3666 and hsiccd le 3666   then FF48='CHIPS';
          if hsiccd ge 3669 and hsiccd le 3669   then FF48='CHIPS';
          if hsiccd ge 3670 and hsiccd le 3679   then FF48='CHIPS';
          if hsiccd ge 3810 and hsiccd le 3810   then FF48='CHIPS';
          if hsiccd ge 3812 and hsiccd le 3812   then FF48='CHIPS';

*37 LabEq  Measuring and Control Equipment;
          if hsiccd ge 3811 and hsiccd le 3811   then FF48='LABEQ';
          if hsiccd ge 3820 and hsiccd le 3820   then FF48='LABEQ';
          if hsiccd ge 3821 and hsiccd le 3821   then FF48='LABEQ';
          if hsiccd ge 3822 and hsiccd le 3822   then FF48='LABEQ';
          if hsiccd ge 3823 and hsiccd le 3823   then FF48='LABEQ';
          if hsiccd ge 3824 and hsiccd le 3824   then FF48='LABEQ';
          if hsiccd ge 3825 and hsiccd le 3825   then FF48='LABEQ';
          if hsiccd ge 3826 and hsiccd le 3826   then FF48='LABEQ';
          if hsiccd ge 3827 and hsiccd le 3827   then FF48='LABEQ';
          if hsiccd ge 3829 and hsiccd le 3829   then FF48='LABEQ';
          if hsiccd ge 3830 and hsiccd le 3839   then FF48='LABEQ';

*38 Paper  Business Supplies;
          if hsiccd ge 2520 and hsiccd le 2549   then FF48='PAPER';
          if hsiccd ge 2600 and hsiccd le 2639   then FF48='PAPER';
          if hsiccd ge 2670 and hsiccd le 2699   then FF48='PAPER';
          if hsiccd ge 2760 and hsiccd le 2761   then FF48='PAPER';
          if hsiccd ge 3950 and hsiccd le 3955   then FF48='PAPER';

*39 Boxes  Shipping Containers;
          if hsiccd ge 2440 and hsiccd le 2449   then FF48='BOXES';
          if hsiccd ge 2640 and hsiccd le 2659   then FF48='BOXES';
          if hsiccd ge 3220 and hsiccd le 3221   then FF48='BOXES';
          if hsiccd ge 3410 and hsiccd le 3412   then FF48='BOXES';

*40 Trans  Transportation;
          if hsiccd ge 4000 and hsiccd le 4013   then FF48='TRANS';
          if hsiccd ge 4040 and hsiccd le 4049   then FF48='TRANS';
          if hsiccd ge 4100 and hsiccd le 4100   then FF48='TRANS';
          if hsiccd ge 4110 and hsiccd le 4119   then FF48='TRANS';
          if hsiccd ge 4120 and hsiccd le 4121   then FF48='TRANS';
          if hsiccd ge 4130 and hsiccd le 4131   then FF48='TRANS';
          if hsiccd ge 4140 and hsiccd le 4142   then FF48='TRANS';
          if hsiccd ge 4150 and hsiccd le 4151   then FF48='TRANS';
          if hsiccd ge 4170 and hsiccd le 4173   then FF48='TRANS';
          if hsiccd ge 4190 and hsiccd le 4199   then FF48='TRANS';
          if hsiccd ge 4200 and hsiccd le 4200   then FF48='TRANS';
          if hsiccd ge 4210 and hsiccd le 4219   then FF48='TRANS';
          if hsiccd ge 4230 and hsiccd le 4231   then FF48='TRANS';
          if hsiccd ge 4240 and hsiccd le 4249   then FF48='TRANS';
          if hsiccd ge 4400 and hsiccd le 4499   then FF48='TRANS';
          if hsiccd ge 4500 and hsiccd le 4599   then FF48='TRANS';
          if hsiccd ge 4600 and hsiccd le 4699   then FF48='TRANS';
          if hsiccd ge 4700 and hsiccd le 4700   then FF48='TRANS';
          if hsiccd ge 4710 and hsiccd le 4712   then FF48='TRANS';
          if hsiccd ge 4720 and hsiccd le 4729   then FF48='TRANS';
          if hsiccd ge 4730 and hsiccd le 4739   then FF48='TRANS';
          if hsiccd ge 4740 and hsiccd le 4749   then FF48='TRANS';
          if hsiccd ge 4780 and hsiccd le 4780   then FF48='TRANS';
          if hsiccd ge 4782 and hsiccd le 4782   then FF48='TRANS';
          if hsiccd ge 4783 and hsiccd le 4783   then FF48='TRANS';
          if hsiccd ge 4784 and hsiccd le 4784   then FF48='TRANS';
          if hsiccd ge 4785 and hsiccd le 4785   then FF48='TRANS';
          if hsiccd ge 4789 and hsiccd le 4789   then FF48='TRANS';

*41 Whlsl  Wholesale;
          if hsiccd ge 5000 and hsiccd le 5000   then FF48='WHLSL';
          if hsiccd ge 5010 and hsiccd le 5015   then FF48='WHLSL';
          if hsiccd ge 5020 and hsiccd le 5023   then FF48='WHLSL';
          if hsiccd ge 5030 and hsiccd le 5039   then FF48='WHLSL';
          if hsiccd ge 5040 and hsiccd le 5042   then FF48='WHLSL';
          if hsiccd ge 5043 and hsiccd le 5043   then FF48='WHLSL';
          if hsiccd ge 5044 and hsiccd le 5044   then FF48='WHLSL';
          if hsiccd ge 5045 and hsiccd le 5045   then FF48='WHLSL';
          if hsiccd ge 5046 and hsiccd le 5046   then FF48='WHLSL';
          if hsiccd ge 5047 and hsiccd le 5047   then FF48='WHLSL';
          if hsiccd ge 5048 and hsiccd le 5048   then FF48='WHLSL';
          if hsiccd ge 5049 and hsiccd le 5049   then FF48='WHLSL';
          if hsiccd ge 5050 and hsiccd le 5059   then FF48='WHLSL';
          if hsiccd ge 5060 and hsiccd le 5060   then FF48='WHLSL';
          if hsiccd ge 5063 and hsiccd le 5063   then FF48='WHLSL';
          if hsiccd ge 5064 and hsiccd le 5064   then FF48='WHLSL';
          if hsiccd ge 5065 and hsiccd le 5065   then FF48='WHLSL';
          if hsiccd ge 5070 and hsiccd le 5078   then FF48='WHLSL';
          if hsiccd ge 5080 and hsiccd le 5080   then FF48='WHLSL';
          if hsiccd ge 5081 and hsiccd le 5081   then FF48='WHLSL';
          if hsiccd ge 5082 and hsiccd le 5082   then FF48='WHLSL';
          if hsiccd ge 5083 and hsiccd le 5083   then FF48='WHLSL';
          if hsiccd ge 5084 and hsiccd le 5084   then FF48='WHLSL';
          if hsiccd ge 5085 and hsiccd le 5085   then FF48='WHLSL';
          if hsiccd ge 5086 and hsiccd le 5087   then FF48='WHLSL';
          if hsiccd ge 5088 and hsiccd le 5088   then FF48='WHLSL';
          if hsiccd ge 5090 and hsiccd le 5090   then FF48='WHLSL';
          if hsiccd ge 5091 and hsiccd le 5092   then FF48='WHLSL';
          if hsiccd ge 5093 and hsiccd le 5093   then FF48='WHLSL';
          if hsiccd ge 5094 and hsiccd le 5094   then FF48='WHLSL';
          if hsiccd ge 5099 and hsiccd le 5099   then FF48='WHLSL';
          if hsiccd ge 5100 and hsiccd le 5100   then FF48='WHLSL';
          if hsiccd ge 5110 and hsiccd le 5113   then FF48='WHLSL';
          if hsiccd ge 5120 and hsiccd le 5122   then FF48='WHLSL';
          if hsiccd ge 5130 and hsiccd le 5139   then FF48='WHLSL';
          if hsiccd ge 5140 and hsiccd le 5149   then FF48='WHLSL';
          if hsiccd ge 5150 and hsiccd le 5159   then FF48='WHLSL';
          if hsiccd ge 5160 and hsiccd le 5169   then FF48='WHLSL';
          if hsiccd ge 5170 and hsiccd le 5172   then FF48='WHLSL';
          if hsiccd ge 5180 and hsiccd le 5182   then FF48='WHLSL';
          if hsiccd ge 5190 and hsiccd le 5199   then FF48='WHLSL';

*42 Rtail  Retail ;
          if hsiccd ge 5200 and hsiccd le 5200   then FF48='RTAIL';
          if hsiccd ge 5210 and hsiccd le 5219   then FF48='RTAIL';
          if hsiccd ge 5220 and hsiccd le 5229   then FF48='RTAIL';
          if hsiccd ge 5230 and hsiccd le 5231   then FF48='RTAIL';
          if hsiccd ge 5250 and hsiccd le 5251   then FF48='RTAIL';
          if hsiccd ge 5260 and hsiccd le 5261   then FF48='RTAIL';
          if hsiccd ge 5270 and hsiccd le 5271   then FF48='RTAIL';
          if hsiccd ge 5300 and hsiccd le 5300   then FF48='RTAIL';
          if hsiccd ge 5310 and hsiccd le 5311   then FF48='RTAIL';
          if hsiccd ge 5320 and hsiccd le 5320   then FF48='RTAIL';
          if hsiccd ge 5330 and hsiccd le 5331   then FF48='RTAIL';
          if hsiccd ge 5334 and hsiccd le 5334   then FF48='RTAIL';
          if hsiccd ge 5340 and hsiccd le 5349   then FF48='RTAIL';
          if hsiccd ge 5390 and hsiccd le 5399   then FF48='RTAIL';
          if hsiccd ge 5400 and hsiccd le 5400   then FF48='RTAIL';
          if hsiccd ge 5410 and hsiccd le 5411   then FF48='RTAIL';
          if hsiccd ge 5412 and hsiccd le 5412   then FF48='RTAIL';
          if hsiccd ge 5420 and hsiccd le 5429   then FF48='RTAIL';
          if hsiccd ge 5430 and hsiccd le 5439   then FF48='RTAIL';
          if hsiccd ge 5440 and hsiccd le 5449   then FF48='RTAIL';
          if hsiccd ge 5450 and hsiccd le 5459   then FF48='RTAIL';
          if hsiccd ge 5460 and hsiccd le 5469   then FF48='RTAIL';
          if hsiccd ge 5490 and hsiccd le 5499   then FF48='RTAIL';
          if hsiccd ge 5500 and hsiccd le 5500   then FF48='RTAIL';
          if hsiccd ge 5510 and hsiccd le 5529   then FF48='RTAIL';
          if hsiccd ge 5530 and hsiccd le 5539   then FF48='RTAIL';
          if hsiccd ge 5540 and hsiccd le 5549   then FF48='RTAIL';
          if hsiccd ge 5550 and hsiccd le 5559   then FF48='RTAIL';
          if hsiccd ge 5560 and hsiccd le 5569   then FF48='RTAIL';
          if hsiccd ge 5570 and hsiccd le 5579   then FF48='RTAIL';
          if hsiccd ge 5590 and hsiccd le 5599   then FF48='RTAIL';
          if hsiccd ge 5600 and hsiccd le 5699   then FF48='RTAIL';
          if hsiccd ge 5700 and hsiccd le 5700   then FF48='RTAIL';
          if hsiccd ge 5710 and hsiccd le 5719   then FF48='RTAIL';
          if hsiccd ge 5720 and hsiccd le 5722   then FF48='RTAIL';
          if hsiccd ge 5730 and hsiccd le 5733   then FF48='RTAIL';
          if hsiccd ge 5734 and hsiccd le 5734   then FF48='RTAIL';
          if hsiccd ge 5735 and hsiccd le 5735   then FF48='RTAIL';
          if hsiccd ge 5736 and hsiccd le 5736   then FF48='RTAIL';
          if hsiccd ge 5750 and hsiccd le 5799   then FF48='RTAIL';
          if hsiccd ge 5900 and hsiccd le 5900   then FF48='RTAIL';
          if hsiccd ge 5910 and hsiccd le 5912   then FF48='RTAIL';
          if hsiccd ge 5920 and hsiccd le 5929   then FF48='RTAIL';
          if hsiccd ge 5930 and hsiccd le 5932   then FF48='RTAIL';
          if hsiccd ge 5940 and hsiccd le 5940   then FF48='RTAIL';
          if hsiccd ge 5941 and hsiccd le 5941   then FF48='RTAIL';
          if hsiccd ge 5942 and hsiccd le 5942   then FF48='RTAIL';
          if hsiccd ge 5943 and hsiccd le 5943   then FF48='RTAIL';
          if hsiccd ge 5944 and hsiccd le 5944   then FF48='RTAIL';
          if hsiccd ge 5945 and hsiccd le 5945   then FF48='RTAIL';
          if hsiccd ge 5946 and hsiccd le 5946   then FF48='RTAIL';
          if hsiccd ge 5947 and hsiccd le 5947   then FF48='RTAIL';
          if hsiccd ge 5948 and hsiccd le 5948   then FF48='RTAIL';
          if hsiccd ge 5949 and hsiccd le 5949   then FF48='RTAIL';
          if hsiccd ge 5950 and hsiccd le 5959   then FF48='RTAIL';
          if hsiccd ge 5960 and hsiccd le 5969   then FF48='RTAIL';
          if hsiccd ge 5970 and hsiccd le 5979   then FF48='RTAIL';
          if hsiccd ge 5980 and hsiccd le 5989   then FF48='RTAIL';
          if hsiccd ge 5990 and hsiccd le 5990   then FF48='RTAIL';
          if hsiccd ge 5992 and hsiccd le 5992   then FF48='RTAIL';
          if hsiccd ge 5993 and hsiccd le 5993   then FF48='RTAIL';
          if hsiccd ge 5994 and hsiccd le 5994   then FF48='RTAIL';
          if hsiccd ge 5995 and hsiccd le 5995   then FF48='RTAIL';
          if hsiccd ge 5999 and hsiccd le 5999   then FF48='RTAIL';

*43 Meals  Restaraunts, Hotels, Motels;
          if hsiccd ge 5800 and hsiccd le 5819   then FF48='MEALS';
          if hsiccd ge 5820 and hsiccd le 5829   then FF48='MEALS';
          if hsiccd ge 5890 and hsiccd le 5899   then FF48='MEALS';
          if hsiccd ge 7000 and hsiccd le 7000   then FF48='MEALS';
          if hsiccd ge 7010 and hsiccd le 7019   then FF48='MEALS';
          if hsiccd ge 7040 and hsiccd le 7049   then FF48='MEALS';
          if hsiccd ge 7213 and hsiccd le 7213   then FF48='MEALS';

*44 Banks  Banking;
          if hsiccd ge 6000 and hsiccd le 6000   then FF48='BANKS';
          if hsiccd ge 6010 and hsiccd le 6019   then FF48='BANKS';
          if hsiccd ge 6020 and hsiccd le 6020   then FF48='BANKS';
          if hsiccd ge 6021 and hsiccd le 6021   then FF48='BANKS';
          if hsiccd ge 6022 and hsiccd le 6022   then FF48='BANKS';
          if hsiccd ge 6023 and hsiccd le 6024   then FF48='BANKS';
          if hsiccd ge 6025 and hsiccd le 6025   then FF48='BANKS';
          if hsiccd ge 6026 and hsiccd le 6026   then FF48='BANKS';
          if hsiccd ge 6027 and hsiccd le 6027   then FF48='BANKS';
          if hsiccd ge 6028 and hsiccd le 6029   then FF48='BANKS';
          if hsiccd ge 6030 and hsiccd le 6036   then FF48='BANKS';
          if hsiccd ge 6040 and hsiccd le 6059   then FF48='BANKS';
          if hsiccd ge 6060 and hsiccd le 6062   then FF48='BANKS';
          if hsiccd ge 6080 and hsiccd le 6082   then FF48='BANKS';
          if hsiccd ge 6090 and hsiccd le 6099   then FF48='BANKS';
          if hsiccd ge 6100 and hsiccd le 6100   then FF48='BANKS';
          if hsiccd ge 6110 and hsiccd le 6111   then FF48='BANKS';
          if hsiccd ge 6112 and hsiccd le 6113   then FF48='BANKS';
          if hsiccd ge 6120 and hsiccd le 6129   then FF48='BANKS';
          if hsiccd ge 6130 and hsiccd le 6139   then FF48='BANKS';
          if hsiccd ge 6140 and hsiccd le 6149   then FF48='BANKS';
          if hsiccd ge 6150 and hsiccd le 6159   then FF48='BANKS';
          if hsiccd ge 6160 and hsiccd le 6169   then FF48='BANKS';
          if hsiccd ge 6170 and hsiccd le 6179   then FF48='BANKS';
          if hsiccd ge 6190 and hsiccd le 6199   then FF48='BANKS';

*45 Insur  Insurance;
          if hsiccd ge 6300 and hsiccd le 6300   then FF48='INSUR';
          if hsiccd ge 6310 and hsiccd le 6319   then FF48='INSUR';
          if hsiccd ge 6320 and hsiccd le 6329   then FF48='INSUR';
          if hsiccd ge 6330 and hsiccd le 6331   then FF48='INSUR';
          if hsiccd ge 6350 and hsiccd le 6351   then FF48='INSUR';
          if hsiccd ge 6360 and hsiccd le 6361   then FF48='INSUR';
          if hsiccd ge 6370 and hsiccd le 6379   then FF48='INSUR';
          if hsiccd ge 6390 and hsiccd le 6399   then FF48='INSUR';
          if hsiccd ge 6400 and hsiccd le 6411   then FF48='INSUR';

*46 RlEst  Real Estate;
          if hsiccd ge 6500 and hsiccd le 6500   then FF48='RLEST';
          if hsiccd ge 6510 and hsiccd le 6510   then FF48='RLEST';
          if hsiccd ge 6512 and hsiccd le 6512   then FF48='RLEST';
          if hsiccd ge 6513 and hsiccd le 6513   then FF48='RLEST';
          if hsiccd ge 6514 and hsiccd le 6514   then FF48='RLEST';
          if hsiccd ge 6515 and hsiccd le 6515   then FF48='RLEST';
          if hsiccd ge 6517 and hsiccd le 6519   then FF48='RLEST';
          if hsiccd ge 6520 and hsiccd le 6529   then FF48='RLEST';
          if hsiccd ge 6530 and hsiccd le 6531   then FF48='RLEST';
          if hsiccd ge 6532 and hsiccd le 6532   then FF48='RLEST';
          if hsiccd ge 6540 and hsiccd le 6541   then FF48='RLEST';
          if hsiccd ge 6550 and hsiccd le 6553   then FF48='RLEST';
          if hsiccd ge 6590 and hsiccd le 6599   then FF48='RLEST';
          if hsiccd ge 6610 and hsiccd le 6611   then FF48='RLEST';

*47 Fin    Trading;
          if hsiccd ge 6200 and hsiccd le 6299   then FF48='FIN';
          if hsiccd ge 6700 and hsiccd le 6700   then FF48='FIN';
          if hsiccd ge 6710 and hsiccd le 6719   then FF48='FIN';
          if hsiccd ge 6720 and hsiccd le 6722   then FF48='FIN';
          if hsiccd ge 6723 and hsiccd le 6723   then FF48='FIN';
          if hsiccd ge 6724 and hsiccd le 6724   then FF48='FIN';
          if hsiccd ge 6725 and hsiccd le 6725   then FF48='FIN';
          if hsiccd ge 6726 and hsiccd le 6726   then FF48='FIN';
          if hsiccd ge 6730 and hsiccd le 6733   then FF48='FIN';
          if hsiccd ge 6740 and hsiccd le 6779   then FF48='FIN';
          if hsiccd ge 6790 and hsiccd le 6791   then FF48='FIN';
          if hsiccd ge 6792 and hsiccd le 6792   then FF48='FIN';
          if hsiccd ge 6793 and hsiccd le 6793   then FF48='FIN';
          if hsiccd ge 6794 and hsiccd le 6794   then FF48='FIN';
          if hsiccd ge 6795 and hsiccd le 6795   then FF48='FIN';
          if hsiccd ge 6798 and hsiccd le 6798   then FF48='FIN';
          if hsiccd ge 6799 and hsiccd le 6799   then FF48='FIN';

*48 Other  Almost Nothing;
          if hsiccd ge 4950 and hsiccd le 4959   then FF48='OTHER';
          if hsiccd ge 4960 and hsiccd le 4961   then FF48='OTHER';
          if hsiccd ge 4970 and hsiccd le 4971   then FF48='OTHER';
          if hsiccd ge 4990 and hsiccd le 4991   then FF48='OTHER'; 
          if hsiccd ge 9990 and hsiccd le 9999   then FF48='OTHER'; 
run;

data my.funda_part; set funda3; run;
 
/**** Start of computing returns, volatility and beta in the past 3 years; ****/
data ret; set crsp.msf(where=(not missing(ret))); keep permno date ret; run;
proc sort data = ret; by permno date; run;

data ret; set ret; D=1; run; *add d for counting number of obs computing ret and vol;
proc expand data = ret OUT = ret_3yr; *mov uses data from t to t-n+1;;
	by permno;
	id date;
    
	convert ret = ret_3yr / TRANSFORMOUT=(+1 MOVPROD 36 -1);
 	convert D = count_ret / TRANSFORMOUT=(movsum 36);

 	convert ret = std_3yr / TRANSFORMOUT=(movstd 36 TRIMLEFT 12);
 	convert D = count_std / TRANSFORMOUT=(movsum 36 TRIMLEFT 12);
run;

data my.ret_vol; set ret_3yr; 
ret_ann = ret_3yr / 3; 
std_ann = std_3yr * sqrt(12);
label ret_ann = 'annualized return in past 3 yr' 
std_ann= 'annualized std in past 3 yr';
drop D ret_3yr std_3yr; 
run;

* compute beta;
proc sql;
create table beta as select a.*, b.mktrf, ret-rf as exret
from ret as a left join 'E:\Data\ff_m' as b
on (a.date) = (b.dateff) 
order by permno, date;
quit;
 
%macro betaloop(dat,yybeginning, yyend);
 %do yy = &yybeginning %to &yyend;
 %do mm = 1 %to 12;

 %let xmonths= %eval(36); *Sample period length in months;
 %let date1=%sysfunc(mdy(&mm,1,&yy));
 %let date1 = %sysfunc (intnx(month, &date1, 0, begin)); *set DATE1 as first (begin) day;
 %let date2= %sysfunc (intnx(month, &date1, &xmonths-1,end)); *Make the DATE2 last day of the month;

 *Regression model estimation -- creates output set with coefficient estimates;
  proc reg noprint data=&dat outest=temp_para1 edf;
      where date between &date1 and &date2;  
      model exret = mktrf;
      by permno;
  run;

 data temp_para;
     set temp_para1(rename=(mktrf=beta));
     date1=&date1;
     date2=&date2;
     nobs= _p_ + _edf_;
     format date1 date2 yymmdd10.;
     keep permno date1 date2 beta nobs;
 run;

  * Append loop results to dataset with all observations between date1 and date2;
  proc append base=temp_beta data=temp_para force;
  run; 
 
  %end;  %* MM month loop;
  %end; %* YY year loop;

  %mend betaloop;

%betaloop(beta,1997,2017);

proc sql;
create table my.crsp_3yr as select a.*, b.beta, b.nobs as count_beta
from ret_vol as a left join temp_beta as b
on a.permno=b.permno and year(date)=year(date2) and month(date)=month(date2)
order by permno, date;
quit;

data crsp_3yr; set my.crsp_3yr; if year(date)>=2000; run;
/** End of computing beta, std, and ret**/


* merge ret, vol and beta with fundamentals;
proc sql;
create table funda4 as select a.*, b.ret_ann, count_ret, std_ann,count_std, beta, count_beta
from my.funda_part as a left join my.crsp_3yr as b
on a.permno=b.permno and cyear=year(b.date) and fyr=month(b.date)
order by gvkey, fyear, fyr;
quit;

data funda4; set funda4; 
label count_ret='Nb of obs computing returns'
count_std = 'Nb of obs computing std'
count_beta='Nb of obs computing beta'
beta = 'beta';
run;


/**** Start of Computing correlation bw RPE firms and other firms ****/
* Get peers;
proc sql;
    create table relpeer as select unique a.cik, b.fycompustat, a.peercik
	from inclab.gpbarelpeer as a left join my.grant_fvj as b
	on a.grantid = b.grantid
	where a.cik~='' and peercik ~= .
    order by cik, fycompustat;
quit;

* get the smallest size of peers for each RPE firm-fyear;
data funda; set funda4; cik2= input( cik, best.);run;

proc sql;
create table relpeer2 as select a.*, size as peersize
from relpeer as a left join funda as b
on a.peercik = b.cik2 and a.fycompustat = b.fyear
order by cik, peercik, fycompustat;

proc sql;
create table rpe as select unique cik, fycompustat, min(peersize) as min_peersize
from relpeer2 
group by cik, fycompustat
order by cik, fycompustat;
quit;

* get fiscalyear-end cym;
proc sql;
create table rpe as select a.*, cyear, fyr
from rpe as a left join funda as b
on a.cik = b.cik and a.fycompustat = b.fyear
order by cik, fycompustat;

data rpe2; set rpe; 
if fycompustat > 2004 and not missing(min_peersize); *cannot find a match if non of its peers has size;
cym = intnx('month', mdy(fyr,1,cyear), 0,'end');
if missing(cym) then cym = intnx('month', mdy(12,1,fycompustat), 0,'end');*assuming fyr ends in dec if missing;
format cym MMDDYY10.; 
run; *2261;

data my.rpe; set rpe2; run;

* get monthly ret in the past 3 yrs for RPE firms;
*the following codes are run in wrds server;
libname celim '/home/uga/celim';

* get the intersection of CRSP and Compustat;
proc sql;
   create table comp_crsp
   as select unique a.cik, a.gvkey, log(a.at) as size, c.permno, c.date, c.ret
   from comp.funda as a,
		CRSPA.CCMXPF_LNKHIST as b,		
		crsp.msf as c,
		crsp.msenames as d
	where a.gvkey=b.gvkey and consol='C' and indfmt='INDL' and datafmt='STD' and popsrc='D' and 
    linkprim in ('P','C') and LINKTYPE in ("LU", "LC", "LN", "LS") and
	(c.date >= b.linkdt or b.LINKDT = .B) and (c.date <= b.linkenddt or b.LINKENDDT = .E)
   and b.lpermno=c.permno and year(a.datadate) = year(c.date) 
   and c.permno = d.permno and NAMEDT<=c.date<=NAMEENDT and shrcd in (10,11,12,18)
   and a.cik ~='' and a.fyear>2004-3 and not missing(c.ret) and calculated size>=0
   order by cik, gvkey, permno, date;
quit;


/* cik-date and permno-date are unique, but same permno may give to different ciks at different time;
proc sql; create table temp as select cik, permno, date, ret, count(*) as c from comp_crsp group by cik, date order by c desc, cik, date; * no duplicates;

data temp; set comp_crsp; run;
proc sort data=temp nodupkey; by cik; run;
proc sql; create table temp as select *, count(*) as c from temp group by permno order by c desc, permno, cik, date; 
*/

* get ret for RPE firms;
proc sql;
create table rpe_ret as select a.*, b.date, b.ret
from celim.rpe as a left join comp_crsp as b
on a.cik = b.cik and cym >= b.date and b.date > intnx('year',cym, -3,'same')
order by cik, fycompustat, date;
quit; *72541;

* get monthly ret for the firms whose size <= the min of peers';
proc sql;
create table rpe_ret2 as select a.*, b.cik as cik_other, b.ret as ret_other
from rpe_ret as a left join comp_crsp as b
on a.cik ~= b.cik and a.date = b.date and a.min_peersize <= b.size
order by cym, cik, cik_other, date; *95494876;

* compute corr;
* count the number of obs for each regression;
proc sql;
create table rpe_ret2 as select *, count(*) as c 
from rpe_ret2 
group by cym, cik, cik_other
order by cym, cik, cik_other, date;
quit;

data rpe_ret3; set rpe_ret2; if c>=12; run;*94322324;

proc corr data=rpe_ret3 OUTP = corr;
by cym cik cik_other;
var ret ret_other;
run; 

data N; set corr;
if _type_ = 'N' ;
keep cym cik cik_other ret_other;
rename ret_other = N_corr;
run;

data corr2; set corr; 
if (_type_ = 'CORR' and _name_ = 'RET' );
keep cym cik cik_other ret_other;
rename ret_other = corr;
run;

data celim.corr; merge corr2 N; run;*2,947,654;

** back to local computer;
* remove lables;
proc datasets lib=my memtype=corr;
   modify class;
     attrib _all_ label=' ';
run;
/** End of computing corr **/



/**** Compute HHI ****/
libname seg 'E:\Data\CompNA\segments';

proc sql;
  create table segcus as select a.gvkey, a.cnms, a.salecs, a.datadate, b.cik, b.revt
  from seg.seg_customer as a join compna.funda as b
  on a.gvkey = b.gvkey and a.datadate = b.datadate;
quit;

data segcus; set segcus; 
if salecs < 0 then salecs=.; if revt < 0 then revt=.; 
salecs_shr = salecs / revt;
salecs_shr_sq = salecs_shr * salecs_shr; 
if cik ~= ''; 
run;

* Calculate sum(shares) and delete data w/ sum(shares) > 1 ;
proc sql;
create table segcus2 as select cik, datadate, count(*) as ncus, sum(salecs_shr) as TSDEP,sum(salecs_shr_sq) as HHI
from segcus 
group by cik, datadate
order by cik, datadate;

data segcus2; set segcus2; 
if TSDEP > 1 then HHI=.; 
label tsdep='Total sales/total revenue'
ncus = 'Number of custormers';
run;

data segcus3; set segcus2; fyear = year(datadate); if month(datadate)<6 then fyear=fyear-1; run;

data my.segcus; set segcus3; run;

* no duplicates;
proc sort data=segcus3; by cik fyear datadate;run;
data segcus3; set segcus3; by cik fyear datadate; if last.fyear; run;

proc sql;
create table funda4 as select a.*, b.tsdep, b.HHI
from funda4 as a left join my.segcus as b 
on a.cik = b.cik and a.fyear = b.fyear
order by cik, cym;

data funda4; set funda4; 
if TSDEP > 1 then HHI=.; *missing for inaccurate sales pct;
if TSDEP =. then HHI=0; * 0 if not matched;
run;

data my.funda_part; set funda4; run;

/**** Compute institutional ownship ****/
* see wrds_OI for codes;
data io; set my.io; run;

proc sql; 
create table io as select distinct permno, rdate, IOR
from io
order by permno, rdate;

* merge with funda;
data funda4; set funda4; 
cym = intnx('month', cym, 0,'end');
format cym MMDDYY10.; 
run;

*use IOR in the quarter closest to the fiscalyear end;
proc sql;
create table temp as select a.*, b.rdate, b.IOR 
from funda4 as a left join io as b
on a.permno = b.permno and intnx('month',cym, -3,'same') <= rdate <= cym
order by cik, cym, rdate;

data funda5; set temp; by cik cym rdate; if last.cym; run;*cik and permno are 1:1 when permno not missing;

data funda5; set funda5; if IOR=. then IOR=0; if IOR>1 then IOR=.; run;

data my.funda_part; set funda5; run;

* Get subsamples used for merging with RPE and report Summary stat;
data funda; set my.funda_part; if cik ~= '' and fyear > 2004; run;*87335;

proc sort data = funda nodupkey; by cik fyear; run;*no duplicates;

* summ;
proc means data=funda mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max;
    vars at size bm ret_ann std_ann beta ratings IOR HHI;
run;

proc means data=my.corr mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max;
    vars corr;
run;

proc freq data=funda;
table sic2 ff48 sp500 sp1500 splticrm;
run;

proc sql;create table temp as select count(unique cik) from funda;*8508 firms; quit;


/* winsorize */
%macro winsor(dsetin=, dsetout=, byvar=none, vars=, type=winsor, pctl=1 99);
  
%if &dsetout = %then %let dsetout = &dsetin;
     
%let varL=;
%let varH=;
%let xn=1;
  
%do %until ( %scan(&vars,&xn)= );
    %let token = %scan(&vars,&xn);
    %let varL = &varL &token.L;
    %let varH = &varH &token.H;
    %let xn=%EVAL(&xn + 1);
%end;
  
%let xn=%eval(&xn-1);
  
data xtemp;
    set &dsetin;
    run;
  
%if &byvar = none %then %do;
  
    data xtemp;
        set xtemp;
        xbyvar = 1;
        run;
  
    %let byvar = xbyvar;
  
%end;
  
proc sort data = xtemp;
    by &byvar;
    run;
  
proc univariate data = xtemp noprint;
    by &byvar;
    var &vars;
    output out = xtemp_pctl PCTLPTS = &pctl PCTLPRE = &vars PCTLNAME = L H;
    run;
  
data &dsetout;
    merge xtemp xtemp_pctl;
    by &byvar;
    array trimvars{&xn} &vars;
    array trimvarl{&xn} &varL;
    array trimvarh{&xn} &varH;
  
    do xi = 1 to dim(trimvars);
  
        %if &type = winsor %then %do;
            if not missing(trimvars{xi}) then do;
              if (trimvars{xi} < trimvarl{xi}) then trimvars{xi} = trimvarl{xi};
              if (trimvars{xi} > trimvarh{xi}) then trimvars{xi} = trimvarh{xi};
            end;
        %end;
  
        %else %do;
            if not missing(trimvars{xi}) then do;
              if (trimvars{xi} < trimvarl{xi}) then delete;
              if (trimvars{xi} > trimvarh{xi}) then delete;
            end;
        %end;
  
    end;
    drop &varL &varH xbyvar xi;

    run;
  
%mend winsor;

%winsor(dsetin=funda, dsetout=funda_w, vars=bm beta, type=winsor, pctl=1 99);

data funda_w; set funda_w; 
if count_ret < 12 then ret_ann=.;
if count_std < 12 then std_ann = .;
if count_beta < 12 then beta =.;
run;

* substitute median for missing ratings;
proc sql; create table funda_w as select *, median(ratings) as med_ratings from funda_w; *same every year, except 2016;

data funda_w;set funda_w; drop med_ratings;
if ratings =. then ratings = med_ratings;
run;

proc sql;
create table funda as select a.*, b.roa, b.q, b.lvg from 
funda_w as a left join freq.funda_computed as b
on a.gvkey=b.gvkey and a.fyear = b.fyear;

proc means data=funda mean std min P1 p5 p10 p90 p95 p99 max ; vars roa q lvg;run;

%winsor(dsetin=funda, dsetout=funda_w, vars=roa q lvg, type=winsor, pctl=1 99);

data my.funda_w; set funda_w; run;

/**** Get fundamentals for RPE firms ****/
/**** Contemparaneous 
proc sql;
create table rpe_var as select a.cik,b.gvkey,b.permno,a.fycompustat,a.fyr,a.cym, a.min_peersize,
at, size, be,mc,bm,HSICCD,sic2,ff48,sp500,sp1500,splticrm,ratings,ret_ann,std_ann,beta,IOR, HHI
from my.rpe as a left join my.funda_w as b
on a.cik = b.cik and a.fycompustat = b.fyear
order by cik, fycompustat;
quit;

* Merge fundamentals of other firms;
proc sql;  
create table temp.psm as select a.*, b.cik as cik_other, 
b.at as at_other, b.size as size_other, b.mc as mc_other,b.bm as bm_other, b.HSICCD as hsiccd_other,b.sic2 as sic2_other,b.ff48 as ff48_other,
b.sp500 as sp500_other,b.sp1500 as sp1500_other,b.splticrm as splticrm_other ,b.ratings as ratings_other,b.ret_ann as ret_ann_other,b.std_ann as std_ann_other,b.beta as beta_other,b.IOR as IOR_other, b.HHI as HHI_other
from rpe_var as a left join my.funda_w as b
on a.cik ~= b.cik and a.fycompustat=b.fyear
order by cik, cik_other;
quit;

* Merge correlation of other firms with RPE firms, less firms merged if combined with rpe_var directly;
proc sql;
create table temp.psm2 as select a.*, corr, N_corr
from temp.psm as a left join my.corr as b
on a.cik=b.cik and a.cik_other = b.cik_other and a.cym=b.cym
order by cik, cym, cik_other;
quit;

** Dummy actual peers;
data psm2; set psm2; cik_other2 = input( cik_other, best.); if cik_other ~=. ; run;

proc sql;
create table psm3 as select a.*, peercik
from psm2 as a left join relpeer as b
on a.cik=b.cik and a.cik_other2=b.peercik and a.fycompustat=b.fycompustat
order by cik, cym, cik_other;

data psm3; set psm3; drop peercik; if peercik =. then D_actualpeer = 0; else d_actualpeer = 1; run;

proc sql;create table temp as select unique sum(D_actualpeer) from psm3; *32209;
* total firms over actual peers is 11,051,577/ 32209 = 343 : 1 ;
***/

/* Get lagged variables; */
proc sql;
create table rpe_var as select a.cik,b.gvkey,b.permno,a.fycompustat,a.fyr,a.cym, a.min_peersize,
size as size_lag, bm as bm_lag,sic2 as sic2_lag,sp500 as sp500_lag,sp1500 as sp1500_lag,ratings as ratings_lag,
ret_ann as ret_lag,std_ann as std_lag,beta as beta_lag,IOR as ior_lag, HHI as hhi_lag, roa as roa_lag, lvg as lvg_lag, q as q_lag
from my.rpe as a left join funda_w as b
on a.cik = b.cik and a.fycompustat = b.fyear + 1
order by cik, fycompustat;
quit;

* Merge fundamentals of other firms;
proc sql; 
create table psm as select a.*, b.cik as cik_other, 
b.size as size_other_lag, b.bm as bm_other_lag, b.sic2 as sic2_other_lag,b.sp500 as sp500_other_lag,b.sp1500 as sp1500_other_lag, 
b.ratings as ratings_other_lag,b.ret_ann as ret_other_lag,b.std_ann as std_other_lag,b.beta as beta_other_lag,b.IOR as IOR_other_lag, b.HHI as HHI_other_lag,
b.roa as roa_other_lag, b.q as q_other_lag,b.lvg as lvg_other_lag
from rpe_var as a left join funda_w as b
on a.cik ~= b.cik and a.fycompustat=b.fyear + 1
order by cym, cik, cik_other; *17,373,832;

* Merge correlation of other firms with RPE firms;
proc sql;
create table psm2 as select a.*, corr as corr_lag
from psm as a left join my.corr as b
on a.cik=b.cik and a.cik_other = b.cik_other and year(a.cym)=year(b.cym)+1 and month(a.cym)=month(b.cym) 
order by cik, cym, cik_other;
quit;

** Dummy actual peers;
data psm2; set psm2; cik_other2 = input( cik_other, best.); if cik_other ~=. ; run;

proc sql;
create table psm3 as select a.*, peercik
from psm2 as a left join relpeer as b
on a.cik=b.cik and a.cik_other2=b.peercik and a.fycompustat=b.fycompustat
order by cik, cym, cik_other;

data psm3; set psm3; drop peercik; if peercik =. then D_actualpeer = 0; else d_actualpeer = 1; run;

/* 26,605 cik-peercik-year;
data accruals; set my.accruals; cik2= input(cik,best.);if cik2 ~=. ; run;
proc sql;create table temp as select unique * from relpeer as a left join accruals as b on a.peercik=b.cik2 and a.fycompustat = b.fyear order by cik, fycompustat, peercik;
data temp; set temp; if CAdTAtm1DechowEtAl~=.; run;
*/

* Summ stat of RPE firms;
proc means data=rpe_var(where=(fycompustat>2005)) mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max;
    vars size_lag bm_lag ret_lag std_lag beta_lag ratings_lag IOR_lag HHI_lag;
run;

/* summ stat of actual vs non-selected peers;*/
* collapse to RPE firm-year level;
proc sql;
create table temp as select cik, D_actualpeer, fycompustat, mean(size_other_lag) as size, mean(bm_other_lag) as bm, mean(ret_other_lag) as ret, 
mean(std_other_lag) as std, mean(beta_other_lag) as beta, mean(ratings_other_lag) as ratings, mean(IOR_other_lag) as IOR, mean(HHI_other_lag) as HHI
from psm3
where fycompustat > 2005
group by D_actualpeer, cik, fycompustat
order by D_actualpeer, cik,fycompustat;
quit;

* compute summ for the avearge;
proc means data=temp mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max;
    by D_actualpeer;
    vars size bm ret std beta ratings IOR HHI;
run;


/**** Generate indep var ****/

/* compute difference; */
*when lags are already available;
data psm3; set psm3; 
same_sic2_lag = 0; if sic2_lag=sic2_other_lag then same_sic2_lag=1;
same_sp500_lag = 0; if sp500_lag=sp500_other_lag then same_sp500_lag=1;
same_sp1500_lag = 0; if sp1500_lag=sp1500_other_lag then same_sp1500_lag=1;
sizediff_lag = size_other_lag - size_lag;
bmdiff_lag = BM_other_lag - BM_lag;
retdiff_lag = ret_other_lag - ret_lag;
stddiff_lag = std_other_lag - std_lag;
betadiff_lag = beta_other_lag - beta_lag;
ratingdiff_lag = ratings_other_lag - ratings_lag;
iordiff_lag = IOR_other_lag - IOR_lag;
hhidiff_lag = HHI_other_lag - HHI_lag;
roadiff_lag = roa_other_lag - roa_lag;
qdiff_lag = q_other_lag - q_lag;
lvgdiff_lag = lvg_other_lag - lvg_lag;
run;

/*when lags are not available;
data psm3; set psm3; 
same_sic2 = 0; if sic2=sic2_other then same_sic2=1;
same_ff48 = 0; if ff48=ff48_other then same_ff48=1;
same_sp500 = 0; if sp500=sp500_other then same_sp500=1;
same_sp1500 = 0; if sp1500=sp1500_other then same_sp1500=1;
sizediff = size_other - size;
bmdiff = BM_other - BM;
retdiff = ret_ann_other - ret_ann;
stddiff = std_ann_other - std_ann;
betadiff = beta_other - beta;
ratingdiff = ratings_other - ratings;
iordiff = IOR_other - IOR;
hhidiff = HHI_other - HHI;
run;

proc sort data=psm3; by cik cik_other fycompustat; run;

data psm3; set psm3; 
same_sic2_lag = lag(same_sic2);
same_ff48_lag = lag(same_ff48);
same_sp500_lag = lag(same_sp500);
same_sp1500_lag = lag(same_sp1500);
sizediff_lag = lag(sizediff);
bmdiff_lag = lag(bmdiff);
retdiff_lag = lag(retdiff);
stddiff_lag = lag(stddiff);
betadiff_lag = lag(betadiff);
ratingdiff_lag = lag(ratingdiff);
iordiff_lag = lag(iordiff);
hhidiff_lag = lag(hhidiff);
if cik~=lag(cik) | cik_other ~= lag(cik_other) | fycompustat ~= (lag(fycompustat) +1) then 
  do;
    same_sic2_lag =.;
    same_ff48_lag =.;
    same_sp500_lag=.;
    same_sp1500_lag=.;
    sizediff_lag=.;
    bmdiff_lag=.;
    retdiff_lag=.;
    stddiff_lag=.;
    betadiff_lag=.;
    ratingdiff_lag=.;
    iordiff_lag=.;
    hhidiff_lag=.;
  end;
run;
*/
/** Compute significance of the diff in characteristics **/
proc sql;
create table temp as select cik, fycompustat, D_actualpeer, 
mean(sizediff_lag) as size, mean(bmdiff_lag) as bm, mean(retdiff_lag) as ret, 
mean(stddiff_lag) as std, mean(betadiff_lag) as beta, mean(ratingdiff_lag) as ratings, mean(IORdiff_lag) as IOR, mean(HHIdiff_lag) as HHI
from psm3
where fycompustat > 2005
group by D_actualpeer, cik, fycompustat
order by D_actualpeer, cik,fycompustat;
quit;

* compute summ for the avearge;
proc means data=temp mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max;
    vars size bm ret std beta ratings ior hhi;
	by D_actualpeer;
run;

* test significance from 0 for each group;
proc ttest plots=none data=temp ;by D_actualpeer; var size bm ret std beta ratings ior hhi; run;

/* Sig of diff in joint variables */
proc sql;
create table temp as select cik, fycompustat, D_actualpeer, mean(corr_lag) as corr, mean(same_sic2_lag) as same_sic2, mean(same_sp500_lag) as same_sp500, mean(same_sp1500_lag) as same_sp1500
from psm3
where fycompustat>2005
group by D_actualpeer, cik, fycompustat
order by D_actualpeer, cik,fycompustat;
quit;

* compute summ for the avearge;
proc means data=temp mean median std min P1 P5 P10 P25 P75 P90 P95 P99 max;
    vars corr same_sic2 same_sp500 same_sp1500;
	by D_actualpeer;
run;

* test sig bw peer and non-peer;
proc ttest data=temp; class D_actualpeer; var corr same_sic2 same_sp500 same_sp1500; run;


data 'F:\Experience\World_bank\RPE_EM\data_code\psm'; set psm3; run;

data psm4; set psm3; if size_other_lag >= min_peersize | d_actualpeer=1; run; *4821897/33218=145;

proc export data=psm3 outfile='D:\World_bank_research\RPE_EM\data_code\PSM.dta' replace;run;


