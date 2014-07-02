#!/bin/bash

# Variables used in this script

# @param HOME = Defualt user home directory
# @param LAMPDIRECTORY = Install directory
# @param NGDIRECTORY = Configuration dir for nginx
# @param MYSQLDIRECTORY = Configuration dir for MySQL
# @param MYSQLROOTPASSWORD = MySQL root Password
# @param PHPFPMIRECTORY = Configuration dir for PHP-FPM

# Nginx version 1.7.2
# MySQL version 5.6.19
# PHP version 5.5.14


echo 'Welcome to this quick LEMP installer'
echo ""
echo "I need to ask you a few questions before starting the setup"
echo "You can leave the default options and just press enter if you are ok with them"
echo "Once intalled is recommended you dont delete this file as it contains your"
echo "instalation directories."
echo ""
# Know my name so I can change myself
SCRIPTNAME=`basename $0`

# Don't modify this lines as the script will change them
#replacethislineforlampdirectory
#replacethislineforngdirectory
#replacethislinefornginxport
#replacethislinefornginxrootdir
#replacethislineformysqldirectory
#replacethislineforphpfpmdirectory

# Setup Root Dir
function InstallPath {
	if [[ ! -v LAMPDIRECTORY ]]; then
		echo "Where do you want me to install?"
		read -p "Folder: " -e -i $HOME/LEMP LAMPDIRECTORY
		sed -i "s|#replacethislineforlampdirectory|LAMPDIRECTORY=$LAMPDIRECTORY|" $PWD/$SCRIPTNAME
	fi
	if [ ! -e $LAMPDIRECTORY ]; then
		mkdir -p $LAMPDIRECTORY
	fi
}
# Install and build in $LAMPDIRECTORY
function InstallNginx {
	echo "Installing Nginx"
	sleep 1
	wget -q http://nginx.org/download/nginx-1.7.2.tar.gz
	tar xzf nginx-1.7.2.tar.gz
	rm nginx-1.7.2.tar.gz
	cd nginx-1.7.2
	./configure --prefix=$LAMPDIRECTORY --with-ipv6 
	make
	make install
	cd ..
	rm -r nginx-1.7.2
}
# Configure Nginx in $NGDIRECTORY
# Port Number $PORT
function ConfigureNginx {
	if [[ ! -v NGDIRECTORY ]]; then
		echo "Where do you want me to configure Nginx?"
		read -p "Folder: " -e -i $HOME/.config/nginx NGDIRECTORY
		sed -i "s|#replacethislineforngdirectory|NGDIRECTORY=$NGDIRECTORY|" $PWD/$SCRIPTNAME
	fi
	# Create the home directory
	mkdir -p $NGDIRECTORY
	mkdir -p $NGDIRECTORY/tmp
	# Create files
	touch $NGDIRECTORY/nginx.conf
	touch $NGDIRECTORY/error.log
	touch $NGDIRECTORY/access.log
	echo "What port do you want for NGINX?"
	PORT=$(( $RANDOM % 30000 + 20000 ))
	read -p "Port: " -e -i $PORT USERPORT
	if [ $USERPORT != "" ]; then
		PORT=$USERPORT
		sed -i "s|#replacethislinefornginxport|PORT=$PORT|" $PWD/$SCRIPTNAME
	fi
	# Echo configuration to nginx conf file
	echo "# nginx.conf" >> $NGDIRECTORY/nginx.conf
	echo "error_log $NGDIRECTORY/error.log info;" >> $NGDIRECTORY/nginx.conf
 	echo "pid /dev/null;" >> $NGDIRECTORY/nginx.conf
 	echo "events { worker_connections 128; }" >> $NGDIRECTORY/nginx.conf
	echo ""  >> $NGDIRECTORY/nginx.conf
	echo "http {" >> $NGDIRECTORY/nginx.conf
	echo "    include mimes.conf; #for custom file types" >> $NGDIRECTORY/nginx.conf
	echo "    default_type application/octet-stream;" >> $NGDIRECTORY/nginx.conf
	echo "    access_log $NGDIRECTORY/access.log combined;" >> $NGDIRECTORY/nginx.conf
	echo "" >> $NGDIRECTORY/nginx.conf
	echo "    index    index.html index.htm index.php;" >> $NGDIRECTORY/nginx.conf
	echo "" >> $NGDIRECTORY/nginx.conf
	echo "    client_body_temp_path $NGDIRECTORY/tmp/client_body;" >> $NGDIRECTORY/nginx.conf
	echo "    proxy_temp_path $NGDIRECTORY/tmp/proxy;" >> $NGDIRECTORY/nginx.conf
	echo "    fastcgi_temp_path $NGDIRECTORY/tmp/fastcgi;" >> $NGDIRECTORY/nginx.conf
	echo "    uwsgi_temp_path $NGDIRECTORY/tmp/uwsgi;" >> $NGDIRECTORY/nginx.conf
	echo "    scgi_temp_path $NGDIRECTORY/tmp/scgi;" >> $NGDIRECTORY/nginx.conf
	echo "" >> $NGDIRECTORY/nginx.conf
	echo "    server_tokens off;" >> $NGDIRECTORY/nginx.conf
	echo "    sendfile on;" >> $NGDIRECTORY/nginx.conf
	echo "    tcp_nopush on;" >> $NGDIRECTORY/nginx.conf
	echo "    tcp_nodelay on;" >> $NGDIRECTORY/nginx.conf
	echo "    keepalive_timeout 4;" >> $NGDIRECTORY/nginx.conf
	echo "" >> $NGDIRECTORY/nginx.conf
	echo "    output_buffers   1 32k;" >> $NGDIRECTORY/nginx.conf
	echo "    postpone_output  1460;" >> $NGDIRECTORY/nginx.conf
	echo "" >> $NGDIRECTORY/nginx.conf
	echo "    server {" >> $NGDIRECTORY/nginx.conf
	echo "        listen ${PORT} default;" >> $NGDIRECTORY/nginx.conf #IPv4
	echo "        listen [::]:${PORT} default;" >> $NGDIRECTORY/nginx.conf #IPv6
	echo "        autoindex on;" >> $NGDIRECTORY/nginx.conf #this is the file list
	# Where will I put the root directory?
	if [[ ! -v NGROOTDIR ]]; then
		read -p "Where do you want your root directory?: " -e -i /home/$USER/files/ NGROOTDIR
		sed -i "s|#replacethislinefornginxrootdir|NGROOTDIR=$NGROOTDIR|" $PWD/$SCRIPTNAME
	fi
	if [ ! -e $NGROOTDIR ]; then
		mkdir -p $NGROOTDIR
	fi
	echo "        root $NGROOTDIR;" >> $NGDIRECTORY/nginx.conf #path you want to share
	# Check if user wants authentication services
	read -p "Do you want authentication services?[y/n]: " -e -i y AUTHSERVICES
	if [ $AUTHSERVICES = 'y' ]; then
		echo "        auth_basic \"Please enter your credentials\";" >> $NGDIRECTORY/nginx.conf
		echo "        auth_basic_user_file $NGDIRECTORY/htpasswd.conf;" >> $NGDIRECTORY/nginx.conf #file with user:pass info
		if [ ! -e $NGDIRECTORY/htpasswd.conf ]; then
			touch $NGDIRECTORY/htpasswd.conf
		fi
		read -p "What user do you want for authentication?: " -e -i $USER USERNGINX
		read -p "What password do you want for your user?: " -e -i pass PASSNGINX
		CRYPTNGINX = crypt $PASSNGINX
		# Echo user to htpasswd.conf
		echo "$USERNGINX:$CRYPTNGINX" >> $NGDIRECTORY/htpasswd.conf
	fi
	read -p "Do you want PHP & nginx?[y/n]: " -e -i y NGINXPHP
	if [ $NGINXPHP = 'y' ]; then
		if [[ ! -v PHPFPMIRECTORY ]]; then
			echo "What is the folder where PHP's socket is?"
			read -p "Folder: " -e -i $HOME/.config/php-fpm PHPFPMIRECTORY
		fi
		echo "		location ~ \\.php\$ {" >> $NGDIRECTORY/nginx.conf
    	echo "			include fastcgi_params;" >> $NGDIRECTORY/nginx.conf
    	echo "			fastcgi_pass unix:$PHPFPMIRECTORY/socket;" >> $NGDIRECTORY/nginx.conf
    	echo "		}" >> $NGDIRECTORY/nginx.conf
    	if [ ! -e $NGDIRECTORY/fastcgi_params  ]; then
			wget https://raw.githubusercontent.com/vpineda1996/LEMPU/master/nginx/fastcgi_params -q -O $NGDIRECTORY/fastcgi_params
		fi
    fi
	echo "    }" >> $NGDIRECTORY/nginx.conf
	echo "}" >> $NGDIRECTORY/nginx.conf
	# Create mime file if it doesn't exist
	if [ ! -e $NGDIRECTORY/mimes.conf  ]; then
		wget https://raw.githubusercontent.com/vpineda1996/LEMPU/master/nginx/mimes.conf -q -O $NGDIRECTORY/mimes.conf
	fi

}

#First check if there is a installation
function CheckConfigNginx {
	if [ ! -e $HOME/.config/nginx/ ]; then
		ConfigureNginx
	else
	read -p "You have a installation of nginx in $HOME/.config/nginx/, do you want me to erase it? [y/n]" -e -i n ERASENGINX
	if [ $ERASENGINX = 'y' ]; then
		rm -r $HOME/.config/nginx
	fi
	ConfigureNginx
	fi
}

# Install MySQL in $LAMPDIRECTORY
function InstallMySQL { 
	echo "Installing MySQL"
	sleep 1
	wget "http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.19.tar.gz" -q -O mysql-5.6.19.tar.gz
	tar xzf mysql-5.6.19.tar.gz		
	rm mysql-5.6.19.tar.gz
	cd mysql-5.6.19
	BUILD/autorun.sh
	./configure --prefix=$LAMPDIRECTORY/mysql
	make
	make install
	cd ..
	rm -r mysql-5.6.19
	if [ ! -e $LAMPDIRECTORY/init.d ]; then
		mkdir -p $LAMPDIRECTORY/init.d
	fi
	mv $LAMPDIRECTORY/mysql/support-files/mysql.server $LAMPDIRECTORY/init.d/mysql.server	
}

# Configure MariaDB in $MYSQLDIRECTORY
# socket @ $MYSQLDIRECTORY/socket.sock
# checar como inicializar MySQL
function ConfigureMySQL {
	if [[ ! -v LAMPDIRECTORY ]]; then
		echo "Where is MySQL installed?"
		read -p "Folder: " -e -i $HOME/LEMP LAMPDIRECTORY
	fi
	if [[ ! -v MYSQLDIRECTORY ]]; then
		echo "Where do you want me to configure MySQL?"
		read -p "Folder: " -e -i $HOME/.config/mysql MYSQLDIRECTORY
		sed -i "s|#replacethislineformysqldirectory|MYSQLDIRECTORY=$MYSQLDIRECTORY|" $PWD/$SCRIPTNAME
	fi
	# Create the MySQL directory
	if [ ! -e $MYSQLDIRECTORY ]; then
		mkdir -p $MYSQLDIRECTORY
	fi
	# Setup Test tables
	$LAMPDIRECTORY/mysql/scripts/mysql_install_db --basedir=$LAMPDIRECTORY/mysql --datadir=$MYSQLDIRECTORY --user=$USER
	sed -i "s|\# innodb_buffer_pool_size = 128M|innodb_buffer_pool_size = 128M|" $LAMPDIRECTORY/mysql/my.cnf
 	sed -i "s|\# basedir = .....|basedir = $LAMPDIRECTORY/mysql|" $LAMPDIRECTORY/mysql/my.cnf
 	sed -i "s|\# datadir = .....|datadir = $MYSQLDIRECTORY|" $LAMPDIRECTORY/mysql/my.cnf
 	sed -i "s|\# socket = .....|socket = $MYSQLDIRECTORY/socket.sock|" $LAMPDIRECTORY/mysql/my.cnf
 	# Symbolic link to $MYSQLDIRECTORY
 	ln -s $LAMPDIRECTORY/mysql/my.cnf $MYSQLDIRECTORY/my.cnf
 	$LAMPDIRECTORY/init.d/mysql.server start
 	echo "What passowrd do you want for MySQL root user?"
 	read -p "Password: " -e -i pass MYSQLROOTPASSWORD
 	$LAMPDIRECTORY/mysql/bin/mysqladmin -u root password $MYSQLROOTPASSWORD --socket=$MYSQLDIRECTORY/socket.sock
}

# Install php-fpm in $LAMPDIRECTORY  --- incomplete
function InstallFPM {
	echo "Installing PHP-FPM"
	sleep 1
	if [[ ! -v PHPFPMIRECTORY ]]; then
		echo "Where do you want me to configure PHP-FPM?"
		read -p "Folder: " -e -i $HOME/.config/php-fpm PHPFPMIRECTORY
		sed -i "s|#replacethislineforphpfpmdirectory|PHPFPMIRECTORY=$PHPFPMIRECTORY|" $PWD/$SCRIPTNAME
	fi
	if [[ ! -v MYSQLDIRECTORY ]]; then
		echo "Where are MySQL config files located?"
		read -p "Folder: " -e -i $HOME/.config/mysql MYSQLDIRECTORY
	fi
	# Create the PHP-FPM directory
	if [ ! -e $PHPFPMIRECTORY ]; then
		mkdir -p $PHPFPMIRECTORY
	fi
	wget http://us1.php.net/get/php-5.5.14.tar.gz/from/this/mirror -q -O php-5.5.14.tar.gz
	tar xzf php-5.5.14.tar.gz
	rm php-5.5.14.tar.gz
	cd php-5.5.14
	./configure --prefix=$LAMPDIRECTORY --disable-cgi --enable-fpm --with-pic --with-xmlrpc --enable-sockets --enable-ipv6 --enable-json --with-config-file-path=$PHPFPMIRECTORY --with-config-file-scan-dir=$PHPFPMIRECTORY  --with-mysql=$LAMPDIRECTORY/mysql --with-mysqli=$LAMPDIRECTORY/mysql/bin/mysql_config --with-gd --with-bz2 --with-zlib --enable-mbstring --enable-calendar --enable-bcmath --enable-ftp --enable-exif --enable-zip --enable-gd-native-ttf --with-mysql-sock=$MYSQLDIRECTORY/socket.sock	
	make
	make install
	# Fix prefix in init.d file to start php-fpm
	sed -i "s|php_fpm_CONF=\${prefix}/etc/php-fpm.conf|php_fpm_CONF=$PHPFPMIRECTORY/conf|" sapi/fpm/init.d.php-fpm
 	sed -i "s|php_fpm_PID=\${prefix}/var/run/php-fpm.pid|php_fpm_PID=$PHPFPMIRECTORY/php-fpm.pid|" sapi/fpm/init.d.php-fpm
 	if [ ! -e $LAMPDIRECTORY/init.d ]; then
		mkdir -p $LAMPDIRECTORY/init.d
	fi
 	mv sapi/fpm/init.d.php-fpm $LAMPDIRECTORY/init.d/php-fpm
 	chmod a+x $LAMPDIRECTORY/init.d/php-fpm
 	cd ..
 	mv php-5.5.14 php_keep
}

function ConfigureFPM {
	if [[ ! -v PHPFPMIRECTORY ]]; then
		echo "Where do you want me to configure PHP-FPM?"
		read -p "Folder: " -e -i $HOME/.config/php-fpm PHPFPMIRECTORY
	fi
	# Create the PHP-FPM directory
	if [ ! -e $PHPFPMIRECTORY ]; then
		mkdir -p $PHPFPMIRECTORY
	fi
	touch $PHPFPMIRECTORY/conf
	echo "[global]" >> $PHPFPMIRECTORY/conf
	echo "daemonize = yes" >> $PHPFPMIRECTORY/conf
	echo "error_log = $PHPFPMIRECTORY/error.log" >> $PHPFPMIRECTORY/conf
	echo "" >> $PHPFPMIRECTORY/conf
	echo "[www]" >> $PHPFPMIRECTORY/conf
	echo "listen = $PHPFPMIRECTORY/socket" >> $PHPFPMIRECTORY/conf
	echo "" >> $PHPFPMIRECTORY/conf
	echo "listen.group = $USER" >> $PHPFPMIRECTORY/conf
	echo "listen.mode = 0600" >> $PHPFPMIRECTORY/conf
	echo "" >> $PHPFPMIRECTORY/conf
	echo "pm = dynamic" >> $PHPFPMIRECTORY/conf
	echo "pm.max_children = 20" >> $PHPFPMIRECTORY/conf
	echo "pm.start_servers = 1" >> $PHPFPMIRECTORY/conf
	echo "pm.min_spare_servers = 1" >> $PHPFPMIRECTORY/conf
	echo "pm.max_spare_servers = 5" >> $PHPFPMIRECTORY/conf
}

function StartMySQL {
	$LAMPDIRECTORY/init.d/mysql.server start
}

function StartPHPFPM {
	$LAMPDIRECTORY/init.d/php-fpm start
}

function StartNGINX {
	$LAMPDIRECTORY/sbin/nginx -c $NGDIRECTORY/nginx.conf
}
function StopMySQL {
	$LAMPDIRECTORY/init.d/mysql.server stop
}

function StopPHPFPM {
	$LAMPDIRECTORY/init.d/php-fpm stop
}

function StopNGINX {
	pkill nginx
}

while :
do
	clear
	echo "What do you want to do?"
	echo ""
	echo "1) Setup..."
	echo "2) Configure..."
	echo "3) Run..."
	echo "4) Stop..."
	echo "5) Install websites"
	echo "5) Exit"
	echo ""
	read -p "Select an option [1-5]: " option
	case $option in
		1) # Setup Menu
				clear
				echo ""
				echo "1) Install and configure all"
				echo "2) Install and Configure Nginx"
				echo "3) Install and Configure MySQL"
				echo "4) Install and Configure PHP-FPM"				
				echo "5) Exit"
				echo ""
				read -p "Select an option [1-5]: " setupOption
				case $setupOption in
					1) # Install and configure all
						InstallPath
						# Install MySQL...
						InstallMySQL
						echo "Confgiuring MySQL"
						ConfigureMySQL
						# Install FPM...
						InstallFPM
						echo "Confgiuring MySQL"
						ConfigureFPM
						# Install Nginx...
						InstallNginx
						echo "Confgiuring NGINX"
						CheckConfigNginx
						;;
					2) # Install and Configure Nginx
						InstallPath
						# Install Nginx...
						InstallNginx
						echo "Confgiuring Nginx"
						CheckConfigNginx
						;;
					3) # Install and Configure MySQL
						InstallPath
						# Install MySQL...
						InstallMySQL
						echo "Confgiuring MySQL"
						ConfigureMySQL
						;;
					4) # Install and Configure PHP-FPM
						InstallPath
						# Install FPM...
						InstallFPM
						echo "Confgiuring MySQL"
						ConfigureFPM
						;;
					5) 
						;;
				esac
			;;
		2) # Configure menu
				clear
				echo ""
				echo "1) Configure Nginx"
				echo "2) Configure MySQL"
				echo "3) Configure PHP-FPM"
				echo "4) Exit"
				echo ""
				read -p "Select an option [1-4]: " setupOption1
				case $setupOption1 in
					1) # Configure Nginx
						echo "Confgiuring Nginx"
						CheckConfigNginx
						;;
					2) # Configure MySQL
						if [[ ! -v LAMPDIRECTORY ]]; then
							echo "Where is MySQL installed?"
							read -p "Folder: " -e -i $HOME/LEMP LAMPDIRECTORY
						fi
						ConfigureMySQL
						;;
					3) # Configure PHP --missing
						ConfigureFPM
						;;
					4) 
						;;
				esac
			;;
		3) # Run Menu
			if [[ ! -v LAMPDIRECTORY ]]; then
				echo "Where is everything installed?"
				read -p "Folder: " -e -i $HOME/LEMP LAMPDIRECTORY
				sed -i "s|#replacethislineforlampdirectory|LAMPDIRECTORY=$LAMPDIRECTORY|" $PWD/$SCRIPTNAME
			fi
			if [[ ! -v NGDIRECTORY ]]; then
				echo "Where is Nginx configuration located?"
				read -p "Folder: " -e -i $HOME/.config/nginx NGDIRECTORY
				sed -i "s|#replacethislineforngdirectory|NGDIRECTORY=$NGDIRECTORY|" $PWD/$SCRIPTNAME
			fi
			StartMySQL
			StartPHPFPM
			StartNGINX
			;;
		4) # Stop Menu
			if [[ ! -v LAMPDIRECTORY ]]; then
				echo "What is the root installation directory of LAMP?"
				read -p "Folder: " -e -i $HOME/LEMP LAMPDIRECTORY
				sed -i "s|#replacethislineforlampdirectory|LAMPDIRECTORY=$LAMPDIRECTORY|" $PWD/$SCRIPTNAME
			fi
			if [[ ! -v NGDIRECTORY ]]; then
				echo "Where is Nginx configuration located?"
				read -p "Folder: " -e -i $HOME/.config/nginx NGDIRECTORY
				sed -i "s|#replacethislineforngdirectory|NGDIRECTORY=$NGDIRECTORY|" $PWD/$SCRIPTNAME
			fi
			StopMySQL
			StopPHPFPM
			StopNGINX
			;;
		5) 
			
			;;
		6) exit;;
	esac
done