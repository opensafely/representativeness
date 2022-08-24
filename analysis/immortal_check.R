library('tidyverse')
fs::dir_create(here::here("output", "tables"))

### Check for immortal patients
df_input <- read_csv(here::here("output", "cohorts","input.csv.gz"))

immort<-df_input %>%
  mutate(agerange=(case_when(age>100~"Over120",age==120~"is120",age>90~"Over110",TRUE~"Under110"))) %>%
  count(agerange) 
  
immort_rounded <- immort  %>%
  mutate(n=case_when(n>5~n),
         n=round(n/7)*7)


write_csv(immort,here::here("output", "tables","immortal.csv"))
write_csv(immort_rounded,here::here("output", "tables","immort_rounded.csv"))