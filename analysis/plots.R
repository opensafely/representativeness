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
library(scales)
library(readr)

agelevels<-c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80-84", "85-89", "90+")



fs::dir_create(here::here("output", "plots"))
 
death<-read_csv(here::here("output", "tables","death_count.csv"))

death_plot<-death %>%
ggplot(aes(x=Cause_of_Death, y=Percentage, fill=Cohort)) +geom_bar(stat = "identity",position = "dodge") +
  theme_classic() + theme(axis.text.x = element_text(size = 16, hjust=0,vjust=0)) + coord_flip() + xlab("") + ylab(" % of all deaths")
ggsave(filename=here::here("output", "plots","Cause_of_Death_count.svg"),death_plot,width = 30, height = 30, units = "cm")

##################################### imd
imd<-read_csv(here::here("output", "tables","imd_count.csv"))

imd_plot<-imd %>% filter(sex=="Total") %>%
  ggplot(aes(x=imd, y=Percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") +
  theme_classic() + theme(axis.text.x = element_text( hjust=0,vjust=0)) + coord_flip() + xlab("") + ylab(" % of Population")
ggsave(filename=here::here("output", "plots","imd_count.svg"),imd_plot)

################################################ age
age_sex<-read_csv(here::here("output", "tables","age_sex_count.csv"))


age_sex<- age_sex %>%
   mutate(sex=case_when(sex=="Females"~"Females",sex=="Males"~"Males"),
     Percentage=case_when( sex=="Females"~Percentage,sex=="Males"~(-1*Percentage))) %>%
   drop_na()

age_sex_plot<-age_sex %>%
   filter(cohort=="ONS") %>%
 ggplot(aes(x = age_group, y = Percentage, fill = sex,alpha=cohort)) + 
   geom_bar(stat = "identity",colour="grey3") + geom_bar(data=age_sex[age_sex$cohort=="TPP",], aes(x = age_group, y = Percentage, fill = sex,alpha=cohort),stat = "identity",colour="white") +
   coord_flip() +
   scale_fill_brewer(palette = "Set1") +scale_alpha_discrete(range=c(0.3,0.7))+ 
   scale_y_continuous(breaks = seq(-8, 8, 1), 
                      labels = comma(c(seq(8,0,-1), seq(1,8,1)))) + 
   theme_bw() + theme(text = element_text(size=16)) + scale_x_discrete(limits = agelevels) +
   xlab("") + ylab(" % of cohort") 
  
ggsave(filename=here::here("output", "plots","age_sex_count.svg"),age_sex_plot,width = 30, height = 30, units = "cm")

 
 age<-read_csv(here::here("output", "tables","age_count.csv"),col_types = cols(
    age =  readr::col_factor(levels=agelevels)))
 
 
 age_plot <-age %>%
   ggplot(aes(x=age_group, y=Percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") +
   theme_classic() + theme(axis.text.x = element_text(size=16,angle = 90,hjust=0.95,vjust=0.2)) + 
    xlab("") + ylab(" % of cohort") + 
    scale_x_discrete(limits = agelevels)
ggsave(filename=here::here("output", "plots","age_count.svg"),age_plot,width = 30, height = 15, units = "cm")



###### sex
sex_plot<-age_sex %>%
  select(sex, cohort,n) %>%
  group_by(cohort,sex) %>%
  summarise(count = sum(abs(n))) %>% 
  mutate(Percentage = round((count/sum(count)),4)*100)  %>%
  ggplot(aes(x=sex, y=Percentage, fill=cohort)) +geom_bar(stat = "identity",position = "dodge") +
  theme_classic() + theme(axis.text.x = element_text(size=16,angle = 90,hjust=0.95,vjust=0.2)) + 
  xlab("") + ylab(" % of cohort")
ggsave(filename=here::here("output", "plots","sex_count.svg"),sex_plot,width = 10, height = 15, units = "cm")


  
  

 