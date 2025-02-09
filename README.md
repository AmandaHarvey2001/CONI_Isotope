# Stable Isotope Ecology of _Chordeiles minor_

This github repository stores the scripts and data used to run the statistical analyses associated with the manuscript entitled "Spatial and Temporal Patterns of Trophic Ecology in Common Nighthawks Nesting in the Gulf Coast." All analyses were ran in R version 4.4.2.

## Project Overview
We collected data on δ15N, δ13C, and δ34S stable isotope ratios from 94 feathers sampled between 1937–2022 to examine spatial and temporal trends in the trophic ecology and habitat use of _C. minor_ in the Gulf Coast by tracing primary producers, trophic level, and salinity content of food webs respectively. 

## Directory Map

|- **<ins>CONI_Isotope</ins>** <br />
|    |- <ins>Data</ins> <br />
|    |    |- CMinorIsotopeData.xlsx <br />
|    |    |- CMinorIsotopeData_withCoastlineDistance.xlsx <br />
|    |    |- LocalitiesDataForMap.xlsx <br />
|    |- <ins>Scripts</ins> <br />
|    |    |- 1_CONIIsotope_DistanceFromCoast_v1.R <br />
|    |    |- 2_CONIIsotope_SampleMap_v1.R <br />
|    |    |- 3_CONIIsotope_StatisticalTestsAndFigure_v1.R <br />
|    |- <ins>Shapefiles</ins> <br />
|    |    |- GSHHS_i_L1.dbf <br />
|    |    |- GSHHS_i_L1.prj <br />
|    |    |- GSHHS_i_L1.shp <br />
|    |    |- GSHHS_i_L1.shx <br /> 

## Instructions for Use

### Description of Directory Contents 
Within the CONI_Isotope Directory are 3 subdirectories containing their respective files for data analysis: Data, Scripts, and Shapefiles. Shapefiles have been sourced from the [_Global Self-consistent, Hierarchical, High-resolution Geography Database_](https://www.ngdc.noaa.gov/mgg/shorelines/) avaliable through the National Center for Environmental Information. Note, an API for Stadia Maps is neccessary for SampleMap.R script and can be obtained at https://stadiamaps.com/.

Below, I will describe the function and neccessary data/shapefile components for each R code file in the Scripts subdirectory. Numbers at the beginning of script names represent the recommended order of execution. 

### Script Execution Order and Function
1. 1_CONIIsotope_DistanceFromCoast_v1.R
  - Required Shapefiles/ Data Sheet
      - GSHHS_i_L1.dbf
      - GSHHS_i_L1.prj
      - GSHHS_i_L1.shp
      - GSHHS_i_L1.shx
      - CMinorIsotopeData.xlsx
  - Description of Code
      - This script includes the code for calculating the distance of a sample's collection site coordinates to the coastline. Calculations are performed by combining all the coastline shapefiles into a single polygon shapefile and then calculating distance of points to the nearest edge of the polygon. Distances to the coastline (in meters) are then added to the existing dataframe as a new column exported for use in subsequent analyses (CMinorIsotopeData_withCoastlineDistance.xlsx).
2. 2_CONIIsotope_SampleMap_v1.R
  - Required Data Sheet
      - LocalitiesDataForMap.xlsx
  - Description of Code
      - This script includes the code for the production of a sample map (Figure 1 in our publication). We use a cleaned excel sheet (LocalitiesDataForMap.xlsx) with standardized coordinates to import our coordinate data. Coordinates were standardized for a locality if several samples were collected from said location to minimize plotting noise in our map. 
3. 3_CONIIsotope_StatisticalTestsAndFigure_v1.R
  - Required Data Sheet
      - CMinorIsotopeData_withCoastlineDistance.xlsx
  - Description of Code
      - This script includes the code for all statistical analyses ran to analyze temporal and spatial trends in stable isotopes: Linear Regression Models, Akaike Information Scores, and Spearman's Rank Correlation Coefficient tests. Further, it includes the code written to produce Figure 2 in our publication: multigrid scatterplots.
