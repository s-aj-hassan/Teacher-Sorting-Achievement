* ================================================================================================ *
**# APPEND TEACHER-STUDENT DATASETS (UDDLAERER) AND MERGE CLASSID FROM UDKLASSE_ID DATA
* ================================================================================================ *

foreach fag in dan mat {
forval t = 2013/2019 { 
	
	if "`fag'" == "dan" local sub "DANSK"
	if "`fag'" == "mat" local sub "MATEMATIK"
	
	* Load data 
	use $UDL/uddlaerer`t'09, clear 

	foreach v of varlist _all {
		rename `v' `=strlower("`v'")'
	}

	* Merge classroom IDs
	merge m:1 pnr using $UDK/udklasse_id`t', keep(1 3) nogen
	rename klasseid classid
	
	destring pnr pnr_laerer, replace force 
	drop if pnr == . 
	drop if pnr_laerer == . 
	
	* Rename variables 
	rename pnr_laerer teacher
	rename udel grade 
	 
	* Keep grades 1-9
	keep if inrange(grade, 1, 9)

	* Keep Danish/Math
	keep if grundskolefag == "`sub'"
	
	* Save and append 
	gen t = `t'
	gen fag = "`fag'"
		
	if `t' > 2013 append using $tmp/append_teacher_student_`fag' 
	order pnr grade t instnr classid 
	sort pnr grade t 
	save $tmp/append_teacher_student_`fag', replace
	
}	
}	

* ================================================================================================ *
**# DOCUMENTATION AND SAVE  
* ================================================================================================ *

// Documentation program 
cap program drop doc 
program define doc 
	count 
	local N = r(N) 

	unique pnr 
	local Ns = r(sum)

	unique teacher 
	local Nt = r(sum)

	unique instnr grade classid 
	local Nc = r(sum)
	mat a = `N', `Ns', `Nt', `Nc'
end 
	

* ================================================================================================ *
**# DANISH DOCUMENTATION 
* ================================================================================================ *	

use $tmp/append_teacher_student_dan, clear 	

putexcel set $dir/output/documentation/teacher_student_append, replace 
putexcel B2 = "Danish, 2013-2019"
putexcel B3 = "Step"
putexcel C3 = "N"
putexcel D3 = "N(students)"
putexcel E3 = "N(teachers)"
putexcel F3 = "N(classrooms)"

// Open data 
doc 
putexcel B4 = "Open data"
putexcel C4 = matrix(a) 

* Drop if missing classid 
drop if missing(classid)

doc
putexcel B5 = "Drop missing classroom identifiers"
putexcel C5 = matrix(a)
	
* Keep normal classes
keep if inlist(kl_type, "40", "41")

doc
putexcel B6 = "Drop irregular classes"
putexcel C6 = matrix(a)

* Keep teacher with most hours 
bysort t pnr (klokketimer_laerer): keep if _n == _N 	

doc
putexcel B7 = "Keep teacher with most hours"
putexcel C7 = matrix(a)
				
* Drop classrooms that still have more than one teacher
sort t instnr grade classid teacher
by t instnr grade classid teacher: gen byte first_occ = _n==1
by t instnr grade classid: egen unique_teachers = total(first_occ)
keep if unique_teachers == 1 

doc
putexcel B8 = "Drop classrooms with more than one teacher"
putexcel C8 = matrix(a)

keep pnr grade t instnr classid teacher fag
save $tmp/teacher_student_dan, replace 


* ================================================================================================ *
**# MATH DOCUMENTATION 
* ================================================================================================ *

use $tmp/append_teacher_student_mat, clear 	

putexcel B11 = "Math, 2013-2019"
putexcel B12 = "Step"
putexcel C12 = "N"
putexcel D12 = "N(students)"
putexcel E12 = "N(teachers)"
putexcel F12 = "N(classrooms)"

// Open data 
doc 
putexcel B13 = "Open data"
putexcel C13 = matrix(a) 

* Drop if missing classid 
drop if missing(classid)

doc
putexcel B14 = "Drop missing classroom identifiers"
putexcel C14 = matrix(a)
	
* Keep normal classes
keep if inlist(kl_type, "40", "41")

doc
putexcel B15 = "Drop irregular classes"
putexcel C15 = matrix(a)

* Keep teacher with most hours 
bysort t pnr (klokketimer_laerer): keep if _n == _N 	

doc
putexcel B16 = "Keep teacher with most hours"
putexcel C16 = matrix(a)
				
* Drop classrooms that still have more than one teacher
sort t instnr grade classid teacher
by t instnr grade classid teacher: gen byte first_occ = _n==1
by t instnr grade classid: egen unique_teachers = total(first_occ)
keep if unique_teachers == 1 

doc
putexcel B17 = "Drop classrooms with more than one teacher"
putexcel C17 = matrix(a)

keep pnr grade t instnr classid teacher fag
save $tmp/teacher_student_mat, replace 

putexcel save

