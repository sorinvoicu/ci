# R environment with .NET 8 for OSPSuite packages
FROM rocker/r-ver:4.4.2

LABEL org.opencontainers.image.source="https://github.com/sorinvoicu/ci"
LABEL org.opencontainers.image.description="Immutable R environment with OSPSuite packages"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Common R package dependencies
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libcairo2-dev \
    libxt-dev \
    # For clipboard support
    xclip \
    # For .NET
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install .NET 8 SDK
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet \
    && rm dotnet-install.sh \
    && ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet

ENV DOTNET_ROOT=/usr/share/dotnet
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Copy package list
COPY r-packages.txt /tmp/r-packages.txt

# Install pak and R packages
RUN Rscript -e "install.packages('pak', repos='https://cloud.r-project.org/')" \
    && Rscript -e " \
        packages <- readLines('/tmp/r-packages.txt'); \
        packages <- packages[packages != '']; \
        for (pkg in packages) { \
            pkg_release <- paste0(pkg, '@*release'); \
            message('Installing: ', pkg_release); \
            pak::pak(pkg_release); \
        } \
    "

# Verify key packages load (package names differ from repo names)
RUN Rscript -e " \
    packages <- c('rSharp', 'ospsuite', 'tlf', 'ospsuite.utils', 'ospsuite.parameteridentification', 'esqlabsR'); \
    for (pkg in packages) { \
        message('Loading: ', pkg); \
        library(pkg, character.only = TRUE); \
        message(pkg, ' loaded successfully!'); \
    }; \
    message('All packages validated!'); \
"

# Clean up and make library read-only
RUN rm -rf /tmp/* /var/tmp/* \
    && chmod -R a-w /usr/local/lib/R/site-library

# Disable package installation at runtime
RUN echo 'options(install.packages.check.source = "never")' >> /usr/local/lib/R/etc/Rprofile.site \
    && echo 'install.packages <- function(...) stop("Package installation is disabled in this environment")' >> /usr/local/lib/R/etc/Rprofile.site \
    && echo 'remove.packages <- function(...) stop("Package removal is disabled in this environment")' >> /usr/local/lib/R/etc/Rprofile.site \
    && echo 'update.packages <- function(...) stop("Package updates are disabled in this environment")' >> /usr/local/lib/R/etc/Rprofile.site

WORKDIR /workspace

CMD ["R"]
