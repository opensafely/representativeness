################################################################################
# Description: Script to plot TPP & ONS data for deaths, imd, sex and age
#
# Input:  /output/tables/age_sex_count.csv.gz
#         /output/tables/age_count.csv.gz
#         /output/tables/death_count.csv.gz
#         /output/tables/imd_count.csv.gz
#         /output/tables/ethnic_group.csv
#
# output: output/plots/Cause_of_Death_count.jpg
#         output/plots/Cause_of_Death_count_eng.jpg
#         output/plots/imd_count.jpg
#         output/plots/age_sex_count.jpg
#         output/plots/age_sex_count_eng.jpg
#         output/plots/age_count.jpg
#         output/plots/age_count_eng.jpg
#         output/plots/sex_count.jpg
#         output/plots/sex_count_eng.jpg
#         output/plots/ethnicity_count.jpg
#         output/plots/ethnicity_count_eng.jpg
#         output/plots/ethnicity16_count.jpg
#         output/plots/ethnicity16_count_eng.jpg
# 
# Author: Colm D Andrews
# Date:   26/11/2021
#
################################################################################

library(tidyverse)
library(scales)
library(readr)

agelevels<-c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80-84", "85-89", "90+")

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

##################################### imd
imd<-read_csv(here::here("output", "tables","imd_count.csv"))

imd_plot<-imd %>% filter(sex=="Total") %>%
  ggplot(aes(x=imd, y=percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") +
    theme_classic() + theme(axis.text.x = element_text( hjust=0,vjust=0)) + coord_flip() + xlab("") + ylab(" % of Population")

ggsave(filename=here::here("output", "plots","imd_count.jpg"),imd_plot)

################################################ age by sex
age_sex<-read_csv(here::here("output", "tables","age_sex_count.csv"))

age_sex<- age_sex %>%
    mutate(percentage=case_when( sex=="Female"~percentage,sex=="Male"~(-1*percentage))) %>%
    drop_na()

age_sex_plot<-age_sex %>%
  filter(cohort=="ONS",region!="England") %>%
  ggplot(aes(x = age_group, y = percentage, fill = sex,alpha=cohort)) + facet_wrap(~ region) +
   geom_bar(stat = "identity",colour="grey3") + geom_bar(data=age_sex[which(age_sex$cohort=="TPP" & age_sex$region!="England"),], aes(x = age_group, y = percentage, fill = sex,alpha=cohort),stat = "identity",colour="white") +
   coord_flip() +
   scale_fill_brewer(palette = "Set1") +scale_alpha_discrete(range=c(0.3,0.7))+ 
   scale_y_continuous(breaks = seq(-8, 8, 1), 
                      labels = comma(c(seq(8,0,-1), seq(1,8,1)),accuracy=1)) + 
   theme_bw() + theme(text = element_text(size=16)) + scale_x_discrete(limits = agelevels) +
   xlab("") + ylab(" % of cohort") 
  
ggsave(filename=here::here("output", "plots","age_sex_count.jpg"),age_sex_plot,width = 60, height = 30, units = "cm")

age_sex_plot_eng<-age_sex %>%
  filter(cohort=="ONS",region=="England") %>%
  ggplot(aes(x = age_group, y = percentage, fill = sex,alpha=cohort)) + facet_wrap(~ region) +
    geom_bar(stat = "identity",colour="grey3") + geom_bar(data=age_sex[which(age_sex$cohort=="TPP" & age_sex$region=="England"),], aes(x = age_group, y = percentage, fill = sex,alpha=cohort),stat = "identity",colour="white") +
    coord_flip() +
    scale_fill_brewer(palette = "Set1") +scale_alpha_discrete(range=c(0.3,0.7))+ 
    scale_y_continuous(breaks = seq(-8, 8, 1), 
                     labels = comma(c(seq(8,0,-1), seq(1,8,1)),accuracy=1)) + 
    theme_bw() + theme(text = element_text(size=16)) + scale_x_discrete(limits = agelevels) +
    xlab("") + ylab(" % of cohort") 

ggsave(filename=here::here("output", "plots","age_sex_count_eng.jpg"),age_sex_plot_eng,width = 20, height = 15, units = "cm")

################################################ age

age<-read_csv(here::here("output", "tables","age_count.csv"),col_types = cols(
              age_group =  readr::col_factor(levels=agelevels)))
 
age_plot <-age %>%
   filter(region!="England") %>%
    ggplot(aes(x=age_group, y=percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") + facet_wrap(~ region) +
        theme_classic() + theme(axis.text.x = element_text(size=16,angle = 90,hjust=0.95,vjust=0.2)) + 
        xlab("") + ylab(" % of cohort") + 
        scale_x_discrete(limits = agelevels)

ggsave(filename=here::here("output", "plots","age_count.jpg"),age_plot,width = 60, height = 30, units = "cm")

age_plot_eng <-age %>%
  filter(region=="England") %>%
  ggplot(aes(x=age_group, y=percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") + facet_wrap(~ region) +
    theme_classic() + theme(axis.text.x = element_text(size=16,angle = 90,hjust=0.95,vjust=0.2)) + 
    xlab("") + ylab(" % of cohort") + 
    scale_x_discrete(limits = agelevels)

ggsave(filename=here::here("output", "plots","age_count_eng.jpg"),age_plot_eng,width = 15, height = 10, units = "cm")

############################################## sex
sex<-age_sex %>%
  select(sex, cohort,N,region) %>%
  group_by(cohort,sex,region) %>%
  summarise(N = sum(N)) %>% 
  group_by(region,cohort) %>% 
  mutate(Total=sum(N)) %>%
  ungroup %>%
  mutate(percentage = round((N/Total)*100,2))

sex_plot<-sex %>% 
  filter(region!="England") %>%
  ggplot(aes(x=sex, y=percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge")  + facet_wrap(~ region) +
    theme_classic() + theme(axis.text.x = element_text(size=16,angle = 90,hjust=0.95,vjust=0.2)) + 
    xlab("") + ylab(" % of cohort")

ggsave(filename=here::here("output", "plots","sex_count.jpg"),sex_plot,width = 30, height = 15, units = "cm")


sex_plot_eng<-sex %>% 
  filter(region=="England") %>%
  ggplot(aes(x=sex, y=percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge")  + facet_wrap(~ region) +
    theme_classic() + theme(axis.text.x = element_text(size=16,angle = 90,hjust=0.95,vjust=0.2)) + 
    xlab("") + ylab(" % of cohort")

ggsave(filename=here::here("output", "plots","sex_count_eng.jpg"),sex_plot_eng,width = 15, height = 10, units = "cm")

############### ethnicity
ethnicity<-read_csv(here::here("output", "tables","ethnic_group.csv"))

ethnicity_plot<-ethnicity %>%
  filter(region!="England",group=="5_2001") %>%
  ggplot(aes(x=Ethnic_Group, y=percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") + facet_wrap(~ region) +
    theme_classic() + theme(axis.text.x = element_text(size = 16, hjust=0,vjust=0)) + coord_flip() + xlab("") + ylab(" % of all ethnicitys")

ggsave(filename=here::here("output", "plots","ethnicity_count.jpg"),ethnicity_plot,width = 45, height = 30, units = "cm")

ethnicity_plot_eng<-ethnicity %>%
  filter(region=="England",group=="5_2001") %>%
  ggplot(aes(x=Ethnic_Group, y=percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") +
    theme_classic() + theme(axis.text.x = element_text(size = 16, hjust=0,vjust=0)) + coord_flip() + xlab("") + ylab(" % of all ethnicitys")

ggsave(filename=here::here("output", "plots","ethnicity_count_eng.jpg"),ethnicity_plot_eng,width = 30, height = 30, units = "cm")


ethnicity_plot16<-ethnicity %>%
  filter(region!="England",group=="16_2001") %>%
  ggplot(aes(x=Ethnic_Group, y=percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") + facet_wrap(~ region) +
    theme_classic() + theme(axis.text.x = element_text(size = 16, hjust=0,vjust=0)) + coord_flip() + xlab("") + ylab(" % of all ethnicitys")

ggsave(filename=here::here("output", "plots","ethnicity16_count.jpg"),ethnicity_plot16,width = 45, height = 30, units = "cm")

ethnicity_plot16_eng<-ethnicity %>%
  filter(region=="England",group=="16_2001") %>%
  ggplot(aes(x=Ethnic_Group, y=percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") +
    theme_classic() + theme(axis.text.x = element_text(size = 16, hjust=0,vjust=0)) + coord_flip() + xlab("") + ylab(" % of all ethnicitys")

ggsave(filename=here::here("output", "plots","ethnicity16_count_eng.jpg"),ethnicity_plot16_eng,width = 30, height = 30, units = "cm")
