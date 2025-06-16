library(dplyr)
library(readr)
library(e1071)
library(Metrics)
library(ggplot2)
library(caret)

# Load models and scalers
model_list <- readRDS("svm_models.rds")
scaler_list <- readRDS("scalers.rds")

# Reload data (for test set generation)
data_folder <- "/Users/zona/Downloads/Model_svm/Preprocess"
csv_files <- list.files(path = data_folder, pattern = "*.csv", full.names = TRUE)
data_all <- lapply(csv_files, read_csv) %>% bind_rows()

# Add time features
data_all$datetime <- as.POSIXct(data_all$StartTime, format = "%Y-%m-%d %H:%M:%S")
data_all$hour <- as.numeric(format(data_all$datetime, "%H"))
data_all$weekday_num <- data_all$vd_week_day
data_all$weekday_sin <- sin(2 * pi * data_all$weekday_num / 7)
data_all$weekday_cos <- cos(2 * pi * data_all$weekday_num / 7)

# Road segment mapping (English version)
etag_name_map <- c(
  "01H0206S-01H0305S" = "Diding to Huanbei",
  "01H0305S-01H0334S" = "Huanbei to Wugu (Elevated)",
  "01H0271N-01H0208N" = "Wugu (Elevated) to Huanbei",
  "01H0208N-01H0200N" = "Huanbei to Xiata You Ramp",
  "01H0200N-01H0174N" = "Xiata You Ramp to Diding"
)
data_all$Segment <- etag_name_map[as.character(data_all$ETagPairID)]
data_all$VehicleType <- as.factor(data_all$VehicleType)

data_all <- data_all %>%
  select(ETagPairID, Segment, TravelTime, hour,
         weekday_num, weekday_sin, weekday_cos,
         VehicleType, SpaceMeanSpeed)

# Store performance results
perf_df <- data.frame()

# Scatter plot storage
scatter_plot_list <- list()

for (id in unique(data_all$ETagPairID)) {
  sub_data <- data_all %>% filter(ETagPairID == id)
  set.seed(123)
  train_index <- sample(1:nrow(sub_data), 0.8 * nrow(sub_data))
  test <- sub_data[-train_index, ]
  
  # Standardize
  scale_cols <- c("hour", "weekday_num", "weekday_sin", "weekday_cos", "SpaceMeanSpeed")
  scaler <- scaler_list[[as.character(id)]]
  test[, scale_cols] <- predict(scaler, test[, scale_cols])
  
  # Predict
  model <- model_list[[as.character(id)]]
  pred <- predict(model, newdata = test)
  
  # Metrics
  rmse_val <- rmse(test$TravelTime, pred)
  mae_val <- mae(test$TravelTime, pred)
  r2_val <- cor(test$TravelTime, pred)^2
  
  # Append to performance dataframe
  perf_df <- rbind(perf_df, data.frame(
    Segment = etag_name_map[id],
    RMSE = rmse_val,
    MAE = mae_val,
    R2 = r2_val
  ))
  
  # Scatter plot
  p <- ggplot(data.frame(Actual = test$TravelTime, Predicted = pred), aes(x = Actual, y = Predicted)) +
    geom_point(alpha = 0.4, color = "steelblue") +
    geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
    ggtitle(paste0("Scatter Plot: ", etag_name_map[id], "\nR² = ", round(r2_val, 2))) +
    xlab("Actual Travel Time (seconds)") + ylab("Predicted Travel Time (seconds)") +
    theme_minimal()
  
  scatter_plot_list[[etag_name_map[id]]] <- p
}

# Plot R² bar chart
ggplot(perf_df, aes(x = Segment, y = R2)) +
  geom_bar(stat = "identity", fill = "darkgreen") +
  ylim(0, 1) +
  ggtitle("Model Performance by Segment - R²") +
  ylab("R²") + xlab("Road Segment") +
  theme_minimal()

# Optional: show each scatter plot
for (name in names(scatter_plot_list)) {
  print(scatter_plot_list[[name]])
}
