# Base image
FROM ubuntu:22.04

ARG NGROK_TOKEN
ARG PASSWORD=rootuser
ENV DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt update && apt upgrade -y && apt install -y \
    ssh wget unzip vim curl python3 gnupg2 lsb-release \
    ca-certificates build-essential libssl-dev libffi-dev python3-dev \
    python3-pip python3-venv mariadb-server mariadb-client nginx \
    && apt clean

# Install ngrok
RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip \
    && unzip ngrok.zip \
    && rm ngrok.zip \
    && mkdir /run/sshd

# Install Docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh \
    && sh get-docker.sh \
    && rm get-docker.sh

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Setup Pterodactyl Panel
RUN mkdir -p /var/www/pterodactyl \
    && cd /var/www/pterodactyl \
    && curl -LO https://github.com/pterodactyl/panel/releases/download/v1.8.1/panel.tar.gz \
    && tar -xzvf panel.tar.gz \
    && rm panel.tar.gz

# Add setup script
COPY setup.sh /setup.sh
RUN chmod +x /setup.sh

# Configure SSH and ngrok
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo root:${PASSWORD} | chpasswd \
    && echo "#!/bin/bash" > /docker.sh \
    && echo "/ngrok tcp 22 --authtoken ${NGROK_TOKEN} &" >> /docker.sh \
    && echo "sleep 5" >> /docker.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; data=json.load(sys.stdin); url=data['tunnels'][0]['public_url']; ip = url.split('//')[1].split(':')[0]; port = url.split(':')[1]; print(f'SSH Info:\\nssh root@{ip} -p {port}\\nROOT Password:{PASSWORD}')\" || echo \"Error: NGROK_TOKEN, Reset ngrok token & try\"" >> /docker.sh \
    && echo '/usr/sbin/sshd -D' >> /docker.sh \
    && chmod +x /docker.sh

EXPOSE 22

CMD ["/bin/bash", "/docker.sh"]
