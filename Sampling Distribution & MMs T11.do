clear all
cap log close

cap log using pset1.log, text replace

// set to directory where NHIS2009_clean.dta is stored
cd "D:/IPA/Stata Practice/14.320 PS1"

set obs 500 
forvalues j = 1/8 {
drawnorm x_N_8_`j', mean(10) sds(3)
}

forvalues j = 1/32 {
drawnorm x_N_32_`j', mean(10) sds(3) 
}

forvalues j = 1/128 {
drawnorm x_N_128_`j', mean(10) sds(3) 
}

egen mean_N_8 = rowmean(x_N_8_*)
egen mean_N_32 = rowmean(x_N_32_*)
egen mean_N_128 = rowmean(x_N_128_*)

hist mean_N_8, density title("Normal from 8 samples") fcolor(purple) xtitle(, color(%0)) subtitle(500 random samples of n = 8) name(g1, replace) xscale(range(7 14)) xlabel(6(2)14) lcolor(%0) yscale(range(0 1.75)) ylabel(0(.5)1.75)

hist mean_N_32, density title("Normal from 32 samples") fcolor(blue) xtitle(, color(%0)) subtitle(500 random samples of n = 32) name(g2, replace) xscale(range(7 14)) xlabel(6(2)14) lcolor(%0) yscale(range(0 1.75)) ylabel(0(.5)1.75)

hist mean_N_128, density title("Normal from 128 samples") fcolor(green) xtitle(, color(%0)) subtitle(500 random samples of n = 128) name(g3, replace) xscale(range(7 14)) xlabel(6(2)14) lcolor(%0) yscale(range(0 1.75)) ylabel(0(.5)1.75)

graph combine g1 g2 g3, name(Normal, replace) title(Sampling Distribution from NORMAL (10,9)) rows(2)

// --------------- BINOMIAL experiments

forvalues j = 1/8 {
gen x_B_8_`j' = rbinomial(1,.7)
}

forvalues j = 1/32 {
gen x_B_32_`j' = rbinomial(1,.7)
}

forvalues j = 1/128 {
gen x_B_128_`j' = rbinomial(1,.7)
}

egen mean_B_8 = rowmean(x_B_8_*)
egen mean_B_32 = rowmean(x_B_32_*)
egen mean_B_128 = rowmean(x_B_128_*)


hist mean_B_8, density title("Bernoulli from 8 samples") fcolor(purple) xtitle(, color(%0)) subtitle(500 random samples of n = 8) name(g4, replace) 

hist mean_B_32, density title("Bernoulli from 32 samples") fcolor(blue) xtitle(, color(%0)) subtitle(500 random samples of n = 32) name(g5, replace) 

hist mean_B_128, density title("Bernoulli from 128 samples") fcolor(green) xtitle(, color(%0)) subtitle(500 random samples of n = 128) name(g6, replace)

graph combine g4 g5 g6, name(Normal, replace) title(Sampling Distribution from Bernoulli (0.7)) rows(2)

****-------------------------------- Q5 PART B --------------------------------

tabstat mean_N_8 mean_N_32 mean_N_128 mean_B_8 mean_B_32 mean_B_128, statistics(mean variance)


****-------------------------------- PART B--------------------------------


*** Metrics
*** Table 1.1
*** goal: make table of health outcomes and characteristics by insurance status ***

* by Georg Graetz, August 6, 2013
* modified by Gabriel Kreindler, June 13, 2014
* modified by Jon Petkun, January 2, 2015
* modified by Ryan Hill, Jan 31, 2020
* modified by Hellary Zhang, April 5, 2021


clear all

use NHIS2009_clean.dta


// set to directory where NHIS2009_clean.dta is stored

*cap log using NHIS2009_hicompare.log, text replace

* PART I: Keep couples and select sample

use NHIS2009_clean, clear

* select non-missings
keep if marradult==1 & perweight!=0 
	by serial: egen hi_hsb = mean(hi_hsb1)
		keep if hi_hsb!=. & hi!=.
	by serial: egen numfem = total(fml)
		keep if numfem==1
		drop numfem
		
	* Josh's sample selection criteria	
		gen angrist = ( age>=26 & age<=59 & marradult==1 & adltempl>=1 )
			keep if angrist==1
		// drop single-person HHs
		by serial: gen n = _N
			keep if n>1
		
* PART II: Create different datasets for husbands and wives
	
	preserve
		keep if fml == 1 
		save wives.dta, replace
	restore
	
	preserve
		keep if fml == 0 
		save husbands.dta, replace
	restore	
	
* PART III: Create Table 1.1
	
	local groups "husbands wives"
	
	foreach g of local groups {
	display "`g'"
	}

	foreach g of local groups {
		
	* Loop over husbands and wives datasets
		use `g', clear
		
	* Prepare matrix to store results
		matrix results = J(15,3,.)
		matrix rownames results = "Health index" "se" "Nonwhite" "se" "Age" "se" "Education" "se" "Family Size" "se" "Employed" "se" "Family income" "se" "Sample size"
		if "`g'" == "husbands" { 
			matrix colnames results = "Husbands: Some HI" "Husbands: No HI" "Husbands: Difference"
		}
		if "`g'" == "wives" { 
			matrix colnames results = "Wives: Some HI" "Wives: No HI" "Wives: Difference" 
		}
		
		matrix list results,format(%8.4f)
		
		local col = 1
		local row1 = 1
		local row2 = 2
		

	 * Health status by insurance coverage and sex
		qui sum hlth if hi==1 /*& fml==`fem'*/ [ aw=perweight ]
			mat results[`row1',`col'] = r(mean)
			mat results[`row2',`col'] = r(sd)
			local ++col
			
		qui sum hlth if hi==0 /*& fml==`fem'*/ [ aw=perweight ]
			mat results[`row1',`col'] = r(mean)
			mat results[`row2',`col'] = r(sd)
			local ++col

		reg hlth hi /*if fml==`fem'*/ [ aw=perweight ], robust
			mat results[`row1',`col'] = _b[hi]
			mat results[`row2',`col'] = _se[hi]
			local ++col
			
			local row1 = `row1' + 2
			local row2 = `row2' + 2

	* Other characteristics by insurance and sex		
		foreach var in nwhite age yedu famsize empl inc {
			
			local col = 1
			
			* means and SDs
				qui sum `var' if hi==1 /*& fml==`fem'*/ [ aw=perweight ]
					mat results[`row1',`col'] = r(mean)
					local ++col
				qui sum `var' if hi==0 /*& fml==`fem'*/ [ aw=perweight ]
					mat results[`row1',`col'] = r(mean)
					local ++col
					
			* mean comparisons 
				reg `var' hi /*if fml==`fem'*/ [ w=perweight ], robust
					mat results[`row1',`col'] = _b[hi]
					mat results[`row2',`col'] = _se[hi]
					local ++col
									
			local row1 = `row1' + 2
			local row2 = `row2' + 2
		}
			
		* Sample sizes
		tab hi /*if fml == 0*/ [aw=perweight], matcell(x)
		mat list x
		
		mat results[`row1',2] = x[1,1]
		mat results[`row1',1] = x[2,1]

	* List results
	matrix list results, format(%8.2f)		
			
		
	* Output results	
	putexcel set MM_Table1_1, modify
	if "`g'" == "husbands" {
		putexcel A1 = matrix(results), names nformat(number_d2)
	}
	if "`g'" == "wives" {
		putexcel E1 = matrix(results), overwritefmt colnames nformat(number_d2) 
	}
	
	}
	
cap log close