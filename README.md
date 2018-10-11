# social-housing-and-wellbeing

An analysis on the effect of social housing on overall well-being of individuals using a combination of GSS Survey and IDI Administrative data.


## Overview
This analysis is meant to be a proof of concept for the application of Social Investment Agency’s (SIA’s) wellbeing measurement approach to an actual policy issue of interest, which we have chosen to be State Social Housing. 

The analysis uses the General Social Survey data in the IDI, combined with administrative data to look at how placement in social housing impacts on the well-being of people. The method adopted in this paper (and code) aims to move beyond a simple descriptive approach, to instead identify the difference in wellbeing outcomes for people before and after being placed in social housing. This is still not as good an estimate of the true causal impact of social housing as a genuine experimental evaluation, but by providing a dynamic picture of the change in wellbeing outcomes associated with a social housing transition, it significantly enriches the available evidence base. The project aims to provide four important pieces of information to assess the impact of social housing interventions. These are:

	* What impact does being placed in social housing have on housing outcomes (i.e. the quality of accommodation for social housing recipients – household crowding, temperature of residence, dampness, and the physical state of the house)?
	* What impact does being placed in social housing have on other outcome domains important to the recipient’s wellbeing (e.g. health, social contact, jobs)?
	* What is the impact of placement in social housing on the recipient’s overall wellbeing?
	* How should we value the gain in recipient’s wellbeing for the purposes of cost-benefit analysis?

Beyond this, there are two additional objectives relating to the methodology used. These are:
	* Can linked administrative and survey data be used in the IDI to identify the wellbeing outcomes of people before and after a social policy intervention?
	* What are the key lessons for using the IDI to assess the impact of policy in wellbeing terms?

For the full report on the analysis, refer to [[https://sia.govt.nz/]].


## Dependencies
* It is necessary to have an IDI project if you wish to run the code. Visit the Stats NZ website for more information about this.
* Code dependencies are captured via submodules in this repository. You will find the submodules in the `lib` folder of this repository. To ensure you clone the submodules as well, use `git clone --recursive https://github.com/nz-social-investment-agency/vulnerable_mothers.git`. Regular cloning or downloading of the zip file will result in all the `lib` subfolders being empty. Currently the code dependencies for the vulnerable mothers repository are -
	* `social_investment_analytical_layer (SIAL)` 
	* `social_investment_data_foundation (SIDF)` 
	* `SIAtoolbox`

* Once the repository is downloaded and put into your IDI project folder, run the `social_investment_analytical_layer` scripts so that the all the SIAL tables are available for use in your database schema. We strongly recommended using the version in the submodule. Note when you create the SIAL tables the scripts will attempt to access to the following schemas in IDI_Clean (or the archives if you wish to use an older IDI refresh). 
	* acc_clean
	* cor_clean
	* cyf_clean
	* data
	* dia_clean
	* hnz_clean
	* moe_clean
	* moh_clean
	* moj_clean
	* msd_clean
    * pol_clean
	* security
* If there are specific schemas listed above that you don't have access to, the **SIAL** main script (after it finishes running) will give you a detailed report on which SIAL tables were not created and why.
* Ensure that you have installed the `SIAtoolbox` library in R. Note that `SIAtoolbox` is not on the CRAN repository, and can be retrieved only from Github. Place this code in a folder in your IDI project, make sure you have the `devtools` package installed and loaded in R and then run `devtools::install("/path/to/file/SIAtoolbox")` in R.

## Folder descriptions
This folder contains all the code necessary to build characteristics and service metrics. Code is also given to create an outcome variable (highest qualification) for use and as an example of how the more complex variables are created and added to the main dataset.

**include:** This folder contains generic formatting scripts.
**lib:** This folder is used to refer to reusable code that belongs to other repositories
**sasautos:** This folder contains SAS macros. All scripts in here will be loaded into the SAS environment during the running of setup in the main script.
**sasprogs:** This folder contains SAS programs. The main script that builds the dataset is located in here as well as the control file that needs to be populated with parameters for your analysis. 
**sql:** This folder contains sql scripts to query the database.
**rprogs:** This folder contains all the necessary R scripts that are required to perform the analysis on the dataset created by the SAS code.
**output:** This folder contains all the outputs generated from the analysis. 

## Instructions to run the social-housing-and-wellbeing project
### Step A: Create analysis population and variables
1. Start a new SAS session
2. Open `sasprogs/si_control.sas`. Go to the yellow datalines and update any of the parameters that need changing. The one that is most likely to change if you are outside the SIA is the `si_proj_schema`. In case the IDI version that you're pointing to needs to be updated, edit the corresponding variables as well. Note that the results in this paper are based on IDI_Clean_20171020. If you have made changes save and close the file.
3. Open `sasprogs/si_main.sas` and change the ``si_source_path` variable to your project folder directory. Once this is done, run the `si_main.sas` script, which will build the datasets that are needed to do the analysis.

### Step B: Data Preparation & Analysis
1. Open up `rprogs/1_of_weighted_gss_analysis_wrapper.R`. This is a wrapper script that runs all steps involved for generating the weighted descriptive statistics for the analysis. The script performs a linking of the GSS survey data with the IDI Spine, and reweights the survey to account for records that are unlinked with the IDI Spine. A comparison test between the distribution of the GSS variables is also performed pre and post-reweighting. This is to ensure that the IDI Spine linkage and the subsequent and re-weighting procedure does not bias the variables that is to be compared. The outputs of this operation can be obtained from the `output` folder. 

2. Open up `rprogs/1_run_analysis_treat_control.R`. This script creates loads up all required libraries and generates all the Before-After analysis results. This analysis does not take into account the survey weights, and compares the group that was housed 12 months before GSS interview to the group housed 15 months after. Bootstrap sampling is used to get confidence intervals around the estimates here. In addition to the main analysis, this code also performs a validation, by comparing the group that was housed 12 months before GSS interview to the group housed 12 months after, and another validation using propensity matched groups.  Additionally, this code also performs regression models for the outcome variables of interest. The outputs of this analysis can be obtained from the `output` folder. 

3. Open up `rprogs/shiny_house.Rmd`. This is a markdown script that checks for the "shiny house" effect i.e., controlling for the short-term effects of moving into a brand new house. Running this file creates a markdown report in the `output` folder.

## Getting Help
If you have any questions email info@sia.govt.nz Tracking number: XXX-XXXX-XXXX

