FROM mediawiki:1.39 as builder

WORKDIR /tmp

RUN apt update && apt install -y unzip
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

WORKDIR /var/www/html

ENV MEDIAWIKI_BRANCH REL1_39

RUN git clone --depth 1 -b $MEDIAWIKI_BRANCH \
    https://gerrit.wikimedia.org/r/mediawiki/extensions/PluggableAuth extensions/PluggableAuth
RUN git clone --depth 1 -b $MEDIAWIKI_BRANCH \
    https://gerrit.wikimedia.org/r/mediawiki/extensions/NativeSvgHandler extensions/NativeSvgHandler
RUN git clone --depth 1 -b $MEDIAWIKI_BRANCH \
    https://gerrit.wikimedia.org/r/mediawiki/extensions/CodeMirror extensions/CodeMirror
RUN git clone --depth 1 -b $MEDIAWIKI_BRANCH \
    https://gerrit.wikimedia.org/r/mediawiki/extensions/TemplateStyles  extensions/TemplateStyles
RUN git clone --depth 1 -b $MEDIAWIKI_BRANCH \
    https://gerrit.wikimedia.org/r/mediawiki/extensions/UserMerge extensions/UserMerge
RUN git clone --depth 1 -b $MEDIAWIKI_BRANCH \
    https://github.com/FyraLabs/mediawiki-extensions-OpenIDConnect extensions/OpenIDConnect
RUN git clone --depth 1 -b 1.14 \
    https://github.com/kulttuuri/DiscordNotifications extensions/DiscordNotifications
RUN git clone --depth 1 -b v2.9.1 \
    https://github.com/StarCitizenTools/mediawiki-skins-Citizen skins/Citizen

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
