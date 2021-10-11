################################################################################
# Description: Script to plot TPP & ONS data for deaths, imd, and age
#
# input: 
#
# Author: Colm D Andrews
# Date: 08/10/2021
#
################################################################################

library(tidyverse)
library(data.table)
library(dtplyr)
library(scales)

dir.create(here::here("output", "plots"), showWarnings = FALSE, recursive=TRUE)

#death<-read_csv("./output/tables/death_count.csv") 
death<-read_csv(here::here("output", "tables","death_count.csv.gz"))

death_plot<-death %>%
ggplot(aes(x=Cause_of_Death, y=Percentage, fill=Cohort)) +geom_bar(stat = "identity",position = "dodge") +
  theme_classic() + theme(axis.text.x = element_text( hjust=0,vjust=0)) + coord_flip() + xlab("") + ylab(" % of all deaths")
ggsave(filename=here::here("output", "plots","Cause_of_Death.svg"),death_plot)

##################################### imd
imd<-read_csv(here::here("output", "tables","imd_count.csv.gz"))

imd_plot<-imd %>% filter(sex=="Total") %>%
  ggplot(aes(x=imd, y=Percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") +
  theme_classic() + theme(axis.text.x = element_text( hjust=0,vjust=0)) + coord_flip() + xlab("") + ylab(" % of Population")
ggsave(filename=here::here("output", "plots","imd_count.svg"),imd_plot)

################################################ age
age_sex<-read_csv(here::here("output", "tables","age_sex_count.csv.gz"))

age_sex_plot<- age_sex %>%
   filter(cohort=="ONS") %>%
 ggplot(aes(x = age, y = n, fill = sex,alpha=cohort)) + 
   geom_bar(stat = "identity",colour="grey3") + geom_bar(data=age_sex[age_sex$cohort=="TPP",], aes(x = age, y = n, fill = sex,alpha=cohort),stat = "identity",colour="white") +
   coord_flip() +
   scale_fill_brewer(palette = "Set1") +scale_alpha_discrete(range=c(0.3,0.7))+ 
   scale_y_continuous(breaks = seq(-400000, 400000, 100000), 
                      labels = comma(c(seq(400000,0,-100000), seq(100000,400000,100000)))) + 
   theme_bw() + theme(text = element_text(size=8))
ggsave(filename=here::here("output", "plots","age_sex_count.svg"),age_sex_plot)

 
 age<-read_csv(here::here("output", "tables","age_count.csv.gz"))
 
 age_plot <-age %>%
   ggplot(aes(x=age, y=Percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") +
   theme_classic() + theme(axis.text.x = element_text(angle = 90, hjust=0,vjust=0)) + xlab("") + ylab(" % of all ages") + scale_x_discrete()
ggsave(filename=here::here("output", "plots","age_count.svg"),age_plot)

 