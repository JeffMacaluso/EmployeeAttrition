# Used https://cran.r-project.org/web/packages/ggRandomForests/vignettes/randomForestSRC-Survival.pdf for reference
library("ggplot2")
library("RColorBrewer")
library("dplyr")
library("parallel")
library("randomForestSRC")
library("ggRandomForests")

theme_set(theme_bw())

## Open circles for censored, x for events, red for termination events
event.marks <- c(1, 4)
event.labels <- c(FALSE, TRUE)
strCol <- brewer.pal(3, "Set1")[c(2, 1, 3)]


# Grow and store the random survival forest - using 250 trees as a previous run has shown that there is marginal benefit from getting more
# ntime = 5 to save on processing power due to hardware constraints
HighPerformer.rfsurv <- rfsrc(Surv(EmploymentLengthMM, Terminated) ~ AvgWeeklyPaycheck + ShortTermProductivity + Productivity + Age + TitleInt + ComboRate + Region + RegionProductivity + Rehire + DistrictProductivity + DivisionProductivity + DivisionInt + EmploymentLengthMM + MilesFromSalon + Territory,
 data = FlightRisk,
 ntime = 5,
 nsplit = 10,
 ntrees = 250,
 na.action = "na.impute")
 
# Summary
HighPerformer.rfsurv

# Plotting OOB Error Rate
plot(gg_error(HighPerformer.rfsurv)) + 
coord_cartesian(y = c(.09, .31))



# Grow and plot the regular random forest - same logic on the parameters as above applies
HighPerformer.rf <- rfsrc(Terminated100 ~ AvgWeeklyPaycheck + ShortTermProductivity + Productivity + Age + TitleInt + ComboRate + Region + RegionProductivity + Rehire + DistrictProductivity + DivisionProductivity + DivisionInt + EmploymentLengthDD + MilesFromSalon
        , data = FlightRisk
        , ntime = 5
        , ntrees = 250)
        
# Summary
HighPerformer.rf

# Plotting the OOB error
gg_e <- gg_error(HighPerformer.rf)

plot(gg_e)

plot(gg_rfsrc(HighPerformer.rf), alpha = .5) +

coord_cartesian(ylim=c(5, 49))

# Plotting VIMP rankings of independent variables
plot(gg_vimp(HighPerformer.rf), lbls=st.labs)

# Minimal Depth: assumes variables w/ high impact on the prediction are most frequently split nodes nearest to trunks
varsel_FlightRisk <- var.select(HighPerformer.rf)

data(varsel_FlightRisk)

gg_md <- gg_minimal_depth(varsel_FlightRisk)

plot(gg_md, lbls = st.labs)

plot.gg_minimal_vimp(gg_md)

# Plotting the variable dependence
gg_v <- gg_variable(HighPerformer.rf)
xvar <- gg_md$topvars
plot(gg_v, xvar=xvar, panel = TRUE
                se = .95, span = 1.2, alpha = 0.4) +
labs(y = st.labs["Terminated100"], x = "")

# Plotting partial dependence
partial_FlightRisk <- plot.variable(HighPerformer.rf,
                xvar = gg_md$topvars,
                partial = TRUE, sorted = FALSE,
                show.plots = FALSE)
                
gg_p <- gg_partial(partial_FlightRisk)

plot(gg_p, xvar = xvar, panel = TRUE, se = FALSE) +
labs(y = st.labs["Terminated100"], x = "")
