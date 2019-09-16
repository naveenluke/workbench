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
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
# https://cran.r-project.org/bin/linux/ubuntu/README.html
RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/" | sudo tee -a /etc/apt/sources.list
# https://launchpad.net/~marutter/+archive/ubuntu/c2d4u3.5
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

# MAKE DEFAULT USER SUDO

# give jovyan sudo permissions
RUN sed -i -e "s/Defaults    requiretty.*/ #Defaults    requiretty/g" /etc/sudoers
RUN echo "jovyan ALL= (ALL) NOPASSWD: ALL" >> /etc/sudoers.d/jovyan
