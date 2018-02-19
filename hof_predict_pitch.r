# Uses Classification techniques LDA, QDA, and SVM to predict if a starting 
# pitcher will be elected into the National Baseball Hall of Fame.

rm(list = ls())
library(dplyr)
library(dbplyr)
library(sqldf)
library(MASS)
library(e1071)
library(ggplot2)

# Setting up the database tables
# Dataset from SeanLahman.com
# Reading in CSV files as data frames
pl = read.csv("./baseballdatabank/core/Master.csv")
pi = read.csv("./baseballdatabank/core/Pitching.csv")
as = read.csv("./baseballdatabank/core/AllstarFull.csv")
aw = read.csv("./baseballdatabank/core/AwardsPlayers.csv")
h = read.csv("./baseballdatabank/core/HallOfFame.csv")

# Preping data for conversion for pitcher career stats
players = subset(pl, select = c(playerID, nameFirst, nameLast))
pitching = subset(pi, GS > 0, select = c(playerID, W, L, IPouts, ER, HR, BB, SO))
allstars = subset(as, select = playerID)
cy_youngs = subset(aw, awardID == "Cy Young Award", select = c(playerID, awardID))
mvps = subset(aw, awardID == "Most Valuable Player", select = c(playerID, awardID))
hof = subset(h, category == "Player", select = c(playerID, inducted))

db = dbConnect(SQLite(), dbname="pitch_stats.sqlite")
dbWriteTable(conn = db, name ="Players", value = players, row.names = FALSE)
dbWriteTable(conn = db, name ="Pitching", value = pitching, row.names = FALSE)
dbWriteTable(conn = db, name ="AllStars", value = allstars, row.names = FALSE)
dbWriteTable(conn = db, name ="CyYoungs", value = cy_youngs, row.names = FALSE)
dbWriteTable(conn = db, name ="MVPs", value = mvps, row.names = FALSE)
dbWriteTable(conn = db, name ="HallOfFame", value = hof, row.names = FALSE)
dbDisconnect(db)

# I use build_pitchercareers.sql to edit the data within pitch_stats.sqlite to
# create table called PictherCareers. This table holds names, wins, losses, outs
# pitched, earned runs, home runs, walks, strikeouts, number of Cy Youngs won,
# number of regular season MVPs won, and, if he is eligible, has been elected to
# the National Baseball Hall Of Fame yet.

# Load the pitcher data
db = dbConnect(SQLite(), dbname="pitch_stats.sqlite")
eligible = dbGetQuery(db,'select * from PitcherCareers where inducted is not null')
ineligible = dbGetQuery(db,'select * from PitcherCareers where inducted is null')
dbDisconnect(db)

eligible$inducted = as.factor(eligible$inducted)
eligible = subset(eligible, IPouts >= 6000)  # Clear out non SP HOFers
row.names(eligible) = 1:nrow(eligible)
elig_temp = subset(eligible, select = -c(playerID, nameLast, nameFirst))
ineligible$inducted = "N"
ineligible$inducted[1] = "Y"
ineligible$inducted = as.factor(ineligible$inducted)
inelg_temp = subset(ineligible, select = -c(playerID, nameLast, nameFirst))

# Looking at covariance matricies
y = subset(elig_temp, inducted == "Y")
n = subset(elig_temp, inducted == "N")
M1 = as.matrix(y[1:10])
M2 = as.matrix(n[1:10])
cov(M1)
cov(M2)

# Creating classification models
lda = lda(inducted ~ ., data = elig_temp)
pred.lda = predict(lda, elig_temp)
mean(elig_temp$inducted != pred.lda$class)

qda = qda(inducted ~ ., data = elig_temp)
pred.qda = predict(qda, elig_temp)
mean(elig_temp$inducted != pred.qda$class)

svm = svm(inducted ~ ., data = elig_temp)
pred.svm = predict(svm, data = elig_temp)
mean(elig_temp$inducted != pred.svm)

# Cross-validation
K = 10
n = nrow(elig_temp)
test.size = ceiling(n/K)
train.size = n - test.size
lda.err.cv = rep(NA,K)
qda.err.cv = rep(NA,K)
svm.err.cv = rep(NA,K)

for (i in 1:100){
  foo = sample(n,train.size)
  train.data = elig_temp[foo,]
  test.data = elig_temp[-foo,]
  lda.cv = lda(inducted~.,data=train.data)
  pred.lda.cv = predict(lda.cv,test.data)
  lda.err.cv[i] = mean(test.data$inducted!=pred.lda.cv$class)
  qda.cv = qda(inducted~.,data=train.data)
  pred.qda.cv = predict(qda.cv,test.data)
  qda.err.cv[i] = mean(test.data$inducted!=pred.qda.cv$class)
  svm.cv = svm(inducted~.,data=train.data)
  pred.svm.cv = predict(svm.cv,test.data)
  svm.err.cv[i] = mean(test.data$inducted!=pred.svm.cv)
}
mean(lda.err.cv)
mean(qda.err.cv)
mean(svm.err.cv)

# Predictions

# Randy Johnson
big_unit = elig_temp[159, ]
predict(lda, big_unit)
predict(qda, big_unit)
predict(svm, big_unit)

# George Zettelin
zett = elig_temp[385, ]
predict(lda, zett)
predict(qda, zett)
predict(svm, zett)

# Mike Mussina
mussina = elig_temp[236, ]
predict(lda, mussina)
predict(qda, mussina)
predict(svm, mussina)

# Clayton Kershaw
kershaw = inelg_temp[27, ]
predict(lda, kershaw)
predict(qda, kershaw)
predict(svm, kershaw)

# Jordan Zimmerman
zimmerman = inelg_temp[56, ]
predict(lda, zimmerman)
predict(qda, zimmerman)
predict(svm, zimmerman)

# Max Scherzer
scherzer = inelg_temp[47, ]
predict(lda, scherzer)
predict(qda, scherzer)
predict(svm, scherzer)

# Roger Clemens
clemens = elig_temp[53, ]
predict(lda, clemens)
predict(qda, clemens)
predict(svm, clemens)

# whoever
player = inelg_temp[21, ]
predict(lda, player)
predict(qda, player)
predict(svm, player)

ggplot(eligible, aes(x = IPouts, y = ER, colour = inducted, label = nameLast)) +
  geom_point() + geom_text(aes(label=nameLast),hjust=0, vjust=0)

ggplot(ineligible, aes(x = IPouts, y = ER, label = nameLast)) +
  geom_point() + geom_text(aes(label=nameLast),hjust=0, vjust=0)

# Does SVM overfit?
clem_temp = elig_temp
clem_temp[1013, "inducted"] = "Y"
clemens2 = clem_temp[1013, ]
lda2 = lda(inducted ~ ., data = clem_temp)
qda2 = qda(inducted ~ ., data = clem_temp)
svm2 = svm(inducted ~ ., data = clem_temp)
predict(lda2, clemens2)
predict(qda2, clemens2)
predict(svm2, clemens2)
