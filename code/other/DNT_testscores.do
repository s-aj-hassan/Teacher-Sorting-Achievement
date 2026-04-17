* This dofile cleans the Danish National Test scores.
clear all
set more off, perm 

glo sah "Y:\Data\workdata\708177\commondata\dnt"
glo STIL "Y:\Data\workdata\708177\STIL\data"
glo temp $sah\temp 
glo out $sah\output 
glo dd100 "E:\Data\rawdata\708177"
glo fmt "Y:\Data\workdata\708177\templates"
glo dstfmt "\\SRVFSENAS1\data\formater\SAS formater i Danmarks Statistik\STATA_datasaet"

set scheme lean1

* DNT test scores - clean 

	use $STIL/dnt_1120, clear 
	
	keep if testtype == "obligatorisk"
	drop testtype 
	
	keep pnr instnr skoleaar fagid klassetrin testtid theta_* 
	
	tab fagid
	
	* Drop incomplete and trial data - English (grade 4 and 7) and Math in grade 8 
	drop if inlist(fagid, "0604", "0607", "0208")
	
	* Keep public schools only 
	merge m:1 instnr using $dd100/inst2019, keep(3) keepus(INST3) nogen
	keep if INST3 == 1012
	drop INST3 
	
	* Tests on time?
	ta klassetrin if fagid == "0102"
	ta klassetrin if fagid == "0104"
	ta klassetrin if fagid == "0106"
	ta klassetrin if fagid == "0108"
	ta klassetrin if fagid == "0203"
	ta klassetrin if fagid == "0206"
		
	** Only keep tests on time (impute with on time grade, if missing grade)
	
	foreach k in 0102 0104 0106 0108 0203 0206 {
		
		local j = substr("`k'", 4, 1)
		replace klassetrin = `j' if klassetrin == . & fagid == "`k'"
		drop if fagid == "`k'" & klassetrin != `j'
		
	}
	
	* Very few tests in 2019/2020 - drop those (COVID) 
	ge t = real(substr(skoleaar), 1, 4)
	ta t 
	drop if t == 2019
	drop skoleaar
	
	* Drop if more than one test by pnr, keep first 
	ge y = real(substr(testtid), 1, 4)
	ge m = real(substr(testtid), 6, 2)
	ge d = real(substr(testtid), 9, 2)
	tab1 y m d
	
	ge date = mdy(m, d, y)
	format date %td
	drop y m d

	ge time = substr(testtid, 12, 5)
	drop testtid
	
	bysort pnr fagid klassetrin (date): keep if _n == 1
	isid pnr fagid
	
	*** STANDARDIZE
	
	forval j = 1/3 {
		
		bysort t fagid: egen M = mean(theta_p`j')
		bysort t fagid: egen S = sd(theta_p`j')
		ge z`j' = (theta_p`j' - M) / S
		drop M S
		
	}

	ge zsum = z1 + z2 + z3
	
	bysort t fagid: egen M = mean(zsum)
	bysort t fagid: egen S = sd(zsum)
	
	ge zscore = (zsum - M) / S
	
	* Keep relevant variables and save 
	keep pnr instnr fagid klassetrin z1 z2 z3 zscore date time t
	order pnr instnr fagid klassetrin z1 z2 z3 zscore date time t
	sort pnr klassetrin t fagid 
	
	isid pnr fagid
	
	destring pnr instnr, replace force
	
	rename klassetrin grade
	
	* Drop missing pnrs 
	drop if pnr == . 
	isid pnr fagid 
	save $sah/data/DNT_testscores, replace