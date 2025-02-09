#library calls
setwd("/CONI_Isotope/") #Edit line to include your assigned directory when running the analyses
library(ggplot2) 
library(readxl)
library(janitor)
library(cowplot) 
library(grid)

#importing excel sheet as data frame
dataset1 <- read_excel("Data/CMinorIsotopeData_withCoastlineDistance.xlsx")

#data clean up
dataset1$numeric_distance<-as.numeric(dataset1$distancefromcoast_inland) #setting distance from coast as a numerical variable
dataset2 <- clean_names(dataset1) #standardizing header names
dataset2$reverseyear<-(2021-as.numeric(dataset2$year)) #developing a column in dataframe representing years since collection

##############Suess Effect Corrections###################
correction1<-(1960-as.numeric(dataset2$year))
correction1[correction1<0]<-0

correction2<-(2024-as.numeric(dataset2$year))-correction1
correction2

dataset2$suess_effect_correctionfor_c <-as.numeric(dataset2$delta13cperc) + (correction1 * -0.005) + (correction2 * -0.022)

######Log Transforming Independent Variables to Fix Skewedness#######
dataset2$logcoastdistance<- log(dataset2$numeric_distance+1)
dataset2$logreverseyear<- log(dataset2$reverseyear+1)

######LM STATISTICS/ AIC FOR CARBON PLOTS#####
lm_carbon_model1<-lm(formula = suess_effect_correctionfor_c ~ logreverseyear, data = dataset2)
lm_carbon_model2<-lm(formula = suess_effect_correctionfor_c ~ numeric_distance, data = dataset2)
lm_carbon_model3<-lm(formula = suess_effect_correctionfor_c ~ logreverseyear + numeric_distance, data = dataset2)
lm_carbon_model4<-lm(formula = suess_effect_correctionfor_c ~ logreverseyear * numeric_distance, data = dataset2)

summary(lm_carbon_model1) #Best AIC Score Model for Carbon Isotope
summary(lm_carbon_model2)
summary(lm_carbon_model3)
summary(lm_carbon_model4)

AIC(lm_carbon_model1)
AIC(lm_carbon_model2)
AIC(lm_carbon_model3)
AIC(lm_carbon_model4)

######LM STATISTIC/ AIC FOR NITROGEN PLOTS#####
lm_nitrogen_model1<-lm(formula = delta15nperc ~ logreverseyear, data = dataset2)
lm_nitrogen_model2<-lm(formula = delta15nperc ~ numeric_distance, data = dataset2)
lm_nitrogen_model3<-lm(formula = delta15nperc ~ logreverseyear + numeric_distance, data = dataset2)
lm_nitrogen_model4<-lm(formula = delta15nperc ~ logreverseyear * numeric_distance, data = dataset2)

summary(lm_nitrogen_model1) #Best AIC Score Model for Nitrogen Isotope
summary(lm_nitrogen_model2) 
summary(lm_nitrogen_model3) 
summary(lm_nitrogen_model4) 

AIC(lm_nitrogen_model1)
AIC(lm_nitrogen_model2)
AIC(lm_nitrogen_model3)
AIC(lm_nitrogen_model4)

######LM STATISTICS/ AIC FOR SULFUR PLOTS######

lm_sulfur_model1<-lm(formula = delta34sperc ~ logreverseyear, data = dataset2)
lm_sulfur_model2<-lm(formula = delta34sperc ~ numeric_distance, data = dataset2)
lm_sulfur_model3<-lm(formula = delta34sperc ~ logreverseyear + numeric_distance, data = dataset2)
lm_sulfur_model4<-lm(formula = delta34sperc ~ logreverseyear * numeric_distance, data = dataset2)

summary(lm_sulfur_model1)
summary(lm_sulfur_model2)
summary(lm_sulfur_model3) #Best AIC Score Model for Sulfur Isotope
summary(lm_sulfur_model4)

AIC(lm_sulfur_model1)
AIC(lm_sulfur_model2)
AIC(lm_sulfur_model3)
AIC(lm_sulfur_model4)

########Spearman Rank Correlation Coefficient###############
##Ran Spearman Rank Correlation Coefficient test for each isotope and their independent variables respectively##
CarbonYrSpearcorr <- cor.test(x=dataset2$logreverseyear, y=dataset2$suess_effect_correctionfor_c, method = 'spearman') 

CarbonYrSpearcorr #run for results

CarbonDistSpearcorr <- cor.test(x=dataset2$logcoastdistance, y=dataset2$suess_effect_correctionfor_c, method = 'spearman')

CarbonDistSpearcorr #run for results

NitrogenYrSpearcorr <- cor.test(x=dataset2$logreverseyear, y=dataset2$delta15nperc, method = 'spearman')

NitrogenYrSpearcorr #run for results

NitrogenDistSpearcorr <- cor.test(x=dataset2$logcoastdistance, y=dataset2$delta15nperc, method = 'spearman')

NitrogenDistSpearcorr #run for results

SulfurYrSpearcorr <- cor.test(x=dataset2$logreverseyear, y=dataset2$delta34sperc, method = 'spearman')

SulfurYrSpearcorr #run for results

SulfurDistSpearcorr <- cor.test(x=dataset2$logcoastdistance, y=dataset2$delta34sperc, method = 'spearman')

SulfurDistSpearcorr #run for results

#####Plot 1a- CxYR#### 

plot1<-ggplot(
  data = dataset2,
  mapping = aes(x = logreverseyear, y = suess_effect_correctionfor_c)
) +
  geom_smooth(method = "lm", color= "black")+ 
  geom_point(color= "black")+
  labs(
    x = "Log Transformed Years Since Collection",
    y = expression(delta^13 * C * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust=0.5)) +
  theme_bw() +
  theme(legend.position = "none",   
        axis.title.x = element_text(size = 12),   
        axis.title.y = element_text(size = 12),   
        axis.text.x = element_text(size = 10),   
        axis.text.y = element_text(size = 10),
        plot.margin = unit(c(0.1, 0.25, 0.1, 0.1), "cm")
  )

plot1 #runtoseefinalresult

####Plot 2a - NxYR####

plot2<-ggplot(
  data = dataset2,
  mapping = aes(x = logreverseyear, y = delta15nperc)
) +
  geom_point(color = "black") +
  geom_smooth(method = "lm", color= "black")+
  labs(
    x = "Log Transformed Years Since Collection",
    y = expression(delta^15 * N * " (" * "\u2030" * ")"),
    color= " ",
    shape= " "
  )+ 
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust=0.5)) +
  theme_bw() +
  theme(legend.position = "none",   
        axis.title.x = element_text(size = 12),   
        axis.title.y = element_text(size = 12),   
        axis.text.x = element_text(size = 10),   
        axis.text.y = element_text(size = 10),
        plot.margin = unit(c(0.1, 0.25, 0.1, 0.1), "cm")
  )

plot2 #runtoseefinalresult

####Plot 3a- SxYR####

plot3<- ggplot(
  data = dataset2,
  mapping = aes(x = logreverseyear, y = delta34sperc)
) +
  geom_point() +
  theme_bw()+
  labs(
    x = "Log Transformed Years Since Collection", 
    y = expression(delta^34 * S * " (" * "\u2030" * ")"), 
    color= " ",
    shape= " "
  ) + 
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust=0.5))+
  theme(
    axis.title.x = element_text(size = 12),   
    axis.title.y = element_text(size = 12),   
    axis.text.x = element_text(size = 10),   
    axis.text.y = element_text(size = 10)      
  )

plot3

####Plot 1b- CxDIST####

plot4 <- ggplot(
  data = dataset2,
  mapping = aes(x = logcoastdistance, y = suess_effect_correctionfor_c)
) +
  geom_point() +
  labs(
    x = "Log Transformed Distance from Coastline (m)", 
    y= expression(delta^13 * C * " (" * "\u2030" * ")"),
    color= " ", 
    shape= " ") + 
  guides(fill = "none") +
  theme(plot.title = element_text(hjust=0.5))+
  theme_bw() +
  theme(legend.position = "none", 
        axis.title.x = element_text(size = 12),   
        axis.title.y = element_text(size = 12),   
        axis.text.x = element_text(size = 10),   
        axis.text.y = element_text(size = 10), 
        plot.margin = unit(c(0.1, 0.25, 0.1, 0.1), "cm")
  )

plot4 #runtoseefinalresult

####Plot 2b- NxDIST####

plot5 <- ggplot(
  data = dataset2,
  mapping = aes(x = logcoastdistance, y = delta15nperc)
) +
  geom_point() +
  labs(
    x = "Log Transformed Distance from Coastline (m)", 
    y= expression(delta^15 * N * " (" * "\u2030" * ")",
                  color= " ", 
                  shape= " ")) + 
  guides(fill = "none") +
  theme(plot.title = element_text(hjust=0.5))+
  theme_bw() +
  theme(legend.position = "none", 
        axis.title.x = element_text(size = 12),   
        axis.title.y = element_text(size = 12),   
        axis.text.x = element_text(size = 10),   
        axis.text.y = element_text(size = 10), 
        plot.margin = unit(c(0.1, 0.25, 0.1, 0.1), "cm"))

plot5 #runtoseefinalresult

####FIG 2,3 SxDIST####

plot6 <- ggplot(
  data = dataset2,
  mapping = aes(x = logcoastdistance, y = delta34sperc)
) +
  geom_point() +
  labs(
    x ="Log Transformed Distance from Coastline (m)", 
    y= expression(delta^34 * S * " (" * "\u2030" * ")"),
    color = " ", 
    shape = " ")+
  geom_smooth(method = "lm", color= "black")+
  guides(fill = "none")+  
  theme_bw() +
  theme(plot.title = element_text(hjust=0.5),  
        axis.title.x = element_text(size = 12),   
        axis.title.y = element_text(size = 12),   
        axis.text.x = element_text(size = 10),   
        axis.text.y = element_text(size = 10)      
  ) 

plot6 #runtoseefinalresults

#####MULTIFRAME GRID OF 6 PLOTS####
plotcombined<-plot_grid(plot1, plot2, plot3, plot4, plot5, plot6,
                        labels = c("1a" , "2a", "3a", "1b", "2b", "3b"),
                        ncol = 3, 
                        align = 'hv',             
                        label_size = 12,
                        rel_heights = c(1, 1, 1),  
                        rel_widths = c(1, 1, 1), 
                        scale= 1.0
) 

plotcombined #run to see combined figures

#Statistics were added to figures outside of RStudio
