## 00_install_packages.R
## 
## Installing missing dependencies. Note: We use `packrat` to track project
## dependencies as it is more robust to a simple install script (such as this).
## 
## To use `packrat`, simply download/install RStudio (http://rstudio.com) and
## open the `opioid_trends.Rproj` file. The correct version of each package
## will be downloaded automatically. If this does not happen, simply open
## `opioid_trends.Rproj` and type `packrat::init()`.
## 
## If you still prefer this method, just run the script below. The code is
## not guaranteed to work since some packages may have introduced backwards-
## incompatible changes.
req_packages <- c("devtools", "tidyverse", "doParallel", "yaml", "digest", 
                  "foreach", "knitr", "config", "rmarkdown")

for (p in req_packages) {
    if (!require(p, character.only = TRUE)) {
        install.packages(p, dependencies = TRUE)
    } 
    library(p, character.only = TRUE)
}

## These packages are not on CRAN so must be installed separately.
## Install narcan for calculating rates and manipulating MCOD files
devtools::install_github("mkiang/narcan", 
                         ref = "b975d72ec98ffa7aa8e73954ac130403a34db870")

## Install patchwork to reproduce figures -- not necessary for analysis
devtools::install_github("thomasp85/patchwork")
