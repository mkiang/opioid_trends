library(tidyverse)
source("./code/mk_nytimes.R")

## Config
output_dir <- config::get()$output_folder

import_jp <- function(filename) {
    df <- readr::read_delim(filename, delim = ";", escape_double =  FALSE, 
                            trim_ws = TRUE)
    names(df) <- tolower(names(df))
    names(df) <- gsub(" ", "", names(df))
    names(df) <- gsub(",", "_", names(df))
    
    return(df)
}

nonop_vs_drugs<- import_jp(
    paste0("./joinpoint_analysis/", 
           "01_opioid_rates_long/", 
           "01_opioid_rates_long.data.txt")) %>% 
    filter(race == "total", 
           opioid_type %in% c("nonopioid", "opioid")) %>% 
    ungroup()

plote1_df <- nonop_vs_drugs %>% 
    mutate(opioid_cat = factor(opioid_type, 
                              levels = c("nonopioid", "opioid"), 
                              labels = c("Non-opioid drug death", 
                                         "Opioid death"), 
                              ordered = TRUE))

plote1 <- ggplot(plote1_df, 
                 aes(x = year, group = opioid_cat, color = opioid_cat)) + 
    geom_point(aes(y = std_rate), alpha = .95) + 
    geom_errorbar(aes(ymin = std_rate - 1.96 * standarderror, 
                      ymax = std_rate + 1.96 * standarderror), 
                  width = .1, alpha = .5) + 
    geom_line(aes(y = model), alpha = .95) +
    mk_nytimes(axis.line = element_line(color = 'black', linetype = 'solid')) + 
    labs(x = NULL, y = "Age-standardized rate (per 100,000)") + 
    scale_color_brewer(NULL, palette = "Dark2") + 
    scale_x_continuous(expand = c(0, .25))

ggsave(sprintf('%s/supp_efig1_opioid_vs_non_opioid.pdf', output_dir), 
       plot = plote1, width = 6.5, height = 3.5, 
       scale = 1.15, device = cairo_pdf)
ggsave(sprintf('%s/supp_efig1_opioid_vs_non_opioid.png', output_dir), 
       plot = plote1, width = 6.5, height = 3.5, 
       scale = 1.15, dpi = 1200)
