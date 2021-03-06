################################################################################
# Description: Script to plot TPP & ONS data for deaths, imd, sex and age
#
# Input:  /output/tables/age_sex_count.csv.gz
#         /output/tables/age_count.csv.gz
#         /output/tables/imd_count.csv.gz
#         /output/tables/ethnic_group.csv
#
# output: output/plots/imd_count.png
#         output/plots/age_sex_count.png
#         output/plots/age_sex_count_eng.png
#         output/plots/age_count.png
#         output/plots/age_count_eng.png
#         output/plots/sex_count.png
#         output/plots/sex_count_eng.png
#         output/plots/ethnicity_count.png
#         output/plots/ethnicity_count_eng.png
#         output/plots/ethnicity16_count.png
#         output/plots/ethnicity16_count_eng.png
#
# Author: Colm D Andrews
# Date:   31/01/2022
#
################################################################################

library(tidyverse)
library(scales)
library(readr)
library(ggpubr)

agelevels <-
  c(
    "0-4",
    "5-9",
    "10-14",
    "15-19",
    "20-24",
    "25-29",
    "30-34",
    "35-39",
    "40-44",
    "45-49",
    "50-54",
    "55-59",
    "60-64",
    "65-69",
    "70-74",
    "75-79",
    "80-84",
    "85-89",
    "90+"
  )

fs::dir_create(here::here("output", "plots"))
fs::dir_create(here::here("output", "plots", "na_removed"))

##################################### imd
imd <- read_csv(here::here("output", "tables", "imd_count.csv"))

imd_plot <- imd %>% filter(sex == "Total") %>%
  ggplot(aes(x = imd, y = percentage, fill = cohort)) + geom_bar(stat = "identity", position = "dodge") +
  theme_classic() + theme(axis.text.x = element_text(hjust = 0, vjust =
                                                       0)) + coord_flip() + xlab("") + ylab(" % of Population")

ggsave(
  filename = here::here("output", "plots", "imd_count.png"),
  imd_plot,
  dpi = 600
)

###### NA removed
imd_NA <- read_csv(here::here("output", "tables", "imd_count_NA.csv"))

imd_plot_NA <- imd_NA %>% filter(sex == "Total") %>%
  ggplot(aes(x = imd, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_classic() +
  theme(axis.text.x = element_text(hjust = 0, vjust = 0)) +
  theme(text = element_text(size = 20)) +
  coord_flip() + xlab("") +
  ylab("Percentage of Population")


ggsave(
  filename = here::here("output", "plots", "na_removed", "imd_count_NA.png"),
  imd_plot_NA,
  dpi = 600,
  ,
  width = 20,
  height = 20,
  units = "cm"
)


################################################ age by sex
age_sex <-
  read_csv(here::here("output", "tables", "age_sex_count.csv"))

age_sex <- age_sex %>%
  mutate(percentage = case_when(sex == "Female" ~ percentage, sex == "Male" ~
                                  (-1 * percentage))) %>%
  drop_na()

age_sex_plot <- age_sex %>%
  filter(cohort == "ONS", region != "England") %>%
  ggplot(aes(
    x = age_group,
    y = percentage,
    fill = sex,
    alpha = cohort
  )) +
  facet_wrap( ~ region) +
  geom_bar(stat = "identity", colour = "grey3") +
  geom_bar(
    data = age_sex[which(age_sex$cohort == "TPP" &
                           age_sex$region != "England"), ],
    aes(
      x = age_group,
      y = percentage,
      fill = sex,
      alpha = cohort
    ),
    stat = "identity",
    colour = "white"
  ) +
  coord_flip() +
  scale_fill_brewer(palette = "Set1") +
  scale_alpha_discrete(range = c(0.3, 0.7)) +
  scale_y_continuous(breaks = seq(-20, 20, 1),
                     labels = comma(c(seq(20, 0, -1), seq(1, 20, 1)), accuracy =
                                      1)) +
  theme(text = element_text(size = 20)) +
  theme_bw() + theme(text = element_text(size = 16)) +
  scale_x_discrete(limits = agelevels) +
  xlab("") + ylab("Percentage of cohort")

ggsave(
  filename = here::here("output", "plots", "age_sex_count.png"),
  age_sex_plot,
  dpi = 600,
  width = 60,
  height = 30,
  units = "cm"
)

age_sex_plot_eng <- age_sex %>%
  filter(cohort == "ONS", region == "England") %>%
  ggplot(aes(
    x = age_group,
    y = percentage,
    fill = sex,
    alpha = cohort
  )) +
  facet_wrap( ~ region) +
  geom_bar(stat = "identity", colour = "grey3") +
  geom_bar(
    data = age_sex[which(age_sex$cohort == "TPP" &
                           age_sex$region == "England"), ],
    aes(
      x = age_group,
      y = percentage,
      fill = sex,
      alpha = cohort
    ),
    stat = "identity",
    colour = "white"
  ) +
  coord_flip() +
  scale_fill_brewer(palette = "Set1") +
  scale_alpha_discrete(range = c(0.3, 0.7)) +
  scale_y_continuous(breaks = seq(-20, 20, 1),
                     labels = comma(c(seq(20, 0, -1), seq(1, 20, 1)), accuracy =
                                      1)) +
  theme_bw() +
  theme(text = element_text(size = 20)) +
  scale_x_discrete(limits = agelevels) +
  xlab("") + ylab("Percentage of cohort")

ggsave(
  filename = here::here("output", "plots", "age_sex_count_eng.png"),
  age_sex_plot_eng,
  dpi = 600,
  width = 20,
  height = 15,
  units = "cm"
)

################################################ age

age <-
  read_csv(
    here::here("output", "tables", "age_count.csv"),
    col_types = cols(age_group =  readr::col_factor(levels = agelevels))
  )

age_plot <- age %>%
  filter(region != "England") %>%
  ggplot(aes(x = age_group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap( ~ region) +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    angle = 90,
    hjust = 0.95,
    vjust = 0.2
  )) +
  xlab("") + ylab("Percentage of cohort") +
  scale_x_discrete(limits = agelevels)

ggsave(
  filename = here::here("output", "plots", "age_count.png"),
  age_plot,
  dpi = 600,
  width = 60,
  height = 30,
  units = "cm"
)

age_plot_eng <- age %>%
  filter(region == "England") %>%
  ggplot(aes(x = age_group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap( ~ region) +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    angle = 90,
    hjust = 0.95,
    vjust = 0.2
  )) +
  xlab("") + ylab("Percentage of cohort") +
  scale_x_discrete(limits = agelevels)

ggsave(
  filename = here::here("output", "plots", "age_count_eng.png"),
  age_plot_eng,
  dpi = 600,
  width = 30,
  height = 20,
  units = "cm"
)

age_cum_plot_eng <-
  age %>% filter(region == "England") %>% group_by(cohort) %>%
  ggplot(aes(
    x = age_group,
    y = cumPerc,
    group = cohort,
    color = cohort
  )) + geom_line() + geom_point() +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    angle = 90,
    hjust = 0.95,
    vjust = 0.2
  )) +
  xlab("") + ylab("Percentage of cohort") +
  scale_x_discrete(limits = agelevels)

ggsave(
  filename = here::here("output", "plots", "age_cum_plot_eng.png"),
  age_cum_plot_eng,
  dpi = 600,
  width = 30,
  height = 20,
  units = "cm"
)

age_cum_plot <-
  age %>% filter(region != "England") %>% group_by(cohort) %>%
  ggplot(aes(
    x = age_group,
    y = cumPerc,
    group = cohort,
    color = cohort
  )) + geom_line() + geom_point() +
  facet_wrap( ~ region) +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    angle = 90,
    hjust = 0.95,
    vjust = 0.2
  )) +
  xlab("") + ylab("Percentage of cohort") +
  scale_x_discrete(limits = agelevels)

ggsave(
  filename = here::here("output", "plots", "age_cum_plot.png"),
  age_cum_plot,
  dpi = 600,
  width = 60,
  height = 30,
  units = "cm"
)

############################################## sex
sex <- age_sex %>%
  select(sex, cohort, N, region) %>%
  group_by(cohort, sex, region) %>%
  summarise(N = sum(N)) %>%
  group_by(region, cohort) %>%
  mutate(Total = sum(N)) %>%
  ungroup %>%
  mutate(percentage = round((N / Total) * 100, 2))

sex_plot <- sex %>%
  filter(region != "England") %>%
  ggplot(aes(x = sex, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge")  +
  facet_wrap( ~ region) +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    angle = 90,
    hjust = 0.95,
    vjust = 0.2
  )) +
  xlab("") + ylab("Percentage of cohort")

ggsave(
  filename = here::here("output", "plots", "sex_count.png"),
  sex_plot,
  dpi = 600,
  width = 30,
  height = 15,
  units = "cm"
)


sex_plot_eng <- sex %>%
  filter(region == "England") %>%
  ggplot(aes(x = sex, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge")  +
  facet_wrap( ~ region) +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    angle = 90,
    hjust = 0.95,
    vjust = 0.2
  )) +
  xlab("") + ylab("Percentage of cohort")

ggsave(
  filename = here::here("output", "plots", "sex_count_eng.png"),
  sex_plot_eng,
  dpi = 600,
  width = 30,
  height = 20,
  units = "cm"
)

############### ethnicity
ethnicity <-
  read_csv(here::here("output", "tables", "ethnic_group.csv"))

ethnicity_plot <- ethnicity %>%
  filter(region != "England", group == "5_2001") %>%
  ggplot(aes(x = Ethnic_Group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap( ~ region) +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    hjust = 0,
    vjust = 0
  )) +
  coord_flip() +
  xlab("") + ylab("Percentage of all ethnicities")



ggsave(
  filename = here::here("output", "plots", "ethnicity_count.png"),
  ethnicity_plot,
  dpi = 600,
  width = 45,
  height = 30,
  units = "cm"
)



ethnicity_plot_eng <- ethnicity %>%
  filter(region == "England", group == "5_2001") %>%
  ggplot(aes(x = Ethnic_Group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    hjust = 0,
    vjust = 0
  )) +
  coord_flip() +
  xlab("") + ylab("Percentage of all ethnicities")

ggsave(
  filename = here::here("output", "plots", "ethnicity_count_eng.png"),
  ethnicity_plot_eng,
  dpi = 600,
  width = 30,
  height = 30,
  units = "cm"
)


ethnicity_plot16 <- ethnicity %>%
  filter(region != "England", group == "16_2001") %>%
  ggplot(aes(x = Ethnic_Group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap( ~ region) +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    hjust = 0,
    vjust = 0
  )) +
  coord_flip() +
  xlab("") + ylab("Percentage of all ethnicities")

ggsave(
  filename = here::here("output", "plots", "ethnicity16_count.png"),
  ethnicity_plot16,
  dpi = 600,
  width = 45,
  height = 30,
  units = "cm"
)

ethnicity_plot16_eng <- ethnicity %>%
  filter(region == "England", group == "16_2001") %>%
  ggplot(aes(x = Ethnic_Group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    hjust = 0,
    vjust = 0
  )) +
  coord_flip() +
  xlab("") + ylab("Percentage of all ethnicities")

ggsave(
  filename = here::here("output", "plots", "ethnicity16_count_eng.png"),
  ethnicity_plot16_eng,
  dpi = 600,
  width = 30,
  height = 30,
  units = "cm"
)



####### NA removed

ethnicity_na <-
  read_csv(here::here("output", "tables", "ethnic_group_NA.csv"))

ethnicity_plot16_eng_na <-  ethnicity_na %>%
  filter(region == "England", group == "16_2001") %>%
  ggplot(aes(x = Ethnic_Group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    hjust = 0,
    vjust = 0
  )) +
  coord_flip() +
  xlab("") + ylab("Percentage of all ethnicities")

ggsave(
  filename = here::here(
    "output",
    "plots",
    "na_removed",
    "ethnicity16_count_eng_na.png"
  ),
  ethnicity_plot16_eng_na,
  dpi = 600,
  width = 30,
  height = 30,
  units = "cm"
)

ethnicity_plot_na <- ethnicity_na %>%
  filter(region != "England", group == "5_2001") %>%
  ggplot(aes(x = Ethnic_Group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap( ~ region) +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    hjust = 0,
    vjust = 0
  )) +
  coord_flip() +
  xlab("") + ylab("Percentage of all ethnicities")

ggsave(
  filename = here::here("output", "plots", "na_removed", "ethnicity_count_na.png"),
  ethnicity_plot_na,
  dpi = 600,
  width = 45,
  height = 30,
  units = "cm"
)

ethnicity_plot_eng_na <- ethnicity_na %>%
  filter(region == "England", group == "5_2001") %>%
  ggplot(aes(x = Ethnic_Group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    hjust = 0,
    vjust = 0
  )) +
  coord_flip() +
  xlab("") + ylab("Percentage of all ethnicities")

ggsave(
  filename = here::here(
    "output",
    "plots",
    "na_removed",
    "ethnicity_count_eng_na.png"
  ),
  ethnicity_plot_eng_na,
  dpi = 600,
  width = 30,
  height = 30,
  units = "cm"
)



ethnicity_plot16_na <- ethnicity_na %>%
  filter(region != "England", group == "16_2001") %>%
  ggplot(aes(x = Ethnic_Group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap( ~ region) +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    hjust = 0,
    vjust = 0
  )) +
  coord_flip() +
  xlab("") + ylab("Percentage of all ethnicities")


ggsave(
  filename = here::here("output", "plots", "na_removed", "ethnicity16_count_na.png"),
  ethnicity_plot16_na,
  dpi = 600,
  width = 45,
  height = 30,
  units = "cm"
)


##### remove white / white british
ethnicity_plot_eng_nw <- ethnicity_na %>%
  filter(region == "England",Ethnic_Group!="White", group == "5_2001") %>%
  ggplot(aes(x = Ethnic_Group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    hjust = 0,
    vjust = 0
  )) +
  coord_flip() +
  xlab("") + ylab("Percentage of all ethnicities")

ggsave(
  filename = here::here("output", "plots", "ethnicity_count_eng_nw.png"),
  ethnicity_plot_eng_nw,
  dpi = 600,
  width = 30,
  height = 30,
  units = "cm"
)

ethnicity_plot_nw <- ethnicity_na %>%
  filter(region != "England",Ethnic_Group!="White" ,group == "5_2001") %>%
  ggplot(aes(x = Ethnic_Group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap( ~ region) +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    hjust = 0,
    vjust = 0
  )) +
  coord_flip() +
  xlab("") + ylab("Percentage of all ethnicities")

ggsave(
  filename = here::here("output", "plots", "ethnicity_count_nw.png"),
  ethnicity_plot_nw,
  dpi = 600,
  width = 45,
  height = 30,
  units = "cm"
)

ethnicity_plot16_nw <- ethnicity_na %>%
  filter(region != "England",Ethnic_Group!="White British", group == "16_2001") %>%
  ggplot(aes(x = Ethnic_Group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap( ~ region) +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    hjust = 0,
    vjust = 0
  )) +
  coord_flip() +
  xlab("") + ylab("Percentage of all ethnicities")

ggsave(
  filename = here::here("output", "plots", "ethnicity16_count_nw.png"),
  ethnicity_plot16_nw,
  dpi = 600,
  width = 45,
  height = 30,
  units = "cm"
)

ethnicity_plot16_eng_nw <- ethnicity_na %>%
  filter(region == "England",Ethnic_Group!="White British", group == "16_2001") %>%
  ggplot(aes(x = Ethnic_Group, y = percentage, fill = cohort)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_classic() +
  theme(text = element_text(size = 20)) +
  theme(axis.text.x = element_text(
    size = 20,
    hjust = 0,
    vjust = 0
  )) +
  coord_flip() +
  xlab("") + ylab("Percentage of all ethnicities")

ggsave(
  filename = here::here("output", "plots", "ethnicity16_count_eng_nw.png"),
  ethnicity_plot16_eng_nw,
  dpi = 600,
  width = 30,
  height = 30,
  units = "cm"
)



ethnicity_5_16 <-
  ggarrange(
    ethnicity_plot_eng_na,
    ethnicity_plot16_eng_na,
    labels = c("A", "B"),
    ncol = 1,
    nrow = 2,
    common.legend = T
  )

ggsave(
  filename = here::here("output", "plots", "ethnicity_5_16_comb.png"),
  ethnicity_5_16,
  dpi = 600,
  width = 30,
  height = 45,
  units = "cm"
)


agesex_comb_plot <- ggarrange(
  age_plot_eng,
  age_sex_plot_eng,
  labels = c("A", "B"),
  ncol = 1,
  nrow = 2
)

ggsave(
  filename = here::here("output", "plots", "agesex_comb_plot.png"),
  agesex_comb_plot,
  dpi = 600,
  width = 30,
  height = 45,
  units = "cm"
)
