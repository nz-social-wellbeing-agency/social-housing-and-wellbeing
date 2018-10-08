/*********************************************************************************************************
DESCRIPTION: 
Combines all the GSS household information across different waves into one single 
table. Only a limited set of variables which are useful for the outcomes framework project have 
been retained in the output.

INPUT:
[&idi_version.].[gss_clean].[gss_household] = 2014 GSS household table
[&idi_version.].[gss_clean].[gss_household_2012] = 2012 GSS household table
[&idi_version.].[gss_clean].[gss_household_2010] = 2010 GSS household table
[&idi_version.].[gss_clean].[gss_household_2008] = 2008 GSS household table

OUTPUT:
sand.of_gss_hh_variables_sh = dataset with household variables for GSS

AUTHOR: 
V Benny

DEPENDENCIES:
NA

NOTES:   
1. Individuals in the GSS households are not linked to the spine at the time of writing this code, except
	for those individuals who also answer the personal questionnaire. 
2. All GSS waves are available only from IDI_Clean_20171027 onwards.


HISTORY: 
22 Nov 2017 VB Converted the SQL version into SAS.

***********************************************************************************************************/

proc sql;

	connect to odbc (dsn=&si_idi_dsnname.);

	create table work._temp_of_gss_hh_variables as
	select *
	from connection to odbc(		
		select 
			household.snz_uid
			,household.snz_gss_hhld_uid
			,gss_id_collection_code
			,[gss_hq_interview_start_date]
			/* For each of the household tenure variables, we only need one value per household ID, and this needs to be 
			inherited from the person who answered the GSS Household questionnaire. For GSS waves 2012, 2010 and 2008,
			these values are available only for this person and are NULLs for everyone else. To do this, we pick the first 
			numeric value available per household by decoding NULLs to an arbitrarily large number. It is to be noted that
			in case there are different responses from different household members, we retain the minimum numeric value.
			*/
			,first_value(gss_hq_house_trust) over (partition by household.snz_gss_hhld_uid 
				order by coalesce(gss_hq_house_trust, 9999999999) asc ) as gss_hq_house_trust
			,first_value(gss_hq_house_own) over (partition by household.snz_gss_hhld_uid 
				order by coalesce(gss_hq_house_own, 9999999999) asc ) as gss_hq_house_own
			,first_value(gss_hq_house_pay_mort_code) over (partition by household.snz_gss_hhld_uid 
				order by coalesce(gss_hq_house_pay_mort_code, 9999999999) asc ) as gss_hq_house_pay_mort_code
			,first_value(gss_hq_house_pay_rent_code) over (partition by household.snz_gss_hhld_uid 
				order by coalesce(gss_hq_house_pay_rent_code, 9999999999) asc ) as gss_hq_house_pay_rent_code
			,first_value(gss_hq_house_who_owns_code) over (partition by household.snz_gss_hhld_uid 
				order by coalesce(gss_hq_house_who_owns_code, 9999999999) asc ) as gss_hq_house_who_owns_code	
			,first_value(gss_pq_HH_tenure_code) over (partition by household.snz_gss_hhld_uid 
				order by coalesce(gss_pq_HH_tenure_code, 9999999999) asc ) as gss_pq_HH_tenure_code
			,gss_hq_household_inc1_dev
			,gss_hq_sex_dev
			,[gss_hq_birth_month_nbr]
			,[gss_hq_birth_year_nbr]
			,[gss_hq_regcouncil_dev]
			/* Create an indicator for whether the member of household is an adult(above 15 years of age) or not*/
			,case [gss_hq_under_15_dev] when 'N' then 1 when 'Y' then 0 end as [adult_ind]
			,gss_hq_age_dev
		from 
			(
			select 
				hh.snz_uid
				,hh.snz_gss_hhld_uid
				,'GSS2014' as gss_id_collection_code
				,p.gss_pq_HQinterview_date as [gss_hq_interview_start_date]
				/* Convert 2014 household tenure variables into integer, to be consistent with waves 2012, 2010, 2008*/
				,cast(hh.gss_hq_house_trust as smallint) as gss_hq_house_trust 
				,cast(hh.gss_hq_house_own as smallint) as gss_hq_house_own
				,cast(hh.gss_hq_house_pay_mort_code as smallint) as gss_hq_house_pay_mort_code
				,cast(hh.gss_hq_house_pay_rent_code as smallint) as gss_hq_house_pay_rent_code
				,hh.gss_hq_house_who_owns_code
				/* We use NULL for HH tenure at household level because we already have that variable at the person GSS level.*/
				,NULL as gss_pq_HH_tenure_code 
				,hh.gss_hq_household_inc1_dev
				,hh.gss_hq_sex_dev
				,hh.[gss_hq_birth_month_nbr]
				,hh.[gss_hq_birth_year_nbr]
				,[gss_hq_regcouncil_dev]
				,[gss_hq_under_15_dev]
				,gss_hq_age_dev
			from [&idi_version.].[gss_clean].[gss_household] hh
			inner join [&idi_version.].[gss_clean].[gss_person] p on (hh.snz_gss_hhld_uid = p.snz_gss_hhld_uid)

			union all 

			select snz_uid
				,snz_gss_hhld_uid
				,'GSS2012' as gss_id_collection_code
				,cast([gss_hq_interview_start_date] as date) as [gss_hq_interview_start_date]
				,gss_hq_CORHQ05
				,gss_hq_CORHQ07
				,gss_hq_CORHQ08
				,gss_hq_CORHQ10
				,gss_hq_CORHQ09
				,gss_hq_CORDV16  
				,gss_hq_CORDV13
				/* Decoding sex variable to be consistent with wave 2014, 11 to 1-Male, 12 to 2-Female */
				,case [gss_hq_CORDV10] when '11' then 1 when '12' then 2 else NULL end as [gss_hq_CORDV10] 
				,[gss_hq_birth_month_nbr]
				,[gss_hq_birth_year_nbr]
				/* Region Council is only available at person level for waves except 2014, so we code it as NULL*/
				,null as [gss_hq_regcouncil_dev]
				,[gss_hq_Under15_DV]
				,[gss_hq_CORDV9]
			from [&idi_version.].[gss_clean].[gss_household_2012]

			union all 

			select snz_uid
				,snz_gss_hhld_uid
				,'GSS2010' as gss_id_collection_code
				,cast([gss_hq_interview_start_date] as date) as [gss_hq_interview_start_date]
				,gss_hq_CORHQ05
				,gss_hq_CORHQ07
				,gss_hq_CORHQ08
				,gss_hq_CORHQ10
				,gss_hq_CORHQ09
				/* For uniformity of "don't know"/"refused" values with waves 2012 and 2014, we decode 88-Don't Know and 
				99-Refused to 77. */
				,case when gss_hq_CORDV16 in ('88', '99') then '77' else gss_hq_CORDV16 end as gss_hq_CORDV16 
				,gss_hq_CORDV13
				/* Decoding sex variable to be consistent with wave 2014, 11 to 1-Male, 12 to 2-Female */
				,case [gss_hq_CORDV10] when '11' then 1 when '12' then 2 else NULL end as [gss_hq_CORDV10]
				,[gss_hq_birth_month_nbr]
				,[gss_hq_birth_year_nbr]
				/* Region Council is only available at person level for waves except 2014, so we code it as NULL*/
				,null as [gss_hq_regcouncil_dev]
				,[gss_hq_Under15_DV]
				,[gss_hq_CORDV9]
			from [&idi_version.].[gss_clean].[gss_household_2010]

			union all 

			select snz_uid
				,snz_gss_hhld_uid
				,'GSS2008' as gss_id_collection_code
				,cast([gss_hq_interview_start_date] as date) as [gss_hq_interview_start_date]
				,gss_hq_CORHQ05
				,gss_hq_CORHQ07
				,gss_hq_CORHQ08
				,gss_hq_CORHQ10
				,gss_hq_CORHQ09
				/* For uniformity of "don't know"/"refused" values with waves 2012 and 2014, we decode 88-Don't Know and 
				99-Refused to 77. */
				,case when gss_hq_CORDV16 in ('88', '99') then '77' else gss_hq_CORDV16 end as gss_hq_CORDV16 
				,gss_hq_CORDV13
				/* Decoding sex variable to be consistent with wave 2014, 11 to 1-Male, 12 to 2-Female */
				,case [gss_hq_CORDV10] when '11' then 1 when '12' then 2 else NULL end as [gss_hq_CORDV10]
				,[gss_hq_birth_month_nbr]
				,[gss_hq_birth_year_nbr]
				/* Region Council is only available at person level for waves except 2014, so we code it as NULL*/
				,null as [gss_hq_regcouncil_dev]
				,[gss_hq_Under15_DV]
				,[gss_hq_CORDV9]
			from [&idi_version.].[gss_clean].[gss_household_2008]
		) household					
	);

	disconnect from odbc;

quit;

/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=work._temp_of_gss_hh_variables,
	si_write_table_out=&si_sandpit_libname..of_gss_hh_variables_sh
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);

/* Remove temporary datasets */
proc datasets lib=work;
	delete _temp_:;
run;