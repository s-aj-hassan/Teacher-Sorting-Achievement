* This dofile cleans the UDFK GPA scores from grade 9 for all schools.

clear all
set more off, perm 

glo sah "Y:\Data\workdata\708177\commondata\udfk"
glo STIL "Y:\Data\workdata\708177\STIL\data"
glo temp $sah\temp 
glo out $sah\output 
glo dd100 "e:\Data\rawdata\708177"
glo fmt "Y:\Data\workdata\708177\templates"
glo dstfmt "\\SRVFSENAS1\data\formater\SAS formater i Danmarks Statistik\STATA_datasaet"

set scheme lean1

* UDFK, 9TH GRADE 

	use $dd100/udfk2021, clear
	ta skoleaar
	
	ge t = real(substr(skoleaar, 1, 4))
	
	* keep danish (oral, spelling, essay), math (written), english (oral), science (oral) 
	
	keep if (grundskolefag == 3  & inlist(fagdisciplin, 4, 6, 7)) 				///
		|	(grundskolefag == 4 & fagdisciplin == 4)							/// 
		|	(inlist(grundskolefag, 7, 39) & inlist(fagdisciplin, 8, 9))			///
		| 	(grundskolefag == 13 & inlist(fagdisciplin, 7, 10, 11))
		
	* Now, for math fagdisciplin should only be 10 or 11 after 2006/7 (uden og med hjælpemidler)
	
		drop if grundskolefag == 13 & fagdisciplin == 7 & t >= 2006 
	
	* Keep grade 9 
	
		keep if kltrin == "09"
	
	* Keep final examinations only 
		
		keep if inlist(proeveform, 2, 5)
		  
	* Keep relevant variables
	
		keep pnr fagdisciplin grundskolefag grundskolekarakter instnr t
		order instnr t pnr grundskolefag fagdisciplin 
	
	* Drop missing pnrs (0.00%)
		
		drop if pnr == . 
		
	* Drop duplicates 
	
		duplicates drop
		
		// Keep first year individual takes test
		bysort pnr: egen min = min(t)
		keep if t == min
		drop min 
		
		// If more than one school by individual, keep the one with most tests 
		// If same number of tests then just keep one of them 
		bysort pnr instnr: ge n_school = _n == 1 
		bysort pnr (instnr): replace n_school = sum(n_school)
		
		ge x = grundskolekarakter != . 
		bysort pnr n_school: egen n_grades = total(x)
		drop x 
		
		bysort pnr: egen max = max(n_grades)
		keep if n_grades == max 
		keep if n_school == 1
		drop n_school n_grades  max 
		
		// Sometimes same subject recorded twice ... keep the one with highest grade 
		replace grundskolekarakter = -999 if grundskolekarakter == .
		bysort pnr t grundskolefag fagdisciplin (grundskolekarakter): keep if _n == _N
		replace grundskolekarakter = . if grundskolekarakter == -999
		
	* Generate subject grades
		
		// Science, oral 
		ge x =  grundskolekarakter if inlist(grundskolefag, 7, 39) & fagdisciplin == 8 
		bysort pnr: egen science = max(x)
		drop x 
		
		// Danish
		
		ge x = grundskolekarakter if grundskolefag == 3 & fagdisciplin == 4 
		bysort pnr: egen danish_oral = max(x)
		
		ge xx = grundskolekarakter if grundskolefag == 3 & fagdisciplin == 6
		bysort pnr: egen danish_spell = max(xx)
		
		ge xxx = grundskolekarakter if grundskolefag == 3 & fagdisciplin == 7
		bysort pnr: egen danish_essay = max(xxx)
		
		drop x xx xxx
		
		gen danish = (danish_oral * 0.5) + (danish_spell * 0.25) + (danish_essay * 0.25)
		
		gen danish_written = (danish_spell * 0.5) + (danish_essay * 0.5)
		
		// English
		
		ge x = grundskolekarakter if grundskolefag == 4 & fagdisciplin == 4 
		bysort pnr: egen english = max(x)
		drop x 
	
		// Math
		
		ge x1 = grundskolekarakter if grundskolefag == 13 & fagdisciplin == 10 & t >= 2006
		ge x2 = grundskolekarakter if grundskolefag == 13 & fagdisciplin == 11 & t >= 2006
		
		bysort pnr: egen max1 = max(x1)
		bysort pnr: egen max2 = max(x2)
		
		ge math = (max1 + max2) / 2 
				
		ge x = grundskolekarakter if grundskolefag == 13 & fagdisciplin == 7 & t < 2006 
		bysort pnr: egen max = max(x)
		replace math = max if t < 2006 
		
		drop x x1 x2 max max1 max2
		
	* Keep one observation per individual 
	
		keep instnr t pnr danish danish_oral danish_written english math science 
		duplicates drop 
		bysort pnr: assert _N == 1 
	
	* Calculate average
	* Missing if all marks missing - if one mark missing then average of those marks 
	
		egen gpa = rowmean(science danish english math)
		egen gpa_written = rowmean(danish_written math)
		
	* Standardize 
	
		foreach v in science danish danish_written danish_oral english math gpa gpa_written { 
			
			bysort t: egen m = mean(`v')
			bysort t: egen s = sd(`v')
			gen `v'_std = (`v' - m) / s
			drop m s 
			
		}
	
	
	* Save data 
		
		save $sah/data/udfk_all_grade9, replace 