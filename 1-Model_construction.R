

###################
# Set environment #
###################

# load libraries and initialize environment
source("set_env.R")


######################
# Model construction #
######################

# Test whether the different models (1-4) fit the data accurately, based on chi2 statistics

# nb_points: number of experimental data points (152)
# nb_par: number of free parameters

# Go to models directory
setwd(model_dir)

# Model 1: no inhibition by acetate
loadModel("Millard2020_Ecoli_glc_ace_model_1.cps")
res_PE_model1 <- runParameterEstimation(method = "Statistics", model = getCurrentModel())
res_PE_model1$chi2 <- test_khi2(nb_points=152, k_val=res_PE_model1$main$objective_value, nb_par=8)

print("chi2-test for model 1:")
print(paste("  p-value = ", res_PE_model1$chi2$`p-value, i.e. P(X^2<=value)`, sep=""))
print(paste("  conclusion: ", res_PE_model1$chi2$conclusion, sep=""))     

# Model 2: inhibition of glycolysis
loadModel("Millard2020_Ecoli_glc_ace_model_2.cps")
res_PE_model2 <- runParameterEstimation(method = "Statistics", model = getCurrentModel())
res_PE_model2$chi2 <- test_khi2(nb_points=152, k_val=res_PE_model2$main$objective_value, nb_par=9)

print("chi2-test for model 2:")
print(paste("  p-value = ", res_PE_model2$chi2$`p-value, i.e. P(X^2<=value)`, sep=""))
print(paste("  conclusion: ", res_PE_model2$chi2$conclusion, sep=""))     

# Model 3: inhibition of TCA cycle
loadModel("Millard2020_Ecoli_glc_ace_model_3.cps")
res_PE_model3 <- runParameterEstimation(method = "Statistics", model = getCurrentModel())
res_PE_model3$chi2 <- test_khi2(nb_points=152, k_val=res_PE_model3$main$objective_value, nb_par=9)

print("chi2-test for model 3:")
print(paste("  p-value = ", res_PE_model3$chi2$`p-value, i.e. P(X^2<=value)`, sep=""))
print(paste("  conclusion: ", res_PE_model3$chi2$conclusion, sep=""))     

# Model 4: inhibition of TCA and glycolysis
loadModel("Millard2020_Ecoli_glc_ace_model_4.cps")
res_PE_model4 <- runParameterEstimation(method = "Statistics", model = getCurrentModel())
res_PE_model4$chi2 <- test_khi2(nb_points=152, k_val=res_PE_model4$main$objective_value, nb_par=10)

print("chi2-test for model 4:")
print(paste("  p-value = ", res_PE_model4$chi2$`p-value, i.e. P(X^2<=value)`, sep=""))
print(paste("  conclusion: ", res_PE_model4$chi2$conclusion, sep=""))     

# plot model evaluation results
setwd(results_dir)
pdf(file="Figure 1B.pdf", width = 5, height = 5)

barplot(c(res_PE_model1$main$objective_value,
       res_PE_model2$main$objective_value,
       res_PE_model3$main$objective_value,
       res_PE_model4$main$objective_value),
       las=1,
       ylab="variance-weighted SSR",
       names.arg=c("model1", "model2", "model3", "model4"))
chi2_threshold <- 171
abline(h=chi2_threshold)

dev.off()


###########
# PLOT FIT vs MEASUREMENTS #
###########

# In current version of CoRc package, custom weights cannot be provided when defining an experiment,
# hence we cannot define weight according to the experimental standard deviations.
# To overcome this limitation, we use a copasi model file with weights pre-defined in the
# Parameter estimation task.

# MODEL 1 #
###########

setwd(model_dir)
loadModel("Millard2020_Ecoli_glc_ace_model_1.cps")

# get parameters for the best fit
res_PE_model <- runParameterEstimation(method = "Statistics", model = getCurrentModel())

# list used to set up global sensitivity analysis and store calculation results
fit_results_m1 <- list("1" = list("initial_concentrations"= c("Ace0_out"=0.92, "Glc"=12.9, "X"=0.0671),
                                  "species_idx" = c("[Ace0_out]_0"=1, "[Glc]_0"=1, "[X]_0"=1),
                                  "data_exp" = read.table("data_1mM.txt", header=TRUE, sep="\t"),
                                  "sd" = c("Ace"=0.2, "Glc"=0.5, "X"=0.045, "Ace_enr"=0.03),
                                  "mapping" = c("Ace"="Acet_out", "Glc"="Glc", "X"="X", "Ace_enr"="Values[Ace_enr]")),
                       "10" = list("initial_concentrations"= c("Ace0_out"=9, "Glc"=14.192, "X"=0.07),
                                   "species_idx" = c("[Ace0_out]_0"=2, "[Glc]_0"=2, "[X]_0"=2),
                                   "data_exp" = read.table("data_10mM.txt", header=TRUE, sep="\t"),
                                   "sd" = c("Ace"=0.2, "Glc"=0.5, "X"=0.045, "Ace_enr"=0.03),
                                   "mapping" = c("Ace"="Acet_out", "Glc"="Glc", "X"="X", "Ace_enr"="Values[Ace_enr]")),
                       "30" = list("initial_concentrations"= c("Ace0_out"=30.2448, "Glc"=12.5, "X"=0.07227),
                                   "species_idx" = c("[Ace0_out]_0"=3, "[Glc]_0"=3, "[X]_0"=3),
                                   "data_exp" = read.table("data_30mM.txt", header=TRUE, sep="\t"),
                                   "sd" = c("Ace"=0.2, "Glc"=0.5, "X"=0.045, "Ace_enr"=0.03),
                                   "mapping" = c("Ace"="Acet_out", "Glc"="Glc", "X"="X", "Ace_enr"="Values[Ace_enr]")),
                       "res_cost" = c(res_PE_model$main$objective_value),
                       "res_converged" = c(test_khi2(nb_points=152, k_val=res_PE_model$main$objective_value, nb_par=10)$`p-value, i.e. P(X^2<=value)` < 0.95))

# simulate data for the best fit
for (i in c("1", "10", "30")){
  # update initial conditions (Glc, Ace and biomass concentrations)
  for (j in names(fit_results_m1[[i]][["initial_concentrations"]])){
    setSpecies(key=j, initial_concentration=fit_results_m1[[i]][["initial_concentrations"]][j])
  }
  # apply initial state
  applyInitialState()
  # run time course simulation
  tmp <- as.matrix(runTimeCourse()$result)
  # get complete simulation results
  idx_t_max <- (tmp[,"Time"] <= max(fit_results_m1[[i]][["data_exp"]]$time))
  fit_results_m1[[i]]$simulations <- tmp[idx_t_max,]
  # get index of simulated data at experimental time points
  fit_results_m1[[i]]$t_idx <- match(fit_results_m1[[i]][["data_exp"]]$time, fit_results_m1[[i]]$simulations[,"Time"])
  # get simulated data that match experimental time points
  sim_data <- fit_results_m1[[i]][["data_exp"]]
  for (k in names(fit_results_m1[[i]][["mapping"]])){
    sim_data[,k] <- fit_results_m1[[i]]$simulations[fit_results_m1[[i]]$t_idx,fit_results_m1[[i]][["mapping"]][[k]]]
  }
  fit_results_m1[[i]]$sim <- sim_data
}

# Plot fitting results
setwd(results_dir)
pdf(file = "Figure 1-figure supplement 1.pdf", width = 7, height = 9)
par(mfrow=c(4,3))

plot_no_ci(fit_results_m1, "1", "X", col="#1F4E79", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="[biomass] (gDW/L)", xlab="", main="[acetate]=1mM")
plot_no_ci(fit_results_m1, "10", "X", col="#2E75B6", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="", xlab="", main="[acetate]=10mM")
plot_no_ci(fit_results_m1, "30", "X", col="#9DC3E6", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="", xlab="", main="[acetate]=30mM")

plot_no_ci(fit_results_m1, "1", "Glc", col="#548235", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,15), xaxs="i", yaxs="i", ylab="[Glc] (mM)", xlab="", main="")
plot_no_ci(fit_results_m1, "10", "Glc", col="#70AD47", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,15), xaxs="i", yaxs="i", ylab="", xlab="", main="")
plot_no_ci(fit_results_m1, "30", "Glc", col="#A9D18E", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,15), xaxs="i", yaxs="i", ylab="", xlab="", main="")

plot_no_ci(fit_results_m1, "1", "Ace", col="#B63A2D", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,5), xaxs="i", yaxs="i", ylab="[Ace] (mM)", xlab="", main="")
plot_no_ci(fit_results_m1, "10", "Ace", col="#D6685C", lwd=1.0, las=1, xlim=c(0,5), ylim=c(8,11), xaxs="i", yaxs="i", ylab="", xlab="", main="")
plot_no_ci(fit_results_m1, "30", "Ace", col="#E49890", lwd=1.0, las=1, xlim=c(0,5), ylim=c(25,32), xaxs="i", yaxs="i", ylab="", xlab="", main="")

plot_no_ci(fit_results_m1, "1", "Ace_enr", col="#BF9000", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="[Ace] (mM)", xlab="time (h)", main="")
plot_no_ci(fit_results_m1, "10", "Ace_enr", col="#FFD966", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,0.7), xaxs="i", yaxs="i", ylab="", xlab="time (h)", main="")
plot_no_ci(fit_results_m1, "30", "Ace_enr", col="#FFE699", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,0.3), xaxs="i", yaxs="i", ylab="", xlab="time (h)", main="")

dev.off()

# MODEL 2 #
###########

setwd(model_dir)
loadModel("Millard2020_Ecoli_glc_ace_model_2.cps")

# get parameters for the best fit
res_PE_model <- runParameterEstimation(method = "Statistics", model = getCurrentModel())

# list used to set up global sensitivity analysis and store calculation results
fit_results_m2 <- list("1" = list("initial_concentrations"= c("Ace0_out"=0.92, "Glc"=12.9, "X"=0.0671),
                                  "species_idx" = c("[Ace0_out]_0"=1, "[Glc]_0"=1, "[X]_0"=1),
                                  "data_exp" = read.table("data_1mM.txt", header=TRUE, sep="\t"),
                                  "sd" = c("Ace"=0.2, "Glc"=0.5, "X"=0.045, "Ace_enr"=0.03),
                                  "mapping" = c("Ace"="Acet_out", "Glc"="Glc", "X"="X", "Ace_enr"="Values[Ace_enr]")),
                       "10" = list("initial_concentrations"= c("Ace0_out"=9, "Glc"=14.192, "X"=0.07),
                                   "species_idx" = c("[Ace0_out]_0"=2, "[Glc]_0"=2, "[X]_0"=2),
                                   "data_exp" = read.table("data_10mM.txt", header=TRUE, sep="\t"),
                                   "sd" = c("Ace"=0.2, "Glc"=0.5, "X"=0.045, "Ace_enr"=0.03),
                                   "mapping" = c("Ace"="Acet_out", "Glc"="Glc", "X"="X", "Ace_enr"="Values[Ace_enr]")),
                       "30" = list("initial_concentrations"= c("Ace0_out"=30.2448, "Glc"=12.5, "X"=0.07227),
                                   "species_idx" = c("[Ace0_out]_0"=3, "[Glc]_0"=3, "[X]_0"=3),
                                   "data_exp" = read.table("data_30mM.txt", header=TRUE, sep="\t"),
                                   "sd" = c("Ace"=0.2, "Glc"=0.5, "X"=0.045, "Ace_enr"=0.03),
                                   "mapping" = c("Ace"="Acet_out", "Glc"="Glc", "X"="X", "Ace_enr"="Values[Ace_enr]")),
                       "res_cost" = c(res_PE_model$main$objective_value),
                       "res_converged" = c(test_khi2(nb_points=152, k_val=res_PE_model$main$objective_value, nb_par=10)$`p-value, i.e. P(X^2<=value)` < 0.95))

# simulate data for the best fit
for (i in c("1", "10", "30")){
  # update initial conditions (Glc, Ace and biomass concentrations)
  for (j in names(fit_results_m2[[i]][["initial_concentrations"]])){
    setSpecies(key=j, initial_concentration=fit_results_m2[[i]][["initial_concentrations"]][j])
  }
  # apply initial state
  applyInitialState()
  # run time course simulation
  tmp <- as.matrix(runTimeCourse()$result)
  # get complete simulation results
  idx_t_max <- (tmp[,"Time"] <= max(fit_results_m2[[i]][["data_exp"]]$time))
  fit_results_m2[[i]]$simulations <- tmp[idx_t_max,]
  # get index of simulated data at experimental time points
  fit_results_m2[[i]]$t_idx <- match(fit_results_m2[[i]][["data_exp"]]$time, fit_results_m2[[i]]$simulations[,"Time"])
  # get simulated data that match experimental time points
  sim_data <- fit_results_m2[[i]][["data_exp"]]
  for (k in names(fit_results_m2[[i]][["mapping"]])){
    sim_data[,k] <- fit_results_m2[[i]]$simulations[fit_results_m2[[i]]$t_idx,fit_results_m2[[i]][["mapping"]][[k]]]
  }
  fit_results_m2[[i]]$sim <- sim_data
}

# Plot fitting results
setwd(results_dir)
pdf(file = "Figure 1-figure supplement 2.pdf", width = 7, height = 9)
par(mfrow=c(4,3))

plot_no_ci(fit_results_m2, "1", "X", col="#1F4E79", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="[biomass] (gDW/L)", xlab="", main="[acetate]=1mM")
plot_no_ci(fit_results_m2, "10", "X", col="#2E75B6", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="", xlab="", main="[acetate]=10mM")
plot_no_ci(fit_results_m2, "30", "X", col="#9DC3E6", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="", xlab="", main="[acetate]=30mM")

plot_no_ci(fit_results_m2, "1", "Glc", col="#548235", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,15), xaxs="i", yaxs="i", ylab="[Glc] (mM)", xlab="", main="")
plot_no_ci(fit_results_m2, "10", "Glc", col="#70AD47", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,15), xaxs="i", yaxs="i", ylab="", xlab="", main="")
plot_no_ci(fit_results_m2, "30", "Glc", col="#A9D18E", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,15), xaxs="i", yaxs="i", ylab="", xlab="", main="")

plot_no_ci(fit_results_m2, "1", "Ace", col="#B63A2D", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,5), xaxs="i", yaxs="i", ylab="[Ace] (mM)", xlab="", main="")
plot_no_ci(fit_results_m2, "10", "Ace", col="#D6685C", lwd=1.0, las=1, xlim=c(0,5), ylim=c(8,11), xaxs="i", yaxs="i", ylab="", xlab="", main="")
plot_no_ci(fit_results_m2, "30", "Ace", col="#E49890", lwd=1.0, las=1, xlim=c(0,5), ylim=c(25,32), xaxs="i", yaxs="i", ylab="", xlab="", main="")

plot_no_ci(fit_results_m2, "1", "Ace_enr", col="#BF9000", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="[Ace] (mM)", xlab="time (h)", main="")
plot_no_ci(fit_results_m2, "10", "Ace_enr", col="#FFD966", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,0.7), xaxs="i", yaxs="i", ylab="", xlab="time (h)", main="")
plot_no_ci(fit_results_m2, "30", "Ace_enr", col="#FFE699", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,0.3), xaxs="i", yaxs="i", ylab="", xlab="time (h)", main="")

dev.off()

###########
# MODEL 3 #
###########

setwd(model_dir)
loadModel("Millard2020_Ecoli_glc_ace_model_3.cps")

# get parameters for the best fit
res_PE_model <- runParameterEstimation(method = "Statistics", model = getCurrentModel())

# list used to set up global sensitivity analysis and store calculation results
fit_results_m3 <- list("1" = list("initial_concentrations"= c("Ace0_out"=0.92, "Glc"=12.9, "X"=0.0671),
                                  "species_idx" = c("[Ace0_out]_0"=1, "[Glc]_0"=1, "[X]_0"=1),
                                  "data_exp" = read.table("data_1mM.txt", header=TRUE, sep="\t"),
                                  "sd" = c("Ace"=0.2, "Glc"=0.5, "X"=0.045, "Ace_enr"=0.03),
                                  "mapping" = c("Ace"="Acet_out", "Glc"="Glc", "X"="X", "Ace_enr"="Values[Ace_enr]")),
                       "10" = list("initial_concentrations"= c("Ace0_out"=9, "Glc"=14.192, "X"=0.07),
                                   "species_idx" = c("[Ace0_out]_0"=2, "[Glc]_0"=2, "[X]_0"=2),
                                   "data_exp" = read.table("data_10mM.txt", header=TRUE, sep="\t"),
                                   "sd" = c("Ace"=0.2, "Glc"=0.5, "X"=0.045, "Ace_enr"=0.03),
                                   "mapping" = c("Ace"="Acet_out", "Glc"="Glc", "X"="X", "Ace_enr"="Values[Ace_enr]")),
                       "30" = list("initial_concentrations"= c("Ace0_out"=30.2448, "Glc"=12.5, "X"=0.07227),
                                   "species_idx" = c("[Ace0_out]_0"=3, "[Glc]_0"=3, "[X]_0"=3),
                                   "data_exp" = read.table("data_30mM.txt", header=TRUE, sep="\t"),
                                   "sd" = c("Ace"=0.2, "Glc"=0.5, "X"=0.045, "Ace_enr"=0.03),
                                   "mapping" = c("Ace"="Acet_out", "Glc"="Glc", "X"="X", "Ace_enr"="Values[Ace_enr]")),
                       "res_cost" = c(res_PE_model$main$objective_value),
                       "res_converged" = c(test_khi2(nb_points=152, k_val=res_PE_model$main$objective_value, nb_par=10)$`p-value, i.e. P(X^2<=value)` < 0.95))

# simulate data for the best fit
for (i in c("1", "10", "30")){
  # update initial conditions (Glc, Ace and biomass concentrations)
  for (j in names(fit_results_m3[[i]][["initial_concentrations"]])){
    setSpecies(key=j, initial_concentration=fit_results_m3[[i]][["initial_concentrations"]][j])
  }
  # apply initial state
  applyInitialState()
  # run time course simulation
  tmp <- as.matrix(runTimeCourse()$result)
  # get complete simulation results
  idx_t_max <- (tmp[,"Time"] <= max(fit_results_m3[[i]][["data_exp"]]$time))
  fit_results_m3[[i]]$simulations <- tmp[idx_t_max,]
  # get index of simulated data at experimental time points
  fit_results_m3[[i]]$t_idx <- match(fit_results_m3[[i]][["data_exp"]]$time, fit_results_m3[[i]]$simulations[,"Time"])
  # get simulated data that match experimental time points
  sim_data <- fit_results_m3[[i]][["data_exp"]]
  for (k in names(fit_results_m3[[i]][["mapping"]])){
    sim_data[,k] <- fit_results_m3[[i]]$simulations[fit_results_m3[[i]]$t_idx,fit_results_m3[[i]][["mapping"]][[k]]]
  }
  fit_results_m3[[i]]$sim <- sim_data
}

# Plot fitting results
setwd(results_dir)
pdf(file = "Figure 1-figure supplement 3.pdf", width = 7, height = 9)
par(mfrow=c(4,3))

plot_no_ci(fit_results_m3, "1", "X", col="#1F4E79", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="[biomass] (gDW/L)", xlab="", main="[acetate]=1mM")
plot_no_ci(fit_results_m3, "10", "X", col="#2E75B6", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="", xlab="", main="[acetate]=10mM")
plot_no_ci(fit_results_m3, "30", "X", col="#9DC3E6", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="", xlab="", main="[acetate]=30mM")

plot_no_ci(fit_results_m3, "1", "Glc", col="#548235", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,15), xaxs="i", yaxs="i", ylab="[Glc] (mM)", xlab="", main="")
plot_no_ci(fit_results_m3, "10", "Glc", col="#70AD47", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,15), xaxs="i", yaxs="i", ylab="", xlab="", main="")
plot_no_ci(fit_results_m3, "30", "Glc", col="#A9D18E", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,15), xaxs="i", yaxs="i", ylab="", xlab="", main="")

plot_no_ci(fit_results_m3, "1", "Ace", col="#B63A2D", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,5), xaxs="i", yaxs="i", ylab="[Ace] (mM)", xlab="", main="")
plot_no_ci(fit_results_m3, "10", "Ace", col="#D6685C", lwd=1.0, las=1, xlim=c(0,5), ylim=c(8,11), xaxs="i", yaxs="i", ylab="", xlab="", main="")
plot_no_ci(fit_results_m3, "30", "Ace", col="#E49890", lwd=1.0, las=1, xlim=c(0,5), ylim=c(25,32), xaxs="i", yaxs="i", ylab="", xlab="", main="")

plot_no_ci(fit_results_m3, "1", "Ace_enr", col="#BF9000", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="[Ace] (mM)", xlab="time (h)", main="")
plot_no_ci(fit_results_m3, "10", "Ace_enr", col="#FFD966", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,0.7), xaxs="i", yaxs="i", ylab="", xlab="time (h)", main="")
plot_no_ci(fit_results_m3, "30", "Ace_enr", col="#FFE699", lwd=1.0, las=1, xlim=c(0,5), ylim=c(0,0.3), xaxs="i", yaxs="i", ylab="", xlab="time (h)", main="")

dev.off()

##############################################
# MODEL 4 - with global sensitivity analysis #
##############################################

setwd(model_dir)
loadModel("Millard2020_Ecoli_glc_ace_model_4_MC.cps")

# create calibration data files for monte carlo simulations
file.copy("data_1mM.txt", "data_1mM_MC.txt", overwrite=TRUE)
file.copy("data_10mM.txt", "data_10mM_MC.txt", overwrite=TRUE)
file.copy("data_30mM.txt", "data_30mM_MC.txt", overwrite=TRUE)

# number of Monte Carlo iterations
n_iter_mc <- 10

# get parameters for the best fit
res_PE_model4 <- runParameterEstimation(method = "Statistics", model = getCurrentModel())

# list used to set up global sensitivity analysis and store calculation results
fit_results <- list("1" = list("initial_concentrations"= c("Ace0_out"=0.92, "Glc"=12.9, "X"=0.0671),
                               "species_idx" = c("[Ace0_out]_0"=1, "[Glc]_0"=1, "[X]_0"=1),
                               "data_exp" = read.table("data_1mM.txt", header=TRUE, sep="\t"),
                               "sd" = c("Ace"=0.2, "Glc"=0.5, "X"=0.045, "Ace_enr"=0.03),
                               "mapping" = c("Ace"="Acet_out", "Glc"="Glc", "X"="X", "Ace_enr"="Values[Ace_enr]")),
                    "10" = list("initial_concentrations"= c("Ace0_out"=9, "Glc"=14.192, "X"=0.07),
                                "species_idx" = c("[Ace0_out]_0"=2, "[Glc]_0"=2, "[X]_0"=2),
                                "data_exp" = read.table("data_10mM.txt", header=TRUE, sep="\t"),
                                "sd" = c("Ace"=0.2, "Glc"=0.5, "X"=0.045, "Ace_enr"=0.03),
                                "mapping" = c("Ace"="Acet_out", "Glc"="Glc", "X"="X", "Ace_enr"="Values[Ace_enr]")),
                    "30" = list("initial_concentrations"= c("Ace0_out"=30.2448, "Glc"=12.5, "X"=0.07227),
                                "species_idx" = c("[Ace0_out]_0"=3, "[Glc]_0"=3, "[X]_0"=3),
                                "data_exp" = read.table("data_30mM.txt", header=TRUE, sep="\t"),
                                "sd" = c("Ace"=0.2, "Glc"=0.5, "X"=0.045, "Ace_enr"=0.03),
                                "mapping" = c("Ace"="Acet_out", "Glc"="Glc", "X"="X", "Ace_enr"="Values[Ace_enr]")),
                    "res_par" = res_PE_model4$parameters[, c("parameter", "value")],
                    "res_cost" = c(res_PE_model4$main$objective_value),
                    "res_converged" = c(test_khi2(nb_points=152, k_val=res_PE_model4$main$objective_value, nb_par=10)$`p-value, i.e. P(X^2<=value)` < 0.95))

# simulate data for the best fit
for (i in c("1", "10", "30")){
  # update initial conditions (Glc, Ace and biomass concentrations)
  for (j in names(fit_results[[i]][["initial_concentrations"]])){
    setSpecies(key=j, initial_concentration=fit_results[[i]][["initial_concentrations"]][j])
  }
  # apply initial state
  applyInitialState()
  # run time course simulation
  tmp <- as.matrix(runTimeCourse()$result)
  # get complete simulation results
  idx_t_max <- (tmp[,"Time"] <= max(fit_results[[i]][["data_exp"]]$time))
  fit_results[[i]]$simulations <- array(NA, dim=c(n_iter_mc+1, sum(idx_t_max), ncol(tmp)), dimnames=list(iter=NULL, time=NULL, specie=colnames(tmp)))
  fit_results[[i]]$simulations[1,,] <- tmp[idx_t_max,]
  # get index of simulated data at experimental time points
  fit_results[[i]]$t_idx <- match(fit_results[[i]][["data_exp"]]$time, fit_results[[i]]$simulations[1,,"Time"])
  # get simulated data that match experimental time points
  sim_data <- fit_results[[i]][["data_exp"]]
  for (k in names(fit_results[[i]][["mapping"]])){
    sim_data[,k] <- fit_results[[i]]$simulations[1,fit_results[[i]]$t_idx,fit_results[[i]][["mapping"]][[k]]]
  }
  fit_results[[i]]$sim_mc <- sim_data
}

# create progress bar
pb <- txtProgressBar(min=0, max=n_iter_mc, style=3)

# run global sensitivity analysis
j <- 0
while (j < n_iter_mc){
  
  # generate noisy datasets according to the experimental standard deviation
  for (i in c("1", "10", "30")){
    # initialize dataset with simulations of the best fit
    data_noise <- fit_results[[i]]$sim_mc
    nr <- nrow(data_noise)
    # add noise
    for (k in names(fit_results[[i]]$sd)){
      data_noise[,k] <- rnorm(nr, mean=data_noise[,k], sd=fit_results[[i]]$sd[[k]])
    }
    # set negative concentrations to 0
    data_noise[data_noise < 0] <- 0
    # save the noisy dataset
    write.table(data_noise, paste("data_", i, "mM_MC.txt", sep=""), sep="\t", row.names = FALSE, quote = FALSE)
  }
  
  # run parameter estimation (SRES followed by Hooke and Jeeves and Levenberg-Marquadt methods to refine convergence)
  # note: this protocol ensures faster convergence in comparison to PSO, which is necessary for monte carlo analysis
  res_PE_tmp <- runParameterEstimation(method = "SRES", randomize_start_values=TRUE, update_model=TRUE)
  res_PE_tmp <- runParameterEstimation(method = "HookeJeeves", randomize_start_values=FALSE, update_model=TRUE)
  res_PE_tmp <- runParameterEstimation(method = "LevenbergMarquardt", randomize_start_values=FALSE, update_model=TRUE)
  
  # check if optimization has converged, reiterate if not
  p_val_chi2 <- test_khi2(nb_points=152, k_val=res_PE_tmp$main$objective_value, nb_par=10)$`p-value, i.e. P(X^2<=value)`
  if (p_val_chi2 < 0.95){
    j = j+1
  }else{
    next
  }
  
  # update the progress bar
  setTxtProgressBar(pb, j)
  
  # save parameter estimation results
  fit_results$res_par <- cbind(fit_results$res_par, res_PE_tmp$parameters[, "value"])
  fit_results$res_cost <- c(fit_results$res_cost, res_PE_tmp$main$objective_value)
  fit_results$res_converged <- c(fit_results$res_converged, p_val_chi2 < 0.95)
  
  # simulate all experiments
  for (i in c("1", "10", "30")){
    # update experiment-dependent parameters
    for (l in names(fit_results[[i]]$species_idx)){
      idx <- which(res_PE_tmp$parameters$parameter==l)[fit_results[[i]]$species_idx[l]]
      k <- sub(".*\\[(.*)\\].*", "\\1", l, perl=TRUE)
      setSpecies(key=k, initial_concentration=as.numeric(res_PE_tmp$parameters[idx,"value"]))
    }
    # apply initial state
    applyInitialState()
    # run time course simulations
    tmp <- as.matrix(runTimeCourse()$result)
    # get complete simulation results
    fit_results[[i]]$simulations[j+1,,] <- tmp[tmp[,"Time"] <= max(fit_results[[i]][["data_exp"]]$time),]
  }
}

# close progress bar
close(pb)

# save global sensitivity analysis results for further use
setwd(results_dir)
save(fit_results, file = "mc_results_10.RData")

# load global sensitivity analysis results
# (here we use results obtained with 100 iterations)
load("mc_results_100.RData")

# Calculate statistics on parameters (mean, sd, rsd)
res_stats_params <- get_parameters_stats(fit_results)
print(res_stats_params)
write.table(res_stats_params, "parameters_stats.txt", sep="\t", quote = FALSE)

# Plot fitting results
pdf(file = "Figure 1C.pdf", width = 7, height = 9)
par(mfrow=c(4,3))

plot_with_ci(fit_results, "1", "X", col="#1F4E79", lwd=1.2, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="[biomass] (gDW/L)", xlab="", main="[acetate]=1mM")
plot_with_ci(fit_results, "10", "X", col="#2E75B6", lwd=1.2, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="", xlab="", main="[acetate]=10mM")
plot_with_ci(fit_results, "30", "X", col="#9DC3E6", lwd=1.2, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="", xlab="", main="[acetate]=30mM")

plot_with_ci(fit_results, "1", "Glc", col="#548235", lwd=1.2, las=1, xlim=c(0,5), ylim=c(0,15), xaxs="i", yaxs="i", ylab="[Glc] (mM)", xlab="", main="")
plot_with_ci(fit_results, "10", "Glc", col="#70AD47", lwd=1.2, las=1, xlim=c(0,5), ylim=c(0,15), xaxs="i", yaxs="i", ylab="", xlab="", main="")
plot_with_ci(fit_results, "30", "Glc", col="#A9D18E", lwd=1.2, las=1, xlim=c(0,5), ylim=c(0,15), xaxs="i", yaxs="i", ylab="", xlab="", main="")

plot_with_ci(fit_results, "1", "Ace", col="#B63A2D", lwd=1.2, las=1, xlim=c(0,5), ylim=c(0,5), xaxs="i", yaxs="i", ylab="[Ace] (mM)", xlab="", main="")
plot_with_ci(fit_results, "10", "Ace", col="#D6685C", lwd=1.2, las=1, xlim=c(0,5), ylim=c(8,11), xaxs="i", yaxs="i", ylab="", xlab="", main="")
plot_with_ci(fit_results, "30", "Ace", col="#E49890", lwd=1.2, las=1, xlim=c(0,5), ylim=c(27,32), xaxs="i", yaxs="i", ylab="", xlab="", main="")

plot_with_ci(fit_results, "1", "Ace_enr", col="#BF9000", lwd=1.2, las=1, xlim=c(0,5), ylim=c(0,1), xaxs="i", yaxs="i", ylab="[Ace] (mM)", xlab="time (h)", main="")
plot_with_ci(fit_results, "10", "Ace_enr", col="#FFD966", lwd=1.2, las=1, xlim=c(0,5), ylim=c(0,0.7), xaxs="i", yaxs="i", ylab="", xlab="time (h)", main="")
plot_with_ci(fit_results, "30", "Ace_enr", col="#FFE699", lwd=1.2, las=1, xlim=c(0,5), ylim=c(0,0.3), xaxs="i", yaxs="i", ylab="", xlab="time (h)", main="")

dev.off()


