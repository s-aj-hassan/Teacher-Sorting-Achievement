****************************************************************************************************
*
* TEACHER DEMOGRAPHICS FROM POPULATION REGISTERS (BEF)
* 
****************************************************************************************************

* Macros 

	global min = 1980
	global max = 2019 
	
* Load teachers 

	use $dir/data/teacherlist, clear
	
* Define variables 
	
	gen double mom = . 
	gen double dad = . 
	gen bdate = .
	gen nonwest = .
	gen female = .
	gen inpop_from = .
	
* Load Western countries codes 

	do $fmt/opr_land_west.do 
	
* Loop over BEF
		
	forval t = $min/$max {
		
		local fvars	"pnrm pnrf sfoddato`t' ietype`t' ieland`t' koen`t'" 
		local bvars "mor_id far_id foed_dag`t' ie_type`t' opr_land`t' koen`t'"
				
		// Merge variables from population registers, FAIN and BEF 
		
		if `t' < 1986 {
			
			merge 1:1 pnr using $dd100/fain`t', keep(1 3) keepus(`fvars')
			rename (`fvars') (`bvars')
			
		}
		
		if `t' > 1985 { 
			
			local vars "`bvars'"
			merge 1:1 pnr using $dd100/bef`t', keep(1 3) keepus(`bvars')  					
			
		}	
		
		local vars "`bvars'" 
		
		// Parent IDs and birth date
		
		replace mom = mor_id if mom == . 
		replace dad = far_id if dad == . 
		replace bdate = foed_dag`t' if bdate == . 
		
		// Female dummy 
		
		ge x = koen`t' == 2 
		replace x = . if koen`t' == . 
		replace female = x if female == . 
		drop x 
		 
		// Non-western immigrant dummy  
		
		ge x = ie_type`t' == 1 | inlist(opr_land`t', $west)				
		replace x = . if ie_type`t' == . & opr_land`t' == . 
		replace x = abs(x-1)
		replace nonwest = x if nonwest == . 
		drop x 
		
		// First year in BEF
		
		replace inpop_from = `t' if inpop_from == . & _merge == 3 
		drop _merge 
		
		drop `vars'
		
	}
	
	isid pnr 

* Rename teacher variables to: T_* 

	foreach v in mom dad bdate nonwest female inpop_from {
		
		rename `v' T_`v'
		
	}
	
	gen T_miss_pop = T_inpop_from == . 

* Save data 
	
	label var pnr 			"Person ID"
	label var T_mom			"Teacher: Mom ID"
	label var T_dad			"Teacher: Dad ID"
	label var T_bdate		"Teacher: Birth date"
	label var T_nonwest		"Teacher: At least one non-western parent"
	label var T_female		"Teacher: Female"
	label var T_inpop_from	"Teacher: First year observed in population register"
	label var T_miss_pop 	"Teacher: Missing from population register"

	label data "Teacher covariates: Demographics"
	
	save $tmp/teachers_demographics, replace 
