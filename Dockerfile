FROM ubuntu:22.04

# Prevent interactive prompts during apt installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install dependencies
RUN apt-get update && apt-get install -y \
    perl \
    libncurses5 \
    apache2 \
    libapache2-mod-perl2 \
    libxml-libxml-perl \
    libunicode-string-perl \
    libterm-readkey-perl \
    libmime-lite-perl \
    libmime-types-perl \
    libdigest-sha-perl \
    libdbd-mysql-perl \
    libxml-parser-perl \
    libxml2-dev \
    libxml-twig-perl \
    libarchive-any-perl \
    libjson-perl \
    lynx \
    wget \
    ghostscript \
    poppler-utils \
    antiword \
    python3-html2text \
    texlive-base \
    texlive-base-bin \
    psutils \
    imagemagick \
    tar \
    gzip \
    unzip \
    libsearch-xapian-perl \
    libtex-encode-perl \
    libconfig-general-perl \
    liblwp-protocol-https-perl \
    libtext-unidecode-perl \
    libio-string-perl \
    gcc \
    make \
    mariadb-client \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add eprints user and group
RUN useradd -m -s /bin/bash -d /opt/eprints3 eprints \
    && usermod -aG sudo eprints

# Copy EPrints source code
COPY . /tmp/eprints-src
WORKDIR /tmp/eprints-src

# Build and install EPrints
RUN ./configure --prefix=/opt/eprints3 --with-user=eprints --with-group=eprints \
    && make \
    && make install

# Setup Apache
RUN a2enmod perl && \
    echo "Include /opt/eprints3/cfg/apache.conf" > /etc/apache2/sites-available/eprints.conf && \
    a2ensite eprints && \
    a2dissite 000-default

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Fix permissions
RUN chown -R eprints:eprints /opt/eprints3

# Configure Apache environment variables to run as eprints
RUN sed -i 's/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=eprints/' /etc/apache2/envvars && \
    sed -i 's/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=eprints/' /etc/apache2/envvars

EXPOSE 80

WORKDIR /opt/eprints3
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2ctl", "-D", "FOREGROUND"]
