* Check data: Which DREAM codes do men/women normally have 1 year before/after child birth?
* This dofile is not used at all for analyses or data construction - just a sanity check 

*---------------------------------------------------------------------------------------------------
* Find kids born 2010-2018, and their parents
*---------------------------------------------------------------------------------------------------
forval t = 2010/2018 {
	
	use $BEF/bef12_`t', clear 
	keep if year(foed_dag) == `t' 
	keep if !missing(pnr, mor_id, far_id)
	keep pnr mor_id far_id foed_dag 
	gen t = `t' 
	
	if `t' > 2010 append using $tmp/veridream 
	bysort far_id t: keep if _n == 1 
	bysort mor_id : keep if _n == 1 
	save $tmp/veridream, replace 


}

*---------------------------------------------------------------------------------------------------
* Find their parents' dream codes (to find common dream codes before/after birth)
*---------------------------------------------------------------------------------------------------

tempfile dad 
use $tmp/veridream, clear 
keep far_id
rename far_id pnr 
duplicates drop 
save `dad'

use $tmp/veridream, clear 
keep mor_id 
rename mor_id pnr 
duplicates drop 
append using `dad'
duplicates drop
save $tmp/verilist, replace 


forval t = 2008/2020 { 
	
	use $dd100/dream`t', clear 
	merge 1:1 pnr using $tmp/verilist, keep(3) keepus(pnr) nogen 
	egen allmiss = rowmax(y_*)
	drop if allmiss == . 
	keep pnr y_*
	
	forval j = 1/9 { 
		rename y_0`j' y_`j'
	}

	reshape long y_, i(pnr) j(w_dream)
	drop if y_ == . 
	gen t_dream = `t'
	
	rename y_ dreamcode 
	merge m:1 t_dream w_dream using $fmt/dream_weeks_convert, keep(1 3) keepus(dreamweek) nogen
	
	if `t' > 2008 append using $tmp/dreambirth
	save $tmp/dreambirth, replace 
	
}


*---------------------------------------------------------------------------------------------------
* Parents' most common dream codes before/after child birth
*---------------------------------------------------------------------------------------------------
foreach par in mor far { 

	use $tmp/veridream, clear
	keep pnr foed_dag `par'_id 
	rename foed_dag day
	merge m:1 day using $fmt/dream_weeks_convert_alldays, keep(1 3) keepus(dreamweek) nogen
	rename pnr child

	rename `par'_id pnr
	rename dreamweek org 

	* before 
	forval t = 0/100 { 
		
		local j = 500 - `t'
		
		gen dreamweek = org - `t'
		merge m:1 pnr dreamweek using $tmp/dreambirth, keep(1 3) keepus(dreamcode) nogen
		rename dreamcode dream_`j'
		drop dreamweek
			
	}

	* after 
	forval t = 1/100 { 
		
		local j = 500 + `t'
		
		gen dreamweek = org - `t'
		merge m:1 pnr dreamweek using $tmp/dreambirth, keep(1 3) keepus(dreamcode) nogen
		rename dreamcode dream_`j'
		drop dreamweek
			
	}
	reshape long dream_, i(child day pnr org) j(t)
	save $tmp/veridream_`par', replace

}	

*---------------------------------------------------------------------------------------------------
* Graphs for entire period
*---------------------------------------------------------------------------------------------------
global out "$dir/output/documentation/dreamcodes"

foreach par in mor far {
forval M = 0/1 { 
	
	use $tmp/veridream_`par', clear 
	replace t = t - 500
		
	if `M' == 1 drop if dream_ == . 
	bysort t dream_: gen N = _N 
	drop if N < 10
	bysort t dream_: keep if _n == 1 
	replace N = -1 * N
	bysort t (N): gen n = _n
	keep if n < 5 

	rename dream_ dreamcode

	replace dreamcode = 1000 if dreamcode == . 

	gen DC = . 
	replace DC = 1 if dreamcode == 111
	replace DC = 2 if dreamcode == 651
	replace DC = 3 if dreamcode == 730
	replace DC = 4 if dreamcode == 881 
	replace DC = 5 if dreamcode == 997
	replace DC = 6 if dreamcode == 1000 

	label define dc 1 "Dagpenge, ledighed (111)" 2 "SU med ydelse (651)" 3 "Kontanthjælp, passiv (730)" 4 "Barselsdagpenge (881)" 5 "Ikke bosiddende i Danmark (997)" 6 "Missing", replace 
	label value DC dc

	keep if inrange(t, -60, 60)
	
	if "`par'" == "mor" local lbpar "Mothers"
	if "`par'" == "far" local lbpar "Fathers"
	
	if `M' == 1 local lbmis "Missings excl."
	if `M' == 0 local lbmis "Missings incl."
	
	gr tw 	sc DC t if n == 1, mcol(red) msym(s) 						///
		||	sc DC t if n == 2, mcol(blue) msym(s) 						///
		||	sc DC t if n == 3, mcol(black) msym(s)  					///
		xtitle("Weeks relative to child birth")							///
		xlab(-60(20)60) 												///
		ytitle("")														///
		ylab(, valuelabels)												///
		title("`lbpar' (`lbmis')")										///
		legend(lab(1 "Most common code") lab(2 "2nd most common") lab(3 "3rd  most common") pos(6) c(2) region(lcol(black)))
	graph export $out/dream_`par'_miss`M'.png, replace 
}
}



*---------------------------------------------------------------------------------------------------
* Graphs for entire period
*---------------------------------------------------------------------------------------------------

* No differences over time, so no need to export all these figures! 

foreach par in mor far {
forval M = 0/1 { 
	
	use $tmp/veridream_`par', clear 
	replace t = t - 500
		
	if `M' == 1 drop if dream_ == . 
	
	gen y = year(day)
	bysort t t dream_: gen N = _N 
	drop if N < 10
	bysort y t dream_: keep if _n == 1 
	replace N = -1 * N
	bysort y t (N): gen n = _n
	keep if n < 5 

	rename dream_ dreamcode

	replace dreamcode = 1000 if dreamcode == . 

	gen DC = . 
	replace DC = 1 if dreamcode == 111
	replace DC = 2 if dreamcode == 651
	replace DC = 3 if dreamcode == 730
	replace DC = 4 if dreamcode == 881 
	replace DC = 5 if dreamcode == 997
	replace DC = 6 if dreamcode == 1000 

	label define dc 1 "Dagpenge, ledighed (111)" 2 "SU med ydelse (651)" 3 "Kontanthjælp, passiv (730)" 4 "Barselsdagpenge (881)" 5 "Ikke bosiddende i Danmark (997)" 6 "Missing", replace 
	label value DC dc

	keep if inrange(t, -60, 60)
	
	if "`par'" == "mor" local lbpar "Mothers"
	if "`par'" == "far" local lbpar "Fathers"
	
	if `M' == 1 local lbmis "Missings excl."
	if `M' == 0 local lbmis "Missings incl."
	
	su y 
	global min = r(min)
	global max = r(max)
	
	forval Y = $min/$max { 
	
		preserve 
		
			keep if y == `Y'
				
			gr tw 	sc DC t if n == 1, mcol(red) msym(s) 						///
				||	sc DC t if n == 2, mcol(blue) msym(s) 						///
				||	sc DC t if n == 3, mcol(black) msym(s)  					///
				xtitle("Weeks relative to child birth")							///
				xlab(-60(20)60) 												///
				ytitle("")														///
				ylab(, valuelabels)												///
				title("`lbpar' (`lbmis') `Y'")									///
				legend(lab(1 "Most common code") lab(2 "2nd most common") lab(3 "3rd  most common") pos(6) c(2) region(lcol(black)))
			graph export $out/yearly/`Y'_dream_`par'_miss`M'.png, replace 
		
		restore 
		
	}
}
}

* ------------------------------------------------------------------------------------------------ *
* Proportion of mothers who get a kid and go on parental leave (within +/- 10 weeks)
* ------------------------------------------------------------------------------------------------ *


use $tmp/dreambirth, clear 

foreach par in mor far {

	
	use $tmp/veridream_`par', clear 
	replace t = t - 500
	keep if inrange(t, -20, 20)
	
	* Dummy: At least one week at parental leave 
	gen x = dream_ == 881 
	bysort pnr day: egen D_pleave = max(x)
	
	* Count number of weeks on parental leave (in those 21 weeks)
	bysort pnr day: egen C_pleave = total(x)
	
	keep child day pnr D_pleave C_pleave 
	duplicates drop 
	
	* Merge teacher 
	merge m:1 pnr using $dir/data/teacherlist, keep(1 3) keepus(pnr) 
	gen teacher = _merge == 3 
	drop _merge 

	save $tmp/childbirth_pleave_`par', replace 
	
	
}


foreach par in mor far { 
	use $tmp/childbirth_pleave_`par', clear

	gen t = year(day)
	collapse (mean) D_pleave, by(t)
	save $tmp/`par'_agg, replace 

	use $tmp/childbirth_pleave_`par', clear 
	gen t = year(day)
	keep if teacher == 1
	collapse (mean) D_pleave, by(t)
	gen teacher = 1
	append using $tmp/`par'_agg
	replace teacher = 0 if teacher == . 

	save $tmp/`par', replace 
}

use $tmp/mor, clear 
gen mom = 1 
append using $tmp/far 
replace mom = 0 if mom == . 

label define lpl 0 "All" 1 "Teachers", replace 
label value teacher lpl

* Graph for moms
graph bar D_pleave if mom == 1, over(teacher) over(t) asyvars	///
	ytitle("")													///
	ylab(, format(%4.2fc))										///
	b1title("Year of childbirth")								///
	title("	{bf: (a)} Mothers")									///
	name(moms, replace) legend(c(2) region(lcol(black)) pos(6))
	
* Graph for dads
graph bar D_pleave if mom == 0, over(teacher) over(t) asyvars	///
	ytitle("")													///
	ylab(, format(%4.2fc))										///
	b1title("Year of childbirth")								///
	title("	{bf: (b)} Fathers")									///
	name(dads, replace) legend(c(2) region(lcol(black)) pos(6))

grc1leg moms dads, ycommon l1title("Proportion with any parental leave")
graph export $out/dream_childbirth.eps, replace
	
	
*******************************************************************************************************






