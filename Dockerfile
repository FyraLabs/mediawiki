FROM alpine:latest AS preparer

WORKDIR /tmp
RUN wget https://extdist.wmflabs.org/dist/extensions/PluggableAuth-REL1_39-8ad42e2.tar.gz
RUN tar -xzf PluggableAuth-REL1_39-8ad42e2.tar.gz
RUN wget https://extdist.wmflabs.org/dist/extensions/OpenIDConnect-REL1_39-92b7b46.tar.gz
RUN tar -xzf OpenIDConnect-REL1_39-92b7b46.tar.gz

FROM mediawiki:1.39 as builder

WORKDIR /tmp

RUN apt update && apt install -y unzip
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

WORKDIR /var/www/html

COPY --from=preparer /tmp/PluggableAuth extensions/PluggableAuth
COPY --from=preparer /tmp/OpenIDConnect extensions/OpenIDConnect
COPY composer.local.json .

RUN composer update

FROM mediawiki:1.39

COPY --from=builder /var/www/html /var/www/html
