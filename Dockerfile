#################################################################
# Dockerfile
#
# Software:         DNASE2TF
# Description:      DNASE2TF Image for Scidap
# Website:          https://bitbucket.org/young_computation/rose, http://scidap.com/
# Provides:         Samtools | Perl | R with Packages multicore, hash, Rsamtools, data.table
# Base Image:       scidap/scidap:v0.0.1
# Build Cmd:        docker build --rm -t scidap/dnase2tf .
# Pull Cmd:         docker pull scidap/dnase2tf
# Run Cmd:          docker run --rm scidap/dnase2tf
#################################################################

FROM scidap/samtools:v1.2-242-4d56437
MAINTAINER BHARATH MANICKA VASAGAM bharath.manickavasagam@cchmc.org
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /usr/local/bin/

### Install required packages
#To configure the virtualbox with another DNS
#CMD "sh" "-c" "echo nameserver 8.8.8.8 > /etc/resolv.conf"
#change the nameserver in resolv.conf to current DNS server

RUN rm -rf /var/lib/apt/lists/* && \ 
  apt-get clean all && \
  apt-get update && \
  apt-get install -y \
  libncurses5-dev \
  libz-dev \
  bedtools \
  bamtools \
  libboost-all-dev \
  libjsoncpp-dev \
  ed \
  less \
  locales \
  wget \
  r-base \
  perl

#Install bamtools
RUN wget -O bamtools-master.zip "https://github.com/pezmaster31/bamtools/archive/master.zip" && \
unzip bamtools-master.zip && \
rm bamtools-master.zip && \
cd bamtools-master && \
mkdir build && \
cd build && \
cmake .. && \
make && \
cd ../.. 

#Install R libraries 

RUN echo 'install.packages(c("hash", "data.table"), repos="http://cran.us.r-project.org", dependencies=TRUE)\n\
source("https://bioconductor.org/biocLite.R")\n\
biocLite("Rsamtools")\n\
install.packages("https://cran.r-project.org/src/contrib/Archive/multicore/multicore_0.2.tar.gz", repos=NULL, type="source")\n\
install.packages("https://sourceforge.net/projects/dnase2tfr/files/dnase2tf_1.0.tar.gz/download?use_mirror=autoselect",repos=NULL, type= "source")\n'\
>> package_install.R && \
Rscript package_install.R

#Mappability code
RUN mkdir Mappability && \
cd Mappability && \
wget -O - 'http://archive.gersteinlab.org/proj/PeakSeq/Mappability_Map/Code/Mappability_Map.tar.gz' | tar -zxv && \
make && \
ln -s /usr/local/bin/Mappability_Map/chr2hash /usr/local/bin && \
ln -s /usr/local/bin/Mappability_Map/mergeOligoCounts /usr/local/bin && \
ln -s /usr/local/bin/Mappability_Map/oligoFindPLFFile /usr/local/bin && \ 
cd .. && \
#bam_compact_utility
mkdir bam_compact_split_util && \
cd bam_compact_split_util && \
wget -O bam_compact_split_util.zip 'http://sourceforge.net/projects/dnase2tfr/files/bam_compact_split_util.zip'/download?use_mirror=autoselect && \
unzip bam_compact_split_util.zip && \
rm -f bam_compact_split_util.zip

# Downloading calcDFT files
RUN mkdir calcDFT && \
cd calcDFT && \
wget -O Makefile 'http://downloads.sourceforge.net/project/dnase2tfr/calcDFT/Makefile?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fdnase2tfr%2Ffiles%2FcalcDFT%2F&ts=1470674455&use_mirror=pilotfiber' && \
wget -O calcDFT.cpp 'http://downloads.sourceforge.net/project/dnase2tfr/calcDFT/calcDFT.cpp?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fdnase2tfr%2Ffiles%2FcalcDFT%2F&ts=1470674519&use_mirror=pilotfiber' && \
wget -O bamfilereader.h 'http://downloads.sourceforge.net/project/dnase2tfr/calcDFT/bamfilereader.h?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fdnase2tfr%2Ffiles%2FcalcDFT%2F&ts=1470674535&use_mirror=pilotfiber' && \
wget -O bamfilereader.cpp 'http://downloads.sourceforge.net/project/dnase2tfr/calcDFT/bamfilereader.cpp?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fdnase2tfr%2Ffiles%2FcalcDFT%2F&ts=1470674552&use_mirror=pilotfiber'
#Change the makefile of CALCDFT program
RUN echo '5,6c5,6\n\
< BAMTOOL_INCLUDEDIR = /home/sjbaek/Data/Programs/bamtools/include/\n\
< BAMTOOL_LIBDIR= /home/sjbaek/Data/Programs/bamtools/lib/\n\
---\n\
> BAMTOOL_INCLUDEDIR = /usr/local/bin/bamtools-master/src\n\
> BAMTOOL_LIBDIR= /usr/lib/x86_64-linux-gnu/\n\
11c11\n\
< LDFLAGS = -L$(BAMTOOL_LIBDIR) -lbamtools-utils -ljsoncpp -lbamtools -lboost_filesystem -lboost_system\n\
---\n\
> LDFLAGS = -L$(BAMTOOL_LIBDIR) -lbamtools -lbamtools-utils -lboost_system -lboost_filesystem\n'\
>> patch.diff && \
mv patch.diff calcDFT/patch.diff && \
cd calcDFT && \
patch Makefile < patch.diff && \
ls -s /usr/local/bin/bamtools-master/lib/* /usr/lib/x86_64-linux-gnu/ && \
cp /usr/local/bin/bamtools-master/lib/* /usr/lib/x86_64-linux-gnu/ && \
make && \
cd .. && \
chmod u+x calcDFT/calcDFT
