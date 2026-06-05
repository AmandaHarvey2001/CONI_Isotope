#############LIBRARY CALLS#############
setwd("/CONI_Isotope/") #Edit line to include your assigned directory when running the analyses
library(readxl)
library(janitor)
library(cowplot) 
library(MuMIn)
library(interactions)
library(dplyr)
library(glmulti)
library(ggplot2)
library(tidyverse)


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

#Making new column to give year of the precipitation data that will
#be pulled from the precipitation data frames based off of molt patterns 
#which will be represented/ affected by age/ month of sample collection

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

#Importing precipitation data downloaded from PRISM for each county 
#and it's respective sample collection year range: https://www.prism.oregonstate.edu/

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

#Averaging Precipitation for May-August
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
coef(c_glmulti)

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
coef(s_glmulti)

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

#######SPEARMAN'S STATISTICS#######
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


#########INTERACTION PLOT FOR SULFUR########

x_seq <- seq(
  min(dataset2$logcoastdistance, na.rm = TRUE),
  max(dataset2$logcoastdistance, na.rm = TRUE),
  length.out = 200
)

modx_mean <- mean(dataset2$logreverseyear, na.rm = TRUE)
modx_sd   <- sd(dataset2$logreverseyear, na.rm = TRUE)

newdat <- expand.grid(
  logcoastdistance = x_seq,
  logreverseyear = c(modx_mean - modx_sd,
                     modx_mean,
                     modx_mean + modx_sd)
)

# predict with SE
pred <- predict(
  interactioneffectmodel,
  newdata = newdat,
  se.fit = TRUE
)

newdat <- newdat %>%
  mutate(
    fit = pred$fit,
    se  = pred$se.fit,
    upper = fit + 1.96 * se,
    lower = fit - 1.96 * se,
    modx_group = factor(logreverseyear,
                        labels = c("-1 SD", "Mean", "+1 SD"))
  )

# split for clarity
mean_df  <- filter(newdat, modx_group == "Mean")
plus_df  <- filter(newdat, modx_group == "+1 SD")
minus_df <- filter(newdat, modx_group == "-1 SD")

# plot

interactionplot <- ggplot() +
  
  # raw points
  geom_point(
    data = dataset2,
    aes(x = logcoastdistance, y = delta15nperc),
    alpha = 0.4
  ) +
  
  # 95% CI ribbons
  geom_ribbon(
    data = newdat,
    aes(
      x = logcoastdistance,
      ymin = lower,
      ymax = upper,
      group = modx_group,
      fill = modx_group
    ),
    alpha = 0.15,
    colour = NA
  ) +
  
  # model lines (now fully mapped for legend + style control)
  geom_line(
    data = newdat,
    aes(
      x = logcoastdistance,
      y = fit,
      color = modx_group,
      linetype = modx_group
    ),
    linewidth = 1
  ) +
  
  theme_bw() +
  
  labs(
    x = "Log Coastline Distance",
    y = expression(delta^34 * S * " (" * "\u2030" * ")"),
    color = "Log Years Since Collection",
    fill = "Log Years Since Collection",
    linetype = "Log Years Since Collection"
  ) +
  
  scale_color_manual(
    values = c(
      "-1 SD" = "#747474",
      "Mean" = "black",
      "+1 SD" = "#969696"
    )
  ) +
  
  scale_fill_manual(
    values = c(
      "-1 SD" = "#747474",
      "Mean" = "black",
      "+1 SD" = "#969696"
    )
  ) +
  
  scale_linetype_manual(
    values = c(
      "-1 SD" = "dashed",
      "Mean" = "solid",
      "+1 SD" = "dotted"
    )
  )

interactionplot



##### INTERACTION PLOT 2 WITH MEAN AS SOLID LINE AND 95% CONFIDENCE INTERVAL
interactioneffectmodel2 <- lm(
  suess_effect_correctionfor_c ~ logcoastdistance * Meanppt,
  data = dataset2
)

# prediction grid
x_seq <- seq(
  min(dataset2$Meanppt, na.rm = TRUE),
  max(dataset2$Meanppt, na.rm = TRUE),
  length.out = 200
)

modx_vals <- c(
  mean(dataset2$logcoastdistance, na.rm = TRUE) - sd(dataset2$logcoastdistance, na.rm = TRUE),
  mean(dataset2$logcoastdistance, na.rm = TRUE),
  mean(dataset2$logcoastdistance, na.rm = TRUE) + sd(dataset2$logcoastdistance, na.rm = TRUE)
)

newdat2 <- expand.grid(
  Meanppt = x_seq,
  logcoastdistance = modx_vals
)

# predictions
pred <- predict(interactioneffectmodel2, newdata = newdat2, se.fit = TRUE)

newdat2 <- newdat2 %>%
  mutate(
    fit = pred$fit,
    se = pred$se.fit,
    upper = fit + 1.96 * se,
    lower = fit - 1.96 * se,
    modx_group = factor(logcoastdistance,
                        labels = c("-1 SD", "Mean", "+1 SD"))
  )

interactionplot2 <- ggplot(newdat2, aes(x = Meanppt)) +
  # Raw data
  geom_point(
    data = dataset2,
    aes(x = Meanppt, y = suess_effect_correctionfor_c),
    inherit.aes = FALSE,
    alpha = 0.4
  ) +
  
  # 95% CI ribbons
  geom_ribbon(
    aes(
      ymin = lower,
      ymax = upper,
      fill = modx_group
    ),
    alpha = 0.15,
    colour = NA
  ) +
  
  # Prediction lines
  geom_line(
    aes(
      y = fit,
      color = modx_group,
      linetype = modx_group
    ),
    linewidth = 1
  ) +
  
  theme_bw() +
  
  labs(
    x = "Mean Precipitation",
    y = expression(delta^13 * C * " (" * "\u2030" * ")"),
    color = "Log Distance",
    fill = "Log Distance",
    linetype = "Log Distance"
  ) +
  
  scale_color_manual(
    values = c(
      "-1 SD" = "#999DA0",
      "Mean" = "black",
      "+1 SD" = "#48494B"
    )
  ) +
  
  scale_fill_manual(
    values = c(
      "-1 SD" = "#999DA0",
      "Mean" = "black",
      "+1 SD" = "#48494B"
    )
  ) +
  
  scale_linetype_manual(
    values = c(
      "-1 SD" = "dashed",
      "Mean" = "solid",
      "+1 SD" = "dotted"
    )
  )

interactionplot2

