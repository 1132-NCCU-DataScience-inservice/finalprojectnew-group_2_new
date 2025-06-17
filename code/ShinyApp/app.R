library(shiny)
library(bslib)
library(shinythemes)
library(shinyTime)
library(lubridate)
library(formattable)

# 國定假日2025
holidays <- read.csv("holidays_2025.csv", header = T)[["Date"]]
# 路段代碼
sections <- c(
  "堤頂-環北" = "01H0206S-01H0305S",
  "環北-五股(高架)" = "01H0305S-01H0334S",
  "五股(高架)-環北" = "01H0271N-01H0208N",
  "環北-下塔悠出口匝道" = "01H0208N-01H0200N",
  "下塔悠出口匝道-堤頂" = "01H0200N-01H0174N"
)
# 車種
vehicle_types <- c(
  "小客車" = 31,
  "小貨車" = 32,
  "大客車" = 41,
  "大貨車" = 42,
  "聯結車" = 5
)

ui <- fluidPage(navbarPage(
  "GLM行程預測",
  theme = shinytheme("cerulean"),
  navset_card_underline(sidebarLayout(
    sidebarPanel(
      fluidRow(column(
        9, dateInput("date", "日期", value = Sys.time())
      )),
      fluidRow(column(
        9, timeInput("time", "時間", seconds = F, value = Sys.time())
      )),
      fluidRow(column(
        9, selectInput("section", "路段", choices = sections)
      )),
      fluidRow(column(
        9, selectInput("vehicleType", "車種", choices = vehicle_types)
      )),
      hr(),
      fluidRow(column(6, actionButton("submit", "預測")))
    ),
    mainPanel(fluidRow(column(9, h3(
      textOutput("result")
    ))))
  ))
))

server <- function(input, output, session) {
  observeEvent(input$submit, {
    req(input$date, input$time, input$section, input$vehicleType)
    
    datetime <-  ymd_hms(paste0(input$date, " ", substr(input$time, 12, 19)))
    
    weekday <- wday(datetime) - 1
    hour <- as.numeric(hour(datetime))
    is_holiday <- as.numeric(ifelse(weekday %in% c(6, 7), T, is.element(input$date, holidays)))
    weekday_sin <- sin(2 * pi * weekday / 7)
    weekday_cos <- cos(2 * pi * weekday / 7)
    hour_sin <- sin(2 * pi * hour / 24)
    hour_cos <- cos(2 * pi * hour / 24)
    
    predict_input <- data.frame(
      ETagPairID = input$section,
      weekday_sin = weekday_sin,
      weekday_cos = weekday_cos,
      Hour_sin = hour_sin,
      Hour_cos = hour_cos,
      VehicleType = input$vehicleType,
      IsHoliday = is_holiday
    )
    # model <- readRDS(paste0("models/", input$section, ".rds"))
    model <- readRDS("models/model.rds")
    
    pred_time <- predict(model, newdata = predict_input, type = "response")
    
    output$result <- renderText({
      paste0("預估行程時間: ", accounting(pred_time), "秒")
    })
  })
  
}

shinyApp(ui = ui, server = server)
