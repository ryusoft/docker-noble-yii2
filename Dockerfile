FROM ubuntu:noble
LABEL maintainer="RYU Chua <me@ryu.my>"

ENV DEBIAN_FRONTEND=noninteractive \
    OS_LOCALE="en_US.UTF-8" \
    TZ="Asia/Kuala_Lumpur" \
    LANG=${OS_LOCALE} \
    LANGUAGE=${OS_LOCALE} \
    LC_ALL=${OS_LOCALE} \
    APACHE_CONF_DIR=/etc/apache2 \
    PHP_CONF_DIR=/etc/php/8.3 \
    PHP_DATA_DIR=/var/lib/php \
    BUILD_DEPS='software-properties-common'

COPY entrypoint.sh /sbin/entrypoint.sh

RUN apt-get update \
	&& apt-get install -y locales tzdata wget gnupg2 \
    && unlink /etc/localtime \
    && ln -s /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime \
	&& locale-gen ${OS_LOCALE} \
    && dpkg-reconfigure locales tzdata \
    && apt-get update \
    # Install common libraries
    && apt-get install --no-install-recommends -y $BUILD_DEPS \
    # Install PHP libraries
    && apt-get install -y apache2 php php-cli php-mbstring php-curl \
    	php-xml php-bcmath php-intl php-zip php-mysql php-pgsql php-json php-imagick php-gd php-memcached php-memcache \
    	libapache2-mod-php php8.3-dev php-pear phpunit libz-dev \
    	libfontenc1 x11-common xfonts-75dpi xfonts-base xfonts-encodings xfonts-utils fontconfig libxrender1 composer \
    # Apache settings
    && cp /dev/null ${APACHE_CONF_DIR}/conf-available/other-vhosts-access-log.conf \
    && a2enmod rewrite \
    # gRPC & Protobuf
    && pecl install grpc \
    && pecl install protobuf \
    # adding to config
    && echo "extension=grpc.so" > ${PHP_CONF_DIR}/mods-available/grpc.ini \
    && echo "extension=protobuf.so" > ${PHP_CONF_DIR}/mods-available/protobuf.ini \
    && ln -s ${PHP_CONF_DIR}/mods-available/grpc.ini ${PHP_CONF_DIR}/cli/conf.d/20-grpc.ini \
    && ln -s ${PHP_CONF_DIR}/mods-available/grpc.ini ${PHP_CONF_DIR}/apache2/conf.d/20-grpc.ini \
    && ln -s ${PHP_CONF_DIR}/mods-available/protobuf.ini ${PHP_CONF_DIR}/cli/conf.d/20-protobuf.ini \
    && ln -s ${PHP_CONF_DIR}/mods-available/protobuf.ini ${PHP_CONF_DIR}/apache2/conf.d/20-protobuf.ini \
    # cleaning
    && apt-get purge -y --auto-remove wget gnupg2 php-pear phpunit libz-dev \
    && apt-get purge -y --auto-remove $BUILD_DEPS \
    && apt-get autoremove -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/pear \
    # Forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log \
    && chmod 755 /sbin/entrypoint.sh \
    && chown www-data:www-data ${PHP_DATA_DIR} -Rf

EXPOSE 80 443

# By default, simply start apache.
CMD ["/sbin/entrypoint.sh"]
