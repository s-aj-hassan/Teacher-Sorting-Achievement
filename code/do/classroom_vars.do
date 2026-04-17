* Aggregate variables at the classroom level 

	use $tmp/teacher_student_dan, clear
	append using $tmp/teacher_student_mat
	keep pnr instnr t grade 
	duplicates drop
	
	gen fag = "dan"
	merge m:1 pnr instnr fag grade t using $tmp/teacher_student_dan, keep(1 3) keepus(classid) nogen
	rename classid classid_dan
	
	replace fag = "mat"
	merge m:1 pnr instnr fag grade t using $tmp/teacher_student_mat, keep(1 3) keepus(classid) nogen
	rename classid classid_mat

	gen x = classid_dan == classid_mat & !missing(classid_dan, classid_mat)		
	assert x == 1 if !missing(classid_dan, classid_mat)
	drop x 
	
	gen classid = classid_dan
	replace classid = classid_mat if classid == ""
	
	drop fag classid_dan classid_mat
	
	merge m:1 pnr using $dir/data/students_covars, keep(1 3) keepus(nonwest female ses) nogen
	
	keep instnr grade t classid nonwest female ses 
	
	collapse (mean) nonwest female ses, by(instnr t classid)
	bysort instnr t classid: assert _N == 1

	save $dir/data/classroom_vars, replace 
	
	
	
	