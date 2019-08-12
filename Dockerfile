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
# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
# https://cran.r-project.org/bin/linux/ubuntu/README.html
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'
#RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/" | sudo tee -a /etc/apt/sources.list
# https://launchpad.net/~marutter/+archive/ubuntu/c2d4u3.5
RUN add-apt-repository ppa:marutter/c2d4u3.5
# Install CRAN binaries from ubuntu
RUN apt-get update && apt-get install -yq --no-install-recommends \
    r-base \
    # r-cran-httpuv \
    && apt-get clean \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    rm -rf /var/lib/apt/lists/*

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


# Fix permissions
RUN conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

USER $NB_UID


# MAKE DEFAULT USER SUDO

# give jovyan sudo permissions
RUN sed -i -e "s/Defaults    requiretty.*/ #Defaults    requiretty/g" /etc/sudoers
RUN echo "jovyan ALL= (ALL) NOPASSWD: ALL" >> /etc/sudoers.d/jovyan


# pre-requisites
RUN apt-get update && apt-get install -yq --no-install-recommends \
    libncurses5-dev \
    libncursesw5-dev \
    procps \
    texlive

# Install FastQC
RUN curl -fsSL http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.5.zip -o /opt/fastqc_v0.11.5.zip && \
    unzip /opt/fastqc_v0.11.5.zip -d /opt/ && \
    chmod 755 /opt/FastQC/fastqc && \
    ln -s /opt/FastQC/fastqc /usr/local/bin/fastqc && \
    rm /opt/fastqc_v0.11.5.zip

# Install Kallisto
RUN curl -fsSL https://github.com/pachterlab/kallisto/releases/download/v0.43.1/kallisto_linux-v0.43.1.tar.gz -o /opt/kallisto_linux-v0.43.1.tar.gz && \
    tar xvzf /opt/kallisto_linux-v0.43.1.tar.gz -C /opt/ && \
    ln -s /opt/kallisto_linux-v0.43.1/kallisto /usr/local/bin/kallisto && \
    rm /opt/kallisto_linux-v0.43.1.tar.gz

# Install STAR
RUN git clone https://github.com/alexdobin/STAR.git /opt/STAR && \
    ln -s /opt/STAR/bin/Linux_x86_64/STAR /usr/local/bin/STAR && \
    ln -s /opt/STAR/bin/Linux_x86_64/STARlong /usr/local/bin/STARlong

# Install SAMTools
RUN curl -fsSL https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2 -o /opt/samtools-1.9.tar.bz2 && \
    tar xvjf /opt/samtools-1.9.tar.bz2 -C /opt/ && \
    cd /opt/samtools-1.9 && \
    make && \
    make install && \
    rm /opt/samtools-1.9.tar.bz2

# Install featureCounts
RUN curl -fsSL http://downloads.sourceforge.net/project/subread/subread-1.5.1/subread-1.5.1-Linux-x86_64.tar.gz -o /opt/subread-1.5.1-Linux-x86_64.tar.gz && \
    tar xvf /opt/subread-1.5.1-Linux-x86_64.tar.gz -C /opt/ && \
    ln -s /opt/subread-1.5.1-Linux-x86_64/bin/featureCounts /usr/local/bin/featureCounts && \
    rm /opt/subread-1.5.1-Linux-x86_64.tar.gz

# Install cutadapt and MAGIC and awscli (to download data)
RUN pip install cutadapt magic-impute awscli

# Install TrimGalore
RUN mkdir /opt/TrimGalore && \
    curl -fsSL https://github.com/FelixKrueger/TrimGalore/archive/0.4.5.zip -o /opt/TrimGalore/trim_galore_v0.4.5.zip && \
    unzip /opt/TrimGalore/trim_galore_v0.4.5.zip -d /opt/TrimGalore && \
    ln -s /opt/TrimGalore/trim_galore /usr/local/bin/trim_galore && \
    rm /opt/TrimGalore/trim_galore_v0.4.5.zip

# Install bedtools2
RUN curl -fsSL https://github.com/arq5x/bedtools2/releases/download/v2.27.1/bedtools-2.27.1.tar.gz -o /opt/bedtools-2.27.1.tar.gz && \
    tar xvzf /opt/bedtools-2.27.1.tar.gz -C /opt/ && \
    cd /opt/bedtools2 && \
    make && \
    cd - && \
    cp /opt/bedtools2/bin/* /usr/local/bin && \
    rm /opt/bedtools-2.27.1.tar.gz

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
RUN Rscript -e 'install.packages(c("Seurat", "rJava", "umap", "bookdown", "cluster", "KernSmooth", "ROCR", "googleVis", "ggbeeswarm", "SLICER", "ggfortify", "mclust", "Rmagic", "DrImpute"))'

# Install Bioconductor packages
RUN Rscript -e 'BiocManager::install(c("graph", "RBGL", "gtools", "xtable", "pcaMethods", "limma", "SingleCellExperiment", "Rhdf5lib", "scater", "scran", "RUVSeq", "sva", "SC3", "TSCAN", "monocle", "destiny", "DESeq2", "edgeR", "MAST", "scmap", "biomaRt", "MultiAssayExperiment", "SummarizedExperiment"))'

# install github packages
RUN Rscript -e 'devtools::install_github(c("immunogenomics/harmony", "LTLA/beachmat", "MarioniLab/DropletUtils", "tallulandrews/M3Drop", "hemberg-lab/scRNA.seq.funcs", "Vivianstats/scImpute", "theislab/kBET", "kieranrcampbell/ouija", "hemberg-lab/scfind"))'

USER $NB_UID

