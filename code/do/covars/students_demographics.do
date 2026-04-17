
	global min = 1996
	global max = 2019 
	
	use $dir/data/studentlist, clear
	
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
			
			// Merge variables from population register, BEF 
			
			local vars "mor_id far_id foed_dag`t' ie_type`t' opr_land`t' koen`t'"
			merge 1:1 pnr using $dd100/bef`t', keep(1 3) keepus(`vars')  
			
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

	* Generate filter variables (main analysis: only drop individuals completely missing from BEF)
	* Those with missing moms and dads are marked but not as a filter variable 

		gen miss_pop = inpop_from == . 

		assert female  != . if miss_pop == 0  
		assert bdate   != . if miss_pop == 0 
		assert nonwest != . if miss_pop == 0 
		
	* Missing parent IDs 

		gen miss_mom 	= mom == . 
		gen miss_dad 	= dad == . 
		
		label var pnr 			"Person ID"
		label var mom			"Mom ID"
		label var dad			"Dad ID"
		label var bdate			"Birth date"
		label var nonwest		"At least one non-western parent"
		label var female		"Female"
		label var inpop_from	"First year observed in population register"
		label var miss_pop 		"Not in population registers"
		label var miss_mom 		"Mom ID missing"
		label var miss_dad 		"Dad ID missing"
		
		label data "Student covariates: Demographics"
		
		save $tmp/students_demographics, replace 