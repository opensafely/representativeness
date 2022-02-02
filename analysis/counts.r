################################################################################
# Description: Script to combine TPP & ONS data for deaths, imd, and age
#
# input: /output/cohorts/input.csv.gz
#        /data/imd_ons.csv.gz
#        /data/age_ons_sex.csv.gz
#        /data/ethnicity_ons.csv.gz
#
# output: /output/tables/age_sex_count.csv.gz
#         /output/tables/age_count.csv.gz
#         /output/tables/imd_count.csv.gz
#         /output/tables/ethnic_group.csv
#
# Author: Colm D Andrews
# Date: 31/01/2022
#
################################################################################

agelevels<-c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80-84", "85-89", "90+")


## import libraries
library('tidyverse')
library('sf')
fs::dir_create(here::here("output", "tables"))

# # import data
df_input <- read_csv(here::here("output", "cohorts","input.csv.gz")) %>%
  mutate(sex = case_when(sex=="F"~"Female",sex=="M"~"Male",sex=="I"~"I",sex=="U"~"Unknown"))

############################# imd ###################################################

imd_ons<-read_csv(here::here("data","imd_ons.csv.gz")) 

imd_sex<-df_input %>%
  group_by(imd,sex) %>% 
  summarise(N = n()) %>%
  mutate(sex = case_when(sex=="Female"~"Females",
                         sex=="Male" ~ "Males",
                         T~sex))

imd_unrounded<-imd_sex%>%
  group_by(imd) %>%
  summarise(N=sum(N)) %>%
  mutate(sex="Total") %>% bind_rows(imd_sex) %>%
  mutate(cohort="TPP")  %>% 
  bind_rows(imd_ons)

imd <- imd_unrounded %>%
  group_by(sex,cohort) %>%
  mutate(Total=sum(N),
         N=round(N/5)*5,
         Total=round(Total/5)*5,
         percentage = round(N/Total*100,4)) %>%
  ungroup() %>% arrange(cohort,sex,imd) %>%
  mutate(imd = case_when(imd==1~"1: Most deprived",
                         imd==2~"2",
                         imd==3~"3",
                         imd==4~"4",
                         imd==0~"Unknown",
                         imd==5~"5: Least deprived"))

write_csv(imd,here::here("output", "tables","imd_count.csv"))  ####add .gz to the end

imd_NA<-imd_unrounded %>%
  filter(imd!=0) %>%
  group_by(sex,cohort) %>%
  mutate(Total=sum(N),
         N=round(N/5)*5,
         Total=round(Total/5)*5,
         percentage = round(N/Total*100,4)) %>%
  ungroup() %>% arrange(cohort,sex,imd) %>%
  mutate(imd = case_when(imd==1~"1: Most deprived",
                         imd==2~"2",
                         imd==3~"3",
                         imd==4~"4",
                         imd==0~"Unknown",
                         imd==5~"5: Least deprived"))

write_csv(imd_NA,here::here("output", "tables","imd_count_NA.csv"))  ####add .gz to the end


############################################## age
age_ons_sex<-read_csv(here::here("data","age_ons_sex.csv.gz")) %>%
  group_by(age_group,sex,Region) %>% 
  summarise(N = sum(N),
            Total=mean(Total),
            percentage=sum(percentage)) %>%
  rename("region"="Region") %>%
  mutate(cohort="ONS")

age_sex_tpp <- df_input %>%
  filter(age>=0)  %>%
  mutate(age=(case_when(age>90~90,TRUE~age)),
    age_group = cut(age, breaks = seq(0,95,5), right = F, labels = agelevels)) %>%
  group_by(region,sex) %>%
  mutate(Total=n()) %>%
  ungroup %>%
  group_by(age_group,region,sex) %>% summarise(N = n(),Total=first(Total))

### Add England
age_sex_tpp <-age_sex_tpp %>%
  group_by(sex,age_group) %>%
  summarise(N=sum(N)) %>% 
  group_by(sex) %>%
    mutate(Total=sum(N), 
            region="England") %>%
  bind_rows(age_sex_tpp) %>%
  mutate(cohort="TPP")

age_sex <- age_sex_tpp %>%        
  bind_rows(age_ons_sex) %>%
  filter(sex=="Male" | sex=="Female") %>%
  ## add rounding
  mutate(N=round(N/5)*5,
           Total=round(Total/5)*5,
           percentage=N/Total*100) 

age_ons_total<-age_ons_sex %>%
  filter(sex=="Total")
  
age<-  age_sex_tpp %>%
  group_by(region,age_group) %>%
  summarise(N = sum(N)) %>%
  group_by(region) %>%
  mutate(Total=sum(N)) %>%
  ungroup %>%
  mutate(cohort="TPP") %>%
  bind_rows(age_ons_total) %>%
  mutate(sex="Total",
         ## add rounding
         N=round(N/5)*5,
         Total=round(Total/5)*5,
         percentage=N/Total*100) 

write_csv(age,here::here("output", "tables","age_count.csv"))

write_csv(age_sex,here::here("output", "tables","age_sex_count.csv"))  ####add .gz to the en

################ Ethnicity

eth_ons<-read_csv(here::here("data","ethnicity_ons.csv.gz"))

eth_tpp <- df_input %>%
  mutate(Ethnic_Group=case_when(
      ethnicity == "1" ~ "White",
      ethnicity == "2" ~ "Mixed/multiple ethnic groups",
      ethnicity == "3" ~ "Asian",
      ethnicity == "4" ~ "Black",
      ethnicity == "5" ~ "Other",))  %>%
  group_by(region,Ethnic_Group) %>%
  summarise(N=n()) %>%
  ungroup %>%
  group_by(region) %>% 
  mutate(Total = sum(N),
         cohort="TPP",
         group="5_2001")


eth_tpp_16 <- df_input %>%
  mutate(Ethnic_Group=case_when(
    ethnicity_16 == "1" ~ "White British",
    ethnicity_16 == "2" ~ "White Irish",
    ethnicity_16 == "3" ~ "Other White",
    ethnicity_16 == "4" ~ "White and Black Caribbean",
    ethnicity_16 == "5" ~ "White and Black African",
    ethnicity_16 == "6" ~ "White and Asian",
    ethnicity_16 == "7" ~ "Other Mixed",
    ethnicity_16 == "8" ~ "Indian",
    ethnicity_16 == "9" ~ "Pakistani",
    ethnicity_16 == "10" ~ "Bangladeshi",
    ethnicity_16 == "11" ~ "Other Asian",
    ethnicity_16 == "12" ~ "Caribbean",
    ethnicity_16 == "13" ~ "African",
    ethnicity_16 == "14" ~ "Other Black",
    ethnicity_16 == "15" ~ "Chinese",
    ethnicity_16 == "16" ~ "Any other ethnic group"))  %>%
  group_by(region,Ethnic_Group) %>%
  summarise(N=n()) %>%
  ungroup %>%
  group_by(region) %>% 
  mutate(Total = sum(N),
         cohort="TPP",
         group="16_2001")

ethnicity<-eth_tpp_16 %>%
  bind_rows(eth_tpp) %>%
  bind_rows(eth_ons) 
### Add England
ethnicity_unrounded <-ethnicity %>%
  group_by(group,Ethnic_Group,cohort) %>%
  summarise(N=sum(N)) %>% 
  group_by(group,cohort) %>%
  mutate(N=N,
         Total=sum(N),
         region="England") %>%
  bind_rows(ethnicity) 
  
  ethnicity2 <- ethnicity_unrounded %>%
    ## add rounding
  mutate(N=round(N/5)*5,
         Total=round(Total/5)*5,
         percentage=N/Total * 100) 

write_csv(ethnicity2,here::here("output", "tables","ethnic_group.csv"))


#### NA removed

ethnicity_na<-ethnicity_unrounded %>%
  drop_na(Ethnic_Group) %>%
  group_by(group,cohort, region) %>%
  mutate(
         Total=sum(N),
         N=round(N/5)*5,
         Total=round(Total/5)*5,
         percentage=N/Total * 100) 

write_csv(ethnicity_na,here::here("output", "tables","ethnic_group_NA.csv"))
