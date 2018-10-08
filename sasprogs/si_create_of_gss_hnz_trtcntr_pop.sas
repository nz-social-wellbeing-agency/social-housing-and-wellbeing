/*********************************************************************************************************
DESCRIPTION: 
Combines GSS individuals and admin related variables to create a dataset of treat-control analysis.

INPUT:
[IDI_Sandpit].[{schemaname}].[of_hnz_gss_population] - base GSS & HNZ intersect population
[IDI_Sandpit].[{schemaname}].[of_gss_ind_variables] - survey variables
[IDI_Sandpit].[{schemaname}].[gss_pop_char] - demographics from admin data
[IDI_Cleanxxx].[data].[person_overseas_spell] - count of overseas spells
[IDI_Cleanxxx].[data].[address_notification] - count of address changes


OUTPUT:
[IDI_Sandpit].[{schemaname}].[of_hnz_gss_population_wide] = dataset for treat-control analysis

AUTHOR: 
Simon Anastasiadis

DEPENDENCIES:
NA

NOTES:   
1. All GSS waves are available only from IDI_Clean_20171027 onwards.


HISTORY: 
29 Nov 2017 VB Created a SAS wrapper
06 Sep 2018 BV Converted to SAS

***********************************************************************************************************/


/*%si_run_sqlscript(filepath = "&si_source_path.\sql\joining_all_tables_for_R.sql"*/
/*	, db_odbc = &idi_version._srvprd*/
/*	, db_schema = "&si_proj_schema."*/
/*	, replace_string = "{schemaname}");*/




proc sql;

	connect to odbc (dsn=&si_idi_dsnname.);

	create table work._temp_of_hnz_gss_population_wide as
	select *
	from connection to odbc(		
	
	/* Join everything together */
	select z.[gss_pq_collection_code]
	      ,z.[snz_uid]
	      ,z.[hnz_application_date]
	      ,z.[hnz_application_exit_date]
	      ,z.[hnz_application_exit_status]
	      ,z.[gss_pq_interview_date] as interview_date
	      ,z.[tenancy_entry_date]
	      ,z.[months_interview_to_entry]
	      ,z.[treat_control]
	      ,z.[hnz_na_analy_score_afford_text]
	      ,z.[hnz_na_analy_score_adeq_text]
	      ,z.[hnz_na_analy_score_suitably_text]
	      ,z.[hnz_na_analy_score_sustain_text]
	      ,z.[hnz_na_analy_score_access_text]
	      ,z.[hnz_na_analysis_total_score_text]
	      ,z.[hnz_na_hshd_size_nbr]
	      ,z.[hnz_apply_type]
		  /*,a.[link_set_key]*/
	      ,a.[snz_sex_code]
	      ,a.[snz_birth_year_nbr]
	      ,a.[snz_birth_month_nbr]
	      ,a.[snz_ethnicity_grp1_nbr]
	      ,a.[snz_ethnicity_grp2_nbr]
	      ,a.[snz_ethnicity_grp3_nbr]
	      ,a.[snz_ethnicity_grp4_nbr]
	      ,a.[snz_ethnicity_grp5_nbr]
	      ,a.[snz_ethnicity_grp6_nbr]
	      /*,a.[snz_deceased_year_nbr]
	      ,a.[snz_deceased_month_nbr]
	      ,a.[snz_parent1_uid]
	      ,a.[snz_parent2_uid]
	      ,a.[snz_person_ind]
	      ,a.[total_score]
	      ,a.[rnk]*/
	      ,a.[as_at_age] /* as at move in date */
	      ,a.[prioritised_eth]
	      ,a.[cen_ind_iwi1_code]
	      ,a.[iwi1_desc]
	      ,a.[cen_ind_iwi2_code]
	      ,a.[iwi2_desc]
	      ,a.[cen_ind_iwi3_code]
	      ,a.[iwi3_desc]
	      ,a.[ant_region_code]
	      ,a.[ant_ta_code]
	      ,a.[ant_meshblock_code]
	      ,a.[snz_ird_ind]
	      ,a.[snz_moe_ind]
	      ,a.[snz_dol_ind]
	      ,a.[snz_msd_ind]
	      ,a.[snz_jus_ind]
	      ,a.[snz_acc_ind]
	      ,a.[snz_moh_ind]
	      ,a.[snz_dia_ind]
	      ,a.[snz_cen_ind]
	      ,a.[uid_miss_ind_cnt]
		  ,d.[snz_gss_hhld_uid]
	      ,d.[snz_spine_ind]
	      ,d.[gss_id_collection_code]
	      ,d.[gss_pq_interview_date]
	      ,d.[gss_hq_interview_start_date]
	      ,d.[gss_hq_sex_dev]
	      ,d.[gss_hq_birth_month_nbr]
	      ,d.[gss_hq_birth_year_nbr]
	      ,d.[gss_hq_house_trust]
	      ,d.[gss_hq_house_own]
	      ,d.[gss_hq_house_pay_mort_code]
	      ,d.[gss_hq_house_pay_rent_code]
	      ,d.[gss_hq_house_who_owns_code]
	      ,d.[gss_pq_hh_tenure_code]
	      ,d.[gss_pq_HH_crowd_code]
	      ,d.[gss_pq_house_mold_code]
	      ,d.[gss_pq_house_cold_code]
	      ,d.[gss_pq_house_condition_code]
	      ,d.[housing_satisfaction]
	      ,d.[gss_pq_prob_hood_noisy_ind]
	      ,d.[gss_pq_safe_night_pub_trans_code]
	      ,d.[gss_pq_safe_night_hood_code]
	      ,d.[gss_pq_safe_day_hood_code]
	      ,d.[gss_pq_discrim_rent_ind]
	      ,d.[gss_pq_crimes_against_ind]
	      ,d.[gss_pq_cult_identity_code]
	      ,d.[gss_pq_ment_health_code]
	      ,d.[gss_pq_phys_health_code]
	      ,d.[gss_pq_lfs_dev]
	      ,d.[gss_pq_highest_qual_dev]
	      ,d.[gss_pq_feel_life_code]
	      ,d.[gss_pq_voting]
	      ,d.[gss_pq_time_lonely_code]
	      ,d.[gss_hq_household_inc1_dev]
	      ,d.[gss_pq_dvage_code]
	      ,d.[gss_pq_eth_european_code]
	      ,d.[gss_pq_eth_maori_code]
	      ,d.[gss_pq_eth_samoan_code]
	      ,d.[gss_pq_eth_cookisland_code]
	      ,d.[gss_pq_eth_tongan_code]
	      ,d.[gss_pq_eth_nieuan_code]
	      ,d.[gss_pq_eth_chinese_code]
	      ,d.[gss_pq_eth_indian_code]
	      ,d.[gss_pq_hh_comp_code]
	      ,d.[gss_hq_regcouncil_dev]
	      ,d.[adult_count]
	      ,d.[gss_pq_person_seinwgt_nbr]
	      ,d.[pub_trpt_safety_ind]
	      ,d.[safety_ind]
	      ,d.[house_crowding_ind]
	      ,d.[crime_exp_ind]
	      ,d.[ct_house_pblms]
	      ,d.[phys_health_sf12_score]
	      ,d.[ment_health_sf12_score]
	      ,d.[lbr_force_status]
	      ,d.[time_lonely_ind]
	      ,d.[voting_ind]
	      ,d.[hh_gss_income]
	      ,d.[life_satisfaction_ind]
	      ,d.[acc_sup_ind]
	      ,d.[housing_status]
	      ,d.[housing_groups]
	      ,d.[life_satisfaction_bin]
	      ,d.[treat_control_main]
	      ,d.[treat_control_sen]
		  ,d.[cult_identity_ind]
		  ,d.[housing_sat_ind]
		  ,e.num_overseas_trips
		  ,f.num_address_changes
		  ,d.gss_pq_material_wellbeing_code
		  ,d.gss_pq_ELSIDV1
		  ,d.hh_gss_income_median_lw_inf
		  ,d.hh_gss_income_median_inf
		  ,d.hh_gss_income_median_up_inf
		  ,d.hh_gss_equi_income_median_lw_inf
		  ,d.hh_gss_equi_income_median_inf
		  ,d.hh_gss_equi_income_median_up_inf
		  ,d.no_access_natural_space
		  ,d.no_free_time
	  from [IDI_Sandpit].[&si_proj_schema.].[of_hnz_gss_population] z

	  /* personal characteristics */
	  left join [IDI_Sandpit].[&si_proj_schema.].[gss_pop_char] a
	  on z.snz_uid = a.snz_uid

	  /* gss individual variables */
	  left join [IDI_Sandpit].[&si_proj_schema.].[of_gss_ind_variables_sh] d
	  on a.snz_uid = d.snz_uid

	  /* id numbers and number of trips out of country in last year */
	  left join ( 
	      select snz_uid,count(*) as num_overseas_trips
	      from (
	      select b.[snz_uid]
	            ,[gss_pq_interview_date]
	      	    ,[pos_applied_date]
	            ,[pos_ceased_date]
	        from [IDI_Sandpit].[&si_proj_schema.].[of_hnz_gss_population] a
	        inner join [&idi_version.].[data].[person_overseas_spell] b
	        on a.snz_uid = b.snz_uid
	        and (([pos_applied_date] between  dateadd(year,-1,[tenancy_entry_date]) and dateadd(week,-1,[tenancy_entry_date]))
	            or ([pos_ceased_date] between dateadd(year,-1,[tenancy_entry_date]) and dateadd(week,-1,[tenancy_entry_date])))
	      ) k
	      group by snz_uid
	  ) e
	  on a.snz_uid = e.snz_uid

	  /* id numbers and number of address changes in last year */
	  left join ( 
	      select snz_uid,count(*) as num_address_changes
	      from (
	      select b.[snz_uid]
	            ,[gss_pq_interview_date]
	            ,[ant_notification_date]
	            ,[ant_replacement_date]
	        from [IDI_Sandpit].[&si_proj_schema.].[of_hnz_gss_population] a
	        inner join [&idi_version.].[data].[address_notification] b
	        on a.snz_uid  = b.snz_uid
	        and (([ant_notification_date] between dateadd(year,-1,[tenancy_entry_date]) and dateadd(week,-1,[tenancy_entry_date]))
	            or ([ant_replacement_date] between dateadd(year,-1,[tenancy_entry_date]) and dateadd(week,-1,[tenancy_entry_date])))
	        ) k
	        group by snz_uid
	  ) f
	  on a.snz_uid = f.snz_uid


	);

	disconnect from odbc;

quit;

/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=work._temp_of_hnz_gss_population_wide,
	si_write_table_out=&si_sandpit_libname..of_hnz_gss_population_wide
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);

/* Remove temporary datasets */
proc datasets lib=work;
	delete _temp_:;
run;