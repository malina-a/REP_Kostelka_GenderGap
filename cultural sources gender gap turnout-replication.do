******************************************************************************
** purpose: 	estimations, producing tables and figures					**
** paper:		cultural sources of the gender gap in turnout				**
** date: 		september 2019												**
** authors: 	Ruth Dassonneville and Filip Kostelka						**
******************************************************************************


cd "~/Dropbox/gender gap/final files (post-accept)/replication materials"


******************************
** ADDITIONAL PACKAGES 		**
******************************

	ssc install fsum, replace
	ssc install oaxaca, replace
	ssc install fairlie, replace
	ssc install sutex, replace

******************************
** SUPPLEMENTAL DATA CODING **
******************************

** load EES data

	use "data/EES_aggregated_macrovariables.dta", clear



** add macro-level variables, source: http://mattgolder.com/elections

	gen presidential=0
	replace presidential=1 if country==1					//"Austria"
	replace presidential=1 if country==3					// "Bulgaria"
	replace presidential=1 if country==4					// "Croatia"
	replace presidential=1 if country==6 & year>=2013		// "Czech Republic" 
	replace presidential=1 if country==10					// "France"
	replace presidential=1 if country==14					// "Ireland"
	replace presidential=1 if country==17					// "Lithuania"
	replace presidential=1 if country==21					// "Poland"
	replace presidential=1 if country==22					// "Portugal"
	replace presidential=1 if country==23					// "Romania"
	replace presidential=1 if country==24 & year>=1999		// "Slovakia" 
	replace presidential=1 if country==25 & year<=2002		// "Slovenia"
	replace presidential=1 if country==25 & year>=2012		// "Slovenia" 

	gen legislative_type=0
	replace legislative_type=1 if country==3				// "Bulgaria"
	replace legislative_type=1 if country==4				// "Croatia"
	replace legislative_type=1 if country==11				// "West Germany"
	replace legislative_type=1 if country==19				// "East Germany"
	replace legislative_type=1 if country==12				// "Greece"
	replace legislative_type=1 if country==13				// "Hungary"
	replace legislative_type=1 if country==15				// "Italy"
	replace legislative_type=1 if country==17				// "Lithuania"
	replace legislative_type=1 if country==23				// "Romania"
	replace legislative_type=2 if country==10				// "France"
	replace legislative_type=2 if country==28				// "United Kingdom"
	replace legislative_type=2 if country==3 & year==2009	// "Bulgaria" 
	replace legislative_type=2 if country==4 & year<=1995	// "Croatia" 
	replace legislative_type=2 if country==15 & year>=1994 & year<=2001 // "Italy" 
	replace legislative_type=2 if country==23& year>=2008 & year<=2012 	// "Romania" 

	gen majoritarian=0 if legislative_type==0
	replace majoritarian=0 if legislative_type==1
	replace majoritarian=1 if legislative_type==2
	

** add math score data
	gen countryyear = string(country) + string(year)
	merge m:1 countryyear using "data/maths_diff_to_merge.dta"
	drop if _merge==2
	drop _merge

** add gender equality index data 
	merge m:1 country year using "data/EIGE_to_merge1.dta" 
	drop _merge	EIGE_country long_term_index

	merge m:1 country using "data/EIGE_to_merge2.dta"
	drop _merge	
	
	lab var value "EIGE" 
	lab var long_term_index "EIGE (2005-2015 average)" 
	
** add EVS survey data 
	merge m:1 country using "data/EVS_to_merge.dta"
	drop _merge	
	
* Generating filter with missing values on some of the individual IVs
	
	gen filter=1
	replace filter=0 if mi(female, age, postsecondary, social_class, employment_status, interest, close_to_party, tu_member, religiosity, membership_good)
	
	sum female age postsecondary social_class employment_status interest close_to_party tu_member religiosity membership_good
	sum female age postsecondary social_class employment_status interest close_to_party tu_member religiosity membership_good if filter==1
	
	gen filter2=1
	replace filter2=0 if mi(female, age, postsecondary, social_class, employment_status, interest, close_to_party)


	
********************
**	MAIN RESULTS  **
********************


* Figure 1. evolution of the gender gap in turnout

	cap set scheme bw

	recode country (2 7 10 14 11 15 18 20 28=1 "Member States in 1979") (else=0), gen(ms1979)

	eststo clear
	foreach k of numlist 1979 1984 1989 1994 1999 2004 2009 2014 {
	reg vote_eur i.female i.country if year==`k', l(90)
	eststo M_`k'_graph_all: margins, dydx(female) post
	}

	foreach k of numlist 1979 1984 1989 1994 1999 2004 2009 2014 {
	reg vote_eur i.female i.country if year==`k' & ms1979==1, l(90)
	eststo M_`k'_graph_MS1979: margins, dydx(female) post
	}

	coefplot (M_1979_graph_all, label("All Member States") msymbol(Oh)) (M_1979_graph_MS1979, label("1979 Member States") msymbol(O)), bylabel(1979) || ///
	M_1984_graph_all M_1984_graph_MS1979, bylabel(1984) || M_1989_graph_all M_1989_graph_MS1979, bylabel(1989) || /// 
	M_1994_graph_all M_1994_graph_MS1979, bylabel(1994) || M_1999_graph_all M_1999_graph_MS1979, bylabel(1999) || /// 
	M_2004_graph_all M_2004_graph_MS1979, bylabel(2004) || M_2009_graph_all M_2009_graph_MS1979, bylabel(2009) || /// 
	M_2014_graph_all M_2014_graph_MS1979, bylabel(2014) bycoef vertical ytitle("Gender gap in the probability to vote", size(medsmall) height(-3)) ///  
	legend(size(small) bm(medsmall)) ylabel(, labs(small))  xlabel(, labs(small)) yline(0, lp(dash))

	graph export "Figure1.eps", replace


* Figure 2. gender gap in EP and national parliament elections by country

	tab year, gen(Y) 
	
	eststo clear 
	forvalues i = 1/29 {
	fre country if country ==`i'
	cap reg vote_eur i.female Y* if country ==`i', l(90)
	eststo M_`i'_graph: margins, dydx(female) post 
	}

	forvalues i = 1/29 {
	fre country if country ==`i'
	cap reg vote_nat i.female Y* if country ==`i', l(90)
	di `i'  
	eststo M_`i'_nat: margins, dydx(female) post
	}

	coefplot (M_17_graph, label("EP Elections")) (M_17_nat, label("National Elections")), bylab("Lithuania") ///
	|| M_8_graph M_8_nat, bylab("Estonia") || M_16_graph M_16_nat, bylab("Latvia") ///
	|| M_19_graph M_19_nat, bylab("Malta") || M_27_graph M_27_nat, bylab("Sweden") || M_9_graph M_9_nat, bylab("Finland") ///
	|| M_29_graph M_29_nat, bylab("East Germany") ||  M_1_graph M_1_nat, bylabel("Austria") ///
	||  M_2_graph M_2_nat, bylab("Belgium") || M_14_graph M_14_nat, bylab("Ireland") ||  M_25_graph M_25_nat, bylab("Slovenia") ///
	||  M_20_graph M_20_nat, bylab("Netherlands") ///
	||  M_26_graph M_26_nat, bylab("Spain") || M_13_graph M_13_nat, bylab("Hungary") || M_12_graph M_12_nat, bylab("Greece")   ///
	||  M_28_graph M_28_nat, bylab("United Kingdom") ||  M_7_graph M_7_nat, bylab("Denmark") || M_24_graph M_24_nat, bylab("Slovakia") ///
	|| M_18_graph M_18_nat, bylab("Luxembourg") || M_5_graph M_5_nat, bylab("Cyprus") ///
	|| M_3_graph M_3_nat, bylab("Bulgaria") ||  M_15_graph M_15_nat, bylab("Italy") ||  M_10_graph M_10_nat, bylab("France") ||  ///
	M_23_graph M_23_nat, bylab("Romania") ||  M_11_graph M_11_nat, bylab("West Germany") || M_6_graph M_6_nat, bylab("Czech Rep.") ///
	||  M_22_graph M_22_nat, bylab("Portugal") ||  M_4_graph M_4_nat, bylab("Croatia")  ///
	|| M_21_graph M_21_nat, bylab("Poland") bycoef msize(medium) horizontal xtitle("Gender gap in the probability to vote", size(small) margin(medium)) /// 
	xline(0, lp(dash)) xlabel(-.12(.02).12, nogrid angle(horizontal) labs(vsmall)) legend(size(small))  ylabel(, nogrid labs(small)) /// 
	ysize(6.5) xsize(4) 

	graph export "Figure2.eps", replace

	
* Table 1. Indivual level factors: (multilevel format, individuals in election-years in countries)
	
	set more off
	eststo clear
	eststo M1: mixed vote_eur i.female if filter==1 || country:  || year:  ,var
	eststo M2: mixed vote_eur i.female age i.postsecondary i.employment_status i.social_class   if filter==1 || country:  || year:  , var
	eststo M3: mixed vote_eur i.female age i.postsecondary i.employment_status i.social_class  i.membership_good   if filter==1 || country:  || year:  , var
	eststo M4: mixed vote_eur i.female age i.postsecondary i.employment_status i.social_class  i.membership_good  tu_member religiosity close_to_party  if filter==1 || country:  || year:  , var
	eststo M5: mixed vote_eur i.female age i.postsecondary i.employment_status i.social_class  tu_member religiosity i.membership_good	close_to_party  interest  if filter==1 || country:  || year:  , var
	esttab M1 M2 M3 M4 M5 using table1.tex, label b(3) se(3) nogap  replace
	
	
* Table 2. Decomposition

	// generate dummies (ind. var not accepted)
	tab country, gen(count)
	tab employment_status, gen(work)
	tab social_class, gen(soc_class) 
	tab membership_good, gen(memb)
	tab year, gen(election)
	
	// Linear decomposition
	oaxaca vote_eur age postsecondary  work2 work3 soc_class2 soc_class3  memb2 memb3 tu_member religiosity close_to_party  interest count1-count28 election1-election7, by(female) pooled detail relax
	reg vote_eur female if filter==1 // the same magnitude of the gender gap as reported by oaxaca 
	
	
*Descriptive statistics 
		
	// These analyses are for footnote 16 (on the potential indirect effects of political interest)	
	reg memb3 age postsecondary  work2 work3 soc_class2 soc_class3  tu_member religiosity close_to_party  interest count1-count28 if filter==1, beta
	reg close_to_party age postsecondary  work2 work3 soc_class2 soc_class3 memb2 memb3 tu_member religiosity   interest count1-count28 if filter==1, beta

	
* Table 3/Fig 3: Explaining political interest, focus on macro level

	// These analyses replicate the results in Table 3 and produce the marginal effects plots in Figure 3

	eststo M6: mixed interest i.female if filter2==1 || country:  || year:  , var
	eststo M7: mixed interest i.female age i.postsecondary i.employment_status i.social_class close_to_party if filter2==1 || country:  || year:  , var

	eststo M8: mixed interest i.female##c.women_parliament_survey age i.postsecondary i.employment_status i.social_class   close_to_party if filter2==1 || country:  || year: female , var
	margins, dydx(female)  at(women_parliament_survey=(4(2)46)) 
	
		marginsplot, level(90)  yline(0) recast(line) recastci(rline)  xtitle("Percentage of women in parliament", margin(medsmall)) ///
		addplot(hist women_parliament_survey, percent bin(30) yaxis(2) yscale(axis(2) alt  )  xlabel(4(2)46) ylabel(-0.04(0.02)-.12) ///
		yscale(range(0(10)100) axis(2)) ylabel(0(5)10, axis(2)) ///
		ytitle("Percentage of observations", axis(2)) ) ///
		ytitle("AME Female")  legend(off) title("") 
		graph export womenparliament.eps, replace 
	
	eststo M9: mixed interest i.female##c.women_parliament_18_21 age i.postsecondary i.employment_status i.social_class  close_to_party if filter2==1 || country:  || year: female , var
		margins , dydx(female)  at(women_parliament_18_21=(0(2)46)) 	
		
		marginsplot, level(90)  yline(0) recast(line) recastci(rline)  xtitle("Percentage of women in parliament (18-21)", margin(medsmall)) ///
		addplot(hist women_parliament_18_21, percent bin(30) yaxis(2) yscale(axis(2) alt) xlabel(0(2)46) ylabel(-0.04(0.02)-.12) ///
		yscale(range(0(10)100) axis(2)) ylabel(0(5)10, axis(2)) ///
		ytitle("Percentage of observations", axis(2)) ) ///
		ytitle("AME Female") title("")  legend(off) title("") 
		graph export womenparliament_18_21.eps, replace 
		
	eststo M10: mixed interest i.female##c.value age i.postsecondary i.employment_status i.social_class  close_to_party if filter2==1 || country:  || year: female , var	
		margins , dydx(female)  at(value=(45(2)83)) 	
	
		marginsplot, level(90)  yline(0) recast(line) recastci(rline)  xtitle("Societal gender equality (EIGE)", margin(medsmall)) ///
		addplot(hist value, percent bin(30) yaxis(2) yscale(axis(2) alt) xlabel(45(2)83) ylabel(-0.04(0.02)-.12) ///
		yscale(range(0(10)100) axis(2)) ylabel(0(5)10, axis(2)) ///
		ytitle("Percentage of observations", axis(2)) ) ///
		ytitle("AME Female") title("")  legend(off) title("") 
		graph export EIGE.eps, replace 
	
	eststo M11: mixed interest i.female##c.long_term_index age i.postsecondary i.employment_status i.social_class  close_to_party if filter2==1 || country:  || year: female , var	
		margins , dydx(female)  at(long_term_index=(48(2)82)) 
	
		marginsplot, level(90)  yline(0) recast(line) recastci(rline)  xtitle("Societal gender equality (EIGE - 2005-2015 average)", margin(medsmall)) ///
		addplot(hist long_term_index, percent bin(30) yaxis(2) yscale(axis(2) alt) xlabel(45(2)83) ylabel(-0.04(0.02)-.12) ///
		yscale(range(0(10)100) axis(2)) ylabel(0(5)10, axis(2)) ///
		ytitle("Percentage of observations", axis(2)) ) ///
		ytitle("AME Female") title("")  legend(off) title("")
		graph export EIGE_average.eps, replace 
	
	eststo M12: mixed interest i.female##c.grand_mean_PISA age i.postsecondary i.employment_status i.social_class  close_to_party if filter2==1 || country:  || year: female , var
		margins, dydx(female)  at(grand_mean_PISA=(-0.040(0.005)0.010)) 
	
		marginsplot, level(90)  yline(0) recast(line) recastci(rline)  xtitle("Gender gap in math (PISA)", margin(medsmall)) ///
		addplot(hist grand_mean_PISA, percent bin(30) yaxis(2) yscale(axis(2) alt)   yscale(range(0(10)100) axis(2)) ylabel(-0.04(0.02)-.12) ///
		ylabel(0(5)10, axis(2)) xlabel(-0.040(0.005)0.010) /// 
		ytitle("Percentage of observations", axis(2)) ) ///
		ytitle("AME Female")  title("")  legend(off)  
		graph export pisa.eps, replace 
	
	eststo M13: mixed interest i.female##c.grand_mean_TIMSS age i.postsecondary i.employment_status i.social_class close_to_party if filter2==1 || country:  || year: female , var
		margins, dydx(female)  at(grand_mean_TIMSS=(-0.025(0.005)0.010)) 
	
		marginsplot, level(90)  yline(0) recast(line) recastci(rline)  xtitle("Gender gap in math (TIMSS)", margin(medsmall)) ///
		addplot(hist grand_mean_TIMSS, percent bin(30) yaxis(2) yscale(axis(2) alt)   yscale(range(0(10)100) axis(2)) ylabel(-0.04(0.02)-.12) ///
		ylabel(0(5)10, axis(2)) xlabel(-0.025(0.005)0.010) /// 
		ytitle("Percentage of observations", axis(2)) ) ///
		ytitle("AME Female")  title("")  legend(off)  
		graph export timss.eps, replace 
	
	
	eststo M14: mixed interest i.female##c.women_parliament_18_21 i.female##c.grand_mean_PISA age i.postsecondary i.employment_status i.social_class  close_to_party if filter2==1 || country:  || year: female , var


	esttab M6 M7 M8 M9 M10 M11 M12 M13 M14  using table3.tex, label b(3) se(3) nogap  replace

	
	
	
	
*****************************	
** SUPPLEMENTARY MATERIALS **
*****************************


	* 1. descriptive statistics

	lab var vote_eur "Turnout"
	lab var female "Female"
	lab var age "Age"
	lab var postsecondary "Postsecondary" 
	lab var work1 "Working"
	lab var work2 "Unemployed" 
	lab var work3 "Not working" 
	lab var soc_class1 "Working class"
	lab var soc_class2 "Middle class"
	lab var soc_class3 "Upper class"
	lab var memb1 "EU membership bad" 
	lab var memb2 "EU membership neither good nor bad" 
	lab var memb3 "EU membership good"
	lab var tu_member "Trade union member"
	lab var religiosity "Attendance of religious services"
	lab var close_to_party "Closeness to a party" 
	lab var interest "Interest in politics" 
	lab var women_parliament_survey "Women parliament survey"
	lab var women_parliament_18_21 "Women in parliament 18-21"
	lab var value "EIGE" 
	lab var long_term_index "EIGE (2005-2015 average)"
	lab var grand_mean_PISA "PISA"  
	lab var grand_mean_TIMSS "TIMSS" 

	sutex vote_eur female age postsecondary work1 work2 work3 soc_class1 soc_class2 soc_class3 ///
	memb1 memb2 memb3 tu_member religiosity close_to_party interest ///
	women_parliament_survey women_parliament_18_21  value  long_term_index grand_mean_PISA grand_mean_TIMSS ///
	if filter2==1, lab nobs key(descstat) replace file(descriptive_stats.tex) minmax digits(2)
	
	
	* 2. non-linear decomposition
	
	fairlie vote_eur age postsecondary  work2 work3 soc_class2 soc_class3  memb2 memb3 tu_member religiosity close_to_party  interest count1-count28 election1-election7, by(female) pooled(female)

	
	* 3. bayes estimates and bivariate associations
	
	mixed interest i.female age i.postsecondary i.employment_status i.social_class close_to_party if filter2==1 || country:  || year: female  
		
	predict ebintcountry ebslopefemale ebintyear, reffect reses(intercountry_se slopefemale_se  interyear_se)
	drop if e(sample)==0
	
	encode key, gen(electionid)	
	
	preserve
	collapse (mean) ebslopefemale slopefemale_se grand_mean_PISA grand_mean_TIMSS year (first) country if filter2==1, by(electionid)
	
	sort ebslopefemale
	gen order=_n
	
	label define order 1 "CY_2004" 2	"WDE_1989" 3	"EL_1989" 4	"PL_2014" 5	"IE_2014" ///
	6	"IT_1994" 7	"IT_1989" 8	"WDE_2014" 9	"DK_1999" 10	"DK_2004" 11	"AT_2014" ///
	12	"AT_2009" 13	"UK_2014" 14	"PL_2004" 15	"BE_1989" 16	"UK_1989" 17	"UK_1999" ///
	18	"BE_1994" 19	"NL_2014" 20	"NL_2004" 21	"PT_1999" 22	"NL_1989" 23	"FI_1999" ///
	24	"FR_1994" 25	"ES_1994" 26	"LU_2009" 27	"FR_1989" 28	"CY_2014" 29	"UK_1994" ///
	30	"NL_1999" 31	"FR_2009" 32	"IE_1989" 33	"CZ_2014" 34	"AT_2004" 35	"HV_2014" ///
	36	"DK_2009" 37	"CZ_2004" 38	"PT_1994" 39	"PT_1989" 40	"DK_1994" 41	"EDE_2009" ///
	42	"EDE_2014"  43	"FI_2009" 44	"LU_1989" 45	"WDE_1999" 46	"NL_1994" 47	"DK_1989" ///
	48	"SK_2014" 49	"PL_2009" 50	"IE_2009" 51	"IE_1994" 52	"ES_1989" 53	"BE_2014" ///
	54	"AT_1999" 55	"NL_2009" 56	"LU_1994" 57	"RO_2009" 58	"HU_2014" 59	"IT_1999" ///
	60	"EL_2014" 61	"EL_1994" 62	"EE_2004" 63	"SI_2014" 64	"WDE_1994" 65	"UK_2009" ///
	66	"PT_2014" 67	"IT_2004" 68	"ES_2004" 69	"IT_2014" 70	"CY_2009" 71	"SK_2004" ///
	72	"IE_1999" 73	"FR_2014" 74	"FR_1999" 75	"EDE_1999" 76	"WDE_2004" 77	"IT_2009" ///
	78	"EDE_1994" 79	"IE_2004" 80	"LU_1999" 81	"HU_2009" 82	"BE_1999" 83	"EL_2009" ///
	84	"BG_2014" 85	"MT_2009" 86	"ES_1999" 87	"LV_2004" 88	"SI_2009" 89	"LU_2014" ///
	90	"SK_2009" 91	"WDE_2009" 92	"EE_2014" 93	"FR_2004" 94	"PT_2009" 95	"CZ_2009" ///
	96	"EL_1999" 97	"ES_2009" 98	"UK_2004" 99	"EDE_2004" 100	"BE_2009" 101	"DK_2014" ///
	102	"LT_2009" 103	"FI_2014" 104	"LV_2014" 105	"PT_2004" 106	"SI_2004" 107	"RO_2014" ///
	108	"HU_2004" 109	"FI_2004" 110	"ES_2014" 111	"EL_2004" 112	"SE_1999" 113	"SE_2009" ///
	114	"EE_2009" 115	"MT_2014" 116	"LV_2009" 117	"SE_2014" 118	"BG_2009" 119	"LT_2014"
	
	label values order order
	
	serrbar ebslopefemale slopefemale_se order, yline(0) scale(1.9) xlabel(1(1)119,  angle(vertical) valuelabel labsize(vsmall)) ylabel(, labsize(vsmall)) xtitle("") ytitle("Estimated slope of female", size(small)) xsize(8) ysize(4)
	graph export femaleslope.eps, replace
	graph export femaleslope.pdf, replace

	serrbar ebslopefemale slopefemale_se grand_mean_PISA , scale(1.9) addplot(lfit ebslopefemale grand_mean_PISA, lpattern(solid)) ///
	ytitle("Empirical bayes estimate of slope of female", size(small)) xtitle("Gender gap in math (PISA)", size(small)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) legend(off)
	graph export femaleslope_PISA.eps, replace
	graph export femaleslope_PISA.pdf, replace
	
	serrbar ebslopefemale slopefemale_se grand_mean_TIMSS , scale(1.9) addplot(lfit ebslopefemale grand_mean_TIMSS, lpattern(solid)) ///
	ytitle("Empirical bayes estimate of slope of female", size(small)) xtitle("Gender gap in math (TIMSS)", size(small)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) legend(off)
	graph export femaleslope_TIMSS.eps, replace
	graph export femaleslope_TIMSS.pdf, replace

	restore
	
	* 4. gender attitudes

	preserve 
	collapse EVS_f2 EVS_income grand_mean_TIMSS grand_mean_PISA, by(country) 
	pwcorr EVS_f2 EVS_income grand_mean_TIMSS grand_mean_PISA // correlations 
	pwcorr EVS_f2 EVS_income grand_mean_TIMSS grand_mean_PISA if country!=20 // correlations without the Netherlands 

	tw scatter EVS_f2 grand_mean_PISA, mlabel(country) || lfit EVS_f2 grand_mean_PISA, /// 
	ytitle("Gender Equality Scale (EVS)") xtitle("PISA") name(graph1, replace) legend(off) title("With the outlying Netherlands (Person's r=0.2)")
	
	tw scatter EVS_f2 grand_mean_PISA if country!=20, mlabel(country) || lfit EVS_f2 grand_mean_PISA if country!=20, /// 
	ytitle("Gender Equality Scale (EVS)") xtitle("PISA") name(graph2, replace)  legend(off) title("Without the outlying Netherlands (Person's r=0.3)")

	graph combine graph1 graph2, ysize(2) xsize(4) note("European Value Survey 1999-2008.") 
	*title("Survey Measure of Gender Equality (EVS) and Mathematical Performance (PISA)")
	graph export EVS_PISA_bivariate.eps, replace 
	graph export EVS_PISA_bivariate.tif, replace 	
	restore 

		// general analysis (all cases)
	eststo clear
	eststo SM1: mixed interest i.female##c.EVS_f2 age i.postsecondary i.employment_status i.social_class  close_to_party if filter2==1 || country:  || year: female , var
	
		margins, dydx(female)  at(EVS_f2=(-1.1(0.1).5)) 
	
		marginsplot, level(90) yline(0) recast(line) recastci(rline)  xtitle("Score on Gender Equality Scale (EVS)", size(small) margin(medsmall)) ///
		addplot(hist EVS_f2, percent bin(30) yaxis(2) yscale(axis(2) alt)   yscale(range(0(10)100) axis(2)) ylabel(-0.04(0.02)-.12) ///
		ylabel(0(5)10, axis(2)) xlabel(-1.1(0.1).5))  /// 
		ytitle("AME Female") /// ytitle("Percentage of observations", axis(2)) ) 
		 title("All Countries")  legend(off)  name(graph3, replace)
		graph export SI_attitudes.eps, replace 
		graph export SI_attitudes.tif, replace 
	
		esttab SM1 using SI_attitudes.tex, label b(3) se(3) nogap  replace
	

		// analyses without the Netherlands (outlier)
	eststo SM2: mixed interest i.female##c.EVS_f2 age i.postsecondary i.employment_status i.social_class  close_to_party if filter2==1 & country!=20 || country:  || year: female , var
	
		preserve
		drop if country==20
		margins if country!=20 , dydx(female)  at(EVS_f2=(-1.1(0.1).5))  
	
		marginsplot, level(90)  yline(0) recast(line) recastci(rline)  xtitle("Score on Gender Equality Scale (%) (EVS)", size(small) margin(medsmall)) ///
		addplot(hist EVS_f2, percent bin(24) yaxis(2) yscale(axis(2) alt)   yscale(range(0(10)100) axis(2)) ylabel(-0.04(0.02)-.12) ///
		ylabel(0(5)10, axis(2)) xlabel(-1.1(0.1).5))  ///
		ytitle("AME Female")  /// xtitle("Percentage of observations", axis(2)) 
		title("All Countries but the Netherlands")  legend(off)  name(graph4, replace)
		graph export SI_attitudes_wo_Netherlands.eps, replace 
		graph export SI_attitudes.tif, replace 
		restore
		
		esttab SM2 using SI_attitudes_wo_Netherlands.tex, label b(3) se(3) nogap  replace
		esttab SM1 SM2 using SI_attitudes_both.tex, label b(3) se(3) nogap  replace



	* 5. mixed ordered logit models
	
	eststo m1: meologit interest i.female age i.postsecondary i.employment_status i.social_class close_to_party if filter2==1 || country:  || year:  
	eststo m2: meologit interest i.female##c.women_parliament_survey age i.postsecondary i.employment_status i.social_class   close_to_party if filter2==1 || country:  || year: female 	
	eststo m3: meologit interest i.female##c.women_parliament_18_21 age i.postsecondary i.employment_status i.social_class  close_to_party if filter2==1 || country:  || year: female 
	eststo m4: meologit interest i.female##c.value age i.postsecondary i.employment_status i.social_class  close_to_party if filter2==1 || country:  || year: female 	
	eststo m5: meologit interest i.female##c.long_term_index age i.postsecondary i.employment_status i.social_class  close_to_party if filter2==1 || country:  || year: female 	
	eststo m6: meologit interest i.female##c.grand_mean_PISA age i.postsecondary i.employment_status i.social_class  close_to_party if filter2==1 || country:  || year: female 
	eststo m7: meologit interest i.female##c.grand_mean_TIMSS age i.postsecondary i.employment_status i.social_class close_to_party if filter2==1 || country:  || year: female 
		
	esttab m1 m2 m3 m4 m5 m6 m7 using SI_ologit.tex, b(3) se(3) nogap 















