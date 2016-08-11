#FILE: DNASE2TF.R
#AUTH: Bharath Vasagam
# Created as a requirement for CWL wrapper of DNASE2TF originally created by , Songjoon Baek
#http://www.cell.com/cms/attachment/2040785497/2054587687/mmc1.pdf
library(data.table)
library(hash)
library(multicore)
library(Rsamtools)
library(dnase2tf)

#arguments: 1: Island_file, 2: Datafilepath_ chr(N).txt, 3: mapfiledir Mappability file dir 
#4: Assembly file dir_ chr(N).fa 5: dftfile

args <- commandArgs(trailingOnly = TRUE)
initial.options <- commandArgs(trailingOnly = FALSE)[4]
file.arg.name <- "--file="
script.name <- sub(file.arg.name, "", initial.options[grep(file.arg.name, initial.options)])
script.basename <- dirname(script.name)
Input_island <- args[1]
Input_island<-read.csv(args[1], stringsAsFactors = FALSE)
#Remove Chromosome M and data cleaning
Input_island = Input_island[Input_island[ ,"chrom"] != "chrM", ]
new_island = Input_island[ ,c("chrom", "start", "end")]
new_island = unique(new_island)
new_island = new_island[complete.cases(new_island),]

write.table(new_island, paste0(script.basename,"/hotspots.bed"), quote=F, col.names=F, row.names=F, append=F, sep="\t")
hotspotfilename = paste0(script.basename,"/hotspots.bed")
datafilepath = args[2]
outputfilepath = paste0(script.basename,"/output")
dir.create(outputfilepath, showWarnings=F)
mapfiledir = args[3]

dnase2tf(datafilepath, hotspotfilename, mapfiledir, outputfilepath,
         assemseqdir=args[4],
         dftfilename= args[5],
         maxw=30,
         minw=6,
         z_threshold =-2,
         numworker = 10,
         FDRs=c(0, 0.001, 0.005, 0.01, 0.05, 0.1 ,0.2));

