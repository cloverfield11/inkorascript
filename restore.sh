#!/usr/bin/env bash
set -euo pipefail

echo "=== InkORA / PTP-SD автозаливка и восстановление ==="

### ==== 1. Параметры (без вопросов) ====

RCLONE_NAME="inkora"
RCLONE_PATH="InkORA-backups"
TARGET_DB="PTP_SD_test"

echo -n "Введите пароль для GPG (символы не отображаются): "
read -rs GPG_PASS
echo

### ==== 2. Установка пакетов ====
echo "=== Установка пакетов ==="
apt update
apt install -y apache2 php php-mysql php-cli php-zip php-curl php-xml php-mbstring php-gd \
               mysql-server gnupg tar gzip rsync unzip

### ==== 3. Проверка rclone remote ====
echo "=== Проверка rclone remote ==="

REMOTE="${RCLONE_NAME}:${RCLONE_PATH}"

rclone lsf "${REMOTE}" || { 
    echo "❌ rclone не видит remote ${REMOTE}. Проверь настройки rclone config!"
    exit 1
}

echo "✔ Remote доступен"

### ==== 4. Находим последний бэкап ====
LAST_BACKUP=$(rclone lsf "${REMOTE}" | sort | tail -n 1)
echo "Используем файл бэкапа: $LAST_BACKUP"

### ==== 5. Скачиваем бэкап ====
echo "=== Скачиваем бэкап ==="
rclone copy "${REMOTE}/${LAST_BACKUP}" /tmp/

### ==== 6. Расшифровка бэкапа ====
echo "=== Расшифровка ==="
echo "${GPG_PASS}" | gpg --batch --yes --passphrase-fd 0 \
  -o /tmp/backup.tar.gz -d "/tmp/${LAST_BACKUP}"

### ==== 7. Распаковка ====
echo "=== Распаковка ==="
mkdir -p /tmp/restore
tar -xzf /tmp/backup.tar.gz -C /tmp/restore

### ==== 8. Восстановление файлов ====
echo "=== Восстанавливаем /var/www ==="
rsync -avh /tmp/restore/var/www/ /var/www/

### ==== 9. Настройка Apache ====

echo "=== Включаем нужные модули Apache ==="
a2enmod rewrite
a2enmod ssl
a2enmod proxy
a2enmod proxy_http
a2enmod headers

### ==== 10. Создаём SSL + PROXY конфиг ====

echo "=== Создаём ptp-proxy.conf ==="

cat >/etc/apache2/sites-available/ptp-proxy.conf <<EOF
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    ServerName 10.0.0.111
    ServerAlias service.ptp-tmn.ru

    SSLEngine on

    ProxyPreserveHost On
    ProxyPass / http://10.0.0.111:3000/
    ProxyPassReverse / http://10.0.0.111:3000/

    <LocationMatch "^/(?!api|.well-known/acme-challenge|InkORA|pages/style/styles_mobile.css|uploads|robots.txt|download)">
        Order allow,deny
        Deny from all
    </LocationMatch>

    ErrorDocument 403 /errors/403.html

    Include /etc/letsencrypt/options-ssl-apache.conf
    SSLCertificateFile /etc/letsencrypt/live/service.ptp-tmn.ru/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/service.ptp-tmn.ru/privkey.pem
</VirtualHost>

<VirtualHost *:80>
    ServerName service.ptp-tmn.ru
    DocumentRoot /var/www/html

    RewriteEngine On
    RewriteCond %{HTTPS} !=on
    RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R=301,L]

    <Directory "/var/www/html/.well-known/acme-challenge">
        AllowOverride None
        Options None
        Require all granted
    </Directory>

    ProxyPreserveHost On
    ProxyPass / http://10.0.0.111:3000/
    ProxyPassReverse / http://10.0.0.111:3000/
</VirtualHost>

<Directory "/var/www/html/.well-known/acme-challenge">
    AllowOverride None
    Options None
    Require all granted
</Directory>
EOF

a2ensite ptp-proxy.conf
systemctl reload apache2

### ==== 11. Восстановление базы данных ====
SQL_DUMP=$(find /tmp/restore -name "*.sql.gz" | head -n 1 || true)

if [[ -z "$SQL_DUMP" ]]; then
  echo "SQL дамп НЕ найден!"
else
  echo "=== Восстанавливаем MySQL ==="
  mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${TARGET_DB};"
  gunzip < "${SQL_DUMP}" | mysql -u root "${TARGET_DB}"
fi

echo "=== ГОТОВО! Сайт восстановлен + SSL + проксирование ==="
