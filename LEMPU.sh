echo 'Welcome to this quick LEMP installer'
echo ""
# LEMP setup and first user creation
echo "I need to ask you a few questions before starting the setup"
echo "You can leave the default options and just press enter if you are ok with them"
echo ""
# Install Nginx... First check if there is a installation
if [ -e $HOME/.config/nginx/nginx.conf ]; then
	echo "Where do you want me to install Nginx?"
	echo "Defualt: ~/.config/nginx)"
	read -p "Folder: " -e -i $HOME/.config/nginx/ NGDIRECTORY
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
	echo ""
	# Echo configuration to nginx conf file
	echo "# nginx.conf" $NGDIRECTORY/nginx.conf
	echo "error_log /home/victor/.config/nginx/error.log info;" >> $NGDIRECTORY/nginx.conf
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
	echo "        auth_basic "Personal file server";" >> $NGDIRECTORY/nginx.conf
	echo "        auth_basic_user_file $NGDIRECTORY/htpasswd.conf;" >> $NGDIRECTORY/nginx.conf #file with user:pass info
	echo "        root /home/$USER/files/;" >> $NGDIRECTORY/nginx.conf #path you want to share
	echo "    }" >> $NGDIRECTORY/nginx.conf
	echo "}" >> $NGDIRECTORY/nginx.conf
fi