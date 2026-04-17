* Parental leave spells 

global min = 2010 
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

	use $tmp/barsel, clear 
	rename (t w) (t_dream w_dream)
		
	merge m:1 t_dream w_dream using $fmt/dream_weeks_convert, keep(1 3) keepus(s e) nogen
	
	sort pnr s
	order pnr t_dream w_dream s e 
	
	bysort pnr (s): gen spell = leave != leave[_n-1]
	bysort pnr (s): replace spell = sum(spell)
	
	collapse (max) leave e (min) s, by(pnr spell) 
 
	keep if leave == 1 
	drop leave spell
	
	order pnr s e 
	duplicates drop 
	bysort pnr (s): gen spell = _n
	reshape wide s e, i(pnr) j(spell)

	save $dir/data/Z_pleave_spells, replace 
