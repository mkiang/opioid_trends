## Imports ----
library(tidyverse)

## Pull in YAML config ----
csv_folder <- config::get()$sav_folder

## Load data ----
std_rates_long <- read_csv(sprintf("%s/age_standardized_rates_long.csv", 
                                   csv_folder))
opioid_rr      <- read_csv(sprintf('%s/opioid_rate_ratio.csv', 
                                   csv_folder))

## For joinpoint analysis 1: pioid, drug, non-opioid drug ----
jp1_data <- std_rates_long %>% 
    filter(opioid_type %in% c("drug", "opioid", "nonopioid")) %>% 
    mutate(sd = sqrt(var)) %>% 
    arrange(opioid_type, race, year)

write.csv(jp1_data %>% select(-var), row.names = FALSE, 
          file = "./joinpoint_analysis/01_opioid_rates_long.csv")

## For joinpoint analysis 2: rate ratio ----
##  Already in the right shape, just need to save to new location
write.csv(opioid_rr %>% select(-var), row.names = FALSE, 
          file = "./joinpoint_analysis/02_opioid_rate_ratio.csv")
    
## For joinpoint analysis 3: heroin, methadone, other ----
##  NOTE: Joinpoint doesn't work if the rate is zero or the standard 
##  deviation is zero. There is one observation (black, 1993, methadone)
##  where we set it to arbitrarily small positive values.
opioids_by_type <- std_rates_long %>% 
    filter(opioid_type %in% c("heroin", "methadone", "nonh_nonm")) %>% 
    arrange(opioid_type, race, year) %>% 
    mutate(std_rate = ifelse(std_rate == 0, .0001, std_rate), 
           var      = ifelse(var == 0, .000001, var), 
           sd       = sqrt(var))

options(scipen = 10)    ## Or else it writes one row using scientific notation
write.csv(opioids_by_type %>% select(-var), row.names = FALSE, 
          file = "./joinpoint_analysis/03_opioid_rates_by_type.csv")

## For joinpoint analysis 4: ICD10 years by all types ----
opioids_type_icd10 <- std_rates_long %>% 
    filter(year >= 1999, 
           !(opioid_type %in% c("opium", "unspec_op"))) %>% 
    arrange(opioid_type, race, year) %>% 
    mutate(sd = sqrt(var))

write.csv(opioids_type_icd10 %>% select(-var), row.names = FALSE, 
          file = "./joinpoint_analysis/04_opioid_rates_icd10type.csv")
