setwd("/CONI_Isotope/")#Edit line to include your assigned directory when running the analyses
library(ggplot2)
library(readxl)
library(ggmap)
library(janitor)

######INPUTTING DATA FRAME AND MANIPULATING COLUMN NAMES/ DATA#######
dataset <- read_excel("Data/LocalitiesDataForMap.xlsx") #Importing excel sheet as dataframe
dataset <- clean_names(dataset) #Standardizing column header names
colnames(dataset)[1]<- "Locality" #Renaming complicated header name (locality_sample_id_for_historical) to Locality
colnames(dataset) #Checking to make sure rename worked 
numeric_lat<-as.numeric(dataset$latitude) #Changing Latitude to be a numeric variable 


######GETTING BASE MAP FROM STADIA MAPS PLATFORM########
register_stadiamaps("a4f2dc12-48f0-4b75-92b9-cc2b9ec817cb") #Inputting API to get access to Stadia Maps platform 
bbox <- c(left = -94.25, bottom = 29, right = -89.079673, top = 30.356697) #Setting latitudinal and longitudinal barriers for base map to vector. Theses plot barriers will cut off 2 points from South Texas. 
coastal_map <- get_stadiamap(bbox, zoom = 9, maptype = "stamen_toner_lite") #Using Stadia maps to get basemap 
ggmap(coastal_map) #Checking base map 


######PLOTTING LOCALITY POINTS ONTO BASE MAP#####
finalmap<-ggmap(coastal_map) +
   geom_point(data = dataset, aes( x = longitude, y = numeric_lat, shape = Locality), size = 2, alpha= 1, position = "jitter") +
  ggtitle("Sample Map")+
  theme(plot.title = element_text(hjust=0.5)) +
  labs (x= "Longitude", y= "Latitude")+
  scale_shape_manual(values= c(0,2,5,6,20)) 

ggsave("CMinorMap.png", plot = finalmap, dpi = 300)
