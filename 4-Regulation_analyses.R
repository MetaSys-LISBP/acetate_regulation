

###################
# Set environment #
###################

# load libraries and initialize environment
source("set_env.R")


############################################
# Load global sensitivity analysis results #
############################################

# This file is generated by script "1-Model_construction.R".
setwd(results_dir)
load("mc_results_100.RData")


#################################
# Metabolic regulation analyses #
#################################

setwd(model_dir)
loadModel("Millard2020_Ecoli_glc_ace_kinetic_model.cps")
setwd(results_dir)
# delete events and fix concentrations of biomass and extracellular glc and acetate
deleteEvent(getEvents()$key)
setSpecies(key="Ace_out", type="fixed")
setSpecies(key="Glc", type="fixed")
setSpecies(key="X", type="fixed")

n_step <- 300
delta_p <- 0.001
conc_threshold <- 14.27174
ace_range <- 10**(seq(-1, 2, length.out = n_step))
ace_range <- ace_range[abs(ace_range - conc_threshold) > 0.1]

res_reg <- array(NA, dim=c(ncol(fit_results$res_par)-1, length(ace_range), 4), dimnames=list(iter=NULL, r=NULL, c=c("ace_conc", "via_acetate_pathway", "via_glc_upt", "via_tca")))

# create progress bar
pb <- txtProgressBar(min=0, max=ncol(fit_results$res_par)-1, style=3)

for (j in seq(ncol(fit_results$res_par)-1)){
  
  res_ace_regulation <- matrix(NA, nrow=length(ace_range), ncol=4, dimnames=list(r=NULL, c=c("ace_conc", "via_acetate_pathway", "via_glc_upt", "via_tca")))
  
  for (i in seq(length(ace_range))){
    
    rp <- c(fit_results$res_par[,j+1])
    names(rp) <- fit_results$res_par[,"parameter"]
    model <- update_params(getCurrentModel(), rp)
    
    # set ace concentration
    setSpecies(key="Ace_out{cell}", initial_concentration = ace_range[i], model=model)
    applyInitialState(model=model)
    
    # get steady-state
    res_ss_i <- runSteadyState(update_model=TRUE, model=model)$global_quantities
    
    # calculate control coefficients
    res_MCA_R <- runMCA(model=model)$flux_control_coefficients_scaled
    
    # calculate elasticities
    
    # fix acetylCoA concentration to calculate elasticity of each pathway wrt acetate
    setSpecies(key="AcCoA", type="fixed", model=model)
    
    # change acetate concentration
    setSpecies(key="Ace_out{cell}", initial_concentration = ace_range[i]*(1+delta_p), model=model)
    applyInitialState(model=model)
    
    # get steady-state
    res_ss_i_eps <- runSteadyState(model=model)$global_quantities
    
    # calculate elasticities (using the more stable numerical method, both being equivalent)
    #elasticities <- (log(abs(res_ss_i_eps$value)) - log(abs(res_ss_i$value))) / log(1+delta_p)
    #print(elasticities)
    elasticities <- (res_ss_i_eps$value - res_ss_i$value) / delta_p / res_ss_i_eps$value
    #print(elasticities)
    
    # reset balance on accoa
    setSpecies(key="AcCoA", type="reactions", model=model)
    
    # calculate response coefficient
    # acetate via Pta-AckA
    res_reg_ace_ace <- sum(res_MCA_R["(ackA)", c("(ackA)", "(pta)", "(ace_xch)")]) * elasticities[res_ss_i_eps$key == "Values[v_ace_net]"]
    # acetate via glc uptake
    res_reg_ace_glc <- res_MCA_R["(ackA)", "(glc_upt)"] * elasticities[res_ss_i_eps$key == "Values[v_glc_uptake]"]
    # acetate via sink
    res_reg_ace_tca <- res_MCA_R["(ackA)", "(sink)"] * elasticities[res_ss_i_eps$key == "Values[v_growth_rate]"]
    
    res_ace_regulation[i,] <- c(ace_range[i], res_reg_ace_ace, res_reg_ace_glc, res_reg_ace_tca)
  }
  
  # save results
  res_reg[j,,] <- res_ace_regulation
  
  # update the progress bar
  setTxtProgressBar(pb, j)
}

# close progress bar
close(pb)

# plot regulation results
pdf(file="Figure 6.pdf", width = 7, height = 9)
par(mfrow=c(4,3))

xlab_main <- c(0.1, 1, 10, 100)
xlab_sec <- c(seq(0.2, 0.9, by=0.1), seq(2, 9, by=1), seq(20, 90, by=10))
conc_threshold <- 14.5


# plot partitioned response coefficients
fconc_max <- 1.12
fconc_min <- 0.82
lines_threshold(ace_range, apply(res_reg[,,"via_acetate_pathway"], 2, median), threshold=conc_threshold, new=TRUE, xaxt="n", las=1, xaxs="i", yaxs="i", col="#2E75B6", xlim=c(0.1,100), type="l", log="x", ylim=c(-5, 5), xlab="[acetate] (mM)", ylab="R_ace_pathway", lwd=1.2)
polygon(x=c(ace_range[ace_range < conc_threshold*fconc_min], rev(ace_range[ace_range < conc_threshold*fconc_min])),
        y=c(apply(res_reg[,ace_range < conc_threshold*fconc_min,"via_acetate_pathway"], 2, max), rev(apply(res_reg[,ace_range < conc_threshold*fconc_min,"via_acetate_pathway"], 2, min))),
        col="#2E75B655", border=NA)
polygon(x=c(ace_range[ace_range > conc_threshold*fconc_max], rev(ace_range[ace_range > conc_threshold*fconc_max])),
        y=c(apply(res_reg[,ace_range > conc_threshold*fconc_max,"via_acetate_pathway"], 2, max), rev(apply(res_reg[,ace_range > conc_threshold*fconc_max,"via_acetate_pathway"], 2, min))),
        col="#2E75B655", border=NA)
axis(side = 1, at = xlab_main, labels = TRUE)
axis(side = 1, at = xlab_sec, labels = FALSE, tcl=-0.3)
abline(h=0)

fconc_max <- 1.12
fconc_min <- 0.84
lines_threshold(ace_range, apply(res_reg[,,"via_glc_upt"], 2, median), threshold=conc_threshold, new=TRUE, xaxt="n", las=1, xaxs="i", yaxs="i", col="#D6685C", xlim=c(0.1,100), type="l", log="x", ylim=c(-5, 5), xlab="[acetate] (mM)", ylab="R_Glc_uptake", lwd=1.2)
polygon(x=c(ace_range[ace_range < conc_threshold*fconc_min], rev(ace_range[ace_range < conc_threshold*fconc_min])),
        y=c(apply(res_reg[,ace_range < conc_threshold*fconc_min,"via_glc_upt"], 2, max), rev(apply(res_reg[,ace_range < conc_threshold*fconc_min,"via_glc_upt"], 2, min))),
        col="#D6685C55", border=NA)
polygon(x=c(ace_range[ace_range > conc_threshold*fconc_max], rev(ace_range[ace_range > conc_threshold*fconc_max])),
        y=c(apply(res_reg[,ace_range > conc_threshold*fconc_max,"via_glc_upt"], 2, max), rev(apply(res_reg[,ace_range > conc_threshold*fconc_max,"via_glc_upt"], 2, min))),
        col="#D6685C55", border=NA)
axis(side = 1, at = xlab_main, labels = TRUE)
axis(side = 1, at = xlab_sec, labels = FALSE, tcl=-0.3)
abline(h=0)

lines_threshold(ace_range, apply(res_reg[,,"via_tca"], 2, median), threshold=conc_threshold, new=TRUE, xaxt="n", las=1, xaxs="i", yaxs="i", col="#70AD47", xlim=c(0.1,100), type="l", log="x", ylim=c(-5, 5), xlab="[acetate] (mM)", ylab="R_TCA", lwd=1.2)
polygon(x=c(ace_range[ace_range < conc_threshold*fconc_min], rev(ace_range[ace_range < conc_threshold*fconc_min])),
        y=c(apply(res_reg[,ace_range < conc_threshold*fconc_min,"via_tca"], 2, max), rev(apply(res_reg[,ace_range < conc_threshold*fconc_min,"via_tca"], 2, min))),
        col="#70AD4755", border=NA)
polygon(x=c(ace_range[ace_range > conc_threshold*fconc_max], rev(ace_range[ace_range > conc_threshold*fconc_max])),
        y=c(apply(res_reg[,ace_range > conc_threshold*fconc_max,"via_tca"], 2, max), rev(apply(res_reg[,ace_range > conc_threshold*fconc_max,"via_tca"], 2, min))),
        col="#70AD4755", border=NA)
axis(side = 1, at = xlab_main, labels = TRUE)
axis(side = 1, at = xlab_sec, labels = FALSE, tcl=-0.3)
abline(h=0)

# plot contribution of each pathway
fconc_max <- 1.14
fconc_min <- 0.84
contributio_ace <- res_reg[,,"via_acetate_pathway"]/apply(res_reg[,,2:4], 1:2, FUN=function(x) sum(abs(x)))
lines_threshold(ace_range, apply(contributio_ace, 2, median), threshold=conc_threshold, new=TRUE, xaxt="n", las=1, xaxs="i", yaxs="i", xlim=c(0.1,100), type="l", log="x", xlab="[acetate] (mM)", ylab="relative_R", ylim=c(-0.7, 0.7), lwd=1.2, col="#2E75B6")
polygon(x=c(ace_range[ace_range < conc_threshold*fconc_min], rev(ace_range[ace_range < conc_threshold*fconc_min])),
        y=c(apply(contributio_ace[,ace_range < conc_threshold*fconc_min], 2, max), rev(apply(contributio_ace[,ace_range < conc_threshold*fconc_min], 2, min))),
        col="#2E75B655", border=NA)
polygon(x=c(ace_range[ace_range > conc_threshold*fconc_max], rev(ace_range[ace_range > conc_threshold*fconc_max])),
        y=c(apply(contributio_ace[,ace_range > conc_threshold*fconc_max], 2, max), rev(apply(contributio_ace[,ace_range > conc_threshold*fconc_max], 2, min))),
        col="#2E75B655", border=NA)
axis(side = 1, at = xlab_main, labels = TRUE)
axis(side = 1, at = xlab_sec, labels = FALSE, tcl=-0.3)
abline(h=0)
contributio_glc_upt <- res_reg[,,"via_glc_upt"]/apply(res_reg[,,2:4], 1:2, FUN=function(x) sum(abs(x)))
lines_threshold(ace_range, apply(contributio_glc_upt, 2, median), threshold=conc_threshold, new=FALSE, type="l", col="#D6685C", lwd=1.2)
polygon(x=c(ace_range[ace_range < conc_threshold*fconc_min], rev(ace_range[ace_range < conc_threshold*fconc_min])),
        y=c(apply(contributio_glc_upt[,ace_range < conc_threshold*fconc_min], 2, max), rev(apply(contributio_glc_upt[,ace_range < conc_threshold*fconc_min], 2, min))),
        col="#D6685C55", border=NA)
polygon(x=c(ace_range[ace_range > conc_threshold*fconc_max], rev(ace_range[ace_range > conc_threshold*fconc_max])),
        y=c(apply(contributio_glc_upt[,ace_range > conc_threshold*fconc_max], 2, max), rev(apply(contributio_glc_upt[,ace_range > conc_threshold*fconc_max], 2, min))),
        col="#D6685C55", border=NA)
contributio_tca <- res_reg[,,"via_tca"]/apply(res_reg[,,2:4], 1:2, FUN=function(x) sum(abs(x)))
lines_threshold(ace_range, apply(contributio_tca, 2, median), threshold=conc_threshold, new=FALSE, type="l", col="#70AD47", lwd=1.2)
polygon(x=c(ace_range[ace_range < conc_threshold*fconc_min], rev(ace_range[ace_range < conc_threshold*fconc_min])),
        y=c(apply(contributio_tca[,ace_range < conc_threshold*fconc_min], 2, max), rev(apply(contributio_tca[,ace_range < conc_threshold*fconc_min], 2, min))),
        col="#70AD4755", border=NA)
polygon(x=c(ace_range[ace_range > conc_threshold*fconc_max], rev(ace_range[ace_range > conc_threshold*fconc_max])),
        y=c(apply(contributio_tca[,ace_range > conc_threshold*fconc_max], 2, max), rev(apply(contributio_tca[,ace_range > conc_threshold*fconc_max], 2, min))),
        col="#70AD4755", border=NA)

dev.off()


