****************************************************************************************************
*
* Students
* SES Index (0 - 100 normalized)	
* 
****************************************************************************************************	

* Macros

	global out "$dir/output/documentation/ses_index_students"

* Load data and keep children in analytic sample 

	use $dir/data/studentlist, clear 
	
* Merge parental SES variables at child age 5 (income, employment, education)	
 
	merge m:1 pnr using $tmp/students_demographics, keep(1 3) keepus(bdate miss_dad miss_mom) nogen 
	merge m:1 pnr using $tmp/students_par_income, keep(1 3) keepus(mom_inc_gross5 dad_inc_gross5) nogen
	merge m:1 pnr using $tmp/students_par_education, keep(1 3) keepus(mom_educ5 dad_educ5) nogen
	merge m:1 pnr using $tmp/students_par_employment, keep(1 3) keepus(mom_emp5 dad_emp5) nogen

* Drop if both mom and dad missing from data 

	drop if miss_mom == 1 & miss_dad == 1 
	
* Dummies for (A) missing or only primary education, (B) university education 
	
	gen mom_ne5 = inlist(mom_educ5, 0, 1) 
	gen dad_ne5 = inlist(dad_educ5, 0, 1)

	gen mom_he5 = mom_educ5 == 4
	gen dad_he5 = dad_educ5 == 4 
	
	rename *inc_gross* *inc*

* Take maximum of mom and dad's variables	
	
	foreach v in inc ne he emp { 
		
		replace mom_`v'5 = . if miss_mom == 1 
		replace dad_`v'5 = . if miss_dad == 1
		
		gen `v' = max(mom_`v'5, dad_`v'5)
		
	}
	
	
* Generate birth year variable, drop missings and weird years (less than 50 obs.) 
* (those are not in the final sample anyway)

	gen t = year(bdate)
	keep pnr t inc he ne emp 
	drop if t == .	

	bysort t: gen N = _N 
	drop if N < 1000
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
	
* SES index by year 
	
	gen ses = . 
	
	local j 1 
	forval t = $min/$max { 
		
		// Estimate PCA in t 
		
			pca incrank ne he emp if t == `t'
		
		// Store matrix with all components 
		
			count if t == `t'
			scalar n = r(N)
			
			mat a = (`t' \ `t' \ `t' \ `t'), (1 \ 2 \ 3 \ 4) , e(L) , (n \ n \ n \ n)
		
		// Scree plot 
		
			screeplot, ci mcol(black) msym(o)				///
				title("")									///
				ylab(, format(%4.2fc))						///
				xtit("Component")							///
				addplot(function y = 1, lpat(dash) range(1 4)) legend(off)
			graph export $out/scree_`t'.eps, replace 
			
		// Predict SES index 
			
			predict comp if t == `t'
			replace ses = comp if t == `t'
			drop comp
			
			
		// Save matrices with components 
		
			if `j' == 1 mat cmp = a 
			else 		mat cmp = a \ cmp 
		
			local ++j 
				
		
	}

* Export long table to excel with all 4 component loadings
* and short table to latex with first components for appendix 

	preserve 

		clear
		svmat cmp 
		rename (cmp1 cmp2 cmp3 cmp4 cmp5 cmp6 cmp7) (t v c1 c2 c3 c4 n)
		
		gen var = ""
		replace var = "Income rank" 		if v == 1 
		replace var = "No education" 		if v == 2
		replace var = "College education" 	if v == 3 
		replace var = "Employment" 			if v == 4
			
		order t var
		sort t v
		export excel t var c1 c2 c3 c4 n using $out/pca_components_all.xlsx, replace firstrow(var) keepcellfmt
		
	* Export nice table with only first component 
		
		keep t v c1 n
		rename c1 fc
		
		reshape wide fc, i(t n) j(v)

		mkmat t n fc*
		
		mat tab = t, fc1, fc2, fc3, fc4, n
		
		frmttable using $out/pca_firstcomponents.tex, statmat(tab) replace tex fragment 	/// 
			sfmt(f,fc,fc,fc,fc,fc)	sdec(0,3,3,3,3,0)										///
			ctitle("Birth year", "Income rank", "No education", "College education", "Employment", "Obs.")
		
	restore 
	
	
* Standardize SES variable 

	
	su t 
	global min = r(min)
	global max = r(max)
	
	ge z = . 

	forval t = $min/$max {
		
		zscore ses if t == `t'
		replace z = z_ses if t == `t'
		drop z_ses 
		
	}
	
	drop ses 
	rename z ses 
	
* Normalize SES variable between 0 and 100 

	gen ses_norm = .
	
	forval t = $min/$max { 
		
		qui su ses if t == `t'
		gen x = (ses - r(min)) / (r(max) - r(min)) if t == `t'
		replace x = x * 100
		replace ses_norm = x if t == `t' 
		drop x 
		
	}
	
	su ses_norm
	
* High-ses (above median) dummy, and Ses group variable (terciles = low, med, high)

	su t 
	global min = r(min)
	global max = r(max)
	
	gen ses_high = . 
	gen ses_group = . 
	
	forval t = $min/$max { 
		
		xtile x = ses if t == `t', nq(3) 
		replace ses_group = x if t == `t'
		drop x 
		
		su ses if t == `t', d  
		gen x = ses > r(p50) if t == `t'
		replace ses_high = x if t == `t' 
		
		drop x 
		
	}
	
	
* Save data (individual level)

	save $tmp/students_ses_index, replace 
	
	
* Local polynomial graphs by year 	
	
	use $tmp/students_ses_index, clear 
	su t 
	global min = r(min)
	global max = r(max) 
	
	forval t = $min/$max { 
		
		gr tw 	lpoly incrank ses_norm if t == `t', 							///
			||	lpoly emp ses_norm if t == `t', 								///
			|| 	lpoly he ses_norm if t == `t',									///
			ylab(, format(%4.2fc))												///
			xtitle(SES index)													///
			legend(	label(1 "Average income rank") 								///
					label(2 "Share with employed parent")						///
					label(3 "Share with college educated parent") 				///
					label(4 "Share with uneducated parent") 					///
						c(2) pos(6))	
		graph export $out/lpoly_`t'.png, replace 
			
	}

* Binned scatter plot - all years, but include time
	
	use $tmp/students_ses_index, clear 
	
	foreach v in incrank ne he emp { 
		
		binscatter `v' ses_norm, absorb(t) savedata($tmp/`v') replace 
		
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
	
	gr tw 	conn incrank ses_norm, 	///
		||	conn emp ses_norm, 					///
		|| 	conn he ses_norm,					///
		||	conn ne ses_norm,				///
			ylab(, format(%4.2fc))												///
			xtitle(SES index)													///
			legend(	label(1 "Average income rank") 								///
					label(2 "Share with employed parent")						///
					label(3 "Share with college educated parent") 				///
					label(4 "Share with uneducated parent") 					///
						c(2) pos(6))	
	graph export $out/binscatter_allyears.eps, replace
	graph export $out/binscatter_allyears.png, replace 
	
	erase $tmp/emp.dta
	erase $tmp/he.dta
	erase $tmp/ne.dta
	erase $tmp/incrank.dta
	
* Binned scatter plots - by year 

	use $tmp/students_ses_index, clear 
	
	su t 
	global min = r(min)
	global max = r(max) 
	
	forval t = $min/$max {
		
		use $tmp/students_ses_index, clear
		keep if t == `t' 
	
		foreach v in incrank ne he emp { 
			
			binscatter `v' ses_norm, absorb(t) savedata($tmp/`v') replace 
			
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
		
		gr tw 	conn incrank ses_norm, 				///
			||	conn emp ses_norm, 						///
			|| 	conn he ses_norm,				///
			||	conn ne ses_norm,			///
				ylab(, format(%4.2fc))												///
				xtitle(SES index)													///
				xlab(1 10(10)100)													///
				legend(	label(1 "Average income rank") 								///
						label(2 "Share with employed parent")						///
						label(3 "Share with college educated parent") 				///
						label(4 "Share with uneducated parent") 					///
							c(2) pos(6))
		graph export $out/binscatter`t'.png, replace 
		
		erase $tmp/emp.dta
		erase $tmp/he.dta
		erase $tmp/ne.dta
		erase $tmp/incrank.dta
		
		
	}
