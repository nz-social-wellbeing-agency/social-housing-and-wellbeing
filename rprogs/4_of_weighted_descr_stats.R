# ================================================================================================ #
# Description: Creating descriptive statistics with new GSS weights.
#
# Input: 
# [DL-MAA2016-15].of_gss_calibrated_weights
# [DL-MAA2016-15].of_gss_ind_variables
#
# Output: 
#
# Author: C MacCormick and V Benny
#
# Dependencies:
#
# Notes:
#
# History (reverse order): 
# 4 October 2017 CM v1
# 21 May 2018 VB Added new variables, repointed linked weights table.
# 30 May 2018 VB Added new variables(mwi_bottom_20, new logic for no_qual)
# ================================================================================================ #

# rm(list = ls())

conn <- set_conn_string("IDI_Sandpit")

# Left join personal vars table with new weights
gss_person <- read_sql_table(paste0("select *, 1 as counter from ",schemaname,".of_gss_ind_variables_sh pers 
                             left join ",schemaname,
                             ".of_gss_calibrated_weights_sh wt
                             on pers.snz_uid = wt.snz_uid")
                             ,connection_string = connstr
                             ,string = TRUE
)

# Keep only the weights that are required, and remove unnecessary columns. Also, rename variable categories.
gss_person_final <- gss_person %>%
  dplyr::select(
    -contains("pq_person_FinalWgt")
    # ,contains("linked")
    ,-snz_uid.1
    ,-gss_id_collection_code.1
  ) %>%
  filter(snz_spine_ind == 1) %>%
  mutate(pub_trpt_safety_ind = ifelse(get("pub_trpt_safety_ind") == 1, "Safe","Unsafe/Unknown")
         ,safety_ind = ifelse(get("safety_ind") == 1, "Safe","Unsafe/Unknown")
         ,safety_day_ind = ifelse(get("safety_day_ind") == 1, "Safe","Unsafe/Unknown")
         ,house_crowding_ind = ifelse(get("house_crowding_ind") == 1, "Crowded","Uncrowded/Unknown")
         ,crime_exp_ind = ifelse(get("crime_exp_ind") == 1, "Yes","No/Unknown")
         ,time_lonely_ind = ifelse(get("time_lonely_ind") == 1, "Yes", ifelse(get("time_lonely_ind") == 0, "No","Unknown") )
         ,voting_ind = ifelse(get("voting_ind") == 1, "Yes", ifelse(get("voting_ind") == 0, "No","Unknown") )
         ,acc_sup_ind = ifelse(get("acc_sup_ind") == 1, "Yes","No/Unknown")
         ,cult_identity_ind = ifelse(get("cult_identity_ind") == 1, "Easy","No/Unknown")
         ,housing_sat_ind = ifelse(get("housing_sat_ind") == 1, "Satisfied","Unsatisfied/Unknown")
         ,gss_pq_house_mold_code = ifelse(get("gss_pq_house_mold_code") == 1, "Yes", "No")
         ,gss_pq_house_cold_code = ifelse(get("gss_pq_house_cold_code") == 1, "Yes", "No")
         ,gss_pq_house_condition_code = ifelse(get("gss_pq_house_condition_code") == 1, "Poor condition/Unknown", "Good condition")
         ,life_satisfaction_bin = ifelse(get("life_satisfaction_bin") == 1, "More satisfied", "Less satisfied/Unknown")
         ,age_bands = cut(gss_pq_dvage_code, breaks = c(-Inf,24,39,59,Inf))
         ,wellbeingind = ifelse(get("gss_id_collection_code") == "GSS2014", ifelse(get("gss_pq_material_wellbeing_code") <= 9, "Low", "High"), 
                                ifelse(get("gss_pq_ELSIDV1") <= 18, "Low", "High"))
         ,highest_qual = ifelse(get("gss_pq_highest_qual_dev") %in% c(1,2,3,4,11),'high school qual',
                                ifelse(get("gss_pq_highest_qual_dev") %in% c(5,6,7,8,9,10,12),'post high school qual',
                                       ifelse(get("gss_pq_highest_qual_dev") %in% c(0),'no qual', 'Unknown')))
         ,mwi_bottom_20 = ifelse(get("gss_id_collection_code") == "GSS2014" | is.na(get("gss_pq_ELSIDV1")), "Unknown", 
                                 ifelse(get("gss_pq_ELSIDV1") <= 31*0.2, "Yes", "No"))
         ,wellbeingind_081012 = ifelse(get("gss_id_collection_code") == "GSS2014" | is.na(get("gss_pq_ELSIDV1")), "Unknown",
                                       ifelse(get("gss_pq_ELSIDV1") <= 18, "Low", "High"))
  )


# List of variables on which stats are required
var_list <- quos(
  # gss_id_collection_code,
  # gss_hq_sex_dev
  # ,gss_pq_HH_crowd_code
  # ,
  gss_pq_house_mold_code
  ,gss_pq_house_cold_code
  ,gss_pq_house_condition_code # Does not exist for 2014
  # ,housing_satisfaction # Does not exist for 2014
  # ,gss_pq_prob_hood_noisy_ind
  # ,gss_pq_safe_night_pub_trans_code
  # ,gss_pq_safe_night_hood_code
  # ,gss_pq_safe_day_hood_code # Does not exist for 2014
  # ,gss_pq_discrim_rent_ind
  # ,gss_pq_crimes_against_ind
  # ,gss_pq_cult_identity_code
  # ,gss_pq_ment_health_code
  # ,gss_pq_phys_health_code
  # ,gss_pq_lfs_dev
  # ,gss_pq_highest_qual_dev
  # ,gss_pq_feel_life_code
  # ,gss_pq_voting # Does not exist for 2014
  # ,gss_pq_time_lonely_code
  # ,gss_hq_household_inc1_dev
  # ,gss_pq_dvage_code
  ,age_bands
  # ,gss_pq_eth_european_code
  # ,gss_pq_eth_maori_code
  # ,gss_pq_eth_samoan_code
  # ,gss_pq_eth_cookisland_code
  # ,gss_pq_eth_tongan_code
  # ,gss_pq_eth_nieuan_code
  # ,gss_pq_eth_chinese_code
  # ,gss_pq_eth_indian_code
  # ,gss_pq_HH_comp_code
  # ,gss_hq_regcouncil_dev
  # ,adult_count
  ,pub_trpt_safety_ind
  ,safety_ind
  ,house_crowding_ind
  ,crime_exp_ind
  # ,ct_house_pblms
  # ,phys_health_sf12_score
  # ,ment_health_sf12_score
  ,lbr_force_status
  ,time_lonely_ind
  ,voting_ind # Does not exist for 2014
  ,hh_gss_income
  ,life_satisfaction_ind
  ,acc_sup_ind
  # ,housing_status
  ,housing_groups
  ,life_satisfaction_bin
  ,treat_control_main
  ,treat_control_sen
  ,safety_day_ind
  ,cult_identity_ind
  ,housing_sat_ind
  ,wellbeingind
  ,highest_qual
  ,no_access_natural_space
  ,no_free_time
  ,mwi_bottom_20
  ,wellbeingind_081012
)

numcols <- names(gss_person_final)[sapply(gss_person_final, is.numeric)]
catcols <- names(gss_person_final)[sapply(gss_person_final, is.factor)]

####################################################################################################
# Functions to generate the statistics


# Univariate stats generation
univariate_descr <- function(inputVar, weighted = TRUE){
  
  # enquo_input <- enquo(inputVar)
  enquo_input <- inputVar
  print(enquo_input)
  
  # if weighted is TRUE, then run the below aggregation
  if(weighted){
    tmp <- gss_person_final_svy %>%
      mutate(var = factor(!!enquo_input)) %>%
      filter(!is.na(var)) %>% # Filter NAs
      group_by(var) %>%
      summarise(wtmean = survey_mean(na.rm = TRUE, vartype = c("ci", "se"))
                ,wttotal = survey_total(na.rm = TRUE, vartype = c("ci", "se"))
                ,unwttotal = unweighted(n())
      ) %>%
      mutate(var_name = rlang::quo_text(enquo_input))
  } else{
    tmp <- gss_person_final_svy %>%
      mutate(var = factor(!!enquo_input)) %>%
      filter(!is.na(var)) %>% # Filter NAs
      group_by(var) %>%
      summarise(unwttotal = unweighted(n)) %>%
      mutate(var_name = rlang::quo_text(enquo_input))
  }
  
  
  # tmp %>%
  #   ggplot(aes(var, total)) +
  #   geom_bar(stat = "identity", alpha = 0.6, fill = "#588D97", width = 0.5) +
  #   geom_errorbar(aes(ymin = total_low, ymax = total_upp), width = 0.1, alpha = 0.6, size = 0.25) +
  #   theme_sia() +
  #   scale_y_continuous(labels = scales::comma) +
  #   labs(x = rlang::quo_text(enquo_input)) +
  #   theme(
  #     text = element_text(size = 5)
  #   ) +
  #   scale_x_discrete(labels = function(x) stringr::str_wrap(x, width = 10))
  
  # ggsave(filename = paste0(rlang::quo_text(enquo_input), ".png"), device = "png", path = "output/plots/no_as",
  #        width = 6, height = 3)
  
  return(tmp)
  
}


# Bivariate

bivariate_descr <- function(inputVar, inputVar2){
  
  # enquo_input <- enquo(inputVar)
  enquo_input <- inputVar
  enquo_input2 <- inputVar2
  print(enquo_input2)
  
 
    tmp1 <- gss_person_final_svy %>%
    mutate(var = factor(!!enquo_input)
           ,var2 = factor(!!enquo_input2)) %>%
    filter(!is.na(var) & !is.na(var2)) %>%
    group_by(var, var2) %>%
    summarise(
      wtmean = survey_mean(na.rm = TRUE, vartype = c("ci", "se"))
      ,wttotal = survey_total(na.rm = TRUE, vartype = c("ci", "se"))
      # ,unwttotal = unweighted(n())
    ) %>%
    mutate(var_name = rlang::quo_text(enquo_input)
           ,var_name2 = rlang::quo_text(enquo_input2)
    )
 
    tmp2 <- gss_person_final_svy %>%
    mutate(var = factor(!!enquo_input)
           ,var2 = factor(!!enquo_input2)) %>%
    filter(!is.na(var) & !is.na(var2)) %>%
    group_by(var, var2) %>%
    summarise(
      unwttotal = unweighted(n())
    ) %>%
    mutate(var_name = rlang::quo_text(enquo_input)
           ,var_name2 = rlang::quo_text(enquo_input2)
    )
    
    tmp <- left_join(tmp1, tmp2, by = c("var", "var_name", "var2", "var_name2"))
  
  # tmp %>%
  #   ggplot(aes(var, mean)) +
  #   geom_bar(stat = "identity", alpha = 0.6, fill = "#F47C20", width = 0.5) +
  #   geom_errorbar(aes(ymin = mean_low, ymax = mean_upp), width = 0.1, alpha = 0.6, size = 0.25) +
  #   theme_sia() +
  #   scale_y_continuous(labels = scales::comma) +
  #   labs(x = rlang::quo_text(enquo_input)) +
  #   theme(
  #     text = element_text(size = 5)
  #   ) +
  #   scale_x_discrete(labels = function(x) stringr::str_wrap(x, width = 10))
  
  # ggsave(filename = paste0(rlang::quo_text(enquo_input), "_", rlang::quo_text(enquo_input2), ".png"), 
  #        device = "png", path = "output/plots/no_as", width = 3.5, height = 3)
  
  return(tmp)
  
}


####################################################################################################

# Create stats for each wave
# write.xlsx(cbind("Notes"=NA), file = "output/univariate_desc_stats.xlsx", sheetName = "Note_to_Stats", row.names = FALSE)
# write.xlsx(cbind("Notes"=NA), file = "output/bivariate_housing_desc_stats_weighted.xlsx", sheetName = "Note_to_Stats", row.names = FALSE)
# write.xlsx(cbind("Notes"=NA), file = "output/bivariate_housing_desc_stats_unweighted.xlsx", sheetName = "Note_to_Stats", row.names = FALSE)
# write.xlsx(cbind("Notes"=NA), file = "output/bivariate_treat_desc_stats_unweighted.xlsx", sheetName = "Note_to_Stats", row.names = FALSE)
# write.xlsx(cbind("Notes"=NA), file = "output/overall_desc_stats_unweighted.xlsx", sheetName = "Note_to_Stats", row.names = FALSE)

# Declare lists and an iterator for storing intermediate datasets from each wave
univariate_list <- list()
bivariate_housing_list <- c()
listcounter <- 1

for(wave in levels(gss_person_final$gss_id_collection_code) ) {
  
  # Create the survey object for generating stats
  gss_person_final_svy <- svrepdesign(id = ~1
                                      , weights = ~link_FinalWgt_nbr
                                      , repweights = "link_FinalWgt[0-9]"
                                      # , repweights = "pq_person_FinalWgt[0-9]"
                                      , data = gss_person_final %>% filter(gss_id_collection_code == wave)
                                      , type = "JK1"
                                      , scale = 0.99
  ) %>%
    as_survey_rep()
  
  # Create an exclusion variable list for each wave.
  if(wave == "GSS2014" ) 
    gssvars <- var_list[unlist(lapply(var_list, function(x) 
      x != c(quos(gss_pq_house_condition_code)) &
        x != c(quos(housing_satisfaction)) &
        x != c(quos(housing_sat_ind)) &
        x != c(quos(safety_day_ind)) &
        x != c(quos(gss_pq_safe_day_hood_code)) &
        x != c(quos(gss_pq_voting)) &
        x != c(quos(voting_ind)) &
        x != c(quos(no_access_natural_space)) &
        x != c(quos(no_free_time)) &
        x != c(quos(mwi_bottom_20)) &
        x != c(quos(wellbeingind_081012))
    ))]
  else gssvars <- var_list
  
  ######## Univariate Statistics - Weighted ########
  univariate_tbl <- data.frame()
  for(i in 1:length(gssvars)){
    print(i)
    univariate_tbl <- rbind(univariate_tbl, univariate_descr(gssvars[[i]]))
  }
  
  write.xlsx(as.data.frame(univariate_tbl), file = "../output/univariate_desc_stats.xlsx", sheetName = wave, row.names = FALSE,
              append = TRUE)
  
  # Save the summary table for later use
  univariate_list[[listcounter]] <- univariate_tbl
  
  ######## Bivariate Statistics at housing groups level- Weighted ########
  bivariate_tbl_housing <- data.frame()
  for(i in 1:length(gssvars)){
    print(i)
    bivariate_tbl_housing <- rbind(bivariate_tbl_housing, bivariate_descr(quo(housing_groups), gssvars[[i]] ))
  }
  
  write.xlsx(as.data.frame(bivariate_tbl_housing), file = "../output/bivariate_housing_desc_stats_weighted.xlsx", sheetName = wave, row.names = FALSE,
              append = TRUE)
  
  # Save the summary table for later use
  bivariate_housing_list[[listcounter]] <- bivariate_tbl_housing
  
  # Increment counter for list
  listcounter <- listcounter + 1
  
}

names(univariate_list) <- levels(gss_person_final$gss_id_collection_code)
names(bivariate_housing_list) <- levels(gss_person_final$gss_id_collection_code)

# Calculate aggregate statistics for univariate case
univar_agg <- univariate_list$GSS2014 %>% dplyr::select(var, var_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) %>%
  full_join(univariate_list$GSS2012 %>% dplyr::select(var, var_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , by = c("var", "var_name"), suffix = c("14", "12")) %>%
  full_join(univariate_list$GSS2010 %>% dplyr::select(var, var_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , by = c("var", "var_name"), suffix = c("12", "10")) %>%
  full_join(univariate_list$GSS2008 %>% dplyr::select(var, var_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , by = c("var", "var_name"), suffix = c("10", "08")) %>%
  dplyr::mutate(overallse = sqrt( ( ifelse(is.na(wtmean_se14), 0, wtmean_se14^2) + 
                               ifelse(is.na(wtmean_se12), 0, wtmean_se12^2) + 
                               ifelse(is.na(wtmean_se10), 0, wtmean_se10^2)  + 
                               ifelse(is.na(wtmean_se08), 0, wtmean_se08^2) ) /
                             (ifelse(is.na(wtmean_se14), 0, 1) + 
                                ifelse(is.na(wtmean_se12), 0, 1) + 
                                ifelse(is.na(wtmean_se10), 0, 1) + 
                                ifelse(is.na(wtmean_se08), 0, 1))^2 
  )
  )

univar_agg$overallmean <- rowMeans(univar_agg[,grepl("mean[0-9]", names(univar_agg))], na.rm = TRUE)
univar_agg$overall_low <- univar_agg$overallmean - 1.96*univar_agg$overallse
univar_agg$overall_upp <- univar_agg$overallmean + 1.96*univar_agg$overallse

# univar_agg$overallse <- rowMeans(univar_agg[,grepl("mean_var[0-9]", names(univar_agg))], na.rm = TRUE)
write.xlsx(as.data.frame(univar_agg), file = "../output/univariate_agg.xlsx", sheetName = "Data", row.names = FALSE)

# Calculate aggregate statistics for bivariate case
bivar_agg <- bivariate_housing_list$GSS2014 %>% dplyr::select(var, var_name, var2, var_name2, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) %>%
  full_join(bivariate_housing_list$GSS2012 %>% dplyr::select(var, var_name, var2, var_name2, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , 
            by = c("var", "var_name", "var2", "var_name2"), suffix = c("14", "12")) %>%
  full_join(bivariate_housing_list$GSS2010 %>% dplyr::select(var, var_name, var2, var_name2, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , 
            by = c("var", "var_name", "var2", "var_name2"), suffix = c("12", "10")) %>%
  full_join(bivariate_housing_list$GSS2008 %>% dplyr::select(var, var_name, var2, var_name2, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , 
            by = c("var", "var_name", "var2", "var_name2"), suffix = c("10", "08"))%>%
  mutate(overallse = sqrt( ( ifelse(is.na(wtmean_se14), 0, wtmean_se14^2) + 
                               ifelse(is.na(wtmean_se12), 0, wtmean_se12^2) + 
                               ifelse(is.na(wtmean_se10), 0, wtmean_se10^2)  + 
                               ifelse(is.na(wtmean_se08), 0, wtmean_se08^2) ) /
                             (ifelse(is.na(wtmean_se14), 0, 1) + 
                                ifelse(is.na(wtmean_se12), 0, 1) + 
                                ifelse(is.na(wtmean_se10), 0, 1) + 
                                ifelse(is.na(wtmean_se08), 0, 1))^2 
  )
  )
bivar_agg$overallmean <-  rowMeans(bivar_agg[,grepl("mean[0-9]", names(bivar_agg))], na.rm = TRUE)
bivar_agg$overall_low <- bivar_agg$overallmean - 1.96*bivar_agg$overallse
bivar_agg$overall_upp <- bivar_agg$overallmean + 1.96*bivar_agg$overallse
write.xlsx(as.data.frame(bivar_agg), file = "../output/bivariate_agg.xlsx", sheetName = "Data", row.names = FALSE)

# Create overall stats by wave for link rates and total counts (weighted and unweighted)
overall_tbl <- gss_person %>% 
  group_by(gss_id_collection_code, snz_spine_ind) %>%
  summarise(unwttot = n()
            ,wttot = sum(gss_pq_person_FinalWgt_nbr))

write.xlsx(as.data.frame(overall_tbl), file = "../output/overall_desc_stats_unweighted.xlsx", sheetName = "All_waves", row.names = FALSE, 
           append = TRUE)


