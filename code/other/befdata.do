clear all
set more off 

global in  "E:\Data\rawdata\708177"
global out "Y:\Data\workdata\708177\commondata\bef"

global min = 1985
global max = 2024
 
forval t = $min/$max {
	
	use $in/bef12_`t', clear 
	drop if pnr == . 
	destring pnr far_id mor_id, replace force 
	isid pnr 
	save $out/bef12_`t', replace 
	
	
}