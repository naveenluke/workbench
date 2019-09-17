# Distributed under the terms of the Modified BSD License.
FROM jupyter/base-notebook

USER root

# GENERAL PACKAGES

RUN apt-get update && apt-get install -yq --no-install-recommends \
    python3-software-properties \
    software-properties-common \
    apt-utils \
    gnupg2 \
    fonts-dejavu \
    tzdata \
    gfortran \
    curl \
    less \
    gcc \
    g++ \
    clang-6.0 \
    openssh-client \
    openssh-server \
    cmake \
    python-dev \
    libgsl-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2 \
    libxml2-dev \
    libapparmor1 \
    libedit2 \
    libhdf5-dev \
    libclang-dev \
    lsb-release \
    psmisc \
    rsync \
    vim \
    default-jdk \
    libbz2-dev \
    libpcre3-dev \
    liblzma-dev \
    zlib1g-dev \
    xz-utils \
    liblapack-dev \
    libopenblas-dev \
    libigraph0-dev \
    libreadline-dev \
    libblas-dev \
    libtiff5-dev \
    fftw3-dev \
    git \
    texlive-xetex \
    hdf5-tools \
    libffi-dev \
    gettext \
    libpng-dev \
    libpixman-1-0 \ 
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Select the right versio of libblas to be used
# there was a problem running R in python and vice versa
RUN pip install simplegeneric
RUN update-alternatives --install /etc/alternatives/libblas.so.3-x86_64-linux-gnu libblas /usr/lib/x86_64-linux-gnu/blas/libblas.so.3 5

# RStudio
ENV RSTUDIO_PKG=rstudio-server-1.1.463-amd64.deb
RUN wget -q http://download2.rstudio.org/${RSTUDIO_PKG}
RUN dpkg -i ${RSTUDIO_PKG}
RUN rm ${RSTUDIO_PKG}
# The desktop package uses /usr/lib/rstudio/bin
ENV PATH="${PATH}:/usr/lib/rstudio-server/bin"
ENV LD_LIBRARY_PATH="/usr/lib/R/lib:/lib:/usr/lib/x86_64-linux-gnu:/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server:/opt/conda/lib/R/lib"

# jupyter-rsession-proxy extension
RUN pip install git+https://github.com/jupyterhub/jupyter-rsession-proxy

# R PACKAGES

# R
# https://askubuntu.com/questions/610449/w-gpg-error-the-following-signatures-couldnt-be-verified-because-the-public-k
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'

RUN add-apt-repository ppa:marutter/c2d4u3.5
# Install CRAN binaries from ubuntu
RUN apt-get update && apt-get install -yq --no-install-recommends \
    r-base \
    # r-cran-httpuv \
    && apt-get clean \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    rm -rf /var/lib/apt/lists/*
    
RUN Rscript -e 'install.packages("hdf5r",configure.args="--with-hdf5=/usr/bin/h5cc")'


# PYTHON PACKAGES

# Install scanpy and other python packages
RUN pip install scanpy python-igraph louvain bbknn rpy2 tzlocal scvelo leidenalg
# Try to fix rpy2 problems
# https://stackoverflow.com/questions/54904223/importing-rds-files-in-python-to-be-read-as-a-dataframe
RUN pip install --upgrade rpy2 pandas
# scanorama
RUN git clone https://github.com/brianhie/scanorama.git
RUN cd scanorama/ && python setup.py install
# necessary for creating user environments 
RUN conda install --quiet --yes nb_conda_kernels

USER root
# install CRAN packages
RUN apt-get update && apt-get install -yq --no-install-recommends \
    r-cran-devtools \
    r-cran-tidyverse \
    r-cran-pheatmap \
    r-cran-plyr \
    r-cran-dplyr \
    r-cran-readr \
    r-cran-reshape \
    r-cran-reshape2 \
    r-cran-reticulate \
    r-cran-viridis \
    r-cran-ggplot2 \
    r-cran-ggthemes \
    r-cran-cowplot \
    r-cran-ggforce \
    r-cran-ggridges \
    r-cran-ggrepel \
    r-cran-gplots \
    r-cran-igraph \
    r-cran-car \
    r-cran-ggpubr \
    r-cran-httpuv \
    r-cran-xtable \
    r-cran-sourcetools \
    r-cran-modeltools \
    r-cran-R.oo \
    r-cran-R.methodsS3 \
    r-cran-shiny \
    r-cran-later \
    r-cran-checkmate \
    r-cran-bibtex \
    r-cran-lsei \
    r-cran-bit \
    r-cran-segmented \
    r-cran-mclust \
    r-cran-flexmix \
    r-cran-prabclus \
    r-cran-diptest \
    r-cran-mvtnorm \
    r-cran-robustbase \
    r-cran-kernlab \
    r-cran-trimcluster \
    r-cran-proxy \
    r-cran-R.utils \
    r-cran-htmlwidgets \
    r-cran-hexbin \
    r-cran-crosstalk \
    r-cran-promises \
    r-cran-acepack \
    r-cran-zoo \
    r-cran-npsurv \
    r-cran-iterators \
    r-cran-snow \
    r-cran-bit64 \
    r-cran-permute \
    r-cran-mixtools \
    r-cran-lars \
    r-cran-ica \
    r-cran-fpc \
    r-cran-ape \
    r-cran-pbapply \
    r-cran-irlba \
    r-cran-dtw \
    r-cran-plotly \
    r-cran-metap \
    r-cran-lmtest \
    r-cran-fitdistrplus \
    r-cran-png \
    r-cran-foreach \
    r-cran-vegan \
    r-cran-tidyr \
    r-cran-withr \
    r-cran-magrittr \
    r-cran-rmpi \
    r-cran-biocmanager \
    r-cran-knitr \
    r-cran-statmod \
    r-cran-mvoutlier \
    r-cran-penalized \
    r-cran-mgcv \
    r-cran-corrplot

# Install other CRAN
RUN Rscript -e 'install.packages(c("circlize"))'

# Install Bioconductor packages
RUN Rscript -e 'BiocManager::install(c("ELMER", "MultiAssayExperiment", "TxDb.Hsapiens.UCSC.hg38.knownGene","karyoploteR", "ComplexHeatmap", "TCGAbiolinks", "SummarizedExperiment", "GenomicRanges"))'

# MAKE DEFAULT USER SUDO

# give jovyan sudo permissions
RUN sed -i -e "s/Defaults    requiretty.*/ #Defaults    requiretty/g" /etc/sudoers
RUN echo "jovyan ALL= (ALL) NOPASSWD: ALL" >> /etc/sudoers.d/jovyan
