################################################################################
# Description: Script to combine TPP & ONS data for deaths, imd, and age
#
# input: 
#
# Author: Colm D Andrews
# Date: 08/10/2021
#
################################################################################



## import libraries
library('tidyverse')
library('sf')

# # import data
df_input <- read_csv("./output/cohorts/input_1_stppop_map.csv.gz",
                     col_types = cols(
                            patient_id = col_integer(),
                            stp = col_character()
                          )) %>%
  mutate(sex = case_when(sex=="F"~"Females",sex=="M"~"Males"))



###################################### deaths
##import ONS death data
death_ons<-read_csv("./data/ONSdeaths2020.csv",skip = 11) 
ons_total<-read_csv("./data/ONSdeaths2020.csv",skip = 10,n_max = 1) %>%
   rename("x1"=1,"Total"=2) %>% select(Total)

### reformat ons data
death_ons<-death_ons %>% rename("cod"=1,"Count"=2) %>% bind_cols(ons_total) %>%
  mutate(Cause_of_Death=case_when(str_sub(cod,1,3)=="U07"~"COVID-19",str_sub(cod,4,4)=="-"~str_sub(cod,9),str_sub(cod,4,4)==" "~str_sub(cod,5))) %>%
mutate(Percentage = round((Count/Total),4)*100,Cohort="ONS") %>%
  select(-cod,-Total)
  
TPP_death <- df_input %>% 
    mutate(total=sum(died_any)) %>%
    # extract relevant parts of the ICD-10 codes to classify deaths
    mutate(cause_chapter = str_sub(died_cause_ons,1,1)) %>% 
    mutate(cause =str_sub(died_cause_ons,1,3)) %>% 
    # create specific causes of death to match K Baskharan's analysis
    # assumes COVID-19 if more than one primary/underlying 
    mutate(Broad_Cause_of_Death = case_when(
      cause_chapter == "C" ~ "Cancer",
      cause_chapter == "I" ~ "Cardiovascular Disease",
      cause_chapter == "J" ~ "Respiratory Disease",
      # dementia codes should be F01, F02, F03 and G30     
      cause >= "F0" & cause_chapter <"F4" ~ 'Dementia', 
      cause == "G30" ~ 'Dementia', 
      died_ons_covid_flag_any == 1 ~ "COVID-19", 
      TRUE ~ "Other"),
      Broad_Cause_of_Death = factor(Broad_Cause_of_Death, levels = c("Respiratory Disease", "Dementia", "Cardiovascular Disease", "Cancer", "Other", "COVID-19"))) %>%
    mutate(Cause_of_Death = case_when( 
      cause == "C15" ~ "Malignant neoplasm of oesophagus",
      cause == "C16" ~ "Malignant neoplasm of stomach",
      cause == "C18" ~ "Malignant neoplasm of colon",
      cause >= "C19" & cause <="C21" ~ "Malignant neoplasm of Rectosigmoid junction, rectum, and anus",
      cause == "C25" ~ "Malignant neoplasm of pancreas",
      cause >= "C33" & cause <="C34" ~ "Malignant neoplasm of trachea, bronchus and lung",
      cause == "C43" ~ "Malignant melanoma of the skin",
      cause == "C44" ~ "Other malignant neoplasm of the skin",
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
      cause == "U07" |cause == "U10.9" ~ "COVID-19"))
  
###### combine TPP and ONS data
deaths <- TPP_death %>% 
# calculate frequency of each code 
group_by(Cause_of_Death) %>% 
summarise(Count = n(),total=mean(total)) %>% 
mutate(Percentage = round((Count/total),4)*100,Cohort="TPP")  %>% 
  select(-total) %>%
  bind_rows(death_ons)


write_csv(deaths,here::here("output", "tables","death_count.csv.gz"))  ####add .gz to the end


############################# imd ###################################################

imd_ons<-read_csv("./data/populationbyimdenglandandwales2020.csv",skip = 2) 

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

write_csv(imd,here::here("output", "tables","imd_count.csv.gz"))  ####add .gz to the end

############################################## age

age_ons<-read_csv("./data/ukpopestimatesmid2020.csv",skip = 7) %>%
    filter(Name=="ENGLAND") %>% select(-starts_with("x"),-Code,-Name,-Geography) %>%
    rownames_to_column %>%
    gather(variable, value, -rowname) %>% 
    spread(rowname, value) %>%  rename("age"=1,"n"=2) %>%
    mutate(cohort="ONS") %>% filter(age!="All ages") %>%
  mutate(age=as.factor(age))
  

age_ons_sex<-read_csv("./data/ukpopestimatesmid2020_male.csv",skip = 7) %>%
  filter(Name=="ENGLAND") %>% select(-starts_with("x"),-Code,-Name,-Geography) %>%
  rownames_to_column %>%
  gather(variable, value, -rowname) %>% 
  spread(rowname, value) %>%  rename("age"=1,"n"=2) %>%
  mutate(cohort="ONS") %>% filter(age!="All ages") %>%
  mutate(age=as.factor(age)) %>% mutate(n=-1*n,sex="Males")

age_ons_female<-read_csv("./data/ukpopestimatesmid2020_female.csv",skip = 7) %>%
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
  mutate(cohort="TPP") %>% mutate(n=case_when(sex=="Males"~(-n),sex=="Females"~n))
         
age_sex<- age_sex_tpp %>%        
  bind_rows(age_ons_sex)%>%
  group_by(cohort,sex) %>%
  mutate(Percentage = round((n/sum(n)),4)*100) %>%
  ungroup() %>%
  mutate(Percentage=case_when(sex=="Males"~(-Percentage),sex=="Females"~Percentage))
  

write_csv(age_sex,here::here("output", "tables","age_sex_count.csv.gz"))  ####add .gz to the end


age<-  age_sex_tpp %>%
  bind_rows(age_ons)%>%
  group_by(cohort,age) %>%
  summarise(n = sum(sqrt(n^2)))%>%
  mutate(Percentage = round((n/sum(n)),4)*100) %>%
  ungroup() %>% arrange(cohort,age)

write_csv(age,here::here("output", "tables","age_count.csv.gz"))  ####add .gz to the end
