#!/usr/bin/env bash
set -euo pipefail

# Stažení balíčku pro instalaci zabbix repo
sudo wget https://repo.zabbix.com/zabbix/8.0/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_8.0+debian13_all.deb

# Instalace meta balíčku
sudo dpkg -i zabbix-release_latest_8.0+debian13_all.deb

# Aktualizace repository
sudo apt update

# Instalace meta balíčku
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent2
sudo apt install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql

# Instalace databaze
sudo apt install -y mariadb-server

# Konfigurace databáze pro Zabbix
sudo mysql -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;"
sudo mysql -e "create user zabbix@localhost identified by 'Zabbix123';"
sudo mysql -e "grant all privileges on zabbix.* to zabbix@localhost;"
sudo mysql -e "set global log_bin_trust_function_creators = 1;"
# sudo mysql -e "quit;"

# Restart MariaDB
sudo systemctl enable mariadb.service
sudo systemctl restart mariadb.service

# Install zabbix balicku
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent2

# Import Zabbix DB schema
sudo zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -pZabbix123 zabbix

# Nastaveni trust_function_creators On
sudo mysql -e "set global log_bin_trust_function_creators = 1;"

# Konfigurace 
sudo cp -v /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf-orig
sudo sed -i "s/# DBPassword=/DBPassword=Zabbix123/g" /etc/zabbix/zabbix_server.conf

# Restart Zabbix komponent
sudo systemctl restart zabbix-server zabbix-agent2 apache2
sudo systemctl enable zabbix-server zabbix-agent2 apache2

# Konfigure Zabbix frontend
sudo cp -v /vagrant/zabbix.conf.php /etc/zabbix/web/
sudo chmod 400 /etc/zabbix/web/zabbix.conf.php
sudo chown www-data:www-data /etc/zabbix/web/zabbix.conf.php
# EOF