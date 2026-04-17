global out "$dir/output"

foreach subject in dan mat { 
	local j 1 
	forval t = 1/8 {

		local tt = `t' + 1 
		local T = 9 
		
		local s 1
		forval k = `tt' / `T' {
			
			if `t' == 1 & inlist(`k', 8, 9) continue 
			if `t' == 2 & `k' == 9 continue
			
			
			local start = 2013 - `t' 
			local end   = 2019 - `k'
			
			di "`t' ... `k' ... `start' - `end'"
			
			use $tmp/teacher_student_`subject', clear 
			gen cohort = t - grade	
				
			* Keep relevant observations (based on cohorts)
					
			keep if inlist(grade, `t', `k')
			keep if inrange(cohort, `start', `end')
		
			keep instnr grade classid t cohort teacher
			duplicates drop

			reshape wide t teacher, i(instnr classid cohort) j(grade)
			

			* Keep classrooms non-missing in all periods (otherwise calculations would contain errors)
			foreach v of varlist t* {
				drop if `v' == . 
			}
						
			* Pr(teacher j != j, from t to t+1)
			ge n_`t'_`k' = teacher`t' != teacher`k'
			collapse (mean) n_`t'_`k'
			ge id = 1 
			
			if `s' > 1 merge 1:1 id using $tmp/hlp, keep(3) nogen 
			save $tmp/hlp, replace 
			
			local ++s
			
		}
		
		if `j' > 1 merge 1:1 id using $tmp/hlp2, keep(3) nogen 
		save $tmp/hlp2, replace 
		
		local ++j
		
	}

	* Merge datasets 
	local j 1 
	forval t = 1/8 { 
		use $tmp/hlp2, clear 
		keep n_`t'_* id
		reshape long n_`t'_, i(id) j(c)
		drop id 
		rename n_`t'_ n_`t'
		if `j' > 1 merge 1:1 c using $tmp/hlp3, keep(1 2 3) nogen 
		save $tmp/hlp3, replace 
		local ++j
	}

	* Set up matrix (correlation like table to plot a heatmap)
	
	local n = _N +1
	set obs `n' 
	replace c = 1 if c == . 
	sort c
	order c n_*, alpha
	drop c 

	* Flip columns (so the y-axis starts at 1 from bottom instead of 9)
	
	gen R = _n
	gsort -R
	mkmat n_*

	mat C = n_1, n_2, n_3, n_4, n_5, n_6, n_7, n_8
	
	clear
	version 16
	
	heatplot C, values(format(%9.2f) mlabsize(medium)) 													///
		color(blue white red)  cuts(-1.05(.1)1.05) 														///
		legend(off) 																					///
		ylab(1 "9" 2 "8" 3 "7" 4 "6" 5 "5" 6 "4" 7 "3" 8 "2" 9 "1", labsize(medlarge) noticks nogrid)	///
		xlab(1 2 3 4 5 6 7 8, labsize(medlarge) noticks nogrid)											///
		ytitle("Grade (to)") xtitle("Grade (from)") 													///
		graphregion(style(none)) plotregion(style(none)) 												///
		yscale(lstyle(none)) xscale(lstyle(none))  														///
		ysize(10) xsize(10)
	graph export "$out/teacher_changes_`subject'.eps", replace 
	
}

* Delete tmp files 

erase $tmp/hlp.dta 
erase $tmp/hlp2.dta 
erase $tmp/hlp3.dta 

version 18