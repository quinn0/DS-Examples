require(tidyverse)
require(dtplyr)
require(data.table)
require(magrittr)

setwd("C:/Users/quinn/Documents/file cabinet/Jibs")
###artile_pos###########
article_pos <- fread("article_positions.csv")
##uniq values for layout and image options
layout_img <- lapply(article_pos[,.(layout, image_options)], unique)

################article####################
article <- fread("articles.csv")
#uniq vals section(22) subsection(65) topic (141)
cats <- lapply(article[,.(section, subsection, topic)], unique)

sub_cats <- lapply(article[section %chin% "Economy" , .(subsection, topic)], unique)
##TO-DO: Graphics create table of counts of subsections and topics for each section 

brkdwn_ct <- article[, .N, by = c("section","subsection", "topic")] %>% .[order(.[,section])]

##broadest topics(not necessarily most popular):
subsec_cts <- brkdwn_ct[, .N, by = "section"] %>% .[order(.[,N], decreasing = T)] %>% 
  setnames(., names(.), c("section", "subsection_count"))

subsec_cts[subsection_count>4]

##Most material by section
art_brkdwn <- article[,.N, by = "section"] %>% .[order(.[,N],decreasing = T)]
setnames(art_brkdwn, names(art_brkdwn), c("section", "article_count"))

##most General topics (flawed metric bc of subsection distributions)
breakdowns <- merge(art_brkdwn,subsec_cts, by = "section") %>% 
  .[, spread_ratio := article_count/subsection_count] %>% 
  .[order(.[,spread_ratio], decreasing = T)]


############################page views#####################################

pg_view <- fread("pageviews.csv") %>% .[order(.[,user_id])]
most_views <- pg_view[,length(unique(visit_num)), by = "user_id"] %>% .[order(.[,V1], decreasing =T)]
nrow(most_views[V1 > 1])/length(unique(pg_view$user_id))
#lonly 2% of users in sample visit the site more than once per week???
# break this out by platform instead of user? mobile -> more engagement?
usr_prof <- fread("user_profiles.csv")

drop_d <- pg_view[!duplicated(pg_view, by = c("user_id", "article_id"))]
####CTR#####

########## Count of article_id duplicates (minus Home Page) group by position
            #### Divide: rows - homepage group by position

art_count <-article_pos[order(article_pos[,c("article_id", "min_time_et")])] #%>% 
                      #.[, time_range := lapply(., interval(start = article_pos$min_time_et, end = max_time_et))]
                        
View(art_count[article_id == "WP-WSJ-0000646944"])
View(pg_view[article_id == "WP-WSJ-0000646944"])











