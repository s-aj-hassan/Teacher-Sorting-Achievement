* ================================================================================================ *
* DANISH - CLASSROOM LEVEL
* ================================================================================================ *

* Construct classroom level data 

	use $tmp/teacher_student_dan, clear
	keep if inrange(t, 2013, 2018)
	
	keep instnr t classid grade teacher fag
	order instnr classid t grade teacher
	
	duplicates drop
	bysort instnr t classid: assert _N == 1 
	sort instnr classid grade t 
	
* Keep relevant grade levels 
	
	keep if inrange(grade, 1, 8)
	
* Groups of grades (1-2 = 2, 3-4 = 4, etc.)
	
	gen G = . 
	replace G = 2 if inrange(grade, 1, 2)
	replace G = 4 if inrange(grade, 3, 4)
	replace G = 6 if inrange(grade, 5, 6)
	replace G = 8 if inrange(grade, 7, 8)
	
* Keep those with 2 grades in each group (e.g. has grade 1 and 2 - because we need the lagged grades)
	
	bysort instnr classid G: keep if _N == 2
		
	bysort instnr classid G (grade): egen min = min(grade)
	bysort instnr classid G (grade): egen max = max(grade)
	
	drop if min == max
	
	drop min max
	

* Make sure "t" (school-year) and "grade" (grade level) are identical / interchangeable within classid 
* I.e. they should identify exactly the same observations

	bysort instnr classid t: assert _N == 1
	bysort instnr classid grade: assert _N == 1
	
	bysort instnr classid t: gen n1 = _n
	bysort instnr classid t: gen n2 = _n
	assert n1 == n2
	drop n1 n2 
	
	egen g1 = group(instnr classid t)
	egen g2 = group(instnr classid grade)
	assert g1 == g2
	drop g1 g2 		

* Keep classes without gaps 

	bysort instnr classid (t): gen x = t-t[_n-1] != 1 & _n != 1
	bysort instnr classid: egen X = max(x)
	drop if X == 1 
	
* Construct teacher change variable 

	bysort instnr classid (t): gen double jlag = teacher[_n - 1]
	
	gen C = teacher != jlag & !missing(jlag, teacher) 

* Make sure no variables start with "s" or "e"
	
	cap d s*
	if _rc != 111 {
		di "Remove/rename variables starting with s"
		stop 
	}
	cap d e* 
	if _rc != 111 {
		di "Remove/rename variables starting with e"
		stop 
	}	
	
* school start dates
	
	gen S = mdy(8, 1, t)
	gen E = mdy(7, 1, t+1)	
	
	
* Merge lagged teacher's parental leave (exclude transition grades in educational stages, i.e 4 and 7)
	
	rename jlag pnr 
	
		
	merge m:1 pnr using $dir/data/Z_pleave_spells, keep(1 3) keepus(e* s*) nogen
	
	ds s*
	global K: word count `r(varlist)'
	
	gen Z = 0
	forval k = 1/$K {
		
		replace Z = 1 if C == 1 & inrange(s`k', S, E) & !inlist(grade, 4, 7)
		replace Z = 1 if C == 1 & inrange(e`k', S, E) & !inlist(grade, 4, 7)
		

	}
	
	drop s* e*
	
	rename Z Z_pleave
	
	
	rename pnr jlag 
	sort instnr classid grade t 
	drop S E	
	
* Merge teacher quality variables and teacher's sex and age 
	
	rename t t0 
	
	// Actual teacher (in t)
	gen t = t0
	rename teacher pnr
	merge m:1 pnr t fag using $dir/data/teacher_qual, keep(1 3) keepus(ctfd spc spceqv expr gpa_std) nogen
	rename (ctfd spc spceqv expr gpa_std) (ctfd_A spc_A spceqv_A expr_A gpa_std_A)
	
	merge m:1 pnr using $dir/data/teachers_covars, keep(1 3) keepus(T_bdate T_female T_nonwest) nogen
	gen T_age = ((mdy(8,1,t-1)-T_bdate)/365)
	drop T_bdate 
	rename (T_age T_female T_nonwest) (T_age_A T_female_A T_nonwest_A)
	
	rename pnr teacher
	
	// Previous teacher (in t-1)
	drop t
	gen t = t0-1
	rename jlag pnr
	merge m:1 pnr t fag using $dir/data/teacher_qual, keep(1 3) keepus(ctfd spc spceqv expr gpa_std) nogen
	rename (ctfd spc spceqv expr gpa_std) (ctfd_C spc_C spceqv_C expr_C gpa_std_C)
	
	merge m:1 pnr using $dir/data/teachers_covars, keep(1 3) keepus(T_bdate T_female T_nonwest) nogen
	gen T_age = ((mdy(8,1,t-1)-T_bdate)/365)
	drop T_bdate 
	rename (T_age T_female T_nonwest) (T_age_C T_female_C T_nonwest_C)	
	
	rename pnr jlag
	drop t 
	
	rename t0 t

		
	save $tmp/student_fe_exoshock_classroom_dan, replace 
	
* ================================================================================================ *
* DANISH - STUDENT LEVEL 
* ================================================================================================ *
* Load data 
	
	use $tmp/teacher_student_dan, clear
	keep if inrange(t, 2013, 2018)

* Drop non-normal classes 

	merge 1:1 pnr t using $dir/data/udsp, keep(1 3) keepus(dual_lang spc_ed) nogen
	replace dual_lang = 0 if dual_lang == .
	replace spc_ed = 0 if spc_ed == . 
	
	bysort instnr classid grade t: gen class_size = _N
	keep if inrange(class_size, 10, 35)
	
	bysort instnr classid grade t: egen tot_dual_lang = total(dual_lang)
	bysort instnr classid grade t: egen tot_spc_ed = total(spc_ed)
	
	gen p_dual_lang = tot_dual_lang / class_size 
	gen p_spc_ed = tot_spc_ed / class_size 
	
	gen f_dual_lang = p_dual_lang >= .5 
	gen f_spc_ed = p_spc_ed >= .5 

	drop p_* dual* spc* tot_*
	
** Keep students who stay in same school throughout 
 	bysort pnr: egen min = min(real(instnr))
 	bysort pnr: egen max = max(real(instnr))
	gen switch = min != max
	drop min max 
	
* Cohort restrictions 
	
	gen cohort = t - grade
	ta cohort grade
	
	keep if 	(cohort == 2008 & inrange(grade, 5, 8)) | (cohort == 2009 & inrange(grade, 5, 8))	///
			|	(cohort == 2010 & inrange(grade, 5, 8)) | (cohort == 2011 & inrange(grade, 3, 6))	///
			|	(cohort == 2012 & inrange(grade, 3, 6))	| (cohort == 2013 & inrange(grade, 1, 4))	///
			|	(cohort == 2014 & inrange(grade, 1, 4)) 
						

	bysort pnr: egen min = min(cohort)
	bysort pnr: egen max = max(cohort)
	gen x = min != max
	bysort pnr: egen X = max(x)
	drop if X == 1 
	drop x X min max 
					
	* Merge test scores 
	
	gen fagid = "010" + string(grade)
	merge m:1 pnr fagid using $DNT/dnt_testscores, keep(1 3) keepus(zscore) nogen
	
	* Number of valid test scores 
	gen val = zscore != .
	bysort pnr: egen nval = total(val)
	keep if nval == 2 
	
	drop val nval

	* Drop those with gaps between grades
	bysort pnr (grade): gen x = (grade - grade[_n-1]) != 1 & _n != 1 
	bysort pnr: egen X = max(x)
	drop if X == 1 
	drop x X
	
	* Keep those observed in all relevant years 
	bysort pnr: gen nobs = _N 
	keep if nobs == 4
	
	**** Here we want to merge on classid - which teacher did you have, and did the CLASS has Z=1 
	
	merge m:1 instnr t classid using $tmp/student_fe_exoshock_classroom_dan, keep(1 3) keepus(instnr t classid)
	tab _merge 
	gen miss = _merge == 1 
	bysort pnr: egen MISS = max(miss)
	ta MISS 
	drop if MISS == 1
	drop miss MISS _merge
	
	* merge 
	merge m:1 instnr t classid using $tmp/student_fe_exoshock_classroom_dan, keep(1 3) nogen 

	foreach v in ctfd spc spceqv expr gpa_std { 
		gen d_`v' = 0
		replace d_`v' = `v'_A - `v'_C if Z_pleave == 1 
		
		gen d_`v'_p = d_`v' > 0 
		gen d_`v'_m = d_`v' < 0 
				
	}

	// Make sure GPA missings are missings (about 25%)
	replace d_gpa_std = . if gpa_std_A == . | gpa_std_C == .
	replace d_gpa_std_p = . if gpa_std_A == . | gpa_std_C == .
	replace d_gpa_std_m = . if gpa_std_A == . | gpa_std_C == .


save $tmp/fe_student_exog_dan, replace 

* ================================================================================================ *
* MATH - CLASSROOM LEVEL
* ================================================================================================ *

* Construct classroom level data 

	use $tmp/teacher_student_mat, clear
	keep if inrange(t, 2013, 2018)
	
	keep instnr t classid grade teacher fag
	order instnr classid t grade teacher
	
	duplicates drop
	bysort instnr t classid: assert _N == 1 
	sort instnr classid grade t 
	
* Keep relevant grade levels 
	
	keep if inrange(grade, 2, 6)

* Make sure "t" (school-year) and "grade" (grade level) are identical / interchangeable within classid 
* I.e. they should identify exactly the same observations

	bysort instnr classid t: keep if _N == 1
	bysort instnr classid grade: keep if _N == 1

	bysort instnr classid t: assert _N == 1
	bysort instnr classid grade: assert _N == 1
	
	bysort instnr classid t: gen n1 = _n
	bysort instnr classid t: gen n2 = _n
	assert n1 == n2
	drop n1 n2 
	
	egen g1 = group(instnr classid t)
	egen g2 = group(instnr classid grade)
	assert g1 == g2
	drop g1 g2 		

* Keep classes without gaps 

	bysort instnr classid (t): gen x = t-t[_n-1] != 1 & _n != 1
	bysort instnr classid: egen X = max(x)
	drop if X == 1 

* For math we don't need the "G" variable (see danish above) because it will produce gaps between
* grades due to the longer gap between subsequent tests in Math 

* Construct teacher change variable 

	bysort instnr classid (t): gen double jlag = teacher[_n - 1]
	
	gen C = teacher != jlag & !missing(jlag, teacher) 

* Make sure no variables start with "s" or "e"
	
	cap d s*
	if _rc != 111 {
		di "Remove/rename variables starting with s"
		stop 
	}
	cap d e* 
	if _rc != 111 {
		di "Remove/rename variables starting with e"
		stop 
	}	
	
* school start dates
	
	gen S = mdy(8, 1, t)
	gen E = mdy(7, 1, t+1)	
	
	
* Merge lagged teacher's parental leave, etc. (exclude transition grades 4 and 7) 
	
	rename jlag pnr 
	
		
	merge m:1 pnr using $dir/data/Z_pleave_spells, keep(1 3) keepus(e* s*) nogen
	
	ds s*
	global K: word count `r(varlist)'
	
	gen Z = 0
	forval k = 1/$K {
		
		replace Z = 1 if C == 1 & inrange(s`k', S, E) & !inlist(grade, 4, 7)
		replace Z = 1 if C == 1 & inrange(e`k', S, E) & !inlist(grade, 4, 7)

	}
	
	drop s* e*
	
	rename Z Z_pleave
		

	rename pnr jlag 
	sort instnr classid grade t 
	drop S E	
	
* Merge teacher quality variables and teacher's sex and age 
	
	rename t t0 
	
	// Actual teacher (in t)
	gen t = t0
	rename teacher pnr
	merge m:1 pnr t fag using $dir/data/teacher_qual, keep(1 3) keepus(ctfd spc spceqv expr gpa_std) nogen
	rename (ctfd spc spceqv expr gpa_std) (ctfd_A spc_A spceqv_A expr_A gpa_std_A)
	
	merge m:1 pnr using $dir/data/teachers_covars, keep(1 3) keepus(T_bdate T_female T_nonwest) nogen
	gen T_age = ((mdy(8,1,t-1)-T_bdate)/365)
	drop T_bdate 
	rename (T_age T_female T_nonwest) (T_age_A T_female_A T_nonwest_A)
	
	rename pnr teacher
	
	// Previous teacher (in t-1)
	drop t
	gen t = t0-1
	rename jlag pnr
	merge m:1 pnr t fag using $dir/data/teacher_qual, keep(1 3) keepus(ctfd spc spceqv expr gpa_std) nogen
	rename (ctfd spc spceqv expr gpa_std) (ctfd_C spc_C spceqv_C expr_C gpa_std_C)
	
	merge m:1 pnr using $dir/data/teachers_covars, keep(1 3) keepus(T_bdate T_female T_nonwest) nogen
	gen T_age = ((mdy(8,1,t-1)-T_bdate)/365)
	drop T_bdate 
	rename (T_age T_female T_nonwest) (T_age_C T_female_C T_nonwest_C)	
	
	rename pnr jlag
	drop t 
	
	rename t0 t
	
	save $tmp/student_fe_exoshock_classroom_mat, replace 


* ================================================================================================ *
* MATH - STUDENT LEVEL
* ================================================================================================ *

* Load data 
	
	use $tmp/teacher_student_mat, clear
	keep if inrange(t, 2013, 2018)
	
* Drop non-normal classes 

	merge 1:1 pnr t using $dir/data/udsp, keep(1 3) keepus(dual_lang spc_ed) nogen
	replace dual_lang = 0 if dual_lang == .
	replace spc_ed = 0 if spc_ed == . 
	
	bysort instnr classid grade t: gen class_size = _N
	keep if inrange(class_size, 10, 35)
	
	bysort instnr classid grade t: egen tot_dual_lang = total(dual_lang)
	bysort instnr classid grade t: egen tot_spc_ed = total(spc_ed)
	
	gen p_dual_lang = tot_dual_lang / class_size 
	gen p_spc_ed = tot_spc_ed / class_size 
	
	gen f_dual_lang = p_dual_lang >= .5 
	gen f_spc_ed = p_spc_ed >= .5 

	drop p_* dual* spc* tot_*
	
** Keep students who stay in same school throughout 

	bysort pnr: egen min = min(real(instnr))
	bysort pnr: egen max = max(real(instnr))
	gen switch = min != max
	drop min max 
	

* Cohort restrictions 
	
	gen cohort = t - grade
	ta cohort grade
	
	keep if inrange(cohort, 2011, 2012) & inrange(grade, 2, 6)
		
	bysort pnr: egen min = min(cohort)
	bysort pnr: egen max = max(cohort)
	
	gen x = min != max 
	bysort pnr: egen X = max(x)
	drop if X == 1 
	drop x X min max
	
	* Merge test scores 
	
	gen fagid = "020" + string(grade)
	merge m:1 pnr fagid using $DNT/dnt_testscores, keep(1 3) keepus(zscore) nogen
	
	* Number of valid test scores 
	gen val = zscore != .
	bysort pnr: egen nval = total(val)
	
	keep if nval == 2 
	
	drop val nval
	
	* Drop those with gaps between grades
	bysort pnr (grade): gen x = (grade - grade[_n-1]) != 1 & _n != 1 
	bysort pnr: egen X = max(x)
	drop if X == 1 
	drop x X
	
	* Keep those observed in all relevant years 
	bysort pnr: gen nobs = _N 
	keep if nobs == 5
	
	
	**** Here we want to merge on classid - which teacher did you have, and did the CLASS has Z=1 
	
	merge m:1 instnr t classid using $tmp/student_fe_exoshock_classroom_mat, keep(1 3) keepus(instnr t classid)
	tab _merge 
	gen miss = _merge == 1 
	bysort pnr: egen MISS = max(miss)
	ta MISS
	drop if MISS == 1
	drop miss MISS _merge
		
	* merge 
	merge m:1 instnr t classid using $tmp/student_fe_exoshock_classroom_mat, keep(1 3) nogen 

	foreach v in ctfd spc spceqv expr gpa_std { 
		gen d_`v' = 0
		replace d_`v' = `v'_A - `v'_C if Z_pleave == 1 
		
		gen d_`v'_p = d_`v' > 0 
		gen d_`v'_m = d_`v' < 0 
		
	}
	
	// Make sure GPA missings are missings (about 25%)
	replace d_gpa_std = . if gpa_std_A == . | gpa_std_C == .
	replace d_gpa_std_p = . if gpa_std_A == . | gpa_std_C == .
	replace d_gpa_std_m = . if gpa_std_A == . | gpa_std_C == .
	
save $tmp/fe_student_exog_mat, replace 

	