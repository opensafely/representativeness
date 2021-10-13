################################################################################
# Description: Script to combine TPP & ONS data for deaths, imd, and age
#
# input: 
#
# Author: Colm D Andrews
# Date: 08/10/2021
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



## import libraries
library('tidyverse')
library('sf')
fs::dir_create(here::here("output", "tables"))

# # import data
df_input <- read_csv(here::here("output", "cohorts","input.csv.gz")) %>%
  mutate(sex = case_when(sex=="F"~"Females",sex=="M"~"Males",sex=="I"~"I",sex=="U"~"Unknown"))



###################################### deaths
##import ONS death data

death_ons<-read_csv(here::here("data","ONSdeaths2020.csv"),skip = 11)
ons_total<-read_csv(here::here("data","ONSdeaths2020.csv"),skip = 10,n_max = 1) %>%
   rename("x1"=1,"Total"=2) %>% select(Total)

### reformat ons data
death_ons<-death_ons %>% rename("cod"=1,"Count"=2) %>% bind_cols(ons_total) %>%
  mutate(Cause_of_Death=case_when(str_sub(cod,1,3)=="U07"~"COVID-19",
                                  str_sub(cod,4,4)=="-"~str_sub(cod,9),
                                  str_sub(cod,4,4)==" "~str_sub(cod,5))) %>%
mutate(Percentage = round((Count/Total),4)*100,Cohort="ONS") %>%
  select(-cod,-Total)
  
TPP_death <- df_input %>% 
    mutate(
          total=sum(died_any),
    # extract relevant parts of the ICD-10 codes to classify deaths
          cause_chapter = str_sub(died_cause_ons,1,1), 
          cause =str_sub(died_cause_ons,1,3), 
    # create specific causes of death to match K Baskharan's analysis
    # assumes COVID-19 if more than one primary/underlying 
          Broad_Cause_of_Death = case_when(
                  cause_chapter == "C" ~ "Cancer",
                  cause_chapter == "I" ~ "Cardiovascular Disease",
                  cause_chapter == "J" ~ "Respiratory Disease",
                  # dementia codes should be F01, F02, F03 and G30     
                  cause >= "F0" & cause_chapter <"F4" ~ 'Dementia', 
                  cause == "G30" ~ 'Dementia', 
                  died_ons_covid_flag_any == 1 ~ "COVID-19", 
                  TRUE ~ "Other"),
          Broad_Cause_of_Death = factor(Broad_Cause_of_Death, levels = c("Respiratory Disease", "Dementia", "Cardiovascular Disease", "Cancer", "Other", "COVID-19")),
          Cause_of_Death = case_when( 
                  cause == "C15" ~ "Malignant neoplasm of oesophagus",
                  cause == "C16" ~ "Malignant neoplasm of stomach",
                  cause == "C18" ~ "Malignant neoplasm of colon",
                  cause >= "C19" & cause <="C21" ~ "Malignant neoplasm of rectosigmoid junction, rectum and anus",
                  cause == "C25" ~ "Malignant neoplasm of pancreas",
                  cause >= "C33" & cause <="C34" ~ "Malignant neoplasm of trachea, bronchus and lung",
                  cause == "C43" ~ "Malignant melanoma of the skin",
                  cause == "C44" ~ "Other malignant neoplasms of skin",
                  cause == "C50" ~ "Malignant neoplasm of breast",
                  cause == "C53" ~ "Malignant neoplasm of cervix uteri",
                  cause == "C61" ~ "Malignant neoplasm of prostate",
                  cause == "C67" ~ "Malignant neoplasm of bladder",
                  cause >= "C91" & cause <="C95" ~ "Leukaemia",
                  cause >= "E10" & cause <="E14" ~ "Diabetes mellitus",
                  cause >= "F01" & cause <="F03" ~ "Dementias",
                  cause == "G30" ~ "Alzheimer disease",
                  cause >= "I20" & cause <="I25" ~ "Ischaemic heart diseases",
                  cause >= "I60" & cause <="I69" ~ "Cerebrovascular diseases",
                  cause >= "J12" & cause <="J18" ~ "Pneumonia",
                  cause >= "J40" & cause <="J44" ~ "Bronchitis, emphysema and other chronic obstructive pulmonary disease",
                  cause >= "K25" & cause <="K27" ~ "Gastric and duodenal ulcer",
                  cause >= "K70" & cause <="K77" ~ "Diseases of liver",
                  cause >= "V01" & cause <="V89" ~ "Land transport accidents",
                  cause >= "X60" & cause <="X84" ~ "Intentional self-harm",
                  cause >= "Y10" & cause <="Y34" ~ "Intentional self-harm",
                  cause == "U07" |cause == "U10.9" ~ "COVID-19")) %>%
      drop_na(Cause_of_Death)
  
###### combine TPP and ONS data
deaths <- TPP_death %>% 
# calculate frequency of each code 
group_by(Cause_of_Death) %>% 
summarise(Count = n(),total=mean(total)) %>% 
mutate(Percentage = round((Count/total),4)*100,Cohort="TPP")  %>% 
  select(-total) %>%
  bind_rows(death_ons)

redacted_deaths <- deaths %>% mutate_at(vars(Count),redactor) %>%
  mutate(Percentage=case_when(!is.na(Count)~Percentage))
write_csv(redacted_deaths,here::here("output", "tables","death_count.csv.gz"))  ####add .gz to the end


############################# imd ###################################################

imd_ons<-read_csv(here::here("data","populationbyimdenglandandwales2020.csv"),skip = 2) 

imd_sex_ons<-imd_ons %>% rename("sex"=1,"imd"=2) %>% mutate(Total=rowSums(across(!imd & !sex))) %>%
  select(sex,imd,Total) %>% drop_na(Total) %>% fill(sex) %>% 
  mutate(imd = case_when(row_number() %% 2==1~(imd+1)/2,row_number() %% 2==0~imd/2,)) %>%
  group_by(sex,imd) %>%
  summarise(Total=sum(Total))

imd_ons<-imd_sex_ons %>%
  group_by(imd) %>%
  summarise(Total=sum(Total)) %>%
  mutate(sex="Total") %>% bind_rows(imd_sex_ons) %>%
  mutate(cohort="ONS")


imd_sex<-df_input %>%
  group_by(imd,sex) %>% summarise(Total = n()) 

imd<-imd_sex%>%
  group_by(imd) %>%
  summarise(Total=sum(Total)) %>%
  mutate(sex="Total") %>% bind_rows(imd_sex) %>%
  mutate(cohort="TPP")  %>% 
  bind_rows(imd_ons)%>%
  group_by(sex,cohort) %>%
  mutate(Percentage = round((Total/sum(Total)),4)*100) %>%
  ungroup() %>% arrange(cohort,sex,imd) %>%
  mutate(imd = case_when(imd==1~"1: Most deprived",imd==2~"2",imd==3~"3",imd==4~"4",imd==0~"Unknown",imd==5~"5: Least deprived"))


redacted_imd <- imd %>% mutate_at(vars(Total),redactor) %>%
  mutate(Percentage=case_when(!is.na(Total)~Percentage))

write_csv(redacted_imd,here::here("output", "tables","imd_count.csv.gz"))  ####add .gz to the end

############################################## age

age_ons<-read_csv(here::here("data","ukpopestimatesmid2020.csv"),skip = 7) %>%
    filter(Name=="ENGLAND") %>% select(-starts_with("x"),-Code,-Name,-Geography) %>%
    rownames_to_column %>%
    gather(variable, value, -rowname) %>% 
    spread(rowname, value) %>%  rename("age"=1,"n"=2) %>%
    mutate(cohort="ONS") %>% filter(age!="All ages") %>%
  mutate(age=as.factor(age))
  

age_ons_sex<-read_csv(here::here("data","ukpopestimatesmid2020_male.csv"),skip = 7) %>%
  filter(Name=="ENGLAND") %>% select(-starts_with("x"),-Code,-Name,-Geography) %>%
  rownames_to_column %>%
  gather(variable, value, -rowname) %>% 
  spread(rowname, value) %>%  rename("age"=1,"n"=2) %>%
  mutate(cohort="ONS") %>% filter(age!="All ages") %>%
  mutate(age=as.factor(age)) %>% mutate(sex="Males")

age_ons_female<-read_csv(here::here("data","ukpopestimatesmid2020_female.csv"),skip = 7) %>%
  filter(Name=="ENGLAND") %>% select(-starts_with("x"),-Code,-Name,-Geography) %>%
  rownames_to_column %>%
  gather(variable, value, -rowname) %>% 
  spread(rowname, value) %>%  rename("age"=1,"n"=2) %>%
  mutate(cohort="ONS") %>% filter(age!="All ages") %>%
  mutate(age=as.factor(age))  %>% mutate(sex="Females") %>%
  bind_rows(age_ons_sex) -> age_ons_sex


age_sex_tpp <- df_input %>%
  mutate(age=case_when(age<90~age,age>=90~90)) %>%   
  arrange(age) %>%
  mutate(age=as.factor(age)) %>% mutate(age= fct_recode(age,'90+'="90")) %>%
  group_by(age,sex) %>% summarise(n = n()) %>%
  mutate(cohort="TPP") 
         
age_sex<- age_sex_tpp %>%        
  bind_rows(age_ons_sex)%>%
  group_by(cohort,sex) %>%
  mutate(Percentage = round((n/sum(n)),4)*100) %>%
  ungroup() %>%
  mutate(age=factor(age,levels=levels(age_sex_tpp$age))) %>%
  arrange(cohort,age)
  
agelevels<-levels(age_sex_tpp$age)
saveRDS(agelevels, here::here("output", "tables","levels.RData"))

age<-  age_sex %>%
  group_by(cohort,age) %>%
  summarise(n = sum(abs(n)))%>%
  mutate(Percentage = round((n/sum(n)),4)*100) %>%
  ungroup() %>% 
  mutate(age=factor(age,levels=levels(age_sex_tpp$age)))%>%
  arrange(cohort,age)

redacted_age <- age %>% mutate_at(vars(n),redactor) %>%
  mutate(Percentage=case_when(!is.na(n)~Percentage))

write_csv(redacted_age,here::here("output", "tables","age_count.csv.gz"))

redacted_age_sex <- age_sex %>% mutate_at(vars(n),redactor) %>%
  mutate(Percentage=case_when(!is.na(n)~Percentage))
write_csv(redacted_age_sex,here::here("output", "tables","age_sex_count.csv.gz"))  ####add .gz to the en
