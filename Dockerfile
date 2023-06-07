FROM alpine:latest AS preparer

RUN apk add --no-cache patch

WORKDIR /tmp
# We need a version pinning system. WMFLABS URLs CHANGE ALL THE TIME.
RUN wget https://extdist.wmflabs.org/dist/extensions/PluggableAuth-REL1_39-fac6234.tar.gz
RUN tar -xzf PluggableAuth-REL1_39-fac6234.tar.gz
RUN wget https://github.com/FyraLabs/mediawiki-extensions-OpenIDConnect/archive/df16f783f40502344f4ba08711f4a202e6cad1c6.tar.gz
RUN tar -xzf df16f783f40502344f4ba08711f4a202e6cad1c6.tar.gz
RUN mv mediawiki-extensions-OpenIDConnect-df16f783f40502344f4ba08711f4a202e6cad1c6 OpenIDConnect
RUN wget https://extdist.wmflabs.org/dist/extensions/NativeSvgHandler-REL1_39-95310ed.tar.gz
RUN tar -xzf NativeSvgHandler-REL1_39-95310ed.tar.gz
RUN wget https://extdist.wmflabs.org/dist/extensions/CodeMirror-REL1_39-0313917.tar.gz
RUN tar -xzf CodeMirror-REL1_39-0313917.tar.gz
RUN wget https://extdist.wmflabs.org/dist/extensions/TemplateStyles-REL1_39-2adabe9.tar.gz
RUN tar -xzf TemplateStyles-REL1_39-2adabe9.tar.gz
RUN wget -O DiscordNotifications.tar.gz https://github.com/kulttuuri/DiscordNotifications/archive/a46e3f22adbe24ba853f38a5579d718027e4d80b.tar.gz
RUN mkdir DiscordNotifications && tar -xzf DiscordNotifications.tar.gz -C DiscordNotifications --strip-components 1
RUN wget -O Citizen.tar.gz https://github.com/StarCitizenTools/mediawiki-skins-Citizen/archive/main.tar.gz
RUN tar -xzf Citizen.tar.gz
RUN mv mediawiki-skins-Citizen-main Citizen

# COPY oidc-composer.patch .
# RUN patch -i oidc-composer.patch OpenIDConnect/composer.json

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
COPY --from=preparer /tmp/DiscordNotifications extensions/DiscordNotifications
COPY --from=preparer /tmp/Citizen skins/Citizen
COPY composer.local.json .
COPY htaccess .htaccess

RUN composer update

# NOTE(lexisother): Trust me, this is absolutely necessary, otherwise the patch
# applied to the composer.json further above will NOT take effect.
# RUN cd extensions/OpenIDConnect && composer update && cd ../../

FROM mediawiki:1.39

# Lua setup, Scribunto has no binaries for arm64
RUN apt update && apt install -y lua5.1 vim
RUN mkdir /var/www/logs && chmod -R o+w /var/www/logs

COPY --from=builder /var/www/html /var/www/html
