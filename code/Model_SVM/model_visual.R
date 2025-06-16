library(dplyr)
library(readr)
library(e1071)
library(Metrics)
library(caret)

# 模型與 scaler 檔案名稱
model_file <- "svm_models.rds"
scaler_file <- "scalers.rds"

# 如果檔案存在就讀取，否則訓練並儲存
if (file.exists(model_file) & file.exists(scaler_file)) {
  cat("✅ 已讀取儲存模型，略過訓練步驟。\n")
  model_list <- readRDS(model_file)
  scaler_list <- readRDS(scaler_file)
} else {
  # 🚧 以下為訓練區塊
  cat("🔄 開始訓練模型...\n")
  
  # 讀資料
  data_folder <- "/Users/zona/Downloads/Model_svm/Preprocess"
  csv_files <- list.files(path = data_folder, pattern = "*.csv", full.names = TRUE)
  data_all <- lapply(csv_files, read_csv) %>% bind_rows()
  
  # 時間特徵
  data_all$datetime <- as.POSIXct(data_all$StartTime, format = "%Y-%m-%d %H:%M:%S")
  data_all$hour <- as.numeric(format(data_all$datetime, "%H"))
  data_all$weekday_num <- data_all$vd_week_day
  data_all$weekday_sin <- sin(2 * pi * data_all$weekday_num / 7)
  data_all$weekday_cos <- cos(2 * pi * data_all$weekday_num / 7)
  
  etag_name_map <- c(
    "01H0206S-01H0305S" = "堤頂-環北",
    "01H0305S-01H0334S" = "環北-五股(高架)",
    "01H0271N-01H0208N" = "五股(高架)-環北",
    "01H0208N-01H0200N" = "環北-下塔悠出口匝道",
    "01H0200N-01H0174N" = "下塔悠出口匝道-堤頂"
  )
  data_all$路段名稱 <- etag_name_map[as.character(data_all$ETagPairID)]
  data_all$VehicleType <- as.factor(data_all$VehicleType)
  
  data_all <- data_all %>%
    select(ETagPairID, 路段名稱, TravelTime, hour,
           weekday_num, weekday_sin, weekday_cos,
           VehicleType, SpaceMeanSpeed)
  
  model_list <- list()
  scaler_list <- list()
  road_ids <- unique(data_all$ETagPairID)
  
  for (id in road_ids) {
    sub_data <- data_all %>% filter(ETagPairID == id)
    set.seed(123)
    train_index <- sample(1:nrow(sub_data), 0.8 * nrow(sub_data))
    train <- sub_data[train_index, ]
    test <- sub_data[-train_index, ]
    
    scale_cols <- c("hour", "weekday_num", "weekday_sin", "weekday_cos", "SpaceMeanSpeed")
    scaler <- preProcess(train[, scale_cols], method = c("center", "scale"))
    train[, scale_cols] <- predict(scaler, train[, scale_cols])
    test[, scale_cols] <- predict(scaler, test[, scale_cols])
    scaler_list[[as.character(id)]] <- scaler
    
    tuned <- tune(
      svm,
      TravelTime ~ hour + weekday_num + weekday_sin + weekday_cos + VehicleType + SpaceMeanSpeed,
      data = train,
      ranges = list(cost = 2^(-1:2), gamma = 2^(-2:1))
    )
    model <- tuned$best.model
    model_list[[as.character(id)]] <- model
    
    pred <- predict(model, newdata = test)
    rmse_val <- rmse(test$TravelTime, pred)
    mae_val <- mae(test$TravelTime, pred)
    r2_val <- cor(test$TravelTime, pred)^2
    
    cat(paste0("路段: ", etag_name_map[id], "\n"))
    cat(paste0("RMSE = ", round(rmse_val, 3), ", MAE = ", round(mae_val, 3), ", R² = ", round(r2_val, 3), "\n\n"))
  }
  
  # 儲存模型與 scaler
  saveRDS(model_list, model_file)
  saveRDS(scaler_list, scaler_file)
  cat("💾 模型與 scaler 已儲存。\n")
}
