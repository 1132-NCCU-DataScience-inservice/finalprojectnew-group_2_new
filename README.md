[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/ZXf3Hbkv)
# [Group_2] 國道車流行為 AI 分析與應用
The goals of this project.
預測國道特定路段未來的旅程時間（Travel Time）
利用 AI 模型，分析各種可能影響車流行為的因子
## Contributors
|組員|系級|學號|工作分配|
|-|-|-|-|
|王雅麗|資科碩專一|113971009|資料擷取ETagID、資料預處理、Random Forest模型訓練、簡報主講人|
|謝叔容|資科碩專一|113971010|資料擷取ETagID、投影片製作、SVM模型訓練|
|林才樞|資科碩專一|113971018|資料擷取VD、ShinyApp製作、GLM模型訓練|
|李嘉境|資科碩專一|113971014|資料擷取weather、README製作、Decision Tree模型訓練|

## Quick start
Please provide an example command or a few commands to reproduce your analysis, such as the following R script:
```R
Rscript code/your_script.R --input data/training --output results/performance.tsv
```

## Folder organization and its related description
idea by Noble WS (2009) [A Quick Guide to Organizing Computational Biology Projects.](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1000424) PLoS Comput Biol 5(7): e1000424.

### docs
* Your presentation, 1132_DS-FP_groupID.ppt/pptx/pdf (i.e.,1132_DS-FP_group1.ppt), by **06.10**
* Any related document for the project, i.e.,
* discussion log
  * 4月26日 會議討論：
    * 網路爬蟲資料擷取分工與程式撰寫
  * 5月01日 會議討論：
    * 資料收集欄位確定、專案目標訂定：旅行時間長度預測
  * 5月17日 會議討論：
    * APP選單資料統一格式
    預測模型決定與分工
  * 5月20日 會議討論：
    * 資料欄位對齊與預處理方式
  * 5月27日 會議討論：
    * 訂定專案產出時程
  * 6月04日 會議討論：
    * 訂定APP使用者介面選單
  * 6月15日 會議討論：
    * 簡報呈現內容以及報告角色分配
* software user guide

### data
* 交通部高速公路局開放資料
  * Source: https://freeway2025.tw/
  * Format: JSON, CSV
  * Size: 依下載範圍，約數千~數十萬筆資料
* 中央氣象局氣象開放平台
  * Source: https://opendata.cwa.gov.tw/index
  * Format: JSON, CSV
  * Size: 依下載範圍，約數千~數十萬筆資料
* 主要欄位：
  * ETagPairID, StartTime, VehicleType, VehicleCount,
  SpaceMeanSpeed, vd_avg_Speed, vd_avg_Occupancy, vd_avg_Volume,
  vd_avg_VSpeed, vd_LaneID, vd_week_day, rain, temp, TravelTime
* 預處理重點：
  * 缺失值補齊
  * 異常值排除
  * 特徵工程
  * 欄位資料型態編碼轉換
  * 時間對齊

### code
* Analysis steps
  #####  1.載入資料
  #####  2.前處理
  #####  3.訓練/測試集切分
  #####  4.各類機器學習模型訓練（Decision Tree, Random Forest, SVM, GLM）
  #####  5.指標計算與可視化（R²、MAE、RMSE、MSE）
  #####  6.圖表/模型檔輸出
* Which method or package do you use?
  * Decision Tree
  * Random Forest
  * SVM
  * GLM
* How do you perform training and evaluation?
  * 以訓練/測試分割，部分模型可加交叉驗證
* What is a null model for comparison?

### results
* What is your performance?

||Random Forest|Decision Tree|SVM|GLM|
|-|-|-|-|-|
|MSE|2121.297|1999.2347|15482.44|9330.017|
|RMSE|46.05754|44.7128|29.01408|96.59201|
|MAE|26.32841|21.5637|7.896077|40.23153|
|Pseudo-R^2|0.934948|0.9369|0.9768|0.9078|

* Is the improvement significant?

## References
* Packages you use
  * dplyr, readr, stringr, lubridate, caret, rpart, rpart.plot, ggplot2, data.table, Matrix, corrplot,e1071, randomForest, fastDummies, DescTools, shiny, bslib, shinythemes, shinyTime, formattable
* Related publications
  * 交通部高速公路局交通資料庫、中央氣象局氣象開放平台
