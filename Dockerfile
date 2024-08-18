# Base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.utf8

# Install packages and set locale
RUN apt-get update \
    && apt-get install -y \
        locales \
        nano \
        ssh \
        sudo \
        python3 \
        curl \
        wget \
        nginx \
        mysql-server \
        php-fpm \
        php-mysql \
        php-xml \
        php-mbstring \
        php-curl \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH tunnel using ngrok
ARG AUTH_TOKEN
ARG PASSWORD=rootuser

RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip \
    && unzip ngrok.zip \
    && rm ngrok.zip \
    && mkdir /run/sshd \
    && echo "/ngrok tcp --authtoken ${AUTH_TOKEN} 22 &" >> /docker.sh \
    && echo "sleep 5" >> /docker.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; print(\\\"SSH Info:\\\n\\\",\\\"ssh\\\",\\\"root@\\\"+json.load(sys.stdin)['tunnels'][0]['public_url'][6:].replace(':', ' -p '),\\\"\\\nROOT Password:${PASSWORD}\\\")\" || echo \"\nError：AUTH_TOKEN，Reset ngrok token & try\n\"" >> /docker.sh \
    && echo '/usr/sbin/sshd -D' >> /docker.sh \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo root:${PASSWORD} | chpasswd \
    && chmod 755 /docker.sh

# Configure Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Set up the web panel
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

# Expose ports
EXPOSE 80 443 22

# Start services
CMD ["/bin/bash", "/docker.sh"]
