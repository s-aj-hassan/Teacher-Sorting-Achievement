* ================================================================================================ *
* SCHOOL GPA FROM UDFK
* ================================================================================================ *

	use $UDFK/udfk_all_grade9, clear
	bysort instnr t: egen GPA = mean(gpa)
	drop if GPA == . 
	keep instnr t GPA 
	duplicates drop
	keep if inrange(t, 2012, 2018)

	gen GPA_qnt = . 
	forval t = 2012/2018 { 
		
		xtile x = GPA if t == `t', n(5)
		replace GPA_qnt = x if t == `t'
		drop x 
		
	}
	
	tostring instnr, replace
	save $dir/data/school_gpa, replace 
	
* ================================================================================================ *
* SCHOOL SES INDEX AND VARIABLES
* ================================================================================================ *

	use $tmp/teacher_student_dan, clear
	append using $tmp/teacher_student_mat
	keep pnr instnr t 
	duplicates drop 
	drop if t == 2019
	
	merge m:1 pnr using $dir/data/students_covars, keep(1 3) keepus(ses *_educ5 nonwest *gross5) nogen
	
	* Construct parental university dummies 
	gen daduni = dad_educ5 == 4
	gen momuni = mom_educ5 == 4 
	
	* Renaem parental income vars 
	rename (dad_inc_gross5 mom_inc_gross5) (dadinc mominc)
	
	collapse (mean) ses daduni momuni dadinc mominc nonwest, by(instnr t)
	duplicates drop

	* Create ses quantiles
	su t 
	
	global min = r(min)
	global max = r(max)
	
	gen ses_group = . 
	gen ses_high = . 
	
	forval t = $min/$max { 
	
		xtile x = ses if t == `t', nq(3)
		replace ses_group = x if t == `t'
		drop x
		
		su ses if t == `t', d
		
		gen x = ses > r(p50) if t == `t'
		replace ses_high = x if t == `t'
		drop x 
		

	}
	
	* School parental income quantiles
		su t 
		local min = r(min)
		local max = r(max)
		
		gen dadinc_qnt = .
		gen mominc_qnt = . 
		
		forval t = `min'/`max' {
			
			xtile D = dadinc if t == `t', nq(5)			
			xtile M = mominc if t == `t', nq(5)
			
			replace dadinc_qnt = D if t == `t'
			replace mominc_qnt = M if t == `t'	
			
			drop D M 
			
		}
		
		replace dadinc = dadinc / 1000
		replace mominc = mominc / 1000
		
		duplicates drop
	
	save $dir/data/school_vars, replace 