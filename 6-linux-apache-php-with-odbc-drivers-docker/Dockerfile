FROM    ubuntu:18.04
LABEL   maintainer="ChubbyCat" \
        git="https://github.com/raffi-ismail/lampodbc" \
        dockerhub="https://hub.docker.com/r/chubbycat/lampodbc"

RUN echo '#!/bin/sh' > /usr/sbin/policy-rc.d  && \
    echo 'exit 101' >> /usr/sbin/policy-rc.d  && \
    chmod +x /usr/sbin/policy-rc.d            && \
    dpkg-divert --local --rename --add /sbin/initctl  && \
    cp -a /usr/sbin/policy-rc.d /sbin/initctl         && \
    sed -i 's/^exit.*/exit 0/' /sbin/initctl          && \
    echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup   && \
    echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean  && \
    echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean && \
    echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean   && \
    echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages   && \
    echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes   && \
    echo 'Apt::AutoRemove::SuggestsImportant "false";' > /etc/apt/apt.conf.d/docker-autoremove-suggests

RUN rm -rf /var/lib/apt/lists/* && \
    mkdir -p /run/systemd && echo 'docker' > /run/systemd/container && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update -qq && apt-get upgrade -qqy && \
    apt-get install -qq -y apt-utils curl git \
            software-properties-common gcc make autoconf libc-dev pkg-config libmcrypt-dev

#RUN add-apt-repository ppa:ondrej/php && \
RUN apt-get install -qqy nano apt-transport-https bash zip unzip jq apache2  php7.2 libapache2-mod-php7.2 \
            php-xml php-pear php7.2-dev php-zip php-curl php-gd \
            php-zip php-mysql php-mbstring php-gmp && \
    apt-get update -qqy 
RUN pecl install mcrypt-1.0.1

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    curl https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb && \
    dpkg -i /tmp/packages-microsoft-prod.deb

RUN apt-get update -qqy && ACCEPT_EULA=Y apt-get install -qqy msodbcsql17 mssql-tools unixodbc-dev powershell
RUN echo extension=sqlsrv.so > /etc/php/7.2/mods-available/sqlsrv.ini && \
    echo extension=pdo_sqlsrv.so > /etc/php/7.2/mods-available/pdo_sqlsrv.ini && \
    ln -s /etc/php/7.2/mods-available/sqlsrv.ini /etc/php/7.2/apache2/conf.d/30-sqlsrv.ini && \
    ln -s /etc/php/7.2/mods-available/pdo_sqlsrv.ini /etc/php/7.2/apache2/conf.d/30-pdo_sqlsrv.ini && \
    curl -sLo /tmp/tmp.deb http://mirrors.kernel.org/ubuntu/pool/multiverse/liba/libapache-mod-fastcgi/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb && \
    dpkg -i /tmp/tmp.deb; apt-get install -f && \
    a2enmod actions fastcgi alias proxy_fcgi && \
    pecl install sqlsrv pdo_sqlsrv 

RUN apt-get update && apt-get install -y --no-install-recommends openssh-server  && echo "root:Docker!" | chpasswd

COPY etc/sshd_config /etc/ssh/

COPY etc/apache2.conf /etc/apache2/
COPY etc/000-default.conf /etc/apache2/sites-available/
COPY etc/php.ini /etc/php/7.2/apache2/
RUN a2enmod rewrite

WORKDIR /var/www
# RUN mkdir -p sandbox && chown -R root:root sandbox && chmod 777 sandbox
COPY etc/composer.json ./
COPY sh/setup-composer.sh /tmp/
RUN chmod +x /tmp/setup-composer.sh && /tmp/setup-composer.sh && ./composer.phar install

# RUN mv html/index.html html/index.old.html
# ADD html html/

COPY startup.sh /var/
RUN chmod +x /var/startup.sh

#WORKDIR /var/www/html/diddle

ENV DEFAULT_LISTEN_PORT_HTTP 80
#-- Not used at the moment ---
#ENV DEFAULT_WEB_LISTEN_PORT_HTTPS

# EXPOSE 2222 443 $PORT
# 2222 for SSH $PORT for $ENV variable if passed from Azure Web Apps (when VNet integration is configured)
# Otherwise $POST defaults to 80.
# SSH not available with Vnet integration 
EXPOSE 2222 $PORT


ENTRYPOINT ["/var/startup.sh"] 