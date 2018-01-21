
-   [Introduction](#introduction)
-   [Requirements](#requirements)
-   [The pipeline](#the-pipeline)
-   [Authors](#authors)
-   [Footnotes](#footnotes)

Introduction
------------

Code for our paper ["Trends in Black and White Opioid Mortality in the United States, 1979-2015"](LINK), which uses multiple cause of death data to examine racial differences in opioid mortality over time. The full citation is:

> PAPER CITATION

Unfortunately, parts of this code depend on the [National Cancer Institute's Joinpoint Regression Program](https://surveillance.cancer.gov/joinpoint/), which requires some parts of the pipeline be run independently of this code.[1] However, we detail all the steps necessary to fully replicate results below.

Please submit issues [via Github](https://github.com/mkiang/opioid_trends/issues) or email.

Requirements
------------

The pipeline
------------

Unforuntately, parts of this analyses require using the NCI Joinpoint Regression Program, and thus are not fully reproducible. However, we include all output and input files required to (re)run the joinpoint parts of the pipeline in the next section.

The pipeline is broken into discrete files and steps.

1.  `01_download_and_trim_raw_data.R`: Downloads data directly from the NBER website and "trims" the dataset by subsetting only to the columns we will use for analysis. In the `config.yml` file, the user can specify if the raw (untrimmed) data should be kept. The raw data take up approximately 2.9 GB of space (when compressed). The trimmed files take up approximately 900 MB when compressed. When running this process in parallel (that is, setting the `proc_in_parallel` option to `true` in the `config.yml` file), each process consumes 3.5–4 GB of RAM and the default number of processes is half of the available cores. Make sure your computer is capable of this before setting this option to true.

### Joinpoint regressions

Reproducing `joinpoint` analyses

Authors
-------

-   [Monica Alexander](http://monicaalexander.com) ([GitHub](https://github.com/MJAlexander))
-   [Magali Barbieri](http://www.demog.berkeley.edu/directories/profiles/barbieri.shtml)
-   [Mathew Kiang](https://mathewkiang.com) ([GitHub](https://github.com/mkiang))

Footnotes
---------

[1] We are investigating ways of reproducing the Joinpoint Regression Program using open-source statistical programs.
