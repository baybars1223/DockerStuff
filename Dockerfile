# Docker-Moodle
# Dockerfile for moodle instance. more dockerish version of https://github.com/sergiogomez/docker-moodle
# Forked from Jon Auer's docker version. https://github.com/jda/docker-moodle
FROM ubuntu:16.04
LABEL maintainer="M <Eudocimus.R4@gmail.com>"

VOLUME ["/var/moodledata"]
EXPOSE 80 443
COPY moodle-config.php /var/www/html/config.php

# Keep upstart from complaining
# RUN dpkg-divert --local --rename --add /sbin/initctl
# RUN ln -sf /bin/true /sbin/initctl

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Database info and other connection information derrived from env variables. See readme.
# Set ENV Variables externally Moodle_URL should be overridden.
ENV MOODLE_URL http://127.0.0.1

ADD ./foreground.sh /etc/apache2/foreground.sh

#Update packages
RUN apt-get update && \
#Install php, mysql and essential packages
apt-get -y install software-properties-common && \
add-apt-repository ppa:ondrej/php && \
apt-get update && \
apt-get -y install git vim apache2 mysql-client mysql-server php5.6 libapache2-mod-php5.6 graphviz aspell php5.6-pspell php5.6-curl php5.6-gd php5.6-intl php5.6-mysql php5.6-xml php5.6-xmlrpc php5.6-ldap php5.6-zip git nano && \
#When prompted, set a root password for mysql
#Restart apache server to load modules correctly
service apache2 restart && \
#Download  moodle
cd /opt && \
git clone git://git.moodle.org/moodle.git && \
cd moodle && \
#Choose which branch to track (As of writing this tutorial, MOODLE_32 is the most recent stable branch)
git branch -a && \
git branch --track MOODLE_32_STABLE origin/MOODLE_32_STABLE && \
git checkout MOODLE_32_STABLE && \
#Copy local repository and set proper privileges
cp -R /opt/moodle /var/www/ && \
mkdir /var/moodledata && \
chown -R www-data /var/moodledata && \
chmod -R 777 /var/moodledata && \
chmod -R 0755 /var/www/moodle
#cron
COPY moodlecron /etc/cron.d/moodlecron
RUN chmod 0644 /etc/cron.d/moodlecron

# Enable SSL, moodle requires it
RUN a2enmod ssl && a2ensite default-ssl  #if using proxy dont need actually secure connection

# Cleanup, this is ran to reduce the resulting size of the image.
RUN apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/dpkg/* /var/lib/cache/* /var/lib/log/*

CMD ["/etc/apache2/foreground.sh"]