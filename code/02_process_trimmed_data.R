## Imports ----
library(tidyverse)
library(narcan)

## Pull in YAML config ----
cfig <- config::get()

## Define parameters ---- 
raw_folder <- cfig$raw_folder
sav_folder <- cfig$sav_folder
year_0     <- cfig$start_year
year_n     <- cfig$end_year
del_trim   <- cfig$delete_trimmed
paral_proc <- cfig$proc_in_parallel

## Load parallel package if necessary ----
if (paral_proc) {
    library(foreach)
}

## Make a folder to save to ----
narcan::mkdir_p(sav_folder)

## Processing trimmed files ----
## Loop through all years, process the files, save them, then delete trimmed
## originals if specified.
## Only loop through if we didn't already create a processed file.
process_looper <- function(csv_folder, year) {
    if (!file.exists(sprintf("%s/cleaned_mcod_%s.RDS", sav_folder, year))) {
        ## Load data
        temp_df <- readRDS(sprintf('%s/trimmed_mcod_%s.RDS', raw_folder, year))
        
        ## Drop nonresidents
        temp_df <- narcan::subset_residents(temp_df)
        
        ## Do ICD-9-specific data munging
        if (year <= 1998) {
            temp_df <- narcan::clean_icd9_data(temp_df)
        } 
        
        ## Unite all 20 contributory cause columns
        temp_df <- narcan::unite_records(temp_df)
        
        ## Convert age, add hspanicr, remap race, and add categories
        temp_df <- temp_df %>% 
            narcan::convert_ager27(.) %>% 
            narcan::add_hspanicr_column(.) %>% 
            narcan::remap_race(.) %>% 
            dplyr::mutate(race_cat = narcan::categorize_race(race), 
                          hsp_cat  = narcan::categorize_hspanicr(hspanicr), 
                          age_cat  = narcan::categorize_age_5(age))
        
        ## Reorder columns
        temp_df <- temp_df %>% 
            dplyr::select(year, race, race_cat, hspanicr, hsp_cat, 
                          age, age_cat, ucod, f_records_all)
        
        ## Save as RDS because readr::write_csv is giving me weird parsing issues
        ## when saving as a compressed csv.
        saveRDS(temp_df, sprintf("%s/cleaned_mcod_%s.RDS", sav_folder, year))
        
        ## Delete trimmed files
        if (del_trim) {
            file.remove(sprintf('%s/trimmed_mcod_%s.RDS', raw_folder, year))
        }
        
        ## Clean up
        rm(temp_df); gc()
        
        return(year)
    }
}

if (paral_proc) {
    ## Set up a parallel backend ----
    doParallel::registerDoParallel()
    getDoParWorkers()   ## Check the number of workers you're using
    
    ## Then call `foreach()` ----
    foreach(year = year_0:year_n, .combine = c, .inorder = FALSE) %dopar% 
        (process_looper(csv_folder = csv_folder, year = year))
} else {
    for (year in year_0:year_n) {
        process_looper(csv_folder = csv_folder, year = year)
    }
}
