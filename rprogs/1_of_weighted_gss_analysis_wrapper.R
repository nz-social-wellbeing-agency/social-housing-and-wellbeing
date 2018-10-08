# ================================================================================================ #
# Description: Declare libraries and functions for generic use in the weighted GSS analysis.
#
# Input: 
# NA
# 
#
# Output: 
#
# Author: C MacCormick, V Benny
#
# Dependencies:
#
# Notes:
#
# History (reverse order): 
# 4 October 2017 CM v1
# ================================================================================================ #

setwd("~/Network-Shares/Datalab-MA/MAA2016-15 Supporting the Social Investment Unit/outcomes_framework/workstream5/rprogs")

library(SIAtoolbox)
library(RODBC)
library(dplyr)
library(survey)
library(srvyr)
library(ggplot2)
library(readr)
library(xlsx)
library(rlang)
# Overwrite the sqlwrite function in RODBC package with a modified version.
# This function fixes an issue with RODBC::sqlSave function, provided that the schema name is provided
# with square brackets while specifying table name. Only works with fast= FALSE in sqlSave function
source("./sqlwrite.R")
assignInNamespace("sqlwrite", value = sqlwrite, ns = "RODBC")


# Set seed for replicability
seedval <- 12345
set.seed(seedval)


################### Create functions for later use ###################

# Generate population totals for benchmark categories
create_vector <- function(tib_object){
  vec_object <- tib_object[[2]]
  names(vec_object) <- paste0(names(tib_object[,1]), tib_object[[1]])
  return(vec_object)
}

# Create and consoilidate the list of benchmark categories
create_bmark_vector <- function(dataset, bmark_cols, weight_col){
  
  ret_obj <- c()
  for(col in bmark_cols){
    objval <- dataset %>% 
      group_by_(col) %>%
      summarise(val = sum(!!sym(weight_col))) %>%
      create_vector()
    ret_obj <-c(ret_obj, objval[2: length(objval)])
  }
  
  return(ret_obj)
}


# Distribution testing functions for post reweighting checks
distribution_compare <- function(pop1, pop2, standardize = FALSE){
  # remove any non-numeric values
  pop1 <- pop1[is.finite(pop1)]
  pop2 <- pop2[is.finite(pop2)]
  # de-mean if correction requested
  if(standardize){
    pop1 <- pop1 - mean(pop1)
    pop2 <- pop2 - mean(pop2)
    pop1 <- pop1 / sd(pop1)
    pop2 <- pop2 / sd(pop2)
  }
  # Mann-Whitney test
  MW_test <- wilcox.test(pop1, pop2, exact=FALSE)
  # Kolmogorov-Smirnov test
  KS_test <- suppressWarnings(ks.test(pop1,pop2, exact=FALSE))
  # return
  list(MW_test = MW_test$p.value, KS_test = KS_test$p.value)
}

make_samples <- function(val1, val2 = val1, wgt1 = NULL, wgt2 = NULL, nn = 1000){
  
  # remove any non-numeric values
  i2 <- is.finite(val2) & is.finite(wgt2)
  val2 <- val2[i2]
  wgt2 <- wgt2[i2]
  i1 <- is.finite(val1) & is.finite(wgt1)
  val1 <- val1[i1]
  wgt1 <- wgt1[i1]
  # checks
  if(!(is.null(wgt1) | length(val1)==length(wgt1))){stop('wgt1 must be null or same length as val1')}
  if(!(is.null(wgt2) | length(val2)==length(wgt2))){stop('wgt2 must be null or same length as val2')}
  
  # weights are 1 if not specified
  if(is.null(wgt1)){wgt1<-rep(1,length(val1))}
  if(is.null(wgt2)){wgt2<-rep(1,length(val2))}
  # sample
  samp1 <- sample(val1, nn, replace=TRUE, prob=wgt1)
  samp2 <- sample(val2, nn, replace=TRUE, prob=wgt2)
  # return
  list(pop1 = samp1, pop2 = samp2)
}

################### Connection to the database ###################
connstr <- set_conn_string(db = "IDI_Sandpit")
schemaname <- "[DL-MAA2016-15]"


############### Source the scripts in sequence ###################

# Recalibration of weights to adjust for individuals who drop off after linking with IDI Spine
# Remember to uncomment the section in this script that writes the new weights to the database if so required.
source("2_of_rewt_gss_person_replicates.R")

# Perform tests on the new weights to check if the weighted distributions of variables is similar to original.
source("3_of_testing_distributions.R")

# Now we start generating weighted descriptive statistics
source("4_of_weighted_descr_stats.R")









