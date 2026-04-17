* Merge all covars on student
	
	use $dir/data/studentlist, clear
	
	merge 1:1 pnr using $tmp/students_demographics, keep(1 3) nogen
	merge 1:1 pnr using $tmp/students_mfr, keep(1 3) nogen
	merge 1:1 pnr using $tmp/students_par_divorce, keep(1 3) keepus(mom_div5) nogen
	merge 1:1 pnr using $tmp/students_par_income, keep(1 3) keepus(mom_inc_gross5 dad_inc_gross5 miss_mom_inc5 miss_dad_inc5) nogen
	merge 1:1 pnr using $tmp/students_par_employment, keep(1 3) keepus(mom_emp5 mom_ump5 mom_nlf5 dad_emp5 dad_ump5 dad_nlf5 miss_dad_emp5 miss_mom_emp5) nogen
	merge 1:1 pnr using $tmp/students_par_education, keep(1 3) keepus(mom_educ5 dad_educ5) nogen 
	merge 1:1 pnr using $tmp/students_ses_index, keep(1 3) keepus(ses ses_high ses_group) nogen 
	
	save $dir/data/students_covars, replace 