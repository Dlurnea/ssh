# Gunakan base image Ubuntu 22.04
FROM ubuntu:22.04

ARG AUTH_TOKEN
ARG PASSWORD=rootuser

# Install paket-paket yang diperlukan dan set locale
RUN apt-get update \
    && apt-get install -y locales nano ssh sudo python3 curl wget unzip \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8

# Download dan konfigurasi ngrok
RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip \
    && unzip ngrok.zip \
    && rm ngrok.zip \
    && mkdir /run/sshd \
    && echo "/ngrok tcp --authtoken ${AUTH_TOKEN} 22 &" >>/docker.sh \
    && echo "sleep 5" >> /docker.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; print(\\\"SSH Info:\\\n\\\",\\\"ssh\\\",\\\"root@\\\"+json.load(sys.stdin)['tunnels'][0]['public_url'][6:].replace(':', ' -p '),\\\"\\\nROOT Password:${PASSWORD}\\\")\" || echo \"\nError: AUTH_TOKEN, Reset ngrok token & try again\n\"" >> /docker.sh \
    && echo '/usr/sbin/sshd -D' >>/docker.sh \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo root:${PASSWORD} | chpasswd \
    && chmod 755 /docker.sh

# Konfigurasi tampilan IP saat login melalui SSH
RUN echo 'echo -e "\nIPv4 Addresses:\n$(hostname -I)" >> ~/.bashrc' >> /etc/skel/.bashrc \
    && echo 'echo -e "IPv6 Addresses:\n$(ip -6 addr show | grep "inet6" | awk '{print $2}')" >> ~/.bashrc' >> /etc/skel/.bashrc \
    && echo 'echo "Welcome, $(whoami)!"' >> /etc/skel/.bashrc

# Expose ports yang diperlukan
EXPOSE 80 8888 8080 443 5130-5135 3306 7860

# Jalankan skrip saat container mulai
CMD ["/bin/bash", "/docker.sh"]
