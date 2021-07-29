print("Running wrf_to_xanthos_process.R ...")

# Initialize
library(im3components)

# Declare arguments
# ncdf_path_i = paste0("/global/cfs/cdirs/m2702/gsharing/CONUS_PGW_WRF_1979_Sample") # Decalre folder
# test files
ncdf_path_i <- (list.files("/global/cfs/cdirs/m2702/gsharing/CONUS_PGW_WRF_2009_Sample_v12", full.names=TRUE))[1:10]
target_grid_i = "C:/Z/models/xanthos/example/input/reference/coordinates.csv"
params_i = c("RAINC","Q2","PSFC","T2","GLW","SWDOWN","V10","U10")
out_dir_i='output_wrf_to_xanthos_process_R'
save_i = T
ncdf_resampled_i = im3components::data_ncdf_resampled_wrf_xanthos
aggregation_method_i = "mean"

# Run script
im3components::wrf_xanthos_resample(
  ncdf_path = ncdf_path_i,
  target_grid = target_grid_i,
  params = params_i,
  aggregation_method = aggregation_method_i,
  out_dir= out_dir_i,
  save = save_i,
  ncdf_resampled = ncdf_resampled_i)