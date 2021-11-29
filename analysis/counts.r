################################################################################
# Description: Script to combine TPP & ONS data for deaths, imd, and age
#
# input: /output/cohorts/input.csv.gz
#        /data/death_ons.csv.gz
#        /data/imd_ons.csv.gz
#        /data/age_ons_sex.csv.gz
#        /data/ethnicity_ons.csv.gz
#
# output: /output/tables/age_sex_count.csv.gz
#         /output/tables/age_count.csv.gz
#         /output/tables/death_count.csv.gz
#         /output/tables/imd_count.csv.gz
#         /output/tables/ethnic_group.csv
#
# Author: Colm D Andrews
# Date: 29/11/2021
#
################################################################################


## Redactor code (W.Hulme)
redactor <- function(n, threshold=6,e_overwrite=NA_integer_){
  # given a vector of frequencies, this returns a boolean vector that is TRUE if
  # a) the frequency is <= the redaction threshold and
  # b) if the sum of redacted frequencies in a) is still <= the threshold, then the
  # next largest frequency is also redacted
  n <- as.integer(n)
  leq_threshold <- dplyr::between(n, 1, threshold)
  n_sum <- sum(n)
  # redact if n is less than or equal to redaction threshold
  redact <- leq_threshold
  # also redact next smallest n if sum of redacted n is still less than or equal to threshold
  if((sum(n*leq_threshold) <= threshold) & any(leq_threshold)){
    redact[which.min(dplyr::if_else(leq_threshold, n_sum+1L, n))] = TRUE
  }
  n_redacted <- if_else(redact, e_overwrite, n)
}
print("redactor function")

agelevels<-c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80-84", "85-89", "90+")


## import libraries
library('tidyverse')
library('sf')
fs::dir_create(here::here("output", "tables"))

# # import data
df_input <- read_csv(here::here("output", "cohorts","input.csv.gz")) %>%
  mutate(sex = case_when(sex=="F"~"Female",sex=="M"~"Male",sex=="I"~"I",sex=="U"~"Unknown"))



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
  summarise(N=n(),total=mean(Total))

TPP_death<-TPP_death %>%
  group_by(Cause_of_Death) %>%
  summarise(N=sum(N),total=sum(total)) %>%
  mutate(region="England") %>%
  bind_rows(TPP_death)  %>%
  mutate(percent=N/total*100,
         cohort="TPP") %>%
  select(-total)

  
###### combine TPP and ONS data
deaths <- TPP_death %>% 
bind_rows(death_ons)

redacted_deaths <- deaths %>% mutate_at(vars(N),redactor) %>%
  mutate(percent=case_when(!is.na(N)~percent))
write_csv(redacted_deaths,here::here("output", "tables","death_count.csv"))  ####add .gz to the end


############################# imd ###################################################

imd_ons<-read_csv(here::here("data","imd_ons.csv.gz")) 

imd_sex<-df_input %>%
  group_by(imd,sex) %>% summarise(Total = n()) 

imd<-imd_sex%>%
  group_by(imd) %>%
  summarise(Total=sum(Total)) %>%
  mutate(sex="Total") %>% bind_rows(imd_sex) %>%
  mutate(cohort="TPP")  %>% 
  bind_rows(imd_ons)%>%
  group_by(sex,cohort) %>%
  mutate(Percentage = round((Total/sum(Total))*100,4)) %>%
  ungroup() %>% arrange(cohort,sex,imd) %>%
  mutate(imd = case_when(imd==1~"1: Most deprived",imd==2~"2",imd==3~"3",imd==4~"4",imd==0~"Unknown",imd==5~"5: Least deprived"))


redacted_imd <- imd %>% mutate_at(vars(Total),redactor) %>%
  mutate(Percentage=case_when(!is.na(Total)~Percentage))

write_csv(redacted_imd,here::here("output", "tables","imd_count.csv"))  ####add .gz to the end

############################################## age
age_ons_sex<-read_csv(here::here("data","age_ons_sex.csv.gz")) %>%
  group_by(age_group,sex,Region) %>% 
  summarise(N = sum(N),Total=sum(Total),percentage=sum(percentage)) %>%
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
  mutate(percentage=N/Total * 100,
         cohort="TPP")

  age_sex <- age_sex_tpp %>%        
  bind_rows(age_ons_sex) %>%
    filter(sex=="Male" | sex=="Female")

age_ons_total<-age_ons_sex %>%
  filter(sex=="Total")
  
age<-  age_sex_tpp %>%
  group_by(region,age_group) %>%
  summarise(N = sum(N)) %>%
  group_by(region) %>%
  mutate(Total=sum(N)) %>%
  ungroup %>%
  mutate(sex="Total",
         percentage=N/Total*100,
         cohort="TPP") %>%
  bind_rows(age_ons_total)

redacted_age <- age %>% mutate_at(vars(N),redactor) %>%
  mutate(Percentage=case_when(!is.na(N)~percentage))

write_csv(redacted_age,here::here("output", "tables","age_count.csv"))

redacted_age_sex <- age_sex %>% mutate_at(vars(N),redactor) %>%
  mutate(Percentage=case_when(!is.na(N)~percentage))
write_csv(redacted_age_sex,here::here("output", "tables","age_sex_count.csv"))  ####add .gz to the en

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
         percent=N/Total*100,
         cohort="TPP",
         group="5_2001")


eth_tpp_16 <- df_input %>%
  mutate(Ethnic_Group=case_when(
    ethnicity_16 == "1" ~ "British",
    ethnicity_16 == "2" ~ "Irish",
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
         percent=N/Total*100,
         cohort="TPP",
         group="16_2001")

ethnicity<-eth_tpp_16 %>%
  bind_rows(eth_tpp) %>%
  bind_rows(eth_ons) 
### Add England
  ethnicity2 <-ethnicity %>%
  group_by(group,Ethnic_Group,cohort) %>%
  summarise(N=sum(N)) %>% 
  group_by(group,cohort) %>%
  mutate(N=N,Total=sum(N),percent=N/Total*100, 
         region="England") %>%
  bind_rows(ethnicity) %>%
  mutate(percent=N/Total * 100)

redacted_ethnicity <- ethnicity2 %>% mutate_at(vars(N),redactor) %>%
  mutate(percent=case_when(!is.na(N)~percent))
write_csv(redacted_ethnicity,here::here("output", "tables","ethnic_group.csv"))
