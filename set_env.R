####################################
# Supplementary information folder #
####################################

# We assume to be already in the working directory, otherwise update the path of the supplementary data folder
wd <- getwd()
#wd <- "C:/Users/millard/Documents/GIT/acetate_regulation/acetate_regulation/"

model_dir <- file.path(wd, "model", "cps")
results_dir <- file.path(wd, "results")

###################
# Set environment #
###################

# load libraries
library(RColorBrewer)
library(gplots)
library(CoRC)
library(stringr)

setwd(wd)
source("misc.R")
