library(plyr)
library(ggplot2)
library(caret)
library(RColorBrewer)
setwd("~/Desktop/plankton_accuracy/")

sol <- read.csv("sol.csv")
sub <- read.csv("sub.csv")

#Image name order may not match
sol <- arrange(sol, image)
sub <- arrange(sub, image)

#Use only public fold for now
public_idx = which(sol$Usage == "Public")
sol <- sol[public_idx,]
sub <- sub[public_idx,]

get_predicted_class <- function(p) {
  return(names(which.max(p)))
}

levels <- names(sol)[2:122] #Skip the image names at the front, and the usage label at the end
preds  <- factor(apply(sub[,2:122], 1, get_predicted_class), levels = levels)
actual <- factor(apply(sol[,2:122], 1, get_predicted_class), levels = levels)

# Overall accuracy
accuracy = sum(preds == actual) / length(actual)

# Plot a confusion matrix
X <- as.table(confusionMatrix(preds, actual))
jBuPuFun <- colorRampPalette(brewer.pal(n = 9, "BuPu"))
jBuPuPalette <- jBuPuFun(256)
pdf("heatmap.pdf", height=11, width=11)
heatmap(as.matrix(X), Rowv = NA, Colv = NA, col = jBuPuPalette, scale = "col", margins = c(14,14))
dev.off()
