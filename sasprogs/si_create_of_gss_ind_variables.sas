/*********************************************************************************************************
DESCRIPTION: 
Combines all the GSS person information across different waves into one single 
table. Only a limited set of variables which are useful for the outcomes framework project have 
been retained.

INPUT:
[&idi_version.].[gss_clean].[gss_person] = 2014 GSS person table
[&idi_version.].[gss_clean].[gss_person_2012] = 2012 GSS person table
[&idi_version.].[gss_clean].[gss_person_2010] = 2010 GSS person table
[&idi_version.].[gss_clean].[gss_person_2008] = 2008 GSS person table

OUTPUT:
sand.of_gss_ind_variables_sh = dataset with person variables for GSS

AUTHOR: 
V Benny

DEPENDENCIES:
NA

NOTES:   
1. All GSS waves are available only from IDI_Clean_20171027 onwards.


HISTORY: 
22 Nov 2017 VB Converted the SQL version into SAS.
20 Dec 2017 WJ Added SQL part of income derived for OECD for benefits and OECD ISCED attempt and mental_health_type

***********************************************************************************************************/

proc sql;

	connect to odbc (dsn=idi_clean_archive_srvprd);

	create table work._temp_of_gss_ind_variables as
	select *
	from connection to odbc(	

	/*From thebottom 5% defined as severe , bottom 15% defined as Common others are rest - values calculated by investigating sf12 scores*/
select z.* ,case when gss_id_collection_code='GSS2008' then 
				case when ment_health_sf12_score <= 34 then 'Severe'
					when ment_health_sf12_score <= 46  then 'Common'
				else 'No Disorder'
					end
				else case when ment_health_sf12_score <= 30 then 'Severe'
					when ment_health_sf12_score <= 43  then 'Common'
						else 'No Disorder'
					end
				end as mental_health_ind,

				case when gss_id_collection_code='GSS2008' then hh_gss_income_median* (1228.0/1063.5)
					when gss_id_collection_code='GSS2010' then hh_gss_income_median* (1228.0/1111.0)
					when gss_id_collection_code='GSS2012' then hh_gss_income_median * (1228.0/1168.0)
					when gss_id_collection_code='GSS2014' then hh_gss_income_median * (1228.0/1195.75)

				end as hh_gss_income_median_inf,

				case when gss_id_collection_code='GSS2008' then hh_gss_equi_income* (1228.0/1063.5)
					when gss_id_collection_code='GSS2010' then hh_gss_equi_income * (1228.0/1111.0)
					when gss_id_collection_code='GSS2012' then hh_gss_equi_income * (1228.0/1168.0)
					when gss_id_collection_code='GSS2014' then hh_gss_equi_income * (1228.0/1195.75)

				end as hh_gss_equi_income_median_inf,

				case when gss_id_collection_code='GSS2008' then hh_gss_income_upper* (1228.0/1063.5)
					when gss_id_collection_code='GSS2010' then hh_gss_income_upper* (1228.0/1111.0)
					when gss_id_collection_code='GSS2012' then hh_gss_income_upper * (1228.0/1168.0)
					when gss_id_collection_code='GSS2014' then hh_gss_income_upper* (1228.0/1195.75)

				end as hh_gss_income_median_up_inf,

				case when gss_id_collection_code='GSS2008' then hh_gss_equi_income_upper* (1228.0/1063.5)
					when gss_id_collection_code='GSS2010' then hh_gss_equi_income_upper * (1228.0/1111.0)
					when gss_id_collection_code='GSS2012' then hh_gss_equi_income_upper * (1228.0/1168.0)
					when gss_id_collection_code='GSS2014' then hh_gss_equi_income_upper * (1228.0/1195.75)

				end as hh_gss_equi_income_median_up_inf,

					case when gss_id_collection_code='GSS2008' then hh_gss_income_lower* (1228.0/1063.5)
					when gss_id_collection_code='GSS2010' then hh_gss_income_lower* (1228.0/1111.0)
					when gss_id_collection_code='GSS2012' then hh_gss_income_lower * (1228.0/1168.0)
					when gss_id_collection_code='GSS2014' then hh_gss_income_lower* (1228.0/1195.75)

				end as hh_gss_income_median_lw_inf,

				case when gss_id_collection_code='GSS2008' then hh_gss_equi_income_lower* (1228.0/1063.5)
					when gss_id_collection_code='GSS2010' then hh_gss_equi_income_lower * (1228.0/1111.0)
					when gss_id_collection_code='GSS2012' then hh_gss_equi_income_lower * (1228.0/1168.0)
					when gss_id_collection_code='GSS2014' then hh_gss_equi_income_lower * (1228.0/1195.75)

				end as hh_gss_equi_income_median_lw_inf


					from (


		select
			all_vars.*

			,/* Business logic for defining housing groups */
				case 
					when housing_status in ('OWN', 'TRUST','PRIVATE, TRUST OR BUSINESS-UNKNOWN','UNKNOWN-NO RENT', 'PRIVATE, TRUST OR BUSINESS-NO RENT') 
							and acc_sup_ind <> 1
						then 'Non Subsidised-Own Home'
					when housing_status in ('OWN', 'TRUST','PRIVATE, TRUST OR BUSINESS-UNKNOWN','UNKNOWN-NO RENT', 'PRIVATE, TRUST OR BUSINESS-NO RENT') 
							and acc_sup_ind = 1
						then 'Accommodation Supplement-Own Home'
					when housing_status = 'HOUSING NZ' 
						then 'IRR'
					when housing_status = 'OTHER SOCIAL HOUSING' 
						then 'Other Social Housing'
					when housing_status in ('PRIVATE, TRUST OR BUSINESS-PAY RENT', 'UNKNOWN-PAY RENT') and acc_sup_ind <> 1
						then 'Non Subsidised-Renting'
					when housing_status in ('PRIVATE, TRUST OR BUSINESS-PAY RENT', 'UNKNOWN-PAY RENT') and acc_sup_ind = 1
						then 'Accommodation Supplement-Renting'
					end as housing_groups

			/* Binary groupings for Life Satisfaction scores*/
			,case when life_satisfaction_ind in (1, 2, 3) then 0 
				when life_satisfaction_ind in (4, 5) then 1 
				else life_satisfaction_ind end as life_satisfaction_bin

			/* Equivalised household income */
			,hh_gss_income_median / hh_size_eq as hh_gss_equi_income
			,hh_gss_income_lower / hh_size_eq as hh_gss_equi_income_lower
			,hh_gss_income_upper / hh_size_eq as hh_gss_equi_income_upper

			/* Add Ignore indicators for individuals who do not belong to treatment and control*/
			,coalesce(hnzmain.treat_control, 'IGNORE') as treat_control_main
			,coalesce(hnzsen.treat_control, 'IGNORE') as treat_control_sen
		from (
			/* Creation of Analysis variables*/
			select 
				person.*

				/* "11-Very Safe" and "12-Safe" are treated as being "Safe" and everyone else is in the "No/Unknown" category.
					It is to be noted that this is a 4-point scale in 2010 & 2012, but 5-point in 2008 and 2014. In case of 
					the 5-point scales, the "13-Neither Safe nor Unsafe" is counted with "No/Unknown" here. Also note that 
					gss_pq_safe_day_hood_code variable does not exist for 2014.	*/
				,case when person.gss_pq_safe_night_pub_trans_code in ('11', '12') then 1 else 0 end as pub_trpt_safety_ind
				,case when person.gss_pq_safe_night_hood_code in ('11', '12') then 1 else 0 end as safety_ind
				,case when person.gss_pq_safe_day_hood_code in ('11', '12') then 1 else 0 end as safety_day_ind

				/* "1-Two or more bedrooms needed" & "2-One bedroom needed" are combined into 1-Crowded. "77-Not stated" is included with 
					Uncrowded/Unknown */
				,case when person.gss_pq_HH_crowd_code in (1, 2) then 1 else 0 end as house_crowding_ind

				/* For crimes experience, "1-Yes" coded as 1. Everything else decoded as No/Unknown. */
				,case when person.gss_pq_crimes_against_ind = 1 then 1 else 0 end as crime_exp_ind
				,case when person.gss_pq_HH_crowd_code in (1, 2) then 1 else 0 end + 
						person.gss_pq_house_mold_code + 
						person.gss_pq_house_cold_code as ct_house_pblms

				/* Casting SF-12 as an integer between 0 and 100 and to eliminate negative values. */
				,case when cast(person.gss_pq_phys_health_code as smallint) between 0 and 100
					then cast(person.gss_pq_phys_health_code as smallint) 
				else NULL 
				end as phys_health_sf12_score
				,case when cast(person.gss_pq_ment_health_code as smallint) between 0 and 100
					then cast(person.gss_pq_ment_health_code as smallint) 
					else NULL 
				end as ment_health_sf12_score
				,case when person.gss_pq_lfs_dev = '01' then 'Employed'
					when person.gss_pq_lfs_dev = '02' then 'Unemployed'
					when person.gss_pq_lfs_dev = '03' then 'Not_in_Labour_Force'
					else NULL end as lbr_force_status

				/* "11-All of the time", "12-Most of the time", & "13-Some of the time" has been coded as "Lonely"
					The scales for 2014 were flipped in the original data, but the inner query standardizes it
					to the same scales as 2008, 2010 and 2014.				*/
				,case when person.gss_pq_time_lonely_code in ('14', '15') then 0 
					when person.gss_pq_time_lonely_code in ('88', '99') or person.gss_pq_time_lonely_code is null then -1
					else 1 end as time_lonely_ind 

				/* No voting indicator exists for 2014, and is all decoded as -1, 1-"Yes" and "2-No". */
				, case when person.gss_pq_voting = 1 then 1 
					when person.gss_pq_voting = 2 then 0
					else -1 end as voting_ind
				,case when gss_hq_household_inc1_dev = '01' then '-Loss'
					when gss_hq_household_inc1_dev = '02' then '0'
					when gss_hq_household_inc1_dev = '03' then '1-5000'
					when gss_hq_household_inc1_dev = '04' then '5001-10000'
					when gss_hq_household_inc1_dev = '05' then '10001-15000'
					when gss_hq_household_inc1_dev = '06' then '15001-20000'
					when gss_hq_household_inc1_dev = '07' then '20001-25000'
					when gss_hq_household_inc1_dev = '08' then '25001-30000'
					when gss_hq_household_inc1_dev = '09' then '30001-35000'
					when gss_hq_household_inc1_dev = '10' then '35001-40000'
					when gss_hq_household_inc1_dev in ('11', '12', '13') then '40001-70000'
					when gss_hq_household_inc1_dev = '14' then '70001-100000'
					when gss_hq_household_inc1_dev = '15' then '100001-150000'
					when gss_hq_household_inc1_dev = '16' then '150001-Inf'
				end as hh_gss_income

				,case when gss_hq_household_inc1_dev = '01' then 0
					when gss_hq_household_inc1_dev = '02' then 0
					when gss_hq_household_inc1_dev = '03' then 2500
					when gss_hq_household_inc1_dev = '04' then 7500
					when gss_hq_household_inc1_dev = '05' then 12500
					when gss_hq_household_inc1_dev = '06' then 17500
					when gss_hq_household_inc1_dev = '07' then 22500
					when gss_hq_household_inc1_dev = '08' then 27500
					when gss_hq_household_inc1_dev = '09' then 32500
					when gss_hq_household_inc1_dev = '10' then 37500
					when gss_hq_household_inc1_dev in ('11', '12', '13') then 55000
					when gss_hq_household_inc1_dev = '14' then 85000
					when gss_hq_household_inc1_dev = '15' then 125000
					when gss_hq_household_inc1_dev = '16' then 175000
				end as hh_gss_income_median

				,case when gss_hq_household_inc1_dev = '01' then 0
					when gss_hq_household_inc1_dev = '02' then 0
					when gss_hq_household_inc1_dev = '03' then 1
					when gss_hq_household_inc1_dev = '04' then 5001
					when gss_hq_household_inc1_dev = '05' then 10001
					when gss_hq_household_inc1_dev = '06' then 15001
					when gss_hq_household_inc1_dev = '07' then 20001
					when gss_hq_household_inc1_dev = '08' then 25001
					when gss_hq_household_inc1_dev = '09' then 30001
					when gss_hq_household_inc1_dev = '10' then 35001
					when gss_hq_household_inc1_dev in ('11', '12', '13') then 40001
					when gss_hq_household_inc1_dev = '14' then 70001
					when gss_hq_household_inc1_dev = '15' then 100001
					when gss_hq_household_inc1_dev = '16' then 150001
				end as hh_gss_income_lower

				,case when gss_hq_household_inc1_dev = '01' then 0
					when gss_hq_household_inc1_dev = '02' then 0
					when gss_hq_household_inc1_dev = '03' then 5000
					when gss_hq_household_inc1_dev = '04' then 10000
					when gss_hq_household_inc1_dev = '05' then 15000
					when gss_hq_household_inc1_dev = '06' then 20000
					when gss_hq_household_inc1_dev = '07' then 25000
					when gss_hq_household_inc1_dev = '08' then 30000
					when gss_hq_household_inc1_dev = '09' then 35000
					when gss_hq_household_inc1_dev = '10' then 40000
					when gss_hq_household_inc1_dev in ('11', '12', '13') then 70000
					when gss_hq_household_inc1_dev = '14' then 100000
					when gss_hq_household_inc1_dev = '15' then 150000
					when gss_hq_household_inc1_dev = '16' then 200000
				end as hh_gss_income_upper

				/* Life satisfaction is a 10-point scale for 2014, and 5 point scales for all previous waves.
					For 2014, the range is 00 to 10 and for previous waves it is flipped from 15 to 11.
					Here we convert the 10-point scales into a 5-point scale and make it numeric in the range 1 to 5.*/
				,case when person.gss_pq_feel_life_code in ('00', '01', '15') then 1
					when person.gss_pq_feel_life_code in ('02','03','04','14') then 2
					when person.gss_pq_feel_life_code in ('05','13') then 3
					when person.gss_pq_feel_life_code in ('06','07','08','12') then 4
					when person.gss_pq_feel_life_code in ('09','10','11') then 5
				else -1 end as life_satisfaction_ind
				,case when accom.snz_gss_hhld_uid is NULL then 0 else 1 end as acc_sup_ind
				,case when gss_hq_house_trust='99' then 'UNKNOWN'
							when gss_hq_house_trust in ('88', '02') then 
								case when gss_hq_house_own = '01' then 'OWN'
									when gss_hq_house_own = '99' then 'UNKNOWN'
									when gss_hq_house_own in ('02','88') then 
										case when gss_hq_house_who_owns_code = '11' and gss_hq_house_pay_rent_code = '01' then 'PRIVATE, TRUST OR BUSINESS-PAY RENT'
											when gss_hq_house_who_owns_code = '11' and gss_hq_house_pay_rent_code = '02' then 'PRIVATE, TRUST OR BUSINESS-NO RENT'
											when gss_hq_house_who_owns_code = '11' and gss_hq_house_pay_rent_code in ('88', '99') then 'PRIVATE, TRUST OR BUSINESS-UNKNOWN'
											when gss_hq_house_who_owns_code in ('12', '14') then 'OTHER SOCIAL HOUSING'
											when gss_hq_house_who_owns_code ='13' then 'HOUSING NZ'
											when gss_hq_house_who_owns_code in ('88', '99') and gss_hq_house_pay_rent_code = '01' then 'UNKNOWN-PAY RENT'
											when gss_hq_house_who_owns_code in ('88', '99') and gss_hq_house_pay_rent_code = '02' then 'UNKNOWN-NO RENT'
											when gss_hq_house_who_owns_code in ('88', '99') and gss_hq_house_pay_rent_code in ('88', '99') then 'UNKNOWN'
										end
								end
							when gss_hq_house_trust = '01' then 'TRUST'
						end as housing_status

				/* For cultural identity, "11- Very Easy" and "12-Easy" is decoded into 1-Easy. Nulls, 88, 99 are kept as Nulls, and others 
					into "0-Not easy"*/
				,case when gss_pq_cult_identity_code in ('11', '12') then 1 
					when gss_pq_cult_identity_code in ('88', '99') then NULL 
					when gss_pq_cult_identity_code is NULL then NULL
					else 0 end as cult_identity_ind
				/* If Housing satisfacion is "11-Very Satisfied" and "12-Satisfied", then we decode "1-Satisfied". If it is "13-Neither Satisfied or Unsatisfied",
					"14-Unsatisfied","15-Very Unsatisfied" then we use 0. Else we use NULL.*/
				,case when housing_satisfaction in (11, 12) then 1 when housing_satisfaction in (13, 14, 15) then 0 else NULL end as housing_sat_ind
				/* Household composition variables*/
				,hhcomp.adult_ct
				,hhcomp.child_ct
				,hhcomp.hh_size
				,hhcomp.hh_size_eq
				/* OECD Qual Level attempt - see ISCED*/
				,case when gss_pq_highest_qual_dev in (0,1) then 'Less Upper Secondary'
					when gss_pq_highest_qual_dev in (2,3,4,11) then 'Upper Secondary'
					when gss_pq_highest_qual_dev in (5,6,7,8,9,10) then 'Tertiary'
					when gss_pq_highest_qual_dev =NULL then 'NULL'
					else 'Other'
					end as gss_oecd_quals
				,case when gss_pq_PHYQ13 in (14, 15) then 1 else 0 end as no_access_natural_space
				,case when leisure_time =13 then 1 else 0 end as no_free_time

			from 
			(
				/* 2014 variables*/
				select 
					pers.snz_uid
					,pers.snz_gss_hhld_uid
					,pers_det.snz_spine_ind
					,'GSS2014' as gss_id_collection_code
					,cast(gss_pq_PQinterview_date as date) as gss_pq_interview_date
					,hhld.gss_hq_interview_start_date
					,hhld.gss_hq_sex_dev
					,hhld.gss_hq_birth_month_nbr
					,hhld.gss_hq_birth_year_nbr
					,hhld.gss_hq_house_trust
					,hhld.gss_hq_house_own
					,hhld.gss_hq_house_pay_mort_code
					,hhld.gss_hq_house_pay_rent_code
					,hhld.gss_hq_house_who_owns_code		
					,pers.gss_pq_HH_tenure_code
					,cast(pers.gss_pq_HH_crowd_code as smallint) as gss_pq_HH_crowd_code
					,case when pers.gss_pq_house_mold_code in ('13') then 1 else 0 end as gss_pq_house_mold_code /* 1- Yes, 0 - No/Unknown */
					,case when pers.gss_pq_house_cold_code in ('11', '12') then 1 else 0 end as gss_pq_house_cold_code /* 1- Yes, 0 - No/Unknown */
					,NULL as gss_pq_house_condition_code /* Not available for 2014 wave. */
					,NULL as housing_satisfaction /* Not available for 2014 wave. */
					,coalesce(pers.gss_pq_prob_hood_noisy_ind, 0) as gss_pq_prob_hood_noisy_ind
					,pers.gss_pq_safe_night_pub_trans_code /* 4 point scale in 2010 & 2012; 5 point in 2008 & 2014*/
					,pers.gss_pq_safe_night_hood_code /* 4 point scale in 2010 & 2012; 5 point in 2008 & 2014*/
					,NULL as gss_pq_safe_day_hood_code /* Available only for 2012, 2010, 2008 waves*/
					,case when pers.gss_pq_discrim_rent_ind = '1' then 1 else 0 end as gss_pq_discrim_rent_ind
					,cast(pers.gss_pq_crimes_against_ind as smallint) as gss_pq_crimes_against_ind/* Slightly different wording (re traffic incidents) */
					,pers.gss_pq_cult_identity_code /* Culture question asked differently across waves (and responses different) */
					,cast(pers.gss_pq_ment_health_code as smallint) as gss_pq_ment_health_code
					,cast(pers.gss_pq_phys_health_code as smallint) as gss_pq_phys_health_code
					,cast(pers.gss_pq_lfs_dev as smallint) as gss_pq_lfs_dev
					,cast(pers.gss_pq_highest_qual_dev as smallint) as gss_pq_highest_qual_dev
					,pers.gss_pq_feel_life_code
					,NULL as gss_pq_voting /* Available only for 2012, 2010, 2008 waves */
					,case pers.gss_pq_time_lonely_code  /* Scales flipped between 2014 and other waves */
						 when 11 then 15
						 when 12 then 14 
						 when 14 then 12 
						 when 15 then 11
						 else pers.gss_pq_time_lonely_code end as gss_pq_time_lonely_code
					,cast(gss_hq_household_inc1_dev as smallint) as gss_hq_household_inc1_dev
					,gss_pq_dvage_code
					,coalesce(gss_pq_eth_european_code, 0) as gss_pq_eth_european_code
					,coalesce(gss_pq_eth_maori_code, 0) as gss_pq_eth_maori_code
					,coalesce(gss_pq_eth_samoan_code, 0) as gss_pq_eth_samoan_code
					,coalesce(gss_pq_eth_cookisland_code, 0) as gss_pq_eth_cookisland_code
					,coalesce(gss_pq_eth_tongan_code, 0) as gss_pq_eth_tongan_code
					,coalesce(gss_pq_eth_nieuan_code, 0) as gss_pq_eth_nieuan_code
					,coalesce(gss_pq_eth_chinese_code, 0) as gss_pq_eth_chinese_code
					,coalesce(gss_pq_eth_indian_code, 0) as gss_pq_eth_indian_code
					,gss_pq_HH_comp_code
					,hhld.[gss_hq_regcouncil_dev]
					,adults.adult_count
					,case when cast(gss_pq_material_wellbeing_code as smallint) between 0 and 20 
						then cast(gss_pq_material_wellbeing_code as smallint)
						else NULL end as gss_pq_material_wellbeing_code
					,NULL as gss_pq_ELSIDV1
       				  ,case when coalesce(gss_pq_inc_unemp_dev,0) =1 or  coalesce(gss_pq_inc_jobseek_dev,0) = 1 then 1 else 0 end as gss_unemp_jobseek 
   					 , case when coalesce(gss_pq_inc_sick_dev,0)  = 1 then 1 else 0 end as gss_sickness
 					, case when coalesce(gss_pq_inc_invalid_dev,0) =1 or   coalesce(gss_pq_inc_supplive_dev,0) = 1 then 1 else 0 end as gss_invalid_support
					, case when coalesce(gss_pq_inc_soleprnt_dev,0) =1 or   coalesce(gss_pq_inc_domestic_dev,0) = 1 then 1 else 0 end as gss_soleprnt_domestic
					, case when coalesce(gss_pq_inc_othben_dev,0)  = 1 then 1 else 0 end as gss_oth_ben
				      ,case when coalesce(gss_pq_inc_none_dev,0)  = 1 then 1 else 0 end as gss_no_income

					,NULL AS gss_pq_PHYQ13 /*environment*/
					,NULL AS gss_pq_PHYQ14 /*environment*/
					,NULL AS leisure_time

/*					Adding variables of interest which matches up*/

					,[gss_pq_person_SeInWgt_nbr]
					,[gss_pq_person_FinalWgt_nbr]
					,[gss_pq_person_FinalWgt1_nbr]
					,[gss_pq_person_FinalWgt2_nbr]
					,[gss_pq_person_FinalWgt3_nbr]
					,[gss_pq_person_FinalWgt4_nbr]
					,[gss_pq_person_FinalWgt5_nbr]
					,[gss_pq_person_FinalWgt6_nbr]
					,[gss_pq_person_FinalWgt7_nbr]
					,[gss_pq_person_FinalWgt8_nbr]
					,[gss_pq_person_FinalWgt9_nbr]
					,[gss_pq_person_FinalWgt10_nbr]
					,[gss_pq_person_FinalWgt11_nbr]
					,[gss_pq_person_FinalWgt12_nbr]
					,[gss_pq_person_FinalWgt13_nbr]
					,[gss_pq_person_FinalWgt14_nbr]
					,[gss_pq_person_FinalWgt15_nbr]
					,[gss_pq_person_FinalWgt16_nbr]
					,[gss_pq_person_FinalWgt17_nbr]
					,[gss_pq_person_FinalWgt18_nbr]
					,[gss_pq_person_FinalWgt19_nbr]
					,[gss_pq_person_FinalWgt20_nbr]
					,[gss_pq_person_FinalWgt21_nbr]
					,[gss_pq_person_FinalWgt22_nbr]
					,[gss_pq_person_FinalWgt23_nbr]
					,[gss_pq_person_FinalWgt24_nbr]
					,[gss_pq_person_FinalWgt25_nbr]
					,[gss_pq_person_FinalWgt26_nbr]
					,[gss_pq_person_FinalWgt27_nbr]
					,[gss_pq_person_FinalWgt28_nbr]
					,[gss_pq_person_FinalWgt29_nbr]
					,[gss_pq_person_FinalWgt30_nbr]
					,[gss_pq_person_FinalWgt31_nbr]
					,[gss_pq_person_FinalWgt32_nbr]
					,[gss_pq_person_FinalWgt33_nbr]
					,[gss_pq_person_FinalWgt34_nbr]
					,[gss_pq_person_FinalWgt35_nbr]
					,[gss_pq_person_FinalWgt36_nbr]
					,[gss_pq_person_FinalWgt37_nbr]
					,[gss_pq_person_FinalWgt38_nbr]
					,[gss_pq_person_FinalWgt39_nbr]
					,[gss_pq_person_FinalWgt40_nbr]
					,[gss_pq_person_FinalWgt41_nbr]
					,[gss_pq_person_FinalWgt42_nbr]
					,[gss_pq_person_FinalWgt43_nbr]
					,[gss_pq_person_FinalWgt44_nbr]
					,[gss_pq_person_FinalWgt45_nbr]
					,[gss_pq_person_FinalWgt46_nbr]
					,[gss_pq_person_FinalWgt47_nbr]
					,[gss_pq_person_FinalWgt48_nbr]
					,[gss_pq_person_FinalWgt49_nbr]
					,[gss_pq_person_FinalWgt50_nbr]
					,[gss_pq_person_FinalWgt51_nbr]
					,[gss_pq_person_FinalWgt52_nbr]
					,[gss_pq_person_FinalWgt53_nbr]
					,[gss_pq_person_FinalWgt54_nbr]
					,[gss_pq_person_FinalWgt55_nbr]
					,[gss_pq_person_FinalWgt56_nbr]
					,[gss_pq_person_FinalWgt57_nbr]
					,[gss_pq_person_FinalWgt58_nbr]
					,[gss_pq_person_FinalWgt59_nbr]
					,[gss_pq_person_FinalWgt60_nbr]
					,[gss_pq_person_FinalWgt61_nbr]
					,[gss_pq_person_FinalWgt62_nbr]
					,[gss_pq_person_FinalWgt63_nbr]
					,[gss_pq_person_FinalWgt64_nbr]
					,[gss_pq_person_FinalWgt65_nbr]
					,[gss_pq_person_FinalWgt66_nbr]
					,[gss_pq_person_FinalWgt67_nbr]
					,[gss_pq_person_FinalWgt68_nbr]
					,[gss_pq_person_FinalWgt69_nbr]
					,[gss_pq_person_FinalWgt70_nbr]
					,[gss_pq_person_FinalWgt71_nbr]
					,[gss_pq_person_FinalWgt72_nbr]
					,[gss_pq_person_FinalWgt73_nbr]
					,[gss_pq_person_FinalWgt74_nbr]
					,[gss_pq_person_FinalWgt75_nbr]
					,[gss_pq_person_FinalWgt76_nbr]
					,[gss_pq_person_FinalWgt77_nbr]
					,[gss_pq_person_FinalWgt78_nbr]
					,[gss_pq_person_FinalWgt79_nbr]
					,[gss_pq_person_FinalWgt80_nbr]
					,[gss_pq_person_FinalWgt81_nbr]
					,[gss_pq_person_FinalWgt82_nbr]
					,[gss_pq_person_FinalWgt83_nbr]
					,[gss_pq_person_FinalWgt84_nbr]
					,[gss_pq_person_FinalWgt85_nbr]
					,[gss_pq_person_FinalWgt86_nbr]
					,[gss_pq_person_FinalWgt87_nbr]
					,[gss_pq_person_FinalWgt88_nbr]
					,[gss_pq_person_FinalWgt89_nbr]
					,[gss_pq_person_FinalWgt90_nbr]
					,[gss_pq_person_FinalWgt91_nbr]
					,[gss_pq_person_FinalWgt92_nbr]
					,[gss_pq_person_FinalWgt93_nbr]
					,[gss_pq_person_FinalWgt94_nbr]
					,[gss_pq_person_FinalWgt95_nbr]
					,[gss_pq_person_FinalWgt96_nbr]
					,[gss_pq_person_FinalWgt97_nbr]
					,[gss_pq_person_FinalWgt98_nbr]
					,[gss_pq_person_FinalWgt99_nbr]
					,[gss_pq_person_FinalWgt100_nbr]
				from
				&idi_version..gss_clean.gss_person pers
				inner join [IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_sh hhld on pers.snz_uid = hhld.snz_uid
				left join &idi_version..data.personal_detail pers_det	on pers.snz_uid = pers_det.snz_uid
				inner join (select snz_gss_hhld_uid, sum([adult_ind]) as adult_count from [IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_sh group by snz_gss_hhld_uid) adults
					on (pers.snz_gss_hhld_uid = adults.snz_gss_hhld_uid)

				union all

				/* 2012 variables*/
				select 
					pers.snz_uid
					,pers.snz_gss_hhld_uid
					,pers_det.snz_spine_ind
					,'GSS2012' as gss_id_collection_code
					,cast([gss_pq_interview_start_date] as date) as gss_pq_interview_date
					,hhld.gss_hq_interview_start_date
					,hhld.gss_hq_sex_dev
					,hhld.gss_hq_birth_month_nbr
					,hhld.gss_hq_birth_year_nbr
					,hhld.gss_hq_house_trust
					,hhld.gss_hq_house_own
					,hhld.gss_hq_house_pay_mort_code
					,hhld.gss_hq_house_pay_rent_code
					,hhld.gss_hq_house_who_owns_code	
					,hhld.gss_pq_HH_tenure_code
					,cast(pers.gss_pq_HOUDV2 as smallint) as gss_pq_HH_crowd_code
					,coalesce(cast(pers.gss_pq_HOUQ03_14 as smallint), 0) as gss_pq_house_mold_code
					,coalesce(cast(pers.gss_pq_HOUQ03_15 as smallint), 0) as gss_pq_house_cold_code
					,cast(pers.gss_pq_HOUQ03_13 as smallint) as gss_pq_house_condition_code
					,cast(pers.gss_pq_HOUQ01 as smallint) as housing_satisfaction
					,pers.gss_pq_HOUQ04_14 as gss_pq_prob_hood_noisy_ind
					,pers.gss_pq_SAFQ01C as gss_pq_safe_night_pub_trans_code /* 4 point scale in 2010 & 2012; 5 point in 2008 & 2014*/
					,pers.gss_pq_SAFQ01E as gss_pq_safe_night_hood_code
					,pers.gss_pq_SAFQ01D as gss_pq_safe_day_hood_code
					,coalesce(pers.gss_pq_HUMQ07_19,0) as gss_pq_discrim_rent_ind /* 2012 question is about "applying for or keeping a house/flat". Probably too small to worry about */
					,cast(pers.gss_pq_SAFQ02 as smallint) as gss_pq_crimes_against_ind /* Slightly different wording (re traffic incidents) */
					,pers.gss_pq_CULQ04 as gss_pq_cult_identity_code /* Culture question asked differently across waves (and responses different)*/
					,cast(pers.gss_pq_HEADV2 as smallint) as gss_pq_ment_health_code
					,cast(pers.gss_pq_HEADV3 as smallint) as gss_pq_phys_health_code
					,cast(pers.gss_pq_CORDV14 as smallint) as gss_pq_lfs_dev
					,cast(pers.gss_pq_CORDV15 as smallint) as gss_pq_highest_qual_dev
					,pers.gss_pq_OLSQ01 as gss_pq_feel_life_code
					,pers.gss_pq_HUMQ01 as gss_pq_voting /* not in 2014 (just made up a var name) */
					/*,pers.gss_pq_SOCQ13 as help_who_code -- Scales flipped between 2014 and rest. Question has different scope too.*/
					,pers.gss_pq_SOCQ11 as gss_pq_time_lonely_code /* Scales flipped between 2014 and rest. Prioritise over 'help who'*/
					,cast(gss_hq_household_inc1_dev as smallint) as gss_hq_household_inc1_dev
					,gss_pq_CORDV9
					,coalesce([gss_pq_CORPQ10_11], 0) as [gss_pq_CORPQ10_11]
					,coalesce([gss_pq_CORPQ10_12], 0) as [gss_pq_CORPQ10_12]
					,coalesce([gss_pq_CORPQ10_13], 0) as [gss_pq_CORPQ10_13]
					,coalesce([gss_pq_CORPQ10_14], 0) as [gss_pq_CORPQ10_14]
					,coalesce([gss_pq_CORPQ10_15], 0) as [gss_pq_CORPQ10_15]
					,coalesce([gss_pq_CORPQ10_16], 0) as [gss_pq_CORPQ10_16]
					,coalesce([gss_pq_CORPQ10_17], 0) as [gss_pq_CORPQ10_17]
					,coalesce([gss_pq_CORPQ10_18], 0) as [gss_pq_CORPQ10_18]
					,[gss_pq_CORDV4]
					,gss_pq_reg_council_08_code
					,adults.adult_count
					,NULL as gss_pq_material_wellbeing_code
					,case when cast(gss_pq_ELSIDV1 as smallint) between 0 and 31 
						then cast(gss_pq_ELSIDV1 as smallint)
					else NULL end as gss_pq_ELSIDV1
					   ,case when coalesce(gss_pq_CORDV8_17,0) =1  then 1 else 0 end as gss_unemp_jobseek 
   					 , case when coalesce(gss_pq_CORDV8_18,0)  = 1 then 1 else 0 end as gss_sickness
 					, case when coalesce(gss_pq_CORDV8_20,0) =1  then 1 else 0 end as gss_invalid_support
					, case when coalesce(gss_pq_CORDV8_19,0) = 1 then 1 else 0 end as gss_soleprnt_domestic
					, case when coalesce(gss_pq_CORDV8_22,0)  = 1 then 1 else 0 end as gss_oth_ben
				      ,case when coalesce(gss_pq_CORDV8_24,0)  = 1 then 1 else 0 end as gss_no_income

					,[gss_pq_PHYQ13]
					,[gss_pq_PHYQ14]
					,[gss_pq_LEIQ01] AS leisure_time

					,[gss_pq_PersonGSSSelectionWeight]
					,[gss_pq_PersonGSSFinalweight]
					,[gss_pq_PersonGSSFinalWeight_1]
					,[gss_pq_PersonGSSFinalWeight_2]
					,[gss_pq_PersonGSSFinalWeight_3]
					,[gss_pq_PersonGSSFinalWeight_4]
					,[gss_pq_PersonGSSFinalWeight_5]
					,[gss_pq_PersonGSSFinalWeight_6]
					,[gss_pq_PersonGSSFinalWeight_7]
					,[gss_pq_PersonGSSFinalWeight_8]
					,[gss_pq_PersonGSSFinalWeight_9]
					,[gss_pq_PersonGSSFinalWeight_10]
					,[gss_pq_PersonGSSFinalWeight_11]
					,[gss_pq_PersonGSSFinalWeight_12]
					,[gss_pq_PersonGSSFinalWeight_13]
					,[gss_pq_PersonGSSFinalWeight_14]
					,[gss_pq_PersonGSSFinalWeight_15]
					,[gss_pq_PersonGSSFinalWeight_16]
					,[gss_pq_PersonGSSFinalWeight_17]
					,[gss_pq_PersonGSSFinalWeight_18]
					,[gss_pq_PersonGSSFinalWeight_19]
					,[gss_pq_PersonGSSFinalWeight_20]
					,[gss_pq_PersonGSSFinalWeight_21]
					,[gss_pq_PersonGSSFinalWeight_22]
					,[gss_pq_PersonGSSFinalWeight_23]
					,[gss_pq_PersonGSSFinalWeight_24]
					,[gss_pq_PersonGSSFinalWeight_25]
					,[gss_pq_PersonGSSFinalWeight_26]
					,[gss_pq_PersonGSSFinalWeight_27]
					,[gss_pq_PersonGSSFinalWeight_28]
					,[gss_pq_PersonGSSFinalWeight_29]
					,[gss_pq_PersonGSSFinalWeight_30]
					,[gss_pq_PersonGSSFinalWeight_31]
					,[gss_pq_PersonGSSFinalWeight_32]
					,[gss_pq_PersonGSSFinalWeight_33]
					,[gss_pq_PersonGSSFinalWeight_34]
					,[gss_pq_PersonGSSFinalWeight_35]
					,[gss_pq_PersonGSSFinalWeight_36]
					,[gss_pq_PersonGSSFinalWeight_37]
					,[gss_pq_PersonGSSFinalWeight_38]
					,[gss_pq_PersonGSSFinalWeight_39]
					,[gss_pq_PersonGSSFinalWeight_40]
					,[gss_pq_PersonGSSFinalWeight_41]
					,[gss_pq_PersonGSSFinalWeight_42]
					,[gss_pq_PersonGSSFinalWeight_43]
					,[gss_pq_PersonGSSFinalWeight_44]
					,[gss_pq_PersonGSSFinalWeight_45]
					,[gss_pq_PersonGSSFinalWeight_46]
					,[gss_pq_PersonGSSFinalWeight_47]
					,[gss_pq_PersonGSSFinalWeight_48]
					,[gss_pq_PersonGSSFinalWeight_49]
					,[gss_pq_PersonGSSFinalWeight_50]
					,[gss_pq_PersonGSSFinalWeight_51]
					,[gss_pq_PersonGSSFinalWeight_52]
					,[gss_pq_PersonGSSFinalWeight_53]
					,[gss_pq_PersonGSSFinalWeight_54]
					,[gss_pq_PersonGSSFinalWeight_55]
					,[gss_pq_PersonGSSFinalWeight_56]
					,[gss_pq_PersonGSSFinalWeight_57]
					,[gss_pq_PersonGSSFinalWeight_58]
					,[gss_pq_PersonGSSFinalWeight_59]
					,[gss_pq_PersonGSSFinalWeight_60]
					,[gss_pq_PersonGSSFinalWeight_61]
					,[gss_pq_PersonGSSFinalWeight_62]
					,[gss_pq_PersonGSSFinalWeight_63]
					,[gss_pq_PersonGSSFinalWeight_64]
					,[gss_pq_PersonGSSFinalWeight_65]
					,[gss_pq_PersonGSSFinalWeight_66]
					,[gss_pq_PersonGSSFinalWeight_67]
					,[gss_pq_PersonGSSFinalWeight_68]
					,[gss_pq_PersonGSSFinalWeight_69]
					,[gss_pq_PersonGSSFinalWeight_70]
					,[gss_pq_PersonGSSFinalWeight_71]
					,[gss_pq_PersonGSSFinalWeight_72]
					,[gss_pq_PersonGSSFinalWeight_73]
					,[gss_pq_PersonGSSFinalWeight_74]
					,[gss_pq_PersonGSSFinalWeight_75]
					,[gss_pq_PersonGSSFinalWeight_76]
					,[gss_pq_PersonGSSFinalWeight_77]
					,[gss_pq_PersonGSSFinalWeight_78]
					,[gss_pq_PersonGSSFinalWeight_79]
					,[gss_pq_PersonGSSFinalWeight_80]
					,[gss_pq_PersonGSSFinalWeight_81]
					,[gss_pq_PersonGSSFinalWeight_82]
					,[gss_pq_PersonGSSFinalWeight_83]
					,[gss_pq_PersonGSSFinalWeight_84]
					,[gss_pq_PersonGSSFinalWeight_85]
					,[gss_pq_PersonGSSFinalWeight_86]
					,[gss_pq_PersonGSSFinalWeight_87]
					,[gss_pq_PersonGSSFinalWeight_88]
					,[gss_pq_PersonGSSFinalWeight_89]
					,[gss_pq_PersonGSSFinalWeight_90]
					,[gss_pq_PersonGSSFinalWeight_91]
					,[gss_pq_PersonGSSFinalWeight_92]
					,[gss_pq_PersonGSSFinalWeight_93]
					,[gss_pq_PersonGSSFinalWeight_94]
					,[gss_pq_PersonGSSFinalWeight_95]
					,[gss_pq_PersonGSSFinalWeight_96]
					,[gss_pq_PersonGSSFinalWeight_97]
					,[gss_pq_PersonGSSFinalWeight_98]
					,[gss_pq_PersonGSSFinalWeight_99]
					,[gss_pq_PersonGSSFinalWeight_100]
				from
					&idi_version..gss_clean.gss_person_2012 pers
				inner join [IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_sh hhld on pers.snz_uid = hhld.snz_uid
				left join &idi_version..data.personal_detail pers_det	on pers.snz_uid = pers_det.snz_uid
				inner join (select snz_gss_hhld_uid, sum([adult_ind]) as adult_count from [IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_sh group by snz_gss_hhld_uid) adults
					on (pers.snz_gss_hhld_uid = adults.snz_gss_hhld_uid)

				union all

				/*Renaming 2010 vars to 2014 vars*/
				select 
					pers.snz_uid
					,pers.snz_gss_hhld_uid
					,pers_det.snz_spine_ind
					,'GSS2010' as gss_id_collection_code
					,cast([gss_pq_interview_start_date] as date) as gss_pq_interview_date
					,hhld.gss_hq_interview_start_date
					,hhld.gss_hq_sex_dev
					,hhld.gss_hq_birth_month_nbr
					,hhld.gss_hq_birth_year_nbr
					,hhld.gss_hq_house_trust
					,hhld.gss_hq_house_own
					,hhld.gss_hq_house_pay_mort_code
					,hhld.gss_hq_house_pay_rent_code
					,hhld.gss_hq_house_who_owns_code	
					,hhld.gss_pq_HH_tenure_code
					,cast(pers.gss_pq_HOUDV2 as smallint) as gss_pq_HH_crowd_code
					,coalesce(cast(pers.gss_pq_HOUQ03_14 as smallint), 0) as gss_pq_house_mold_code
					,coalesce(cast(pers.gss_pq_HOUQ03_15 as smallint), 0) as gss_pq_house_cold_code
					,cast(pers.gss_pq_HOUQ03_13 as smallint) as gss_pq_house_condition_code
					,cast(pers.gss_pq_HOUQ01 as smallint) as housing_satisfaction
					,pers.gss_pq_HOUQ04_14 as gss_pq_prob_hood_noisy_ind
					,pers.gss_pq_SAFQ01C as gss_pq_safe_night_pub_trans_code /* 4 point scale in 2010 & 2012; 5 point in 2008 & 2014*/
					,pers.gss_pq_SAFQ01E as gss_pq_safe_night_hood_code /* 4 point scale in 2010 & 2012; 5 point in 2008 & 2014*/
					,pers.gss_pq_SAFQ01D as gss_pq_safe_day_hood_code /* not in 2014 */
					,coalesce(pers.gss_pq_HUMQ07_19,0) as gss_pq_discrim_rent_ind /* Questions in earlier waves is about "applying for or keeping a house/flat". Probably too small to worry about*/
					,cast(pers.gss_pq_SAFQ02 as smallint) as gss_pq_crimes_against_ind /* Slightly different wording (re traffic incidents)*/
					,pers.gss_pq_CULQ04 as gss_pq_cult_identity_code /* Culture question asked differently across waves (and responses different)*/
					,cast(pers.gss_pq_HEADV2 as smallint) as gss_pq_ment_health_code
					,cast(pers.gss_pq_HEADV3 as smallint) as gss_pq_phys_health_code
					,cast(pers.gss_pq_CORDV14 as smallint) as gss_pq_lfs_dev
					,cast(pers.gss_pq_CORDV15 as smallint) as gss_pq_highest_qual_dev
					,pers.gss_pq_OLSQ01 as gss_pq_feel_life_code
					,pers.gss_pq_HUMQ01 as gss_pq_voting /* not in 2014 (just made up a var name) */
					/*pers.gss_pq_SOCQ13 as help_who_code -- Scales flipped between 2014 and rest. Question has different scope too.*/
					,pers.gss_pq_SOCQ11 as gss_pq_time_lonely_code /* Scales flipped between 2014 and rest. Prioritise over 'help who' */
					,cast(gss_hq_household_inc1_dev as smallint) as gss_hq_household_inc1_dev
					,gss_pq_CORDV9
					,[gss_pq_CORPQ10_11]
					,[gss_pq_CORPQ10_12]
					,[gss_pq_CORPQ10_13]
					,[gss_pq_CORPQ10_14]
					,[gss_pq_CORPQ10_15]
					,[gss_pq_CORPQ10_16]
					,[gss_pq_CORPQ10_17]
					,[gss_pq_CORPQ10_18]
					,[gss_pq_CORDV4]
					,gss_pq_reg_council_08_code
					,adults.adult_count
					,NULL as gss_pq_material_wellbeing_code
					,case when cast(gss_pq_ELSIDV1 as smallint) between 0 and 31 
						then cast(gss_pq_ELSIDV1 as smallint)
					else NULL end as gss_pq_ELSIDV1
					,case when coalesce(gss_pq_CORDV8_17,0) =1  then 1 else 0 end as gss_unemp_jobseek 
   					 , case when coalesce(gss_pq_CORDV8_18,0)  = 1 then 1 else 0 end as gss_sickness
 					, case when coalesce(gss_pq_CORDV8_20,0) =1  then 1 else 0 end as gss_invalid_support
					, case when coalesce(gss_pq_CORDV8_19,0) = 1 then 1 else 0 end as gss_soleprnt_domestic
					, case when coalesce(gss_pq_CORDV8_22,0)  = 1 then 1 else 0 end as gss_oth_ben
				      ,case when coalesce(gss_pq_CORDV8_24,0)  = 1 then 1 else 0 end as gss_no_income

					,[gss_pq_PHYQ13]
					,[gss_pq_PHYQ14]
					,[gss_pq_LEIQ01] AS leisure_time

					,[gss_pq_PersonGSSSelectionWeight]
					,[gss_pq_PersonGSSFinalWeight]
					,[gss_pq_PersonGSSFinalWeight_1]
					,[gss_pq_PersonGSSFinalWeight_2]
					,[gss_pq_PersonGSSFinalWeight_3]
					,[gss_pq_PersonGSSFinalWeight_4]
					,[gss_pq_PersonGSSFinalWeight_5]
					,[gss_pq_PersonGSSFinalWeight_6]
					,[gss_pq_PersonGSSFinalWeight_7]
					,[gss_pq_PersonGSSFinalWeight_8]
					,[gss_pq_PersonGSSFinalWeight_9]
					,[gss_pq_PersonGSSFinalWeight_10]
					,[gss_pq_PersonGSSFinalWeight_11]
					,[gss_pq_PersonGSSFinalWeight_12]
					,[gss_pq_PersonGSSFinalWeight_13]
					,[gss_pq_PersonGSSFinalWeight_14]
					,[gss_pq_PersonGSSFinalWeight_15]
					,[gss_pq_PersonGSSFinalWeight_16]
					,[gss_pq_PersonGSSFinalWeight_17]
					,[gss_pq_PersonGSSFinalWeight_18]
					,[gss_pq_PersonGSSFinalWeight_19]
					,[gss_pq_PersonGSSFinalWeight_20]
					,[gss_pq_PersonGSSFinalWeight_21]
					,[gss_pq_PersonGSSFinalWeight_22]
					,[gss_pq_PersonGSSFinalWeight_23]
					,[gss_pq_PersonGSSFinalWeight_24]
					,[gss_pq_PersonGSSFinalWeight_25]
					,[gss_pq_PersonGSSFinalWeight_26]
					,[gss_pq_PersonGSSFinalWeight_27]
					,[gss_pq_PersonGSSFinalWeight_28]
					,[gss_pq_PersonGSSFinalWeight_29]
					,[gss_pq_PersonGSSFinalWeight_30]
					,[gss_pq_PersonGSSFinalWeight_31]
					,[gss_pq_PersonGSSFinalWeight_32]
					,[gss_pq_PersonGSSFinalWeight_33]
					,[gss_pq_PersonGSSFinalWeight_34]
					,[gss_pq_PersonGSSFinalWeight_35]
					,[gss_pq_PersonGSSFinalWeight_36]
					,[gss_pq_PersonGSSFinalWeight_37]
					,[gss_pq_PersonGSSFinalWeight_38]
					,[gss_pq_PersonGSSFinalWeight_39]
					,[gss_pq_PersonGSSFinalWeight_40]
					,[gss_pq_PersonGSSFinalWeight_41]
					,[gss_pq_PersonGSSFinalWeight_42]
					,[gss_pq_PersonGSSFinalWeight_43]
					,[gss_pq_PersonGSSFinalWeight_44]
					,[gss_pq_PersonGSSFinalWeight_45]
					,[gss_pq_PersonGSSFinalWeight_46]
					,[gss_pq_PersonGSSFinalWeight_47]
					,[gss_pq_PersonGSSFinalWeight_48]
					,[gss_pq_PersonGSSFinalWeight_49]
					,[gss_pq_PersonGSSFinalWeight_50]
					,[gss_pq_PersonGSSFinalWeight_51]
					,[gss_pq_PersonGSSFinalWeight_52]
					,[gss_pq_PersonGSSFinalWeight_53]
					,[gss_pq_PersonGSSFinalWeight_54]
					,[gss_pq_PersonGSSFinalWeight_55]
					,[gss_pq_PersonGSSFinalWeight_56]
					,[gss_pq_PersonGSSFinalWeight_57]
					,[gss_pq_PersonGSSFinalWeight_58]
					,[gss_pq_PersonGSSFinalWeight_59]
					,[gss_pq_PersonGSSFinalWeight_60]
					,[gss_pq_PersonGSSFinalWeight_61]
					,[gss_pq_PersonGSSFinalWeight_62]
					,[gss_pq_PersonGSSFinalWeight_63]
					,[gss_pq_PersonGSSFinalWeight_64]
					,[gss_pq_PersonGSSFinalWeight_65]
					,[gss_pq_PersonGSSFinalWeight_66]
					,[gss_pq_PersonGSSFinalWeight_67]
					,[gss_pq_PersonGSSFinalWeight_68]
					,[gss_pq_PersonGSSFinalWeight_69]
					,[gss_pq_PersonGSSFinalWeight_70]
					,[gss_pq_PersonGSSFinalWeight_71]
					,[gss_pq_PersonGSSFinalWeight_72]
					,[gss_pq_PersonGSSFinalWeight_73]
					,[gss_pq_PersonGSSFinalWeight_74]
					,[gss_pq_PersonGSSFinalWeight_75]
					,[gss_pq_PersonGSSFinalWeight_76]
					,[gss_pq_PersonGSSFinalWeight_77]
					,[gss_pq_PersonGSSFinalWeight_78]
					,[gss_pq_PersonGSSFinalWeight_79]
					,[gss_pq_PersonGSSFinalWeight_80]
					,[gss_pq_PersonGSSFinalWeight_81]
					,[gss_pq_PersonGSSFinalWeight_82]
					,[gss_pq_PersonGSSFinalWeight_83]
					,[gss_pq_PersonGSSFinalWeight_84]
					,[gss_pq_PersonGSSFinalWeight_85]
					,[gss_pq_PersonGSSFinalWeight_86]
					,[gss_pq_PersonGSSFinalWeight_87]
					,[gss_pq_PersonGSSFinalWeight_88]
					,[gss_pq_PersonGSSFinalWeight_89]
					,[gss_pq_PersonGSSFinalWeight_90]
					,[gss_pq_PersonGSSFinalWeight_91]
					,[gss_pq_PersonGSSFinalWeight_92]
					,[gss_pq_PersonGSSFinalWeight_93]
					,[gss_pq_PersonGSSFinalWeight_94]
					,[gss_pq_PersonGSSFinalWeight_95]
					,[gss_pq_PersonGSSFinalWeight_96]
					,[gss_pq_PersonGSSFinalWeight_97]
					,[gss_pq_PersonGSSFinalWeight_98]
					,[gss_pq_PersonGSSFinalWeight_99]
					,[gss_pq_PersonGSSFinalWeight_100]
				from
					&idi_version..gss_clean.gss_person_2010 pers
				inner join [IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_sh hhld on pers.snz_uid = hhld.snz_uid
				left join &idi_version..data.personal_detail pers_det on pers.snz_uid = pers_det.snz_uid
				inner join (select snz_gss_hhld_uid, sum([adult_ind]) as adult_count from [IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_sh group by snz_gss_hhld_uid) adults
					on (pers.snz_gss_hhld_uid = adults.snz_gss_hhld_uid)

				union all

				/*Renaming 2008 vars to 2014 vars */
				select 
					pers.snz_uid
					,pers.snz_gss_hhld_uid
					,pers_det.snz_spine_ind
					,'GSS2008' as gss_id_collection_code
					,cast([gss_pq_interview_start_date] as date) as gss_pq_interview_date
					,hhld.gss_hq_interview_start_date
					,hhld.gss_hq_sex_dev
					,hhld.gss_hq_birth_month_nbr
					,hhld.gss_hq_birth_year_nbr
					,hhld.gss_hq_house_trust
					,hhld.gss_hq_house_own
					,hhld.gss_hq_house_pay_mort_code
					,hhld.gss_hq_house_pay_rent_code
					,hhld.gss_hq_house_who_owns_code	
					,hhld.gss_pq_HH_tenure_code
					,cast(pers.gss_pq_HOUDV2 as smallint) as gss_pq_HH_crowd_code
					,coalesce(cast(pers.gss_pq_HOUQ03_14 as smallint), 0) as gss_pq_house_mold_code
					,coalesce(cast(pers.gss_pq_HOUQ03_15 as smallint), 0) as gss_pq_house_cold_code
					,cast(pers.gss_pq_HOUQ03_13 as smallint) as gss_pq_house_condition_code
					,cast(pers.gss_pq_HOUQ01 as smallint) as housing_satisfaction
					,pers.gss_pq_HOUQ04_14 as gss_pq_prob_hood_noisy_ind
					,pers.gss_pq_SAFQ01C as gss_pq_safe_night_pub_trans_code /* 4 point scale in 2010 & 2012; 5 point in 2008 & 2014*/
					,pers.gss_pq_SAFQ01E as gss_pq_safe_night_hood_code /* 4 point scale in 2010 & 2012; 5 point in 2008 & 2014*/
					,pers.gss_pq_SAFQ01D as gss_pq_safe_day_hood_code /* not in 2014*/
					,coalesce(pers.gss_pq_HUMQ07_19,0) as gss_pq_discrim_rent_ind /* 2012 question is about "applying for or keeping a house/flat". Probably too small to worry about */
					,cast(pers.gss_pq_SAFQ02 as smallint) as gss_pq_crimes_against_ind /* Slightly different wording (re traffic incidents) */
					,pers.gss_pq_CULQ04 as gss_pq_cult_identity_code /* Culture question asked differently across waves (and responses different)*/
					,cast(pers.gss_pq_HEADV2 as smallint) as gss_pq_ment_health_code
					,cast(pers.gss_pq_HEADV3 as smallint) as gss_pq_phys_health_code
					,cast(pers.gss_pq_CORDV14 as smallint) as gss_pq_lfs_dev
					,cast(pers.gss_pq_CORDV15 as smallint) as gss_pq_highest_qual_dev
					,pers.gss_pq_OLSQ01 as gss_pq_feel_life_code
					,pers.gss_pq_HUMQ01 as gss_pq_voting /* not in 2014 (just made up a var name) */
					/*pers.gss_pq_SOCQ13 as help_who_code -- Scales flipped between 2014 and rest. Question has different scope too.*/
					,pers.gss_pq_SOCQ11 as gss_pq_time_lonely_code /* Scales flipped between 2014 and rest. Prioritise over 'help who'*/
					,cast(gss_hq_household_inc1_dev as smallint) as gss_hq_household_inc1_dev
					,gss_pq_CORDV9
					,[gss_pq_CORPQ10_11]
					,[gss_pq_CORPQ10_12]
					,[gss_pq_CORPQ10_13]
					,[gss_pq_CORPQ10_14]
					,[gss_pq_CORPQ10_15]
					,[gss_pq_CORPQ10_16]
					,[gss_pq_CORPQ10_17]
					,[gss_pq_CORPQ10_18]
					,[gss_pq_CORDV4]
					,gss_pq_reg_council_08_code
					,adults.adult_count
					,NULL as gss_pq_material_wellbeing_code
					,case when cast(gss_pq_ELSIDV1 as smallint) between 0 and 31 
						then cast(gss_pq_ELSIDV1 as smallint)
					else NULL end as gss_pq_ELSIDV1
				,case when coalesce(gss_pq_CORDV8_17,0) =1  then 1 else 0 end as gss_unemp_jobseek 
   					 , case when coalesce(gss_pq_CORDV8_18,0)  = 1 then 1 else 0 end as gss_sickness
 					, case when coalesce(gss_pq_CORDV8_20,0) =1  then 1 else 0 end as gss_invalid_support
					, case when coalesce(gss_pq_CORDV8_19,0) = 1 then 1 else 0 end as gss_soleprnt_domestic
					, case when coalesce(gss_pq_CORDV8_22,0)  = 1 then 1 else 0 end as gss_oth_ben
				      ,case when coalesce(gss_pq_CORDV8_24,0)  = 1 then 1 else 0 end as gss_no_income

					,[gss_pq_PHYQ13]
					,[gss_pq_PHYQ14]
					,[gss_pq_LEIQ01] AS leisure_time

					,[gss_pq_PersonGSSSelectionWeight]
					,[gss_pq_person_FinalWgt_nbr]
					,[gss_pq_person_FinalWgt1_nbr]
					,[gss_pq_person_FinalWgt2_nbr]
					,[gss_pq_person_FinalWgt3_nbr]
					,[gss_pq_person_FinalWgt4_nbr]
					,[gss_pq_person_FinalWgt5_nbr]
					,[gss_pq_person_FinalWgt6_nbr]
					,[gss_pq_person_FinalWgt7_nbr]
					,[gss_pq_person_FinalWgt8_nbr]
					,[gss_pq_person_FinalWgt9_nbr]
					,[gss_pq_person_FinalWgt10_nbr]
					,[gss_pq_person_FinalWgt11_nbr]
					,[gss_pq_person_FinalWgt12_nbr]
					,[gss_pq_person_FinalWgt13_nbr]
					,[gss_pq_person_FinalWgt14_nbr]
					,[gss_pq_person_FinalWgt15_nbr]
					,[gss_pq_person_FinalWgt16_nbr]
					,[gss_pq_person_FinalWgt17_nbr]
					,[gss_pq_person_FinalWgt18_nbr]
					,[gss_pq_person_FinalWgt19_nbr]
					,[gss_pq_person_FinalWgt20_nbr]
					,[gss_pq_person_FinalWgt21_nbr]
					,[gss_pq_person_FinalWgt22_nbr]
					,[gss_pq_person_FinalWgt23_nbr]
					,[gss_pq_person_FinalWgt24_nbr]
					,[gss_pq_person_FinalWgt25_nbr]
					,[gss_pq_person_FinalWgt26_nbr]
					,[gss_pq_person_FinalWgt27_nbr]
					,[gss_pq_person_FinalWgt28_nbr]
					,[gss_pq_person_FinalWgt29_nbr]
					,[gss_pq_person_FinalWgt30_nbr]
					,[gss_pq_person_FinalWgt31_nbr]
					,[gss_pq_person_FinalWgt32_nbr]
					,[gss_pq_person_FinalWgt33_nbr]
					,[gss_pq_person_FinalWgt34_nbr]
					,[gss_pq_person_FinalWgt35_nbr]
					,[gss_pq_person_FinalWgt36_nbr]
					,[gss_pq_person_FinalWgt37_nbr]
					,[gss_pq_person_FinalWgt38_nbr]
					,[gss_pq_person_FinalWgt39_nbr]
					,[gss_pq_person_FinalWgt40_nbr]
					,[gss_pq_person_FinalWgt41_nbr]
					,[gss_pq_person_FinalWgt42_nbr]
					,[gss_pq_person_FinalWgt43_nbr]
					,[gss_pq_person_FinalWgt44_nbr]
					,[gss_pq_person_FinalWgt45_nbr]
					,[gss_pq_person_FinalWgt46_nbr]
					,[gss_pq_person_FinalWgt47_nbr]
					,[gss_pq_person_FinalWgt48_nbr]
					,[gss_pq_person_FinalWgt49_nbr]
					,[gss_pq_person_FinalWgt50_nbr]
					,[gss_pq_person_FinalWgt51_nbr]
					,[gss_pq_person_FinalWgt52_nbr]
					,[gss_pq_person_FinalWgt53_nbr]
					,[gss_pq_person_FinalWgt54_nbr]
					,[gss_pq_person_FinalWgt55_nbr]
					,[gss_pq_person_FinalWgt56_nbr]
					,[gss_pq_person_FinalWgt57_nbr]
					,[gss_pq_person_FinalWgt58_nbr]
					,[gss_pq_person_FinalWgt59_nbr]
					,[gss_pq_person_FinalWgt60_nbr]
					,[gss_pq_person_FinalWgt61_nbr]
					,[gss_pq_person_FinalWgt62_nbr]
					,[gss_pq_person_FinalWgt63_nbr]
					,[gss_pq_person_FinalWgt64_nbr]
					,[gss_pq_person_FinalWgt65_nbr]
					,[gss_pq_person_FinalWgt66_nbr]
					,[gss_pq_person_FinalWgt67_nbr]
					,[gss_pq_person_FinalWgt68_nbr]
					,[gss_pq_person_FinalWgt69_nbr]
					,[gss_pq_person_FinalWgt70_nbr]
					,[gss_pq_person_FinalWgt71_nbr]
					,[gss_pq_person_FinalWgt72_nbr]
					,[gss_pq_person_FinalWgt73_nbr]
					,[gss_pq_person_FinalWgt74_nbr]
					,[gss_pq_person_FinalWgt75_nbr]
					,[gss_pq_person_FinalWgt76_nbr]
					,[gss_pq_person_FinalWgt77_nbr]
					,[gss_pq_person_FinalWgt78_nbr]
					,[gss_pq_person_FinalWgt79_nbr]
					,[gss_pq_person_FinalWgt80_nbr]
					,[gss_pq_person_FinalWgt81_nbr]
					,[gss_pq_person_FinalWgt82_nbr]
					,[gss_pq_person_FinalWgt83_nbr]
					,[gss_pq_person_FinalWgt84_nbr]
					,[gss_pq_person_FinalWgt85_nbr]
					,[gss_pq_person_FinalWgt86_nbr]
					,[gss_pq_person_FinalWgt87_nbr]
					,[gss_pq_person_FinalWgt88_nbr]
					,[gss_pq_person_FinalWgt89_nbr]
					,[gss_pq_person_FinalWgt90_nbr]
					,[gss_pq_person_FinalWgt91_nbr]
					,[gss_pq_person_FinalWgt92_nbr]
					,[gss_pq_person_FinalWgt93_nbr]
					,[gss_pq_person_FinalWgt94_nbr]
					,[gss_pq_person_FinalWgt95_nbr]
					,[gss_pq_person_FinalWgt96_nbr]
					,[gss_pq_person_FinalWgt97_nbr]
					,[gss_pq_person_FinalWgt98_nbr]
					,[gss_pq_person_FinalWgt99_nbr]
					,[gss_pq_person_FinalWgt100_nbr]
				from
					&idi_version..gss_clean.gss_person_2008 pers
				inner join [IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_sh hhld on pers.snz_uid = hhld.snz_uid
				left join &idi_version..data.personal_detail pers_det on pers.snz_uid = pers_det.snz_uid
				inner join (select snz_gss_hhld_uid, sum([adult_ind]) as adult_count from [IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_sh group by snz_gss_hhld_uid) adults
					on (pers.snz_gss_hhld_uid = adults.snz_gss_hhld_uid)
			) person
			left join (
				select hh.[snz_gss_hhld_uid]
				from
				[IDI_Sandpit].[&si_proj_schema.].of_hh_addr_linking  addr
				inner join [IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_sh hh on (hh.snz_uid = addr.snz_uid_gss)
				inner join IDI_Sandpit.[&si_proj_schema.].SIAL_MSD_T2_events t2 
					on (addr.snz_uid = t2.snz_uid 
						and event_type = '471' 
						and addr.gss_hq_interview_date between t2.start_date and t2.end_date)
				group by hh.[snz_gss_hhld_uid] 
			) as accom on (person.snz_gss_hhld_uid = accom.snz_gss_hhld_uid)
			/*Create equivalised household size, uses Modified OECD method. 1 for first adult, 0.5 for subsequent adults and 0.3 for 
			children*/
			left join (select 
						snz_gss_hhld_uid
						,adult_ct
						,child_ct
						,hh_size
						,case when adult_ct > 0 then 1 else 0 end +
							case when adult_ct > 1 then 0.5 * (adult_ct - 1)  else 0 end +
							(0.3*child_ct) as hh_size_eq
					from (
						select 
							snz_gss_hhld_uid
							,sum(case when gss_hq_age_dev > 18 then 1 else 0 end) as adult_ct
							,sum(case when gss_hq_age_dev <= 18 then 1 else 0 end) as child_ct
							,count(*) as hh_size
						from IDI_Sandpit.[&si_proj_schema.].[of_gss_hh_variables_sh]
						group by snz_gss_hhld_uid
						)hhsize
					) as hhcomp
				on (person.snz_gss_hhld_uid = hhcomp.snz_gss_hhld_uid)
		) all_vars
		left join ( select * from [IDI_Sandpit].[&si_proj_schema.].[of_hnz_gss_population] 
					where 
						hnz_apply_type = 'new application' 
						and months_interview_to_entry between -12 and 15
					) hnzmain on (all_vars.snz_uid = hnzmain.snz_uid)
		left join ( select * from [IDI_Sandpit].[&si_proj_schema.].[of_hnz_gss_population] 
					where 
						hnz_apply_type = 'new application' 
						and months_interview_to_entry between -12 and 12
					) hnzsen on (all_vars.snz_uid = hnzsen.snz_uid)
	)z );

	disconnect from odbc;

quit;


/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=work._temp_of_gss_ind_variables,
	si_write_table_out=&si_sandpit_libname..of_gss_ind_variables_sh
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);