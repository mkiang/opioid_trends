## Plot figure 2, rates for opioids by race and opioid type, 1979-2015

## Imports
library(tidyverse)
source("./code/mk_nytimes.R")

output_dir <- config::get()$output_folder

## Helper functions
import_results_data <- function(filename) {
    df <- readr::read_delim(filename, delim = ";", escape_double =  FALSE, 
                            trim_ws = TRUE)
    names(df) <- tolower(names(df))
    names(df) <- gsub(" ", "", names(df))
    names(df) <- gsub(",", "_", names(df))
    
    return(df)
}

## Import data
opioid_types_jp <- import_results_data(
    paste0("./joinpoint_analysis/", 
           "03_opioid_rates_by_type/", 
           "03_opioid_rates_by_type.data.txt"))

plot2_df <- opioid_types_jp %>% 
    filter(race != "total") %>% 
    ungroup() %>% 
    mutate(race_cat = factor(race, 
                             levels = c("total", "white", "black"), 
                             labels = c("Total", "White", "Black"), 
                             ordered = TRUE), 
           opioid_cat = factor(opioid_type, 
                               levels = c("heroin", "methadone", "nonh_nonm"), 
                               labels = c("Heroin", "Methadone", "Other"), 
                               ordered = TRUE))

plot2 <- ggplot(plot2_df, 
                aes(x = year, group = opioid_cat, 
                    color = opioid_cat, shape = opioid_cat)) + 
    geom_errorbar(aes(ymin = std_rate - 1.96 * standarderror, 
                      ymax = std_rate + 1.96 * standarderror), 
                  width = .1, alpha = .5) + 
    geom_line(aes(y = model), alpha = .95) +
    geom_point(aes(y = std_rate), alpha = .95, size = 1) + 
    mk_nytimes(axis.line = element_line(color = 'black', linetype = 'solid')) + 
    labs(x = NULL, y = "Rate (per 100,000)") + 
    scale_color_brewer(NULL, palette = "Dark2") + 
    scale_shape_ordinal(NULL) + 
    theme(legend.position = c(0, .99), 
          legend.justification = c(0, 1)) + 
    facet_grid(race_cat ~ .) + 
    scale_x_continuous(expand = c(0, .25))

ggsave(sprintf('%s/fig2_opioid_types.pdf', output_dir), plot2, 
       width = 8.5, height = 5, units = "cm", scale = 2, 
       device = cairo_pdf)
ggsave(sprintf('%s/fig2_opioid_types.png', output_dir), plot2, 
       width = 8.5, height = 5, units = "cm", scale = 2, 
       dpi = 1200)
