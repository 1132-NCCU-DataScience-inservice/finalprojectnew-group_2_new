# 載入必要套件
library(randomForest)
library(dplyr)
library(readr)

# ...existing code...
# 讀取 preprocess 資料夾內所有 CSV 檔案並合併
file_list <- list.files("preprocess", pattern = "\\.csv$", full.names = TRUE)
data_list <- lapply(file_list, read_csv)
data <- bind_rows(data_list)
# ...existing code...

# 處理StartTime，只保留時分秒
data$StartTime <- substr(data$StartTime, 12, 19)
data$StartTime <- paste0(substr(data$StartTime, 1, 2), ":00:00")

# 選擇特徵x與目標y
x_vars <- c("StartTime", "VehicleType", "VehicleCount", "SpaceMeanSpeed",
            "vd_avg_Speed", "vd_avg_Occupancy", "vd_avg_Volume", "vd_avg_VSpeed",
            "vd_LaneID", "vd_week_day", "rain", "temp")
y_var <- "TravelTime"

df <- data %>% select(all_of(c(x_vars, y_var)))

# 將必要欄位轉為factor
df$StartTime <- as.factor(df$StartTime)
df$VehicleType <- as.factor(df$VehicleType)
df$vd_LaneID <- as.factor(df$vd_LaneID)
df$vd_week_day <- as.factor(df$vd_week_day)

# 分割訓練與測試資料
set.seed(123)
train_idx <- sample(seq_len(nrow(df)), size = 0.8 * nrow(df))
train_data <- df[train_idx, ]
test_data <- df[-train_idx, ]

train_data <- na.omit(train_data)
test_data <- na.omit(test_data)

# 建立Random Forest模型
rf_model <- randomForest(
    TravelTime ~ .,
    data = train_data,
    ntree = 100,
    importance = TRUE
)
saveRDS(rf_model, file = "rf_model100.rds")
# 預測與評估
pred <- predict(rf_model, test_data)
mse <- mean((pred - test_data$TravelTime)^2)
rmse <- sqrt(mse)
mae <- mean(abs(pred - test_data$TravelTime))
cat("Test MSE:", mse, "\n")
cat("Test RMSE:", rmse, "\n")
cat("Test MAE:", mae, "\n")

# 計算Pseudo-R²
SSE <- sum((pred - test_data$TravelTime)^2)
SST <- sum((test_data$TravelTime - mean(test_data$TravelTime))^2)
pseudo_R2 <- 1 - SSE/SST
cat("Pseudo-R²:", pseudo_R2, "\n")

# 顯示特徵重要性
imp <- importance(rf_model)
imp_df <- data.frame(
  Feature = rownames(imp),
  Importance = imp[, 1]
)

# 視覺化預測結果與實際值
library(ggplot2)

result_df <- data.frame(
  Actual = test_data$TravelTime,
  Predicted = pred
)

ggplot(result_df, aes(x = Actual, y = Predicted)) +
  geom_point(alpha = 0.5) +
  geom_abline(slope = 1, intercept = 0, color = "red") +
  labs(title = "Random Forest 預測 vs 實際", x = "實際值", y = "預測值") +
  theme_minimal()

# 視覺化特徵重要性
ggplot(imp_df, aes(x = reorder(Feature, Importance), y = Importance)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(title = "各特徵對 TravelTime 的重要性", x = "特徵", y = "重要性") +
  theme_minimal()

ggplot(df, aes(x = vd_week_day, y = TravelTime)) +
  geom_boxplot(fill = "lightgreen", outlier.shape = NA) +
  coord_cartesian(ylim = quantile(df$TravelTime, c(0.05, 0.95), na.rm = TRUE)) +
  labs(title = "vd_week_day 與 TravelTime 的關係", x = "星期幾 (vd_week_day)", y = "TravelTime") +
  theme_minimal()

ggplot(df, aes(x = vd_LaneID, y = TravelTime)) +
  geom_boxplot(fill = "skyblue", outlier.shape = NA) +
  coord_cartesian(ylim = quantile(df$TravelTime, c(0.05, 0.95), na.rm = TRUE)) +
  labs(title = "vd_LaneID 對 TravelTime 的關係", x = "vd_LaneID", y = "TravelTime") +
  theme_minimal()

# 篩選早上7點到晚上8點的資料
df_sub <- df[df$StartTime >= "07:00:00" & df$StartTime <= "20:00:00", ]

ggplot(df_sub, aes(x = vd_LaneID, y = TravelTime)) +
  geom_boxplot(fill = "skyblue", outlier.shape = NA) +
  coord_cartesian(ylim = quantile(df_sub$TravelTime, c(0.05, 0.95), na.rm = TRUE)) +
  labs(title = "vd_LaneID 對 TravelTime（07:00~20:00）", x = "vd_LaneID", y = "TravelTime") +
  theme_minimal()
