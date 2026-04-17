****************************************************************************************************
*
* STUDENT COVARIATES: PARENTAL INCOME 
* Every year from age 1-15 
*
*
*
* Missings are defined as having all income variables (gross, wage, net, transfer) as missings 
*
****************************************************************************************************

* Macros and templates 
	set varabbrev on

	global min = 1980 
	global max = 2018 
	
	do $fmt/fpi
	do $fmt/PPP_usd_dkkr

	global fpiref = $fpi2018
	global PPPref = $PPP2018

* Find mom's and dad's income every year	
	

	foreach par in mom dad { 
			
		use $tmp/students_demographics, clear 
		keep `par' 
		drop if `par' == . 
		rename `par' pnr
		duplicates drop 
		
		forval t = $min/$max { 

			global tt = `t' 
			
			do $fmt/income		
			
			foreach v in gross wage transfer net disp miss { 
				
				rename inc_`v' `par'_inc_`v'`t'
				
			}		
		}
		
		rename pnr `par'
		save $tmp/`par', replace 
				
	}
	

* Merge on student data 
	
	use $tmp/students_demographics, clear 
	keep pnr mom dad bdate 
	merge m:1 mom using $tmp/mom, keep(1 3) nogen 
	merge m:1 dad using $tmp/dad, keep(1 3) nogen 
	
* Construct age-specific parental variables 

	foreach v in gross wage transfer net miss { 
		
		forval j = 1/15 { 
			
			gen M_inc_`v'`j' = . 
			gen D_inc_`v'`j' = .
			
			forval t = $min/$max { 
				
				replace M_inc_`v'`j' = mom_inc_`v'`t' if `t' - year(bdate) == `j'
				replace D_inc_`v'`j' = dad_inc_`v'`t' if `t' - year(bdate) == `j'
				
			}
		}
	}

	drop mom_inc* dad_inc*
	drop D_inc_miss* M_inc_miss*
	rename (D_* M_*) (dad_* mom_*)
	
* Generate missing variables 
* Missing income in year t if all income variables are either 0 or missing 

	forval j = 1/15 {

		egen m = rowtotal(mom_inc_gross`j' mom_inc_wage`j' mom_inc_transfer`j' mom_inc_net`j')
		egen d = rowtotal(dad_inc_gross`j' dad_inc_wage`j' dad_inc_transfer`j' dad_inc_net`j')
		
		gen miss_mom_inc`j' = inlist(m, 0, .)
		gen miss_dad_inc`j' = inlist(d, 0, .)
		
		drop d m
		
	}
	
* Set missings in income variables to zero 
	
	foreach v in gross wage transfer net { 
	forval j = 1/15 {
	
		replace mom_inc_`v'`j' = 0 if mom_inc_`v'`j' == . 
		replace dad_inc_`v'`j' = 0 if dad_inc_`v'`j' == . 		
		
	}
	}
	

* Save data 
	
	forval j = 1/15 { 
		
		label var mom_inc_gross`j'	 	"Mother's gross income at child age `j'', PPP-Adjusted 2018-USD"
		label var mom_inc_wage`j' 		"Mother's wage income at child age `j'', PPP-Adjusted 2018-USD"
		label var mom_inc_transfer`j' 	"Mother's transfer income at child age `j'', PPP-Adjusted 2018-USD"
		label var mom_inc_net`j' 		"Mother's net income at child age `j'', PPP-Adjusted 2018-USD"
		
		label var dad_inc_gross`j'	 	"Father's gross income at child age `j'', PPP-Adjusted 2018-USD"
		label var dad_inc_wage`j' 		"Father's wage income at child age `j'', PPP-Adjusted 2018-USD"
		label var dad_inc_transfer`j' 	"Father's transfer income at child age `j'', PPP-Adjusted 2018-USD"
		label var dad_inc_net`j' 		"Father's net income at child age `j'', PPP-Adjusted 2018-USD"
		
		label var miss_mom_inc`j' 		"Mother's income missing at child age `j'"
		label var miss_dad_inc`j' 		"Father's income missing at child age `j'"
		
	}
	
	label data "Student covariates: Parental income"
	
	isid pnr
	save $tmp/students_par_income, replace 
	
	set varabbrev off

	