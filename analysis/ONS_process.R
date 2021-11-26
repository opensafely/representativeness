################################################################################
# Description: Script to combine TPP & ONS data for deaths, imd, and age
################ RUN LOCALLY ###################################################
#
# input:  downloaded va Nomis:(https://www.nomisweb.co.uk/query/select/getdatasetbytheme.asp?opt=3&theme=&subgrp=)
#        data/upopulationbyimdenglandandwales2020.xlsx
#        data/nomis_2021_11_22_110504.xlsx
#        data/nomis_2021_11_22_104904.xlsx
#        data/nomis_2021_11_22_213653.xlsx
#
# output: /data/death_ons.csv.gz
#         /data/imd_ons.csv.gz
#         /data/age_ons_sex.csv.gz
#         /data/ethnicity_ons.csv.gz
#
# Author: Colm D Andrews
# Date: 26/11/2021
#
################################################################################

library("readxl")
library("tidyverse")

############## IMD
# ONS data downloaded va Nomis:(https://www.nomisweb.co.uk/query/select/getdatasetbytheme.asp?opt=3&theme=&subgrp=)
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
# ONS data downloaded va Nomis:(https://www.nomisweb.co.uk/query/select/getdatasetbytheme.asp?opt=3&theme=&subgrp=)
# male
age_ons_male<-read_excel(here::here("data","nomis_2021_11_22_110504.xlsx"),skip = 108,n_max = 93)

age_ons_male_total<-age_ons_male %>% filter(Age=="All Ages") %>%
  select(-Age) %>% 
  mutate(England=rowSums(across(where(is.numeric)))) %>% 
  pivot_longer(everything(), names_to = "Region",values_to ="Total" )

age_ons_male<-age_ons_male  %>% filter(Age!="All Ages") %>%
  mutate(England=rowSums(across(where(is.numeric)))) %>% 
  pivot_longer(!Age, names_to = "Region",values_to ="N" ) %>% 
  full_join(age_ons_male_total,by="Region") %>%
  mutate( percentage=N/Total*100,
          Age=parse_number(Age),
          age_group = cut(Age, breaks = seq(0,95,5), right = F, labels = c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80-84", "85-89", "90+")),
          sex="Male",
          cohort="ONS")

######## females
age_ons_female<-read_excel(here::here("data","nomis_2021_11_22_110504.xlsx"),skip = 210,n_max = 93)

age_ons_female_total<-age_ons_female %>% filter(Age=="All Ages") %>%
  select(-Age) %>% 
  mutate(England=rowSums(across(where(is.numeric)))) %>% 
  pivot_longer(everything(), names_to = "Region",values_to ="Total" )

age_ons_female<-age_ons_female  %>% filter(Age!="All Ages") %>%
  mutate(England=rowSums(across(where(is.numeric)))) %>% 
  pivot_longer(!Age, names_to = "Region",values_to ="N" ) %>% 
  full_join(age_ons_female_total,by="Region") %>%
  mutate( percentage=N/Total*100,
          Age=parse_number(Age),
          age_group = cut(Age, breaks = seq(0,95,5), right = F, labels = c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80-84", "85-89", "90+")),
          sex="Female",
          cohort="ONS") 

### Combined
age_ons<-read_excel(here::here("data","nomis_2021_11_22_110504.xlsx"),skip = 6,n_max = 93)

age_ons_total<-age_ons %>% filter(Age=="All Ages") %>%
  select(-Age) %>% 
  mutate(England=rowSums(across(where(is.numeric)))) %>% 
  pivot_longer(everything(), names_to = "Region",values_to ="Total" )

age_ons<-age_ons  %>% filter(Age!="All Ages") %>%
  mutate(England=rowSums(across(where(is.numeric)))) %>% 
  pivot_longer(!Age, names_to = "Region",values_to ="N" ) %>% 
  full_join(age_ons_total,by="Region") %>%
  mutate( percentage=N/Total*100,
          Age=parse_number(Age),
          age_group = cut(Age, breaks = seq(0,95,5), right = F, labels = c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80-84", "85-89", "90+")),
          sex="Total",
          cohort="ONS") %>%
  bind_rows(age_ons_male,
            age_ons_female)

write_csv(age_ons,here::here("data","age_ons_sex.csv.gz"))  ####add .gz to the end

###### death
# ONS data downloaded va Nomis:(https://www.nomisweb.co.uk/query/select/getdatasetbytheme.asp?opt=3&theme=&subgrp=)
death_ons<-read_excel(here::here("data","nomis_2021_11_22_104904.xlsx"),skip = 8)
ons_total<-read_excel(here::here("data","nomis_2021_11_22_104904.xlsx"),skip = 8,n_max = 1) %>%
    select(-`cause of death`,-starts_with("Wales")) %>%
    mutate(England=rowSums(across(where(is.numeric)))) %>% 
    pivot_longer(everything(), names_to = "Region",values_to ="Total" )

### reformat ons data
death_ons<-death_ons %>% rename("cod"=1) %>% 
  filter(substr(cod,1,1)=="L") %>%
  mutate(England=rowSums(across(where(is.numeric))), 
         Cause_of_Death=str_split(cod, " ", 2),
         Cause_of_Death=sapply(Cause_of_Death,"[",2)) %>%
  select(-cod,-starts_with("Wales")) %>%
  pivot_longer(!Cause_of_Death, names_to = "Region",values_to ="N" ) %>% 
  full_join(ons_total,by="Region") %>%
  mutate(percent=N/Total*100) %>%
  select(-Total)

write_csv(death_ons,here::here("data","death_ons.csv.gz"))  ####add .gz to the end

######### Ethnicity
# ONS data downloaded va Nomis:(https://www.nomisweb.co.uk/query/select/getdatasetbytheme.asp?opt=3&theme=&subgrp=)
eth_ons<-read_excel(here::here("data","nomis_2021_11_22_213653.xlsx"),skip = 8,n_max = 19) %>%
  mutate(Ethnic_Group=str_split(`Ethnic Group`, ": ", 2),
         Ethnic_Group=sapply(Ethnic_Group,"[",2),
         Ethnic_Group=case_when(
           Ethnic_Group=="English/Welsh/Scottish/Northern Irish/British"~"British",
           Ethnic_Group=="Arab"~"Any other ethnic group",
           Ethnic_Group=="Gypsy or Irish Traveller"~"Other White",
           TRUE ~ Ethnic_Group),
         Ethnic_Group5=case_when(
           (Ethnic_Group=="British" | Ethnic_Group=="Irish" | Ethnic_Group=="Other White")~"White",
           (Ethnic_Group=="White and Black Caribbean"|Ethnic_Group=="White and Black African"|Ethnic_Group=="White and Asian"|Ethnic_Group=="Other Mixed")~"Mixed/multiple ethnic groups",
           (Ethnic_Group=="Indian"|Ethnic_Group=="Pakistani"|Ethnic_Group=="Bangladeshi"|Ethnic_Group=="Other Asian")~"Asian",
           (Ethnic_Group=="African"|Ethnic_Group=="Caribbean"|Ethnic_Group=="Other Black")~"Black",
           (Ethnic_Group=="Any other ethnic group"|Ethnic_Group=="Chinese")~"Other")) %>%
  select(-`Ethnic Group`) %>% filter(Ethnic_Group!="All usual residents")

eth_16_ons<-eth_ons %>%
  select(-Ethnic_Group5) %>%
  pivot_longer(!starts_with("Ethnic"), names_to = "region",values_to ="N" ) %>%
  group_by(region,Ethnic_Group) %>%
  summarise(N=sum(N)) %>%
  group_by(region) %>%
  mutate(Total=sum(N),
         percent=N/Total*100,
         group="16_2001")

eth_5_ons<-eth_ons %>%
  select(-Ethnic_Group) %>%
  pivot_longer(!starts_with("Ethnic"), names_to = "region",values_to ="N" ) %>% 
  group_by(region,Ethnic_Group5) %>%
  summarise(N=sum(N)) %>%
  group_by(region) %>%
  mutate(Total=sum(N),
         percent=N/Total*100,
         group="5_2001") %>%
  rename("Ethnic_Group" = "Ethnic_Group5")

eth_ons_2001 <-eth_5_ons %>%
  bind_rows(eth_16_ons) %>%
  mutate(cohort="ONS")
  
write_csv(eth_ons_2001,here::here("data","ethnicity_ons.csv.gz")) 