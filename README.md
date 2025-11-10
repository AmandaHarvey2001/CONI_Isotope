# Stable Isotope Ecology of _Chordeiles minor_

This github repository stores the scripts and data used to run the statistical analyses associated with the manuscript entitled "Spatial and Temporal Patterns of Trophic Ecology in Common Nighthawks Nesting in the Gulf Coast." All analyses were ran in R version 4.4.2.

## Project Overview
We collected data on δ15N, δ13C, and δ34S stable isotope ratios from 94 feathers sampled between 1937–2022 to examine spatial and temporal trends in the trophic ecology and habitat use of _C. minor_ in the Gulf Coast by tracing primary producers, trophic level, and salinity content of food webs respectively. 

## Directory Map

|- **<ins>CONI_Isotope</ins>** <br />
|    |- <ins>Data</ins> <br />
|    |    |- CMinorIsotopeData.xlsx <br />
|    |    |- CMinorIsotopeData_withCoastlineDistance.xlsx <br />
|    |    |- LocalitiesDataForMap_V2.xlsx <br />
|    |    |- PrecipitationData
|    |    |    |- PRISM_ppt_CalcasieuPar_1940.csv
|    |    |    |- PRISM_ppt_CameronCo_1991.csv
|    |    |    |- PRISM_ppt_CameronPar_1936_2022.csv
|    |    |    |- PRISM_ppt_JeffersonPar_1936_1993.csv
|    |    |    |- PRISM_ppt_LafourchePar_1991.csv
|    |    |    |- PRISM_ppt_OrleansPar_1992.csv
|    |- <ins>Scripts</ins> <br />
|    |    |- 1_CONIIsotope_DistanceFromCoast_v1.R <br />
|    |    |- 2_CONIIsotope_SampleMap_v2.R <br />
|    |    |- 3_CONIIsotope_StatisticalTestsAndFigure_v3.R <br />
|    |- <ins>Shapefiles</ins> <br />
|    |    |- GSHHS_i_L1.dbf <br />
|    |    |- GSHHS_i_L1.prj <br />
|    |    |- GSHHS_i_L1.shp <br />
|    |    |- GSHHS_i_L1.shx <br /> 

## Instructions for Use

### Description of Directory Contents 
Within the CONI_Isotope Directory are 3 subdirectories containing their respective files for data analysis: Data, Scripts, and Shapefiles. Precipitation Data from Shapefiles have been sourced from the [ Northwest Alliance for Computational Science & Engineering at Oregon State University PRISM Weather Data Set](https://prism.oregonstate.edu/). Shapefiles were avaliable through the National Center for Environmental Information's [_Global Self-consistent, Hierarchical, High-resolution Geography Database_](https://www.ngdc.noaa.gov/mgg/shorelines/).

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
      - This script includes the code for calculating the distance of a sample's collection site coordinates to the coastline. Distances to the coastline (in meters) are then added to the existing dataframe as a new column exported for use in subsequent analyses (CMinorIsotopeData_withCoastlineDistance_v2.xlsx).
2. 2_CONIIsotope_SampleMap_v2.R
  - Required Data Sheet
      - LocalitiesDataForMap_V2.xlsx
  - Description of Code
      - This script includes the code for the production of a sample map (Figure 1 in our publication). We use a cleaned excel sheet (LocalitiesDataForMap.xlsx) with standardized coordinates. For visualization purposes, individual nesting sites within a locality were standardized to minimize plotting noise.
3. 3_CONIIsotope_StatisticalTestsAndFigure_v3.R
  - Required Data Sheet
      - CMinorIsotopeData_withCoastlineDistance_v2.xlsx
      - PRISM_ppt_CalcasieuPar_1940.csv
      -  PRISM_ppt_CameronCo_1991.csv
      -  PRISM_ppt_CameronPar_1936_2022.csv
      -  PRISM_ppt_JeffersonPar_1936_1993.csv
      -  PRISM_ppt_LafourchePar_1991.csv
      -  PRISM_ppt_OrleansPar_1992.csv
  - Description of Code
      - This script includes the code for all temporal, ecological and spatial analyses of stable isotopes: General Linear Regression Models, Akaike Information Scores, and Spearman's Rank Correlation Coefficient tests. Further, it includes the code written to produce all tables and Figures 2, 3, and S1 in our publication.
