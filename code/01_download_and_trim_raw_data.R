## This script downloads and trims (subsets to columns we want) the raw
## multiple cause of death data. Then removes the raw (untrimmed) datasets 
## if specified in the config file.
## 
## 
## Please note the data use restrictions outlined on the CDC Wonder Website:
##  https://wonder.cdc.gov/datause.html

## Load libraries ----
library(tidyverse)
library(narcan)

## Pull in YAML config ----
cfig <- config::get(config = "dev")

## Define parameters ---- 
raw_folder <- cfig$raw_folder
year_0     <- cfig$start_year
year_n     <- cfig$end_year
del_zip    <- cfig$delete_zip_orig
paral_proc <- cfig$proc_in_parallel

## Load `parallel` package if necessary ----
if (paral_proc) {
    library(foreach) 
}

## Make directories ----
narcan::mkdir_p(raw_folder)

## Make helpers ----
## The NBER files have a weird parsing issue so for ICD-9 years, download
## the dta file and for ICD-10 years, download the csv file.
download_mcod_wrapper <- function(year, download_dir) {
    if (year >= 1979 & year <= 1998) {
        narcan::download_mcod_dta(year, download_dir = download_dir)
    } else if (year >= 1999 & year <= 2017) {
        narcan::download_mcod_csv(year, download_dir = download_dir)
    } else {
        
    }
}

## Make a corresponding helper that uses haven::read_dta() for ICD-9 and
## readr::read_csv() for ICD-10
load_mcod_wrapper <- function(year, download_dir) {
    if (year >= 1979 & year <= 1998) {
        fname <- sprintf("%s/mort%s.dta.zip", download_dir, year)
        df    <- haven::read_dta(fname) %>% 
                     narcan::zap_dta_data(dta_df = .)
    } else if (year >= 1999 & year <= 2017) {
        fname <- sprintf("%s/mort%s.csv.zip", download_dir, year)
        df    <- readr::read_csv(fname)
    ## NBER public version of 2018 is not up yet so use restricted version for now
    } else if (year == 2018) {
        df <- narcan:::.import_restricted_data("./data_private/Mort2018US.AllCnty.txt", year)
    }
    return(df %>% dplyr::mutate(year = year))
}

## Get MCOD data and trim it ----
## Downloads the zipped dta file, unzips, imports using haven::read_dta
## or readr::read_csv as approriate. 1979 to 1998 are downloaded as dta while
## 1999+ files are downloaded as csv.
## 
## We then subsets to columns we care about and save the file as an RDS.
## 
## NOTE: We use the looper functions so we can do this quickly via parallel or
## sequentially as specified in the YAML file. Doing this part in parallel is
## non-trivial. Each thread will take ~ 4GB of RAM. Make sure you either have
## enough RAM or lower the number of threads accordingly.
download_looper <- function(raw_folder, year) {
    ## Make sure the RDS doesn't already exist
    if (!file.exists(sprintf('%s/trimmed_mcod_%s.RDS', raw_folder, year))) {
        
        ## Make sure zipped dta or csv don't already exist, if not 
        ## download and process
        if (!file.exists(sprintf('%s/mort%s.dta.zip', raw_folder, year)) & 
            !file.exists(sprintf('%s/mort%s.csv.zip', raw_folder, year))) {
            download_mcod_wrapper(year, download_dir = raw_folder)
        } 
        
        ## However, if zipped dta already exists, just process
        temp_df <- load_mcod_wrapper(year, download_dir = raw_folder)
        
        ## Subset to columns we want
        temp_df <- temp_df %>% 
            dplyr::select(dplyr::one_of(c("year", "race", "hspanicr", 
                                          "ager27", "restatus", "ucod")),
                          dplyr::starts_with("record_"), 
                          dplyr::starts_with("rnifla"))
        
        ## Write it out -- some years have odd integer formats that gives
        ## write.csv() and write_csv() issues so just save as an RDS.
        saveRDS(temp_df, 
                file = sprintf('%s/trimmed_mcod_%s.RDS', raw_folder, year))
        
        rm(temp_df); gc()
        
        if (del_zip) {
            file.remove(sprintf('%s/mort%s.%s.zip', raw_folder, year, 
                                ifelse(year <= 1998, "dta", "csv")))
        }
        return(year)
    }
}

if (paral_proc) {
    ## Set up a parallel backend ----
    doParallel::registerDoParallel()
    
    ## Then call `foreach()` ----
    foreach(year = year_0:year_n, .combine = c, .inorder = FALSE) %dopar% 
        (download_looper(raw_folder = raw_folder, year = year))
} else {
    for (year in year_0:year_n) {
        download_looper(raw_folder = raw_folder, year = year)
    }
}
