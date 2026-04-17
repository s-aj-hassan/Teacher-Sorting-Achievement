* Merge all covars on teacher
	
	use $dir/data/teacherlist, clear 
	keep pnr 
	duplicates drop
	
	merge 1:1 pnr using $tmp/teachers_demographics, keep(1 3) nogen
	merge 1:1 pnr using $tmp/teachers_par_income, keep(1 3) keepus(T_mom_inc_gross15 T_dad_inc_gross15 T_miss_mom_inc15 T_miss_dad_inc15) nogen
	merge 1:1 pnr using $tmp/teachers_par_employment, keep(1 3) keepus(T_mom_emp15 T_mom_ump15 T_mom_nlf15 T_dad_emp15 T_dad_ump15 T_dad_nlf15 T_miss_dad_emp15 T_miss_mom_emp15) nogen
	merge 1:1 pnr using $tmp/teachers_par_education, keep(1 3) keepus(T_mom_educ15 T_dad_educ15) nogen 
	merge 1:1 pnr using $tmp/teachers_ses_index, keep(1 3) keepus(T_ses T_ses_high T_ses_group) nogen 
	
	save $dir/data/teachers_covars, replace 