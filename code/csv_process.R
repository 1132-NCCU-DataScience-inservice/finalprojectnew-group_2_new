# 讀取csv檔
etag_link_transaction <- read.csv("etag_link_transaction.csv",header = FALSE)
for (date in list.dirs("DB", recursive = FALSE)) {
  # 若Date資料夾裡沒有3個檔案則跳過
  if (length(list.files(date))!=3) next
  etag_data <- read.csv(paste0(date,"/ETag_",gsub("DB/", "", date),".csv"))
  temperature_data <- read.csv(paste0(date,"/temperature_",gsub("DB/", "", date),".csv"))
  vd_data <- read.csv(paste0(date,"/VDLive_",gsub("DB/", "", date),".csv"))
  
  # 處理temperature(同個obs_time的資料刪除)
  temperature_data <- temperature_data[!duplicated(temperature_data$ObsTime), ]
  
  # 處理星期幾
  weekday <- weekdays(as.Date(gsub("DB/", "", date)))
  vd_data$WeekDay <- weekday
  # 星期幾中文轉數字
  vd_data$WeekDay[vd_data$WeekDay == "星期一" | vd_data$WeekDay == "Monday"] <- 1
  vd_data$WeekDay[vd_data$WeekDay == "星期二" | vd_data$WeekDay == "Tuesday"] <- 2
  vd_data$WeekDay[vd_data$WeekDay == "星期三" | vd_data$WeekDay == "Wednesday"] <- 3
  vd_data$WeekDay[vd_data$WeekDay == "星期四" | vd_data$WeekDay == "Thursday"] <- 4
  vd_data$WeekDay[vd_data$WeekDay == "星期五" | vd_data$WeekDay == "Friday"] <- 5
  vd_data$WeekDay[vd_data$WeekDay == "星期六" | vd_data$WeekDay == "Saturday"] <- 6
  vd_data$WeekDay[vd_data$WeekDay == "星期日" | vd_data$WeekDay == "Sunday"] <- 7
  # 處理vd
  for (i in 1:nrow(etag_link_transaction)) {
    # 對應的EtagPairID加入vd_data欄位
    match_idx <- match(vd_data$LinkID, etag_link_transaction[i, ])
    vd_data$EtagPairID[!is.na(match_idx)] <- etag_link_transaction[i, 1]
  }
  etag_data <- etag_data[etag_data$TravelTime != 0, ]
  # 將vd_data中EtagPairID欄位為None和VSpeed欄位為0的資料刪除
  vd_data <- vd_data[!is.na(vd_data$EtagPairID) & vd_data$VSpeed != 0, ]
  
  lane_ids <- unique(vd_data$LaneID)
  Lane_df <- data.frame()
  for (one_etag_data in 1:nrow(etag_data)) {
    etag_id <- etag_data$ETagPairID[one_etag_data]
    end_time_ori <- etag_data$EndTime[one_etag_data]
    end_time <- gsub("T", " ", end_time_ori)
    vt <- etag_data$VehicleType[one_etag_data]
    # 轉換 VehicleType
    if (vt == "5") {
      vt_new <- "T"
    } else if (vt %in% c("41", "42")) {
      vt_new <- "L"
    } else if (vt %in% c("31", "32")) {
      vt_new <- "S"
    }
    # 計算temp和平均
    temp_pick <- temperature_data[temperature_data$ObsTime==end_time_ori,]
    
    if (nrow(temp_pick) != 0) {
      temp_db <- data.frame(
        rain = temp_pick[1,"新北_雨量"],
        temp = temp_pick[1,"新北_氣溫"]
      )
    }
    else {
      time_obj <- as.POSIXct(end_time_ori, format="%Y-%m-%dT%H:%M:%S", tz="Asia/Taipei")
      time_before5 <- time_obj - 5*60
      time_before5_str <- format(time_before5, "%Y-%m-%dT%H:%M:%S")
      time_before5_obj <- temperature_data[grepl(time_before5_str, temperature_data$ObsTime),]
      
      time_after5 <- time_obj + 5*60
      time_after5_str <- format(time_after5, "%Y-%m-%dT%H:%M:%S")
      time_after5_obj <- temperature_data[grepl(time_after5_str, temperature_data$ObsTime),]
      temp_db <- data.frame(
        rain = (time_before5_obj[1,"新北_雨量"]+time_after5_obj[1,"新北_雨量"])/2,
        temp = (time_before5_obj[1,"新北_氣溫"]+time_after5_obj[1,"新北_氣溫"])/2
      )
    }
    
    # 動態處理所有 LaneID
    for (lane in lane_ids) {
      subset_data <- vd_data[ vd_data$UpdateTime == end_time & 
                              vd_data$LaneID == lane & 
                              vd_data$EtagPairID == etag_id & 
                              vd_data$VehicleType == vt_new, ]
      if (nrow(subset_data) != 0) {
        avg_Speed <- mean(subset_data$Speed, na.rm = TRUE)
        avg_Occupancy <- mean(subset_data$Occupancy, na.rm = TRUE)
        avg_Volume <- mean(subset_data$Volume, na.rm = TRUE)
        avg_VSpeed <- mean(subset_data$VSpeed, na.rm = TRUE)
        cbind_df <- cbind(etag_data[one_etag_data,], data.frame(
          vd_avg_Speed = avg_Speed,
          vd_avg_Occupancy = avg_Occupancy,
          vd_avg_Volume = avg_Volume,
          vd_avg_VSpeed = avg_VSpeed,
          vd_LaneID = lane,
          vd_week_day = subset_data$WeekDay[1]
        ))
        cbind_df <- cbind(cbind_df, temp_db)
        Lane_df <- rbind(Lane_df, cbind_df)
      }
    }
  }
  write.csv(Lane_df, file = paste0(gsub("DB/", "", date),".csv"), row.names = FALSE)
}

