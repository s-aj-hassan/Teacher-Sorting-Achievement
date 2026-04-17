****************************************************************************************************
****************************************************************************************************
* TEACHER SORTING AND INEQUALITIES IN STUDENT ACHIEVEMENT: 
* UNEQUAL EXPOSURES AND DIFFERENTIAL RETURNS TO TEACHER QUALIFICATIONS 
* 
* Sociological Science - 2026
* Said Hassan - https://saidhassan.net
*
* This master dofile builds all datasets, runs all analyses, and exports all tables and figures
* in the paper. 
* Make sure to construct the appropriate folders first and saw your raw datasets in the folders
* accordingly. 
* 
* For instructions on how to access the datasets, see https://www.dst.dk/en/TilSalg/data-til-forskning
* and my GitHub page for the paper. 

****************************************************************************************************
****************************************************************************************************

clear all 
set more off, perm

global dir 		"Y:\Data\Workdata\708177\sah\teachqual" 		// Your working directory here
global tmp 		"$dir/temp"

global dd100	"E:\Data\rawdata\708177" 						// Stats DK registers 

global common 	"Y:/Data/workdata/708177/commondata" 			// Location of some common files 
global DNT		"Y:/Data/workdata/708177/commondata/dnt/data" 	// Danish National Test clean files 
global UDFK		"$common/udfk/data" 							// GPA clean data 
global UDL 		"$common/uddlaerer" 							// Teacher-student raw data location
global UDK 		"$common/udklasse" 								// Classid raw data location 
global BEF 		"$common/bef" 									// Clean version of population register BEF with one row per individual 
global STIL		"Y:\Data\Workdata\708177\STIL" 					// STIL dataset with teacher qualification measures "kompetencedeakning"

global dstfmt 	"//SRVFSENAS1/data/formater/SAS formater i Danmarks Statistik/STATA_datasaet" 		// Value labels and formats from Stats DK 
global fmt 		"Y:\Data\workdata\708177\templates" 

set scheme stcolor
set sortseed 42 

****************************************************************************************************
****************************************************************************************************
* 
* BUILD CORE DATASETS
*
****************************************************************************************************
****************************************************************************************************

* STUDENT AND TEACHER ID LISTS
	// List of teacher and student IDs in UDDLAERER - makes subsequent data construction easier 
	
	do $dir/do/ID_list
	
* TEACHER QUALIFICATION MEASURES 
	// Certifications from UDSF; Specialization from UDDLAERER; Experience from AKM and UDDLAERER; 
	// High school grades from UDG; Teacher College GPAs from UDG 
	
	do $dir/do/teacher_qual
	
* APPEND ANNUAL TEACHER-STUDENT DATASETS FROM UDDLAERER 

	do $dir/do/teacher_student_append 

* IDENTIFY IRREGULAR CLASSES
	// Non-normal classes (UDSP data): for individual students taking special ed / second language

	do $dir/do/udsp
	
* TEACHER PARENTAL LEAVE SPELLS

	// Verify parental leave DREAM codes 
	* verify_dream.do is not used in the paper. It just checks the parental leave spells
	* the DREAM data. Takes very long to run!
	do $dir/do/verify_dream 
	
	// Parental leave 
	do $dir/do/pleave 
	do $dir/do/pleave_spells 
		
* STUDENT COVARIATES 

	do $dir/do/covars/students_demographics
	do $dir/do/covars/students_mfr 
	do $dir/do/covars/students_par_divorce 
	do $dir/do/covars/students_par_education
	do $dir/do/covars/students_par_income 
	do $dir/do/covars/students_par_employment
	do $dir/do/covars/students_ses_index 
	do $dir/do/students_covars 							// Merges all covars on students 	

* TECHER COVARIATES

	do $dir/do/covars/teachers_demographics
	do $dir/do/covars/teachers_par_education
	do $dir/do/covars/teachers_par_income 
	do $dir/do/covars/teachers_par_employment
	do $dir/do/covars/teachers_ses_index 
	do $dir/do/teachers_covars 							// Merges all covars on teachers  		
	
* SCHOOL LEVEL VARIABLES

	do $dir/do/school_vars
	
* CLASSROOM LEVEL VARIABLES 

	do $dir/do/classroom_wellbeing
	do $dir/do/classroom_DNT
	do $dir/do/classroom_vars
	
****************************************************************************************************
****************************************************************************************************
*
* DESCRIPTIVES 
*
****************************************************************************************************
****************************************************************************************************

* Descriptive teacher-student graphs 
	
	// Distribution of qualifications by student SES
	do $dir/do/analyses/sortdist
	
	// Teacher sorting - selection of graduate teachers 
	do $dir/do/analyses/sortgrad 
	
* Descriptive figure: Teacher changes in general 
	do $dir/do/analyses/teacher_changes_desc 

* Descriptive figure: Parental leave spells
	do $dir/do/analyses/desc_parental_leaves

	
****************************************************************************************************
****************************************************************************************************	
*
* MAIN FINDINGS 
*
****************************************************************************************************
****************************************************************************************************	
	
* Testing exoegeneity of parental leave spells	
	do $dir/do/analyses/exogeneity

* Student FE model with exogenous shocks 

	// Construct samples 
	do $dir/do/fe_student_shock_samples
	
	// Results for Danish and Math samples seperately 
	do $dir/do/fe_student_shock_results 

