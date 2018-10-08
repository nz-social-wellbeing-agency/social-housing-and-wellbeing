# ================================================================================================ #
# Description: Polished functions used for the comparison of the treated & control / before & after
# populations to produce output for submission to checking as part of the outcomes-framework social
# housing test case (paper 5).
#
# Input: NA
#
# Output: All the R functions used for analysis in the outcomes-framework social housing test case
# 
# Author: S. Anastasiadis
#
# Dependencies: SIAtoolbox
#
# Notes: # Order of library calls is important as the Matching package requires the MASS package, which shares
# some function names with dplyr.
#
# History (reverse order): 
# 28 Nov 2017 SA v1
# ================================================================================================ #



#' Assert function for run time testing of code.
#' Throws an error if condition is not TRUE
#' 
assert <- function(condition, msg){
  # condition must be logical
  if(! class(condition) %in% "logical"){
    msg <- sprintf("expected condition to be logical, received %s instead\n",class(condition))
    stop(msg)
  }
  # check condition and throw error
  if(condition == FALSE)
    stop(msg)
}

#' Print out table in comma separated form.
#' For using sink to print tables to CSV format output files.
#' 
#' Example 1:
#' dataset <- data.frame(score = c(1.1,3.9,4.2), category = c("[0,2]","[2,4]","[4,6]"), sex = as.factor(c("M","F","F")))
#' sink("test_file.csv")
#' comma_print_table(tbl = dataset)
#' sink()
#' 
comma_print_table <- function(tbl){
  # stop if input type is wrong
  assert(is.data.frame(tbl), msg = "tbl must be a dataframe")
  
  # convert any factors to characters (else factors may display as numeric values)
  # and add " quote marks before and after character strings (to ensure these are kept together
  # e.g. "score [1,4]" should remain a single entry and hence should not split on the comma)
  for(name in names(tbl)){
    if("factor" %in% class(tbl[[name]])){
      tbl[[name]] <- paste0("\"",as.character(tbl[[name]]),"\"")
    } 
    else if ("character" %in% class(tbl[[name]]))
      tbl[[name]] <- paste0("\"",(tbl[[name]]),"\"")
  }
  # get number of records
  num_records <- length(tbl[,1])
  # print header
  line <- paste0("\"",paste0(names(tbl),collapse = "\",\""),"\"\n")
  cat(line)
  # print contents
  for(ii in 1:num_records)
    cat(paste0(paste0(tbl[ii,],collapse = ",")),"\n")
}

#' Produces a single bootstrap sample from existing population, for use within replicate.
#' Under the hypothesis that the dependent variable is independent of the variable chosen.
#' 
#' Example:
#' reduced_dataset <- data.frame(score = c("A","B","B"), sex = c("M","F","F"), wgt = c(2,1,1))
#' bootstrapped_samples <- replicate(100, boot_strap_for_table(reduced_dataset, "score", "sex"))
#'
boot_strap_for_table <- function(reduced_dataset, dependent_var, var_name){
  # stop if input type is wrong
  assert(is.data.frame(reduced_dataset), msg = "dataset must be a dataframe")
  assert(is.character(dependent_var), msg = "dependent_var must be a character string")
  assert(is.character(var_name), msg = "var_name must be a character string")
  # columns in dataset
  assert(dependent_var %in% names(reduced_dataset), msg = sprintf("dependent_var (%s) must be a column of dataset",dependent_var))
  assert(var_name %in% names(reduced_dataset), msg = sprintf("var_name (%s) must be a column of dataset",var_name))
  assert("wgt" %in% names(reduced_dataset), msg = "dataset must be setup with wgt column")
  
  # sample without replacement to randomize values of variable - this is equivalent to randomizing the labels
  # from the dependent variable but preserves the weights of the records
  reduced_dataset[[var_name]] <- sample(reduced_dataset[[var_name]], length(reduced_dataset[[var_name]]))
  # construct cross table of (weighted) counts
  tbl <- reshape2::dcast(reduced_dataset, paste0(var_name," ~ ",dependent_var), fun.aggregate = sum, value.var = "wgt")
  # rearrange table (col1 = dependet_var, col2 = var_name, col3 = wgt.count)
  tbl <- reshape2::melt(tbl, id.vars = var_name)
  # return
  return(tbl[,3])
}

#' Cross tabulate the dependent variable against an explanitory variable.
#' Using bootstrap to produce confidence intervals, and summary plots.
#' 
#' (LB, UB) provides a 95% C.I. on the dependent variable under the hypothesis
#' that the dependent variable is independent of the variable chosen. This is
#' approximately equivalent to a formal test (alpha = 5%).
#' 
#' Example:
#' dataset <- data.frame(score = c("A","B","B"), sex = c("M","F","F"))
#' cross_table_and_plot(dataset,"score","sex_code","Sex of respondent")
#' 
cross_table_and_plot <- function(dataset, dependent_var, var_name, var_label){
  # stop if input type is wrong
  assert(is.data.frame(dataset), msg = "dataset must be a dataframe")
  assert(is.character(dependent_var), msg = "dependent_var must be a character string")
  assert(is.character(var_name), msg = "var_name must be a character string")
  assert(is.character(var_label), msg = "var_label must be a character string")
  # dependent variable must be binary
  assert(length(base::unique(dataset[[dependent_var]])) == 2, msg = "dependent variable must be binary")
  # columns in dataset
  assert(dependent_var %in% names(dataset), msg = sprintf("dependent_var (%s) must be a column of dataset",dependent_var))
  assert(var_name %in% names(dataset), msg = sprintf("var_name (%s) must be a column of dataset",var_name))
  
  # if wgt does not exist create it (equal to 1 so sum(wgt) is equiv to count)
if(! "wgt" %in% names(dataset))
    dataset[["wgt"]] <- 1
  # produce reduced dataset
  reduced_dataset <- dplyr::select_(dataset, dependent_var, var_name, "wgt") %>% filter_(paste0("!is.na(",var_name,")"))
  
  # produce cross tabulation
  tbl <- reshape2::dcast(reduced_dataset, paste0(var_name," ~ ",dependent_var), fun.aggregate = sum, value.var = "wgt")
  # reshape
  tbl <- reshape2::melt(tbl, id.vars = var_name)
  # bootstrap
  boots <- replicate(NUM_REPS,boot_strap_for_table(reduced_dataset, dependent_var, var_name))
  tbl <- mutate(tbl, LB = apply(boots, MARGIN = 1, FUN = quantile, probs = 0.025))
  tbl <- mutate(tbl, UB = apply(boots, MARGIN = 1, FUN = quantile, probs = 0.975))
  
  # create plot
  p <- ggplot(data = tbl) +
    geom_col(aes_string(x = var_name, fill = "variable", y = "value")
             ,position = "dodge") +
    scale_fill_manual(values = c("#313143", "#BDBAC0", "#414258", "#F47C20")) +
    geom_errorbar(aes_string(x = var_name, ymin = "LB", ymax = "UB", group = "variable")
                  ,width = 0.2,position = position_dodge(0.9)) +
    ylab("(Weighted) count  of population") +
    xlab(var_label) +
    # theme_sia() +
    ggtitle(paste0("Comparison of \"",var_label,"\" across \"",dependent_var,"\""))
  # display output
  comma_print_table(tbl)
  print(p)
}

#' Test populations for whether differences are statistically significant.
#' Error bounds from the plots produced by cross_table_and_plot are approximately equivalent
#' to a formal test, but this approach lets us be rigerous.
#' 
#' Code built to handle binary, categorical and continuous independent variable.
#' Dependent variable must be categorical & binary.
#' 
#' Example 1:
#' dataset <- data.frame(category = c("A","B","B","A"), sex = c("M","F","F","M"), score = c(1,2,3,4))
#' test_population_differences(dataset, "category", "category", "sex", "Sex of respondent")
#' 
#' Example 2:
#' test_population_differences(dataset, "category", "category", "score", "Score of respondent") 
#' 
test_population_differences <- function(dataset, dependent_var, var_name, var_label){
  # stop if input type is wrong
  assert(is.data.frame(dataset), msg = "dataset must be a dataframe")
  assert(is.character(dependent_var), msg = "dependent_var must be a character string")
  assert(is.character(var_name), msg = "var_name must be a character string")
  assert(is.character(var_label), msg = "var_label must be a character string")
  # dependent variable must be binary
  assert(length(base::unique(dataset[[dependent_var]])) == 2, msg = "dependent variable must be binary")
  # columns in dataset
  assert(dependent_var %in% names(dataset), msg = sprintf("dependent_var (%s) must be a column of dataset",dependent_var))
  assert(var_name %in% names(dataset), msg = sprintf("var_name (%s) must be a column of dataset",var_name))
  
  # require indepentent variable is suitable for analysis
  msg <- sprintf("%s is neither character, factor, logical, numeric or integer", var_name)
  condition <- class(dataset[[var_name]]) %in% c("integer", "numeric", "logical", "factor", "character")
  assert(condition,msg)
  
  # if wgt does not exist create it (equal to 1 so sum(wgt) is equiv to count)
  if(! "wgt" %in% names(dataset))
    dataset[["wgt"]] <- 1
  # produce reduced dataset
  reduced_dataset <- dplyr::select_(dataset, dependent_var, var_name, "wgt") %>% filter_(paste0("!is.na(",var_name,")"))
  
  # continuous case
  if(any(c("numeric", "integer") %in% class(reduced_dataset[[var_name]]))){
    # level label & variable
    var_level <- "mean"
    reduced_dataset$tmp_var <- reduced_dataset[[var_name]]
    # run test
    test_and_summarize(reduced_dataset, dependent_var, var_label, var_level)
  }
  # categorical case
  if(any(c("logical", "factor", "character") %in% class(reduced_dataset[[var_name]]))){
    # unique levels in independent variable
    level_labels <- base::unique(dataset[[var_name]])
    # exclude NA levels
    level_labels <- level_labels[! is.na(level_labels)]
    # binary case
    if(length(level_labels) == 2){
      # level label & variable
      var_level <- sort(level_labels)[2]
      reduced_dataset$tmp_var <- ifelse(reduced_dataset[[var_name]] == var_level, 1, 0)
      # run test
      test_and_summarize(reduced_dataset, dependent_var, var_label, var_level)
    }
    # multi-category case
    else if(length(level_labels) > 2){
      for(level in level_labels){
        # level label & variable
        var_level <- level
        reduced_dataset$tmp_var <- ifelse(reduced_dataset[[var_name]] == var_level, 1, 0)
        # run test
        test_and_summarize(reduced_dataset, dependent_var, var_label, var_level)
      }
    }
    # error mono-category case
    else {
      msg <- sprintf("%s is either empty or contains only a single category\n",var_name)
      cat(msg)
    }
  }
}

#' Sub-function for test_population_differences.
#' Conducts t.test and displays a summary of the result.
#' 
test_and_summarize <- function(reduced_dataset, dependent_var, var_label, var_level){
  # stop if input type is wrong
  assert(is.data.frame(reduced_dataset), msg = "dataset must be a dataframe")
  assert(is.character(dependent_var), msg = "dependent_var must be a character string")
  assert(is.character(var_label), msg = "var_name must be a character string")
  # columns in dataset
  assert(dependent_var %in% names(reduced_dataset), msg = sprintf("dependent_var (%s) must be a column of dataset",dependent_var))
  assert("tmp_var" %in% names(reduced_dataset), msg = "dataset must be setup with tmp_var column")
  assert("wgt" %in% names(reduced_dataset), msg = "dataset must be setup with wgt column")
  
  # get labels of dependent variable
  level_labels <- as.character(base::unique(reduced_dataset[[dependent_var]]))
  lvl1 <- level_labels[1]
  lvl2 <- level_labels[2]
  # split
  lvl1_data <- filter_(reduced_dataset, paste0(dependent_var," == \"",lvl1,"\""))
  lvl2_data <- filter_(reduced_dataset, paste0(dependent_var," == \"",lvl2,"\""))
  # test
  this_test <- wtd.t.test(x = lvl1_data$tmp_var, weight  = lvl1_data$wgt,
                          y = lvl2_data$tmp_var, weighty = lvl2_data$wgt,
                          samedata = FALSE)
  # weighted means
  lvl1_mu <- sum(lvl1_data$tmp_var * lvl1_data$wgt) / sum(lvl1_data$wgt)
  lvl2_mu <- sum(lvl2_data$tmp_var * lvl2_data$wgt) / sum(lvl2_data$wgt)
  # format and display output
  msg <- sprintf("%s = %s,  %s = %6f,  %s = %6f,  t = %7f,  df = %6f,  p-value = %5f\n",
                 var_label, var_level,
                 lvl1, lvl1_mu,
                 lvl2, lvl2_mu,
                 this_test$coefficients[1], this_test$coefficients[2], this_test$coefficients[3])
  cat(msg)
}

#' Analysis wrapper function.
#' Loop over variables, producing tables and running tests.
#' 
analysis_wrapper <- function(dataset, dependent_var, SAVE_PLOTS, columns_to_analyse){
  # filter to window of interest
  dataset <- filter_(dataset, paste0(dependent_var," != \"IGNORE\""))
  # create folder for plots if needed
  plot_path <- paste0('../output/plots_',dependent_var)
  if(SAVE_PLOTS & !dir.exists(file.path(plot_path)))
    dir.create(file.path(plot_path))
  
  ## analysis - tables
  sink(paste0("../output/",dependent_var,"_tbl.csv"))
  
  for(varname in columns_to_analyse){
    if(varname[3] %in% c("both", "table")){
      # make table
      cross_table_and_plot(dataset, dependent_var, varname[1], varname[2])
      # save plots
      if(SAVE_PLOTS){
        filename <- paste0('../output/plots_',dependent_var,'/',varname[2],'.png')
        ggsave(filename=filename, scale=1, width=10,height=6,units="in")
      }
    }
  }
  
  sink()
  
  # analysis - tests
  sink(paste0("../output/",dependent_var,"_test.csv"))
  
  for(varname in columns_to_analyse){
    if(varname[3] %in% c("both", "test")){
      # run test
      test_population_differences(dataset, dependent_var, varname[1], varname[2])
    }
  }
  
  sink()
  
  # Completion time
  print(paste0("Complete ",dependent_var,":"))
  print(Sys.time())
}



## Function to save the regressions coefficient estimates / robust regression
robust_glm_wrapper <- function(formula_matrix, dataset, dependent_var) {
  
  ds <- filter_(dataset, paste0(dependent_var," != \"IGNORE\""))
  
  
  # Create the output files and the index page
  write.xlsx(formula_matrix, file=paste0("../output/coeff_",dependent_var, ".xlsx"), sheetName="Index");
  
  for (i in 1:nrow(formula_matrix) ){
    print(paste0("Formula ", as.character(i), ": ", formula_matrix[i,1]))
    robust_glm <- glmrob(as.formula(formula_matrix[i,1]), data = ds, family =  formula_matrix[i,2], control = glmrobMqle.control(maxit=100))
    

   y <- summary(robust_glm)
    
   xlsx::write.xlsx(y$coefficients, file=paste0("../output/coeff_",dependent_var, ".xlsx"), 
                    sheetName=str_sub(reg_formulas[i,1],1,str_locate(reg_formulas[i,1],"~")[1]-1), append=TRUE);
    
  }
  
}

## Function to save the regressions coefficient estimates / glm
glm_wrapper <- function(formula_matrix, dataset, dependent_var) {
  
  ds <- filter_(dataset, paste0(dependent_var," != \"IGNORE\""))
  
  
  # Create the output files and the index page
  write.xlsx(formula_matrix, file=paste0("../output/coeff_",dependent_var, ".xlsx"), sheetName="Index");
  
  for (i in 1:nrow(formula_matrix) ){
    print(paste0("Formula ", as.character(i), ": ", formula_matrix[i,1]))
    glm <- glm(as.formula(formula_matrix[i,1]), data = ds, family =  formula_matrix[i,2], weights=wgt)
    
    
    y <- summary(glm)
    
    xlsx::write.xlsx(y$coefficients, file=paste0("../output/coeff_",dependent_var, ".xlsx"), 
                     sheetName=str_sub(reg_formulas[i,1],1,str_locate(reg_formulas[i,1],"~")[1]-1), append=TRUE);
    
  }
  
}


