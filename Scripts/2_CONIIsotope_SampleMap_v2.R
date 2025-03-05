### These are the packages that I usually use for doing GIS operations in R ###
install.packages(c("sf","terra","usmap","basemaps","vcfR"))

library(sf) #for managing vectors
library(terra) #for managing rasters
library(usmap)#has shapefiles of US maps
library(adegenet)
library(basemaps)
library(readxl)
library(janitor)

# Set the working directory
setwd("/CONI_Isotope/") #Edit line to include your assigned directory when running the analyses

# Uploading and cleaning dataset
dataset <- read_excel("Data/LocalitiesDataForMap_V2.xlsx") #Importing excel sheet as data frame
dataset <- clean_names(dataset) #Standardizing column header names
colnames(dataset)[1]<- "Locality" #Renaming complicated header name (locality_sample_id_for_historical) to Locality
colnames(dataset) #Checking to make sure rename worked 
numeric_lat<-as.numeric(dataset$latitude) #Making latitude a numeric variable 

### Convert coordinates to the correct format ###
dataset_sf <- sf::st_as_sf(dataset, coords = c("longitude", "latitude"), crs = 4326) #The CRS code here matches World Geodetic System 1984 (WGS84), which is good for dealing with standard coordinates
dataset_sf_transformed<-sf::st_transform(dataset_sf,crs=3395) #Transform projection to match satellite basemaps, which uses a mercator projection (different from WGS84)

#Transforming Locality names
dataset_sf_transformed$Locality<-factor(dataset_sf_transformed$Locality,levels=c("Holly Beach","Rutherford Beach","Rockefeller Wildlife Preserve","Specimen Locality"))

### This creates a bounding box that includes all of our sample points ###
bbox_coords<-sf::st_bbox(dataset_sf)
bbox_coords_sf<-sf::st_as_sfc(bbox_coords)

### Plotting Bounding Box ###
plotting_coords<-c(xmin=-95,ymin=28,xmax=-88,ymax=31.5)
plotting_bbox<-sf::st_as_sfc(sf::st_bbox(plotting_coords))
plotting_box<-st_set_crs(plotting_bbox,4326)

### Louisiana Bounding Box ###
louisiana_bbox<-sf::st_as_sfc(sf::st_bbox(louisiana_map))
louisiana_map_transformed<-sf::st_transform(louisiana_map,crs=3395)

### Create a basic map of Louisiana ###
louisiana_map<-usmap::us_map(regions="states",include="Louisiana")

### Get a satellite map to plot over ###
chordeiles_basemap<-basemap_terra(plotting_box, map_service = "maptiler", map_type = "satellite",map_token="WnDyrJY4DcvXuYu7gEvS")

### Plot sampling points and state outline ###
terra::plotRGB(chordeiles_basemap,mar=c(0,0,0,0))
plot(sf::st_geometry(louisiana_map_transformed),add=T,col="transparent",border="white",lwd=1)

### Plot first layer of historical samples ###
plot(sf::st_geometry(dataset_sf_transformed[dataset_sf_transformed$Locality=="Specimen Locality",]), add=T, pch=21, main="Sample Map",cex=1,bg="white",col="black")

###Plot second layer of contemporary sampling sites###
plot(sf::st_geometry(dataset_sf_transformed[dataset_sf_transformed$Locality!="Specimen Locality",]), add=T, pch=c(22,23,24,25,21)[dataset_sf_transformed$Locality], main="Sample Map",cex=2,bg="transparent",col="white")

###Add legend###
legend(x=-10500000,y=3410000,legend=levels(dataset_sf_transformed$Locality),cex=0.4,pch=c(22,23,24,21),pt.lwd=0.5,pt.cex=1.25,bg="white")

dev.off()

#savingplottedmap
png(file="~/Desktop/Cminor_satellite_samplingmap_v1.png",width=6.5,height=3.25,units=
      "in",res=500)

