FROM mcr.microsoft.com/mssql/server:2019-CTP3.1-ubuntu
LABEL   maintainer="ChubbyCat" \
        git="https://github.com/raffi-ismail/sqlsrv2019sandbox" \
        dockerhub="https://hub.docker.com/r/chubbycat/lampodbc"

ENV MSSQL_PID Developer
# The SA user password (mssqlserv picks this up in startup.sh)
# Also for sandbox SQL username and password
ENV SA_PASSWORD DiddleDoo2019
ENV SANDBOX_DB AdventureWorks
ENV SANDBOX_USERNAME diddle
ENV SANDBOX_PASSWORD #Diddl3#
# SQL DATA DIR
ENV SQL_DATA_DIR /var/opt/mssql/data
# Location of tmp dir where backup file is stored
ENV TMP_DIR /tmp
# Backup filename (without extension)
ENV DEMO_BACKUP_NAME AdventureWorks2017

ENV DEFAULT_DOCKER_EXPOSE_PORT 1433

RUN apt-get update -qq && apt-get install -qqy apt-utils curl wget
# The following are needed if building container from vanilla Ubuntu distros.
# Uncommenting them when building from mssql/server images will result in duplicate source.list errors/warnings
# RUN curl https://packages.microsoft.com/keys/microsoft.asc |  apt-key add -
# RUN curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | tee /etc/apt/sources.list.d/msprod.list

# ODBC Drivers
RUN apt-get install -qqy  mssql-tools unixodbc-dev
# Set Paths
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
# RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc && source ~/.bashrc

# sqlserv data directory, needs to be writable
WORKDIR $SQL_DATA_DIR
RUN chmod -R +w ./

# Copy stsrtup scripts, make shell script executable
WORKDIR /var
COPY $DEMO_BACKUP_NAME.bak /$TMP_DIR/
COPY startup.* ./
COPY setup.* ./
RUN chmod +x *.sh

ENV DELAY_IN_SECONDS_BEFORE_SETUPSQL 60

RUN ./setup.sh


EXPOSE $PORT
ENTRYPOINT [ "/bin/bash", "-c" ];
CMD [ "/var/startup.sh"]