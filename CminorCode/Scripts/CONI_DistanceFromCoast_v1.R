## Load required packages
library("xlsx")
library("sf") #Used for reading in shape files in R
library(readxl)
setwd("/Users/aharv36/Desktop/ChordeilesMinor") #Edit line to include your assigned directory when running the analyses
cm_data<-read_excel("CMinorIsotopeData.xlsx") ## Read in excel file with data, using the Geo-referenced Coordinates for the following calculations

## Dataframe manipulation ###
cm_data<-cm_data[!is.na(cm_data$LONGITUDE),] #Removing rows that are missing Longitude Data

## Convert coordinates of samples to compatible format ###
cm_data_coords<-st_as_sf(cm_data,coords=c("LONGITUDE","LATITUDE"), crs=4326)

### Read in shape file of US Coast lines ###
coastline<-read_sf(GSHHS_i_L1.shp)
sf_use_s2(FALSE) 

coastline_union<-st_union(st_make_valid(coastline)) #Combine all the coastline shapefiles into a single shapefile, this facilitates us calculating the distance to the nearest coastline rather than ALL the coastlines included in the file

coastline_union_multistring<-st_cast(coastline_union,to="MULTILINESTRING") #This allows us to calculate distance to the edge of the polygon when points are inside (i.e. our inland samples)
distancefromcoast_inlandTF<-st_distance(cm_data_coords,coastline_union) ### This will calculate distance to the edge of the polygon, but return "0" if it is inside
distancefromcoast_inland<-st_distance(cm_data_coords,coastline_union_multistring) ### This will calculate distance to the edge of the polygon, whether it is inside or outside

distancefromcoast_inland[!as.numeric(distancefromcoast_inlandTF)==0]<-0 #This will create a finalized vector that has the distances to the coastline and anything that is beyond the coastline (according to this shape file) is given a 0 and treated as 'on the coast or beyond'

# Adding this new 'distancefromcoast' variable to our data frame
cm_data_out<-cbind(cm_data,distancefromcoast_inland)

# This will write out the data to a new excel file # 
write.xlsx(cm_data_out,"~/CMinor/Data/CMinorIsotopeData_withCoastlineDistance.xlsx",row.names=F)

## Troubleshooting to validate data / distance calculations
plot(coastline_union,xlim=st_bbox(cm_data_coords)[c(1,3)],ylim=st_bbox(cm_data_coords)[c(2,4)])
plot(st_geometry(cm_data_coords),add=T,col="red")
text(x=as.numeric(cm_data$LONGITUDE),y=as.numeric(gsub("\t","",cm_data$LATITUDE)),label=distancefromcoast_inland)




