# ================================================================================================ #
# Description: Testing if the recalibrated weights produced after linking to the spine have 
#   a distribution of outcomes/descriptive variabes that are consistent with the original 
#   distribution.
#
# Input: 
# of_rewt_gss_preson_replicates.R (or similar script) to produce datasets for consistency checking.
#
# Output: 
# results.csv providing p-values that the corresponding distributions are the same.
#
# Author: S Anastasiadis
#
# Dependencies:
# NA
#
# Notes:
# Output csv file is titled "comparison_pvals.csv". This has been inspected, with additional 
# comments and description in "validity of reweighting checks.xls".
#
# History (reverse order): 
# 22 Sep 2017 SA v1
# ================================================================================================ #

############### prepare data ###################

# build combined dataset
compare_data <- left_join(dataset,all_weights_df,by = 'snz_uid', suffix=c(".ds",".new")) %>%
  # select("snz_uid",
  #        contains('.new'),
  #        contains('HH_'),
  #        contains('qual_'),
  #        contains('health_'),
  #        contains('birth_year'),
  #        contains('born_nz'),
  #        contains('descent_'),
  #        contains('paid_work'),
  #        contains('dvage_'),
  #        contains('Region_'),
  #        contains('Eth_'),
  #        contains('AOD_'),
  #        contains('feel_life'),
  #        contains('house_'),
  #        contains('Wgt')) %>%
  dplyr::mutate(
    gss_pq_house_condition_code = ifelse( is.na(get("gss_pq_house_condition_code")), -1, gss_pq_house_condition_code )
         ,housing_satisfaction =  ifelse(is.na(get("housing_satisfaction")), -1, housing_satisfaction)
         ,gss_pq_safe_day_hood_code =  ifelse(is.na(get("gss_pq_safe_day_hood_code")), -1, gss_pq_safe_day_hood_code)
         ,lbr_force_status = factor(ifelse(is.na(as.character(get("lbr_force_status"))), "UNK", as.character(lbr_force_status)))
         )
# compare_data$gss_pq_house_condition_code[which(is.na(compare_data$gss_pq_house_condition_code))] <- -1
# compare_data$housing_satisfaction[which(is.na(compare_data$housing_satisfaction))] <- -1
# compare_data$gss_pq_safe_day_hood_code[which(is.na(compare_data$gss_pq_safe_day_hood_code))] <- -1
# compare_data$lbr_force_status <- as.character(compare_data$lbr_force_status)
# compare_data$lbr_force_status[which(is.na(compare_data$lbr_force_status))] <- "UNK"
# compare_data$lbr_force_status <- as.factor(compare_data$lbr_force_status)



# list of columns containing weights
wgt_prefix <- c("link_","gss_pq_person_")
wgt_list   <- c(  'FinalWgt_nbr', paste('FinalWgt',1:100,'_nbr',sep=''))

# list of columns containing parameters whose distribution we care about
param_list <- c("gss_hq_sex_dev"
                ,"gss_hq_birth_month_nbr"
                ,"gss_hq_birth_year_nbr"
                ,"gss_hq_house_trust"
                ,"gss_hq_house_own"
                ,"gss_hq_house_pay_mort_code"
                ,"gss_hq_house_pay_rent_code"
                ,"gss_hq_house_who_owns_code"
                ,"gss_pq_HH_tenure_code"
                ,"gss_pq_HH_crowd_code"
                ,"gss_pq_house_mold_code"
                ,"gss_pq_house_cold_code"
                ,"gss_pq_house_condition_code"
                ,"housing_satisfaction"
                ,"gss_pq_prob_hood_noisy_ind"
                ,"gss_pq_safe_night_pub_trans_code"
                ,"gss_pq_safe_night_hood_code"
                ,"gss_pq_safe_day_hood_code"
                ,"gss_pq_discrim_rent_ind"
                ,"gss_pq_crimes_against_ind"
                ,"gss_pq_cult_identity_code"
                ,"gss_pq_ment_health_code"
                ,"gss_pq_phys_health_code"
                ,"gss_pq_lfs_dev"
                ,"gss_pq_highest_qual_dev"
                ,"gss_pq_feel_life_code"
                # ,"gss_pq_voting"
                ,"gss_pq_time_lonely_code"
                ,"gss_hq_household_inc1_dev"
                ,"gss_pq_dvage_code"
                ,"gss_pq_eth_european_code"
                ,"gss_pq_eth_maori_code"
                ,"gss_pq_eth_samoan_code"
                ,"gss_pq_eth_cookisland_code"
                ,"gss_pq_eth_tongan_code"
                ,"gss_pq_eth_nieuan_code"
                ,"gss_pq_eth_chinese_code"
                ,"gss_pq_eth_indian_code"
                ,"gss_pq_HH_comp_code"
                ,"gss_hq_regcouncil_dev"
                ,"adult_count"
                ,"pub_trpt_safety_ind"
                ,"safety_ind"
                ,"house_crowding_ind"
                ,"crime_exp_ind"
                ,"ct_house_pblms"
                ,"phys_health_sf12_score"
                ,"ment_health_sf12_score"
                # ,"lbr_force_status"
                ,"time_lonely_ind"
                ,"voting_ind"
                # ,"hh_gss_income"
                ,"life_satisfaction_ind"
                )

############### run checks ###################

for(i in levels(dataset$gss_id_collection_code) ){
  
  print(i)
  # Filter the required GSS wave for analysis
  test.ds <- compare_data %>% filter(gss_id_collection_code.ds == i)
  
  # storage for Mann-Whitney test results
  sink(paste0('../output/comparison_pvals_',i,'.csv'))
  
  # Mann-Whitney U Tests
  cat('Mann-Whitney U Tests\n')
  # column headers
  cat('SIA wgt,GSS wgt,',paste(param_list,collapse=','),'\n')
  # iterate through weights
  for(this_wgt in wgt_list){
    
    # current weight
    cat(this_wgt)
    # weight codes
    this_sia_wgt <- paste0(wgt_prefix[1],this_wgt)
    this_snz_wgt <- paste0(wgt_prefix[2],this_wgt)
    # test distribution of weights
    test <- distribution_compare(pop1 = test.ds[[this_sia_wgt]], pop2 = test.ds[[this_snz_wgt]], standardize = TRUE)
    cat(',',test$MW_test)
    # test distribution of outcomes
    for(param in param_list){
      # weighted sampling of parameter
      tmp_samples <- make_samples(test.ds[[param]], wgt1=test.ds[[this_sia_wgt]], wgt2=test.ds[[this_snz_wgt]])
      # compare
      test <- distribution_compare(pop1 = tmp_samples$pop1, pop2 = tmp_samples$pop2)
      cat(',',test$MW_test)
    }
    # end line
    cat('\n')
  }
  
  # Kolmogorov-Smirnov Tests
  cat('Kolmogorov-Smirnov Tests\n')
  # column headers
  cat('SIA wgt,GSS wgt,',paste(param_list,collapse=','),'\n')
  # iterate through weights
  for(this_wgt in wgt_list){
    # current weight
    cat(this_wgt)
    # weight codes
    this_sia_wgt <- paste0(wgt_prefix[1],this_wgt)
    this_snz_wgt <- paste0(wgt_prefix[2],this_wgt)
    # test distribution of weights
    test <- distribution_compare(pop1 = test.ds[[this_sia_wgt]], pop2 = test.ds[[this_snz_wgt]], standardize = TRUE)
    cat(',',test$KS_test)
    # test distribution of outcomes
    for(param in param_list){
      # weighted sampling of parameter
      tmp_samples <- make_samples( test.ds[[param]] , wgt1=test.ds[[this_sia_wgt]], wgt2=test.ds[[this_snz_wgt]])
      # compare
      test <- distribution_compare(pop1 = tmp_samples$pop1, pop2 = tmp_samples$pop2)
      cat(',',test$KS_test)
    }
    # end line
    cat('\n')
  }
  
  sink()
  
  # plot standardized distribution of weights
  tmp <- test.ds %>%
    # select(gss_pq_person_FinalWgt_nbr,link_FinalWgt_nbr) %>%
    mutate(SNZ_wgt = (gss_pq_person_FinalWgt_nbr - mean(gss_pq_person_FinalWgt_nbr))/sd(gss_pq_person_FinalWgt_nbr)) %>%
    mutate(SIA_wgt = (link_FinalWgt_nbr-mean(link_FinalWgt_nbr,na.rm=TRUE))/sd(link_FinalWgt_nbr,na.rm=TRUE))
  ggplot() +
    geom_density(data=tmp,aes(x=SNZ_wgt),col='red') +
    geom_density(data=tmp %>% filter(!is.na(SIA_wgt)),aes(x=SIA_wgt))
}



