library(sp)

# import data
directory = "//SRV02/RL-Institut/04_Projekte/140_open_eGo/10-Stud_Ordner/Jonas_Guetter/Daten/"
df1_name = "model_draft_ego_grid_lv_ontnumber.csv"
df2_name = "model_draft_ego_grid_lv_loadarea_ta_mview.csv"
df1 = read.csv(paste(directory,df1_name,sep =""),header=TRUE,sep=";",na.strings=c(""))
df2 = read.csv(paste(directory,df2_name,sep =""),header=TRUE,sep=";",na.strings=c(""))

df3 = merge(df1,df2,by="id", all = TRUE)

# make NA to zero
df3 [which(is.na(df3$modnr)),]$modnr = 0 

# Ermittlung der Unterschiede pro Lastgebiet
df3$diff = df3$modnr - df3$realnr
mean(df3$diff)
sd(df3$diff)
plot(df3$realnr,df3$diff)
plot(df3$realnr,df3$diff,xlim=c(0,30), ylim=c(-10,15))
fm_diff <- lm(df3$realnr ~ df3$diff)

# Ermittlung des relativen Fehlers pro Lastgebiet im Bezug auf reale ONS
df3$rel_diff = (df3$diff/df3$realnr)*100
mean(df3$rel_diff)
sd(df3$rel_diff)
plot(df3$realnr, df3$rel_diff)
plot(df3$realnr, df3$rel_diff, xlim=c(0,20),ylim = c(-100,400))
fm_rel_diff <- lm(df3$realnr ~ df3$rel_diff)
#nl_fm_rel_diff<-nls(df3$rel_diff ~ (cosh(df3$realnr)/sinh(df3$realnr)))


# Ermittlung der Unterschiede pro Lastgebiet (Betrag)
df3$diff_abs = abs(df3$diff)
mean(df3$diff_abs)
sd(df3$diff_abs)
plot(df3$realnr,df3$diff_abs)
plot(df3$realnr,df3$diff_abs,xlim=c(0,25), ylim=c(0,15))
fm_diff_abs <- lm(df3$realnr ~ df3$diff_abs)

# Ermittlung des relativen Fehlers pro Lastgebiet im Bezug auf reale ONS (Betrag)
df3$rel_diff_abs = (df3$diff_abs/df3$realnr)*100
mean(df3$rel_diff_abs)
sd(df3$rel_diff_abs)
plot(df3$realnr, df3$rel_diff_abs)
plot(df3$realnr, df3$rel_diff_abs, xlim=c(0,25),ylim = c(0,450))
fm_rel_diff_abs <- lm(df3$realnr ~ df3$rel_diff_abs)




