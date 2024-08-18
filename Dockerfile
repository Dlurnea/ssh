# Mengganti base image sesuai permintaan
FROM debian:latest

ARG AUTH_TOKEN
ARG PASSWORD=rootuser

# Install packages dan set locale
RUN apt-get update \
    && apt-get install -y locales nano ssh sudo python3 curl wget unzip \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Konfigurasi ngrok dan SSH
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8

RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip \
    && unzip ngrok.zip \
    && rm ngrok.zip \
    && chmod +x ngrok \
    && mkdir /run/sshd

# Membuat skrip docker.sh
RUN echo "#!/bin/bash\n" > /docker.sh \
    && echo "/ngrok tcp --authtoken ${AUTH_TOKEN} 22 &" >> /docker.sh \
    && echo "sleep 10" >> /docker.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; import re; try: data = json.load(sys.stdin); url = data['tunnels'][0]['public_url']; print(f'SSH Info:\\nssh root@{re.sub(r'^https?://', '', url)}\\nROOT Password: ${PASSWORD}'); except (IndexError, KeyError, json.JSONDecodeError): print('Error: Failed to retrieve Ngrok tunnel information');\"" >> /docker.sh \
    && echo '/usr/sbin/sshd -D' >> /docker.sh \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo root:${PASSWORD} | chpasswd \
    && chmod +x /docker.sh

# Expose ports yang diperlukan
EXPOSE 80 8888 8080 443 5130-5135 3306 7860

# Jalankan skrip saat container mulai
CMD ["/bin/bash", "/docker.sh"]
