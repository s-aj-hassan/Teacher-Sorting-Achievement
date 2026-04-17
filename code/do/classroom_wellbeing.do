****************************************************************************************************

* Classroom level variables: well-being data 

	* CODES
	* (0 = always means that the student didn't want to respond)
	*
	* GRADES 0 -- 3
	*	1 is always the worst (less well being), and 3 the best (most well being)
	*
	*	q2: 	er du glad for din klasse?									
	*				1 = no 
	*				2 = yes, a bit 
	*				3 = yes, a lot
	*
	*	q9: 	kan du koncentrere dig i timerne? 							
	*				1 = no
	*				2 = yes, some times
	*				3 = yes, most times 
	*
	*	q13:	er der nogen, der driller dig, så du bliver ked af det? 	
	*				1 = yes, a lot
	*				2 = yes, a bit
	*				3 = no
	*
	* 	q16:	er timerne kedelige?
	*				1 = yes, a lot
	*				2 = yes, a bit
	*				3 = no	
	*
	*	q18:	er det svært at høre, hvad læreren siger i timerne?
	*				1 = yes, often
	*				2 = yes, some times
	*				3 = no
	*
	* 	q19:	er jeres klasselokale rart at være i?
	*				1 = no 
	*				2 = yes, a bit
	*				3 = yes, a lot
	
	* GRADES 4 -- 9 
	*	1 is always the worse (less well being), and 5 the best (most well being)
	*				
	*	q2:		er du glad for din klasse?
	*				1 = never
	*				2 = rarely
	*				3 = sometimes
	*				4 = often 
	* 				5 = very often 
	*
	*	q8:		kan du koncentrere dig i timerne?
	*				1 = never
	*				2 = rarely
	*				3 = sometimes
	*				4 = often 
	* 				5 = very often 
	*
	* 	q14: 	er du blevet mobbet i dette skoleår?
	*				1 = very often
	*				2 = often
	*				3 = sometimes
	*				4 = rarely
	*				5 = never 
	*
	* 	q19:	er undervisningen kedelig?
	*				1 = very often
	*				2 = often
	*				3 = sometimes
	*				4 = rarely
	*				5 = never 
	*
	* 	q24:	er det let at høre, hvad læreren siger i timerne?
	*				1 = never
	*				2 = rarely
	*				3 = sometimes
	*				4 = often 
	* 				5 = very often 
	*
	* 	q39:	jeg synes godt om undervisningslokalerne på skolen
	*				1 = disagree strongly
	*				2 = disagree 
	*				3 = neither disagrees nor agrees
	*				4 = agree
	*				5 = agree strongly

	
	

****************************************************************************************************

* Clean 0 - 3 well-being data 
* Because students may have a missing in one question but not another, I do this one variable 
* at a time 

	use $STIL/data/samlet_kl_0_3_2015_20, clear
	destring pnr, replace force
	drop if pnr == . 
	ge t = real(substr(skoleaar, 1, 4))
	
	// Keep public schools 
	ge instnr = string(institutionsnummer)
	merge m:1 instnr using $dd100/inst2019, keep(3) keepus(INST3) nogen
	keep if INST3 == 1012
	drop INST3 
	destring instnr, replace force
	
	// Keep relevant variables
	keep pnr t instnr klassetrin klassebetegnelse q2 q9 q13 q16 q18 q19 

	foreach v of varlist q* {
		
		replace `v' = . if `v' == 0
		
	}
	
	rename q2 happy_classroom
	rename q9 concentrate
	rename q13 bullied
	rename q16 boring
	rename q18 disturb
	rename q19 nice_classroom
	
	tempfile grade03
	save `grade03'
	
	
// CLEAN GRADES 4 - 9 
	
	use $STIL/data/samlet_kl_4_9_2015_20, clear
	destring pnr, replace force
	drop if pnr == . 
	ge t = real(substr(skoleaar, 1, 4))
	
	// Keep public schools 
	ge instnr = string(institutionsnummer)
	merge m:1 instnr using $dd100/inst2019, keep(3) keepus(INST3) nogen
	keep if INST3 == 1012
	drop INST3 
	destring instnr, replace force
	
	// Keep relevant variables
	keep pnr t instnr klassetrin klassebetegnelse q2 q8 q14 q19 q24 q39

	foreach v of varlist q* {
		
		// Make it more like the 0-3 grade variables, i.e. 3 categories
		gen x = .
		replace x = 1 if inlist(`v', 1, 2)
		replace x = 2 if `v' == 3
		replace x = 3 if inlist(`v', 4, 5)
		
		drop `v'
		rename x `v'
		
	}
	
	rename q2 	happy_classroom
	rename q8 	concentrate
	rename q14 	bullied
	rename q19	boring
	rename q24	disturb
	rename q39	nice_classroom
	
	append using `grade03'

	
	// Get classid from teacher_student data 
	
	drop klassebetegnelse
	rename klassetrin grade
	drop if grade == 0 
	
	tostring instnr, replace force 
	gen fag = "dan"
	merge m:1 pnr instnr fag grade t using $tmp/teacher_student_dan, keep(1 3) keepus(classid) nogen
	rename classid classid_dan
	
	replace fag = "mat"
	merge m:1 pnr instnr fag grade t using $tmp/teacher_student_mat, keep(1 3) keepus(classid) nogen
	rename classid classid_mat

	gen x = classid_dan == classid_mat & !missing(classid_dan, classid_mat)		
	assert x == 1 if !missing(classid_dan, classid_mat)
	drop x 
	
	gen classid = classid_dan
	replace classid = classid_mat if classid == ""
	
	drop fag classid_dan classid_mat
	
	* Drop small classes and missings
	drop if missing(classid)
	
	bysort instnr t grade classid: ge N = _N 
	keep if inrange(N, 10, 35)
	
	* Well-being index (of the variables above), by grade-year 
	* just for the index - set missings to 1 (i.e. worse!)
		
	global items "happy_classroom concentrate bullied boring disturb nice_classroom"
	foreach i in $items { 
		
		gen i_`i' = `i' 
		replace i_`i' = 1 if i_`i' == . 
		
	}
	
	egen gradeyear = group(grade t)
	su gradeyear 
	global min = r(min)
	global max = r(max)	
	
	gen wellbeing_index = . 
	
	forval j = $min/$max { 
		
		pca i_* if gradeyear == `j'
		predict x if gradeyear == `j'
		replace wellbeing_index = x if gradeyear == `j'
		drop x 
	}

	drop i_* gradeyear 	
		
	foreach v in happy_classroom concentrate bullied boring disturb nice_classroom wellbeing_index { 
		
		bysort instnr t grade classid: egen m = mean(`v')
		drop `v'
		rename m `v'

		
	}

	keep instnr t grade classid happy_classroom concentrate bullied boring disturb nice_classroom wellbeing_index
	duplicates drop 
	
	* Now standardize variables by grade year 
	
	foreach v in happy_classroom concentrate bullied boring disturb nice_classroom { 
		
		bysort t grade: egen m = mean(`v')
		bysort t grade: egen s = sd(`v')
		gen z = (`v' - m) / s
		drop `v'
		rename z `v'
		
		drop m s
		
	}
		
	save $dir/data/classroom_wellbeing, replace
