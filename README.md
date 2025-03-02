Info:
1. A script to set up a docker container to run a database with these packages: ssh, apache2, mysqld, mariadb and php-mysql
2. The apache2, mysqld, mariadb and php-mysql configs are modified to allow DBs to be migrated
3. Please modify the setup script before deployment to change default ssh password and DB max filesize


On Linux host:
1. get docker
2. wget -O /home/$USER/DB_setup.sh https://raw.githubusercontent.com/techscapades/DB-docker/main/DB_setup.sh
3. docker run -t -d --name DB --network host -v /home/$USER/DB_setup.sh:/DB_setup.sh ubuntu
4. docker exec -it DB bash -c "chmod +x /DB_setup.sh && /DB_setup.sh"

Steps 4 is interactive, please setup the DB passwords by yourself, make sure to set up the phpmyadmin webserver for apache2.

To start the DB container and run services:
1. docker start DB && docker exec -it DB bash -c "chmod +x /start_services.sh && /start_services.sh"


It is highly encouraged to go through the setup script to understand whats going on!!!!
