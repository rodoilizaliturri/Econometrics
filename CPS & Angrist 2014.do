
****************************************************
* Code for for PSet 2 Part 2 Q1 in 14.320, Spring 2022 *
****************************************************

* Setup
pause on
clear all
set more off
cap log close


// set to directory 
cd "D:/IPA/Stata Practice/14.320 PS2"

cap log using Practice_PSet2.log, text replace

use cps_extract

keep if (age >= 30 & age <= 49)

summarize age uhrswork1 wkswork1 incwage

gen awe = incwage / wkswork1
gen ahe = awe / uhrswork1
gen ln_awe = log(awe)
gen ln_ahe = log(ahe)

gen sex_rec = (sex == 2)

sum awe ahe ln_ahe ln_awe

ttest ln_awe, by(sex_rec)

reg ln_awe sex_rec

****************************************************
*-------------- With loops
****************************************************

local vars "ln_ahe ln_awe"

foreach v of local vars {
	ttest `v' if (age >= 40 & age <= 49) , by(sex_rec) 
}

foreach v of local vars {
	reg `v' sex_rec if (age >= 40 & age <= 49) 
}

gen age_2 = age*age

reg ln_ahe age age_2

****************************************************
*-------------- Plot
****************************************************

twoway ///
	(qfit ln_ahe age if sex_rec == 0, lc(blue) lw(thick)) ///
	(qfit ln_ahe age if sex_rec == 1, lc(red) lw(thick)) , ///
	legend(on size(small) ///
      order( ///
        1 "Men" ///
        2 "Women" ///
		)) title("Fitted values by gender")



****************************************************
*-------------- Wage gap
****************************************************

tab educ99
tab educ99, nolabel

gen coll_grad = (educ99 >= 15)

reg ln_ahe sex_rec i.race age age_2 coll_grad
reg ln_ahe sex_rec

display as text "mean of mpg = " as result _b[sex]


****************************************************
****************************************************
*-------------- AOW 2014
****************************************************
****************************************************

clear all

use OKgradesUpdate_Feb5_2010, replace

/* CREATE A FEW VARIABLES */

gen C = 1-T
gen s_second_year = 1-s_first_year
gen s_female = 1-s_male

/* CHANGE COLLEGE GRAD/HIGH SCHOOL GRAD VARIABLES TO INCLUDE THOSE WITH HIGHER DEGREES */

replace s_motherhsdegree = 1 if s_mothercolldegree==1 | s_mothergraddegree==1
replace s_fatherhsdegree = 1 if s_fathercolldegree==1 | s_fathergraddegree==1
replace s_mothercolldegree = 1 if s_mothergraddegree==1
replace s_fathercolldegree = 1 if s_fathergraddegree==1

/* GENERATE CONTROLS HYPOTHETICAL EARNINGS VARIABLES */

gen controlswhoearned = gradeover702008 if T==0
gen controlsearnings = earnings2008 if T==0

/* SET THE STRATA CONTROLS LIST */

local stratacontrols ""
tab s_group_quart, gen(s_group_quart)
forvalues i=2(1)16 {
	local stratacontrols "`stratacontrols' s_group_quart`i'"
}

forvalues i=2(1)16 {
	display `i'
}

/* DESCRIPTIVE STATISTICS ON DEMOGRAPHIC VARIABLES BY STRATIFICATION GROUP AND TREATMENT */

*Make variable name labels
local var1 "Age"
local var2 "High school grade average"
local var3 "1st language is English"
local var4 "Mother finished college"
local var5 "Father finished college"
local var6 "Answered earnings test question correctly"
local var7 "Controls who would have been paid"
local var8 "Mean hypothetical earnings for controls"

*Erase the old table
capture erase nbertable1.csv
estimates clear

* Results matrix

matrix results = J(16,2,.)

*TREATMENT DIFFERENCES CONTROLLING FOR STRATA
*Loop over variables to be summarized
local i = 1
foreach sumvar in s_age s_hsgrade3 s_mtongue_english s_mothercolldegree s_fathercolldegree s_test2correct controlswhoearned controlsearnings {


	qui summarize `sumvar' if T==0

	matrix results[`i',1] = round(r(mean),.001)
	matrix results[`i'+1,1] = round(r(sd),.001)
	

	qui reg `sumvar' T s_group_quart2 - s_group_quart16, r
	
	matrix results[`i',2] = round(_b[T],.001)
	matrix results[`i'+1,2] = round(_se[T],.001)
	
	
	local i=`i'+2
}


estout matrix(results)

frmttable, statmat(results)


cap log close