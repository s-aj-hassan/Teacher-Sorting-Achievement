****************************************************************************************************
*
* STUDENT COVARIATES: PARENTAL EMPLOYMENT 
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
****************************************************************************************************

* Macros and templates 
		
	global min = 1980 
	global max = 2018 
	
	do $fmt/fpi
	do $fmt/PPP_usd_dkkr

	global fpiref = $fpi2018
	global PPPref = $PPP2018

	set varabbrev on
	
* Find mom's and dad's income every year	
	
	foreach par in mom dad { 
			
		use $tmp/students_demographics, clear 
		keep `par' 
		drop if `par' == . 
		rename `par' pnr
		duplicates drop 
		
		forval t = $min/$max { 

			global tt = `t' 
			
			do $fmt/RAS_employment		
			
			foreach v in emp ump nlf emp_miss { 
				
				rename `v' `par'_`v'`t'
				
			}		
		}
		
		rename pnr `par'
		save $tmp/`par', replace
				
	}

	set varabbrev off

	
* Merge on student data 
	
	use $tmp/students_demographics, clear 
	keep pnr mom dad bdate 
	merge m:1 mom using $tmp/mom, keep(1 3) nogen 
	merge m:1 dad using $tmp/dad, keep(1 3) nogen 
	
* Construct age-specific parental variables 

	foreach v in emp ump nlf emp_miss { 
		
		forval j = 1/15 { 
			
			gen M_`v'`j' = . 
			gen D_`v'`j' = .
			
			forval t = $min/$max { 
				
				replace M_`v'`j' = mom_`v'`t' if `t' - year(bdate) == `j'
				replace D_`v'`j' = dad_`v'`t' if `t' - year(bdate) == `j'
				
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
		
		label var mom_emp`j'	 	"Mother employed income at child age `j'"
		label var mom_ump`j'		"Mother unemployed at child age `j'"
		label var mom_nlf`j'		"Mother not in labor force at child age `j'" 
		
		
		label var dad_emp`j'	 	"Father employed income at child age `j'"
		label var dad_ump`j'		"Father unemployed at child age `j'"
		label var dad_nlf`j'		"Father not in labor force at child age `j'" 
		
		
		label var miss_mom_emp`j' 		"Mother's employment missing at child age `j'"
		label var miss_dad_emp`j' 		"Father's employment missing at child age `j'"
		
	}
	
	label data "Student covariates: Parental employment"
	
	isid pnr
	save $tmp/students_par_employment, replace 
	
	



