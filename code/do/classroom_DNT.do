* Classroom level test scores from DNT

	use $tmp/teacher_student_dan, clear 
	bysort pnr grade: keep if _N == 1
	
	keep if inlist(grade, 2, 4, 6, 8)
	
	gen fagid = "010" + string(grade)
	merge 1:1 pnr fagid using $DNT/dnt_testscores, keep(3) keepus(zscore) nogen
	
	collapse (mean) zscore, by(instnr classid t)
	bysort instnr classid t: assert _N == 1 
	
	save $dir/data/classroom_DNT_dan, replace 
	
* Average test scores by classroom, Math DNT 	
	
	use $tmp/teacher_student_mat, clear 
	bysort pnr grade: keep if _N == 1

	keep if inlist(grade, 3, 6)
	gen fagid = "020" + string(grade)
	merge 1:1 pnr fagid using $DNT/dnt_testscores, keep(3) keepus(zscore) nogen
	
	collapse (mean) zscore, by(instnr classid t)
	bysort instnr classid t: assert _N == 1 
	
	save $dir/data/classroom_DNT_mat, replace 
	