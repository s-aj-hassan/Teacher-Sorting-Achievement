# Replication Package: Teacher Sorting and Inequalities in Student Achievement

This repo contains code to replicate the results in "Teacher Sorting and Inequalities in Student Achievement: Unequal Exposures and Differential Returns to Teacher Qualifications" (Said Hassan) in *Sociological Science*, 2026 [[Link to paper]](https://doi.org/10.15195/v13.a29).

I have written the code in Stata (version 18) and uploaded all files to this repo. For the paper, I use full population Danish register data (see below for information on how to access the data). 

## Data Availability 

The analysis uses confidential administrative register data from Denmark accessed through Statistics Denmark. These data are not publicly available but require approved access through Statistics Denmark. For information on how to apply for data access, see: (https://www.dst.dk/en/TilSalg/data-til-forskning/autorisering-af-institutioner). 

I use the following registers 

| Register | Description | 
|--------|----------|
| UDD_NATTEST_OPRINDELIGE | National Test Score database |
| UDD_TRIVSEL_SMAA_KLASSER | Well-being survey grades 1-3 | 
| UDD_TRIVSEL_STORE_KLASSER | Well-being survey grades 4-9 |
| UDFK | GPA data grade 9 | 
| UDKLASSE_ID | Classroom IDs | 
| UDDLAERER | Teacher-student database | 
| BEF | Population registers | 
| FAIN | Population registers | 
| AKM | The work classification module | 
| DREAM | Weekly public transfer database | 
| IND | Income register |
| RAS | Employment register | 
| INST | Institutions register | 
| LPRMFRLF | Birth register |  
| MFR | Birth register | 
| UDDA | Educational attainment register | 
| UDSF | Educational attainment register | 
| UDG | Grades from completed educations | 
| UDSP | Special education classes | 

## Code 

The folder **code** above contains all Stata dofiles to construct the data from the raw administrative registers and to conduct all analyses in the paper. The file `master.do` constructs all datasets and produces all tables and figures. 

## Figures and Tables

Figures

| Figure | Location in code |
|----------|----------|
| 1   | `do\analyses\sortdist.do`   |
| 2   | `do\analyses\sortgrad.do`   |
| 3   | `do\analyses\teacher_changes_desc.do` | 
| 4   | `do\analyses\desc_parental_leaves.do` |
| 5   | `do\analyses\exogeneity.do` |
| 6   | `do\analyses\fe_student_exog_shock_results.do` |
| 7   | `do\analyses\fe_student_exog_shock_results.do` |
| B1  | `do\covars\students_ses_index.do` |

Tables

| Table | Location in code |
|----------|----------|
| 1   | `do\analyses\fe_student_exog_shock_results.do`  |
| A1  | `do\analyses\exogeneity.do` |
| A2  | `do\analyses\fe_student_exog_shock_results.do` |
| A3  |  `do\analyses\fe_student_exog_shock_results.do` |
