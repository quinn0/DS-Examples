require(shiny)
require(shinythemes)
require(flexdashboard)
require(plotly)
##under construction but welcome to run the dashboard. 

# http://hrbrmstr.github.io/metricsgraphics/
#   

#########Parameters################
# y float length to FF
# inc float annual take home after taxes (not salary!)
# curBill float current expenses
# desBill desired expenses
# curInv sum(investments) "4"01k, IRA, "4"03b, ETFs

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
  sidebarLayout(sidebarPanel(wellPanel(
    fluidRow(textAreaInput(inputId = "Income",
                               label = "Takehome Income:",
                              value = "(Annual After Taxes)",
                           width = '60%')
                          ),
    fluidRow(textAreaInput(inputId = "Expenses",
                            label = "Total Expenses:",
                            value = "Expense budget for year",
                            width = '60%'),
                         ),
    
    fluidRow(textAreaInput(inputId = "Investments",
                            label = "Total Investments:",
                            value = "Total value of investments",
                             width = '60%'),
                        ),
    
    
    fluidRow(textAreaInput(inputId = "FFYears",
                            label = "Years To Financial Freedom:",
                            value = "40",
                           width = '60%'),
                      ),
                ),
                submitButton(text = "Calculate!"),
      position = "left",
      fluid = TRUE),
                mainPanel(fluidRow(textInput("inputId", " ")),
                         fluidRow(textInput("inputId1", " ")),
                          plotOutput("circleGraph"),
                          # fluidRow(textInput("inputId1", " "))
                          )
  )
)

server <- function(input, output) {
  output$circleGraph <- renderPlot({
    tibble(theta=seq(0, 2*pi, 0.025), 
           x= 100*log(as.numeric(input$FFYears)) * sin(theta), 
           y=100*log(as.numeric(input$FFYears)) * cos(theta)) %>%   
      ggplot(aes(x, y)) +
      geom_path() +
      coord_fixed() +
      theme_void()
  },
  height=150, ## radius = parameter of interest
  width=150)


}

shinyApp(ui = ui, server = server)
