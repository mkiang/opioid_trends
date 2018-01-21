## Opioid relative rate with variance calculation ----
## Imports ----
library(tidyverse)

## Pull in YAML config ----
csv_folder <- config::get()$sav_folder

## Get data ----
all_data <- read.csv(sprintf('%s/working_opioid_data.csv', csv_folder), 
                     stringsAsFactors = FALSE) %>% 
    dplyr::mutate(age_cat = narcan::categorize_age_5(age)) %>% 
    dplyr::select(-sex)

## Age-specific rates for opioid deaths ----
## From Flanders, 1984 Eq. 5, we need:
##      (w_i/t_i)^2 x_i
## For both black and whites where:
##      i is age group, w is weight, t is person-years, and x is cases
## 
## Let's do it long first and call it opioid_wtx
opioid_age_spec <- all_data %>% 
    mutate(
        asmr_opioid = opioid_d / pop,
        opioid_wtx  = (unit_w / pop)^2 * opioid_d
    )

## Age standardized rates for opioid deaths ----
## From Flanders, 1984 Eq. 5, we need:
##      the sum of opioid_wtx  
##      the age standradized rates
## Additionally, we need the inverse of the standardized rate, squared:
##      (1/std_rate)^2 * \sum{(w_i/t_i)^2 x_i} for blacks and whites
opioid_age_std <- opioid_age_spec %>% 
    group_by(year, race) %>% 
    summarise(
        dras_opioid  = weighted.mean(asmr_opioid, unit_w),
        opioid_wtx = sum(opioid_wtx)) %>% 
    ungroup() %>% 
    mutate(inv_rate_wtx = (1/dras_opioid)^2 * opioid_wtx)

## Now lets go from long to wide
opioid_age_std_wide <- opioid_age_std %>% 
    filter(race == "black") %>% 
    select(year, 
           std_rate_black = dras_opioid, 
           inv_rate_wtx_black = inv_rate_wtx) %>% 
    left_join(
        opioid_age_std %>% 
            filter(race == "white") %>% 
            select(year, 
                   std_rate_white = dras_opioid, 
                   inv_rate_wtx_white = inv_rate_wtx)
    )

## Calculate RR
opioid_rr <- opioid_age_std_wide %>% 
    mutate(
        opioid_rr = std_rate_white / std_rate_black, 
        opioid_rr_var = opioid_rr^2 * (inv_rate_wtx_white + inv_rate_wtx_black), 
        opioid_rr_sd  = sqrt(opioid_rr_var)) %>% 
    select(year, opioid_rr, opioid_rr_var, opioid_rr_sd)

## Save it 
write.csv(opioid_rr, 
          file = sprintf('%s/opioid_rate_ratio.csv', csv_folder), 
          row.names = FALSE)
