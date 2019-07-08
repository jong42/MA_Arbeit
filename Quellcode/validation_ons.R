library(plyr)
library(readr)

################## number of ONS

#import dataframe
loadarea <- read_delim("F:/RLI/Daten/csv/loadarea.csv", 
                       ";", escape_double = FALSE, col_names = FALSE, 
                       trim_ws = TRUE)

# rename dataframe and remove unnecessary variables
loadarea  = rename(loadarea, c("X1"="id","X9"="area_ha","X37"="real_ons_nr", "X38"="modelled_ons_nr"))
loadarea = loadarea[,c("id","area_ha","real_ons_nr","modelled_ons_nr")]

# difference with leading sign
loadarea$ons_difference = loadarea$real_ons_nr - loadarea$modelled_ons_nr
summary(loadarea$ons_difference)
sd(loadarea$ons_difference)
hist(loadarea$ons_difference,main = "",xlab ="Differenz zwischen realer und modellierter Anzahl an Ortsnetzstationen", ylab = "Häufigkeit")

#  difference as absolute value without leading sign
loadarea$ons_difference_abs = abs(loadarea$real_ons_nr - loadarea$modelled_ons_nr)
summary(loadarea$ons_difference_abs)
sd(loadarea$ons_difference_abs)
hist(loadarea$ons_difference_abs,main = "",xlab ="Betrag der Differenz zwischen realer und modellierter Anzahl an Ortsnetzstationen", ylab = "Häufigkeit")

# Plots
plot (loadarea$real_ons_nr,loadarea$modelled_ons_nr, xlab = "reale Anzahl", ylab = "modellierte Anzahl")
plot (loadarea$area_ha,loadarea$ons_difference, xlab = "Lastgebietsfläche [ha]", ylab = "Differenz zwischen realer und modellierter Anzahl an Ortsnetzstationen")
plot (loadarea$area_ha,loadarea$ons_difference_abs, xlab = "Lastgebietsfläche [ha]", ylab = "Betrag der Differenz zwischen realer und modellierter Anzahl an Ortsnetzstationen")

################## position of ONS


#import dataframe
ons <- read_delim("F:/RLI/Daten/csv/modelled_ons.csv", 
                       ";", escape_double = FALSE, col_names = FALSE, 
                       trim_ws = TRUE)

# rename dataframe and remove unnecessary variables
ons  = rename(ons, c("X2"="id","X4"="la_id","X11"="dist_real_ons"))
ons = ons[,c("id","la_id","dist_real_ons")]

#
hist(ons$dist_real_ons, main = "",xlab = "Distanz zur nächsten realen ONS [m]", ylab = "Häufigkeit")
summary(ons$dist_real_ons)
sd(ons$dist_real_ons)

# Calculate mean distance to next real ons for each load area
df = ddply(ons,~la_id,summarise,dist_real_ons_mean=mean(dist_real_ons))
loadarea = merge (loadarea, df, by.x ="id", by.y ="la_id")

hist (loadarea$dist_real_ons_mean)
plot (loadarea$area_ha,loadarea$dist_real_ons_mean,xlab = "Fläche des Lastgebiets [ha]", ylab = "Mittlere Distanz zur nächsten realen ONS")
