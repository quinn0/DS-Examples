import matplotlib.pyplot as plt
from matplotlib.ticker import PercentFormatter as PF
import seaborn as sb
import pandas as pd
import scipy as sp
import numpy as np
from sklearn.decomposition import PCA
# from sklearn.cluster import dendrogram, linkage
import plotly as ply
import plotly_express as px
from datetime import timezone as tz
from itertools import chain
import os

#reading all necessary datasets 
ar =pd.read_csv("articles.csv")
ar_pos = pd.read_csv("article_positions.csv")
pg_views = pd.read_csv("pageviews.csv")
usr_prof = pd.read_csv("user_profiles.csv")
##################### 1: Readership + Platform Curation ###################
#### 1 Top 10 articles####
#popularity will be measured by the number of users who visited that articles page at least once, ignoring the homepage
#Other considerations: how many times the user reads another article after      
                    ## how many times page_num_visits per article (flawed?)


## Cause: Inactivity? Refreshing page?
# print(pg_views.sort_values(by = ["user_id"]).head(5)) (ex: USER_000040cfd786180b5a5b)
#ordered user_id to check user-view duplicates
# #preprocess article info to interpret dates
# #get title and filter out dates outside of 9/23-9/30 (some prior to 9/23)
ar['pub_date_est'] = pd.to_datetime(ar['pub_date_est'], yearfirst=True)
ar_clean = ar.loc[(ar['pub_date_est'] >= "2023-09-23 00:00:00+00:00") \
                  & (ar['pub_date_est'] < "2023-10-01 00:00:00+00:00") \
                    , ["original_headline", "article_id", "pub_date_est"]]
#DF of publications sorted by most frequently used
top_views = (
    #exclude homepage from count
    pg_views.loc[pg_views["article_id"] != "mobile_app_homepage"] 
    # Drop user-article duplicates due to visit_page_num field 
    .drop_duplicates(subset= ["user_id", "article_id"])
    .groupby(by = "article_id")
    .size().to_frame().reset_index()
    #sort views descending to find most frequently viewed
    .sort_values(0, ascending = False)
    #**Note**: would normally .split() and order as strings
    ########## preserving date (ns, UTC) format for posterity
    .merge(ar_clean, how = "inner", on= "article_id")
    .rename(columns = {0:"Total Views", "original_headline":"Title" \
                       , "pub_date_est":"Date Published"})
    [["Title", "Total Views", "article_id", "Date Published"]]
)
## display top 10
print("_________________________________________________________")
print("Top 10 Articles Published between 9/23/2023-9/30/2023 \n")

print("\t"+"Views"+ "              Title")
for i, title in enumerate(top_views.head(10)['Title'].tolist()):
    print("\t"+ str(top_views.at[i, "Total Views"]) + "  " + title)
print("_________________________________________________________\n ")
#full breakdown
#print(top_views.head(10))

#### 2 Homepage - Article CTR by position####
#Notes:+ Articles are in different positions at different times
#      + Def for Homepage --> Article: views in which **visit_page_num  == homepage_visit_page_num + 1**, 
#      indicating viewing an article after the home page
#      + **Some users (i.e. USER_92e3165e8ed2a98f9f63) navigated directly
#           to an article, then returned to the homepage
#      + No date range specified for capture
#      + Not user-specific (multiple WSJ visits in week)
#      + Visit_num in capture is not unique to User
#      + User can return to the same article in one visit from homepage  
# Mapping Position to user page view conditional on time viewed
# add column to articles.csv: position label for each view

#returns value of visit_page_num for all visits to homepage
#    for particular user and WSJ visit (multiple visit numbers)
#    increments each element of list by 1 to find article visited after HP
# appends 'next-page' indices

ind = []
#using copy of page views in order to delete rows for efficiency
pg_views1 = pg_views.copy()
def check_visnums(usr, v_num):
    hp_view = pg_views1.loc[(pg_views1["page_type"] == "Homepage") \
                 & (pg_views1["user_id"] == usr) \
                 & (pg_views1["visit_num"] == v_num)]\
                 ["visit_page_num"].tolist()
    ##for next page view DF, hp_views + 1 
    for i in range(len(hp_view)):
        hp_view[i] = hp_view[i] + 1
    nxt_view = pg_views1.loc[(pg_views1["visit_page_num"].isin(hp_view)) \
                 & (pg_views1["user_id"] == usr) \
                 & (pg_views1["visit_num"] == v_num)].index.tolist()
    
    if(len(nxt_view)>0):
        ind.append(nxt_view)
        pg_views1.drop(index= nxt_view, inplace= True)


#filter for articles visited after homepage **visit_page_num  == homepage_visit_page_num + 1**
## Throw out users that did not start on the homepage
# print(pg_views.loc[pg_views["page_type"] == "Homepage"].sort_values("visit_num", ascending=False).head(10))

# clean = pg_views.loc[pg_views["page_type"] == "mobile_app_homepage" & pg_views["page_type"] == 1].tolist()
#test: below user has no visits after homepage
#Note: page num visits per WSJ visit per user are not always sequential
# test = check_visnums("USER_ce2d3de7e9e33ad160b2", 8969)
# print(pg_views.loc[pg_views[user_id] == "USER_ce2d3de7e9e33ad160b2"])
# print(ind)


#apply would be faster but data requirements are trickier to handle
#less resource intensive in R with lapply to list
# ind = []

# for i, row in pg_views.iterrows():
#     user = row["user_id"]
#     vnum = row["visit_num"]
#     ind.append(check_visnums(user, vnum))

# ind = list(filter(lambda item: item is not None, ind))
# ind = list(chain.from_iterable(ind))
# ***WRITING OUTPUT TO FILE to avoid resource intensive procedures***

# print(ind)
# pg_views.iloc[ind].to_csv(os.getcwd()+'\\CTR_pageviews.csv', index=False)

#loading dataset for visits from homepage  
CTR_clicks = pd.read_csv("CTR_pageviews.csv").drop_duplicates()

#map_pos returns position number based on user view    
def map_pos(view_dt, pos_dt1, pos_dt2, pos):
    if pos_dt1 <= view_dt:
        if pos_dt2 >= view_dt:
            return pos
    else:
        print(view_dt, pos_dt1, pos_dt2, pos)
        return -1

## return 
#user view times
usr_viewsT = CTR_clicks["event_datetime_et"]
pos_list = []
for i, row in CTR_clicks.iterrows():
    temp = ar_pos.loc[(ar_pos["article_id"] == row["article_id"]) \
        & (row["event_datetime_et"] >= ar_pos["min_time_et"])\
        & (row["event_datetime_et"] <= ar_pos["max_time_et"]), "mobile_position"].tolist()
    pos_list.append(temp)
##revisiting the same article in same timeframe of location causing multiple impressions
pos_list =  list(chain.from_iterable(pos_list))
print(pos_list)
# print(type(temp))
views = len(pg_views.loc[pg_views["page_type"] == "Homepage"].drop_duplicates())

plt.hist(pos_list, weights=np.ones(len(pos_list)) / views, bins = range(0,max(pos_list),1), edgecolor = "black")

plt.gca().yaxis.set_major_formatter(PF(1))
plt.xlabel("Mobile Position")
plt.ylabel("CTR (%)")
plt.title("WSJ Clickthrough Rate 9/23/2023-9/30/2023")
plt.show()
