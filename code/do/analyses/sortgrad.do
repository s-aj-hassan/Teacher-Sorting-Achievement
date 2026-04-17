* Macros

	tempfile ctfd GPA SES
	
* Keep teachers graduating in 2013-2018 (All available STIL years)

	use $dir/data/ctfd_dates, clear
	
	gen t = year(date_ctfd) if month(date_ctfd) <= 9 
	replace t = year(date_ctfd) + 1 if month(date_ctfd) > 9 

	keep if inrange(t, 2013, 2018)
	
	rename t t_ctfd
	keep pnr t_ctfd 
	isid pnr
	
	// Add teacher HS GPA 
	
	merge 1:1 pnr using $tmp/udg, keep(1 3) keepus(gpa) nogen
	rename gpa HS_GPA
	
	gen HS_GPA_qnt =  .
	
	su t_ctfd
	
	local min = r(min)
	local max = r(max)
	
	forval t = `min' / `max' { 
		
		xtile x = HS_GPA if t_ctfd == `t', nq(5)
		replace HS_GPA_qnt = x if t_ctfd == `t'
		drop x 
		
	}
	
	* --------------------------------------------------------------------------------------------
	
	// Add teacher college GPA 
	
	merge 1:1 pnr using $tmp/tc_gpa, keep(1 3) nogen

	rename tc_gpa TC_GPA
		
	gen TC_GPA_qnt =  .
	
	su t_ctfd
	
	local min = r(min)
	local max = r(max)
	
	forval t = `min' / `max' { 
		
		xtile x = TC_GPA if t_ctfd == `t', nq(5)
		replace TC_GPA_qnt = x if t_ctfd == `t'
		drop x 
		
	}
	
	* --------------------------------------------------------------------------------------------
	
	// Add teacher SES: mom education 
	
	merge m:1 pnr using $dir/data/teachers_covars, keep(1 3) nogen
	
	save $tmp/sortgrad, replace

* Find first school 

	use $STIL/data/kompetencedaekning2014_20, clear 
	
	gen t = real(substr(skoleaar, 1, 4))
	bysort pnr (t): keep if _n == 1 
	
	rename institutionsnummer instnr 
	rename t t_emp 
	
	keep pnr instnr t_emp
	destring pnr, replace force 
	
	merge 1:1 pnr using $tmp/sortgrad, keep(1 3) nogen
	
	drop if t_ctfd == . 
	
* Now we want school characteristics in t_emp - 1 (i.e. how was the school one year before their emp)

	rename t_emp t
	replace t = t-1
	
	tostring instnr, replace force
	merge m:1 instnr t using $dir/data/school_vars, keep(1 3) nogen
	merge m:1 instnr t using $dir/data/school_gpa, keep(1 3) nogen 
	
	ta TC_GPA							
	bysort TC_GPA: ge N = _N 
	drop if N < 5 // for confidentiality 
		
	label var TC_GPA 		"Teacher College GPA"
	label var TC_GPA_qnt 	"Teacher College GPA (quantile)"
	label var HS_GPA  		"Teacher's high school GPA"
	label var HS_GPA_qnt	"Teacher's high school GPA (quantile)"
	label var T_mom_educ15	"Teacher's maternal education"
	label var T_dad_educ15	"Teacher's paternal education"
	label var T_ses 		"Teacher SES"
	
	label var GPA			"School GPA"
	label var GPA_qnt		"School GPA (quantile)"
	label var daduni		"School share university-educated fathers"
	label var momuni		"School share university-educated mothers"
	label var nonwest		"School share nonwestern immigrants"
	label var dadinc		"School avg. paternal income ('000 $)"
	label var dadinc_qnt	"School paternal income (quantile)"
	label var mominc		"School avg. maternal income ('000 $)"
	label var mominc_qnt	"School maternal income (quantile)"	
	label var ses 			"School SES"
	
	
	* Selected graphs for paper 
	global out "$dir/output"

		// Teacher SES vs School SES

		binscatter ses T_ses, line(none)										///
			mcol(black) msym(O)													///
			xtitle("Teacher SES ({it:t})") 										///
			ytitle("School SES ({it:t}-1)")										///
				ylab(, angle(hor) format(%4.2fc))								///
			ysize(5) xsize(5) note({bf:(a)}, pos(11) ring(0))							
		graph export "$out/sortgrad_ses.eps", replace
		
		
		// Teacher GPA vs School gpa 
		
		binscatter GPA TC_GPA, line(none)										///
			mcol(black) msym(O)			 										///
			xtitle("Teacher GPA ({it:t})") 										///
			ytitle("School GPA ({it:t}-1)")										///
				ylab(6.7(.1)7.1, angle(hor) format(%4.2fc))						///
			ysize(5) xsize(5) note({bf:(b)}, pos(11) ring(0))							
		graph export "$out/sortgrad_gpa.eps", replace


		
	
	
	
	