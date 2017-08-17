rm(list=ls())
library(XML)
library(xml2)
library(dtplyr)
library(dplyr)
library(plotly)
library(purrr)
library(lubridate)
library(magrittr)

xml.url <- "http://statdb.dgbas.gov.tw/PXweb/OpenData/PriceStatistics/PR0104A1M.xml"
xmlfile <- xmlTreeParse(xml.url, useInternalNodes = TRUE)

input<-c(9,17,25)
XPath.set<-paste0("/GenericData/DataSet/Series[",
                  as.character(input),
                  "]/SeriesProperty[1]/Obs")
xpath2dataframe <- function(xpath)  {
  xmlfile %>% getNodeSet(xpath) %>%  
    xmlApply(xmlAttrs) %>% 
    unlist %>%
    matrix(length(.)/2,2,byrow=TRUE) %>%
    as.data.frame %>% 
    rename("時間"="V1","指數"="V2") %>% 
    mutate(
      指數=as.numeric(as.character(指數)),
      時間=時間 %>% as.character %>%
        gsub("M","-",.) %>%
        paste0("-01")  %>%
        ymd)
}

map(XPath.set,xpath2dataframe)->data.list

#Recursively apply a function to a list
purrr::reduce(data.list,left_join,by="時間") %>% 
  na.omit %>%
  rename(
    "最低20％"="指數.x",
    "中間60％"="指數.y",
    "最高20％"="指數")-> cpiByHouseholdIncome

cpiByHouseholdIncome %<>% gather(income.level,cpi,-時間)

save(cpiByHouseholdIncome, data.list,file="cpiByHouseholdIncome.Rda")
