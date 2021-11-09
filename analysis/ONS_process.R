################################################################################
# Description: Script to combine TPP & ONS data for deaths, imd, and age
################ RUN LOCALLY ###################################################
#
# input: data/populationbyimdenglandandwales2020.xlsx
#        data/ukpopestimatesmid2020on2021geography.xls
#        data/ONSdeaths2020.csv (downloaded va Nomis: https://www.nomisweb.co.uk/query/construct/components/apicomponent.aspx?menuopt=1611&subcomp=)
#
# output: /data/death_ons.csv.gz
#         /data/imd_ons.csv.gz
#         /data/age_ons_sex.csv.gz
#
# Author: Colm D Andrews
# Date: 14/10/2021
#
################################################################################

agelevels<-c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80-84", "85-89", "90+")

library("readxl")
library("tidyverse")



############## IMD
input_imd_ons<-read_excel(here::here("data","populationbyimdenglandandwales2020.xlsx"),sheet="Table 1 - England",skip = 2) 

imd_sex_ons<-input_imd_ons %>% rename("sex"=1,"imd"=2) %>% mutate(Total=rowSums(across(!imd & !sex))) %>%
  select(sex,imd,Total) %>% drop_na(Total) %>% fill(sex) %>% 
  mutate(imd = case_when(row_number() %% 2==1~(imd+1)/2,row_number() %% 2==0~imd/2,)) %>%
  group_by(sex,imd) %>%
  summarise(Total=sum(Total))

imd_ons<-imd_sex_ons %>%
  group_by(imd) %>%
  summarise(Total=sum(Total)) %>%
  mutate(sex="Total") %>% bind_rows(imd_sex_ons) %>%
  mutate(cohort="ONS")


write_csv(imd_ons,here::here("data","imd_ons.csv.gz"))  ####add .gz to the end


############### age

age_ons<-read_excel(here::here("data","ukpopestimatesmid2020on2021geography.xls"),sheet ="MYE2 - Persons" ,skip = 7) %>%
  filter(Name=="ENGLAND") %>% select(-starts_with("x"),-Code,-Name,-Geography) %>%
  select(where(is.numeric) & !starts_with("All")) %>%
  rownames_to_column %>%
  gather(variable, value, -rowname) %>% 
  spread(rowname, value) %>%  rename("age"=1,"n"=2) %>%
  mutate(cohort="ONS") %>% filter(age!="All ages") %>%
  mutate(age=as.numeric(age))  %>%
  replace_na(list(age=90))  %>%
  mutate(age_group = cut(age, breaks = seq(0,95,5), right = F, labels = c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80-84", "85-89", "90+")))

age_ons_males<-read_excel(here::here("data","ukpopestimatesmid2020on2021geography.xls"),sheet ="MYE2 - Males" ,skip = 7) %>%
  filter(Name=="ENGLAND") %>% 
  select(where(is.numeric) & !starts_with("All")) %>%
  rownames_to_column %>%
  gather(variable, value, -rowname) %>% 
  spread(rowname, value) %>%  rename("age"=1,"n"=2) %>%
  mutate(cohort="ONS") %>% 
  filter(age!="All ages") %>%
  mutate(age=as.numeric(age))  %>%
  replace_na(list(age=90))  %>%
  mutate(age_group = cut(age, breaks = seq(0,95,5), right = F, labels = agelevels),
         sex="Males")  %>%
  group_by(age_group) %>%
  mutate(n=sum(n))


age_ons_female<-read_excel(here::here("data","ukpopestimatesmid2020on2021geography.xls"),sheet ="MYE2 - Females" ,skip = 7) %>%
  filter(Name=="ENGLAND") %>%
  select(where(is.numeric) & !starts_with("All")) %>%
  rownames_to_column %>%
  gather(variable, value, -rowname) %>% 
  spread(rowname, value) %>%  rename("age"=1,"n"=2) %>%
  mutate(cohort="ONS") %>% 
  filter(age!="All ages") %>%
  mutate(age=as.numeric(age))  %>%
  replace_na(list(age=90))  %>%
  mutate(age_group = cut(age, breaks = seq(0,95,5), right = F, labels =agelevels),
         sex="Females") %>%
  group_by(age_group) %>%
  mutate(n=sum(n)) %>%
  bind_rows(age_ons_males) %>%
  select(-age) %>%
  distinct()  -> age_ons_sex

write_csv(age_ons_sex,here::here("data","age_ons_sex.csv.gz"))  ####add .gz to the end

###### death
###### ONS data downloaded va Nomis: https://www.nomisweb.co.uk/query/construct/components/apicomponent.aspx?menuopt=1611&subcomp=
death_ons<-read_excel(here::here("data","nomis_2021_11_09_141838.xlsx"),skip = 10)
ons_total<-read_excel(here::here("data","nomis_2021_11_09_141838.xlsx"),skip = 9,n_max = 1) %>%
  rename("x1"=1,"Total"=2) %>% select(Total)

### reformat ons data
death_ons<-death_ons %>% rename("cod"=1,"Count"=2) %>% bind_cols(ons_total) %>%
  mutate(Cause_of_Death=str_split(cod, " ", 2),
         Cause_of_Death=sapply(Cause_of_Death,"[",2),
         Percentage = round((Count/Total),4)*100,Cohort="ONS") %>%
          select(-cod,-Total)

write_csv(death_ons,here::here("data","death_ons.csv.gz"))  ####add .gz to the end