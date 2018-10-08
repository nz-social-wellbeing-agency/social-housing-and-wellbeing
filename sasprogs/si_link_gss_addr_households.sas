/*********************************************************************************************************
DESCRIPTION: 
Creates a mapping between the GSS version of unlinked snz_uids to the IDI Spine UIDs on the basis
of address data, date & month of birth and sex. Only one-to-one links are retained, others are discarded.

This involves the following steps:

1. We first pick all people from GSS person interviews (across all waves), and only retain the ones 
	linked to IDI Spine.
2. Then we obtain the address of these interviewees as on the household interview date, and find all 
	individuals is resident at the address on the same date.
3. Once we have the list of all residents at the address, we use sex, month and year of birth listed in 
	GSS Household to match these individuals of the same household with the residents at the same address.
4. In case of one-to-many matches between GSS snz_uids and spine_sz_uids (and vice-versa), we remove such links 
	and retain only one to one matches.

INPUT:
[&idi_version.].[gss_clean].[gss_person] = 2014 GSS person table
[&idi_version.].[gss_clean].[gss_person_2012] = 2012 GSS person table
[&idi_version.].[gss_clean].[gss_person_2010] = 2010 GSS person table
[&idi_version.].[gss_clean].[gss_person_2008] = 2008 GSS person table
[IDI_Sandpit].[<schemaname>].[of_gss_hh_variables_sh] = Household variables dataset
[&idi_version.].data.address_notification
[&idi_version.].data.personal_detail

OUTPUT:
sand.of_hh_addr_linking = Linked individuals from GSS households

AUTHOR: 
V Benny

DEPENDENCIES:
NA

NOTES:   


HISTORY: 
22 Nov 2017 VB Created a wrapper for the SQL script that does all the heavy lifting.
12 Sep 2018 VB Added the queries into the file for easier switching between IDI refreshes.

***********************************************************************************************************/

/* This table creates a mapping between the unlinked "snz_uid"s in the GSS household tables across 2008 to 2014
and potential matched individuals in the IDI Spine, using the individuals in the same address listed by GSS 
personal questionairre individuals (who are already linked to spine).*/
proc sql;
	connect to odbc (dsn=&idi_version._srvprd);
	create table _temp_gss_hh_snzuid_mapping as 
		select * from connection to odbc (
			/*	First, we define all individuals answering the GSS personal questionnaire.*/
			with of_gss_ind as (
				select 
					p.*
					,h.[gss_hq_interview_start_date] 
				from
				(
					select distinct snz_uid, snz_gss_hhld_uid from &idi_version..[gss_clean].[gss_person]
					union all 
					select distinct snz_uid, snz_gss_hhld_uid from &idi_version..[gss_clean].[gss_person_2012]
					union all 
					select distinct snz_uid, snz_gss_hhld_uid from &idi_version..[gss_clean].[gss_person_2010]		
					union all 
					select distinct snz_uid, snz_gss_hhld_uid from &idi_version..[gss_clean].[gss_person_2008]
				) p
				inner join [IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_sh h on (p.snz_uid = h.snz_uid)		
			)
			select distinct 
				other_resident
				,hh.snz_uid
			from (
				select 
					mainper.snz_gss_hhld_uid
					, a.snz_uid as other_resident
					, per.snz_birth_year_nbr
					, per.snz_birth_month_nbr
					, per.snz_sex_code
				from 
				(
					select 
						linked_gss.snz_uid as main_person
						,linked_gss.snz_gss_hhld_uid
						,linked_gss.gss_hq_interview_start_date
						,addr.snz_idi_address_register_uid
					from 
					(
						select 
							gss.snz_uid
							,gss.gss_hq_interview_start_date
							,gss.snz_gss_hhld_uid
						from of_gss_ind gss
						/* Retain only those from the GSS personal data that link to IDI Spine*/
						inner join &idi_version..data.personal_detail p on (gss.snz_uid = p.snz_uid and p.snz_spine_ind = 1)
						)linked_gss
					/* Get their addresses from Admin data as on the date of household interview*/
					inner join &idi_version..data.address_notification addr 
						on (linked_gss.snz_uid = addr.snz_uid 
							and linked_gss.gss_hq_interview_start_date between addr.ant_notification_date and addr.ant_replacement_date)
				) mainper
				/* Based on the addresses of the GSS personal questionnaire individuals, obtain everyone else resident at the address on the 
					household interview date as on the household interview date (such that those individuals are also linked to spine).*/
				inner join &idi_version..data.address_notification a 
					on (mainper.snz_idi_address_register_uid = a.snz_idi_address_register_uid 
						and mainper.gss_hq_interview_start_date between a.ant_notification_date and a.ant_replacement_date)
				inner join &idi_version..data.personal_detail per on (a.snz_uid = per.snz_uid and per.snz_spine_ind = 1)
			)all_ind
			/* Join those individuals resident at the addresses of the GSS PQ individuals to the GSS Household individuals, and match on date & month of birth and sex*/
			inner join [IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_sh hh on ( 
				all_ind.snz_gss_hhld_uid = hh.snz_gss_hhld_uid and all_ind.snz_sex_code = hh.gss_hq_sex_dev and all_ind.snz_birth_year_nbr = hh.gss_hq_birth_year_nbr 
				and all_ind.snz_birth_month_nbr = hh.gss_hq_birth_month_nbr)
		);
	disconnect from odbc;
quit;


/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=work._temp_gss_hh_snzuid_mapping,
	si_write_table_out=&si_sandpit_libname..gss_hh_snzuid_mapping
	,si_cluster_index_flag=True,si_index_cols=%bquote(other_resident, &si_id_col.)
	);

/* Step 4 - Eliminate one-to-many matches between admin and GSS Household snz_uid mappings and retain one-to-one links*/
proc sql;
	connect to odbc (dsn=&idi_version._srvprd);
	create table _temp_hh_addr_linking as 
		select * from connection to odbc (
			select 
				linking.snz_uid_spine as snz_uid
				,hh.snz_uid as snz_uid_gss
				,hh.snz_gss_hhld_uid
				,cast(hh.gss_hq_interview_start_date as datetime) gss_hq_interview_date
			from [IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_sh hh
			inner join (
				select  
					other_resident as snz_uid_spine
					,snz_uid as snz_uid_gss 
				from IDI_Sandpit.[&si_proj_schema.].gss_hh_snzuid_mapping
				where other_resident not in (select other_resident from IDI_Sandpit.[&si_proj_schema.].gss_hh_snzuid_mapping 
											group by other_resident having count(distinct snz_uid) > 1)
					and snz_uid not in (select snz_uid from IDI_Sandpit.[&si_proj_schema.].gss_hh_snzuid_mapping 
										group by snz_uid having count(distinct other_resident) > 1)
				) linking on (hh.snz_uid = linking.snz_uid_gss)
		);
	disconnect from odbc;
quit;


/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=work._temp_hh_addr_linking,
	si_write_table_out=&si_sandpit_libname..of_hh_addr_linking
	,si_cluster_index_flag=True,si_index_cols=%bquote(snz_uid)
	);
