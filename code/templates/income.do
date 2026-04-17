* Finds and deflates income variables from income register (IND)

** Remember to run fpi and PPP macros first (in templates folder)
** And set global tt to t-1 in the dofile you're using - not here!
* Also set fpi and PPP references macros in your own dofile not here 
* e.g., global fpiref = fpi2018, global PPP2018


	local overf "overforsindk"
	local skatmv "skatmvialt_ny"
	local dispon "dispon_ny"
	if $tt >= 2014 local skatmv "skatmvialt"
	if $tt >= 1987 local overf  "off_overforsel_13"
	if $tt >= 1987 local dispon "dispon_13"
	
	local income "perindkialt loenmv `overf' skatfriyd `skatmv' `dispon'"

	preserve 
		
		tempfile IND 
		use $dd100/ind$tt, clear 
		keep pnr `income'
		egen tot = rowtotal(`income')
		assert tot != . 
		bysort pnr (tot): keep if _n == _N 
		drop tot 
		save `IND'
		
	restore 			
		
	merge m:1 pnr using `IND', keep(1 3) nogen 

* Deflate according to FPI, then PPP-adjust to 2018 dollars 

	local f "fpi$tt"

	foreach v in `income' {
		
		replace `v' = (`v' / ( $`f' / $fpiref ) ) / ( $PPPref )
		
	}

* Income vars 

	ge inc_gross	 	= perindkialt
	ge inc_wage			= loenmv
	ge inc_transfer		= `overf' + skatfriyd
	ge inc_net 			= perindkialt - `skatmv'
	ge inc_disp 		= `dispon'

* Indicate missings and set to 0

	ge inc_miss = inc_gross == . 
	
	foreach v in gross wage transfer net disp {
		
		replace inc_`v' = 0 if inc_miss == 1
	}

	drop `income'

	
