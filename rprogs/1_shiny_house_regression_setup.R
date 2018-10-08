# ================================================================================================ #
# Description: Polished setup for the R libraries used and plot functions required for the shiny house regression analysis
#as part of the outcomes-framework social housing test case (paper 5).
#
# Input: sia_rmd_functions.R, sia_rmd_outcome_chunks.R
#
# Output: NA
# 
# Author: W Lee
#
# Dependencies:
# SIAtoolbox - for data loading
#
# Notes:
# This script is required before 2_shiny_house_regression_data.R is run
# This script is part of the main script of shiny_house.Rmd
#
# History (reverse order): 
# 28 Nov 2017 Nafees v1
# 07 Sep 2018 W Lee v2
# ================================================================================================ #

# Pre-load existing libraries required

library(RODBC)
library(readr)
library(dplyr)
library(ggplot2)
library(scales)
library(DT)
library(knitr)
library(tidyr)
library(SIAtoolbox)
library(zoo)
library(arm)
library(survey)
library(caret)

set.seed(12345)


#plot function estimates + CI

plot_estimates <- function(model){
  coefs <- data.frame(summary(model)$coefficients)
  coefs$names <- row.names(coefs)
  coefs$pt_shpe <- ifelse(coefs$Pr...t..<0.05,8,ifelse(coefs$Pr...t..<0.1,3,20))
  coefs$pt_color <- ifelse(coefs$Pr...t..<0.05,"red",ifelse(coefs$Pr...t..<0.1,"orange","black"))
  coefs$pt_size <- ifelse(coefs$Pr...t..<0.05,5,ifelse(coefs$Pr...t..<0.1,2,1))
  
  ggplot(coefs[-which(coefs$names=="(Intercept)"),], aes(x=names, y=Estimate, ymin=Estimate-1.96*Std..Error, ymax= Estimate+1.96*Std..Error)) +
    geom_point(shape=coefs[-which(coefs$names=="(Intercept)"),"pt_shpe"],
               color=coefs[-which(coefs$names=="(Intercept)"),"pt_color"],
               size=coefs[-which(coefs$names=="(Intercept)"),"pt_size"]) +
    geom_errorbar(width=0.3) +
    theme_light() +
    theme(axis.text.x = element_text(angle = 90, hjust=1)) +
    xlab("Variable")
}

#For glm models...
plot_estimates_glm <- function(model){
  coefs <- data.frame(summary(model)$coefficients)
  coefs$names <- row.names(coefs)
  coefs$pt_shpe <- ifelse(coefs$Pr...z..<0.05,8,ifelse(coefs$Pr...z..<0.1,3,20))
  coefs$pt_color <- ifelse(coefs$Pr...z..<0.05,"red",ifelse(coefs$Pr...z..<0.1,"orange","black"))
  coefs$pt_size <- ifelse(coefs$Pr...z..<0.05,5,ifelse(coefs$Pr...z..<0.1,2,1))
  
  ggplot(coefs[-(coefs$names=="(Intercept)"),], aes(x=names, y=Estimate, ymin=Estimate-1.96*Std..Error, ymax= Estimate+1.96*Std..Error)) +
    geom_point(shape=coefs[-which(coefs$names=="(Intercept)"),"pt_shpe"],
               color=coefs[-which(coefs$names=="(Intercept)"),"pt_color"],
               size=coefs[-which(coefs$names=="(Intercept)"),"pt_size"]) +
    geom_errorbar(width=0.3) +
    theme_light() +
    theme(axis.text.x = element_text(angle = 90, hjust=1)) +
    xlab("Variable")
}