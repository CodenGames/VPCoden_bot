apt-get update -y
apt-get upgrade -y
apt-get install -y sudo wget python3-pip curl sqlite3 supervisor

sudo apt install -y wget software-properties-common build-essential libnss3-dev zlib1g-dev libgdbm-dev libncurses5-dev   libssl-dev libffi-dev libreadline-dev libsqlite3-dev libbz2-dev
wget https://www.python.org/ftp/python/3.11.4/Python-3.11.4.tgz
tar xvf Python-3.11.4.tgz
cd Python-3.11.4
./configure --enable-optimizations
sudo make altinstall
cd ..
rm -rf Python-3.11.4.tgz
rm -rf Python-3.11.4

pip3.11 install qrcode==7.4.2 pyTelegramBotAPI==4.10.0 Pillow==9.4.0 path==16.6.0 paramiko==3.1.0 yoomoney==0.1.0 pandas==2.0.1 plotly==5.14.1 numpy==1.24.3 yookassa outline-vpn-api==3.0.0 aiohttp==3.8.3 aiosqlite==0.19.0 aiogram==2.25.1 outline-vpn-api==3.0.0 tinkoff-acquiring-api==0.1.3 walletpay==1.3.1 pydantic==2.5.3 cryptomusapi==1.0.1 flask==2.3.1 flask-httpauth==4.8.0
pip3.11 install --upgrade pip

echo -e '[program:bot]\ncommand=python3.11 /root/bot.py > /dev/null 2>&1\nautostart=true\nautorestart=true\nuser=root' > /etc/supervisor/conf.d/bot.conf
supervisorctl reread
supervisorctl update
echo -e 'SHELL=/bin/bash\n0 3 * * * reboot\n0 7 * * * supervisorctl restart bot' | crontab -
