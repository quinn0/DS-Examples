require(shiny)
require(shinythemes)
require(flexdashboard)
require(plotly)
data(airquality)
# http://hrbrmstr.github.io/metricsgraphics/
#   
#   MetricsGraphics enables easy creation of D3 scatterplots, line charts, and histograms.
# 
# library(metricsgraphics)
# mjs_plot(mtcars, x=wt, y=mpg) %>%
#   mjs_point(color_accessor=carb, size_accessor=carb) %>%
#   mjs_labs(x="Weight of Car", y="Miles per Gallon")
#########Parameters################
# y float length to FF
# inc float annual take home after taxes (not salary!)
# curBill float current expenses
# desBill desired expenses
# curInv sum(investments) 401k, IRA, 403b, ETFs

############### Design ####################
# every parameter should be a togglable
# whichever parameter is not entered becomes 
###  becomes the visualized output 
#########Visualized by: 
######### expanding circle with parameter label and output. 
######### colored by magnitude
#feasible regions? must understand equation better (non linear)
# Define UI for app that draws a histogram ----
ui <- fluidPage(
  titlePanel("Financial Freedom Calculator"),
  sidebarLayout(sidebarPanel(
                  sliderInput(inputId = "Income",
                               label = "Takehome Income (After Tax):",
                               min = 1,
                               max = 10,
                               value = 1),
                sliderInput(inputId = "Expenses",
                            label = "Expenses:",
                            min = 1,
                            max = 10,
                            value = 1),
                sliderInput(inputId = "Investments",
                            label = "Total Investments:",
                            min = 1,
                            max = 10,
                            value = 1),
                sliderInput(inputId = "FFYears",
                            label = "Years To Financial Freedom:",
                            min = 1,
                            max = 10,
                            value = 1)
                ),
                mainPanel(fluidRow(textInput("inputId", " ")),
                         fluidRow(textInput("inputId1", " ")),
                          plotOutput("circleGraph"),
                          # fluidRow(textInput("inputId1", " "))
                          )
  )
)

# Define server logic required to draw a histogram ----
server <- function(input, output) {
  output$circleGraph <- renderPlot({
    tibble(theta=seq(0, 2*pi, 0.025), 
           x=sin(theta), 
           y=cos(theta)) %>%   
      ggplot(aes(x, y)) +
      geom_path() +
      coord_fixed() +
      theme_void()
  },
  height=150, ## radius = parameter of interest
  width=150)

  # output$distPlot <- renderPlot({
  #   
  #   x    <- airquality$Ozone
  #   x    <- na.omit(x)
  #   bins <- seq(min(x), max(x), length.out = input$bins + 1)
  #   
  #   hist(x, breaks = bins, col = "#75AADB", border = "black",
  #        xlab = "Ozone level",
  #        main = "Histogram of Ozone level")
  #   
  # })
  
}

# Create Shiny app ----
shinyApp(ui = ui, server = server)
