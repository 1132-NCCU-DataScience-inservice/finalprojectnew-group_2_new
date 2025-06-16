### ===== 1. 載入必要套件 =====
suppressPackageStartupMessages({
  library(dplyr)        # 資料處理與資料整理，進行過濾、排序、分組等操作（類似 Python 的 pandas）
  library(readr)        # 讀取與寫入 CSV、TSV 等純文字資料檔案，速度快、語法簡單
  library(stringr)      # 字串處理，提供一致且強大的字串操作函數（如搜尋、取代、分割等）
  library(lubridate)    # 處理日期與時間資料，讓時間欄位格式轉換、運算、比較變得簡單
  library(caret)        # 統一的機器學習流程框架，支援特徵選取、交叉驗證、訓練多種模型
  library(rpart)        # 建立決策樹模型，可用於分類（Classification）與回歸（Regression）
  library(rpart.plot)   # 繪製 rpart 套件產生的決策樹圖形，讓模型結構可視化
  library(ggplot2)      # 最有名的繪圖套件，專門製作高質感統計圖、資料視覺化
  library(data.table)   # 高效能資料表處理，處理大資料集速度非常快（類似進階版 data.frame）
  library(Matrix)       # 處理稀疏矩陣（大量零值的矩陣），常見於機器學習特徵工程
  library(corrplot)     # 畫出相關係數矩陣的相關圖（Correlation Plot），用於變數關聯分析
})
### ===== 2. 讀取與前處理資料 =====
# 設定檔案路徑
data_dir <- "processed_data_with_dummies.csv"
# 顯示檔案基本資料
message("讀取資料檔案: ", data_dir)
# 讀取資料
all_data <- fread(data_dir, encoding = "UTF-8")
# 回報讀取資料的基本資訊
message("資料已讀取，共 ", nrow(all_data), " 筆資料，包含 ", ncol(all_data), " 欄位")

### ===== 3. 建立決策樹模型 =====
set.seed(123)  # 設定隨機種子

# 取出 target 與 features
target <- all_data$TravelTime               # 預測目標
features <- all_data %>% select(-TravelTime)  # 其他欄位為特徵

# 分割資料集
train_idx <- createDataPartition(all_data$TravelTime, p = 0.8, list = FALSE)  # 取得訓練集 index
train_data <- all_data[train_idx, ]      # 訓練集資料
test_data <- all_data[-train_idx, ]      # 測試集資料

# 建立決策樹模型（回歸任務）
tree_model <- rpart(TravelTime ~ .,      # 公式：預測 TravelTime，其餘為自變數
                    data = train_data,   # 用訓練集資料
                    method = "anova",    # 回歸用 anova
                    control = rpart.control(maxdepth = 20, cp = 0.0001, minsplit = 2))  # 控制樹結構
# minsplit: 最小分割數量，控制樹的複雜度
# 模型訓練完成
# 儲存模型
saveRDS(tree_model, file = "decision_tree_model.rds")  # 儲存模型到檔案

message("決策樹模型訓練完成，已準備好進行預測")

### ===== 4. 預測與模型評估 =====
# 用測試集特徵資料預測
predictions <- predict(tree_model, newdata = test_data)  # 得到連續數值預測

# 顯示前10筆預測結果
message("預測結果:")
print(head(predictions, 10))  # 前10筆預測

# 顯示前10筆實際值
message("實際值:")
print(head(test_data$TravelTime, 10))

# 合併實際與預測
comparison <- data.frame(Actual = test_data$TravelTime, Predicted = predictions)
message("預測與實際值比較:")
print(head(comparison, 10))

# 計算模型評估指標（回歸用指標）
message("計算模型評估指標...")

# 計算 R-squared
ss_res <- sum((test_data$TravelTime - predictions)^2)         # 殘差平方和
ss_tot <- sum((test_data$TravelTime - mean(test_data$TravelTime))^2)  # 總平方和
r_squared <- 1 - ss_res / ss_tot
# 計算seudo R-squared
pseudo_r_squared <- 1 - (ss_res / ss_tot)

# 回報 R-squared
message("R-squared: ", round(r_squared, 4))
# 計算 RMSE
rmse <- sqrt(mean((predictions - test_data$TravelTime)^2))
# 計算 MAE
mae <- mean(abs(predictions - test_data$TravelTime))
# 計算 MSE
mse <- mean((predictions - test_data$TravelTime)^2)

# 回報模型評估結果
message("模型評估結果:")
message("R-squared: ", round(r_squared, 4))
message("Pseudo R-squared: ", round(pseudo_r_squared, 4))
message("RMSE: ", round(rmse, 4))
message("MAE: ", round(mae, 4))
message("MSE: ", round(mse, 4))

### ===== 5. 繪製決策樹視覺化 =====
# 繪製決策樹
rpart.plot(tree_model, 
           main = "決策樹模型結構", 
           extra = 101,  # 顯示節點預測值與樣本數
           fallen.leaves = TRUE,  # 讓葉節點在底部
           type = 3,  # 顯示節點類型
           box.palette = "RdYlGn",  # 節點顏色
           shadow.col = "gray")  # 陰影顏色
# 設定輸出圖檔名稱
output_path <- "decision_tree_plot.png"

# 用 png() 開啟圖檔寫入，接著呼叫 rpart.plot 畫圖，最後 dev.off() 關閉圖檔
png(output_path, width = 1000, height = 800, res = 120)
rpart.plot::rpart.plot(tree_model,            # 你的 rpart 決策樹物件名稱，需與前面一致
                       type = 3,              # 選擇樹的型態
                       extra = 101,           # 顯示節點資訊
                       fallen.leaves = TRUE,  # 樹葉下墜
                       box.palette = "RdYlGn",# 色帶
                       shadow.col = "gray")   # 陰影
dev.off()
message("儲存決策樹圖檔到：", output_path)


# 繪製決策樹的特徵重要性
importance <- tree_model$variable.importance
importance_df <- data.frame(Feature = names(importance), Importance = importance)
importance_df <- importance_df %>%
  arrange(desc(Importance))  # 按重要性排序
# 繪製特徵重要性圖
ggplot(importance_df, aes(x = reorder(Feature, Importance), y = Importance)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +  # 水平條形圖
  labs(title = "特徵重要性", x = "特徵", y = "重要性") +
  theme_minimal()
# 儲存特徵重要性圖形
importance_output_path <- "feature_importance_plot.png"
ggsave(importance_output_path, width = 10, height = 6, dpi = 300)
# 回報儲存特徵重要性圖形的路徑
message("特徵重要性圖形已儲存至: ", importance_output_path)

# # 繪製預測值 vs 實際值的散佈圖
ggplot(data = comparison, aes(x = Actual, y = Predicted)) +
  geom_point(alpha = 0.5, color = "blue") +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  labs(title = "預測值 vs 實際值", x = "實際值", y = "預測值") +
  theme_minimal() +
  xlim(0, max(test_data$TravelTime, na.rm = TRUE)) +
  ylim(0, max(test_data$TravelTime, na.rm = TRUE))
# 儲存預測值 vs 實際值的散佈圖
scatter_output_path <- "predicted_vs_actual_scatter.png"
ggsave(scatter_output_path, width = 10, height = 6, dpi = 300)
# 回報儲存預測值 vs 實際值的散佈圖的路徑
message("預測值 vs 實際值的散佈圖已儲存至: ", scatter_output_path)

# 繪製殘差圖
residuals <- test_data$TravelTime - predictions
ggplot(data = data.frame(Actual = test_data$TravelTime, Residuals = residuals), aes(x = Actual, y = Residuals)) +
  geom_point(alpha = 0.5, color = "blue") +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  labs(title = "殘差圖", x = "實際值", y = "殘差") +
  theme_minimal() +
  xlim(0, max(test_data$TravelTime, na.rm = TRUE)) +
  ylim(min(residuals, na.rm = TRUE), max(residuals, na.rm = TRUE))
# 儲存殘差圖
residuals_output_path <- "residuals_plot.png"
ggsave(residuals_output_path, width = 10, height = 6, dpi = 300)
# 回報儲存殘差圖的路徑
message("殘差圖已儲存至: ", residuals_output_path)

