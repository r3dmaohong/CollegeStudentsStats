##Descriptive statistics of University path...

##############
## Preparation
##############
rm(list = ls()) #Remove all objects in the environment
gc() ##Free up the memory

if(!exists("original_path"))
  original_path <- getwd()
setwd(file.path("CollegeStudentsStats"))

options(scipen=999)
dir.create(file.path("output", Sys.Date()), showWarnings = FALSE)

##libraries
options(java.parameters = "-Xmx2g")
library(readxl)
library(data.table)
library(dplyr)
library(stringdist)
library(XLConnect)

##
insertRow <- function(existingDF, newrow, r) {
  existingDF[seq(r+1,nrow(existingDF)+1),] <- existingDF[seq(r,nrow(existingDF)),]
  existingDF[r,] <- newrow
  existingDF
}

##Find the file...
list.files("input")
n              <- readline(prompt="Enter the folder's name: ") ##list.files("input")[1]
totalFormFName <- list.files(file.path("input", n), full=T)[grepl("��t¾�P�a��", list.files(file.path("input", n)))]

##Standard data
MatchTable    <- read_excel(totalFormFName, sheet = "�Ǩt�������")
OldEducation  <- read_excel(totalFormFName, sheet = "�ɾ��Ź�")
OldEmployment <- read_excel(totalFormFName, sheet = "�N�~�Ź�")

##Raw data
EducationFName      <- list.files(file.path("input", n), full=T)[grepl("�ɾ�", list.files(file.path("input", n)))]
EmploymentFName     <- list.files(file.path("input", n), full=T)[grepl("�N�~", list.files(file.path("input", n)))]
wb                  <- loadWorkbook(EducationFName)
RawEducation        <- readWorksheet(wb, sheet = 1, header = FALSE)
RawEducation[2, ]
names(RawEducation) <- RawEducation[2, ]
RawEducation        <- RawEducation[-c(1:2), ]
wb                  <- loadWorkbook(EmploymentFName)
RawEmployment       <- readWorksheet(wb, sheet = 1, header = TRUE)

IndustryRenew <- read.csv("���~�s���Ovs�����O.csv", stringsAsFactors=F)
JobRenew      <- read.csv("¾�Ȥp���ഫ��.csv", stringsAsFactors=F)
##CollegeNameT  <- read.csv("�ǮզW�٥��W�ƪ���.csv",stringsAsFactors=F)

##Remove redundant curriculum vitaes...
RawEmployment$�i���s�� <- NULL
RawEmployment <- unique(setDT(RawEmployment))

Employment <- RawEmployment[, c("�|���s��","�ǮեN�X", "�ǮզW��", "��t�W��", "��t���O�N��", 
                           "��t���O�W��", "���~�p���N�X", "���~�p���W��", 
                           "¾�Ȥp���N�X", "¾�Ȥp���W��", "���~�p���N�X1",
                           "���~�p���W��1", "¾�Ȥp���N�X1", "¾�Ȥp���W��1",
                           "���~�p���N�X2", "���~�p���W��2", "¾�Ȥp���N�X2",
                           "¾�Ȥp���W��2", "���~�p���N�X3", "���~�p���W��3", 
                           "¾�Ȥp���N�X3", "¾�Ȥp���W��3"), with=FALSE ]

Employment <- Employment[!grepl("[0-9]", �ǮզW��)]
Employment <- Employment[!grepl("�Ǥ��Z", ��t�W��)]

##College names correction...
Employment <- Employment[�ǮզW�� %in% MatchTable$�ǮզW��]
Employment$SchoolName <- Employment$�ǮզW��
#for(x in unique(Employment$�ǮզW��)){
#  tmp <- ifelse(toString(rev(sort(CollegeNameT$������[CollegeNameT$trim���l == x ]))[1])!="" & toString(rev(sort(CollegeNameT$������[CollegeNameT$trim���l== x]))[1])!="NA"
#                , rev(sort(CollegeNameT$������[CollegeNameT$trim���l== x]))[1]
#                , x)
#  if(x!=tmp)
#    Employment$SchoolName[which(Employment$�ǮզW��==x)] <- tmp
#}
#for(x in unique(Employment$SchoolName)){
#  ##Fuzzy matching : find the Min dist word
#  Employment$SchoolName[which(Employment$SchoolName==x)] <- unique(MatchTable$�ǮզW��)[which.min(stringdist(x, unique(MatchTable$�ǮզW��) ,method='jw'))][1]
#}

##Check
#Employment[�ǮզW��!=SchoolName, .(�ǮզW��, SchoolName)] %>% unique

##Department names corrections...
Employment$Department <- Employment$��t�W��

UniMatchT        <- MatchTable[, c("�ǮզW��", names(MatchTable)[11])] %>% unique
names(UniMatchT) <- c("�ǮզW��", "��t�W��")
UniMatchT        <- UniMatchT[which(UniMatchT$��t�W��!="NULL"), ]
EmploymentMatchT <- Employment[, .(SchoolName, Department)] %>% unique

#check <- data.frame("Original"=character(), "Match"=character(), stringsAsFactors = FALSE)
for(i in 1:nrow(EmploymentMatchT)){
  ##Fuzzy matching : find the Min dist word
  tmp <- UniMatchT$��t�W��[UniMatchT$�ǮզW��==Employment$SchoolName[i]][which.min(stringdist(EmploymentMatchT$Department[i], UniMatchT$��t�W��[UniMatchT$�ǮզW��==Employment$SchoolName[i]] ,method='jw'))][1]
  
  if(EmploymentMatchT$Department[i]!=tmp){
    Employment$Department[which(Employment$SchoolName==EmploymentMatchT$SchoolName[i] & Employment$Department==EmploymentMatchT$Department[i])] <- tmp
    #check <- insertRow(check, c(EmploymentMatchT$Department[i], tmp), 1)
  } 
  cat("\r Department Correction : ", format(round(i/nrow(EmploymentMatchT)*100, 2), nsmall=2), " %")
}




##########
## Module
##########
DStatModule <- function(DT, school, department, target){
  ##Try new method...
  ##Not using eval..., just rename the col in the function...
  ##More readable?
  setDF(DT)
  names(DT)[which(names(DT)==school)]     <- "School"
  names(DT)[which(names(DT)==department)] <- "Department"
  names(DT)[which(names(DT)==target)]     <- "Target"

  DStatDT <- DT[ , .N, by= .(School, Department, Target)]
  DStatDT <- DStatDT[order(School, Department, -N)]
  #DStatDT[, Percentage:=N/sum(N), by = .(School, Department)]
  
  return(DStatDT)
}
#cbnName="�W��(�@)"
UpdateModule <- function(ODT, NDT, cbnName){
  setDT(ODT)
  #school, department, index of cbnName and the next one
}


####################
## Start : Education
####################

#####################
## Start : Employment
#####################