################################################################################
# Description: Script to calculate percentage of TPP coverage in ONS population per NUTS1 Region
#
# input:  /output/cohorts/input.csv.gz  - pull NUTS1 region for all TPP-registered patients
#         /output/data/age_ons_sex.csv.gz   - total population ONS estimates per NUTS1 region
# 
# output: /output/plots/tpp_coverage_map.tiff
#         /output/tables/tpp_pop_all.csv
#
# Author: Colm D Andrews
# Date: 26/11/2021
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

fs::dir_create(here::here("output", "plots"))
fs::dir_create(here::here("output", "tables"))

theme_set(theme_minimal())
options(datatable.old.fread.datetime.character = TRUE)
# ---------------------------------------------------------------------------- #

#----------------------#
#    LOAD/CLEAN DATA   #
#----------------------#

## TPP-registered patient records (from study definition)
## Include ALL patients with non-missing region in calculation of TPP populations
input <- read_csv(here::here("output", "cohorts","input.csv.gz")) %>%
  # Remove individuals w missing region
  filter(!is.na(region))

## National NUTS1 population estimates (ONS mid-2020):
nuts1_pop <- read_csv(here::here("data","age_ons_sex.csv.gz"),n_max=9) %>%
  select(Region,Total) %>%
  rename("region"="Region")
                               
# ---------------------------------------------------------------------------- #

print("No. Regions in England:")
n_distinct(nuts1_pop$region)

print("No. TPP-registered patients with non-missing Regions:")
nrow(input)

print("No. unique Regions with patients registered in TPP:")
n_distinct(input$region)

# ---------------------------------------------------------------------------- #

#----------------------------------------------------#
#  Aggregate by Region and merge with ONS population   #
#----------------------------------------------------#

tpp_cov<-input %>%
  # Count records per Nuts1
  group_by(region) %>%
  tally(name =  "tpp_pop_all") %>%
  ungroup() %>%
  right_join(nuts1_pop,by="region") %>%
  mutate(nuts118cd = case_when(region=="East"~"UKH",
                               region=="North West"~"UKD",
                               region=="North East"~"UKC",
                               region=="Yorkshire and The Humber"~"UKE",
                               region=="East Midlands"~"UKF",
                               region=="West Midlands"~"UKG",
                               region=="London"~"UKI",
                               region=="South East"~"UKJ",
                               region=="South West"~"UKK"),
         region = as.factor(region),
         tpp_pop_all=round(tpp_pop_all/5)*5,
         Total=round(Total/5)*5,
         tpp_cov_all = tpp_pop_all*100/Total)


summary(tpp_cov)

# ---------------------------------------------------------------------------- #

#------------------------------------------#
#   Save    #
#------------------------------------------#

write_csv(tpp_cov, here::here("output", "tables","tpp_pop_all.csv"))

################################################################################
#----------------------#
#       FIGURES        #
#----------------------#
## Load shapefiles
nuts_shp<-st_read("data/NUTS_Level_1_(January_2018)_Boundaries.shp")
saveRDS(nuts_shp,here::here("data", "nuts_shp.rds"))
nuts_shp<-readRDS(here::here("data", "nuts_shp.rds"))

coverage_plot<-nuts_shp %>%
  filter(nuts118nm!="Wales" & nuts118nm!="Northern Ireland" & nuts118nm!="Scotland") %>%
  left_join(tpp_cov,by="nuts118cd") %>%
  ggplot(aes(geometry = geometry,fill=tpp_cov_all)) +
  geom_sf(lwd = .8, colour='black') +
  geom_sf_label(aes(label = paste0(round(tpp_pop_all/1000000,1),"M")),
                label.size = 0.1,
                label.r = unit(0.5, "lines"),
                fun.geometry = st_centroid,
                show.legend = F) +
  scale_fill_gradient2(limits=c(0,100), breaks = c(0,sort(round(tpp_cov$tpp_cov_all,0)),100),midpoint = 50, high = "navyblue",
                       mid = "indianred", low = "ivory1",na.value = "white") +
  theme(legend.position = c(0.2,0.5),legend.text.align = 1,
        panel.background=element_rect(fill="white")) + 
  ggtitle("TPP population coverage per NUTS 1 Region") +
  guides(fill=guide_legend(title="TPP population\ncoverage (%)")) + 
  xlab("") + ylab("")

ggsave(filename=here::here("output", "plots","tpp_coverage_map.tiff"),coverage_plot,dpi=600,width = 20,height = 20, units = "cm")
