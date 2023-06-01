FROM rockylinux/rockylinux:9.1-minimal as download_ssp

ARG SIMPLE_SAML_PHP_VERSION=2.0.4
ARG SIMPLE_SAML_PHP_HASH=10f50ae5165b044cd4c78de3c118a025ecf47586e428f16b340933f9d44ab52c

RUN microdnf update -y
RUN microdnf install -y wget tar php \
    && ssp_version=$SIMPLE_SAML_PHP_VERSION; \
           ssp_hash=$SIMPLE_SAML_PHP_HASH; \
           wget https://github.com/simplesamlphp/simplesamlphp/releases/download/v$ssp_version/simplesamlphp-$ssp_version.tar.gz \
    && echo "$ssp_hash  simplesamlphp-$ssp_version.tar.gz" | sha256sum -c - \
    && cd /var \
    && tar xzf /simplesamlphp-$ssp_version.tar.gz \
    && mv simplesamlphp-$ssp_version simplesamlphp \
    && cp simplesamlphp/config/config.php.dist simplesamlphp/config/config.php \ 
    && cp simplesamlphp/config/authsources.php.dist simplesamlphp/config/authsources.php \
    && sed -i 's/123/123456/g'  simplesamlphp/config/config.php \
    && sed -i 's/defaultsecretsalt/defaultsecretsalt123456/g'  simplesamlphp/config/config.php \ 
    $$ sed -i -e '/loggingdir/s/\/\///' simplesamlphp/config/config.php \
    && sed -i 's/myapp.example.org/myapp.uhu.es/g' simplesamlphp/config/authsources.php \
    && wget https://getcomposer.org/installer -O composer-installer.php && php composer-installer.php --filename=composer --install-dir=/usr/local/bin

FROM rockylinux/rockylinux:9.1-minimal

LABEL maintainer="Unicon, Inc."

# ARG PHP_VERSION=7.4.19
# ARG HTTPD_VERSION=2.4.37

COPY --from=download_ssp /var/simplesamlphp /var/simplesamlphp
COPY --from=download_ssp /usr/local/bin /usr/local/bin

#RUN dnf module enable -y php:7.4 \
#    && dnf install -y httpd-$HTTPD_VERSION php-$PHP_VERSION \
#    && dnf clean all \
#    && rm -rf /var/cache/yum

VOLUME /var/simplesamlphp
    
RUN microdnf install -y httpd php  php-intl php-zip mod_ssl git \
    && microdnf clean all \
    && rm -rf /var/cache/yum
    
RUN echo $'\nSetEnv SIMPLESAMLPHP_CONFIG_DIR /var/simplesamlphp/config\nAlias /simplesaml /var/simplesamlphp/public\n \
<Directory /var/simplesamlphp/public>\n \
    Require all granted\n \
</Directory>\n' \
       >> /etc/httpd/conf.d/simplesamlphp.conf
       
RUN openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=ES/ST=Huelva/L=Huelva/O=UHU/CN=localhost" \
    -keyout /etc/pki/tls/private/localhost.key  -out /etc/pki/tls/certs/localhost.crt
    
RUN openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=ES/ST=Huelva/L=Huelva/O=UHU/CN=localhost" \
    -keyout /etc/pki/tls/private/localhost.key  -out /etc/pki/tls/certs/localhost.crt

COPY httpd-foreground /usr/local/bin/

EXPOSE 80 443

CMD ["httpd-foreground"]
