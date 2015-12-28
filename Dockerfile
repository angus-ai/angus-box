FROM debian:jessie

#
# Install Dependencies
#
RUN sed -i "s/jessie main/jessie main contrib non-free/" /etc/apt/sources.list
RUN    apt-get -y upgrade

# Python
RUN    apt-get update
RUN    apt-get install -y \
  python-pip \
  python-opencv \
  python-scipy \
  python-dateutil \
  python-virtualenv \
  python

# Web server
RUN    apt-get update
RUN    apt-get install -y \
  nginx-extras \
  ssl-cert

# Compilation
RUN    apt-get update
RUN    apt-get install -y \
  git \
  libjpeg-dev \
  python-dev \
  libopencv-dev \
  libboost-all-dev \
  cython \
  cmake

# Process control
RUN    apt-get update
RUN    apt-get install -y \
  supervisor \
  sudo

# Text to speech
RUN    apt-get update
RUN    apt-get install -y \
  libttspico-utils

# Zbar
RUN    apt-get install -y \
  python-zbar

#
# Create user angus
#
RUN    mkdir -p /home/angus
RUN    mkdir -p /var/log/angus
RUN    adduser angus --shell /bin/bash
RUN    chown angus:angus /home/angus
RUN    rm /bin/sh && ln -s /bin/bash /bin/sh
#
# Python virtualenv
#
RUN    virtualenv /home/angus/angus-env --system-site-packages
COPY   etc/requirements.txt /tmp/
RUN    source /home/angus/angus-env/bin/activate; \
       pip install -r /tmp/requirements.txt

#
# Import all services (git clone)
#
RUN    cd /home/angus/; git clone https://github.com/angus-ai/angus-gateway.git
RUN    cd /home/angus/; git clone https://github.com/angus-ai/angus-framework.git
RUN    cd /home/angus/; git clone https://github.com/angus-ai/angus-service-dummy.git
RUN    cd /home/angus/; git clone https://github.com/angus-ai/angus-service-facedetection.git
#
# Update all git repositories
# To update repository just touch on UPDATE_GIT.txt
#
ADD    UPDATE_GIT.txt /tmp/UPDATE_GIT.txt
RUN    cd /home/angus/angus-gateway; git fetch; git pull --rebase
RUN    cd /home/angus/angus-framework; git fetch; git pull --rebase
RUN    for file in `ls -d /home/angus/angus-service-*`; do cd $file; git fetch; git pull --rebase; done;

#
# Packages compilation & installation
#
# Gateway
RUN    source /home/angus/angus-env/bin/activate; \
       python /home/angus/angus-gateway/bin/angus-access.py -db sqlite:///home/angus/client.db -a init; \
       python /home/angus/angus-gateway/bin/angus-access.py -db sqlite:///home/angus/client.db -a create -id 7f5933d2-cd7c-11e4-9fe6-490467a5e114 -t db19c01e-18e5-4fc2-8b81-7b3d1f44533b; \
       python /home/angus/angus-gateway/bin/angus-access.py -db sqlite:///home/angus/client.db -a htpasswd > /home/angus/htpasswd

# Framework
RUN    source /home/angus/angus-env/bin/activate; \
       pip install -e /home/angus/angus-framework

USER   root
#
# Copy configuration files (angus)
#
ADD    etc/services.json /home/angus/
ADD    etc/env.sh /home/angus/
RUN    chown angus:angus /home/angus/*
#
# Copy configuration files (root)
#
ADD    etc/supervisord.conf /etc/supervisor/conf.d/
ADD    etc/nginx.conf /etc/nginx/sites-enabled/default
ADD    etc/sudoers /etc/
RUN    chmod 0440 /etc/sudoers

RUN    cp /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/gate.angus.ai.key
RUN    cp /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/gate.angus.ai.crt
RUN    cp /etc/ssl/certs/ssl-cert-snakeoil.pem /home/angus/angus-gateway/static/landing_page/certificate.pem
RUN    chown angus:angus /home/angus/angus-gateway/static/landing_page/certificate.pem
#
# Run process control
#
CMD    ["supervisord", "-n"]

EXPOSE 80 443 
