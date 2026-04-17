* ================================================================================================ *
* teacher_qual.do 
* This dofile codes teacher qualification measures
* ================================================================================================ *

* ================================================================================================ *
* Certified 
* ================================================================================================ *

use $dd100/udsf2019, clear
destring pnr, replace force
drop if pnr == . 
keep if inlist(senaudd, 3329, 5440, 5441)
bysort pnr (SEN_VFRA): keep if _n == 1 

keep pnr SEN_VFRA 
rename SEN_VFRA date_ctfd

// Save a dataset with teacher graduation dates 
save $dir/data/ctfd_dates, replace 

// Now create yearly dummy for being certified (in the available teacher-student data years)

expand 2019 - 2013 + 1 
bysort pnr: gen t = 2013 + _n - 1
replace t = mdy(10, 1, t)
gen ctfd = date_ctfd <= t
replace t = year(t)	
keep pnr t ctfd

save $tmp/ctfd, replace 

* ================================================================================================ *
* Specialized 
* ================================================================================================ *


forval t = 2013/2019 { 
	use $UDL/uddlaerer`t'09, clear 
	keep PNR_LAERER grundskolefag LAERER_UDDANNELSESNIVEAU
	rename PNR_LAERER pnr
	destring pnr, replace force 
	drop if pnr == . 
	
	gen fag = "dan" if grundskolefag == "DANSK"
	replace fag = "mat" if grundskolefag == "MATEMATIK"
	keep if fag != ""
	duplicates drop 
	
	rename LAERER_UDDANNELSESNIVEAU x 
	
	gen x_spc = x == "L"
	gen x_spceqv = x == "K"
	replace x_spceqv = 1 if x_spc == 1
	
	bysort pnr fag: egen spc 	= max(x_spc)
	bysort pnr fag: egen spceqv = max(x_spceqv)
	
	keep pnr fag spc spceqv
	gen t = `t' 
	
	if `t' > 2013 append using $tmp/x_spc
	save $tmp/x_spc, replace 
	
}

* Now if specialized in t, set all k < t to specialized 

	use $tmp/x_spc, clear
	keep if spc == 1 
	bysort pnr fag (t): keep if _n == 1 
	keep pnr fag t
	rename t t_first_spc 
	save $tmp/spc_first, replace 
	
	use $tmp/x_spc, clear
	keep if spceqv == 1 
	bysort pnr fag (t): keep if _n == 1 
	keep pnr fag t
	rename t t_first_spceqv
	save $tmp/spceqv_first, replace 
	
* Now create year-subject panel for all teachers with dummies for spc

	use $dir/data/teacherlist, clear 
	expand 2
	
	sort pnr 
	gen fag = ""
	bysort pnr: replace fag = "dan" if _n == 1
	bysort pnr: replace fag = "mat" if _n == 2 
	
	expand 2019 - 2013 + 1 
	bysort pnr fag: ge t = _n + 2013 - 1 

	merge m:1 pnr fag using $tmp/spc_first, keep(1 3) nogen 
	gen spc = t >= t_first_spc 
	
	merge m:1 pnr fag using $tmp/spceqv_first, keep(1 3) nogen 
	gen spceqv = t >= t_first_spceqv 
	
	keep pnr fag t spc spceqv
	
	* Assert more in spc_eqv than in spc

	su spc 
	local m1 = r(mean)
	su spceqv 
	local m2 = r(mean)
	assert `m2' > `m1'
	
	save $tmp/spc, replace

* ================================================================================================ *
* Experience 
* ================================================================================================ *

	// AKM before 1980 very unreliable. From 1980 there are around 80-90 thousand people 
	// Employed in teacher professions every year. This correspond OK to official numbers.
	// 1976-1979 it's around 6 thousand. 

	global min = 1980
	global max = 2018 
	
	forval t = $min/$max {
	    
		use $dd100/akm`t', clear 
		drop if pnr == .
		
		if `t' <= 1990 { 
			
			keep if branche_77 == 93103
		}

		
		if inrange(`t', 1991, 2009) { 
			
			cap destring disco_alle_indk_13, replace 
			keep if inlist(disco_alle_indk_13, 233000, 233100, 233110)
			
		}
		
		if `t' > 2009 {
			
			cap destring disco08_alle_indk_13, replace 
			keep if inlist(disco08_alle_indk_13, 234100, 234110, 234120)
		}
		
		keep pnr
		bysort pnr: keep if _n == 1 
		
		ge t = `t'
		
		if `t' > $min append using $tmp/akm
		save $tmp/akm, replace
		
	}
	
	* Years in UDDLARER 
	
	forval t = 2013/2019 {
		
		use $UDL/uddlaerer`t'09, clear 
		keep PNR_LAERER 
		rename PNR_LAERER pnr
		destring pnr, replace force 
		drop if pnr == . 
		duplicates drop 
		gen t = `t' 
		if `t' > 2013 append using $tmp/x_expr
		save $tmp/x_expr, replace 
		
		
	}
	
	gen UDL = 1 
	reshape wide UDL, i(pnr) j(t)
	
	forval j=2013/2019 {
		replace UDL`j' = 0 if UDL`j' == . 
	}
	
	bysort pnr: assert _N == 1
		
	* Merge AKM 
	
	expand 2019 - 1980 + 1 
	bysort pnr: gen t = 1980 + _n - 1
	merge 1:1 pnr t using $tmp/akm, keep(1 3) 
	
	gen x = _merge == 3 
	drop _merge 
	
	forval j = 2013/2019 { 
		replace x = 1 if UDL`j' == 1 & t == `j'
	}
	
	drop UDL*
	
	* Aggreagte 
	bysort pnr (t): gen expr_yrs = sum(x)
	
	* Keep relevant years 
	
	keep pnr t expr_yrs 
	keep if inrange(t, 2013, 2019)
	
	* Experienced dummy 
	
	gen expr = expr_yrs > 2 
	
	save $tmp/expr, replace 
	
* ================================================================================================ *
* High school grades  
* ================================================================================================ *
	
	* Find highschool GPA from UDG

		use $dd100/udg2021, clear
		keep pnr karakter_udd_vtil audd karakter_udd skala 
	
	* Merge AUDD codes and keep high school 
	
		rename audd start
		
		merge m:1 start using "$dstfmt/disced/n_audd_level_l1l4_k", keep(1 3) nogen
		
		keep if AUDD_LEVEL_L1L4_K == "3"	
		drop start AUDD_LEVEL_L1L4_K 

	* Keep first record, if more than one 	
		
		bysort pnr (karakter_udd_vtil): keep if _n == 1 
	
	* Convert GPA on old scale (13) to new scale (7). Old should always be < 6 (v v few errors)
		
		gen double old = karakter_udd / 10
		replace old = 6.0 if old < 6 & skala == 13 
		
		gen new = .
		do $fmt/grade_convert_13_7
		
		gen gpa = new
		replace gpa = old if skala == 7 
		assert !missing(gpa)		
		replace gpa = 2 if gpa < 2 
	
		drop old new skala karakter_udd
	
	* Save
	
		save $tmp/udg, replace 

	* Merge on teachers 
	
		use $dir/data/teacherlist, clear
		merge 1:1 pnr using $tmp/udg, keep(3)  nogen 
		
	* Construct measure: gpa_high (compared to teachers who graduated high school same year)	
	* Also, since it's a distributional measure (percentile rank) drop if less than 100 in the
	* graduation year 
		
		gen t = year(karakter_udd_vtil)
		bysort t: gen N = _N 
		drop if N < 100
		
		gen gpa_p90 = 0
		gen gpa_p10 = 0
		gen gpa_std = .
		
		su t
		global min = r(min)
		global max = r(max) 
		
		forval t = $min/$max { 
			
			su gpa if t == `t', d
			
			replace gpa_p90 = 1 if gpa >= r(p90) & t == `t' 
			replace gpa_p10 = 1 if gpa <= r(p10) & t == `t' 
			
			zscore gpa if t == `t' 
			replace gpa_std = z_gpa if t == `t' 
			
			drop z_gpa
			
		}

		drop karakter_udd_vtil t N 

		save $tmp/gpa, replace 
	
* ================================================================================================ *
* Teacher College GPA  
* ================================================================================================ *
		
	use $dd100/udg2021, clear
	keep if inlist(audd, 3329, 5440, 5441)
	tostring karakter_udd, gen(x) 
	
	gen double old = karakter_udd / 10
	replace old = 6.0 if old < 6 & skala == 13 
	
	gen new = .
	do $fmt/grade_convert_13_7
	
	gen gpa = new
	replace gpa = old if skala == 7 
	assert !missing(gpa)		
	replace gpa = 2 if gpa < 2 


	drop old new skala karakter_udd
	keep pnr gpa karakter_udd_vtil 
	bysort pnr (gpa): keep if _n == _N  
	
	rename gpa tc_gpa 
	keep pnr tc_gpa karakter_udd_vtil
		
	save $tmp/tc_gpa, replace	
	
	* Merge on teachers 
	use $dir/data/teacherlist, clear
	merge 1:1 pnr using $tmp/tc_gpa, keep(3)  nogen 
	
	* Construct measure: gpa_high (compared to teachers who graduated high school same year)	
	* Also, since it's a distributional measure (percentile rank) drop if less than 100 in the
	* graduation year 
		
	gen t = year(karakter_udd_vtil)
	bysort t: gen N = _N 
	drop if N < 100
	
	gen tc_gpa_p90 = 0
	gen tc_gpa_p10 = 0
	gen tc_gpa_std = .
	
	su t
	global min = r(min)
	global max = r(max) 
	
	forval t = $min/$max { 
		
		su tc_gpa if t == `t', d
		
		replace tc_gpa_p90 = 1 if tc_gpa >= r(p90) & t == `t' 
		replace tc_gpa_p10 = 1 if tc_gpa <= r(p10) & t == `t' 
		
		zscore tc_gpa if t == `t' 
		replace tc_gpa_std = z_tc_gpa if t == `t' 
		
		drop z_tc_gpa
		
	}

	drop karakter_udd_vtil t N 

	save $tmp/tc_gpa, replace 


* ================================================================================================ *
* Teacher quality dataset
* ================================================================================================ *

	use $dir/data/teacherlist, clear
	expand 2019 - 2013 + 1 
	bysort pnr: gen t = 2013 + _n - 1 
	expand 2
	bysort pnr t: gen fag = "dan" if _n == 1
	bysort pnr t: replace fag = "mat" if _n == 2 
	
	merge m:1 pnr t using $tmp/ctfd, keep(1 3) keepus(ctfd) nogen
	replace ctfd = 0 if ctfd == . 
	
	merge m:1 pnr t fag using $tmp/spc, keep(1 3) keepus(spc spceqv) nogen
	assert spc != . & spceqv != . 
	
	merge m:1 pnr t using $tmp/expr, keep(1 3) keepus(expr expr_yrs) nogen
	assert expr != . & expr_yrs != . 
		
	merge m:1 pnr using $tmp/gpa, keep(1 3) keepus(gpa gpa_p90 gpa_p10 gpa_std) nogen
	
	merge m:1 pnr using $tmp/tc_gpa, keep(1 3) keepus(tc_gpa tc_gpa_p90 tc_gpa_p10 tc_gpa_std) nogen
	
	save $dir/data/teacher_qual, replace 
	