
# ================================================================================================ #
# Description: Load data from output taken from si_main.sas where treatment and control population has already been created. 
#             The other population is the whole gss population with complete list of clean variables. 
#             This script takes the data in and 
#             prepares it for the regression analysis. 
#             What it does is factorizes the variables, add dummy variables and create income bands
#
# Input: [IDI_Sandpit].[Schema].of_gss_ind_variables_sh, 
#         [IDI_Clean_Version].data.address_notification,
#         [IDI_Sandpit].[Schema].[of_hnz_gss_population_wide]

#
# Output: gss_var
# 
# Author: W Lee
#
# Dependencies:
# SIAtoolbox - for data loading
# SAS executable program si_main.sas
# 1_shiny_house_regression_setup.R
#
#
# Notes:
# Please run 1_shiny_house_regression_setup first.
# This script is part of the main script of shiny_house.Rmd
#
#
# History (reverse order): 
# 28 Nov 2017 Nafees v1
# 07 Sep 2018 W Lee v2
# ================================================================================================ #


###Set DB name and create connection string
connstr <- set_conn_string(db = "IDI_Sandpit")


# Create the dataset with individuals in the GSS, and the address change details in the 3 years leading up to
# interview date and 3 years subsequent to interview date.
gss_var<-SIAtoolbox::read_sql_table(paste0("
select 
  datediff(DAY,ant_notification_date,gss_pq_interview_date) as days_in_house
  ,y.residence_count_b4
  ,y.days_in_house_b4
  ,y.change_house_b4
  ,y.b4_6M
  ,y.b4_6M_12M
  ,y.b4_1Y_2Y
  ,y.b4_2Y_3Y
  ,y.b4_6plus
  ,z.residence_count_after
  ,z.days_in_house_after
  ,z.change_house_after
  ,z.after_6M
  ,z.after_6M_12M
  ,z.after_1Y_2Y
  ,z.after_2Y_3Y
  ,z.after_6plus
  ,x.*  
from ( 
  select  
    addr.[ant_notification_date]
    ,addr.[ant_replacement_date]
    ,a.*
    ,person.snz_birth_month_nbr
    ,person.snz_birth_year_nbr
    ,person.snz_sex_code
    ,person.[snz_ethnicity_grp1_nbr]
    ,person.[snz_ethnicity_grp2_nbr]
    ,person.[snz_ethnicity_grp3_nbr]
    ,person.[snz_ethnicity_grp4_nbr]
    ,person.[snz_ethnicity_grp5_nbr]
    ,person.[snz_ethnicity_grp6_nbr]
  from [IDI_Sandpit].",sandpitname ,".[of_gss_ind_variables_sh] a
  inner join ", databasename , ".data.personal_detail person 
    on (a.snz_uid = person.snz_uid)
  inner join ", databasename , ".data.address_notification  addr 
    on (a.snz_uid =addr.snz_uid 
    and cast(a.gss_pq_interview_date as datetime) between addr.ant_notification_date and addr.ant_replacement_date)
) x
left join (
  select 
    aa.snz_uid
    ,count(*) as residence_count_b4
    ,datediff(DAY,max(ant_notification_date),min(gss_pq_interview_date)) as days_in_house_b4
    ,(case when count(*) > 1 then 1 else 0 end) as change_house_b4
    ,MAX(case when DATEDIFF(m,aa.ant_notification_date,ab.gss_pq_interview_date) between 25 and 36 then 1 else 0 end) as b4_2Y_3Y
    ,MAX(case when DATEDIFF(m,aa.ant_notification_date,ab.gss_pq_interview_date) between 13 and 24 then 1 else 0 end) as b4_1Y_2Y
    ,MAX(case when DATEDIFF(m,aa.ant_notification_date,ab.gss_pq_interview_date) between 7 and 12 then 1 else 0 end) as b4_6M_12M
    ,MAX(case when DATEDIFF(m,aa.ant_notification_date,ab.gss_pq_interview_date) > 6 then 1 else 0 end) as b4_6plus
    ,MAX(case when DATEDIFF(m,aa.ant_notification_date,ab.gss_pq_interview_date) between 0 and 6 then 1 else 0 end) as b4_6M
  from ", databasename , ".data.address_notification aa
  inner join [IDI_Sandpit].",sandpitname ,".[of_gss_ind_variables_sh] ab
    on (aa.snz_uid=ab.snz_uid
    and aa.ant_notification_date between cast(dateadd(yy, -3, ab.gss_pq_interview_date) as datetime) and cast(ab.gss_pq_interview_date as datetime) )
  group by aa.snz_uid
) y
  on y.snz_uid=x.snz_uid 
left join (
  select 
    aa.snz_uid
    ,count(*) as residence_count_after
    ,datediff(DAY,min(gss_pq_interview_date), MIN(ant_notification_date)) as days_in_house_after
    ,(case when count(*) > 1 then 1 else 0 end) as change_house_after
    ,MAX(case when DATEDIFF(m,aa.ant_notification_date,ab.gss_pq_interview_date) between -6 and -1 then 1 else 0 end) as after_6M
    ,MAX(case when DATEDIFF(m,aa.ant_notification_date,ab.gss_pq_interview_date) < -6 then 1 else 0 end) as after_6plus
    ,MAX(case when DATEDIFF(m,aa.ant_notification_date,ab.gss_pq_interview_date) between -12 and -7 then 1 else 0 end) as after_6M_12M
    ,MAX(case when DATEDIFF(m,aa.ant_notification_date,ab.gss_pq_interview_date) between -24 and -13 then 1 else 0 end) as after_1Y_2Y
    ,MAX(case when DATEDIFF(m,aa.ant_notification_date,ab.gss_pq_interview_date) between -36 and -25 then 1 else 0 end) as after_2Y_3Y 
  from ", databasename , ".data.address_notification aa
  inner join [IDI_Sandpit].",sandpitname ,".[of_gss_ind_variables_sh] ab
    on (aa.snz_uid=ab.snz_uid
    and aa.ant_notification_date between cast(dateadd(dd, 1, ab.gss_pq_interview_date) as datetime) and cast(dateadd(yy, 3, ab.gss_pq_interview_date) as datetime))
  group by aa.snz_uid
) z
on z.snz_uid=x.snz_uid"),
                     connstr, string = TRUE)


#removing life statisfaction of -1 (which is a proxy code for NULLs)
gss_var <- gss_var[-which(gss_var$life_satisfaction_ind==-1),]


#Clear up the warnings
assign("last.warning",NULL,envir = baseenv())

#Calculating Age as on gss interviews dates from address table
gss_var$birth<-as.Date(paste(15,gss_var$snz_birth_month_nbr,gss_var$snz_birth_year_nbr,sep = "/"),"%d/%m/%Y")
gss_var$age<-round(as.yearmon(gss_var$gss_pq_interview_date)-as.yearmon(gss_var$birth))

#Age square values in regression model...
gss_var$age2<-gss_var$age^2


#Calculating Age as on gss interviews dates from gss table
gss_var$gss_age<-gss_var$gss_pq_dvage_code


#creating month variable 
gss_var$months_in_house<-12*(as.yearmon(gss_var$gss_pq_interview_date)-as.yearmon(gss_var$ant_notification_date))

#gss_var$months_in_house<-gss_var$days_in_house/30.5

#Converting Gender variables to factor...
gss_var$snz_sex_code<-as.factor(gss_var$snz_sex_code)
levels(gss_var$snz_sex_code)<-c("MALE","FEMALE")


#Dummy variables for education qualifications as suggested by Conal...
gss_var$sch_qual_ind<-ifelse(gss_var$gss_pq_highest_qual_dev %in% c(1:3,11),1,0)
gss_var$higher_sch_qual_ind<-ifelse(gss_var$gss_pq_highest_qual_dev %in% c(4:6),1,0)
gss_var$tertiary_qual_ind<-ifelse(gss_var$gss_pq_highest_qual_dev %in% c(7),1,0)
gss_var$postgrad_qual_ind<-ifelse(gss_var$gss_pq_highest_qual_dev %in% c(8:10),1,0)
gss_var$no_qual_ind<-ifelse(gss_var$gss_pq_highest_qual_dev %in% c(0),1,0)



#re-leveling the hh_gss_income
gss_var$hh_gss_income<-factor(gss_var$hh_gss_income, levels =c("-Loss","0","1-5000","5001-10000","10001-15000","15001-20000","20001-25000"
                                                               ,"25001-30000","30001-35000","35001-40000","40001-70000","70001-100000"
                                                               ,"100001-150000","150001-Inf") )


#Converting to numeric and mid point to the income band... 
gss_var$hh_income_numeric<-gss_var$hh_gss_income
levels(gss_var$hh_income_numeric)<-c(0,0,seq(2500,37500,by=5000),55000,85000,125000,175000)
gss_var$hh_income_numeric<-as.numeric(as.character(gss_var$hh_income_numeric))

#Binning the month/days variables...
gss_var$month_cat<-cut(gss_var$months_in_house,breaks=c(0,3,6,9,12,15,18,24,36,48,182),right=FALSE)
levels(gss_var$month_cat)<-c("0 to 3M","3 to 6M","6 to 9M","9 to 12M","12 to 15M","15 to 18M","18 to 24M"
                             ,"24 to 36M","36 to 48M","48+Month")

gss_var$days_cat<-cut(gss_var$days_in_house,breaks=c(0,180,366,732,1095,5532),right=FALSE)
levels(gss_var$days_cat)<-c("0 to 6 Month","6 Month to Year","2 Year","3 Year","4+ Year")


#to add up change in residence for the 6 years before and after...
gss_var$residence_count_total<-rowSums(gss_var[,c("residence_count_b4","residence_count_after")],na.rm = TRUE)



#changing NA to zero's... for regression analysis...
for (i in c("residence_count_b4","days_in_house_b4","b4_2Y_3Y","b4_1Y_2Y","b4_6M_12M","b4_6plus", "b4_6M",
            "residence_count_after","days_in_house_after","after_2Y_3Y","after_1Y_2Y","after_6M_12M","after_6plus", "after_6M")){
  gss_var[is.na(gss_var[,i]),i] <- 0
}


#Imputing number of days in house to max of three year if residence count is equal to zero...
gss_var$days_in_house_b4<-ifelse(gss_var$residence_count_b4==0,1096,gss_var$days_in_house_b4)
gss_var$days_in_house_after<-ifelse(gss_var$residence_count_after==0,1096,gss_var$days_in_house_after)

#######################################
# To include the labour force indicator
#table(gss_var$gss_pq_lfs_dev)

gss_var$unemployed_ind<-ifelse(gss_var$gss_pq_lfs_dev==2,1,0)

gss_var$unemployed_ind<-as.factor(gss_var$unemployed_ind)


