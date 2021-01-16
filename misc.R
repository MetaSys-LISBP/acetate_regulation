library(RColorBrewer)
library(gplots)
library(CoRC)
library(stringr)

test_khi2 <- function(nb_points, k_val, nb_par){
  # Perform Khi2 statistical test.
  #
  # Args:
  #   nb_points (int): number of data points
  #   k_val (float): khi2 value (cost)
  #   nb_par (int): number of free parameters
  #
  # Returns (list):
  #   $'khi2 value' (float): khi2 value (cost)
  #   $'data points' (int): number of data points
  #   $'fitted parameters' (int): number of free parameters
  #   $'degrees of freedom' (int): degrees of freedom
  #   $'khi2 reduced value' (float): chi2 reduced value
  #   $'p-value, i.e. P(X^2<=value)' (float): p value
  #   $conclusion (str): message indicating whether the models fits (or not) the data at 95% confidence interval
  #
  df <- nb_points - nb_par
  p_val <- pchisq(k_val, df=df)
  khi2test <- list("khi2 value"                  = k_val,
                   "data points"                 = nb_points,
                   "fitted parameters"           = nb_par,
                   "degrees of freedom"          = df,
                   "khi2 reduced value"          = k_val/df,
                   "p-value, i.e. P(X^2<=value)" = p_val)
  if (p_val > 0.95){
    khi2test$conclusion <- "At level of 95% confidence, the model does not fit the data good enough with respect to the provided measurement SD."
  }else{
    khi2test$conclusion <- "At level of 95% confidence, the model fits the data good enough with respect to the provided measurement SD."
  }
  return(khi2test)
}

plot_points <- function(x, y, sd, col="black", offset=1.5, mode="v", cex=1){
  # Scatterplot with error bars.
  #
  # Args:
  #   x (vector): x coordinates
  #   y (vector): y coordinates
  #   sd (vector): error bars
  #   col (color code): color of points
  #   offset (float): width (or height if mode = 'v') of error bars
  #   mode ('v' or 'h'): errors of y (if mode='v') or x (if mode='h')
  #
  if (mode == "v"){
    segments(x0=x, y0=y-sd, x1=x, y1=y+sd) 
    segments(x0=x-offset, y0=y+sd, x1=x+offset, y1=y+sd) 
    segments(x0=x-offset, y0=y-sd, x1=x+offset, y1=y-sd) 
  }else if (mode == "h"){
    segments(x0=x-sd, y0=y, x1=x+sd, y1=y) 
    segments(x0=x+sd, y0=y-offset, x1=x+sd, y1=y+offset) 
    segments(x0=x-sd, y0=y-offset, x1=x-sd, y1=y+offset) 
  }
  points(x, y, pch=21, bg=col, col="black", cex=cex)
}

lines_threshold <- function(x, y, threshold, new, ...){
  # Split data according to a given threshold, and plot lines for
  # each set.
  #
  # Args:
  #   x (vector): x coordinates
  #   y (vector): y coordinates
  #   threshold (float): value of x at which lines should not
  #                      be connected
  #   new (bool): create a new plot if TRUE, otherwise add
  #               lines to an existing plot
  #
  id_1 <- (x < threshold)
  id_2 <- (x > threshold)
  if (new){
    plot(x[id_1], y[id_1], ...)
  }else{
    suppressWarnings(lines(x[id_1], y[id_1], ...))
  }
  suppressWarnings(lines(x[id_2], y[id_2], ...))
}

get_parameters_stats <- function(fit_results){
  li <- grep("]_0", fit_results$res_par$parameter, fixed=TRUE, invert=TRUE)
  tmp <- matrix(NA, nrow=length(li), ncol=6, dimnames=list(par=fit_results$res_par$parameter[li], stats=c("mean", "median", "ci95_lb", "ci95_up", "sd", "rsd")))
  for (i in li){
    data <- as.numeric(unlist(fit_results$res_par[i,-1]))
    tmp[fit_results$res_par[i,1],] <- c(mean(data), median(data), quantile(data, probs = c(0.025, 0.975)), sd(data), sd(data)/mean(data))
  }
  return(tmp)
}

update_params <- function(model, rp){
  setCurrentModel(model)
  for (i in names(rp)){
    if (grepl("_0", i, fixed = TRUE)){
      next
    }else if (grepl(".InitialValue", i, fixed = TRUE)){
      k <- str_remove(i, ".InitialValue")
      #print(getGlobalQuantities(key=k))
      setGlobalQuantities(key=k, initial_value=rp[i])
      #print(getGlobalQuantities(key=k))
    }else{
      #print(getParameters(key=i))
      setParameters(key=i, value=rp[i])
      #print(getParameters(key=i))
    }
  }
  applyInitialState()
  return(model)
}

plot_with_ci <- function(fit_results, cond, specie, col, ...){
  if (specie %in% dimnames(fit_results[[cond]]$simulations)$specie){
    specie_id <- specie
  }else{
    specie_id <- fit_results[[cond]]$mapping[specie]
  }
  plot(fit_results[[cond]]$simulations[1,,"Time"], apply(fit_results[[cond]]$simulations[,,specie_id], 2, mean), col=col, type="l", ...)
  #polygon(x=c(fit_results[[cond]]$simulations[1,,"Time"], rev(fit_results[[cond]]$simulations[1,,"Time"])),
  #        y=c(apply(fit_results[[cond]]$simulations[,,specie_id], 2, max), rev(apply(fit_results[[cond]]$simulations[,,specie_id], 2, min))),
  #        col=paste(col, "33", sep=""), border=NA)
  polygon(x=c(fit_results[[cond]]$simulations[1,,"Time"], rev(fit_results[[cond]]$simulations[1,,"Time"])),
          y=c(apply(fit_results[[cond]]$simulations[,,specie_id], 2, max), rev(apply(fit_results[[cond]]$simulations[,,specie_id], 2, min))),
          col=paste(col, "55", sep=""), border=NA)
  plot_points(fit_results[[cond]]$data_exp$time,
              fit_results[[cond]]$data_exp[, specie],
              fit_results[[cond]]$sd[specie], offset=0.03, col=col, cex=1.2)
}

plot_with_ci_2 <- function(x1, y1, y2, x2, y3, sd_y3, col, h=NULL, ...){
  plot(x1, y1, type="l", col=col, ...)
  if (!is.null(h)){
    abline(h=h)
  }
  polygon(x=c(x1, rev(x1)),
          y=c(apply(y2, 2, max), rev(apply(y2, 2, min))),
          col=paste(col, "55", sep=""), border=NA)
  plot_points(x2, y3, sd_y3, offset=0.002, col=col)
}

plot_with_ci_3 <- function(sim_results, x, specie, col, ...){
  plot(sim_results[1,,x], apply(sim_results[,,specie], 2, mean), col=col, type="l", ...)
  polygon(x=c(sim_results[1,,x], rev(sim_results[1,,x])),
          y=c(apply(sim_results[,,specie], 2, max), rev(apply(sim_results[,,specie], 2, min))),
          col=paste(col, "55", sep=""), border=NA)
}

plot_no_ci <- function(fit_results, cond, specie, col, ...){
  if (specie %in% dimnames(fit_results[[cond]]$simulations)$specie){
    specie_id <- specie
  }else{
    specie_id <- fit_results[[cond]]$mapping[specie]
  }
  plot(fit_results[[cond]]$simulations[,"Time"], fit_results[[cond]]$simulations[,specie_id], col=col, type="l", ...)
  plot_points(fit_results[[cond]]$data_exp$time,
              fit_results[[cond]]$data_exp[, specie],
              fit_results[[cond]]$sd[specie], offset=0.03, col=col, cex=1.2)
}

get_index_closest <- function(x, v){
  idx <- c()
  for (i in x){
    idx <- c(idx, which.min(abs(v - i)))
  }
  return(idx)
}
