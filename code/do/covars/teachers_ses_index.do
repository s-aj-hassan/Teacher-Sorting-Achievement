****************************************************************************************************
*
* Teachers
* SES Index (0 - 100 normalized)	
* 
****************************************************************************************************	

* Macros

	global out "$dir/output/documentation/ses_index_teachers"

* Load teachers 

	use $dir/data/teacherlist, clear 

* Merge parental SES variables at child age 5 (income, employment, education)	
 
	merge m:1 pnr using $tmp/teachers_demographics, keep(1 3) 	keepus(T_bdate T_dad T_mom) nogen 
	merge m:1 pnr using $tmp/teachers_par_income, keep(1 3) 	keepus(T_mom_inc_gross15 T_dad_inc_gross15) nogen
	merge m:1 pnr using $tmp/teachers_par_education, keep(1 3) 	keepus(T_mom_educ15 T_dad_educ15) nogen
	merge m:1 pnr using $tmp/teachers_par_employment, keep(1 3) keepus(T_mom_emp15 T_dad_emp15) nogen

	rename T_* *
	gen miss_mom = mom == . 
	gen miss_dad = dad == .
	
* Drop if both mom and dad missing from data 

	drop if miss_mom == 1 & miss_dad == 1 
	
* Dummies for (A) missing or only primary education, (B) university education 
	
	gen mom_ne15 = inlist(mom_educ15, 0, 1) 
	gen dad_ne15 = inlist(dad_educ15, 0, 1)

	gen mom_he15 = mom_educ15 == 4
	gen dad_he15 = dad_educ15 == 4 
	
	rename *inc_gross* *inc*

* Take maximum of mom and dad's variables	
	
	foreach v in inc ne he emp { 
		
		replace mom_`v'15 = . if miss_mom == 1 
		replace dad_`v'15 = . if miss_dad == 1
		
		gen `v' = max(mom_`v'15, dad_`v'15)
		
	}
	
	
* Generate birth year variable, drop missings and weird years (less than 50 obs.) 
* (those are not in the final sample anyway)

	gen t = year(bdate)
	keep pnr t inc he ne emp 
	drop if t == .	

	bysort t: gen N = _N 
	drop if N < 100
	drop N 
	
* Calculate income rank by year 

	su t 
	global min = r(min)
	global max = r(max)
	
	gen incrank = . 
	forval t = $min/$max { 
		
		xtile x = inc if t == `t', nq(100)
		replace incrank = x if t == `t'
		
		drop x
	}
	
	replace incrank = incrank / 100 
	
* SES index (pooled over yeras - because some years too few teachers)
	
	
	// Estimate PCA in t 
	
		pca incrank ne he emp 
	
	// Store matrix with all components 
	
		count 
		scalar n = r(N)
		
		mat a = (1 \ 2 \ 3 \ 4) , e(L) , (n \ n \ n \ n)
	
	// Scree plot 
	
		screeplot, ci msym(o) mcol(black)				///
			title("")									///
			ylab(, format(%4.2fc))						///
			xtit("Component")							///
			addplot(function y = 1, lpat(dash) range(1 4)) legend(off)
		graph export $out/scree.eps, replace 
		graph export $out/scree.png, replace 		
		
	// Predict SES index 
		
		predict ses			
		
	// Save matrices with components 
	
		mat cmp = a 
		
* Export long table to excel with all 4 component loadings
* and short table to latex with first components for appendix 

	preserve 

		clear
		svmat cmp 
		rename (cmp1 cmp2 cmp3 cmp4 cmp5 cmp6) (v c1 c2 c3 c4 n)
		
		gen var = ""
		replace var = "Income rank" 		if v == 1 
		replace var = "No education" 		if v == 2
		replace var = "College education" 	if v == 3 
		replace var = "Employment" 			if v == 4
			
		order var
		sort v
		export excel var c1 c2 c3 c4 n using $out/pca_components_all.xlsx, replace firstrow(var) keepcellfmt

	restore 
	
* Standardize SES variable (by 9 year intervals .. i.e. born 1950-59, 1960-69, and so on)
* otherwise not enough variation

* Create teacher's birth cohort
	
	su t 

	gen cohort = . 
	
	forval t = 1950(10)1990 { 
		
		local tt = `t' + 9
		replace cohort = `t' if inrange(t, `t', `tt')
	
	}


	su cohort
	global min = r(min)
	global max = r(max)

	gen z = . 
	forval t = $min/$max {
		
		zscore ses if cohort == `t'
		replace z = z_ses if cohort == `t'
		drop z_ses 
		
	}
	
	drop ses 
	rename z ses 
	
* Normalize SES variable between 0 and 100 

	gen ses_norm = .
	
	levelsof cohort
	local C = r(levels)
	
	foreach t in `C' { 
		
		qui su ses if cohort == `t'
		gen x = (ses - r(min)) / (r(max) - r(min)) if cohort == `t'
		replace x = x * 100
		replace ses_norm = x if cohort == `t' 
		drop x 
		
	}
	
	su ses_norm
	
* High-ses (above median) dummy, and Ses group variable (terciles = low, med, high)

	
	gen ses_high = . 
	gen ses_group = .
	
	levelsof cohort
	local C = r(levels)
 
	
	foreach t in `C' { 
		
		xtile x = ses if cohort == `t', nq(3) 
		replace ses_group = x if cohort == `t'
		drop x 
		
		su ses if cohort == `t', d  
		gen x = ses > r(p50) if cohort == `t'
		replace ses_high = x if cohort == `t' 
		
		drop x 
		
	}
	
	
* Save data (individual level)

	save $tmp/teachers_ses_index, replace 
	

* Local polynomial graphs by cohort 	
	
	use $tmp/teachers_ses_index, clear 
	

	levelsof cohort
	local C = r(levels)
	
	foreach t in `C' {
		
		gr tw 	lpoly incrank ses_norm if cohort == `t', 		///
			||	lpoly emp ses_norm if cohort == `t', 			///
			|| 	lpoly he ses_norm if cohort == `t',				///
			||	lpoly ne ses_norm if cohort == `t',				///
			ylab(, format(%4.2fc))														///
			xtitle(SES index)															///
			legend(	label(1 "Average income rank") 										///
					label(2 "Share with employed parent")								///
					label(3 "Share with college educated parent") 						///
					label(4 "Share with uneducated parent") 							///
						c(2) pos(6))	
		graph export $out/lpoly_`t'.png, replace
			
	}

* Binned scatter plot - all years, but include time
	
	use $tmp/teachers_ses_index, clear 
		
	foreach v in incrank ne he emp { 
		
		binscatter `v' ses_norm, absorb(cohort) savedata($tmp/`v') replace 
		
		preserve
			clear 
			import delimited using $tmp/`v'
			save $tmp/`v', replace 
			erase $tmp/`v'.csv
			erase $tmp/`v'.do
		restore
	}
	
	use $tmp/incrank, clear 

	foreach v in emp he ne {
		append using $tmp/`v'
	}
	
	gr tw 	conn incrank ses_norm, 		///
		||	conn emp ses_norm, 			///
		|| 	conn he ses_norm,			///
		||	conn ne ses_norm,			///
			ylab(, format(%4.2fc))													///
			xtitle(SES index)														///
			legend(	label(1 "Average income rank") 									///
					label(2 "Share with employed parent")							///
					label(3 "Share with college educated parent") 					///
					label(4 "Share with uneducated parent") 						///
						c(2) pos(6))	
	graph export $out/binscatter_allyears.eps, replace 
	graph export $out/binscatter_allyears.png, replace 

	
	erase $tmp/emp.dta
	erase $tmp/he.dta
	erase $tmp/ne.dta
	erase $tmp/incrank.dta
	
* Binned scatter plots - by year 

	use $tmp/teachers_ses_index, clear 
	
	levelsof cohort
	local C = r(levels)
 
	foreach t in `C' {
		
		use $tmp/teachers_ses_index, clear
		keep if cohort == `t' 
	
		foreach v in incrank ne he emp { 
			
			binscatter `v' ses_norm, absorb(cohort) savedata($tmp/`v') replace 
			
			preserve
				clear 
				import delimited using $tmp/`v'
				save $tmp/`v', replace 
				erase $tmp/`v'.csv
				erase $tmp/`v'.do
			restore
		}
		
		use $tmp/incrank, clear 

		foreach v in emp he ne {
			append using $tmp/`v'
		}
		
		gr tw 	conn incrank ses_norm,		///
			||	conn emp ses_norm, 			///
			|| 	conn he ses_norm,			///
			||	conn ne ses_norm,			///
				ylab(, format(%4.2fc))													///
				xtitle(SES index)														///
				legend(	label(1 "Average income rank") 									///
						label(2 "Share with employed parent")							///
						label(3 "Share with college educated parent") 					///
						label(4 "Share with uneducated parent") 						///
							c(2) pos(6))	
		graph export $out/binscatter`t'.png, replace
		
		erase $tmp/emp.dta
		erase $tmp/he.dta
		erase $tmp/ne.dta
		erase $tmp/incrank.dta
		
		
	}

* Rename to T_

	use $tmp/teachers_ses_index, clear
	ds pnr, not 
	local vars `r(varlist)'
	foreach v in `vars' {
	    
		rename `v' T_`v'
		
	}
	
	save $tmp/teachers_ses_index, replace 
	