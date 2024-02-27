require(tidyverse)

p <- fread("C:/Users/quinn/Documents/file cabinet/Jibs/DS Examples/ShinyExample/dataDashboard/data/pokemon.csv")
p$ncapture_rate = as.numeric(p$capture_rate)
features <-  names(p)[sapply(p, function(x) class(x) %in% c("integer", "numeric"))]

p <- na.omit(p[,.SD, .SDcols = !c("percentage_male", "pokedex_number")])
##too much missing data in this feature (98)
features <-  names(p)[sapply(p, function(x) class(x) %in% c("integer", "numeric"))]

cp_cols <- sapply(names(p)[names(p) %in% features], function(x) paste0("P_",x))
cats <-  names(p)[sapply(p, function(x) !(class(x) %in% c("integer", "numeric")))]
catnm <- names(cats)

p %>% setnames(features, cp_cols)

pcats <- p[,cats,with=F]
fcopy <-  names(p)[sapply(p, function(x) class(x) %in% c("integer", "numeric"))]

p <- p[,lapply(p[,fcopy, with = F], scale)] %>% 
  cbind(.,pcats) %>% 
  as.data.table(.) %>% 
  rename_with(., ~ gsub(".V1", "", .x, fixed = TRUE)) %>%
  rename_with(., ~ gsub("X.", "", .x, fixed = TRUE)) 
save(p, file = "poke_cleaned.RData")
