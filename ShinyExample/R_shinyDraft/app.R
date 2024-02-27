##Compile plotly and kmeans or PCA given an R or kaggle dataset
# 
# require(rsconnect)
# rsconnect::deployApp('path/to/your/app')
require(plotly)
require(tidyverse)
require(tidyclust)
library(stringr)
##theme darkly
## icon "circle-half-stroke"
library(shiny)
library(data.table)
library(shinydashboard)
library(shiny)
library(shinyWidgets)
#####UI
library(factoextra)
library(FactoMineR) 
library(ggplot2)
library(fresh)
load("poke_cleaned.Rdata")
ptypes <- c("All", unique(p$type1))
features <-  names(p)[sapply(p, function(x) class(x) %in% c("integer", "numeric"))]

hcpcPlot <- function(dat=p, x=p$P_speed, y = p$P_hp, z = p$P_base_total, nc = 3){
  features <-  names(dat)[sapply(dat, function(x) class(x) %in% c("integer", "numeric"))]
  
  p_pca<- PCA(dat[,features,with = F], ncp = 3, graph = FALSE)
  # Compute hierarchical clustering on principal components
  
  p_hcpc <- HCPC(p_pca, graph = FALSE)
  
  pclust <-p_hcpc$data.clust %>% 
    setnames(old = "clust", new = "PCA3_Cluster")
  
  kmeans_spec <- k_means(num_clusters = nc)
  kmeans_fit <- kmeans_spec %>%
    fit(~  . , data = p[,features, with = F])
  
  kmeans_summary <- kmeans_fit %>%
    extract_fit_summary()
  
  clustdat <- as.data.table(cbind(kmeans_summary$orig_labels, p)) %>% 
    setnames(old = "V1", new = "Cluster")
  
  
  mod <- cbind(dat,pclust$PCA3_Cluster, kmeans_summary$orig_labels) %>% 
    setnames(old = c("V2", "V3"), new = c("PCA3_Cluster", "K3Cluster"))
  
  mod$PCA3_Cluster = as.factor(mod$PCA3_Cluster)
  mod$K3Cluster = as.factor(mod$K3Cluster)
  x <- enquo(x)
  y <- enquo(y)
  z <- enquo(z)
  print(c(x, y, z))
  fig <- plot_ly(data = mod, x = x, y = y, z = z, color = ~PCA3_Cluster, 
                 colors = c('#BF382A', '#0C4B8E', "purple"),
                 marker = list(symbol = 'circle', sizemode = 'diameter', size = 5,
                               line = list(
                                 color = 'Black',
                                 width = 12
                               )),
                 text = ~paste('Name: ', name, '<br>Capture %: ', capture_rate, 
                               '<br>Abilities:', abilities,
                               '<br>Type:', type1),
                 hoverinfo = "text")
  
  fig <- fig %>% layout(scene = list(xaxis = list(title = 'PCA_1'),
                                     yaxis = list(title = 'PCA_2'),
                                     zaxis = list(title = 'PCA_3'),
                                     zerolinecolor = '#ffff', 
                                     showgrid=TRUE, 
                                     gridwidth=1,
                                     zerolinewidth = 2,
                                     gridcolor = 'MediumPurple'),
                        legend=list(title=list(text='<b> Groups (Click) </b>'),
                                    bgcolor = "#ac83e6",
                                    bordercolor = "gray",
                                    borderwidth = 2)) %>% 
    layout(plot_bgcolor='black') %>% 
    layout(paper_bgcolor='black')
  fig
}

ui <- pageWithSidebar(
  # setBackgroundColor("black"),
  headerPanel('Poke-Cluster: \n What makes a Pokemon hard/easy to catch?'),
  sidebarPanel(
    selectInput("ptype", "Pokemon Type", ptypes, selected = "All"),
    # selectInput('xcol', 'X Variable', features, selected = "P_speed"),
    # selectInput('ycol', 'Y Variable', features, selected = "P_hp"),
    # selectInput('zcol', 'Z Variable', features, selected = "P_base_total"),
    numericInput('clusters', 'Cluster count', 3, min = 1, max = 15),
      # setBackgroundColor("black")

  ),
  mainPanel(
    plotlyOutput('plot1', width = "800px", height = "720px")

  )
)
#####server
server <- function(input, output, session) {

 
  pselect <- reactive({
    as.data.table(list(p[type1 == input$ptype],
      p)[(input$ptype == "All") + 1])
 
    })
  
  clusters <- reactive({
    dat <- pselect()
    features <-  names(dat)[sapply(dat, function(x) class(x) %in% c("integer", "numeric"))]
    
    p_pca<- PCA(dat[,features,with = F], ncp = input$clusters, graph = FALSE)
    # Compute hierarchical clustering on principal components
    
    p_hcpc <- HCPC(p_pca, graph = FALSE,)
    
    pclust <-p_hcpc$data.clust %>% 
      setnames(old = "clust", new = "PCA3_Cluster")
    
    kmeans_spec <- k_means(num_clusters = input$clusters)
    kmeans_fit <- kmeans_spec %>%
      fit(~  . , data = dat[,features, with = F])
    
    kmeans_summary <- kmeans_fit %>%
      extract_fit_summary()
    
    mod <- cbind(dat,pclust$PCA3_Cluster, kmeans_summary$orig_labels) %>% 
      setnames(old = c("V2", "V3"), new = c("PCA3_Cluster", "K3Cluster"))
    
    mod$PCA3_Cluster = as.factor(mod$PCA3_Cluster)
    mod$K3Cluster = as.factor(mod$K3Cluster)
    
    
    fig <- plot_ly(data = mod, 
                   x = ~P_hp,
                   y = ~P_base_total, 
                   z = ~P_height_m, 
                   color = ~K3Cluster, 
                   colors = c('#BF382A', '#0C4B8E', "purple"),
                   marker = list(symbol = 'circle', sizemode = 'diameter', size = 5,
                                 line = list(
                                   color = 'Black',
                                   width = 12
                                 )),
                   text = ~paste('Name: ', name, '<br>Capture %: ', capture_rate, 
                                 '<br>Abilities: ', abilities,
                                 '<br>Type: ', type1),
                   hoverinfo = "text")
    fig <- fig %>% layout(scene = list(xaxis = list(title = 'PCA_1'),
                                       yaxis = list(title = 'PCA_2'),
                                       zaxis = list(title = 'PCA_3'),
                                       zerolinecolor = '#ffff', 
                                       showgrid=TRUE, 
                                       gridwidth=1,
                                       zerolinewidth = 2,
                                       gridcolor = 'MediumPurple'),
                          legend=list(title=list(text='<b> Groups (Click) </b>'),
                                      bgcolor = "#ac83e6",
                                      bordercolor = "gray",
                                      borderwidth = 2)) %>% 
      layout(plot_bgcolor  = "rgba(0, 0, 0, 0)",
             paper_bgcolor = "rgba(0, 0, 0, 0)")    
    
    fig
    
  })
  
 
  output$plot1 <- renderPlotly({clusters()})
  
}
#####
shinyApp(ui = ui, server = server)

