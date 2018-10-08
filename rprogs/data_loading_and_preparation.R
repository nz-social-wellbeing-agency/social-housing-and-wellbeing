# ================================================================================================ #
# Description: Polished data preparation used for the comparison of the treated & control / before & after
# populations to produce output for submission to checking as part of the outcomes-framework social
# housing test case (paper 5).
#
# Input: SQL database prepared by SAS and SQL scripts that merges NZGSS and HNZ tables.
#
# Output: Prepared dataset, along with a list of variables to analyse.
# 
# Author: S. Anastasiadis
#
# Dependencies:
# SIAtoolbox - for data loading
# function_for_treat_control.R - for testing functions
#
# Notes:
# This script is a subscript to run_analysis_treat_control.R
# This script checks that the required columns exist in the dataset before making use of them
# and will throw errors if the specified columns are missing.
#
# History (reverse order): 
# 28 Nov 2017 SA v1
# ================================================================================================ #

################ Setup ################

# source functions if running stand-alone
source('./function_for_treat_control.R')

# Overwrite the sqlwrite function in RODBC package with a modified version.
# This function fixes an issue with RODBC::sqlSave function, provided that the schema name is provided
# with square brackets while specifying table name. Only works with fast= FALSE in sqlSave function
source("./sqlwrite.R")
assignInNamespace("sqlwrite", value = sqlwrite, ns = "RODBC")

################ Load SQL dataset ################

# Connection to the database
connstr <- set_conn_string(db = "IDI_Sandpit")

# Read in GSS & HNZ  population
dataset <- SIAtoolbox::read_sql_table(paste0("SELECT *
                                      FROM [IDI_Sandpit].",sandpitname,".[of_hnz_gss_population_wide]")
                                      ,connstr, string = TRUE)

################ Data re-labeling & preparations ################

# list of variable columns needed in dataset
column_names_used <- c("snz_sex_code", "snz_ethnicity_grp1_nbr", "snz_ethnicity_grp2_nbr", "snz_ethnicity_grp3_nbr",
                       "snz_ethnicity_grp4_nbr", "snz_ethnicity_grp5_nbr", "snz_ethnicity_grp6_nbr", "house_crowding_ind",
                       "gss_pq_house_cold_code", "gss_pq_house_condition_code", "gss_pq_house_mold_code",
                       "gss_pq_discrim_rent_ind", "housing_sat_ind", "gss_pq_prob_hood_noisy_ind", "crime_exp_ind",
                       "pub_trpt_safety_ind", "safety_ind", "time_lonely_ind", "voting_ind", "cult_identity_ind",
                       "snz_spine_ind", "num_overseas_trips", "life_satisfaction_bin",
                       "gss_pq_highest_qual_dev", "num_address_changes", "adult_count", "gss_hq_household_inc1_dev",
                       "housing_groups", "life_satisfaction_ind", "gss_pq_dvage_code", "months_interview_to_entry",
                       "gss_pq_phys_health_code", "gss_pq_ment_health_code", "hh_gss_income", "gss_pq_HH_crowd_code",
                       "gss_pq_cult_identity_code", "gss_pq_lfs_dev", "gss_pq_material_wellbeing_code",
                       "gss_pq_ELSIDV1","hh_gss_equi_income_median_lw_inf","hh_gss_income_median_lw_inf",
                       "hh_gss_equi_income_median_up_inf","hh_gss_income_median_up_inf",
                       "no_access_natural_space",
                       "no_free_time"
                       
)
# check input columns exist in the dataset before attempting to use them
for(name in column_names_used){
  assert(name %in% names(dataset), sprintf("column %s does not exist in dataset", name))
}

#
#### PRODUCE MORE USEFUL LABELS FOR BINARY INDICATORS ####
# age^2 - for regressions
dataset <- mutate(dataset, age2 = as_at_age^2)
# sex - use SNZ sex as trusted to be higher quality
dataset <- mutate(dataset, sex = ifelse(snz_sex_code == 1,'Male','Female'))
# ethnicity - use SNZ ethnicity as records whether person has every identified as ethnicity;
# merge Asian, Meela and Other into Other due to small sample size
dataset <- mutate(dataset, eth_european = ifelse(snz_ethnicity_grp1_nbr == 1,'Y','N'))
dataset <- mutate(dataset, eth_maori = ifelse(snz_ethnicity_grp2_nbr == 1,'Y','N'))
dataset <- mutate(dataset, eth_pacifica = ifelse(snz_ethnicity_grp3_nbr == 1,'Y','N'))
dataset <- mutate(dataset, eth_other = ifelse(snz_ethnicity_grp4_nbr == 1 
                                                 | snz_ethnicity_grp5_nbr == 1 
                                                 | snz_ethnicity_grp6_nbr == 1,'Y','N'))
# housing condition outcomes
dataset <- mutate(dataset, house_crowding_ind = ifelse(house_crowding_ind == 1,'Y','N'))
dataset <- mutate(dataset, house_cold_code = ifelse(gss_pq_house_cold_code == 1,'Y','N'))
dataset <- mutate(dataset, house_condition_issue = ifelse(gss_pq_house_condition_code == 1,'Y','N'))
dataset <- mutate(dataset, house_mold_code = ifelse(gss_pq_house_mold_code == 1,'Y','N'))
dataset <- mutate(dataset, discrim_rent_ind = ifelse(gss_pq_discrim_rent_ind == 1,'Y','N'))
dataset <- mutate(dataset, housing_sat_ind = ifelse(housing_sat_ind == 1,'Y','N'))
# community outcomes
dataset <- mutate(dataset, hood_noisy_ind = ifelse(gss_pq_prob_hood_noisy_ind == 1,'Y','N'))
dataset <- mutate(dataset, crime_exp_ind = ifelse(crime_exp_ind == 1,'Y','N'))
dataset <- mutate(dataset, pub_trpt_safety_ind = ifelse(pub_trpt_safety_ind == 1,'Y','N'))
dataset <- mutate(dataset, safe_hood_night = ifelse(safety_ind == 1,'Y','N'))
dataset <- mutate(dataset, time_lonely_ind = ifelse(time_lonely_ind == 1,'Y','N'))
dataset <- mutate(dataset, voting_ind = ifelse(voting_ind == 1,'Y','N'))
dataset <- mutate(dataset, cult_identity_ind = ifelse(cult_identity_ind == 1,'Y','N'))
# admin
dataset <- mutate(dataset, snz_spine_ind = ifelse(snz_spine_ind == 1,'Connected to spine','Not part of spine'))
dataset <- mutate(dataset, overseas_trip  = ifelse(is.na(num_overseas_trips) ,'N','Y'))
# life satisfaction
dataset <- mutate(dataset, life_satisfaction_bin = ifelse(life_satisfaction_bin == 1,'Y','N'))
# free space and leisure time 21/5/2018
dataset <- mutate(dataset, no_access_natural_space = ifelse(no_access_natural_space == 1,'Y','N'))
dataset <- mutate(dataset, no_free_time = ifelse(no_free_time == 1,'Y','N'))

# NZGSS wave to numeric for time trend
dataset <- mutate(dataset, wave = ifelse(gss_pq_collection_code == "GSS2008",1,
                                                 ifelse(gss_pq_collection_code == "GSS2010",2,
                                                        ifelse(gss_pq_collection_code == "GSS2012",3,4))))

#
#### PRODUCE MORE USEFUL LABELS FOR CATEGORICAL VARIABLES ####
# In almost all cases grouped due to small sample size.
#
# highest qualification
dataset <- mutate(dataset, highest_qual = ifelse(gss_pq_highest_qual_dev %in% c(1,2,3,4,11),'high school qual',
                      ifelse(gss_pq_highest_qual_dev %in% c(5,6,7,8,9,10,12),'post high school qual','no qual')))
# number of address changes
# between 1 year and 1 week before move in data (1 week before move in date avoids counting HNZ move)
dataset <- mutate(dataset, address_change = ifelse(is.na(num_address_changes),'none',
                                                   ifelse(num_address_changes %in% c(1,2),'1-2 changes','3+ changes')))
# number of adults in household
dataset <- mutate(dataset, adult_count = ifelse(adult_count == 1,'1 adult',ifelse(adult_count == 2,'2 adults','3+ adults')))
# NZGSS reported household income - as a measure from admin data could not be constructed
dataset <- mutate(dataset, hh_income = cut(gss_hq_household_inc1_dev, c(-2,6,10,Inf), labels=c('<$20k','$20-40k','$40k+')))

#NZGSS income inflated upper
dataset <- mutate(dataset, hh_income_equp=ifelse(hh_gss_equi_income_median_up_inf < 20000,'<$20k',
                                                     ifelse(hh_gss_equi_income_median_up_inf >= 20000 
                                                      & hh_gss_equi_income_median_up_inf <= 40000,'$20-40k','$40k+')))

#NZGSS income inflated lower
dataset <- mutate(dataset, hh_income_eqdw=ifelse(hh_gss_equi_income_median_lw_inf < 20000,'<$20k',
                                                     ifelse(hh_gss_equi_income_median_lw_inf >= 20000 
                                                            & hh_gss_equi_income_median_lw_inf <= 40000,'$20-40k','$40k+')))


#Converting to numeric and mid point to the income band... 
dataset$hh_gss_income <- factor(dataset$hh_gss_income, levels =c("0","5001-10000","10001-15000","15001-20000",
                                                                       "20001-25000","25001-30000","30001-35000",
                                                                       "35001-40000","40001-70000","70001-100000") )


dataset <- mutate(dataset,hh_income_numeric=hh_gss_income)

# levels(dataset$hh_income_numeric)
levels(dataset$hh_income_numeric)<-c(0,seq(7500,37500,by=5000),55000,85000)
dataset$hh_income_numeric<-as.numeric(as.character(dataset$hh_income_numeric))

# housing type
levels(dataset$housing_groups) <- list('Other' = c('Non Subsidised-Own Home','Non Subsidised-Renting','Other Social Housing'),
                                       'Social Housing' = 'IRR',
                                       'Accommodation Supplement-Renting' = 'Accommodation Supplement-Renting')
# life satisfaction
dataset <- mutate(dataset, life_satisfaction_merge = cut(life_satisfaction_ind, c(-1,2,3,4,5),
                                                       labels=c('(very) bad','neutral','good','very good')))

#
#### CONVERT NUMERIC VARIABLES TO CATEGORIES ####
#
# categorized age
dataset <- mutate(dataset, age_cat = cut(gss_pq_dvage_code, c(-1,24,39,59,1000),
                                         labels=c('15-24yrs','25-39yrs','40-59yrs','60+yrs')))
# gap between interview and move in date
dataset <- mutate(dataset, months_interview_to_entry = cut(abs(months_interview_to_entry), c(-1,3,6,9,15),
                                                               labels=c('0-3 months','4-6 months','7-9 months','10+ months')))
# SF12 physical and mental health - category boundaries chosen somewhat arbitrarily
dataset <- mutate(dataset, gss_pq_phys_health_code = ifelse(gss_pq_phys_health_code == 777,NA,gss_pq_phys_health_code))
dataset <- mutate(dataset, gss_pq_ment_health_code = ifelse(gss_pq_ment_health_code == 777,NA,gss_pq_ment_health_code))
dataset <- mutate(dataset, sf12_phys_hth = cut(gss_pq_phys_health_code, c(-1,35,50,100),
                                              labels=c('low (0-35)','medium (36-50)','high (51+)')))
dataset <- mutate(dataset, sf12_ment_hth = cut(gss_pq_ment_health_code, c(-1,35,50,100),
                                              labels=c('low (0-35)','medium (36-50)','high (51+)')))
# Economic Living Standard Index
dataset <- mutate(dataset, ELSIDV = ifelse(gss_pq_ELSIDV1 <= 18,"lower 20%","upper 80%"))
# material wellbeing
dataset <- mutate(dataset, material_wellbeing = ifelse(gss_pq_material_wellbeing_code <= 9,"lower 20%","upper 80%"))
# combine ELSI and material wellbeing
dataset <- mutate(dataset, material_wellbeing_ELSI = NA)
dataset$material_wellbeing_ELSI[!is.na(dataset$ELSIDV)] = dataset$ELSIDV[!is.na(dataset$ELSIDV)]
dataset$material_wellbeing_ELSI[!is.na(dataset$material_wellbeing)] = dataset$material_wellbeing[!is.na(dataset$material_wellbeing)]

#
#### RELABEL FACTOR VARIABLES FOR CLARITY ####
#
# highest qualification
dataset <- mutate(dataset, gss_pq_highest_qual_dev = factor(gss_pq_highest_qual_dev,
                                                            c(0,1,2,3,4,5,6,7,8,9,10,11,12),
                                                            labels=c('no qual','level 1 cert','level 2 cert','level 3 cert',
                                                                     'level 4 cert','level 5 cert','level 6 cert','bachelors',
                                                                     'postgrad & honours','masters','doctorate',
                                                                     'overseas secondary school','other')))
# income
dataset <- mutate(dataset, hh_gss_income = factor(hh_gss_income,levels=c('-Loss','0','1-5000','5001-10000','10001-15000',
                                                                         '15001-20000','20001-25000','25001-30000',
                                                                         '30001-35000','35001-40000','40001-70000',
                                                                         '70001-100000','100001-150000','150001-Inf')))
# number of bedrooms required
dataset <- mutate(dataset, gss_pq_HH_crowd_code = factor(gss_pq_HH_crowd_code,levels=c(1,2,3,4,5),
                                                         labels=c('2+ bedrm needed','1 bedrm needed',
                                                                  'no bedrm needed','1 bedrm spare','2+ bedrm spare')))
# ability to express cultural identity
dataset <- mutate(dataset, gss_pq_cult_identity_code = factor(gss_pq_cult_identity_code,c(11,12,13,14,15),
                                                              labels=c('v. easy','easy','neutral','hard','v. hard')))
# labour force status
dataset <- mutate(dataset, labour_force_status = factor(gss_pq_lfs_dev,levels=c(1,2,3),
                                                        labels=c('employed','unemployed','not in labour force')))
#

#### TIDY UP ####

# house_condition and housing_satisfaction were not asked in the 2014 GSS wave
# hence the 2014 values are set equal to NA
dataset <- mutate(dataset, house_condition_issue = ifelse(gss_pq_collection_code == "GSS2014",NA,house_condition_issue))
dataset <- mutate(dataset, housing_sat_ind = ifelse(gss_pq_collection_code == "GSS2014",NA,housing_sat_ind))

# convert all character fields to factors for ease of analysis
for(name in names(dataset)){
  if("character" %in% class(dataset[[name]]))
    dataset[[name]] <- as.factor(dataset[[name]])
}

################ List of variables to analyse ################

# List of dataset columns to analyse.
# We then loop over this list, carrying out the same analysis on each entry.
#
# Each entry takes the form:
# c(<name_of_dataset_column>, <text_description_of_column>, <analysis_to_run> = c('table', 'test', 'both'))
columns_to_analyse <- list(
  c('age_cat', 'Age category of respondent','both'),
  c('eth_european', 'Respondent identifies as European','both'),
  c('eth_maori', 'Respondent identifies as Maori','both'),
  c('eth_pacifica', 'Respondent identifies as Pacific Island','both'),
  c('eth_other', 'Respondent identifies as another ethnicity','both'),
  c('sex', 'Sex','both'),
  c('highest_qual', 'Highest qualification obtained','both'),
  c('lbr_force_status', 'Labour force status','both'),
  c('hh_income', 'Household income category (from NZGSS)','both'),
  
  c('gss_pq_collection_code', 'NZGSS wave','both'),
  c('months_interview_to_entry', 'Months between interview and entry date','table'),
  c('housing_groups', 'Tenancy type','table'),
  
  c('life_satisfaction_bin', 'Are you satisfied with your life','both'),
  c('hood_noisy_ind', 'Is noise a problem in your neighbourhood','both'),
  c('house_crowding_ind', 'Is your house crowded','both'),
  c('pub_trpt_safety_ind', 'Do you feel safe on public transport at night','both'),
  c('safe_hood_night', 'Do you feel safe in your neighbourhood at night','both'),
  c('time_lonely_ind', 'Felt lonely some or most or all of the time in the last four weeks','both'),
  c('voting_ind', 'Did you vote in the last election','both'),
  c('cult_identity_ind', 'It easy to express your cultural identity','both'),
  c('house_cold_code', 'Is your house cold','both'),
  c('house_condition_issue', 'Being in poor condition is an issue with the house','both'),
  c('house_mold_code', 'Is your house moldy','both'),
  c('housing_sat_ind', 'Do you feel satisfied with your housing','both'),
  c('crime_exp_ind', 'Crime committed against you in last 12 months','both'),
  
  c('adult_count', 'Number of adults in the house','both'),
  c('overseas_trip', 'Did you travel overseas in the year before moving into social housing','both'),
  c('address_change', 'Number of address changes in the year prior to moving into social housing (excl. move in)','both'),
  
  c('life_satisfaction_merge', 'How satisfied are you with your life (numerical)','table'),
  c('life_satisfaction_ind', 'How satisfied are you with your life','test'),
  
  c('hnz_na_analy_score_access_text', 'Need HNZ due to accessibility','table'),
  c('hnz_na_analy_score_adeq_text', 'Need HNZ due to adequatness','table'),
  c('hnz_na_analy_score_afford_text', 'Need HNZ due to affordability','table'),
  c('hnz_na_analy_score_suitably_text', 'Need HNZ due to suitability','table'),
  c('hnz_na_analy_score_sustain_text', 'Need HNZ due to sustainability','table'),
  
  c('sf12_phys_hth', 'Categorized SF12 physical health','table'),
  c('sf12_ment_hth', 'Categorized SF12 mental health','table'),
  c('gss_pq_phys_health_code', 'SF12 physical health','test'),
  c('gss_pq_ment_health_code', 'SF12 mental health','test'),
  
  c('ELSIDV', 'ELSI score (2008-2012 waves only)', 'both'),
  c('material_wellbeing_ELSI', 'material wellbeing and ELSI', 'both'),
  c('no_access_natural_space', 'access to natural space bush', 'both'),
  c('no_free_time', 'have free time', 'both')
)

# check columns for analysis exist in the dataset before attempting to use them
for(item in columns_to_analyse){
  name <- item[[1]]
  assert(name %in% names(dataset), sprintf("column %s does not exist in dataset", name))
}
