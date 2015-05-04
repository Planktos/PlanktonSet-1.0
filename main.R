rm(list = ls())
setwd("/Users/wcuk/git/KaggleCompetitions/BoozPlankton/")
library(plyr)
library(ggplot2)
library(stringr)
library(assertive)
library(EBImage)
rm(list=ls())
set.seed(5462522)

# Directories
rawDir <- "./raw_data/"
outDir <- "./competition_data/"
trainPct <- 0.5 #Percent to use as training set
publicPct <- 0.3 #Percent to use for public fold
numPoison <- 100000 #Number of poison images to use

# Remove Thumbs.db from folders
system("find ./raw_data -name \"Thumbs.db\" -exec rm \'{}\' \\;")

# Make directories
unlink(file.path(outDir,"train"), recursive = TRUE)
unlink(file.path(outDir,"test"), recursive = TRUE) 
dir.create(file.path(outDir, "train"), showWarnings = FALSE)
dir.create(file.path(outDir, "test"), showWarnings = FALSE)

# Images
numImages <- length(dir(rawDir, recursive = TRUE, pattern = "\\.jpg$"))
X <- data.frame(matrix(ncol = 0, nrow = numImages))
X$originalImage<- dir(rawDir, recursive = TRUE, pattern = "\\.jpg$", full.names = FALSE)

# Classes
X$class <- str_extract(X$originalImage, "^.*/") #directory is the class
X$class <- str_extract(X$class, "[^/]+") #removes trailing slash

# Split train/test
X$split <- ifelse(runif(numImages) < trainPct, "train", "test")

# Usage column
numTest <- sum(X$split == "test")
X$Usage[X$split == "test"] <- ifelse(runif(numTest) < publicPct, "Public", "Private")

# Poison the test set
X$isPoison <- FALSE
Y <- data.frame(
  originalImage = sample(X$originalImage[X$split == "test"], numPoison, replace = TRUE),
  class = NA,
  split = "test",
  Usage = "Ignored",
  isPoison = TRUE
  )
X <- rbind(X,Y) #Add the poison images
rm(Y)

# Every image gets a new random name
X$competitionImage <- paste(sample(numImages+numPoison), ".jpg", sep="")

# Function to poison (distort) images
poisonImage <- function(img) {
  numTimes <- sample(0:3,1)
  if (numTimes == 0 ) return(img)
  h <- dim(img)[1];
  w <- dim(img)[2];
  lopassfilter <- makeBrush(floor(0.05*w), shape='disc', step=FALSE)^2
  lopassfilter <- lopassfilter/sum(lopassfilter)
  for (k in  1:numTimes) {
    switch(sample(8,1),
             img <- img,
             img <- flip(img),
             img <- flop(img),
             img[sample(1:h,1), sample(1:w,1)] <- runif(1,0,1),
             img <- rotate(img, runif(1, 0, 5), bg.col = "white"),
             img2 <- translate(img, runif(2,-0.05*h,0.05*h)),
             img <- filter2(img, lopassfilter),
             img <- img + rnorm(h*w,mean=0,sd=runif(1,0,0.05))
        )
    }
  return(img)
}

# Important - make sure no unseen classes in the test set
allTestClasses <- unique(X$class[X$split=="test"])
allTrainClasses <- unique(X$class[X$split=="train"])
stopifnot(is.na(setdiff(allTestClasses,allTrainClasses))) #only class in test that isn't in train should be NA for poison images
allTestClasses <- setdiff(allTestClasses, NA) #remove the NA so it wont trip us up later

# Make folders for classes in the train set
allClasses <- unique(X$class)
for (class in allTrainClasses){
  dir.create(file.path(outDir, "train", class), showWarnings = FALSE)
}

# Shuffle entire dataset to make sure file timestamps do not correlate with classes
X <- X[sample(nrow(X)),]

# Ingest and spit out images
for(i in 1:nrow(X)) {
  fileName <- file.path(rawDir, X$originalImage[i])
  img <- readImage(fileName)
  
  if (X$split[i] == "train") { 
    #train set
    newFileName <- file.path(outDir, "train", X$class[i], X$competitionImage[i])
    writeImage(img, newFileName, quality = 100)
  } else {
    #test set
    newFileName <- file.path(outDir, "test", X$competitionImage[i])
    if(X$isPoison[i]){
      img <- poisonImage(img)
    }
    writeImage(img, newFileName, quality = 100)
  }
  print(i)
}

# Make solution file
Y <- X[X$split == "test",] # the test set
sol <- data.frame(matrix(0, nrow = numTest + numPoison, ncol = (length(allTestClasses) + 2))) # +2 for id and usage column
names(sol) <- c("image", allTestClasses, "Usage")
sol$image <- Y$competitionImage
sol$Usage <- Y$Usage
for (i in 1:nrow(Y)){
  if (!is.na(Y$class[i])){
    sol[i,Y$class[i]] <- 1
  }
}
sol <- arrange(sol,image) # sort by image
stopifnot(all(rowSums(sol[,2:(ncol(sol)-1)])<=1)) #No image should have more than one class
stopifnot(all(rowSums(sol[sol$Usage == "Ignored",2:(ncol(sol)-1)])==0)) #No ignored images should have a class
stopifnot(all(rowSums(sol[sol$Usage != "Ignored",2:(ncol(sol)-1)])==1)) #All images should have a class
write.csv(sol, file.path(outDir,"solution.csv"), quote = F, row.names = F)

# Make sample submission file
Y <- X[X$split == "test",] # the test set
sub <- data.frame(matrix(1/length(allTestClasses), nrow = numTest + numPoison, ncol = (length(allTestClasses) + 1))) # +1 for id
names(sub) <- c("image", allTestClasses)
sub$image <- Y$competitionImage
sub <- arrange(sub,image) # sort by image
stopifnot(all(rowSums(sub[,2:ncol(sub)])==1))
write.csv(sub, file.path(outDir,"sampleSubmission.csv"), quote = F, row.names = F)

# Save the image key for admin use
write.csv(X, file.path(outDir,"key.csv"), quote=F, row.names = F)
