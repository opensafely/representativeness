################################################################################
# Description: Script to calculate TPP coverage per MSOA and ONS population estimates per MSOA
#
# input: 
#
# Author: Colm D Andrews
# Date: 08/10/2021
#
################################################################################

time_total <- Sys.time()

################################################################################

library(tidyverse)
library(lubridate)
library(ggplot2)
library(sf)
library(data.table)
library(dtplyr)

dir.create(here::here("output", "plots"), showWarnings = FALSE, recursive=TRUE)
dir.create(here::here("output", "tables"), showWarnings = FALSE, recursive=TRUE)
dir.create(here::here("output", "cohorts"), showWarnings = FALSE, recursive=TRUE)


theme_set(theme_minimal())
options(datatable.old.fread.datetime.character = TRUE)

# ---------------------------------------------------------------------------- #

#----------------------#
#    LOAD/CLEAN DATA   #
#----------------------#

# * input.csv 
#   - pull MSOA for all TPP-registered patients
# * msoa_pop.csv 
#   - total population estimates per MSOA
#   - population estimates by single year age
# 
 args <- c("./output/cohorts/input_1_stppop_map.csv.gz","./data/sape23dt4mid2020msoa.csv","./data/msoa_shp.rds")

## TPP-registered patient records (from study definition)
## Include ALL patients with non-missing MSOA in calculation of TPP populations
input <- read_csv(args[1]) %>%
  # Remove individuals w missing/non-England MSOA
  filter(grepl("E",msoa) & !is.na(msoa)) %>%
  mutate(`65+` =case_when(age>=65~1) )

## National MSOA population estimates (ONS mid-2020):
msoa_pop <- fread(args[2], data.table = FALSE, na.strings = "") %>%
  mutate(msoa = as.factor(`MSOA Code`),
         msoa_pop = parse_number(`All Ages`)) %>%
  # Filter to England
  filter(grepl("E", msoa)) %>%
  ungroup() %>%
  select(msoa, msoa_pop)


# ---------------------------------------------------------------------------- #

print("No. MSOAs in England:")
n_distinct(msoa_pop$msoa)

print("No. TPP-registered patients with non-missing MSOA:")
nrow(input)

print("No. unique MSOAs with patients registered in TPP:")
n_distinct(input$msoa)


# ---------------------------------------------------------------------------- #

#----------------------------------------------------#
#  Aggregate by MSOA and merge with ONS population   #
#----------------------------------------------------#

tpp_cov<-input %>%
  # Count records per MSOA
  group_by(msoa) %>%
  tally(name =  "tpp_pop_all") %>%
  ungroup() %>%
  right_join(msoa_pop,by="msoa") %>%
  mutate(msoa = as.factor(msoa),
         tpp_cov_all = tpp_pop_all*100/msoa_pop)

summary(tpp_cov)

# ---------------------------------------------------------------------------- #

#------------------------------------------#
#   Save    #
#------------------------------------------#

saveRDS(tpp_cov, here::here("output", "cohorts","tpp_pop_all.rds"))

################################################################################



## Load shapefiles
msoa_shp <- readRDS(args[3])

# ---------------------------------------------------------------------------- #

#----------------------#
#       FIGURES        #
#----------------------#



plot<-msoa_shp %>%
  filter(grepl("E",MSOA11CD)) %>%
  full_join(tpp_cov, by = c("MSOA11CD" = "msoa")) %>%
  ggplot(aes(geometry = geometry, fill = tpp_cov_all)) +
  geom_sf(lwd = 0) +
  scale_fill_gradient2(midpoint = 100, high = "steelblue", low = "indianred", mid = "white") +
  theme(legend.position = c(0.2,0.9))
  
  
  ggsave(filename=here::here("output", "plots","tpp_coverage_map.svg"),plot)

