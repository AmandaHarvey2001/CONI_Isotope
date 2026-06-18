### Install Packages to most current versions ###
# install.packages("sf", dependencies = TRUE)

## Load required packages
library("xlsx")
library("sf") #Used for reading in shape files in R
library("readxl")

cm_data<-read_excel("Data/CMinorIsotopeData_v2.xlsx") ## Read in excel file with data, using the Geo-referenced Coordinates for the following calculations

## Convert coordinates of samples to compatible format ###
### Use crs = 5070 for Conus Albers which is good for dealing with North America and changes using st_buffer with meters rather than lat /long degrees
cm_data_coords<-st_as_sf(cm_data,coords=c("LONGITUDE","LATITUDE"), crs=4326)
cm_data_coords_nad83 <- st_transform(cm_data_coords, 5070)  # NAD83 / Conus Albers
cm_data_coords_bbpoly<-st_as_sfc(st_bbox(cm_data_coords_nad83))

### Because we only need distances, we can let sf use s2 spherical geometry:
sf_use_s2(TRUE) 

### Read in shape file of US Coast lines ###
coastline<-read_sf("/Users/NickMason_1/Desktop/Manuscripts/ChordeliesMinor/Code/Shapefiles/GSHHS_i_L1.shp")
coastline_nad83 <- st_transform(coastline, 5070)  # NAD83 / Conus Albers
coastline_union<-st_union(st_make_valid(coastline_nad83))
coastline_union_simp<-st_simplify(coastline_union,dTolerance=100) #Simplify the polygon by a scale of 100 meters
coastline_union_simp_buffer<-st_buffer(coastline_union_simp,-1250) #Move the coastline in by 1250 m, this seems to work well based on ground truthing with google images

#Combine all the coastline shapefiles into a single shapefile, this facilitates us calculating the distance to the nearest coastline rather than ALL the coastlines included in the file
coastline_union_simp_buffer_multistring<-st_cast(coastline_union_simp_buffer,to="MULTILINESTRING") #This allows us to calculate distance to the edge of the polygon when points are inside (i.e. our inland samples)

### Calculate distance for each point from nearest vertex of the polygon ###
distancefromcoast_1<-st_distance(cm_data_coords_nad83,coastline_union_simp_buffer_multistring) ### This will calculate distance to the edge of the polygon, but return "0" if it is inside
distancefromcoast_2<-st_distance(cm_data_coords_nad83,coastline_union_simp_buffer) ### This will calculate distance to the edge of the polygon, but return "0" if it is inside
distancefromcoast_1[!as.numeric(distancefromcoast_2)==0]<-0 #This will create a finalized vector that has the distances to the coastline and anything that is beyond the coastline (according to this shape file) is given a 0 and treated as 'on the coast or beyond'
distancefromcoast_revised<-distancefromcoast_1

### Plot shapefiles and bounding box to troubleshoot ###
plot(cm_data_coords_bbpoly)
plot(coastline_union_simp_buffer,col=NA,border="red",add=T)
plot(st_geometry(cm_data_coords_nad83),pch=21,bg="blue",add=T)

# Adding this new 'distancefromcoast' variable to our data frame
cm_data_out<-cbind(cm_data,distancefromcoast_revised)

# This will write out the data to a new excel file # 
write.xlsx(cm_data_out,"~/Desktop/CMinorIsotopeData_withCoastlineDistance_v4.xlsx",row.names=F)

