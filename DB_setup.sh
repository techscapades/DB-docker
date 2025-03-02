#!/bin/bash

set -e

echo "updating, upgrading and setting up environment"
echo -e "\n"
apt-get update && apt-get upgrade -y && apt autoremove -y
DEBIAN_FRONTEND=noninteractive apt install python3 python3-pip -y
apt install nano bash build-essential git curl net-tools openssh-server htop expect -y

echo "Setting up ssh service"
echo -e "\n"
mkdir -p /var/run/sshd
useradd -m -d /home/DB -s /bin/bash DB
echo "DB:1234567890" | chpasswd
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

echo "Installing apache2, php, mariadb-server and php-mysql"
echo -e "\n"
apt install apache2 php mariadb-server php-mysql -y

echo "Modifying apache2, mysqld, mariadb and php-mysql config"
echo -e "\n"
sed -i 's/^Listen 80$/Listen 17701/' /etc/apache2/ports.conf
sed -i 's|<VirtualHost \*:80>|<VirtualHost *:17701>|g' /etc/apache2/sites-available/000-default.conf
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
chmod 755 /run/mysqld
mkdir -p /var/tmp/mysql
chown mysql:mysql /var/tmp/mysql
sed -i 's|#tmpdir[[:space:]]*=.*|tmpdir = /var/tmp/mysql|' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i '/#innodb_buffer_pool_size = 8G/a innodb_use_native_aio=0' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 512M/' /etc/php/*/apache2/php.ini
sed -i 's/^post_max_size = .*/post_max_size = 512M/' /etc/php/*/apache2/php.ini
sed -i 's/^max_execution_time = .*/max_execution_time = 300/' /etc/php/*/apache2/php.ini
sed -i 's/^memory_limit = .*/memory_limit = 1024M/' /etc/php/*/apache2/php.ini

clear
echo -e "\n"
echo "press enter after the apache2 and mysql services start, after seeing this output: "
echo "Version: 'XX.XX.X-MariaDB-XXXXX'  socket: '/run/mysqld/mysqld.sock'  port: 3306  Ubuntu XX.XX"
sleep 1

echo "Starting apache2 and mysqld"
echo -e "\n"
apache2ctl -D FOREGROUND &
mysqld --user=root --console &

echo -e "\n"
echo "Installing mysql, user input required"
echo -e "\n"
mysql_secure_installation

echo -e "\n"
echo "Installing phpmyadmin, user input required"
echo -e "\n"
apt install phpmyadmin -y

echo "Modifying phpmyadmin config"
echo -e "\n"
sed -i "/\$cfg\['UploadDir'\] = '';/i \$cfg['ExecTimeLimit'] = 300;\n\$cfg['MaxAllowedPacket'] = '512M';" /etc/phpmyadmin/config.inc.php
phpenmod mysqli
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

echo "Creating admin user, enter the mysql root password to continue"
echo -e "\n"
echo "CREATE USER 'admin'@'localhost' IDENTIFIED BY '54941'; GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost'; FLUSH PRIVILEGES;" | mysql --user=root --password

echo -e "\n"
echo "Creating startup script..."
# Define the filename for the generated script
SCRIPT_PATH="start_services.sh"

# Create the script
cat <<EOF > "$SCRIPT_PATH"
#!/bin/bash

echo -e "\\n"
echo "Starting SSH, apache2 and mysqld!"
/usr/sbin/sshd &
echo -e "\\n"
hostname -I
echo "Navigate to \$(hostname -I | awk '{print \$1}'):17701/phpmyadmin on browser to access"
apache2ctl -D FOREGROUND &
mysqld --user=root --console &

sleep 2
exit 0
EOF

# Make the script executable
chmod +x "$SCRIPT_PATH"
echo "use: bash start_services.sh to start DB services"

echo -e "\\n"
echo "Setup complete, apache2, mysqld and SSH still active, exiting, please wait....!"
hostname -I
echo "Navigate to \$(hostname -I | awk '{print \$1}'):17701/phpmyadmin on browser to access"
#pkill apache2 &
#killall -9 mysqld &

exit 0
