library(tidyverse)
library(data.table)
library(dtplyr)

args <- c("input_1_stppop_map.csv.gz", "data/msoa_shp.rds")

## Load shapefiles
msoa_shp <- readRDS(args[2])
input <- read_csv(args[1])

# TPP coverage by MSOA
png("./tpp_coverage_msoa.png", height = 500, width = 600)
input %>%
  group_by(msoa) %>%
  summarise(tpp_cov = unique(tpp_cov)) %>%
  ungroup() %>%
  ggplot(aes(tpp_cov)) +
  geom_histogram(bins = 30, fill = "white", col = "black") 
dev.off()


