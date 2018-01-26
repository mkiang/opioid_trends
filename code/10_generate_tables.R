## Config
output_dir <- config::get()$output_folder

## Render the files
rmarkdown::render('./rmds/table1_joinpoint_1979_2015.Rmd', 
                  knit_root_dir = "../")
rmarkdown::render('./rmds/table2_joinpoint_1999_2015.Rmd', 
                  knit_root_dir = "../")

## Move them to the output folder: the knitr options seem to break 
## config() within the rmd files so just doing it manually.
doc_files <- list.files('./rmds', pattern = "\\.docx", full.names = TRUE)
file.rename(doc_files, gsub("\\./rmds", output_dir, doc_files))
