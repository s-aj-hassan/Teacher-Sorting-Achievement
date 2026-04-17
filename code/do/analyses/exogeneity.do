* This dofile regresses probability of teacher changes due to parental leave on classroom vars 

* Construct a panel with teachers
* Look at their average classroom characteristics in t
 
use $tmp/teacher_student_dan, clear 
append using $tmp/teacher_student_mat 
bysort instnr grade t classid: gen class_size = _N / 2 
keep if inrange(class_size, 10, 35)
keep instnr grade t classid teacher class_size
duplicates drop
drop if classid == ""

drop if t == 2013 // no wellbeing data 
drop if t == 2019 // covid

// Make sure every teacher is only in one school per year 
sort teacher t instnr
by teacher t: gen unique = cond(_N == 1, 1, instnr != instnr[_n-1])
by teacher t: egen num_unique = total(unique) 
keep if num_unique == 1 
drop unique num_unique

// Merge classroom variables (in t)
 
merge m:1 instnr t classid using $dir/data/classroom_wellbeing, keep(1 3) nogen
merge m:1 instnr t classid using $dir/data/classroom_vars, keep(1 3) nogen
merge m:1 instnr t classid using $dir/data/classroom_DNT_dan, keep(1 3) nogen
  
// One obs. per teacher ==> Average classroom variable for teacher

local vars "wellbeing_index happy_classroom concentrate bullied boring disturb nice_classroom nonwest female ses class_size zscore" 
collapse (mean) `vars' (first) instnr, by(teacher t)

// Now merge teacher's parental leave in subsequence years (t+1, t+2)

rename teacher pnr

rename t t0

forval s = 1/2 {
	
	gen t = t0 + `s'
		 
	merge m:1 pnr t using $dir/data/Z_pleave, keep(1 3) keepus(leave pl_weeks) nogen
	replace pl_weeks = 0 if pl_weeks == . 
	replace leave = 0 if leave == . 
	
	rename (leave pl_weeks) (leave`s' pl_weeks`s')
	
	drop t 
}

rename t0 t 

// Actual teacher (in t)
merge m:1 pnr using $dir/data/teachers_covars, keep(1 3) keepus(T_bdate T_female T_nonwest) nogen
drop if T_bdate == . 
gen T_age = ((mdy(8,1,t-1)-T_bdate)/365)
drop T_bdate 

rename pnr teacher

* Age group dummies 
gen T_ag_18_30 = T_age >= 18 & T_age < 31 & !missing(T_age)
gen T_ag_31_40 = T_age >= 31 & T_age < 41 & !missing(T_age)
gen T_ag_41_50 = T_age >= 41 & T_age < 51 & !missing(T_age)
gen T_ag_51_60 = T_age >= 51 & T_age < 61 & !missing(T_age)
gen T_ag_61_90 = T_age >= 61 & T_age < 9999 & !missing(T_age)		


* Standardize to make comparable 
global W "happy_classroom concentrate bullied boring disturb nice_classroom wellbeing_index ses class_size female nonwest zscore"

foreach w in $W { 
	bysort t: egen M = mean(`w')
	bysort t: egen S = sd(`w')
	gen z = (`w' - M) / S
	drop M S `w'
	rename z `w'
} 


save $tmp/exog_graphdata, replace


* ESTIMATE MODELS 

use $tmp/exog_graphdata, clear
 
forval s = 1/2 {	
		
	local j 1 
	foreach w in $W {
		
		reg leave`s' `w' T_ag* T_female i.t
			* for figure
			mat a = r(table)' 
			mat b = a[1,1], a[1,5], a[1,6], `s'
			mat rownames b = `w'
			
			* for table
			mat c = a[1,1], a[1,2], a[1,4], e(r2), e(N), `s'
			mat rownames c = `w'
			
			
			* for table 
			if `j' == 1 mat A`s' = b 
			else 		mat A`s' = A`s' \ b
			
			* for figure 
			if `j' == 1 mat B`s' = c 
			else		mat B`s' = B`s' \ c 
					
			local ++j
			
	}
}	

mat A = A1 \ A2
mat B = B1 \ B2 

* Draw graph

	clear 
	svmat2 A, rnames(names)
	rename (A1 A2 A3 A4) (b ll ul lag)

	bysort lag: gen n = _n
	
	replace names = "Average test score" 				if names == "zscore"
	replace names = "Class size"						if names == "class_size"
	replace names = "Proportion minority students"		if names == "nonwest"
	replace names = "Proportion girls"					if names == "female"
	replace names = "SES index"							if names == "ses"
	replace names = "Classroom wellbeing index"			if names == "wellbeing_index"
	replace names = "Classroom atmosphere"				if names == "happy_classroom"
	replace names = "Classroom calmness"				if names == "concentrate"
	replace names = "Classroom bullying"				if names == "bullied"
	replace names = "Classroom motivation"				if names == "boring"
	replace names = "Classroom disruption"				if names == "disturb"
	replace names = "Classroom satisfaction"			if names == "nice_classroom"
		
	labmask n , val(names) 
	replace n = n - .2 if lag == 2

	gen x = .										// Empty pseudo variable to create nice legend key with CIs
	
	global out "$dir/output"
	
	gr tw 	sc n b if lag == 1, mcol(stc1)										///
		|| 	rspike ll ul n if lag == 1, hor lcol(stc1) 							///
		|| 	sc n b if lag == 2, mcol(stc2) msym(T)								///
		|| 	rspike ll ul n if lag == 2,  hor lcol(stc2)							///
		|| 	conn n x if lag == 1, col(stc1) msym(O)								///
		||	conn n x if lag == 2, col(stc2) msym(T)								///
		ytitle("")																///
		ylab(1(1)12, valuelabels)												///
		xtitle("Coefficients and 95% CIs")										///
		xlab(-0.01(0.002).01) 													///
		xline(0) 																///	
		legend(order(5 "Parental leave {it:t}+1" 6 "Parental leave {it:t}+2")	///
			pos(1) ring(0) size(small) symx(*.7) symy(*.7) rowgap(*.1) region(lcol(black) margin(tiny)))	
	graph export $out/exogeneity_leave.eps, replace 	


** Export table with estimates 

mat C1 = B1[1...,1..5]
mat C2 = B2[1...,1..5]

frmttable using $dir/output/extra/app_exogeneity_lag1.tex, replace statmat(C1) sdec(3,3,3,3,0) ///
	fragment tex 																				///
	ctitle("Variable", "Est.", "(SE)", " $ p$-value", " $ R^2$", "Obs.")						///
	rtitle("Classroom atmosphere"\"Classroom calmness"\"Classroom bullying"\"Classroom motivation"\"Classroom disruption"\"Classroom satisfaction"\"Classroom wellbeing index"\"SES index"\"Class size"\"Proportion girls"\"Proportion minority students"\"Average test score")

frmttable using $dir/output/extra/app_exogeneity_lag2.tex, replace statmat(C2) sdec(3,3,3,3,0) ///
	fragment tex 																				///
	ctitle("Variable", "Est.", "(SE)", " $ p$-value", " $ R^2$", "Obs.")						///
	rtitle("Classroom atmosphere"\"Classroom calmness"\"Classroom bullying"\"Classroom motivation"\"Classroom disruption"\"Classroom satisfaction"\"Classroom wellbeing index"\"SES index"\"Class size"\"Proportion girls"\"Proportion minority students"\"Average test score")

		
			