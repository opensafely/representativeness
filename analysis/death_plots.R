################################################################################
# Description: Script to plot TPP & ONS data for deaths, imd, sex and age
#
# Input:  output/tables/death_count.csv.gz
#
# output: output/plots/Cause_of_Death_count.png
#         output/plots/Cause_of_Death_count_eng.png
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
levels<-c("Malignant neoplasm of trachea, bronchus and lung","Cerebrovascular diseases","Ischaemic heart diseases","Dementia and Alzheimer disease","COVID-19")
death<-read_csv(here::here("output", "tables","death_count.csv"))


death_plot<-death %>%
  filter(region!="England") %>%
  ggplot(aes(x=Cause_of_Death, y=percentage, fill=cohort)) +
  geom_bar(stat = "identity",position = "dodge") + 
  facet_wrap(~ region) +
  theme_classic() + 
  theme(text = element_text(size = 20)) + 
  coord_flip() + 
  xlab("") + ylab("Percentage of all deaths") +
  scale_x_discrete(limits = levels)

ggsave(filename=here::here("output", "plots","Cause_of_Death_count.png"),death_plot,dpi=600,width = 60, height = 30, units = "cm")

death_plot_eng<-death %>%
  filter(region=="England") %>%
  ggplot(aes(x=Cause_of_Death, y=percentage, fill=cohort)) +
  geom_bar(stat = "identity",position = "dodge") +
  theme_classic() + 
  theme(text = element_text(size = 20)) + 
  coord_flip() + xlab("") + 
  ylab("Percentage of all deaths") + 
  scale_x_discrete(limits = levels)

ggsave(filename=here::here("output", "plots","Cause_of_Death_count_eng.png"),death_plot_eng,dpi=600,width = 30, height = 30, units = "cm")
