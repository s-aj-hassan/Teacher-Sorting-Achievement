
* ================================================================================================ *
* MAIN RESULTS
* ================================================================================================ *

* MAIN RESULTS TABLE 

	eststo clear 

	global Y "zscore"
	global FEs "pnr grade cohort"
	
	// DANISH 
	use $tmp/fe_student_exog_dan, clear 	
	keep if inlist(grade, 2, 4, 6, 8)

	local j 1 
	foreach q in ctfd spceqv expr gpa_std {
		
		eststo d`j': reghdfe $Y d_`q', absorb($FEs) cluster(pnr)
		
		unique pnr if e(sample)
		estadd scalar Ns = r(sum)
		count if d_`q' != 0 & d_`q' != . 
		estadd scalar Ne = r(N)
		if r(N) < 50 stop 
		
		local ++j 
		
	}
	// MATH
	use $tmp/fe_student_exog_mat, clear 
	keep if inlist(grade, 3, 6)
	
	label var d_ctfd "Certified"
	label var d_spceqv "Specialized"
	label var d_expr "Experienced"
	label var d_gpa_std "High school GPA"

	local j 1 
	foreach q in ctfd spceqv expr gpa_std {
		
		eststo m`j': reghdfe $Y d_`q', absorb($FEs) cluster(pnr)
		
		unique pnr if e(sample)
		estadd scalar Ns = r(sum)
		count if d_`q' != 0 & d_`q' != . 
		estadd scalar Ne = r(N)
		if r(N) < 50 stop 
		
		local ++j 
	}
		
	// EXPORT
	global out "$dir/output"
	esttab d1 d2 d3 d4 m1 m2 m3 m4 using $out/mainresults.tex, replace 										///
		booktabs width(\hsize) 																				///
		keep(_cons d_*) label b(3) se(3)																	///
		stats(N Ns Ne, 																						///
			label(" \textit{N} (observations)" " \textit{N} (students)" "\textit{N} (identifying obs.)")	///
			fmt(%9.0gc %9.0gc)) 																			///
		mgroup("Danish" "Mathematics", pattern(1 0 0 0 1 0 0 0)  											///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 					///
		nonotes nomtit msign("$-$")	
		

* ================================================================================================ *
* ASYMMETRIC EFFECTS 
* ================================================================================================ *	

* ESTIMATE MODELS 

	// Danish 
		eststo clear 

		global FEs "pnr grade cohort"
		
		use $tmp/fe_student_exog_dan, clear 
		
		eststo d1: reghdfe zscore d_ctfd_p d_ctfd_m C, absorb($FEs) cluster(pnr)
			mat a = r(table)' 
			mat a = (a[1,1], a[1,5], a[1,6], 4, 1 \ a[2,1], a[2,5], a[2,6], 4, 0) 
			mat a1 = a
		
		eststo d2: reghdfe zscore d_spceqv_p d_spceqv_m C, absorb($FEs) cluster(pnr)
			mat a = r(table)' 
			mat a = (a[1,1], a[1,5], a[1,6], 3, 1 \ a[2,1], a[2,5], a[2,6], 3, 0)
			mat a2 = a
			
		eststo d3: reghdfe zscore d_expr_p d_expr_m C, absorb($FEs) cluster(pnr)
			mat a = r(table)' 
			mat a = (a[1,1], a[1,5], a[1,6], 2, 1 \ a[2,1], a[2,5], a[2,6], 2, 0)
			mat a3 = a
			
		eststo d4: reghdfe zscore d_gpa_std_p d_gpa_std_m C, absorb($FEs) cluster(pnr)
			mat a = r(table)' 
			mat a = (a[1,1], a[1,5], a[1,6], 1, 1 \ a[2,1], a[2,5], a[2,6], 1, 0)
			mat a4 = a
		
		mat A = a1 \ a2 \ a3 \ a4
		mat dan = A 
	
	// Math
		
		use $tmp/fe_student_exog_mat, clear 
		keep if inlist(grade, 3, 6)
		
		label var d_ctfd_p 		"Certified, positive"
		label var d_ctfd_m 		"Certified, negative"
		label var d_spceqv_p 	"Specialized, positive"
		label var d_spceqv_m	"Specialized, negative"
		label var d_expr_p		"Experienced, positive"
		label var d_expr_m		"Experienced, negative"
		label var d_gpa_std_p	"High school GPA, positive"
		label var d_gpa_std_m	"High school GPA, negative"
		label var C				"Any change"
		
		eststo m1: reghdfe zscore d_ctfd_p d_ctfd_m C, absorb($FEs) cluster(pnr)
			mat a = r(table)' 
			mat a = (a[1,1], a[1,5], a[1,6], 4, 1 \ a[2,1], a[2,5], a[2,6], 4, 0) 
			mat a1 = a
		
		eststo m2: reghdfe zscore d_spceqv_p d_spceqv_m C, absorb($FEs) cluster(pnr)
			mat a = r(table)' 
			mat a = (a[1,1], a[1,5], a[1,6], 3, 1 \ a[2,1], a[2,5], a[2,6], 3, 0)
			mat a2 = a
			
		eststo m3: reghdfe zscore d_expr_p d_expr_m C, absorb($FEs) cluster(pnr)
			mat a = r(table)' 
			mat a = (a[1,1], a[1,5], a[1,6], 2, 1 \ a[2,1], a[2,5], a[2,6], 2, 0)
			mat a3 = a
			
		eststo m4: reghdfe zscore d_gpa_std_p d_gpa_std_m C, absorb($FEs) cluster(pnr)
			mat a = r(table)' 
			mat a = (a[1,1], a[1,5], a[1,6], 1, 1 \ a[2,1], a[2,5], a[2,6], 1, 0)
			mat a4 = a
		
		mat A = a1 \ a2 \ a3 \ a4
		mat mat = A
	
* APPENDIX TABLE WITH ALL ESTIMATES 

	esttab d1 d2 d3 d4 m1 m2 m3 m4 using $out/app_asymmetry.tex, replace					///
		booktabs width(\hsize) 																///
		order (d_* C) label b(3) se(3)														///
		stats(N, label(" \textit{N} (observations)") fmt(%9.0gc)) 							///
		mgroup("Danish" "Mathematics", pattern(1 0 0 0 1 0 0 0)  							///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 	///
		nonotes nomtit msign("$-$")																	

* GRAPH
	
	clear 
	svmat dan 
	rename dan* A*
	rename (A1 A2 A3 A4 A5) (b ll ul v p)
	
	replace v = v + .1 if p == 1
	replace v = v - .1 if p == 0 
	
	
	// Pseudo variable to get nice legend keys with both symbol and CIs
	gen x = . 
	
	
	local P "msym(O) mlabpos(12) mcol(stc1) mlabcol(stc1) "
	local M "msym(T) mlabpos(6) mcol(stc2) mlabcol(stc2)"
	local O "msize(medlarge) mlabsize(medlarge) mlab(b) mlabf(%4.3fc)"
	
	gr tw 	sc v b if p == 1, `O' `P'																///
		||	rspike ll ul v if p == 1, hor lcol(stc1) 												///
		|| 	sc v b if p == 0, `O' `M'																///
		|| 	rspike ll ul v if p == 0, hor lcol(stc2)												///
		||	conn x b if p == 1, col(stc1) msym(O) msize(medlarge)									///
		||	conn x b if p == 0, col(stc2) msym(T) msize(medlarge)									///
		xtitle("Coefs and 95% CIs")																	///
		xlab(-.3(.1).3, format(%4.2fc) labsize(medlarge))											///
		xline(0)																					///
		ylab(1 "High school GPA" 2 "Experienced" 3 "Specialized" 4 "Certified", labsize(medlarge)) 	///
		yscale(r(0.7 4.2)) 																			///
		legend(off) name(gdan, replace) fxsize(100) title("{bf:(a)} Reading", margin(0 0 5 0) pos(12))
	
	
	clear 
	svmat mat
	rename mat* A*
	rename (A1 A2 A3 A4 A5) (b ll ul v p)
	
	replace v = v + .1 if p == 1
	replace v = v - .1 if p == 0 
	
	// Pseudo variable to get nice legend keys with both symbol and CIs
	gen x = . 
	
	global out "$dir/output"
	
	local P "msym(O) mlabpos(12) mcol(stc1) mlabcol(stc1) "
	local M "msym(T) mlabpos(6) mcol(stc2) mlabcol(stc2)"
	local O "msize(medlarge) mlabsize(medlarge) mlab(b) mlabf(%4.3fc)"
	
	gr tw 	sc v b if p == 1, `O' `P'															///
		||	rspike ll ul v if p == 1, hor lcol(stc1) 											///
		|| 	sc v b if p == 0, `O' `M'															///
		|| 	rspike ll ul v if p == 0, hor lcol(stc2)											///
		||	conn x b if p == 1, col(stc1) msym(O) msize(medlarge)								///
		||	conn x b if p == 0, col(stc2) msym(T) msize(medlarge)								///
		xtitle("Coefs and 95% CIs")																///
		xlab(-.3(.1).3, format(%4.2fc) labsize(medlarge))										///
		xline(0)																				///
		yscale(off)																				///
	legend(order(5 "Positive" 6 "Negative") size(*.8) symy(*.5) symx(*.7) region(lcol(black))) 	///
	name(gmat, replace) fxsize(70) title("{bf:(b)} Math", pos(12) margin(0 0 5 0))
	
	grc1leg2 gdan gmat, ycommon xcommon legend(gmat) span position(2)  ring(0)
	graph export $out/results_asymmetry.eps, replace
	graph export $out/results_asymmetry.emf, replace 
	
* ================================================================================================ *
* SOCIAL DIFFERENTIALS
* ================================================================================================ *	

global FEs "pnr grade cohort"

// DANISH 
	use $tmp/fe_student_exog_dan, clear 
	merge m:1 pnr using $dir/data/students_covars, keep(1 3) keepus(*ses*) nogen
	
	* Matrix goes: point estimate, lower ci, upper ci, variable, positive=1/0, ses group
	
	// CTFD (v=4)
	eststo d_ctfdH: reghdfe zscore d_ctfd_p d_ctfd_m C if ses_high == 1, absorb($FEs) cluster(pnr)
		mat a = r(table)' 
		mat a = (a[1,1], a[1,5], a[1,6], 4, 1, 1 \ a[2,1], a[2,5], a[2,6], 4, 0, 1) 
		mat a11 = a

	eststo d_ctfdL: reghdfe zscore d_ctfd_p d_ctfd_m C if ses_high == 0, absorb($FEs) cluster(pnr)
		mat a = r(table)' 
		mat a = (a[1,1], a[1,5], a[1,6], 4, 1, 0 \ a[2,1], a[2,5], a[2,6], 4, 0, 0) 
		mat a12 = a
	
	
	// SPC (V=3)
	* Matrix goes: point estimate, lower ci, upper ci, variable, positive=1/0, ses group
	eststo d_spcH: reghdfe zscore d_spceqv_p d_spceqv_m C if ses_high == 1 , absorb($FEs) cluster(pnr)
		mat a = r(table)' 
		mat a = (a[1,1], a[1,5], a[1,6], 3, 1, 1 \ a[2,1], a[2,5], a[2,6], 3, 0, 1) 
		mat a21 = a

	eststo d_spcL: reghdfe zscore d_spceqv_p d_spceqv_m C if ses_high == 0, absorb($FEs) cluster(pnr)
		mat a = r(table)' 
		mat a = (a[1,1], a[1,5], a[1,6], 3, 1, 0 \ a[2,1], a[2,5], a[2,6], 3, 0, 0) 
		mat a22 = a
	
	
	mat A = a11 \ a12 \ a21 \ a22 
	mat dan = A
	
// MATH 
	use $tmp/fe_student_exog_mat, clear 
	merge m:1 pnr using $dir/data/students_covars, keep(1 3) keepus(*ses*) nogen
	
	* Matrix goes: point estimate, lower ci, upper ci, variable, positive=1/0, ses group
	
	// CTFD (v=4)
	eststo m_ctfdH: reghdfe zscore d_ctfd_p d_ctfd_m C if ses_high == 1 , absorb($FEs) cluster(pnr)
		mat a = r(table)' 
		mat a = (a[1,1], a[1,5], a[1,6], 4, 1, 1 \ a[2,1], a[2,5], a[2,6], 4, 0, 1) 
		mat a11 = a

	eststo m_ctfdL: reghdfe zscore d_ctfd_p d_ctfd_m C if ses_high == 0, absorb($FEs) cluster(pnr)
		mat a = r(table)' 
		mat a = (a[1,1], a[1,5], a[1,6], 4, 1, 0 \ a[2,1], a[2,5], a[2,6], 4, 0, 0) 
		mat a12 = a
	
	
	// SPC (V=3)
	* Matrix goes: point estimate, lower ci, upper ci, variable, positive=1/0, ses group
	eststo m_spcH: reghdfe zscore d_spceqv_p d_spceqv_m C if ses_high == 1 , absorb($FEs) cluster(pnr)
		mat a = r(table)' 
		mat a = (a[1,1], a[1,5], a[1,6], 3, 1, 1 \ a[2,1], a[2,5], a[2,6], 3, 0, 1) 
		mat a21 = a

	eststo m_spcL: reghdfe zscore d_spceqv_p d_spceqv_m C if ses_high == 0, absorb($FEs) cluster(pnr)
		mat a = r(table)' 
		mat a = (a[1,1], a[1,5], a[1,6], 3, 1, 0 \ a[2,1], a[2,5], a[2,6], 3, 0, 0) 
		mat a22 = a

	
	mat A = a11 \ a12 \ a21 \ a22 
	mat mat = A
	
* Appendix table 
	esttab d_ctfdL d_ctfdH m_ctfdL m_ctfdH using $out/app_results_ses_ctfd.tex, replace	///
		b(3) se(3)																				///
		booktabs width(\hsize) 																	///
		order (d_* C)																			///
		stats(N, label(" \textit{N} (observations)") fmt(%9.0gc)) 								///
		mgroup("Danish" "Mathematics", pattern(1 0 1 0 )  										///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 		///
		nonotes msign("$-$")																	///
		mtitle("Low-SES" "High-SES" "Low-SES" "High-SES")										///
		varlabels(d_ctfd_p "Certified, positive" d_ctfd_m "Certified, negative" C "Any change" _cons "Constant")

// SPC
	esttab d_spcL d_spcH m_spcL m_spcH using $out/app_results_ses_spc.tex, replace		///
		b(3) se(3)																				///
		booktabs width(\hsize) 																	///
		order (d_* C)																			///
		stats(N, label(" \textit{N} (observations)") fmt(%9.0gc)) 								///
		mgroup("Danish" "Mathematics", pattern(1 0 1 0 )  										///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 		///
		nonotes msign("$-$")																	///
		mtitle("Low-SES" "High-SES" "Low-SES" "High-SES")										///
		varlabels(d_spc_p "Certified, positive" d_spc_m "Certified, negative" C "Any change" _cons "Constant")
	
	
	
* DRAW 	

// DANISH 
		
	// CTFD
	clear
	svmat dan
	rename dan* A*
	rename (A1 A2 A3 A4 A5 A6) (b ll ul v p s)
	
		
	gen n = p
	replace n = n - .25 if s == 0
	replace n = n + .25 if s == 1 
	
	keep if v == 4
	
	// pseudo variable for nice legend 
	gen x = . 
	
	local O "mlab(b) mlabf(%4.3fc) mlabpos(1)"

	gr tw 	rspike ll ul n 	if s == 0, hor lcol(stc2)												///
		||	sc n b 			if s == 0, msym(O) col(stc2) msize(medlarge) `O' mlabcol(stc2)			///
		|| 	rspike ll ul n 	if s == 1, hor lcol(stc1)												///
		|| 	sc n b 			if s == 1, msym(T) mcol(stc1) msize(medlarge) `O' mlabcol(stc1)			///	
		xtitle("")																					///
		xlab(-.4(.2).4, format(%4.1fc))																///
		ytitle("{bf:Certified}")																	///
		ylab(0 `""Negative" "change ""' 1 `""Positive" "change""', notick)							///
		yline(0.5, lpat(solid) lcol(gs12)) xline(0)													///
		yscale(r(-0.5 1.5))																			///
		/* PSEUDO LEGEND */ 																		///
		|| conn b x, msym(O) col(stc2) msize(medlarge)												///
		|| conn b x, msym(T) col(stc1) msize(medlarge)												///	
		legend(off) name(ctfd_dan, replace) title("{bf:(a)} Reading", pos(12) size(medium)) fxsize(90)
		
	
	// SPC
	clear
	svmat dan
	rename dan* A*
	rename (A1 A2 A3 A4 A5 A6) (b ll ul v p s)
	
		
	gen n = p
	replace n = n - .25 if s == 0 
	replace n = n + .25 if s == 1 
	
	keep if v == 3
	
	// pseudo variable for nice legend 
	gen x = . 
	
	local O "mlab(b) mlabf(%4.3fc) mlabpos(1)"

	gr tw 	rspike ll ul n 	if s == 0, hor lcol(stc2)												///
		||	sc n b 			if s == 0, msym(O) col(stc2) msize(medlarge) `O' mlabcol(stc2)			///
		|| 	rspike ll ul n 	if s == 1, hor lcol(stc1)												///
		|| 	sc n b 			if s == 1, msym(T) mcol(stc1) msize(medlarge) `O' mlabcol(stc1)			///	
		xtitle("")																					///
		xlab(-.4(.2).4, format(%4.1fc))																///
		ytitle("{bf:Specialized}")																	///
		ylab(0 `""Negative" "change ""' 1 `""Positive" "change""', notick)							///
		yline(0.5, lpat(solid) lcol(gs12)) xline(0)													///
		yscale(r(-0.5 1.5))																			///
		/* PSEUDO LEGEND */ 																		///
		|| conn b x, msym(O) col(stc2) msize(medlarge)												///
		|| conn b x, msym(T) col(stc1) msize(medlarge)												///	
		legend(off) name(spc_dan, replace) title("{bf:(c)} Reading", pos(12) size(medium)) fxsize(90)
		
// MATH 
		
	// CTFD
	clear
	svmat mat
	rename mat* A*
	rename (A1 A2 A3 A4 A5 A6) (b ll ul v p s)
	
		
	gen n = p
	replace n = n - .25 if s == 0
	replace n = n + .25 if s == 1 
	
	keep if v == 4
	
	// pseudo variable for nice legend 
	gen x = . 
		
	local O "mlab(b) mlabf(%4.3fc) mlabpos(1)"
	
	gr tw 	rspike ll ul n 	if s == 0, hor lcol(stc2)												///
		||	sc n b 			if s == 0, msym(O) col(stc2) msize(medlarge) `O' mlabcol(stc2)			///
		|| 	rspike ll ul n 	if s == 1, hor lcol(stc1)												///
		|| 	sc n b 			if s == 1, msym(T) mcol(stc1) msize(medlarge) `O' mlabcol(stc1)			///	
		xtitle("")																					///
		xlab(-.4(.2).4, format(%4.1fc))																///
		ytitle("")																					///
		ylab(0 `""Negative" "change ""' 1 `""Positive" "change""', notick)							///
		yline(0.5, lpat(solid) lcol(gs12)) xline(0)													///
		yscale(r(-0.5 1.5))																			///
		/* PSEUDO LEGEND */ 																		///
		|| conn b x, msym(O) col(stc2) msize(medlarge)												///
		|| conn b x, msym(T) col(stc1) msize(medlarge)												///	
		yscale(off) fxsize(68) 																		///
		legend(off) name(ctfd_mat, replace) title("{bf:(b)} Math", pos(12) size(medium))								
	
	// SPC
	clear
	svmat mat
	rename mat* A*
	rename (A1 A2 A3 A4 A5 A6) (b ll ul v p s)
		
	gen n = p
	replace n = n - .25 if s == 0
	replace n = n + .25 if s == 1 
	
	keep if v == 3
	
	// pseudo variable for nice legend 
	gen x = . 
	
	local O "mlab(b) mlabf(%4.3fc) mlabpos(1)"
	
	gr tw 	rspike ll ul n 	if s == 0, hor lcol(stc2)												///
		||	sc n b 			if s == 0, msym(O) col(stc2) msize(medlarge) `O' mlabcol(stc2)			///
		|| 	rspike ll ul n 	if s == 1, hor lcol(stc1)												///
		|| 	sc n b 			if s == 1, msym(T) mcol(stc1) msize(medlarge) `O' mlabcol(stc1)			///	
		xtitle("")																					///
		xlab(-.4(.2).4, format(%4.1fc))																///
		ytitle("")																					///
		ylab(0 `""Negative" "change ""' 1 `""Positive" "change""', notick)							///
		yline(0.5, lpat(solid) lcol(gs12)) xline(0)													///
		yscale(r(-0.5 1.5))																			///
		/* PSEUDO LEGEND */ 																		///
		|| conn b x, msym(o) col(stc2) msize(medlarge)												///
		|| conn b x, msym(t) col(stc1) msize(medlarge)												///	
		yscale(off) fxsize(68) 																		///
		name(spc_mat, replace) title("{bf:(d)} Math",pos(12) size(medium))							///
		legend(order(6 "High-SES" 5 "Low-SES") c(2) size(7pt) symx(*.6) region(lcol(black)))
		
		 
	
	grc1leg ctfd_dan ctfd_mat spc_dan spc_mat, xcommon ycommon legend(spc_mat) pos(6) ring(1) 
	graph display, ysize(5) xsize(4) 
	graph export $dir/output/results_ses.eps, replace 
	graph export $dir/output/results_ses.emf, replace 
	
