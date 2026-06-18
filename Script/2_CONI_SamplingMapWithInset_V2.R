library(remotes)

remotes::install_github("ropensci/rnaturalearthhires")

install.packages(
  "rnaturalearthhires",
  repos = "https://ropensci.r-universe.dev",
  type = "source"
)

library(rnaturalearth)
library(rnaturalearthdata)
library(rnaturalearth)

#install.packages(c("sf", "terra", "geodata", "maptiles", "ggplot2", "ggspatial", "cowplot"))

library(sf)
library(terra)
library(geodata)
library(maptiles)
library(ggplot2)
library(ggspatial)
library(cowplot)
library("readxl")
library("openxlsx")

# US state boundaries
usa_states <- ne_states(country = "United States of America", returnclass = "sf")
mx_states <- ne_states(country = "Mexico", returnclass = "sf")

states<-rbind(usa_states,mx_states)

# Transform for main map
states_3857 <- st_transform(states, 3857)

### Read in common nighthawk data ###
coni_data<-read_excel("Data/CMinorIsotopeData_withCoastlineDistance_v4.xlsx")
coni_data$LATITUDE<-as.numeric(coni_data$LATITUDE)

coni_localities_sf <- st_as_sf(
  coni_data,
  coords = c("LONGITUDE", "LATITUDE"),
  crs = 4326
)

# Get USA + Mexico outlines
countries <- geodata::gadm(country = c("USA", "MEX"), level = 0, path = tempdir())
countries <- st_as_sf(countries)

# Inset extent: all continental US + some Mexico
inset_bbox <- st_bbox(c(
  xmin = -120,
  xmax = -60,
  ymin = 19,
  ymax = 55
), crs = st_crs(4326))

# Louisiana outline
la <- geodata::gadm(country = "USA", level = 1, path = tempdir())
la <- st_as_sf(la)
la <- la[la$NAME_1 == "Louisiana", ]

# Choose zoomed-in map extent
# Example: southeast Louisiana / Baton Rouge-New Orleans area
bbox_zoom <- st_bbox(c(
  xmin = -95,
  xmax = -87,
  ymin = 27.5,
  ymax = 33.5
), crs = st_crs(4326))
zoom_poly <- st_as_sfc(bbox_zoom)

# Transform to Web Mercator for satellite tiles
bbox_3857 <- st_transform(zoom_poly, 3857)
bbox_extent_3857 <- st_buffer(bbox_3857, dist = 50000)

# Get satellite basemap for zoomed extent
sat <- get_tiles(
  bbox_extent_3857,
  provider = "Esri.WorldImagery",
  zoom = 7,
  crop = F
)

# Main zoomed map
main_map <- ggplot() +
  layer_spatial(sat) +
  
  # state outlines
  geom_sf(
    data = states_3857,
    fill = NA,
    color = "white",
    linewidth = 0.3
  ) +
  
  # locality points
  geom_sf(
    data = coni_localities_sf,
    shape = 21,
    fill = "red",
    color = "white",
    size = 1.5,
    stroke = 0.35
  ) +
  
  coord_sf(
    xlim = st_bbox(bbox_3857)[c("xmin", "xmax")],
    ylim = st_bbox(bbox_3857)[c("ymin", "ymax")],
    expand = FALSE
  ) +
  
  annotation_scale(
    location = "br",
    width_hint = 0.25,
    height = unit(0.15, "cm"),
    line_width = 0.8,
    text_cex = 0.6
  ) +
  
  annotation_north_arrow(
    location = "br",
    which_north = "true",
    
    # overall size
    height = unit(1.0, "cm"),
    width  = unit(1.09, "cm"),
    
    # padding from edge
    pad_x = unit(0.25, "cm"),
    pad_y = unit(0.5, "cm"),
    
    style = north_arrow_fancy_orienteering
  ) +
  
  theme_minimal() +
  
  theme(
    panel.grid.major = element_line(
      color = "white",
      linewidth = 0.2
    ),
    
    axis.title = element_blank(),
    
    axis.text = element_text(
      color = "black",
      size = 6
    )
  )

# Inset map
inset_map <- ggplot() +

  # state outlines
  geom_sf(
    data = states,
    fill = "gray99",
    color = "gray80",
    linewidth = 0.1
  ) +
  
  # countries
  geom_sf(
    data = countries,
    fill = NA,
    color = "black",
    linewidth = 0.2
  ) +
  
  # zoom extent box
  geom_sf(
    data = zoom_poly,
    fill = NA,
    color = "red",
    linewidth = 0.5
  ) +
  
  coord_sf(
    xlim = inset_bbox[c("xmin", "xmax")],
    ylim = inset_bbox[c("ymin", "ymax")],
    expand = FALSE
  ) +
  
  theme_void() 

# Combine inset with main map
final_map <- ggdraw(main_map) +
  draw_plot(inset_map, x = 0.68, y = 0.66, width = 0.32, height = 0.32)

ggsave(
  #set working directory to export to prior to file name
  filename = "CommonNighthawk_IsotopeSamplingMap_v2.png",
  plot = final_map,
  width = 3.25,
  height = 3.25,
  units = "in",
  dpi = 500,
  bg = "white"
)
