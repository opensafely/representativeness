################################################################################
# Description: Script to plot TPP & ONS data for deaths, imd, sex and age
#
# Input:  output/tables/death_count.csv.gz
#
# output: output/plots/Cause_of_Death_count.jpg
#         output/plots/Cause_of_Death_count_eng.jpg
#
# Author: Colm D Andrews
# Date:   26/11/2021
#
################################################################################

library(tidyverse)
library(scales)
library(readr)

fs::dir_create(here::here("output", "plots"))
############################# deaths

death<-read_csv(here::here("output", "tables","death_count.csv"))

death_plot<-death %>%
  filter(region!="England") %>%
  ggplot(aes(x=Cause_of_Death, y=percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") + facet_wrap(~ region) +
    theme_classic() + theme(axis.text.x = element_text(size = 16, hjust=0,vjust=0)) + coord_flip() + xlab("") + ylab(" % of all deaths")

ggsave(filename=here::here("output", "plots","Cause_of_Death_count.jpg"),death_plot,width = 30, height = 30, units = "cm")

death_plot_eng<-death %>%
  filter(region=="England") %>%
  ggplot(aes(x=Cause_of_Death, y=percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") +
    theme_classic() + theme(axis.text.x = element_text(size = 16, hjust=0,vjust=0)) + coord_flip() + xlab("") + ylab(" % of all deaths")

ggsave(filename=here::here("output", "plots","Cause_of_Death_count_eng.jpg"),death_plot_eng,width = 30, height = 30, units = "cm")
