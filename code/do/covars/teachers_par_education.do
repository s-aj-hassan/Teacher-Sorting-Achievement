****************************************************************************************************
*
* TEACHER COVARIATES: PARENTAL EDUCATION 
* 
****************************************************************************************************

* Macros 

	global min = 1981
	global max = 2020 
	
* Search for parents' education in UDDA 
	
	foreach par in mom dad { 
	
		use $tmp/teachers_demographics, clear 
		keep T_`par' 
		duplicates drop 
		rename T_`par' pnr 
		save $tmp/`par', replace 

		forval t = $min/$max {
			
			use $dd100/udda`t', clear 
			keep pnr hfaudd hf_vfra 
			drop if missing(pnr, hf_vfra, hfaudd)
			
			merge m:1 pnr using $tmp/`par', keep(3) keepus(pnr) nogen 
			
			if `t' > $min append using $tmp/e_`par'
			duplicates drop 
			save $tmp/e_`par', replace 
			
		}

		rename pnr T_`par' 
		bysort T_`par' (hf_vfra): ge n = _n
		reshape wide hf_vfra hfaudd, i(T_`par') j(n)
		save $tmp/e_`par', replace 
	}

* Merge on student data and construct parental education variables for ages 1-15
* The variable is categorical and missings are set to = 0 
	
	use $tmp/teachers_demographics, clear 
	keep pnr T_bdate T_mom T_dad 
	
	foreach par in mom dad { 

		merge m:1 T_`par' using $tmp/e_`par', keep(1 3) nogen 

		reshape long hf_vfra hfaudd, i(pnr T_mom T_dad T_bdate) j(j)
		
		drop if hf_vfra == . & j > 1 
		rename hfaudd start 
		merge m:1 start using "$dstfmt/disced/n_audd_hoved_e_l1l5_k", keep(1 3) nogen
		rename AUDD_HOVED_E_L1L5_K AUDD
		destring AUDD, replace force
	
		ge x = . 
		replace x = 1 if inrange(AUDD, 1, 10)
		replace x = 2 if inrange(AUDD, 11, 25)
		replace x = 3 if inrange(AUDD, 26 , 59)
		replace x = 4 if inrange(AUDD, 60, 89)
		replace x = 0 if x == . 
		
		forval j = 1/15 { 
			
			gen X = x 
			gen tau = T_bdate + (365 * `j')
			replace X = . if hf_vfra > tau 
			
			bysort pnr: egen `par'_educ`j' = max(X)
			replace `par'_educ`j' = 0 if `par'_educ`j' == . 
			
			drop tau X 
			
		}
			
			keep pnr T_mom T_dad T_bdate *_educ* 
			bysort pnr: keep if _n == 1 
			
	}
	
	isid pnr 
	
* Save data 
	
	label define educat 0 "Missing" 1 "Primary education" 2 "Upper secondary" 3 "Vocational" 4 "University", replace 
	label value mom_educ* educat
	label value dad_educ* educat
	
	forval j = 1/15 { 
		
		label var mom_educ`j' "Teacher: Mother's education at child age `j'"
		label var dad_educ`j' "Teacher: Father's education at child age `j'"
		
	}
	
	rename (mom* dad*) (T_mom* T_dad*)
	
	save $tmp/teachers_par_education, replace 
