library (car)


# import data
directory = "C:/Users/Jonas/Desktop/RLI/Daten/"
df1_name = "model_draft_ego_grid_mvlv_controlgroup.csv"
df2_name = "model_draft_ego_grid_mvlv_referenceontpoints.csv"
df1 = read.csv(paste(directory,df1_name,sep =""),header=TRUE,sep=";",na.strings=c(""))
df2 = read.csv(paste(directory,df2_name,sep =""),header=TRUE,sep=";",na.strings=c(""))


# merge datasets
df1$area_id <- NULL
df1$ons <- FALSE
df2$ons <- TRUE

df <- rbind(df1,df2)


# Only look at rows without NA values
sapply(df,function(x) sum(is.na(x)))
df<-df[!(is.na(df$diststreet) | is.na(df$distcrossroad)),]

# Split the data into a training and a testing dataset
x <- sample(1:2222, 1111, replace=F)

train <- df[x,]
test <- df[-x,]

rm(x)


# Look at parameters to decide which are suited best to be used as explanatory variables

# create factor variable
train$ons_factor = factor (train$ons)

# Create histograms

hist(train$pop50, main="Bevölkerung im Umkreis von 50m",xlab="Einwohner",ylab="Häufigkeit")
hist(train$pop100, main="Bevölkerung im Umkreis von 100m",xlab="Einwohner",ylab="Häufigkeit")
hist(train$pop250, main="Bevölkerung im Umkreis von 250m",xlab="Einwohner",ylab="Häufigkeit")
hist(train$pop500, main="Bevölkerung im Umkreis von 500m",xlab="Einwohner",ylab="Häufigkeit")
hist(train$pop1000, main="Bevölkerung im Umkreis von 1000m",xlab="Einwohner",ylab="Häufigkeit")
hist(train$diststreet, main="Distanz zur nächsten Straße",xlab="Distanz in Metern",ylab="Häufigkeit")
hist(train$distcrossroad, main="Distanz zur nächsten Straßenkreuzung",xlab="Distanz in Metern",ylab="Häufigkeit")
hist(train$buildingsnr50, main="Gebäudeanzahl im Umkreis von 50m",xlab="Gebäudeanzahl",ylab="Häufigkeit")
hist(train$buildingsnr100, main="Gebäudeanzahl im Umkreis von 100m",xlab="Gebäudeanzahl",ylab="Häufigkeit")
hist(train$buildingsnr250, main="Gebäudeanzahl im Umkreis von 250m",xlab="Gebäudeanzahl",ylab="Häufigkeit")
hist(train$buildingsnr500, main="Gebäudeanzahl im Umkreis von 500m",xlab="Gebäudeanzahl",ylab="Häufigkeit")
hist(train$buildingsnr1000, main="Gebäudeanzahl im Umkreis von 1000m",xlab="Gebäudeanzahl",ylab="Häufigkeit")
hist(train$buildingsarea50, main="Gesamte Gebäudefläche im Umkreis von 50m",xlab="Gebäudefläche in Quadratmetern",ylab="Häufigkeit")
hist(train$buildingsarea100, main="Gesamte Gebäudefläche im Umkreis von 100m",xlab="Gebäudefläche in Quadratmetern",ylab="Häufigkeit")
hist(train$buildingsarea250, main="Gesamte Gebäudefläche im Umkreis von 250m",xlab="Gebäudefläche in Quadratmetern",ylab="Häufigkeit")
hist(train$buildingsarea500, main="Gesamte Gebäudefläche im Umkreis von 500m",xlab="Gebäudefläche in Quadratmetern",ylab="Häufigkeit")
hist(train$buildingsarea1000, main="Gesamte Gebäudefläche im Umkreis von 1000m",xlab="Gebäudefläche in Quadratmetern",ylab="Häufigkeit")

# Create box Plots

boxplot(train$pop50,ylab="Einwohner")
title(main="Bevölkerung im Umkreis von 50m")
boxplot(train$pop100,ylab="Einwohner")
title(main="Bevölkerung im Umkreis von 100m")
boxplot(train$pop250,ylab="Einwohner")
title(main="Bevölkerung im Umkreis von 250m")
boxplot(train$pop500,ylab="Einwohner")
title(main="Bevölkerung im Umkreis von 500m")
boxplot(train$pop1000,ylab="Einwohner")
title(main="Bevölkerung im Umkreis von 1000m")
boxplot(train$diststreet,ylab="Distanz[m]")
title(main="Distanz zur nächsten Straße")
boxplot(train$distcrossroad,ylab="Distanz[m]")
title(main="Distanz zur nächsten Straßenkreuzung")
boxplot(train$buildingsnr50,ylab="Gebäude")
title(main="Anzahl an Gebäuden im Umkreis von 50m")
boxplot(train$buildingsnr100,ylab="Gebäude")
title(main="Anzahl an Gebäuden im Umkreis von 100m")
boxplot(train$buildingsnr250,ylab="Gebäude")
title(main="Anzahl an Gebäuden im Umkreis von 250m")
boxplot(train$buildingsnr500,ylab="Gebäude")
title(main="Anzahl an Gebäuden im Umkreis von 500m")
boxplot(train$buildingsnr1000,ylab="Gebäude")
title(main="Anzahl an Gebäuden im Umkreis von 1000m")
boxplot(train$buildingsarea50,ylab="Fläche [qm]")
title(main="Gesamte Gebäudefläche im Umkreis von 50m")
boxplot(train$buildingsarea100,ylab="Fläche [qm]")
title(main="Gesamte Gebäudefläche im Umkreis von 100m")
boxplot(train$buildingsarea250,ylab="Fläche [qm]")
title(main="Gesamte Gebäudefläche im Umkreis von 250m")
boxplot(train$buildingsarea500,ylab="Fläche [qm]")
title(main="Gesamte Gebäudefläche im Umkreis von 500m")
boxplot(train$buildingsarea1000,ylab="Fläche [qm]")
title(main="Gesamte Gebäudefläche im Umkreis von 1000m")

# Get non-visual information about parameters
summary(train$pop50)
summary(train$pop100)
summary(train$pop250)
summary(train$pop500)
summary(train$pop1000)
summary(train$diststreet)
summary(train$distcrossroad)
summary(train$buildingsnr50)
summary(train$buildingsnr100)
summary(train$buildingsnr250)
summary(train$buildingsnr500)
summary(train$buildingsnr1000)
summary(train$buildingsarea50)
summary(train$buildingsarea100)
summary(train$buildingsarea250)
summary(train$buildingsarea500)
summary(train$buildingsarea1000)


# Create Spine-plots

spineplot(train$ons_factor ~ train$pop50,breaks = quantile(train$pop50, c(.2, .4, .6, .8, 1)), ylab = "ONS", xlab = "Einwohner")
title(main="Bevölkerung im Umkreis von 50m")
spineplot(train$ons_factor ~ train$pop100,breaks = quantile(train$pop100, c(0,.2, .4, .6, .8, 1)), ylab = "ONS", xlab = "Einwohner")
title(main="Bevölkerung im Umkreis von 100m")
spineplot(train$ons_factor ~ train$pop250, ylab = "ONS", breaks = quantile(train$pop250, c(0,.2, .4, .6, .8, 1)), xlab = "Einwohner")
title(main="Bevölkerung im Umkreis von 250m")
spineplot(train$ons_factor ~ train$pop500, ylab = "ONS", breaks = quantile(train$pop500, c(0,.2, .4, .6, .8, 1)), xlab = "Einwohner")
title(main="Bevölkerung im Umkreis von 500m")
spineplot(train$ons_factor ~ train$pop1000, ylab = "ONS",breaks = quantile(train$pop1000, c(0,.2, .4, .6, .8, 1)), xlab = "Einwohner")
title(main="Bevölkerung im Umkreis von 1000m")
spineplot(train$ons_factor ~ train$diststreet, ylab = "ONS",breaks = quantile(train$diststreet, c(0,.2, .4, .6, .8, 1)), xlab = "Distanz in Metern")
title(main="Distanz zur nächsten Straße")
spineplot(train$ons_factor ~ train$distcrossroad, ylab = "ONS",breaks = quantile(train$distcrossroad, c(0,.2, .4, .6, .8, 1)), xlab = "Distanz in Metern")
title(main="Distanz zur nächsten Straßenkreuzung")
spineplot(train$ons_factor ~ train$buildingsnr50, ylab = "ONS",breaks = quantile(train$buildingsnr50, c(0,.2, .4, .6, .8, 1)), xlab = "Gebäudeanzahl")
title(main="Gebäudeanzahl im Umkreis von 50m")
spineplot(train$ons_factor ~ train$buildingsnr100, ylab = "ONS",breaks = quantile(train$buildingsnr100, c(0,.2, .4, .6, .8, 1)), xlab = "Gebäudeanzahl")
title(main="Gebäudeanzahl im Umkreis von 100m")
spineplot(train$ons_factor ~ train$buildingsnr250, ylab = "ONS",breaks = quantile(train$buildingsnr250, c(0,.2, .4, .6, .8, 1)), xlab = "Gebäudeanzahl")
title(main="Gebäudeanzahl im Umkreis von 250m")
spineplot(train$ons_factor ~ train$buildingsnr500, ylab = "ONS",breaks = quantile(train$buildingsnr500, c(0,.2, .4, .6, .8, 1)), xlab = "Gebäudeanzahl")
title(main="Gebäudeanzahl im Umkreis von 500m")
spineplot(train$ons_factor ~ train$buildingsnr1000, ylab = "ONS",breaks = quantile(train$buildingsnr1000, c(0,.2, .4, .6, .8, 1)), xlab = "Gebäudeanzahl")
title(main="Gebäudeanzahl im Umkreis von 1000m")
spineplot(train$ons_factor ~ train$buildingsarea50, ylab = "ONS",breaks = quantile(train$buildingsarea50, c(0,.2, .4, .6, .8, 1)), xlab = "Gebäudefläche in Quadratmetern")
title(main="Gesamte Gebäudefläche im Umkreis von 50m")
spineplot(train$ons_factor ~ train$buildingsarea100, ylab = "ONS",breaks = quantile(train$buildingsarea100, c(0,.2, .4, .6, .8, 1)), xlab = "Gebäudefläche in Quadratmetern")
title(main="Gesamte Gebäudefläche im Umkreis von 100m")
spineplot(train$ons_factor ~ train$buildingsarea250, ylab = "ONS",breaks = quantile(train$buildingsarea250, c(0,.2, .4, .6, .8, 1)), xlab = "Gebäudefläche in Quadratmetern")
title(main="Gesamte Gebäudefläche im Umkreis von 250m")
spineplot(train$ons_factor ~ train$buildingsarea500, ylab = "ONS",breaks = quantile(train$buildingsarea500, c(0,.2, .4, .6, .8, 1)), xlab = "Gebäudefläche in Quadratmetern")
title(main="Gesamte Gebäudefläche im Umkreis von 500m")
spineplot(train$ons_factor ~ train$buildingsarea1000, ylab = "ONS",breaks = quantile(train$buildingsarea1000, c(0,.2, .4, .6, .8, 1)), xlab = "Gebäudefläche in Quadratmetern")
title(main="Gesamte Gebäudefläche im Umkreis von 1000m")

# Evtl. PCA im Vorfeld, um Kolinearität uzu reduzieren?

# Stepwise variable selection by AIC
null_model = glm(ons ~ 1, family=binomial(logit), data = train)
model = step(null_model, scope = ons ~ pop50 + pop100 + pop250 + pop500 + pop1000 + diststreet + distcrossroad + 
                   buildingsnr50 + buildingsnr100 + buildingsnr250 + buildingsnr500 + buildingsnr1000 + buildingsarea50 + 
                   buildingsarea100 + buildingsarea250 + buildingsarea500 + buildingsarea1000, direction = "forward", trace = 2)
summary(model)

# check variance inflation factor

vif(model)

# Build new model based on variables with low vif

model_final = glm(ons ~ train$pop50+train$pop100+train$diststreet+train$distcrossroad+
                    train$buildingsnr50+train$buildingsarea100+train$buildingsarea250, 
                  family=binomial(logit), data = train)
summary(model_final)

vif(model_final)