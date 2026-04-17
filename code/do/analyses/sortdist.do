use $tmp/teacher_student_dan, clear
append using $tmp/teacher_student_mat

* Merge teacher vars 
	rename pnr child
	rename teacher pnr
	merge m:1 pnr t fag using $dir/data/teacher_qual, keep(1 3) nogen
	rename pnr teacher 
	rename child pnr 
	
	collapse (mean) ctfd gpa tc_gpa spceqv (count) N = pnr, by(instnr t)
	drop if N < 10 // for confidentiality
	
	merge m:1 instnr t using $dir/data/school_vars, keep(1 3) nogen
	
* Draw graphs 

	global out "$dir/output"

	gr tw kdensity tc_gpa if ses_high == 1, 						///
		|| kdensity tc_gpa if ses_high == 0, 						///
		xtitle("Teacher college GPA")								///
		ytitle("Kernel density")									///
		ylab(0(.1).4, format(%4.2fc))								///
		legend(order(1 "High-SES" 2 "Low-SES ")						///
			pos(11) ring(0) bmargin(medlarge) region(col(none)))	///
		ysize(5) xsize(5) note({bf:(a)}, pos(11) ring(0))											
	graph export $out/sortdist_tcgpa.eps, replace
	
	binscatter spceqv ses, line(none)								///
		msym(O) mcol(black)											///
		ytitle("Proportion specialized teachers")					///
		ylab(.9(.01).96, format(%4.2fc))							///
		xtitle("School SES")										///
		xlab(, format(%4.2fc))										///
		ysize(5) xsize(5) note({bf:(b)}, pos(11) ring(0))						
	graph export $out/sortdist_spc.eps, replace
		
