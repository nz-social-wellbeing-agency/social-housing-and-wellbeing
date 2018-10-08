/*********************************************************************************************************
DESCRIPTION: Main script that determines the sequence of execution for all SAS data preparation tasks.


INPUT:
	si_control.sas = Specify the parameters which decide how the data foundation works and what variables 
		to create.
	si_source_path = Specify the path where you saved the SI data foundation code.

OUTPUT:
	

AUTHOR: V Benny

DEPENDENCIES:
1. Social Investment Data Foundation macros need to be available as a library.
2. si_control.sas file should be set up with the configuration parameters required to run the data 
	foundation.

NOTES: 
This script takes 40 minutes to run end to end.

HISTORY: 
*********************************************************************************************************/

/* Switch this statement off when testing is complete */
options mlogic mprint;

/* Parameterise location where the folders are stored */
%let si_source_path = \\wprdfs09\Datalab-MA\MAA2016-15 Supporting the Social Investment Unit\outcomes_framework\workstream5;

/*********************************************************************************************************/

/* Set up a variable to store the runtime of the script; this helps to plan for future re-runs of code if necessary */
%global si_main_start_time;
%let si_main_start_time = %sysfunc(time());

/* Load all the macros from the social investment data foundation*/
options obs=MAX mvarsize=max pagesize=132
        append=(sasautos=("&si_source_path.\lib\social_investment_data_foundation\sasautos"));

/* Load the user's parameters and global variables that define how the data foundation works from the 
	control file */
%include "&si_source_path.\sasprogs\si_control.sas";
libname &si_sandpit_libname. ODBC dsn= idi_sandpit_srvprd schema="&si_proj_schema." bulkload=yes;

/* Generate the GSS population of individuals from household for which variables are to be created.*/
%include "&si_source_path.\sasprogs\si_create_of_gss_hh_variables.sas";

/* Perform linking of individuals in the household dataset with admin data in the IDI.*/
%include "&si_source_path.\sasprogs\si_link_gss_addr_households.sas";

/* Create dataset for GSS household individuals with HNZ admin variables*/
%include "&si_source_path.\sasprogs\si_create_hnz_population.sas";

/* Create a GSS personal questionaire individuals dataset integrating all the required variables from household and HNZ data*/
%include "&si_source_path.\sasprogs\si_create_of_gss_ind_variables.sas";

/* Add admin data characteristics to the GSS individuals */
%si_conditional_drop_table(si_cond_table_in=sand.gss_pop_char);
%si_get_characteristics(si_char_proj_schema=&si_proj_schema., 
	si_char_table_in=of_gss_ind_variables_sh, 
	si_as_at_date=gss_pq_interview_date,
	si_char_table_out=sand.gss_pop_char);

/* Create Analysis ready dataset for unweighted treat-control analysis */
%include "&si_source_path.\sasprogs\si_create_of_gss_hnz_trtcntr_pop.sas";

/*********************************************************************************************************/





