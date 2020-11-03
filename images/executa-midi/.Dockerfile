# Generated by Dockta 0.22.2 at 2020-11-03T20:48:15.464Z
# To stop Dockta generating this file and start editing it yourself,
# rename it to "Dockerfile".

# This tells Docker which base image to use.
FROM stencila/executa-all

# All installation commands are run as the root user
USER root

# This section installs system packages needed to add extra system repositories.
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common

# This section adds system repositories required to install extra system packages.
RUN curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 51716619E084DAB9
RUN apt-add-repository "deb https://deb.nodesource.com/node_12.x eoan main" \
 && apt-add-repository "deb https://mran.microsoft.com/snapshot/2020-11-01/bin/linux/ubuntu eoan-cran35/"

# This section sets environment variables within the image.
ENV TZ="Etc/UTC"

# This section installs system packages required for your project
# If you need extra system packages add them here.
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      gdal-bin \
      git-core \
      libcurl4-openssl-dev \
      libfribidi-dev \
      libgdal-dev \
      libgeos-dev libgeos++-dev \
      libgit2-dev \
      libharfbuzz-dev \
      libpng-dev \
      libssh2-1-dev \
      libssl-dev \
      libtiff-dev \
      libudunits2-dev \
      libxml2-dev \
      make \
      nodejs \
      pandoc pandoc-citeproc \
      python3 \
      python3-pip \
      r-base \
      zlib1g-dev \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# It's good practice to run Docker images as a non-root user.
# This section creates a guest user (if necessary) and sets its home directory as the default working directory.
RUN id -u guest >/dev/null 2>&1 || useradd --create-home --uid 1000 -s /bin/bash guest
WORKDIR /home/guest

# This is a special comment to tell Dockta to manage the build from here on
# dockta

# This section copies package requirement files into the image
COPY package.json package.json
COPY requirements.txt requirements.txt
COPY DESCRIPTION DESCRIPTION

# This section runs commands to install the packages specified in the requirement file/s
RUN npm install package.json \
 && pip3 install --requirement requirements.txt \
 && bash -c "Rscript <(curl -sL https://unpkg.com/@stencila/dockta/src/install.R)"

# This sets the default user when the container is run
USER guest
