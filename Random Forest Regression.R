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
# Initial run imputes null values, but future run will handle these differently
HighPerformer.rfsurv <- rfsrc(Surv(Tenure_Mo, Terminated) ~ x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 + x12 + x13 + x14 + x15
 ,data = FlightRisk
 ,ntime = 5
 ,nsplit = 10
 ,ntree = 250
 ,na.action = "na.impute")
 
# Summary
HighPerformer.rfsurv

# Plotting OOB Error Rate and Variable Importance
plot(HighPerformer.rfsurv)



# Grow and plot the regular random forest - same logic on the parameters as above applies
HighPerformer.rf <- rfsrc(Terminated ~ x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 + x12 + x13 + x14 + x15 + x16
        , data = FlightRisk
        , ntime = 5
        , ntree = 250)
        
# Summary
HighPerformer.rf

# Plotting the OOB error and Variable Importance
plot(HighPerformer.rf)


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
labs(y = st.labs["Terminated"], x = "")

# Plotting partial dependence
partial_FlightRisk <- plot.variable(HighPerformer.rf,
                xvar = gg_md$topvars,
                partial = TRUE, sorted = FALSE,
                show.plots = FALSE)
                
gg_p <- gg_partial(partial_FlightRisk)

plot(gg_p, xvar = xvar, panel = TRUE, se = FALSE) +
labs(y = st.labs["Terminated"], x = "")
