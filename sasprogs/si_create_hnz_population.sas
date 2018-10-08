/*********************************************************************************************************
DESCRIPTION: 
Creates the HNZ population subset to the GSS population.

INPUT:
[&idi_version.].[gss_clean].[gss_household] = 2014 GSS household table
[&idi_version.].[gss_clean].[gss_household_2012] = 2012 GSS household table
[&idi_version.].[gss_clean].[gss_household_2010] = 2010 GSS household table
[&idi_version.].[gss_clean].[gss_household_2008] = 2008 GSS household table
[&idi_version.].[hnz_clean].[tenancy_snapshot]
[&idi_version.].[hnz_clean].[tenancy_household_snapshot]
[&idi_version.].[hnz_clean].[tenancy_exit]


OUTPUT:
sand.assembled_tenancy_HNZ = dataset with HNZ tenancy details for individuals in GSS08-14
sand.assembled_registry_HNZ = dataset with HNZ register details for individuals in GSS08-14
sand.of_hnz_gss_population = dataset with household variables for GSS

AUTHOR: 
S Anastasiadis

DEPENDENCIES:
NA

NOTES:   
1. Individuals in the GSS households are not linked to the spine at the time of writing this code, except
	for those individuals who also answer the personal questionnaire. 
2. All GSS waves are available only from &idi_version._20171027 onwards.


HISTORY: 
22 Nov 2017 VB Converted the SQL version into SAS.

***********************************************************************************************************/


/* This script identifies all individuals in the GSS person table that are also in the HNZ tenancy tables,
	and captures all tenancy terms they've had. Tenancy tables track HNZ clients once they have 
	been placed in a social house. */
proc sql;
	connect to odbc (dsn=&idi_version._srvprd);
	create table _temp_assembled_tenancy_HNZ as 
		select * from connection to odbc (
			/* For each primary tenant, get the start and end date of snapshots for each time 
			they resided in an HNZ house*/
			with trim_ts as(
				SELECT [snz_household_uid]
				  ,[snz_legacy_household_uid]
				  ,[hnz_ts_house_entry_date]
				  ,[snz_hnz_ts_house_uid]
				  ,[snz_hnz_ts_legacy_house_uid]
				  ,min(hnz_ts_snapshot_date) AS min_ts_snap_date
				  ,max(hnz_ts_snapshot_date) AS max_ts_snap_date
				FROM [&idi_version.].[hnz_clean].[tenancy_snapshot]
				GROUP BY [snz_household_uid]
				      ,[snz_legacy_household_uid]
				      ,[hnz_ts_house_entry_date]
				      ,[snz_hnz_ts_house_uid]
				      ,[snz_hnz_ts_legacy_house_uid]
			)
			/* For each member of the tenant household, get the start and end date of snapshots for each time 
			they resided in an HNZ house*/
			,trim_ths as (
				SELECT [snz_household_uid]
				  ,[snz_legacy_household_uid]
				  ,[snz_uid]
				  ,min(hnz_ths_snapshot_date) AS min_ths__snap_date
				  ,max(hnz_ths_snapshot_date) AS max_ths_snap_date
				FROM [&idi_version.].[hnz_clean].[tenancy_household_snapshot]
				GROUP BY [snz_household_uid]
				      ,[snz_legacy_household_uid]
				      ,[snz_uid]
			)
			/* Get the exit dates for each tenancy*/
			,trim_te as (
				SELECT *
				FROM [&idi_version.].[hnz_clean].[tenancy_exit]
				WHERE [hnz_te_exit_status_text] IS NOT NULL
			)
			/* Get all GSS personal questionnaire responders*/
			,NZGSS_full_IDs as (
				SELECT *
				FROM (
					SELECT [snz_uid],[gss_pq_collection_code],[gss_pq_interview_start_date] FROM [&idi_version.].[gss_clean].[gss_person_2008]
					UNION ALL
					SELECT [snz_uid],[gss_pq_collection_code],[gss_pq_interview_start_date] FROM [&idi_version.].[gss_clean].[gss_person_2010]
					UNION ALL
					SELECT [snz_uid],[gss_pq_collection_code],[gss_pq_interview_start_date] FROM [&idi_version.].[gss_clean].[gss_person_2012]
					UNION ALL
					SELECT [snz_uid],[gss_pq_collection_code],[gss_pq_PQinterview_date] FROM [&idi_version.].[gss_clean].[gss_person])x
			)
			SELECT gss.[gss_pq_collection_code]
			      ,gss.gss_pq_interview_start_date
			      ,ts.[snz_household_uid]
			      ,ts.[snz_legacy_household_uid]			      
			      ,ts.[hnz_ts_house_entry_date]
			      ,te.[hnz_te_exit_date]
			      ,ts.[min_ts_snap_date]
			      ,ts.[max_ts_snap_date]
				  ,ths.[min_ths__snap_date]
				  ,ths.[max_ths_snap_date]
			      ,te.[hnz_te_snapshot_date]
			      ,te.[hnz_te_exit_status_text]			      
			      ,ts.[snz_hnz_ts_house_uid]
			      ,ts.[snz_hnz_ts_legacy_house_uid]
				  ,ths.[snz_uid]
			  FROM [NZGSS_full_IDs] gss
			  INNER JOIN [trim_ths] ths ON gss.snz_uid = ths.snz_uid
			  LEFT JOIN [trim_ts] ts 
				ON (ts.[snz_household_uid] = ths.[snz_household_uid]
			  	OR ts.[snz_legacy_household_uid] = ths.[snz_legacy_household_uid])
			  LEFT JOIN [trim_te] te
				  ON (ts.[snz_household_uid] = te.[snz_household_uid]
				  OR ts.[snz_legacy_household_uid] = te.[snz_legacy_household_uid])
		);
	disconnect from odbc;
quit;

/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=work._temp_assembled_tenancy_HNZ,
	si_write_table_out=&si_sandpit_libname..assembled_tenancy_HNZ
	,si_cluster_index_flag=True,si_index_cols=%bquote(snz_uid)
	);




/* This script identifies all individuals in the GSS person table that are also in the HNZ application registers
	with a successfully housed outcome for their applications- both new and transfers. */
proc sql;
	connect to odbc (dsn=&idi_version._srvprd);
	create table _temp_assembled_registry_HNZ as 
		select * from connection to odbc (
			/* For each individual who spent time on the application register, this query gives the start
			and end of those register waits (approximated as start and end of snapshot dates)*/
			with trim_rs as (
				SELECT [snz_application_uid]
					,[snz_legacy_application_uid]
					,min([hnz_rs_snapshot_date]) AS min_rs_snap_date
					,max([hnz_rs_snapshot_date]) AS max_rs_snap_date
				FROM [&idi_version.].[hnz_clean].[register_snapshot]
				GROUP BY [snz_application_uid]
					,[snz_legacy_application_uid]
			)
			/* For each individual who spent time on the application register, this query gives the start
			and end of those register waits (approximated as start and end of snapshot dates) for everyone
			included as part of the application*/
			,trim_rhs as (
				SELECT [snz_application_uid]
					,[snz_legacy_application_uid]
					,[snz_uid]
					,min([hnz_rhs_snapshot_date]) AS min_rhs__snap_date
					,max([hnz_rhs_snapshot_date]) AS max_rhs_snap_date
				FROM [&idi_version.].[hnz_clean].[register_household_snapshot]
				GROUP BY [snz_application_uid]
					,[snz_legacy_application_uid]
					,[snz_uid]
			)
			/* Get the register wait end dates for all housed applications*/
			,trim_re as (
				SELECT *
				FROM [&idi_version.].[hnz_clean].[register_exit]
				WHERE [hnz_re_exit_status_text] = 'HOUSED'
			)
			/* Get all application attributes (for both new and tranfer applications)*/
			,trim_ra as (
				SELECT *
				FROM (
					SELECT [hnz_na_date_of_application_date]
						,[snz_application_uid]
						,[snz_legacy_application_uid]
						,[hnz_na_analy_score_afford_text]
						,[hnz_na_analy_score_adeq_text]
						,[hnz_na_analy_score_suitably_text]
						,[hnz_na_analy_score_sustain_text]
						,[hnz_na_analy_score_access_text]
						,[hnz_na_analysis_total_score_text]
						,[hnz_na_hshd_size_nbr]
						,'new application' AS hnz_apply_type
					FROM [&idi_version.].[hnz_clean].[new_applications]
					UNION ALL
					SELECT [hnz_ta_application_date]
						,[snz_application_uid]
						,[snz_legacy_application_uid]
						,[hnz_ta_analy_score_afford_text]
						,[hnz_ta_analy_score_adeq_text]
						,[hnz_ta_analy_score_suit_text]
						,[hnz_ta_analy_score_sustain_text]
						,[hnz_ta_analy_score_access_text]
						,[hnz_ta_analysis_total_score_text]
						,[hnz_ta_hshd_size_nbr]
						,'transfer application' AS hnz_apply_type
					FROM [&idi_version.].[hnz_clean].[transfer_applications]
				) k
			)
			/* Get all GSS personal questionnaire responders*/
			,NZGSS_full_IDs as (
				SELECT *
/*				INTO [IDI_Sandpit].[{schemaname}].[NZGSS_full_IDs]*/
				FROM (
				SELECT [snz_uid],[gss_pq_collection_code],[gss_pq_interview_start_date] FROM [&idi_version.].[gss_clean].[gss_person_2008]
				UNION ALL
				SELECT [snz_uid],[gss_pq_collection_code],[gss_pq_interview_start_date] FROM [&idi_version.].[gss_clean].[gss_person_2010]
				UNION ALL
				SELECT [snz_uid],[gss_pq_collection_code],[gss_pq_interview_start_date] FROM [&idi_version.].[gss_clean].[gss_person_2012]
				UNION ALL
				SELECT [snz_uid],[gss_pq_collection_code],[gss_pq_PQinterview_date] FROM [&idi_version.].[gss_clean].[gss_person]
				) k
			)
			SELECT gss.[gss_pq_collection_code]
			,gss.[gss_pq_interview_start_date]
			,rs.[snz_application_uid]
			,rs.[snz_legacy_application_uid]
			,ra.[hnz_na_date_of_application_date]
			,re.[hnz_re_exit_date]
			,rs.[min_rs_snap_date]
			,rs.[max_rs_snap_date]
			,rhs.[min_rhs__snap_date]
			,rhs.[max_rhs_snap_date]
			,re.[hnz_re_exit_status_text]
			,re.[snz_house_uid]
			,re.[snz_legacy_house_uid]
			,rhs.[snz_uid]
			,ra.[hnz_na_analy_score_afford_text]
			,ra.[hnz_na_analy_score_adeq_text]
			,ra.[hnz_na_analy_score_suitably_text]
			,ra.[hnz_na_analy_score_sustain_text]
			,ra.[hnz_na_analy_score_access_text]
			,ra.[hnz_na_analysis_total_score_text]
			,ra.[hnz_na_hshd_size_nbr]
			,ra.[hnz_apply_type]
/*			INTO [IDI_Sandpit].[{schemaname}].[assembled_registry_HNZ]*/
			FROM [NZGSS_full_IDs] gss
			INNER JOIN [trim_rhs] rhs
				ON gss.snz_uid = rhs.snz_uid
			LEFT JOIN [trim_rs] rs
				ON rs.[snz_application_uid] = rhs.[snz_application_uid]
					OR rs.[snz_legacy_application_uid] = rhs.[snz_legacy_application_uid]
			LEFT JOIN [trim_re] re
				ON rs.[snz_application_uid] = re.[snz_application_uid]
					OR rs.[snz_legacy_application_uid] = re.[snz_legacy_application_uid]
			LEFT JOIN [trim_ra] ra
				ON rs.[snz_application_uid] = ra.[snz_application_uid]
					OR rs.[snz_legacy_application_uid] = ra.[snz_legacy_application_uid]
		);
	disconnect from odbc;
quit;


/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=work._temp_assembled_registry_HNZ,
	si_write_table_out=&si_sandpit_libname..assembled_registry_HNZ
	,si_cluster_index_flag=True,si_index_cols=%bquote(snz_uid)
	);



proc sql;
	connect to odbc (dsn=&idi_version._srvprd);
	create table _temp_of_hnz_gss_population as 
		select * from connection to odbc (
			with of_hnz_gss_population_tmp as (
				SELECT DISTINCT *
	/*			INTO [IDI_Sandpit].[{schemaname}].[of_hnz_gss_population_tmp]*/
				FROM (
					SELECT 
						t.[gss_pq_collection_code]
						,t.[snz_uid]
						,r.[hnz_na_date_of_application_date] AS hnz_application_date
						,r.[hnz_re_exit_date] AS hnz_application_exit_date
						,r.[hnz_re_exit_status_text] hnz_application_exit_status
						,t.[gss_pq_interview_start_date] AS gss_pq_interview_date
						,t.[hnz_ts_house_entry_date] AS tenancy_entry_date
						,t.hnz_te_exit_date
						,t.hnz_te_exit_status_text
						,datediff(m,t.[gss_pq_interview_start_date],t.[hnz_ts_house_entry_date]) AS months_interview_to_entry /*in how many months will you enter*/
						,CASE WHEN datediff(d,t.[gss_pq_interview_start_date],t.[hnz_ts_house_entry_date]) <= 0 THEN 'TREATED' ELSE 'CONTROL' END AS treat_control
						,CASE WHEN abs(datediff(d,r.[hnz_re_exit_date],t.[hnz_ts_house_entry_date])) IS NOT NULL THEN abs(datediff(d,r.[hnz_re_exit_date],t.[hnz_ts_house_entry_date])) ELSE 0 END AS days_granted_to_entry
						,r.[hnz_na_analy_score_afford_text]
						,r.[hnz_na_analy_score_adeq_text]
						,r.[hnz_na_analy_score_suitably_text]
						,r.[hnz_na_analy_score_sustain_text]
						,r.[hnz_na_analy_score_access_text]
						,r.[hnz_na_analysis_total_score_text]
						,r.[hnz_na_hshd_size_nbr]
						,r.[hnz_apply_type]
					FROM [IDI_Sandpit].[&si_proj_schema.].[assembled_tenancy_HNZ] t
					FULL OUTER JOIN [IDI_Sandpit].[&si_proj_schema.].[assembled_registry_HNZ] r
						ON (t.snz_uid = r.snz_uid AND t.snz_hnz_ts_house_uid = r.snz_house_uid)
							OR (t.snz_uid = r.snz_uid AND t.snz_hnz_ts_legacy_house_uid = r.snz_legacy_house_uid)
					WHERE 
						datediff(m,t.[gss_pq_interview_start_date],t.[hnz_ts_house_entry_date]) <= 18 /* 18 months from interview date*/
						AND datediff(m,t.[gss_pq_interview_start_date],t.[hnz_ts_house_entry_date]) >= -18 /* 18 months before interview date*/
						AND t.[hnz_ts_house_entry_date] IS NOT NULL /*have an entry date*/
						/*--AND r.[hnz_re_exit_date] IS NOT NULL --housed according to register
						--AND r.[hnz_na_date_of_application_date] IS NOT NULL --have an application date
						--AND r.[hnz_na_date_of_application_date] < t.[gss_pq_interview_start_date] --applied before interview
						--AND (datediff(m,t.[gss_pq_interview_start_date],t.[hnz_te_exit_date]) IS NULL 
								OR datediff(m,t.[gss_pq_interview_start_date],t.[hnz_te_exit_date]) >= 12) --does not exit within 12 months of interview*/
						AND abs(datediff(m,t.[hnz_ts_house_entry_date],t.[min_ths__snap_date])) <= 6 /*appear in snapshot data within 6 months of house being entered*/
						/*--AND ((NOT t.hnz_te_exit_status_text = 'EXIT ALL SOCIAL HOUSING') 
								OR t.gss_pq_interview_start_date < t.hnz_te_exit_date OR t.hnz_te_exit_date IS NULL) --don't exit before interview*/    
				) k
			)
			SELECT a.[gss_pq_collection_code]
				,a.[snz_uid]
				,a.[hnz_application_date]
				,a.[hnz_application_exit_date]
				,a.[hnz_application_exit_status]
				,a.[gss_pq_interview_date]
				,a.[tenancy_entry_date]
				,a.[months_interview_to_entry]
				,a.[treat_control]
				,a.[hnz_na_analy_score_afford_text]
				,a.[hnz_na_analy_score_adeq_text]
				,a.[hnz_na_analy_score_suitably_text]
				,a.[hnz_na_analy_score_sustain_text]
				,a.[hnz_na_analy_score_access_text]
				,a.[hnz_na_analysis_total_score_text]
				,a.[hnz_na_hshd_size_nbr]
				,a.[hnz_apply_type]
/*			INTO [IDI_Sandpit].[DL-MAA2016-15].[of_hnz_gss_population]*/
			FROM [of_hnz_gss_population_tmp] a
			INNER JOIN (
				SELECT snz_uid,min(tenancy_entry_date) AS tenancy_entry_date
				FROM [of_hnz_gss_population_tmp]
				GROUP BY snz_uid
				) b
				ON a.snz_uid = b.snz_uid AND a.tenancy_entry_date = b.tenancy_entry_date
			INNER JOIN (
				SELECT snz_uid,min(days_granted_to_entry) As min_diff
				FROM [of_hnz_gss_population_tmp]
				GROUP BY snz_uid
			) c
				ON a.snz_uid = c.snz_uid AND a.days_granted_to_entry = c.min_diff;
		);
	disconnect from odbc;
quit;


/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=work._temp_of_hnz_gss_population,
	si_write_table_out=&si_sandpit_libname..of_hnz_gss_population
	,si_cluster_index_flag=True,si_index_cols=%bquote(snz_uid)
	);
