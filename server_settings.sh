apt-get update -y
apt-get upgrade -y
apt-get install -y sudo wget curl sqlite3 supervisor

sudo apt install -y wget software-properties-common build-essential libnss3-dev zlib1g-dev libgdbm-dev libncurses5-dev   libssl-dev libffi-dev libreadline-dev libsqlite3-dev libbz2-dev
wget https://www.python.org/ftp/python/3.11.4/Python-3.11.4.tgz
tar xvf Python-3.11.4.tgz
cd Python-3.11.4
./configure
make clean
make
make install
cd ..
rm -rf Python-3.11.4.tgz
rm -rf Python-3.11.4

wget https://raw.githubusercontent.com/CodenGames/VPCoden_bot/main/requirements.txt
pip3.11 install -r requirements.txt
pip3.11 install --upgrade pip

echo -e '[program:bot]\ncommand=python3.11 /root/bot.py > /dev/null 2>&1\nautostart=true\nautorestart=true\nuser=root' > /etc/supervisor/conf.d/bot.conf
supervisorctl reread
supervisorctl update
echo -e 'SHELL=/bin/bash\n0 3 * * * reboot\n0 7 * * * supervisorctl restart bot' | crontab -
