* ================================================================================================ *
*
* This dofile codes parental leave spells. Weeks on parental leave in school year t 
* 
* COMMENTS 
* A school year normally goes from around 10 august to 20 june
* Here, I count: from week 31 in t, to week 30 in t+1
* "t = 2013"  is the school year "2013/2014", i.e. "2013 w31" to "2014 w30"
* "t = 2014"  is the school year "2014/2015", i.e. "2014 w31" to "2015 w30"
* and so on...
* I exclude from the measure the summer break.
*
* ================================================================================================ *

** ADD PL_WEEKS VAR AND CHECK CODE
global min = 2009
global max = 2020

forval t = $min/$max { 
	
		use $dd100/dream`t', clear
		
		keep pnr y_*
		forval j = 1/9 { 
			rename y_0`j' y_`j'
		}
		
		* To reduce computing time (reshape) keep teachers
		merge 1:m pnr using $dir/data/teacherlist, keep(3) keepus(pnr) nogen 
		duplicates drop 
		
		* To reduce computing time (reshape) keep if relevant (i.e. had some leave in this year)
		gen rel = 0 
		foreach w of varlist y_* { 
			replace rel = 1 if `w' == 881
		}
		keep if rel == 1 
		drop rel
		
		* Now reshape 
		reshape long y_, i(pnr) j(w)
		gen leave = y_ == 881
		drop y_
		
		gen t = `t'
		
		if `t' > $min append using $tmp/barsel
		save $tmp/barsel, replace
		
}

* Adjust school-years

	use $tmp/barsel, clear
	keep if leave == 1 
	keep pnr w t 	
	replace t = t-1 if w < 31 
	
	bysort pnr t: gen pl_weeks = _N
	assert pl_weeks < 54
	bysort t: egen weeks_in_t = max(w)
	
	gen leave = (pl_weeks/weeks_in_t) >= .5
	keep pnr t leave pl_weeks 
	duplicates drop
	bysort pnr t: assert _N == 1 
	
	save $tmp/barsel, replace 
	
* Merge on teacher data 

	use $dir/data/teacherlist, clear
	keep pnr
	duplicates drop
	expand 2019 - 2010 + 1 
	bysort pnr: gen t = 2010 + _n - 1 
	merge 1:1 pnr t using $tmp/barsel, keep(1 3) keepus(leave pl_weeks) nogen
	replace leave = 0 if leave == .
	replace pl_weeks = 0 if pl_weeks == .
	
	save $dir/data/Z_pleave, replace 
	
	
	
	


