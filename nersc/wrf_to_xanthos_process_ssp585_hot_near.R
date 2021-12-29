print("Running wrf_to_xanthos_process.R ...")

# Initialize
library(dplyr)
library(data.table)
library(tidyr)
out_dir = "output_wrf_to_xanthos_process_ssp5_hot_near_R"
if(!dir.exists(out_dir)){dir.create(out_dir)}

# Get list of files
files <- list.files(full.names = T,recursive=T);
files <- files[grepl("_ssp5_hot_near_R_",files)]; files
files <- files[grepl(".*resampled_wrf_to.*.csv",files)]; files
print(paste0("Running files: ", paste(files,collapse=", ")))

# For each param combine files
param_list = c("GLW_W m-2","PSFC_Pa","Q2_kg","RAINC_mm","rh_percent","SWDOWN_W m-2","T2_K","tempDegC_degC","U10_m s-1","v_m s-1","V10_m s-1")

for(param_i in param_list){
  files_i <- files[grepl(param_i,files)]; files_i
  tbl_i <- tibble::tibble()

  for(file_i in files_i){
    tbl_temp <- data.table::fread(file_i,header=T) %>%
      tibble::as_tibble() %>%
      tidyr::gather(key="x",value="value",-lon,-lat,-gridid,-param,-unit)

    tbl_i <- tbl_i %>%
      dplyr::bind_rows(tbl_temp)
  }


  # Summarize
  tbl_out_i <- tbl_i %>%
    dplyr::group_by(lon,lat,gridid,param,unit,x) %>%
    dplyr::summarize(value = mean(value,na.rm=T)) %>%
    tidyr::spread(key="x",value="value") %>%
    ungroup();

  years_i <- names(tbl_out_i)[!names(tbl_out_i) %in% c("lon","lat","gridid","param","unit")]
  fname_i <- paste0(out_dir,"/resampled_wrf_to_xanthos_monthly_",param_i,"_",years_i[1],"_to_",years_i[length(years_i)],".csv"); fname_i
  data.table::fwrite(x=tbl_out_i,file=fname_i)

  print(paste0("File saved as: ", fname_i))
}

print("wrf_to_xanthos_process.R complete.")
