library(haven)
library(gmodels)
library(vcd)
library(smbinning)
library(dplyr)
library(stringr)

accepts <- read_sas("C:/Users/Kristin/Documents/Financial Analytics/Homework1/accepted_customers.sas7bdat")
accepts <- as.data.frame(accepts)
# Understand Target Variable #
table(accepts$GB)

#Change it so goods are flagged instead
accepts$GB <- abs(accepts$GB - 1)
table(accepts$GB)

# Create Training and Validation #
set.seed(12345)
train_id <- sample(seq_len(nrow(accepts)), size = floor(0.70*nrow(accepts)))

train <- accepts[train_id, ]
test <- accepts[-train_id, ]

#Understand Target Variable in Training and tEst
table(train$GB)
table(test$GB)

#checking types and number of variables 
names <- names(train)
length(names)#26 variables

num_names <- names(train)[sapply(train, is.numeric)] 
length(num_names) #18

factor_names <- names(train)[sapply(train, is.factor)] 
length(factor_names)#0 variables

character_names <- names(train)[sapply(train, is.character)]
length(character_names)#8

#changing falsely labed "numeric" variables to correctly labeled factor variables 
factor_list <- list() # Creating empty list to store factor variables

for(i in 1:length(num_names)){
  check_res <- smbinning(df = train, y = "GB", x = num_names[i])
  if(check_res == "Uniques values < 5") {
    factor_list[[num_names[i]]] <- check_res
  }
}


#Splitting numeric variables into numeric and factor variables 

length(num_names)#18 --checking the length 
length(names)#26 --checking the lenghth
length(factor_list)#9 --checking the length 


factors <- unlist(factor_list, recursive = TRUE, use.names = TRUE)#turning list back into vector
factor_names <- names(factors) #getting the names
#factor_names <- type.convert(factor_names) #converting type to factor in vector 
for(i in factor_names){
  train[[i]]<-as.factor(train[[i]]) #looping through factor vector to change type to factor in dataframe
}


num_names <- setdiff(num_names, factor_names) #subtracting the factor variables from the numeric variables
length(num_names)#9 #checking the length 

#binning all continous variables 
num_all_sig <- list() # Creating empty list to store all results #

for(i in 1:length(num_names)){
  check_res <- smbinning(df = train, y = "GB", x = num_names[i])
  
  if(check_res == "Uniques values < 5") {
    next
  }
  else if(check_res == "No significant splits") {
    next
  }
  else if(check_res$iv < 0.1) {
    next
  }
  else {
    num_all_sig[[num_names[i]]] <- check_res
  }
}


#binning all factor variables 
factor_all_sig <- list() # Creating empty list to store all results #

for(i in 1:length(factor_names)){
  check_res <- smbinning.factor(df = train, y = "GB", x = factor_names[i])
  
  if(check_res == "No significant splits") {
    next
  }
  else if(check_res$iv < 0.1) {
    next
  }
  else {
    factor_all_sig[[factor_names[i]]] <- check_res
  }
}


# Generating Variables of Bins and WOE Values for numeric variables #
for(i in 1:length(num_all_sig)) {
  train <- smbinning.gen(df = train, ivout = num_all_sig[[i]], chrname = paste(num_all_sig[[i]]$x, "_bin", sep = ""))
}

for (j in 1:length(num_all_sig)) {
  for (i in 1:nrow(train)) {
    bin_name <- paste(result_all_sig[[j]]$x, "_bin", sep = "")
    bin <- substr(train[[bin_name]][i], 2, 2)
    
    woe_name <- paste(result_all_sig[[j]]$x, "_WOE", sep = "")
    
    if(bin == 0) {
      bin <- dim(result_all_sig[[j]]$ivtable)[1] - 1
      train[[woe_name]][i] <- result_all_sig[[j]]$ivtable[bin, "WoE"]
    } else {
      train[[woe_name]][i] <- result_all_sig[[j]]$ivtable[bin, "WoE"]
    }
  }
}
    
