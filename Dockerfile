# Official images are cool.
FROM jenkins
MAINTAINER oolongd <oolongdo@gmail.com>

# Jenkins is using jenkins user, we need root to install things.
USER root

# Install php packages.
RUN apt-get update
RUN apt-get -y -f install php5-cli php5-dev php5-curl curl php-pear ant 

# Install required jenkins plugins.
RUN /usr/local/bin/install-plugins.sh checkstyle cloverphp crap4j dry htmlpublisher jdepend \
    plot pmd violations warnings xunit ant git-client scm-api git bitbucket publish-over-ssh greenballs \
    workflow-aggregator ansicolor docker-build-publish

# Install php xdebug extension for code coverage
# Setup the Xdebug version to install
ENV XDEBUG_VERSION 2.3.3
ENV XDEBUG_MD5 60e6fdf41840104a23debe16db15a2af

# Install Xdebug
RUN set -x \
     && curl -SL "http://www.xdebug.org/files/xdebug-$XDEBUG_VERSION.tgz" -o xdebug.tgz \
     && echo $XDEBUG_MD5 xdebug.tgz | md5sum -c - \
     && mkdir -p /usr/src/xdebug \
     && tar -xf xdebug.tgz -C /usr/src/xdebug --strip-components=1 \
     && rm xdebug.* \
     && cd /usr/src/xdebug \
     && phpize \
     && ./configure \
     && make -j"$(nproc)" \
     && make install \
     && make clean

COPY ext-xdebug.ini /etc/php5/mods-available/
COPY ext-xdebug.ini /etc/php5/cli/conf.d/


# Install docker
RUN apt-get -y -f install docker.io

# Create a jenkins "HOME" for composer files.
RUN mkdir /home/jenkins
RUN chown jenkins:jenkins /home/jenkins

USER jenkins

#### This don't work as $JENKINS_HOME is a volume ####
# Install php template.
#RUN mkdir -p "$JENKINS_HOME/jobs/php-template"
#RUN curl -L https://raw.github.com/sebastianbergmann/php-jenkins-template/master/config.xml -o "$JENKINS_HOME/jobs/php-template/config.xml"
####                sad panda is sad              ####


# Install composer, yes we can't install it in $JENKINS_HOME :(
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/home/jenkins

# Install required php tools.
RUN /home/jenkins/composer.phar config -g repo.packagist composer https://packagist.phpcomposer.com
RUN /home/jenkins/composer.phar --working-dir="/home/jenkins" -n require phing/phing:2.* notfloran/phing-composer-security-checker:~1.0 \
    phploc/phploc:* phpunit/phpunit:~4.0 pdepend/pdepend:~2.0 phpmd/phpmd:~2.2 sebastian/phpcpd:* \
    squizlabs/php_codesniffer:* mayflower/php-codebrowser:~1.1 codeception/codeception:*
#RUN echo "export PATH=$PATH:/home/jenkins/.composer/vendor/bin" >> $JENKINS_HOME/.bashrc # Keep dreaming!

USER root
RUN apt-get clean -y

# Go back to jenkins user.
USER jenkins
