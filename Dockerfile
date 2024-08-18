# Base image
FROM debian

ARG NGROK_TOKEN
ARG PASSWORD=rootuser
ENV DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt update && apt upgrade -y && apt install -y \
    ssh wget unzip vim curl python3

# Configure SSH tunnel using ngrok
RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip \
    && unzip ngrok.zip \
    && rm ngrok.zip \
    && mkdir /run/sshd \
    && echo "/ngrok tcp --authtoken ${NGROK_TOKEN} 22 &" >> /docker.sh \
    && echo "sleep 5" >> /docker.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; print(\\\"SSH Info:\\\n\\\",\\\"ssh\\\",\\\"root@\\\"+json.load(sys.stdin)['tunnels'][0]['public_url'][6:].replace(':', ' -p '),\\\"\\\nROOT Password:${PASSWORD}\\\")\" || echo \"\nError：NGROK_TOKEN，Reset ngrok token & try\n\"" >> /docker.sh \
    && echo '/usr/sbin/sshd -D' >> /docker.sh \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo root:${PASSWORD} | chpasswd \
    && chmod 755 /docker.sh

EXPOSE 22
CMD ["/bin/bash", "/docker.sh"]
