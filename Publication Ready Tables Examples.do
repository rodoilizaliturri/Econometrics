set more off
clear all

sysuse nlsw88, clear

*generate a dummy variable for each race category
tab race, gen(dum_race)


*calculate summary statistics for the specified variables
estpost summarize age wage dum_race1 dum_race2 dum_race3 collgrad

*store the calculated summary statistics in a macro 
eststo summstats

*output the summary statistics to a table
esttab summstats using table2.rtf,  replace main(mean %6.2f) aux(sd) nomtitles nonumber nostar ///
refcat(dum_race1 "Race:", nolabel) ///
coeflabel(dum_race1 "White" dum_race2 "Black" dum_race3 "Other" age "Age" wage "Hourly wage" collgrad "College graduate") ///
title(Table 2. Summary Statistics, NLSW88) ///
nonotes addn(Standard deviations in parentheses.)

*run a regression
regress wage age collgrad dum_race2 dum_race3

*store the regression results in a macro
eststo regression

*output the regression results to a table
esttab regression using table3.rtf, replace se r2 nostar ///
mtitle("Dependent variable: Wage") ///
refcat(dum_race2 "Race:", nolabel) ///
coeflabel(dum_race2 "Black" dum_race3 "Other" age "Age" wage "Hourly wage" collgrad "College graduate" _cons "Constant") ///
title(Table 3. Regression Results) ///
addn(The omitted race category is white.)

* MORE
*summary stats by subsample
eststo grad: estpost summarize age wage dum_race1 dum_race2 dum_race3 if collgrad==1
eststo nograd: estpost summarize age wage dum_race1 dum_race2 dum_race3 if collgrad==0

esttab summstats grad nograd using table4.rtf,  replace main(mean %6.2f) aux(sd) nonumber nostar ///
mtitle("Full sample" "College graduates" "Non-college graduates") ///
refcat(dum_race1 "Race:", nolabel) ///
coeflabel(dum_race1 "White" dum_race2 "Black" dum_race3 "Other" age "Age" wage "Hourly wage" collgrad "College graduate") ///
title(Table 4. Summary Statistics, NLSW88) ///
nonotes addn(Standard deviations in parentheses.)

*place std dev in its own column
esttab summstats grad nograd using table4b.rtf,  replace cell("mean(fmt(2)) sd(fmt(2))") nonumber nostar ///
mtitle("Full sample" "College graduates" "Non-college graduates") ///
refcat(dum_race1 "Race:", nolabel) ///
coeflabel(dum_race1 "White" dum_race2 "Black" dum_race3 "Other" age "Age" wage "Hourly wage" collgrad "College graduate") ///
title(Table 4. Summary Statistics, NLSW88)