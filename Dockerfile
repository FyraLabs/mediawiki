FROM alpine:latest AS preparer

RUN apk add --no-cache patch

WORKDIR /tmp
RUN wget https://extdist.wmflabs.org/dist/extensions/PluggableAuth-REL1_39-dc30743.tar.gz
RUN tar -xzf PluggableAuth-REL1_39-dc30743.tar.gz
RUN wget https://extdist.wmflabs.org/dist/extensions/OpenIDConnect-REL1_39-92b7b46.tar.gz
RUN tar -xzf OpenIDConnect-REL1_39-92b7b46.tar.gz
RUN wget https://extdist.wmflabs.org/dist/extensions/NativeSvgHandler-REL1_39-95310ed.tar.gz
RUN tar -xzf NativeSvgHandler-REL1_39-95310ed.tar.gz
RUN wget https://extdist.wmflabs.org/dist/extensions/CodeMirror-REL1_39-e5c63ef.tar.gz
RUN tar -xzf CodeMirror-REL1_39-e5c63ef.tar.gz
RUN wget https://extdist.wmflabs.org/dist/extensions/TemplateStyles-REL1_39-a8c062d.tar.gz
RUN tar -xzf TemplateStyles-REL1_39-a8c062d.tar.gz

COPY oidc-composer.patch .
RUN patch -i oidc-composer.patch OpenIDConnect/composer.json

FROM mediawiki:1.39 as builder

WORKDIR /tmp

RUN apt update && apt install -y unzip
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

WORKDIR /var/www/html

COPY --from=preparer /tmp/PluggableAuth extensions/PluggableAuth
COPY --from=preparer /tmp/OpenIDConnect extensions/OpenIDConnect
COPY --from=preparer /tmp/NativeSvgHandler extensions/NativeSvgHandler
COPY --from=preparer /tmp/CodeMirror extensions/CodeMirror
COPY --from=preparer /tmp/TemplateStyles extensions/TemplateStyles
COPY composer.local.json .
COPY htaccess .htaccess

RUN composer update

# NOTE(lexisother): Trust me, this is absolutely necessary, otherwise the patch
# applied to the composer.json further above will NOT take effect.
RUN cd extensions/OpenIDConnect && composer update && cd ../../

FROM mediawiki:1.39

COPY --from=builder /var/www/html /var/www/html
