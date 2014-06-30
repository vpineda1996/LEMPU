echo 'Welcome to this quick LEMP installer'
echo ""
# LEMP setup and first user creation
echo "I need to ask you a few questions before starting the setup"
echo "You can leave the default options and just press enter if you are ok with them"
echo ""

# Root Dir
function InstallPath {
	echo "Where do you want me to install?"
	read -p "Folder: " -e -i $HOME/LEMP $LAMPDIRECTORY
	if [ ! -e $LAMPDIRECTORY ]; then
		mkdir -p $LAMPDIRECTORY
	fi
}
# Install and build in $LEMP
function InstallNginx {
	echo "Installing Nginx"
	sleep 1
	wget -q http://nginx.org/download/nginx-1.7.2.tar.gz
	tar xzvf nginx-1.7.2.tar.gz
	rm nginx-1.7.2.tar.gz
	cd nginx-1.7.2
	./configure --prefix=$LEMP
	make
	make install
	cd ..
	rm -r nginx-1.7.2
}
# Configure Nginx in $LEMP
function ConfigureNginx {
	echo "Where do you want me to configure Nginx?"
	read -p "Folder: " -e -i $HOME/.config/nginx NGDIRECTORY
	# Create the home directory
	mkdir -p $NGDIRECTORY
	# Create files
	touch $NGDIRECTORY/nginx.conf
	touch $NGDIRECTORY/error.log
	touch $NGDIRECTORY/access.log
	echo "What port do you want for NGINX?"
	PORT=$(( $RANDOM % 30000 + 20000 ))
	read -p "Port: " -e -i $PORT USERPORT
	if [ $USERPORT != "" ]; then
		PORT=$USERPORT
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
	echo "    lient_body_temp_path $NGDIRECTORY/tmp/client_body;" >> $NGDIRECTORY/nginx.conf
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
	# Check if user wants authentication services
	read -p "Where do you want your root directory?: " -e -i /home/$USER/files/ NGROOTDIR
	echo "        root $NGROOTDIR;" >> $NGDIRECTORY/nginx.conf #path you want to share
	read -p "Do you want authentication services?[y/n]: " -e -i y AUTHSERVICES
	if [ $AUTHSERVICES = 'y' ]; then
		echo "        auth_basic \"Please enter your credentials\";" >> $NGDIRECTORY/nginx.conf
		echo "        auth_basic_user_file $NGDIRECTORY/htpasswd.conf;" >> $NGDIRECTORY/nginx.conf #file with user:pass info
		if [ ! -e $NGDIRECTORY/htpasswd.conf ]; then
			touch $NGDIRECTORY/htpasswd.conf
		fi
		read -p "What user do you want for authentication?: " -e -i $USER $USERNGINX
		read -p "What password do you want for your user?: " -e -i pass $PASSNGINX
		CRYPTNGINX = crypt $PASSNGINX
		# Echo user to htpasswd.conf
		echo "$USERNGINX:$CRYPTNGINX" >> $NGDIRECTORY/htpasswd.conf
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
	read -p "You have a installation of nginx in $HOME/.config/nginx/, do you want me to erase it? [y/n]" -e -i n $ERASENGINX
	if [ $ERASENGINX = 'y' ]; then
		rm -r $HOME/.config/nginx
	fi
	ConfigureNginx
	fi
}

# Install MariaDB in $LEMP
function InstallMariaDB { 
	echo "Installing MariaDB"
	sleep 1
	wget "https://downloads.mariadb.org/f/mariadb-10.0.12/source/mariadb-10.0.12.tar.gz/from/http:/ftp.utexas.edu/mariadb?serve" -q -O mariadb-10.0.12.tar.gz
	tar xzvf mariadb-10.0.12.tar.gz
	rm mariadb-10.0.12.tar.gz
	cd mariadb-10.0.12
	cmake -DCMAKE_INSTALL_PREFIX:PATH=$LEMP . && make all install
	cd ..
	rm -r mariadb-10.0.12
}

# Install php-fpm in $LEMP  --- incomplete
function InstallFPM {
	echo "Installing PHP-FPM"
	sleep 1
	wget http://us1.php.net/get/php-5.5.14.tar.gz/from/this/mirror -q -O php-5.5.14.tar.gz
	tar xzvf php-5.5.14.tar.gz
	rm php-5.5.14.tar.gz
	cd php-5.5.14

}



while :
do
	echo "What do you want to do?"
	echo ""
	echo "1) Setup LEMP"
	echo "2) Install and Configure Nginx"
	echo "3) Install and Configure MariaDB"
	echo "4) Exit"
	echo ""
	read -p "Select an option [1-4]: " option
	case $option in
		1) # Setup LEMP
			InstallPath
			# Install Nginx...
			InstallNginx
			CheckConfigNginx
			exit
			;;
		2) # Install and Configure Nginx
			InstallPath
			# Install Nginx...
			InstallNginx
			CheckConfigNginx
			exit
			;;
		3)
			InstallMariaDB
			exit
			;;
		10) exit;;
	esac
done


