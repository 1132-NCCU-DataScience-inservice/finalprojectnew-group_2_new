library(dplyr)
library(ggplot2)
library(readr)
library(corrplot)
library(lubridate)
library(fastDummies)
library(DescTools)

data <- list.files(path = "Preprocess/", full.names = T) %>%
  lapply(read_csv) %>%
  bind_rows

summary(data)

holidays <- read.csv("holidays_2025.csv", header = T)[["Date"]]
data$DateTime <- ymd_hms(substr(data$UpdateTime, 1, 19))
data <- data[!is.na(data$DateTime), ]

data$Date <- substr(data$UpdateTime, 1, 10)
data$Hour <- as.numeric(hour(data$DateTime))
data$Hour_sin <- sin(2 * pi * data$Hour / 24)
data$Hour_cos <- cos(2 * pi * data$Hour / 24)
data$IsHoliday <- ifelse(data$vd_week_day %in% c(6, 7),
                         T,
                         is.element(data$Date, holidays))
data$IsHoliday <- as.numeric(data$IsHoliday)
data$weekday_sin <- sin(2 * pi * data$vd_week_day / 7)
data$weekday_cos <- cos(2 * pi * data$vd_week_day / 7)

data$VehicleType <- as.factor(data$VehicleType)

data[is.na(data$temp), 'temp'] <- mean(data$temp, na.rm = T)
data[is.na(data$rain), 'rain'] <- mean(data$rain, na.rm = T)

data <- data %>%
  select(
    ETagPairID,
    TravelTime,
    weekday_sin,
    weekday_cos,
    Hour_sin,
    Hour_cos,
    VehicleType,
    SpaceMeanSpeed,
    rain,
    temp,
    IsHoliday
  )

model_list <- list()
road_ids <- unique(data$ETagPairID)

model <- glm(
  TravelTime ~ ETagPairID + Hour_sin + Hour_cos + weekday_sin + weekday_cos + VehicleType + IsHoliday
  data,
  family = Gamma(link = "log")
)
pseudo_r2 <- 1 - (model$deviance / model$null.deviance)
cat('Pseudo-R^2: ', pseudo_r2)
saveRDS(model, 'models/model.rds')

# for (id in road_ids) {
#   sub_data <- data %>% filter(ETagPairID == id)
#   
#   model <- glm(
#     TravelTime ~ Hour_sin + Hour_cos + weekday_sin + weekday_cos + VehicleType + IsHoliday,
#     data = sub_data,
#     family = Gamma(link = "log")
#   )
#   model_list[[as.character(id)]] <- model
# 
#   print(1 - (model$deviance / model$null.deviance))
#   saveRDS(model, paste0('models/', id, '.rds'))
# }

predictions <- predict(model, newdata = data, type = "response")
comparison <- data.frame(Actual = data$TravelTime, Predicted = predictions)
