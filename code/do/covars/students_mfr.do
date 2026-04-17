****************************************************************************************************
*
* STUDENT COVARIATES: BIRTH CHARACTERISTICS FROM FMR 
*
**************************************************************************************************** 

* Macros 

	global min = 1997
	global max = 2018 
	
* Append MFR datasets 1997 to latest 

	forval t = $min/$max {
		
		use $dd100/mfr`t', clear
		
		rename (cpr_barn apgarscore_efter5minutter vaegt_barn) (k_bcpr v_apgar5 v_vagt)
		keep k_bcpr v_apgar5 v_vagt
		destring k_bcpr v_apgar5, replace force
		
		drop if k_bcpr == . 
		
		if `t' > $min append using $tmp/mfr
		duplicates drop
		save $tmp/mfr, replace 
		
	}

* Append on pre-1997 MFR data 

	use $dd100/lprmfrlf1996, clear 

	keep k_bcpr v_apgar5 v_vagt
	destring k_bcpr, replace force
	drop if k_bcpr == . 

	append using $tmp/mfr
	duplicates drop

	rename (k_bcpr v_apgar5 v_vagt) (pnr apgar bweight)

	isid pnr
	save $tmp/mfr, replace 

* Merge on original data, set missings to 0 
 
	
	use $dir/data/studentlist, clear 
	merge 1:1 pnr using $tmp/mfr, keep(1 3) nogen
	

* Construct variables 

	foreach v in apgar bweight { 
		
		gen miss_`v' = `v' == . 
		replace `v'  = 0 if `v' == .
		
	}

	gen lowapgar	= apgar   != 10  & miss_apgar   == 0 
	gen lowbweight 	= bweight < 2500 & miss_bweight == 0 

* Save data 

	label var pnr 			"Person ID"
	label var apgar			"APGAR score"
	label var bweight		"Birth weight (grams)"
	label var lowapgar  	"APGAR < 10"
	label var lowbweight	"Birth weight < 2500g"
	label var miss_apgar	"APGAR score missing"
	label var miss_bweight	"Birth weight missing"

	label data "Birth characteristics from MFR"

	save $tmp/students_mfr, replace 	
