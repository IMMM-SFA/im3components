![test-coverage](https://github.com/IMMM-SFA/im3components/workflows/build/badge.svg) [![codecov](https://codecov.io/gh/IMMM-SFA/im3components/branch/main/graph/badge.svg)](https://codecov.io/gh/IMMM-SFA/im3components)

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


## Contribute components
To add a new component:
 - create a branch or fork of this repo with the naming convention `<parent_model_name>-<child_model_name>-<purpose>`
 - add a script following the same name convention as your function within the Python package in this repository with the code you intend to publish
 - generate tests within the testing module of the `im3components` package; ask a DSC member for assistance if you need help setting these up
 - update the table in the README to account for your component
 - for Python, ensure that you have updated the `requirements.txt` file with any dependencies from your code
 - create a pull requests and set a member of our DSC team as a reviewer; the pull request description should include a description of the desired functionality and the location of any data needed to conduct tests
 - once the pull requests has been reviewed, accepted, and all test are passing this will be merged into the master and a new version will be released
