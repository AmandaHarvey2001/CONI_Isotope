#############LIBRARY CALLS#############
setwd("/CONI_Isotope") #Edit line to include your assigned directory when running the analyses
library(readxl)
library(janitor)
library(cowplot) 
library(MuMIn)
library(interactions)
library(dplyr)
library(glmulti)
library(ggplot2)
library(tidyverse)
library(rJava)
library(writexl)
library(interactions)
library(grid)

#######DATA IMPORT AND CLEAN UP#######

#Importing excel sheet as data frame
dataset1 <- read_excel("Data/CMinorIsotopeData_withCoastlineDistance_v4.xlsx")
colnames(dataset1)
dataset1$numeric_distance<-as.numeric(dataset1$distancefromcoast_revised) #Setting distance from coast as a numerical variable
numeric_distance<-as.numeric(dataset1$distancefromcoast_revised) #Making separate vector for SD and mean analyses
  #SD and mean of distance from the coast for in-text
  sd(numeric_distance, na.rm= FALSE)
  mean(numeric_distance)
dataset2 <- clean_names(dataset1) #standardizing header names
dataset2$reverseyear<-(2021-as.numeric(dataset2$year)) #developing a column in data frame representing years since collection

######Log Transforming Independent Variables to Fix Skewedness#######
dataset2$logcoastdistance<- log(dataset2$numeric_distance+1)
dataset2$logreverseyear<- log(dataset2$reverseyear+1)

##############Suess Effect Corrections###################
correction1<-(1960-as.numeric(dataset2$year))
correction1[correction1<0]<-0

correction2<-(2024-as.numeric(dataset2$year))-correction1
correction2

dataset2$suess_effect_correctionfor_c <-as.numeric(dataset2$delta13cperc) + (correction1 * -0.005) + (correction2 * -0.022)

#########GETTING AVERAGE PRECIPITATION COLUMN IN DATA FRAME#############

#Making new column to give year that precipitation data should be pulled from precipitation data frames based
#off of molt patterns which will be represented/ affected by age/ month of sample collection

dataset2$yearforppt <- ifelse(
  dataset2$age %in% c("H", "HY", "L"), 
  dataset2$year, 
  ifelse(
    dataset2$month %in% 8:12, 
    dataset2$year, 
    ifelse(
      dataset2$month %in% 1:7, 
      dataset2$year - 1, 
      NA  # fallback if month is invalid
    )
  )
)  

#Importing precipitation data downloaded from PRISM for each county and it's respective sample collection year range: https://www.prism.oregonstate.edu/
CameronParppt<-read.csv("Data/PrecipitationData/PRISM_ppt_CameronPar_1936_2022.csv", skip=10, header= TRUE, row.names= NULL)
CameronCoppt<-read.csv("Data/PrecipitationData/PRISM_ppt_CameronCo_1991.csv", skip=10, header= TRUE, row.names= NULL)
Calcasieuppt<-read.csv("Data/PrecipitationData/PRISM_ppt_CalcasieuPar_1940.csv", skip=10, header= TRUE, row.names= NULL)
Jeffersonppt<-read.csv("Data/PrecipitationData/PRISM_ppt_JeffersonPar_1936_1993.csv", skip=10, header= TRUE, row.names= NULL)
Lafourcheppt<-read.csv("Data/PrecipitationData/Prism_ppt_LafourchePar_1991.csv", skip=10, header= TRUE, row.names= NULL)
Orleansppt<-read.csv("Data/PrecipitationData/Prism_ppt_OrleansPar_1992.csv", skip=10, header= TRUE, row.names= NULL)

#Making new column in original data frame for precipitation data for each month

dataset2$ppt5 <- as.numeric(NA)
dataset2$ppt6 <- as.numeric(NA)
dataset2$ppt7 <- as.numeric(NA)
dataset2$ppt8 <- as.numeric(NA)

#loops through each row to get precipitation data:
  #run lines 75-110 for this
  #ignore TX error (doesn't seem to matter?)
for (i in 1:nrow(dataset2)) {
  state <- dataset2$state[i]
  county <- dataset2$county[i]
  year <- dataset2$yearforppt[i]
  if (state == "TX") {
    df_name <- paste0(gsub(" County", "Co", county), "ppt")# Construct the name of the precipitation data frame
  } else if (state == "LA") {
    df_name <- paste0(gsub(" Parish", "Par", county), "ppt")
  } else { print("error in constructu name of the precipitation data set")
    next  # skip if unknown state
  }
  
  # Check if the data frame exists
  if (!exists(df_name)) {
    warning(paste("Data frame", df_name, "not found. Skipping row", i))
    next
  }
  
  # Get the actual data frame
  precip_df <- get(df_name)
  
  # Ensure column names are standardized
  colnames(precip_df) <- c("Date", "ppt")
  
  # Extract precipitation values for May to August of the specified year
  for (month in 5:8) {
    date_key <- paste0(year, "-", sprintf("%02d", month))
    ppt_val <- precip_df$ppt[precip_df$Date == date_key]
    
    if (length(ppt_val) > 0) {
      dataset2[i, paste0("ppt", month)] <- ppt_val[1]
    } else {
      dataset2[i, paste0("ppt", month)] <- NA
    }
  }
}


#Getting rid of random NA rows in dataset2
dataset2<-na.omit(dataset2)

#Averaging Precipitation
dataset2$Meanppt<-NA #making new column for precipitation average
dataset2 <- dataset2 %>% 
  rowwise() %>% 
  mutate(Meanppt = mean(c(ppt5, ppt6, ppt7, ppt8), na.rm = TRUE))

###########RUNNING LM USING glmulti####################

colnames(dataset2)
options(na.action = "na.fail")

#Carbon GLMs

c_glmulti <- glmulti(suess_effect_correctionfor_c ~ logcoastdistance + logreverseyear + Meanppt,
                     data = dataset2,
                     level = 2,
                     marginality = TRUE,
                     maxK = 6,
                     crit = "aicc",
                     method = "h")


print(c_glmulti)
weightable(c_glmulti)
#exporting as excel sheet for easier data transfer to manuscript
Cweightable<-weightable(c_glmulti)
Cweightable
Cweightable2<-as.data.frame(Cweightable)
write_xlsx(Cweightable2, path = "/Users/aharv36/Desktop/Cweightable.xlsx")

coef(c_glmulti)
#exporting as excel sheet for easier data transfer to manuscript
Ccoef<-coef(c_glmulti)
Ccoef2<-as.data.frame(Ccoef)
write_xlsx(Ccoef2, path = "/Users/aharv36/Desktop/Ccoef.xlsx")
summary(c_glmulti)

#Analyzing best AIC model
cbestfit<- lm(suess_effect_correctionfor_c ~ 1 + logcoastdistance + logreverseyear + Meanppt + Meanppt:logcoastdistance, data=dataset2)
summary(cbestfit)

#Nitrogen GLMs
n_glmulti <- glmulti(delta15nperc ~ logcoastdistance + logreverseyear + Meanppt,
                     data = dataset2,
                     level = 2,
                     marginality = TRUE,
                     maxK = 6,
                     crit = "aicc",
                     method = "h")

print(n_glmulti)
weightable(n_glmulti)
#exporting as excel sheet for easier data transfer to manuscript
Nweightable<-weightable(n_glmulti)
Nweightable2<-as.data.frame(Nweightable)
write_xlsx(Nweightable2, path = "/Users/aharv36/Desktop/Nweightable.xlsx")

coef(n_glmulti)
#exporting as excel sheet for easier data transfer to manuscript
Ncoef<-coef(n_glmulti)
ncoef2<-as.data.frame(Ncoef)
write_xlsx(ncoef2, path = "/Users/aharv36/Desktop/Ncoef.xlsx")
summary(n_glmulti)

#Analyzing best AIC model
nbestfit<-lm(delta15nperc ~ 1 + logreverseyear, data=dataset2)
summary(nbestfit)

#Sulfur GLMs
s_glmulti <- glmulti(delta34sperc ~ logcoastdistance + logreverseyear + Meanppt,
                     data = dataset2,
                     level = 2,
                     marginality = TRUE,
                     maxK = 6,
                     crit = "aicc",
                     method = "h")

print(s_glmulti)
weightable(s_glmulti)
#exporting as excel sheet for easier data transfer to manuscript
Sweightable<-weightable(s_glmulti)
Sweightable
Sweightable2<-as.data.frame(Sweightable)
write_xlsx(Sweightable2, path = "/Users/aharv36/Desktop/Sweightable.xlsx")

coef(s_glmulti)
#exporting as excel sheet for easier data transfer to manuscript
Scoef<-coef(s_glmulti)
Scoef2<-as.data.frame(Scoef)
write_xlsx(Scoef2, path = "/Users/aharv36/Desktop/scoef.xlsx")
summary(s_glmulti)

#Analyzing best AIC model
sbestfit<-lm(delta34sperc ~ 1 + logcoastdistance + logreverseyear + Meanppt + logreverseyear:logcoastdistance, data=dataset2)
summary(sbestfit)



#####MULTIPLOT FIGURES#######

###########9 PANEL FIGURE FOR ISOTOPES INTERACTIONS W/ PPT, YR, DIST########

theme = theme(
  axis.title.x = element_text(size = 8),
  axis.title.y = element_text(size = 10)) #setting theme across all

#C x YR
plot1<-ggplot(
  data = dataset2,
  mapping = aes(x = logreverseyear, y = suess_effect_correctionfor_c)
) +
  geom_point()+
  labs(
    x = "Log Transformed Years Since Collection",
    y = expression(delta^13 * C * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme_bw() 

plot1<-plot1+theme

plot1 

#Cx DIST
plot2<-ggplot(
  data = dataset2,
  mapping = aes(x = logcoastdistance, y = suess_effect_correctionfor_c)
) +
  geom_point()+
  labs(
    x = "Log Transformed Distance from Coastline",
    y = expression(delta^13 * C * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust=0.5)) +
  theme_bw() 

plot2<-plot2+theme
plot2

#C x Precipitation
plot3<-ggplot(
  data = dataset2,
  mapping = aes(x = Meanppt, y = suess_effect_correctionfor_c)
) +
  geom_point()+
  labs(
    x = "Mean Precipitation",
    y = expression(delta^13 * C * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust=0.5)) +
  theme_bw() 

plot3<-plot3+theme
plot3

#N x YR
plot4<-ggplot(
  data = dataset2,
  mapping = aes(x = logreverseyear, y = delta15nperc)
) +
  geom_point()+
  labs(
    x = "Log Transformed Years Since Collection",
    y= expression(delta^15 * N * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust=0.5)) +
  theme_bw() 

plot4<-plot4+theme
plot4

#N x DIST
plot5<-ggplot(
  data = dataset2,
  mapping = aes(x = logcoastdistance, y = delta15nperc)
) +
  geom_point()+
  labs(
    x = "Log Transformed Distance from Coastline",
    y= expression(delta^15 * N * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust=0.5)) +
  theme_bw() 

plot5<-plot5+theme
plot5

#N x Precipitation
plot6<-ggplot(
  data = dataset2,
  mapping = aes(x = Meanppt, y = delta15nperc)
) +
  geom_point()+
  labs(
    x = "Mean Precipitation",
    y = expression(delta^15 * N * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +  theme_bw() +
  theme(legend.text = element_text(size=5))


plot6<-plot6+theme
plot6

#S x YR
plot7<-ggplot(
  data = dataset2,
  mapping = aes(x = logreverseyear, y = delta34sperc)
) +
  geom_point()+
  labs(
    x = "Log Transformed Years Since Collection",
    y= expression(delta^34 * S * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust=0.5)) +
  theme_bw() 

plot7<-plot7+theme
plot7

#S x DIST
plot8<-ggplot(
  data = dataset2,
  mapping = aes(x = logcoastdistance, y = delta34sperc)
) +
  geom_point()+
  labs(
    x = "Log Transformed Distance from Coastline",
    y= expression(delta^34 * S * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust=0.5)) +
  theme_bw() 

plot8<-plot8+theme
plot8

#N x Precipitation
plot9<-ggplot(
  data = dataset2,
  mapping = aes(x = Meanppt, y = delta34sperc)
) +
  geom_point()+
  labs(
    x = "Mean Precipitation",
    y = expression(delta^34 * S * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust=0.5)) +
  theme_bw() 

plot9<-plot9+theme
plot9

#MULTIGRID FOR EXPORT:

plotcombined<-plot_grid(plot4, plot5, plot6, plot1, plot2, plot3, plot7, plot8, plot9,
                        ncol = 3, 
                        align = 'hv',
                        rel_heights = c(1, 1, 1),  
                        rel_widths = c(1, 1, 1), 
                        scale= 1.0
) 

plotcombined

ggsave("plotcombined.jpg", 
       plot= plotcombined,
       width= 11,
       height= 10
         )



######3 PANEL FIGURE FOR ISOTOPES INTERACTIONS WITH EACHOTHER##########
#CXN

CxN<-ggplot(
  data = dataset2,
  mapping = aes(x = suess_effect_correctionfor_c, y = delta15nperc)
) +
  geom_point(show.legend = FALSE)+
  labs(
    x = expression(delta^13 * C * " (" * "\u2030" * ")"),
    y= expression(delta^15 * N * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust=0.5)) +
  theme_bw() 
CxN

#SXN

SxN<-ggplot(
  data = dataset2,
  mapping = aes(x = delta34sperc, y = delta15nperc)
) +
  geom_point(show.legend = FALSE)+
  labs(
    x= expression(delta^34 * S * " (" * "\u2030" * ")"),
    y= expression(delta^15 * N * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust=0.5)) +
  theme_bw() 

SxN

#SxC
SxC<-ggplot(
  data = dataset2,
  mapping = aes(x = delta34sperc, y = suess_effect_correctionfor_c)
) +
  geom_point()+
  labs(
    x = expression(delta^34 * S * " (" * "\u2030" * ")"),
    y = expression(delta^13 * C * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme_bw() + 
  theme(legend.text = element_text(size=5))

SxC

#3 panel multiplot

plotcombined2<-plot_grid(CxN, SxN, SxC,
                        ncol = 3, 
                        align = 'hv',
                        rel_heights = c(1, 1, 1),  
                        rel_widths = c(0.1, 0.1, 0.1), 
                        scale= 1.0
) 

plotcombined2


#######Spearman's for 3 panel plot, isotope x isotope##########
CarbonxSulfurSpearcorr <- cor.test(x=dataset2$delta34sperc, y=dataset2$suess_effect_correctionfor_c, method = 'spearman') 
CarbonxSulfurSpearcorr #run for results

CarbonxNitrogenSpearcorr<- cor.test(x=dataset2$delta15nperc, y=dataset2$suess_effect_correctionfor_c, method = 'spearman') 
CarbonxNitrogenSpearcorr #run for results

SulfurxNitrogenSpearcorr<-cor.test(x=dataset2$delta15nperc, y=dataset2$delta34sperc, method = 'spearman') 
SulfurxNitrogenSpearcorr #run for results

#######Spearman's for 3x3 panel plot, each ecological variable x each isotope######

CarbonYrSpearcorr <- cor.test(x=dataset2$logreverseyear, y=dataset2$suess_effect_correctionfor_c, method = 'spearman') 
CarbonYrSpearcorr #run for results

CarbonDistSpearcorr <- cor.test(x=dataset2$logcoastdistance, y=dataset2$suess_effect_correctionfor_c, method = 'spearman')
CarbonDistSpearcorr #run for results

CarbonPrecSpearcorr <- cor.test(x=dataset2$Meanppt, y=dataset2$suess_effect_correctionfor_c, method = 'spearman')
CarbonPrecSpearcorr  #run for results

NitrogenYrSpearcorr <- cor.test(x=dataset2$logreverseyear, y=dataset2$delta15nperc, method = 'spearman')
NitrogenYrSpearcorr #run for results

NitrogenDistSpearcorr <- cor.test(x=dataset2$logcoastdistance, y=dataset2$delta15nperc, method = 'spearman')
NitrogenDistSpearcorr #run for results

NitrogenPrecSpearcorr <- cor.test(x=dataset2$Meanppt, y=dataset2$delta15nperc, method = 'spearman')
NitrogenPrecSpearcorr  #run for results

SulfurYrSpearcorr <- cor.test(x=dataset2$logreverseyear, y=dataset2$delta34sperc, method = 'spearman')
SulfurYrSpearcorr #run for results

SulfurDistSpearcorr <- cor.test(x=dataset2$logcoastdistance, y=dataset2$delta34sperc, method = 'spearman')
SulfurDistSpearcorr #run for results

SulfurPrecSpearcorr <- cor.test(x=dataset2$Meanppt, y=dataset2$delta34sperc, method = 'spearman')
SulfurPrecSpearcorr #run for results

##########INTERACTION PLOT FOR SULFUR######
interactioneffectmodel<-lm(delta34sperc~logreverseyear*logcoastdistance, 
                           data=dataset2)

interactionplot<-interact_plot(interactioneffectmodel,
                               pred = logcoastdistance,
                               modx = logreverseyear,
                               interval = TRUE, 
                               plot.points = TRUE,
                               colors = c("black","darkgray", "#b3b4b2"),
                               legend.main = "Log Years Since Collection",
                               vary.lty= TRUE,
                               point.size = 2.5,      # Increase point size
                               point.alpha = 0.5) +  
  ggplot2::theme_bw() +
  labs(x = "Log Coastline Distance",
       y = expression(delta^34 * S * " (" * "\u2030" * ")"))

interactionplot +
  scale_linetype_manual(
    values = c("dashed", "solid", "dotted")
  ) +
  guides(
    linetype = "none",
    color = guide_legend(
      override.aes = list(
        linetype = c( "dashed", "solid", "dotted"),
        linewidth = 1
      )
    )
  ) +
  theme(
    legend.key.width = unit(2, "cm"),
    legend.position = c(0.05, 0.05),
    legend.justification = c(0, 0),
    legend.background = element_rect(
      fill = "white",
      colour = "black"
    ),
    legend.box.background = element_blank()
  )


#######INTERACTION PLOT FOR CARBON#######


interactioneffectmodel2 <- lm(
  suess_effect_correctionfor_c ~ logcoastdistance * Meanppt,
  data = dataset2
)


interactionplot2<-interact_plot(interactioneffectmodel2,
                               pred = Meanppt,
                               modx = logcoastdistance,
                               interval = TRUE, 
                               plot.points = TRUE,
                               colors = c("black","#7d7f7c", "#b3b4b2"),
                               legend.main = "Mean Precipitation",
                               vary.lty= TRUE,
                               point.size = 2.5,      # Increase point size
                               point.alpha = 0.5) +  
  ggplot2::theme_bw() +
  labs(x = "Mean Precipitation",
       y = expression(delta^13 * C * " (" * "\u2030" * ")"))


interactionplot2 +
  scale_linetype_manual(
    values = c("dashed", "solid", "dotted")
  ) +
  guides(
    linetype = "none",
    color = guide_legend(
      override.aes = list(
        linetype = c( "dashed", "solid", "dotted"),
        linewidth = 1
      )
    )
  ) +
  theme(
    legend.key.width = unit(2, "cm"),
    legend.position = c(0.05, 0.05),
    legend.justification = c(0, 0),
    legend.background = element_rect(
      fill = "white",
      colour = "black"
    ),
    legend.box.background = element_blank()
  )
