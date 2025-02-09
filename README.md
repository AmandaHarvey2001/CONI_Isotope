# Stable Isotope Ecology of _Chordeiles minor_

This github repository stores the scripts and data used to run the statistical analyses associated with the manuscript entitled "Spatial and Temporal Patterns of Trophic Ecology in Common Nighthawks Nesting in the Gulf Coast." All analyses were ran in R version 4.4.2.

Note, an API for Stadia Maps is neccessary for SampleMap.R script and can be obtained at https://stadiamaps.com/

## Project Overview
We collected data on δ15N, δ13C, and δ34S stable isotope ratios from 94 feathers sampled between 1937–2022 to examine spatial and temporal trends in the trophic ecology and habitat use of _C. minor_ in the Gulf Coast by tracing primary producers, trophic level, and salinity content of food webs respectively. 

## Directory Map
|- CONI_Isotope
|  |-Data
|  |  |- CMinorIsotopeData.xlsx
|  |  |- CMinorIsotopeData_withCoastlineDistance.xlsx
|  |  |- LocalitiesDataForMap.xlsx
|  |-Scripts
|  |  |- 1_CONIIsotope_DistanceFromCoast_v1.R
|  |  |- 2_CONIIsotope_SampleMap_v1.R
|  |  |- 3_CONIIsotope_StatisticalTestsAndFigure_v1.R
|  |-Shapefiles
|  |  |- GSHHS_i_L1.dbf
|  |  |- GSHHS_i_L1.prj
|  |  |- GSHHS_i_L1.shp
|  |  |- GSHHS_i_L1.shx

## Instructions for Use

