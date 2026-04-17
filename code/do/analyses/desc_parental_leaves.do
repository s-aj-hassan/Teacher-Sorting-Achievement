* Distribution of weeks of parental leave for males vs. females in private and public sector in the population^
* X-axis weeks 
* Population all women and men who get a child in year t  (then look at parental leave in t-1 to t+1)
set varabbrev on
global min = 1997
global max = 2018 

forval t = $min/$max {

	use $dd100/dream`t', clear
	keep if pnr != . 
	bysort pnr: assert _N == 1 

	rename y_0* y_*

	ge w = 0
	foreach v of varlist y* {
		replace w = w + 1 if `v' == 881 
	}

	keep if w > 0 
	keep pnr w
	
	ge t = `t'
	
	if `t' > $min append using $tmp/dream
	save $tmp/dream, replace 
	
}
	
glo min = 2000
glo max = 2017 

forval t = $min/$max{ 
	 
	use $dd100/bef`t', clear 
	local r = `t' - 1
	rename foed_dag`t' foed_dag
	keep if year(foed_dag) == `r'
	
	// Drop if not born in Denmark (e.g., Greenland)
	drop if kom`t' > 900
	
	keep pnr mor_id far_id
	keep if !missing(mor_id, far_id)
	
	// Rename 
	rename pnr child
	rename far_id dad
	rename mor_id mom
	
	// Drop twins 
	bysort dad: keep if _n == 1 
	bysort mom: keep if _n == 1 
		
	// Merge parental leave from t-1 to t+1 
	
	foreach par in mom dad { 
		
		// Rename parent id --> pnr 
		rename `par' pnr 
		
		// Locals for t-1 to t+1 
		local tm = `t' - 1
		local tp = `t' + 1
		
		// Macro to define weeks on leave in (t-1, t, t+1) as variables (w1, w2, w3)
		local c 1 
		
		forval j = `tm'/`tp' {
			ge t = `j' 
			merge m:1 pnr t using $tmp/dream, keep(1 3) keepus(w) nogen 
			replace w = 0 if w == .
			rename w w`c' 
			drop t 
			local ++c
		}
		
		// Aggregate weeks on leave in the entire period from t-1 to t+1 in one variable, w 
		ge w = w1 + w2 + w3 
		drop w1 w2 w3
		
		// Rename pnr --> parent id 
		rename pnr `par'
		
		// Indicate mom and dad weeks on leave
		rename w w_`par'
		
		
	}
		
	// Birth year of child variable
	
	ge t = `t'
	// Save 
	if `t' > $min append using $tmp/pop_leaves
	save $tmp/pop_leaves, replace 
	
}

* Construct data with all individuals employed in t - 2 (t = child's birth year)
* I.e., parents who were employed in November the year before their child was born 

global min = 2010
global max = 2017 

forval t = $min/$max { 
	use $dd100/ras`t', clear
	drop if pnr == . 
	keep if primaer_status == 1 
	keep if inrange(soc_status_kode, 110, 136)
	keep pnr
	ge t = `t'
	if `t' > $min append using $tmp/ras
	save $tmp/ras, replace 
}

* Private / Public

global min = 2010
global max = 2017 

forval t = $min/$max { 

	use $dd100/idan`t', clear	
	
	// Keep if pnr and sector non-missing 
	drop if pnr == .
	drop if arb_sek == .  


	// Keep primary job 
	ge prim = typ == "H"
	bysort pnr (prim): keep if _n == _N 

	// Public sector indicator 
	
	ge pub = 0 
	replace pub = 1 if inrange(arb_sek, 11, 16) 
	replace pub = 1 if inrange(arb_sek, 71, 79) 
	replace pub = 1 if inlist(arb_sek, 21, 27, 31, 37, 41, 47, 51, 57, 61) 
	replace pub = . if inlist(, 99, .)
	keep pnr pub
	ge t = `t'
	
	if `t' > $min append using $tmp/idan 
	save $tmp/idan, replace 

}



* Merge employment on data 

use $tmp/pop_leaves, clear
keep if t >= 2013

foreach par in dad mom { 

	rename `par' pnr
	merge 1:1 pnr t using $tmp/ras, keep(1 3) 
	ge emp_`par' = _merge == 3 
	drop _merge 
	
	// Merge public/private sector job

	merge 1:1 pnr t using $tmp/idan, keep(1 3) nogen 
	rename pub pub_`par'
	
	
	// Teachers 
	
	merge m:1 pnr using $dir/data/teacherlist, keep(1 3) 
	ge teacher_`par' = _merge == 3 
	drop _merge 
	
	rename pnr `par'

	
}

save $tmp/pleaves_desc_graphs, replace 

*** DRAW GRAPHS 

** Men vs women in public sector in general 

	use $tmp/pleaves_desc_graphs, clear


	drop if w_mom > 120  // hardly anyone
	drop if w_dad > 120
	
	// Data confidentiality 
	bysort w_dad emp_dad: gen Ndad = _N 
	bysort w_mom emp_mom: gen Nmom = _N 
	
	su w_dad if emp_dad == 1 & pub_dad == 1, d 
	su w_mom if emp_mom == 1 & pub_mom == 1, d

	gr tw 	hist w_dad if emp_dad == 1 & pub_dad == 1 & Ndad > 10, fcol(stc1%70) lcol(stc1%60) w(5) 	///
		|| 	hist w_mom if emp_mom == 1 & pub_mom == 1 & Nmom > 10, fcol(stc2%70)  lcol(stc2%60) w(5)	///
		xtitle("Weeks on parental leave")													///
		xscale(titlegap(3))																	///
		xlab(0(20)120)																		/// 
		ylab(, format(%4.2fc))																///
		yscale(titlegap(3))																	///
		legend(lab(1 "Fathers") lab(2 "Mothers") ring(0) pos(1))
	graph export $dir/output/parental_leave_publicsector.eps, replace 
	
* Teachers 

	use $tmp/pleaves_desc_graphs, clear

	drop if w_mom > 120  // hardly anyone
	drop if w_dad > 120
	
	// Data confidentiality 
	bysort w_dad emp_dad teacher_dad: gen Ndad = _N 
	bysort w_mom emp_mom teacher_mom: gen Nmom = _N 
	
	su w_dad if emp_dad == 1 & pub_dad == 1, d 
	su w_mom if emp_mom == 1 & pub_mom == 1, d 
	
	su w_dad if emp_dad == 1 & pub_dad == 1 & teacher_dad == 1, d   
	su w_mom if emp_mom == 1 & pub_mom == 1 & teacher_mom == 1, d   

	gr tw 	hist w_dad if emp_dad == 1 & pub_dad == 1 & teacher_dad == 1 & Ndad > 10 , fcol(stc1%70) lcol(stc1%60) w(5) 	///
		|| 	hist w_mom if emp_mom == 1 & pub_mom == 1 & teacher_mom == 1 & Nmom > 10, fcol(stc2%70)  lcol(stc2%60) 	w(5) 	///
		xtitle("Weeks on parental leave")													///
		xscale(titlegap(3))																	///
		xlab(0(20)120)																		/// 
		ylab(, format(%4.2fc))																///
		yscale(titlegap(3))																	///
		legend(lab(1 "Fathers") lab(2 "Mothers") ring(0) pos(1))
	graph export $dir/output/parental_leave_teachers.svg, replace

	
* Delete tmp datasets 

	erase $tmp/deleteme.dta
	erase $tmp/dream.dta
	erase $tmp/idan.dta
	erase $tmp/pop_leaves.dta
	erase $tmp/ras.dta 
set varabbrev off