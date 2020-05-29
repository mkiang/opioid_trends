## Imports ----
library(tidyverse)
library(narcan)
library(here)

## DELETE THIS ----
Sys.setenv(R_CONFIG_ACTIVE = "dev")

## Pull in YAML config ----
cfig <- config::get()

## Define parameters ---- 
csv_folder <- cfig$sav_folder
year_0     <- cfig$start_year
year_n     <- cfig$end_year
paral_proc <- cfig$proc_in_parallel
del_clean  <- cfig$delete_cleaned

pop_df <- read_csv(here("data", "pop_est_collapsed_long.csv"))

## Load parallel package if necessary ----
if (paral_proc) {
    library(foreach)
}

## Looper function ----
## We make a looper functions so we can do this sequentially or in parallel
## as specified by the config file.
calculation_looper <- function(csv_folder, year) {
    print(year)
    
    ## Load ----
    temp_df <- readRDS(sprintf("%s/cleaned_mcod_%s.RDS", csv_folder, year))
    
    ## Flag the deaths ----
    ##  Flag all drug deaths, opioid deaths, drug deaths that are not
    ##  opioid deaths, then by type. Lastly, flag deaths that involved 
    ##  something other than (but could also include) heroin or methadone.
    processed_df <- temp_df %>% 
        narcan::flag_drug_deaths(., year = year) %>% 
        narcan::flag_opioid_deaths(., year = year) %>% 
        narcan::flag_nonopioid_drug_deaths(.) %>% 
        narcan::flag_opioid_types(., year = year) %>% 
        dplyr::mutate(nonh_nonm = case_when(
            (opium_present + other_natural_present + other_synth_present + 
                 other_op_present + unspecified_op_present) > 0 & 
                opioid_death == 1 ~ 1, 
            TRUE ~ 0)) %>% 
        select(-ucod, -f_records_all)
    
    ## All race/ethnicity ----
    all_races <- processed_df %>% 
        dplyr::select(-race, -race_cat, -hspanicr, -hsp_cat) %>% 
        narcan::summarize_binary_columns() %>% 
        dplyr::mutate(race_ethnicity = "total") %>% 
        dplyr::ungroup()
    
    ## All white and black (regardless of hispanic origin) ----
    white_black_all <-  processed_df %>% 
        dplyr::select(-race, -hspanicr, -hsp_cat) %>%  
        dplyr::filter(race_cat %in% c("white", "black")) %>% 
        narcan::summarize_binary_columns(race_cat) %>% 
        dplyr::mutate(race_ethnicity = ifelse(race_cat == "white", 
                                       "white", 
                                       "black")) %>% 
        dplyr::select(-race_cat)  %>% 
        dplyr::ungroup()
    
    ## All others (regardless of hispanic origin) ----
    other_all <- processed_df %>% 
        dplyr::filter(!(race_cat %in% c("white", "black"))) %>% 
        dplyr::select(-race_cat, -race, -hspanicr, -hsp_cat) %>% 
        narcan::summarize_binary_columns() %>% 
        dplyr::mutate(race_ethnicity = "other") %>% 
        dplyr::ungroup()
    
    ## nonhispanic white and nonhispanic black ----
    white_black_nh <- processed_df %>% 
        dplyr::filter(hsp_cat %in% c("nonhispanic_white", 
                                     "nonhispanic_black")) %>% 
        dplyr::select(-race, -race_cat, -hspanicr) %>% 
        narcan::summarize_binary_columns(hsp_cat) %>% 
        dplyr::mutate(race_ethnicity = ifelse(hsp_cat == "nonhispanic_white", 
                                       "nhw", 
                                       "nhb")) %>% 
        dplyr::select(-hsp_cat) %>% 
        dplyr::ungroup()
    
    ## all hispanic ----
    all_hispanic <- processed_df %>%
        dplyr::filter(
            hsp_cat %in% c(
                "other_hispanic",
                "puerto_rican",
                "mexican",
                "cuban",
                "central_south_america"
            )
        ) %>%
        dplyr::select(-race, -race_cat, -hspanicr, -hsp_cat) %>%
        narcan::summarize_binary_columns() %>% 
        dplyr::mutate(race_ethnicity = "all_hispanic") %>%
        dplyr::ungroup()
    
    ## American Indian ----
    american_indian <- processed_df %>%
        dplyr::filter(race_cat %in% c("american_indian") &
                          hsp_cat %in% c("nonhispanic_other")) %>%
        dplyr::select(-race, -race_cat, -hspanicr, -hsp_cat) %>%
        narcan::summarize_binary_columns() %>% 
        dplyr::mutate(race_ethnicity = "nh_american_indian") %>%
        dplyr::ungroup()
    
    ## Combine dataframes ----
    opioid_data <-
        rbind(all_races,
              other_all,
              white_black_all,
              white_black_nh,
              all_hispanic,
              american_indian) %>% 
        select(race_ethnicity, everything())
    
    ## Return ----
    return(opioid_data)
}

## Loop through data ----
## Just loop, perform calculations per year, combine the aggregated data.
if (paral_proc) {
    doParallel::registerDoParallel()
    
    opioid_data <- foreach(year = year_0:year_n, 
                           .combine = rbind, 
                           .inorder = FALSE) %dopar% 
        (calculation_looper(csv_folder = csv_folder, year = year))
} else {
    opioid_data <- NULL
    for (year in year_0:year_n) {
        temp_df <- calculation_looper(csv_folder = csv_folder, year = year)
        opioid_data <- rbind(opioid_data, temp_df)
        
        rm(temp_df); gc()
    }
}

opioid_data <- opioid_data %>% 
    arrange(race_ethnicity, year, age_cat) %>% 
    filter(!is.na(age))

## Reshape population data to match the opioid race/ethnicity groups ----
total_pop <- pop_df %>% 
    group_by(age, year) %>% 
    summarize(pop = sum(pop_est)) %>% 
    mutate(race_ethnicity = "total") %>% 
    ungroup()

white_black_all_pop <- pop_df %>%
    filter(race %in% c("white", "black")) %>% 
    group_by(age, race, year) %>% 
    summarize(pop = sum(pop_est)) %>%
    ungroup() %>% 
    mutate(race_ethnicity = ifelse(race == "white", "white", "black")) %>%
    select(-race)

other_all_pop <- pop_df %>%
    filter(!(race %in% c("white", "black"))) %>%
    group_by(age, year) %>%
    summarize(pop = sum(pop_est)) %>%
    ungroup() %>%
    mutate(race_ethnicity = "other") 

black_white_nh_pop <- pop_df %>% 
    filter(race %in% c("white", "black"),
           hispanic == 0)  %>% 
    group_by(age, race, year) %>% 
    summarize(pop = sum(pop_est)) %>%
    ungroup() %>% 
    mutate(race_ethnicity = ifelse(race == "white", "nhw", "nhb")) %>%
    select(-race)

all_hispanic_pop <- pop_df %>% 
    filter(hispanic == 1) %>% 
    group_by(age, year) %>% 
    summarize(pop = sum(pop_est)) %>% 
    ungroup() %>% 
    mutate(race_ethnicity = "all_hispanic") 

american_indian_nh_pop <- pop_df %>% 
    filter(race %in% c("american_indian"),
           hispanic == 0) %>% 
    group_by(age, year) %>% 
    summarize(pop = sum(pop_est)) %>% 
    ungroup() %>% 
    mutate(race_ethnicity = "nh_american_indian")

all_pops <- bind_rows(
    total_pop,
    white_black_all_pop,
    other_all_pop,
    black_white_nh_pop,
    all_hispanic_pop,
    american_indian_nh_pop
) %>% 
    select(race_ethnicity, everything())

## To get working data: 
##  (1) subset to columns we'll need for analysis, 
##  (2) add sex column (just to match with population data)
##  (3) add population counts,  
##  (4) add standard population, and
##  (5) filter out rows with missing age and subset to total/white/black

working_data <- opioid_data %>%
    select(
        race_ethnicity, 
        year,
        age,
        age_cat,
        total_d = deaths,
        opioid_d = opioid_death,
        drug_d = drug_death,
        nonop_drug_d = nonop_drug_death,
        had_opium = opium_present,
        had_heroin = heroin_present,
        had_natural = other_natural_present,
        had_methadone = methadone_present,
        had_synth = other_synth_present,
        had_other_op = other_op_present,
        had_unspec_op = unspecified_op_present,
        had_nonh_nonm = nonh_nonm
    ) %>% 
    left_join(all_pops) %>% 
    narcan::add_std_pop(.) 

write.csv(working_data, sprintf('%s/working_opioid_data.csv', csv_folder), 
          row.names = FALSE)
