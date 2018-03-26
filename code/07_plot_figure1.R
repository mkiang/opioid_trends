## Plot figure 1, rates for opioids by race, 1979-2015 and rate ratio

## Imports
library(tidyverse)
library(patchwork)  # devtools::install_github("thomasp85/patchwork")
source("./code/mk_nytimes.R")

## Config
output_dir <- config::get()$output_folder
narcan::mkdir_p(output_dir)

## Helper function
import_results_data <- function(filename) {
    df <- readr::read_delim(filename, delim = ";", escape_double =  FALSE, 
                            trim_ws = TRUE)
    names(df) <- tolower(names(df))
    names(df) <- gsub(" ", "", names(df))
    names(df) <- gsub(",", "_", names(df))
    
    return(df)
}

## Import joinpoint data
opioid_rates_jp <- import_results_data(
    paste0("./joinpoint_analysis/", 
           "01_opioid_rates_long/", 
           "01_opioid_rates_long.data.txt"))

opioid_rr_jp <- import_results_data(
    paste0("./joinpoint_analysis/", 
           "02_opioid_rate_ratio/", 
           "02_opioid_rate_ratio.data.txt"))

plot1a_df <- opioid_rates_jp %>% 
    filter(opioid_type == "opioid") %>% 
    ungroup() %>% 
    mutate(race_cat = factor(race, 
                             levels = c("total", "white", "black"), 
                             labels = c("Total", "White", "Black"), 
                             ordered = TRUE))

## Top figure
plot1a <- ggplot(plot1a_df, 
                 aes(x = year, group = race_cat, 
                     shape = race_cat)) + 
    geom_line(aes(y = model, color = race_cat), alpha = .95) + 
    geom_errorbar(aes(ymin = std_rate - 1.96 * standarderror, 
                      ymax = std_rate + 1.96 * standarderror, color = race_cat), 
                  width = .15, alpha = .9) + 
#    geom_point(aes(y = std_rate), color = "white", size = 2.5) + 
    geom_point(aes(y = std_rate, color = race_cat), alpha = .9, size = 1.75) + 
    mk_nytimes() + 
    labs(x = NULL, y = "Rate (per 100,000)") + 
    scale_color_brewer(NULL, palette = "Set1") + 
    scale_shape_ordinal(NULL) + 
    theme(legend.position = c(.01, .99), 
          legend.justification = c(0, 1)) + 
    scale_x_continuous(expand = c(0, .25)) + 
    scale_y_continuous(limits = c(0, 15.5), expand = c(0, 0))

## Bottom figure
plot1b <- ggplot(opioid_rr_jp, aes(x = year)) + 
    geom_errorbar(aes(ymin = opioid_rr * exp(-1.96 * standarderror), 
                      ymax = opioid_rr * exp(1.96 * standarderror)), 
                  width = .15, alpha = .9) + 
    geom_line(aes(y = model), alpha = .95) +
#    geom_point(aes(y = opioid_rr), color = "white", size = 2.5) + 
    geom_point(aes(y = opioid_rr), alpha = .95, size = 1.75) + 
    mk_nytimes() + 
    labs(x = NULL, y = "Rate ratio") + 
    theme(legend.position = c(.01, .99), 
          legend.justification = c(0, 1)) + 
    scale_y_log10(breaks = c(.5, 1, 2)) + 
    scale_x_continuous(expand = c(0, .25))

## Save
ggsave(sprintf("%s/fig1_rate_and_ratio.pdf", output_dir),
       plot = plot1a + plot1b + plot_layout(ncol = 1, heights = c(3, 1)), 
       width = 8.5, units = "cm", height = 5, scale = 2, device = cairo_pdf)
ggsave(sprintf("%s/fig1_rate_and_ratio.png", output_dir),
       plot = plot1a + plot1b + plot_layout(ncol = 1, heights = c(3, 1)), 
       width = 8.5, units = "cm", height = 5, scale = 2, dpi = 300)
