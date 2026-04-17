* Finds employment codes in RAS

// DEFINE MACROS IN USED DOFILE, NOT HERE
*local tt = `t' - 1 

if $tt < 1994 					local rascode "arbstil"
if inrange($tt, 1994, 1995)		local rascode "nyarb"
if inrange($tt, 1996, 2007)		local rascode "socstil"
if $tt > 2007 					local rascode "soc_status_kode"

								local nov "novprio"
if $tt > 2007					local nov "primaer_status_kode"

preserve 
	tempfile ras 
	use $dd100/ras$tt, clear
	drop if pnr == . 
	drop if `rascode' == .
	if $tt > 1989 keep if `nov' == 1 
	bysort pnr: keep if _n == 1 
	save `ras'
restore

if $tt < 1994 {
    
	// Merge from RAS 
	
		merge m:1 pnr using `ras', keep(1 3) keepus(`rascode') nogen 
		
	// Conventional empoyment codes
	
		ge emp			= inrange(`rascode', 11, 37)
		ge ump			= `rascode' == 40 
		ge nlf			= inrange(`rascode', 50, 92)
	
}

if inrange($tt, 1994, 1995) {
    
	
	// Merge from RAS 
		
		merge m:1 pnr using `ras', keep(1 3) keepus(`rascode') nogen 
		
	// Conventional empoyment codes
	
		ge emp 		= inrange(`rascode', 11, 37) 
		ge ump 		= `rascode' == 40
		ge nlf 		= inrange(`rascode', 310, 400)
	
}

if inrange($tt, 1996, 2007) {
    
	// Merge from RAS 
	
		merge m:1 pnr using `ras', keep(1 3) keepus(`rascode') nogen 
		
	// Conventional empoyment codes
	
		ge emp 		= inrange(`rascode', 115, 135) 
		ge ump 		= `rascode' == 200
		ge nlf	 	= inrange(`rascode', 310, 400) 
	
}

if $tt > 2007 {
    
	// Merge from RAS 
	
		merge m:1 pnr using `ras', keep(1 3) keepus(`rascode') nogen 
		
	// Conventional empoyment codes
	
		ge emp		= inrange(`rascode', 110, 136)
		ge ump 		= `rascode' == 200 
		ge nlf 		= inrange(`rascode', 300, 612) 
	
}


* Set missings to 0 

	foreach v in ump emp nlf {
	    
		replace `v' = . if `rascode' == . | (emp + ump + nlf == 0)
		
	}
	
	ge emp_miss = emp == . 
	
	foreach v in ump emp nlf {
	    
		replace `v' = 0 if `v' == . 
		
	}

drop `rascode'
















