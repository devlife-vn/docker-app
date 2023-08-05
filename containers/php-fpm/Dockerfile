# # author: quandn
# ARG FPM_PHP_VERSION

# FROM php:${FPM_PHP_VERSION}-fpm
# COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# # Set working directory
# WORKDIR /var/www

# RUN install-php-extensions bcmath
# RUN install-php-extensions bz2
# RUN install-php-extensions calendar
# RUN install-php-extensions csv
# # RUN install-php-extensions decimal
# RUN install-php-extensions exif
# RUN install-php-extensions gd
# RUN install-php-extensions geospatial
# RUN install-php-extensions gettext
# RUN install-php-extensions gnupg
# RUN install-php-extensions http
# RUN install-php-extensions imagick
# RUN install-php-extensions imap
# RUN install-php-extensions intl
# RUN install-php-extensions mcrypt
# RUN install-php-extensions mysqli
# RUN install-php-extensions oci8
# RUN install-php-extensions opcache
# RUN install-php-extensions pdo_mysql
# RUN install-php-extensions pdo_oci
# RUN install-php-extensions redis
# RUN install-php-extensions soap
# RUN install-php-extensions sockets
# RUN install-php-extensions ssh2
# RUN install-php-extensions vips
# RUN install-php-extensions yaml
# RUN install-php-extensions zip
# RUN install-php-extensions pcntl

# RUN apt-get update -y && apt-get install --no-install-recommends --no-install-suggests -y \
#     curl \
#     git \
#     ghostscript \
#     jq \
#     poppler-utils \
#     ssh \
#     unzip \
#     zip \
#     nano \
#     vim \
#     iputils-ping \
#     xz-utils \
#     libvips-tools && \
#     rm -rf /var/lib/apt/lists/* && \
#     apt-get autoremove -y && \
#     apt-get clean -y && \
#     rm -rf /var/lib/apt/lists/*

# RUN curl https://rclone.org/install.sh | bash
# RUN rclone config touch && \
#     cp /root/.config/rclone/rclone.conf /var/www/.rclone.conf && \
#     chown www-data:www-data /var/www/.rclone.conf

# RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
# RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
# RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
# RUN apt-get install -y nodejs
# RUN apt-get install -y yarn
# RUN apt-get update && apt-get install git

# RUN npm install -g @vue/cli
# RUN npm install -g cross-env

# RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
# COPY ./custom.ini $PHP_INI_DIR/conf.d/xy-custom.ini
# COPY ./pools/* $PHP_INI_DIR/pool.d/
# COPY ./laravel.ini /usr/local/etc/php/conf.d
# COPY ./xlaravel.pool.conf /usr/local/etc/php-fpm.d/

# USER root

# # Clean up
# RUN apt-get clean && \
#     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
#     rm /var/log/lastlog /var/log/faillog

# # Configure non-root user.
# ARG PUID=1000
# ENV PUID ${PUID}
# ARG PGID=1000
# ENV PGID ${PGID}

# RUN groupmod -o -g ${PGID} www-data && \
#     usermod -o -u ${PUID} -g www-data www-data

# EXPOSE 80 8083

# CMD ["php-fpm"]



ARG FPM_PHP_VERSION

FROM php:${FPM_PHP_VERSION}-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    nano \
    vim && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install NVM
RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
ENV NVM_DIR ~/.nvm
ENV NODE_VERSION 18.17.0

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get install nodejs -y
RUN apt-get install yarn -y
# RUN npm install @vue/cli
# RUN npm install cross-env

# Create system user to run Composer and Artisan Commands
ARG PUID=1000
ENV PUID ${PUID}
ARG PGID=1000
ENV PGID ${PGID}
RUN groupmod -o -g ${PGID} www-data && \
    usermod -o -u ${PUID} -g www-data www-data

# Set working directory
WORKDIR /var/www

USER $user

EXPOSE 80 8083