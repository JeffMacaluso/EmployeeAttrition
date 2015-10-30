# EmployeeAttrition
###Calculating the likelihood of the termination of field employees 


This repository includes sections of code used to calculate the likelihood of employee termination.  It is not the complete code, as most of it was specific to the company's SQL database, and parts of the R code repeated itself.

Random forest is the algorithm of choice due to the goal of obtaining an accurate predictor score and to prevent under/overfitting.

The regression algorithms used in the R file are random forest regression, and random forest regression utilizing survival analysis.  The regular regression gives us an overall 0-100 score per employee, whereas the survival analysis variant gives us a score for each time interval (months in this case).
