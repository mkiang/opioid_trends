## 02_create_pop_data.R ----
##
## Tasks in this file:
##      (1) If population files do not exist yet, download them.
##      (2) Reshape and convert to 5-year age groups then save.
##
##  The end result is a dataframe with population counts for every race and
##  Hispanic origin for every county for every year 1999-2016 saved as:
##  './data/pop_est_collapsed_long.RDS'

## Imports ----
library(tidyverse)
library(here)

## Config ----
data_folder <- "raw_data"

## (1) Downloading files ----
## 1999 data
if (!file.exists(sprintf("%s/icen1999.txt.zip", data_folder))) {
    download.file(
        url = paste0(
            "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/",
            "datasets/nvss/bridgepop/icen1999.txt"
        ),
        destfile = sprintf("%s/icen1999.txt", data_folder)
    )
    
    zip(
        files = sprintf("%s/icen1999.txt", data_folder),
        zipfile = sprintf("%s/icen1999.txt.zip", data_folder)
    )
    
    file.remove(sprintf("%s/icen1999.txt", data_folder))
}

## 2000-2004 data
if (!file.exists(sprintf("%s/icen_2000_09_y0004.zip", data_folder))) {
    download.file(
        url = paste0(
            "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/",
            "datasets/nvss/bridgepop/2000_09/",
            "icen_2000_09_y0004.zip"
        ),
        destfile = sprintf("%s/icen_2000_09_y0004.zip", data_folder)
    )
}

## 2005-2009 data
if (!file.exists(sprintf("%s/icen_2000_09_y0509.zip", data_folder))) {
    download.file(
        url = paste0(
            "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/",
            "datasets/nvss/bridgepop/2000_09/",
            "icen_2000_09_y0509.zip"
        ),
        destfile = sprintf("%s/icen_2000_09_y0509.zip", data_folder)
    )
}

## 2010-2018 data (get the 2018 Vintage)
if (!file.exists(sprintf("%s/pcen_v2018_y1018.txt.zip", data_folder))) {
    download.file(
        url = paste0(
            "https://www.cdc.gov/nchs/nvss/bridged_race/",
            "pcen_v2018_y1018.txt.zip"
        ),
        destfile = sprintf("%s/pcen_v2018_y1018.txt.zip",
                           data_folder)
    )
}


## (2) Reshape population data ----
## Import population files in wide format where columns are: ----
##      fipst, fipsct, age, racesex, hispanic, pop_est_XXXX
## with XXXX being a year between 1999-2015 and age representing 5-year age
## in 0-4, 5-9, ... , 85+ groupings.
pop1999 <- read_fwf(sprintf("%s/icen1999.txt.zip", data_folder),
                    fwf_widths(
                        c(4, 2, 3, 2, 1, 1, 8),
                        c(
                            "year",
                            "fipst",
                            "fipsct",
                            "age",
                            "racesex",
                            "hispanic",
                            "pop_est_1999"
                        )
                    )) %>%
    select(-year) %>%
    ## Right now age is 0, 1-4, 5-9, etc. Collapse and make age sensible.
    mutate(age = ifelse(age > 0, (age - 1) * 5, age)) %>%
    group_by(fipst, fipsct, age, racesex, hispanic) %>%
    summarize(pop_est_1999 = sum(pop_est_1999)) %>%
    ungroup()

width_00s <- c(8, 2, 3, 2, 1, 1, 8, 8, 8, 8, 8)
pop2000s <-
    left_join(## We can left_join() here because 2000-2009 have the same FIPS
        read_fwf(
            sprintf("%s/icen_2000_09_y0004.zip", data_folder),
            fwf_widths(
                width_00s,
                c(
                    "series",
                    "fipst",
                    "fipsct",
                    "age",
                    "racesex",
                    "hispanic",
                    "pop_est_2000",
                    "pop_est_2001",
                    "pop_est_2002",
                    "pop_est_2003",
                    "pop_est_2004"
                )
            )
        ),
        read_fwf(
            sprintf("%s/icen_2000_09_y0509.zip", data_folder),
            fwf_widths(
                width_00s,
                c(
                    "series",
                    "fipst",
                    "fipsct",
                    "age",
                    "racesex",
                    "hispanic",
                    "pop_est_2005",
                    "pop_est_2006",
                    "pop_est_2007",
                    "pop_est_2008",
                    "pop_est_2009"
                )
            )
        )) %>%
    select(-series) %>%
    mutate(age = (cut(
        age,
        c(0, seq(5, 85, 5), Inf),
        include.lowest = TRUE,
        right = FALSE,
        labels = FALSE
    ) - 1) * 5) %>%
    group_by(fipst, fipsct, age, racesex, hispanic) %>%
    summarize_all(sum) %>%
    ungroup()

pop2010s <-
    read_fwf(sprintf("%s/pcen_v2018_y1018.txt.zip", data_folder),
             fwf_widths(
                 c(4, 2, 3, 2, 1, 1, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8),
                 c(
                     "series",
                     "fipst",
                     "fipsct",
                     "age",
                     "racesex",
                     "hispanic",
                     "pop_est_2010april",
                     "pop_est_2010",
                     "pop_est_2011",
                     "pop_est_2012",
                     "pop_est_2013",
                     "pop_est_2014",
                     "pop_est_2015",
                     "pop_est_2016",
                     "pop_est_2017",
                     "pop_est_2018"
                 )
             ))  %>%
    select(-series) %>%
    mutate(age = (cut(
        age,
        c(0, seq(5, 85, 5), Inf),
        include.lowest = TRUE,
        right = FALSE,
        labels = FALSE
    ) - 1) * 5) %>%
    group_by(fipst, fipsct, age, racesex, hispanic) %>%
    summarize_all(sum) %>%
    ungroup()

## Now modify each population dataframe with better race/sex/hispanic columns
## such that race and sex are separated and hispanic/female are indicators.
## Also add the IHME collapsed FIPS as a separate column.
clean_pop_data <- function(df) {
    newdf <- df %>%
        ungroup() %>%
        mutate(
            race = case_when(
                racesex %in% 1:2 ~ "white",
                racesex %in% 3:4 ~ "black",
                racesex %in% 5:6 ~ "american_indian",
                racesex %in% 7:8 ~ "asian_pacific"
            ),
            female = ifelse(racesex %% 2 == 0, 1, 0),
            hispanic = hispanic - 1,
            fipschar = paste0(fipst, fipsct) #,
            # fipsihme = stringr::str_replace_all(fipschar, fips_pattern)
        )
    return(newdf)
}

pop1999  <- clean_pop_data(pop1999)
pop2000s <- clean_pop_data(pop2000s)
pop2010s <- clean_pop_data(pop2010s)

## Now collapse over sex and the IHME FIPS codes ----
## Then combine into a single file.
collapse_df <- function(df) {
    newdf <- df %>%
        select(age, race, hispanic, starts_with("pop_est_")) %>%
        group_by(age, race, hispanic) %>%
        summarize_all(sum)
    return(newdf)
}

pop1999  <- collapse_df(pop1999)
pop2000s <- collapse_df(pop2000s)
pop2010s <- collapse_df(pop2010s)

all_pops_wide <- pop1999 %>%
    left_join(pop2000s) %>%
    left_join(pop2010s) %>%
    ungroup()

## Convert to long
all_pops_long <- all_pops_wide %>%
    ungroup() %>%
    select(-ends_with("april")) %>%
    gather(year, pop_est, pop_est_1999:pop_est_2018) %>%
    mutate(year = as.integer(gsub("pop_est_", "", year)))

## Save ----
write_csv(all_pops_long,
          here("data", "pop_est_collapsed_long.csv"))
