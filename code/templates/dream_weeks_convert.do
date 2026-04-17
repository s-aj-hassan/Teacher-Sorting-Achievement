* Where to data 

global dir "Y:\Data\workdata\708177\templates"

* Note: This dofile converts the DREAM weeks to two date variables (days) 
* s = the date of the first day in the dream week
* e = the date of the last day in the dream week 

* You will need to reshape your DREAM data to a long format where you have:
* t_dream (the dream year)
* w_dream (the dream week ... for instance "y_52" would here be "52")


* Dates where weeks start every year 
* Note that 1991 starts in week 32 in DREAM 

local s_1991 = "05aug1991"
local s_1992 = "30dec1991"
local s_1993 = "04jan1993"
local s_1994 = "03jan1994"
local s_1995 = "02jan1995"
local s_1996 = "01jan1996"
local s_1997 = "30dec1996"
local s_1998 = "29dec1997"
local s_1999 = "04jan1999"
local s_2000 = "03jan2000"
local s_2001 = "01jan2001"
local s_2002 = "31dec2001"
local s_2003 = "30dec2002"
local s_2004 = "29dec2003"
local s_2005 = "03jan2005"
local s_2006 = "02jan2006"
local s_2007 = "01jan2007"
local s_2008 = "31dec2007"
local s_2009 = "29dec2008"
local s_2010 = "04jan2010"
local s_2011 = "03jan2011"
local s_2012 = "02jan2012"
local s_2013 = "31dec2012"
local s_2014 = "30dec2013"
local s_2015 = "29dec2014"
local s_2016 = "04jan2016"
local s_2017 = "02jan2017"
local s_2018 = "01jan2018"
local s_2019 = "31dec2018"
local s_2020 = "30dec2019" 

* Years with 53 weeks

global oddY "1992, 1998, 2004, 2009, 2015, 2020"

forval t = 1991/2020 {
	
	clear 
	
	* Last week 
	global L = 52
	if inlist(`t', $oddY) global L = 53 
	
	* First week 
	global F = 1 
	if `t' == 1991 global F = 32 
	
	* Total weeks 
	global weeks = ($L - $F) + 1 
	
	* Start dataset 
	set obs $weeks 
	
	* Dream year and week variables 
	gen t_dream = `t' 
	gen w_dream = _n + $F - 1 
	
	* Start of week and end of week dates 
	
	gen s = td(`s_`t''') if _n == 1 
	replace s = s[_n-1] + 7 if _n > 1
	
	gen e = s + 6
	
	format %td s e
	
	if `t' > 1991 append using $dir/dream_weeks_convert 
	save $dir/dream_weeks_convert, replace 
	
	
}


use $dir/dream_weeks_convert, clear 
sort s
gen dreamweek = _n 	// This one is not really useful but corresponds to the "Dream uge" in the "DREAM kalender" documentation sheet


save $dir/dream_weeks_convert, replace 


* Now let's attach a dream week to every single day 

use $dir/dream_weeks_convert, clear 
expand e - s + 1 
egen min = min(s)
sort s
gen day = _n + min - 1  
format day %td
drop min

save $dir/dream_weeks_convert_alldays, replace 


