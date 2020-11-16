# im3components
IM3 components to maintain reproducible interoperability

## Overview
This repository will hold code that has been built to facilitate interoperability between IM3 modeling software for each experiement.

## Current components
Each component should follow this naming convention in all lower case separated by an underscore:

`<parent_model_name>_<child_model_name>_<purpose>`

| component | from | from_version | to | to_version | description |
| -- | -- | -- | -- | -- | -- |
| gcam_cerf_expansion_plan | GCAM | TBD | CERF | TBD | converts a GCAM-USA electricity capacity expansion plan into the format needed for CERF's inputs. |
