## Config
output_dir <- config::get()$output_folder

## Render the files
rmarkdown::render('./rmds/supp_etable1a_opioid_total_pop.Rmd', 
                  knit_root_dir = "../")
rmarkdown::render('./rmds/supp_etable1b_nonopioid_total_pop.Rmd', 
                  knit_root_dir = "../")
rmarkdown::render('./rmds/supp_etable3_opioids_white.Rmd', 
                  knit_root_dir = "../")
rmarkdown::render('./rmds/supp_etable4_opioids_black.Rmd', 
                  knit_root_dir = "../")
rmarkdown::render('./rmds/supp_etable5_by_broad_type_white.Rmd', 
                  knit_root_dir = "../")
rmarkdown::render('./rmds/supp_etable6_by_broad_type_black.Rmd', 
                  knit_root_dir = "../")
rmarkdown::render('./rmds/supp_etable7_icd10type_white.Rmd', 
                  knit_root_dir = "../")
rmarkdown::render('./rmds/supp_etable8_icd10type_black.Rmd', 
                  knit_root_dir = "../")
rmarkdown::render('./rmds/supp_etable9_rate_ratio.Rmd', 
                  knit_root_dir = "../")

## Move them to the output folder: the knitr options seem to break 
## config() within the rmd files so just doing it manually.
doc_files <- list.files('./rmds', pattern = "\\.docx", full.names = TRUE)
file.rename(doc_files, gsub("\\./rmds", output_dir, doc_files))
