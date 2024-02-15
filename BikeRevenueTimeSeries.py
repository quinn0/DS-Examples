# %% [markdown]
# 1.0 Load Libraries ----
# # Core Python Data Analysis


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Plotting
from plotnine import( 
    ggplot, aes, geom_col,
    geom_line, geom_smooth,
    facet_wrap, scale_y_continuous,
    scale_x_datetime, labs, theme,
    theme_minimal, theme_matplotlib,
    expand_limits, element_text,
    element_blank, element_rect,
    element_line, theme_seaborn
)

from mizani.breaks import date_breaks
from mizani.formatters import date_format, currency_format


# Misc
from os import mkdir, getcwd
from rich import pretty #format temrinal output nice
pretty.install() #just workspace



# 2.0 Importing Data Files ----
# help(pd.read_excel)
# help(pd.read_excel)
# - Use "q" to quit
bikes_df = pd.read_excel("Mod0/00_data_raw/bikes.xlsx")
bikeshops_df = pd.read_excel("Mod0/00_data_raw/bikeshops.xlsx")
orderlines_df = pd.read_excel(
    io ="Mod0/00_data_raw/orderlines.xlsx",
    converters= {'order.date' : str} )


# 3.0 Examining Data ----
# orderlines_df.head()
bikeshops_df.head()

top5_bikes_series = bikes_df['description'].\
    value_counts().\
        nlargest(4).\
            sort_values()
fig = top5_bikes_series.plot(kind = "barh")
fig.invert_yaxis()
plt.show()
# 4.0 Joining Data ----
bike_orders_df = orderlines_df.\
    drop(columns= "Unnamed: 0").\
    merge(right = bikes_df, 
        how = "left",
        left_on = "product.id",
        right_on = "bike.id").\
    merge(right = bikeshops_df,
          how = "left",
          left_on = "customer.id",
          right_on = "bikeshop.id")
    


df = bike_orders_df.copy()
df["order.date"] = pd.to_datetime(df["order.date"])
df.T
# "Mountain - Over Mountain - Carbon".split(" - ")
temp_df = df['description'].str.split(pat = " - ", expand= True)

df['terrain'] = temp_df[0]
df['terrain2'] = temp_df[1]
df['frame_material'] = temp_df[2]
temp_df = df['location']\
    .str.split(pat = ", ", expand= True)
    
df['city'] = temp_df[0]
df['state'] = temp_df[1]

# * Price Extended
df['total_price'] = df['quantity']*df['price']

df.sort_values("total_price", ascending= False)

# * Reorganizing
keep_ls = ['order.id', 
'order.line', 
'order.date', 
'product.id',
'quantity', 
'price',
'total_price',
'model', 
'description',
'bikeshop.name', 
'location', 
'terrain', 
'terrain2', 
'frame_material']

df  =df[keep_ls]

# 'order.date'.replace(".","_")

df.columns = df.columns.str.replace(".", "_")
bike_orders_clean_df = df
# %%
# %%
df = pd.read_pickle("00_data_wrangled/bike_orders_clean_df.pkl")
# 6.1 Total Sales by Month ----
order_totals_df = df[['order_date', 'total_price']]

sales_by_month_df = order_totals_df.set_index('order_date')\
                .resample(rule = "MS")\
                .aggregate(np.sum)\
                .reset_index()
#MS = Month Start Y, YS, M, MS
## ALLL OFFSET ALIASES
# https://pandas.pydata.org/pandas-docs/stable/user_guide/timeseries.html#offset-aliases

# Quick Plot ----
sales_by_month_df.plot(x = 'order_date', y = 'total_price')
# plt.show()
# %%
# Report Plot ----
# %%
usd = currency_format(prefix = "$", digits= 0 , big_mark= ',')
ggplot(aes(x = 'order_date',
           y = 'total_price'), 
        data = sales_by_month_df) + \
    geom_line() + \
    geom_smooth(method = "lowess", 
                span = .2, 
                color = "#600080")+ \
    scale_y_continuous(labels = usd) + \
    labs(title = "Revenue by Month", 
         x = "",
         y = "Revenue") + \
    expand_limits(y = 0)
            

sales_by_month_df = df[["terrain2", "order_date", "total_price"]]\
    .set_index("order_date")\
    .groupby('terrain2') \
    .resample(rule = "MS")\
    .agg(func = {'total_price' : np.sum}) \
    .reset_index()

# %%
# Step 2 - Visualize ----
ggplot(aes(x = 'order_date',
           y = 'total_price'), 
        data = sales_by_month_df) + \
    geom_line() + \
    geom_smooth(method = "lowess", 
                span = .1, 
                color = "#600080")+ \
    scale_y_continuous(labels = usd) + \
    labs(title = "Revenue by Month", 
         x = "",
         y = "Revenue") + \
    expand_limits(y = 0) 

# Simple Plot
# sales_by_month_df
# df
# weekly_price_terrain2_df
# sales_by_month_df.T

sales_by_month_df \
    .pivot(index = 'order_date',
           columns = 'terrain2',
           values = 'total_price'
        )\
    .fillna(0)\
    .plot(kind = 'line', 
          subplots = True,
          layout = (3,3))

plt.show()
# Reporting Plot
ggplot(mapping=aes(x = 'order_date', 
           y = "total_price"), 
           #color = 'terrain2'),#'terrain2'
       data = sales_by_month_df) + \
    geom_line(color = "#2c3e50", size = 1.5) +\
    geom_smooth(method = "lm", se = False, color = "#600080") + \
    facet_wrap(facets = "terrain2",
               ncol=3,
               scales= "free_y") + \
    theme_minimal() + \
    theme(subplots_adjust = {"wspace" : 0.25}) +\
    theme(axis_text_x= element_text(angle = 55, 
                                    hjust = .5,
                                    size = 6.8),
          axis_text_y= element_text(size = 6.8)) +\
    scale_y_continuous(labels = usd)  +\
    scale_x_datetime(breaks = date_breaks("6 months"),
                     labels = date_format("%Y-%m")) +\
    expand_limits(y = 0) +\
    labs(title = "Monthly Bike Revenue",
         x = "",
         y = "Revenue")


# 7.0 Writing Files ----


# Pickle ----

df.to_pickle("00_data_wrangled/bike_orders_clean_df.pkl")
# CSV ----

df.to_csv("00_data_wrangled/bike_orders_clean_df.csv")
# Excel ----
df.to_excel("00_data_wrangled/bike_orders_clean_df.xlsx")


# WHERE WE'RE GOING
# - Building a forecast system
# - Create a database to host our raw data
# - Develop Modular Functions to:
#   - Collect data
#   - Summarize data and prepare for forecast
#   - Run Automatic Forecasting for One or More Time Series
#   - Store Forecast in Database
#   - Retrieve Forecasts and Report using Templates


# %%
