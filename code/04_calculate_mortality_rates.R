## Calculate opioid rates ----
## Imports ----
library(tidyverse)
library(narcan)

## Pull in YAML config ----
csv_folder <- config::get()$sav_folder

## Get data ----
all_data <- read.csv(sprintf('%s/working_opioid_data.csv', csv_folder), 
                     stringsAsFactors = FALSE) %>% 
    dplyr::mutate(age_cat = narcan::categorize_age_5(age)) %>% 
    dplyr::select(-sex) %>% 
    as_tibble()

## Calculate age-specific rates ----
## We just use purrr to loop through the columns we are interested in

## Define column bases (for new column names) and current columns
c_base <- c("opioid", "drug", "nonopioid", "opium", "heroin", 
             "natural", "methadone", "synth", "other_op", "unspec_op", 
             "nonh_nonm")
c_name <- c("opioid_d", "drug_d", "nonop_drug_d", "had_opium", "had_heroin", 
            "had_natural", "had_methadone", "had_synth", "had_other_op", 
            "had_unspec_op", "had_nonh_nonm")

## Loop through and calculate the age-specific rates for each
age_spec_rates <- purrr::map2(.x = c_base, 
                              .y = c_name, 
                              .f = ~ narcan::calc_asrate_var(all_data, 
                                                             !!rlang::sym(.x), 
                                                             !!rlang::sym(.y))) %>% 
    dplyr::bind_cols() %>% 
    dplyr::ungroup() %>% 
    dplyr::select(year = `year...1`, 
                  age = `age...2`, 
                  age_cat = `age_cat...3`,
                  race  = `race...16`,
                  pop = `pop...17`,
                  pop_std = `pop_std...18`, 
                  unit_w = `unit_w...19`, 
                  dplyr::ends_with("_rate"), 
                  dplyr::ends_with("_var")) %>% 
    dplyr::mutate_at(dplyr::vars(dplyr::ends_with("_rate"), 
                                 dplyr::ends_with("_var")), 
                     coalesce, 0)

write.csv(age_spec_rates, sprintf("%s/age_specific_rates.csv", csv_folder), 
          row.names = FALSE)

## Calculate age-standardized rates ----
age_std_wide <- 
    purrr::map(.x = c_base, 
               .f = ~ narcan::calc_stdrate_var(age_spec_rates,
                                               !!rlang::sym(paste0(.x, "_rate")), 
                                               !!rlang::sym(paste0(.x, "_var")), 
                                               year, race)) %>% 
    dplyr::bind_cols() %>% 
    dplyr::ungroup() %>% 
    dplyr::select(year = `year...1`,
                  race = `race...2`, 
                  dplyr::ends_with("_rate"), 
                  dplyr::ends_with("_var")) %>% 
    dplyr::arrange(race, year)

write.csv(age_std_wide, 
          sprintf("%s/age_standardized_rates_wide.csv", csv_folder), 
          row.names = FALSE)

## Now convert to long format
age_std_long <- age_std_wide %>% 
    dplyr::select(year, race, ends_with("rate")) %>% 
    tidyr::gather(opioid_type, std_rate, opioid_rate:nonh_nonm_rate) %>% 
    dplyr::mutate(opioid_type = gsub("_rate", "", opioid_type)) %>% 
    dplyr::left_join(
        age_std_wide %>% 
            dplyr::select(year, race, ends_with("var")) %>% 
            tidyr::gather(opioid_type, var, opioid_var:nonh_nonm_var) %>% 
            dplyr::mutate(opioid_type = gsub("_var", "", opioid_type))
    )

write.csv(age_std_long, 
          sprintf("%s/age_standardized_rates_long.csv", csv_folder), 
          row.names = FALSE)
