* Construct a variable only containing teacher IDs - helps creating subsequent datasets easily

forval t = 2013/2019 { 
	
	use $UDL/uddlaerer`t'09, clear 
	keep PNR_LAERER
	rename PNR_LAERER pnr 
	destring pnr, replace force 
	drop if pnr == . 
	duplicates drop 
	
	if `t' > 2013 append using $dir/data/teacherlist
	duplicates drop 
	save $dir/data/teacherlist, replace 
		
}

* Teachers in UDDLAERER by year 

forval t = 2013/2019 { 
	
	* Load data 
	use $UDL/uddlaerer`t'09, clear 
	keep PNR_LAERER 
	rename PNR_LAERER pnr 
	destring, replace force 
	drop if pnr == . 
	duplicates drop 
	
	gen t = `t' 
	
	if `t' > 2013 append using $dir/data/teacherlist_years
	save $dir/data/teacherlist_years, replace 
	
	
}

* Student list 

forval t = 2013/2019 { 
	
	use $UDL/uddlaerer`t'09, clear 
	keep pnr 
	destring pnr, replace force 
	drop if pnr == . 
	duplicates drop 
	
	if `t' > 2013 append using $dir/data/studentlist
	duplicates drop 
	save $dir/data/studentlist, replace 
		
}