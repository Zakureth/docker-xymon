FROM ubuntu:20.04
MAINTAINER Dewey Sasser <dewey@deweysasser.com>

ENV DEBIAN_FRONTEND=noninteractive TZ=posixrules
ADD AutomaticCleanup /etc/apt/apt.conf.d/99AutomaticCleanup

# Install what we need from Ubuntu
RUN apt-get update

# tcpdump is for debugging client issues, others are required
RUN apt-get install -y curl xymon apache2 tcpdump ssmtp mailutils rrdtool ntpdate tzdata vim-tiny ntpdate rpcbind fping dumb-init traceroute

#
# No need to pull dumb-init directlt, it's part of ubuntu
#
# Get the 'dumb init' package for proper 'init' behavior
# RUN curl -L https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_amd64.deb > dumb-init.deb && \
#     dpkg -i dumb-init.deb && \
#     rm dumb-init.deb

ADD add-files /

# Enable necessary apache components
# make sure the "localhost" is correctly identified
# and ensure the ghost list can be updated
# Then, save the configuration so when this container starts with a
# blank volume, we can initialize it

RUN a2enmod rewrite authz_groupfile cgi info status; \
     perl -i -p -e "s/^127.0.0.1.*/127.0.0.1    xymon-docker # bbd apache http:\/\/localhost\//" /etc/xymon/hosts.cfg; \
     chown xymon:xymon /etc/xymon/ghostlist.cfg /var/lib/xymon/www ; \
     tar -C /etc/xymon -czf /root/xymon-config.tgz . ; \
     tar -C /var/lib/xymon -czf /root/xymon-data.tgz .



VOLUME /etc/xymon /var/lib/xymon
EXPOSE 80 1984

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/etc/init.d/container-start"]

HEALTHCHECK --interval=5m --timeout=3s --start-period=10s \
  CMD /usr/lib/xymon/server/bin/xymon localhost ping || exit 1
