****************************************************************************************************
*
* STUDENET COVARIATES: PARENTAL DIVORCE 
*
* Based on mothers 
*
****************************************************************************************************

* Local macros 

	global min = 1980
	global max = 2019

* Load student demographics data set and keep mothers 
	
	use $tmp/students_demographics, clear
	keep if miss_mom == 0 
	keep mom 
	rename mom pnr 
	duplicates drop

* Find maternal divorces every year in population registers FAIN/BEF 

	forval t = $min/$max {

		if `t' < 1986 { 
			
			merge 1:1 pnr using $dd100/fain`t', keep(1 3) keepus(scivdto`t' civst`t') nogen 
			rename (scivdto`t' civst`t') (date`t' status`t')
			
		}

		else { 
			
			merge 1:1 pnr using $dd100/bef`t', keep(1 3) keepus(civ_vfra`t' civst`t') nogen 
			rename (civ_vfra`t' civst`t') (date`t' status`t')
			
		}

	}

* Reshape wide --> long, and keep divorce records 

	reshape long date status, i(pnr) j(n)
	drop if date == . & status == ""	
	keep if inlist(status, "O", "F")
	assert date != . 
	drop n status
	duplicates drop

	bysort pnr (date): ge n = _n

* Reshape long --> wide, and merge on demographcis data 

	reshape wide date, i(pnr) j(n)
	rename pnr mom
	
	save $tmp/hlp, replace 
	
	use $tmp/students_demographics, clear
	keep if miss_mom == 0 
	keep pnr mom bdate 
	
	merge m:1 mom using $tmp/hlp, keep(1 3) nogen 
	reshape long date, i(pnr mom bdate) j(n)
	
	drop if date == . 
	
* Construct indicator variables for whether pnr's mom was divorced every year from 1 - 15

	forval t = 1/15 {
	    
		gen x = date <= (bdate + (365 * `t'))
		bysort pnr: egen mom_div`t' = max(x)
		drop x 
		label var mom_div`t' "Mom divorced, age `t'"
		
	}
	
	keep pnr mom_div*
	duplicates drop 
	
* Merge on original data, set missings to 0

	save $tmp/hlp, replace 
	
	use $dir/data/studentlist, clear
	merge 1:1 pnr using $tmp/hlp, keep(1 3) keepus(mom_div*) nogen
	
	forval t = 1/15 { 
		replace mom_div`t' = 0 if mom_div`t' == . 
	}

* Save data

	label var pnr "Person ID"
	label data "Student covariates: Mom divorced"
	
	save $tmp/students_par_divorce, replace 
