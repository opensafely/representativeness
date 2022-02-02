################################################################################
# Description: Script to combine TPP & ONS data for deaths
#
# input: /output/cohorts/input.csv.gz
#        /data/death_ons.csv.gz
#
# output: /output/tables/death_count.csv.gz
#
# Author: Colm D Andrews
# Date: 31/01/2022
#
################################################################################

## import libraries
library('tidyverse')
library('sf')
fs::dir_create(here::here("output", "tables"))

# # import data
df_input <- read_csv(here::here("output", "cohorts","input_deaths.csv.gz"))

###################################### deaths
##import ONS death data
death_ons<-read_csv(here::here("data","death_ons.csv.gz")) %>%
  rename("region"="Region") %>%
  mutate(cohort="ONS")

TPP_death <- df_input %>% 
    mutate(
          total=sum(died_any),
    # extract relevant parts of the ICD-10 codes to classify deaths
          cause_chapter = str_sub(died_cause_ons,1,1), 
          cause =str_sub(died_cause_ons,1,3), 
          Cause_of_Death = case_when( 
                  cause >= "C33" & cause <="C34" ~ "Malignant neoplasm of trachea, bronchus and lung",
                  cause >= "I20" & cause <="I25" ~ "Ischaemic heart diseases",
                  cause >= "I60" & cause <="I69" ~ "Cerebrovascular diseases",
                  cause == "U07" |cause == "U10.9" ~ "COVID-19",
                  (cause >= "F01" & cause <="F03") | cause == "G30" ~ "Dementia and Alzheimer disease",
                 )) %>%
    group_by(region) %>%
    mutate(Total=sum(died_any)) %>%
  ungroup() %>%
  group_by(region,Cause_of_Death) %>%
  summarise(N=n(),Total=mean(Total))

TPP_death<-TPP_death %>%
  group_by(Cause_of_Death) %>%
  summarise(N=sum(N),Total=sum(Total)) %>%
  mutate(region="England") %>%
  bind_rows(TPP_death)  %>%
  mutate(cohort="TPP") %>%
  drop_na(Cause_of_Death)

  
###### combine TPP and ONS data & use rounding
deaths <- TPP_death %>% 
bind_rows(death_ons) %>%
  mutate(N=round(N/5)*5,
         Total=round(Total/5)*5,
         percentage=N/Total*100)

write_csv(deaths,here::here("output", "tables","death_count.csv"))  ####add .gz to the end
