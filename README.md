![py-build](https://github.com/IMMM-SFA/im3components/workflows/py-build/badge.svg) [![py-codecov](https://codecov.io/gh/IMMM-SFA/im3components/branch/main/graph/badge.svg)](https://codecov.io/gh/IMMM-SFA/im3components) ![R-CMD](https://github.com/IMMM-SFA/im3components/workflows/R-CMD/badge.svg)

# im3components
IM3 components to maintain reproducible interoperability

## Overview
This repository will hold code that has been built to facilitate interoperability between IM3 modeling software for each experiement.  Currently, code can be provided in either Python or R as a part of each package in this repository.

## Current components
Each component should follow this naming convention in all lower case separated by an underscore:

`<parent_model_name>_<child_model_name>_<purpose>`

| language | component | from | from_version | to | to_version | description |
| :--: | :--: | :--: | :--: | :--: | :--: | -- |
| Python | `gcam_cerf_expansion_plan` | GCAM | TBD | CERF | TBD | converts a GCAM-USA electricity capacity expansion plan into the format needed for CERF's inputs. |
| R | `gcam_modelx_sum` | GCAM | TBD | ModelX | TBD | example function to represent data from GCAM being converted for some use by ModelX (fake model) |
|R| `pop_gcam_process` | raw pop data | IMMM-SFA/statepop: v0.1.0 | GCAM | Branch: [zk/feature/gcam-usa-im3](https://stash.pnnl.gov/projects/JGCRI/repos/gcam-core/browse?at=refs%2Fheads%2Fzk%2Ffeature%2Fgcam-usa-im3)| process raw popultation by state for GCAM scenarios.|
| R | `wrf_xanthos_resample` | wrf | TBD | xanthos | v2.4.0 | resample from WRF hourly, 12kmx12km data to Xanthos monthly, 0.5x0.5deg grid for each WRF parameter selected.|
| python | `wrf_xanthos_to_npy` | wrf | TBD | xanthos | v2.4.0 | convert .csv file out from wrf_xanthos_resample to .npy for xanthos|
| bash | `wrf_xanthos_process.sh` | wrf | TBD | xanthos | v2.4.0 | run wrf_xanthos_process.R and wrf_xanthos_process.py on NERSC|
| R | `wrf_xanthos_process.R` | wrf | TBD | xanthos | v2.4.0 | run wrf_xanthos_resample on NERSC|
| Python | `wrf_xanthos_process.py` | wrf | TBD | xanthos | v2.4.0 | run wrf_xanthos_to_npy on NERSC|



## Contribute components
To add a new component:
 - create a branch or fork of this repo with the naming convention `<parent_model_name>-<child_model_name>-<purpose>`
 - add a script following the same name convention as your function within the Python package in this repository with the code you intend to publish
 - generate tests within the testing module of the `im3components` package; ask a DSC member for assistance if you need help setting these up
 - update the table in the README to account for your component
 - for Python, ensure that you have updated the `requirements.txt` file with any dependencies from your code
 - create a pull requests and set a member of our DSC team as a reviewer; the pull request description should include a description of the desired functionality and the location of any data needed to conduct tests
 - once the pull requests has been reviewed, accepted, and all test are passing this will be merged into the master and a new version will be released


## Raw Population by State to GCAM
Work flow to process raw population data to GCAM
- Data has been processed using the im3components R function: `im3components::pop_gcam_process()`
- The processed data has been included into GCAM and pushed to the branch: [zk/feature/gcam-usa-im3](https://stash.pnnl.gov/projects/JGCRI/repos/gcam-core/browse?at=refs%2Fheads%2Fzk%2Ffeature%2Fgcam-usa-im3)
- The particular commit is: [2d77115a78e](https://stash.pnnl.gov/projects/JGCRI/repos/gcam-core/commits/2d77115a78eb5ed32f7d626c5d26390b65028f8b)
- Files modified in the branch are:
-- ./input/gcamdata/R/LA100.Socioeconomics.R
-- ./input/gcamdata/R/L201.socioeconomics_USA.R
-- ./input/gcamdata/inst/extdata/gcam-usa/NCAR_SSP_pop_state.csv (File Added)
- File NCAR_SSP_pop_state.csv was created using the function from this package: im3components::pop_gcam_process()

## WRF to Xanthos
Work flow for WRF to Xanthos data processing:
- Login into NERSC
- cd /global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos
- Modify the 'ncdf_path_i' in /global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos/wrf_to_xanthos_process.R to point to the folder or files to processing
- WRF files are being hosted at: /global/cfs/cdirs/m2702/gsharing
- sbatch wrf_to_xanthos.sh
- squeue -u USERNAME # To see progress
- Outputs from the wrf_to_xanthos_process.R script in .csv format at: cd /global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos/outputs_wrf_to_xanthos_process_R
- Outputs from the wrf_to_xanthos_process.py script in .npy format at: cd /global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos/outputs_wrf_to_xanthos_process_python

