print("Running wrf_to_xanthos_process.py ...")

from im3components import wrf_xanthos_to_npy

folder_path = '/global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos/output_wrf_to_xanthos_process_historical_R'
out_dir = 'output_wrf_to_xanthos_process_historical_python'

wrf_xanthos_to_npy(folder_path=folder_path, out_dir=out_dir)