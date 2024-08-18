FROM debian:latest

ARG NGROK_TOKEN
ARG REGION=ap

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update, upgrade, dan install paket yang diperlukan
RUN apt update && apt upgrade -y \
    && apt install -y ssh wget unzip vim curl python3 \
    && rm -rf /var/lib/apt/lists/*

# Download dan konfigurasi ngrok
RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip \
    && unzip ngrok.zip \
    && rm ngrok.zip \
    && mkdir /run/sshd \
    && echo "/ngrok tcp --authtoken ${NGROK_TOKEN} --region ${REGION} 22 &" >>/docker.sh \
    && echo "sleep 5" >> /docker.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; print(\\\"SSH Info:\\\n\\\",\\\"ssh\\\",\\\"root@\\\"+json.load(sys.stdin)['tunnels'][0]['public_url'][6:].replace(':', ' -p '))\" || echo \"\nError: NGROK_TOKEN, Reset ngrok token & try again\n\"" >> /docker.sh \
    && echo '/usr/sbin/sshd -D' >>/docker.sh \
    && chmod 755 /docker.sh

# Konfigurasi SSH dan root login
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo root:root | chpasswd

# Expose ports yang diperlukan
EXPOSE 22

# Jalankan skrip saat container mulai
CMD ["/bin/bash", "/docker.sh"]
