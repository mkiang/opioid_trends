## Just a simple script that calls the files in ./code/ to run through
## Step 1 (downloading data, munging, and calculating rates).

source('./code/01_download_and_trim_raw_data.R')

source('./code/02_process_trimmed_data.R')

source('./code/03_flag_opioid_deaths.R')

source('./code/04_calculate_mortality_rates.R')

source('./code/05_calculate_opioid_rate_ratio.R')

source('./code/06_prepping_data_for_joinpoint.R')
