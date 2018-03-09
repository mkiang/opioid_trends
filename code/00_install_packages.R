## 00_install_packages.R
## 
## Install all packages necessary for reproducing this paper. Will not 
## re-install or overwrite existing version of the package. Note that two 
## packages below are installed using Github because they are not available
## on CRAN.

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
