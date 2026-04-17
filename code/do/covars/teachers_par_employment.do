****************************************************************************************************
*
* TEACHER COVARIATES: PARENTAL EMPLOYMENT 
* Every year from age 1-15 
*
* Constructs 3 employment variables 
* emp = employed 
* ump = unemployed
* nlf = not in labor force 
* 
* MISSINGS:
* Missing if missing in RAS or if emp+ump+nlf = 0
*
* 
****************************************************************************************************
	
	set varabbrev on

* Macros and templates 
	
	global min = 1980 
	global max = 2018 
	
	do $fmt/fpi
	do $fmt/PPP_usd_dkkr

	global fpiref = $fpi2018
	global PPPref = $PPP2018

* Find mom's and dad's income every year	
	
	foreach par in mom dad { 
			
		use $tmp/teachers_demographics, clear 
		keep T_`par' 
		drop if T_`par' == . 
		rename T_`par' pnr
		duplicates drop 
		
		forval t = $min/$max { 

			global tt = `t' 
			
			do $fmt/RAS_employment		
			
			foreach v in emp ump nlf emp_miss { 
				
				rename `v' `par'_`v'`t'
				
			}		
		}
		
		rename pnr T_`par'
		save $tmp/`par', replace 
				
	}

	
* Merge on student data 
	
	use $tmp/teachers_demographics, clear 
	keep pnr T_mom T_dad T_bdate 
	merge m:1 T_mom using $tmp/mom, keep(1 3) nogen 
	merge m:1 T_dad using $tmp/dad, keep(1 3) nogen 
	
* Construct age-specific parental variables 

	foreach v in emp ump nlf emp_miss { 
		
		forval j = 1/15 { 
			
			gen M_`v'`j' = . 
			gen D_`v'`j' = .
			
			forval t = $min/$max { 
				
				replace M_`v'`j' = mom_`v'`t' if `t' - year(T_bdate) == `j'
				replace D_`v'`j' = dad_`v'`t' if `t' - year(T_bdate) == `j'
				
			}
		}
	}

	drop mom_* dad_*
	rename (D_* M_*) (dad_* mom_*)
	drop *emp_miss*
	
* Generate missing variables (missing if all zeroes are missing)

	forval j = 1/15 {

		egen m = rowtotal(mom_emp`j' mom_ump`j' mom_nlf`j')
		egen d = rowtotal(dad_emp`j' dad_ump`j' dad_nlf`j')
		
		gen miss_mom_emp`j' = inlist(m, 0, .)
		gen miss_dad_emp`j' = inlist(d, 0, .)
		
		drop d m
		
	}	
	
* Set missings in employment variables to zero 
	
	foreach v in emp ump nlf { 
	forval j = 1/15 {
	
		replace mom_`v'`j' = 0 if mom_`v'`j' == . 
		replace dad_`v'`j' = 0 if dad_`v'`j' == . 		
		
	}
	}
	

* Save data 
	
	forval j = 1/15 { 
		
		label var mom_emp`j'	 		"Teacher: Mother employed income at child age `j'"
		label var mom_ump`j'			"Teacher: Mother unemployed at child age `j'"
		label var mom_nlf`j'			"Teacher: Mother not in labor force at child age `j'" 
		
		
		label var dad_emp`j'	 		"Teacher: Father employed income at child age `j'"
		label var dad_ump`j'			"Teacher: Father unemployed at child age `j'"
		label var dad_nlf`j'			"Teacher: Father not in labor force at child age `j'" 
		
		
		label var miss_mom_emp`j' 		"Teacher: Mother's employment missing at child age `j'"
		label var miss_dad_emp`j' 		"Teacher: Father's employment missing at child age `j'"
		
	}
	
	rename (mom* dad* miss*) (T_mom* T_dad* T_miss*)	
	
	label data "Teacher covariates: Parental employment"
	
	isid pnr
	save $tmp/teachers_par_employment, replace 
	
	set varabbrev off


