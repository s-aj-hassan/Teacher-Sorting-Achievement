* This dofile finds special educational students. 

global min = 2013
global max = 2018 
forval t = $min/$max { 
	
    
	* Load UDSP data in t																		 
	
		use $dd100/udsp`t', clear 
		
	* Rename all variables to lower case 
	
		foreach v of varlist _all { 
		    
			local x = lower("`v'")
			rename `v' `x'
			
		}
	
	* Drop missing pnrs 
	
		destring pnr, replace force
		drop if pnr == . 
		drop cprtjek cprtype 
		
	* Keep one obs. per student and year 
		keep if year(skl_vfra) == `t'
		bysort pnr (skl_vfra): keep if _n == 1 
	
	* Keep grades 1-9 
	
		rename udel grade 
		keep if inrange(grade, 1, 9)
		drop udd 
	
	* School-year indicator
	
		ge t = `t'
	
	* Dummy "dual_lang" for being "modtagerklasse elev" or "danish as second language" student
		destring dansk_2_sp modt, replace force 
		gen dual_lang = max(dansk_2_sp, modt)
		
	* Dummy for being special education student 
	
		gen spc_ed = 0 
		replace spc_ed = 1 if !inlist(spc_art, "H00", "")
		replace spc_ed = 1 if spc_omfang > 0 & !missing(spc_omfang)
		replace spc_ed = 1 if !missing(spc_start)
		replace spc_ed = 1 if !missing(spc_slut)
		
		keep pnr grade instnr t dual_lang spc_ed
	
	
	* Append earlier years and drop duplicates (i.e., repeat-grade observations kept in last grade)
	
		if `t' > $min append using $tmp/udsp
		
		if `t' == $max { 
		    
			bysort pnr grade (t): keep if _n == _N 
			
		}
	
	* Save 
		
		save $dir/data/udsp, replace 
			
}

