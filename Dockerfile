FROM nginx:alpine
MAINTAINER Paul Valla <paul.valla+docker@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV HTTPD_USER nobody

RUN apk add --no-cache \
   php5-fpm supervisor php5-json \
   wget unzip patch php5-gd

# install h5ai and patch configuration
ENV H5AI_VERSION 0.29.0+002~140eb30
RUN wget -O h5ai.zip https://github.com/CoRfr/h5ai/raw/build/build/h5ai-$H5AI_VERSION.zip --no-check-certificate
RUN unzip h5ai.zip -d /usr/share/h5ai

# patch h5ai because we want to deploy it ouside of the document root and use /var/www as root for browsing
COPY class-setup.php.patch class-setup.php.patch
RUN patch -p1 -u -d /usr/share/h5ai/_h5ai/private/php/core/ -i /class-setup.php.patch && rm class-setup.php.patch

# make the cache writable
RUN chown ${HTTPD_USER} /usr/share/h5ai/_h5ai/public/cache/
RUN chown ${HTTPD_USER} /usr/share/h5ai/_h5ai/private/cache/

RUN mkdir /var/log/supervisor/
RUN apk del wget unzip patch
RUN rm -rf /var/cache/apk/* /tmp/*

# use supervisor to monitor all services
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# expose only nginx HTTP port
EXPOSE 80 443

# expose path
VOLUME /var/www
