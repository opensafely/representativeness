library('tidyverse')
fs::dir_create(here::here("output", "tables"))

### Check for immortal patients
df_input <- read_csv(here::here("output", "cohorts","input.csv.gz"))

immort<-df_input %>%
  mutate(agerange=(case_when(age>120~"Over120",age==120~"is120",age>110~"Over110",TRUE~"Under110"))) %>%
  count(agerange) %>%
  mutate(n=round(n/5)*5,
         percentage=n/sum(n)*100)


write_csv(immort,here::here("output", "tables","immortal.csv"))