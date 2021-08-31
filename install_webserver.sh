#!/bin/bash
#Ubuntu 18.04.5 LTS �°�װnginx��tomcat��redis��mysql�Զ��ű�

default_redis_version=6.2.5
default_nginx_version=1.20.1
default_tomcat_large_version=8
default_tomcat_version=8.5.70

redis_version=$default_redis_version
nginx_version=$default_nginx_version
tomcat_large_version=$default_tomcat_large_version
tomcat_version=$default_tomcat_version


#�Ƿ�װnginx,0 ����װ ��1 ��װ�����ȶ��棬 2 ��װָ���汾
install_nginx_state=0
#�Ƿ�װredis ,0 ����װ ��1 ��װ�����ȶ��棬 2 ��װָ���汾
install_redis_state=0
#�Ƿ�װtomcat��0 ����װ��1��װ
install_tomcat_state=0
#�Ƿ�װmysql 5.7 ��0 ����װ��1��װ
install_mysql_state=0 
#�Ƿ�װab���ߣ�0����װ
install_apache_ab_state=0
#�Ƿ�װiperf3������Թ��ߣ�0����װ
install_iperf3_state=0

#���˿ں��Ƿ�ռ����
check_port() {
    netstat -tlpn | grep "\b$1\b"
}
#��װ�����ȶ��汾nginx
function install_nginx_online(){
	#��ȡnginx�汾��
	#nginx -V 2>&1 | grep "version" | awk '{print $3}' | awk -F/ '{print $2}'
	#https://nginx.org/en/download.html
	sudo apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
	curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
	    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
	gpg --dry-run --quiet --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
	echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
	http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
	    | sudo tee /etc/apt/sources.list.d/nginx.list
	echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
	    | sudo tee /etc/apt/preferences.d/99nginx
	sudo apt update
	sudo apt install -y nginx
	#sudo systemctl daemon-reload
	#sudo systemctl enable nginx
	sudo systemctl start nginx

	echo "Install nginx done, installation directory is /usr/local/nginx"
}


#��������redis�汾��
function select_nginx_install_option(){	
    green "1. ����װnginx"
    green "2. ��װ�����ȶ��汾"
    green "3. ��װĬ��nginx $default_nginx_version"
	green "����ֵ��װָ���汾���������ʾ����汾"
    red "0. �˳���װ"
    echo
    read -p "��ѡ��nginx��װѡ��:" num
    case "$num" in
        1)
        install_nginx_state=0       
        ;;
        2)
        install_nginx_state=1        
        ;;
        3) 
        install_nginx_state=2
        nginx_version=$default_nginx_version       
        ;;
        0)
        exit 1    
        ;;
        *)
		read -p "������nginx�汾��:" nginx_version_in
		url=http://nginx.org/download/nginx-$nginx_version_in.tar.gz
		isExist=$(curl -s -m 5 -IL $url|grep 200)
		if (["$isExist" == ""]);then
			echo "����İ汾������"
			select_nginx_install_option
		fi
        install_nginx_state=2
		nginx_version=$nginx_version_in
        ;;
        esac	
}

#���밲װnginx 1.20.1
function install_nginx(){
	sudo apt-get update
	sudo apt-get install -y gcc
	sudo apt-get install -y zlib1g zlib1g-dev
	sudo apt-get install -y openssl libssl-dev
	sudo apt-get install -y libpcre3 libpcre3-dev
	sudo apt-get install -y make
	sudo wget https://nginx.org/download/nginx-$nginx_version.tar.gz
	sudo tar xzf nginx-$nginx_version.tar.gz
	cd nginx-$nginx_version/
	sudo ./configure --with-http_ssl_module
	#sudo ./configure --user=nginx --prefix=/usr/local/nginx --with-http_ssl_module --with-http_stub_status_module --with-pcre --with-stream
	sudo make -j
	sudo make install
	#����û�
	#useradd -s /sbin/nologin -M nginx
sudo tee /lib/systemd/system/nginx.service >/dev/null <<EOF
[Unit]
Description=nginx server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s stop
[Install]
WantedBy=multi-user.target
EOF
	sudo systemctl daemon-reload
	sudo systemctl enable nginx
	sudo systemctl start nginx

	echo "Install nginx $nginx_version done, installation directory is /usr/local/nginx"
}
#��װtomcat 8.5.70
function install_tomcat(){
	sudo apt-get update
	#û�а�װjavaʱ�Զ���װopen java 8 
	if ! [ -x "$(command -v java)" ];then
	    sudo apt-get install -y openjdk-8-jdk
	fi
	sudo wget https://mirrors.cnnic.cn/apache/tomcat/tomcat-$tomcat_large_version/v$tomcat_version/bin/apache-tomcat-$tomcat_version.tar.gz
	sudo tar xzf apache-tomcat-$tomcat_version.tar.gz
	sudo mv apache-tomcat-$tomcat_version /usr/local/tomcat
sudo tee /usr/local/tomcat/bin/setenv.sh >/dev/null <<EOF
CATALINA_PID="/usr/local/tomcat/tomcat.pid"
EOF
sudo tee /lib/systemd/system/tomcat.service >/dev/null <<EOF
[Unit]
Description=Apache Tomcat 8
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/usr/local/tomcat/tomcat.pid
ExecStart=/usr/local/tomcat/bin/startup.sh
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
#User=tomcat
#Group=tomcat

[Install]
WantedBy=multi-user.target
EOF
	sudo systemctl daemon-reload
	sudo systemctl enable tomcat
	sudo systemctl start tomcat

	echo "Install tomcat $tomcat_version done, installation directory is /usr/local/tomcat"
}

#��������tomcat�汾��
function select_tomcat_install_option(){
    green "1. ����װtomcat"
    green "2. ��װtomcat $default_tomcat_version"
	green "����ֵ��װָ���汾���������ʾ����汾"
    red "0. �˳���װ"
    echo
    read -p "��ѡ��tomcat��װѡ��:" num
    case "$num" in
        1)
        install_tomcat_state=0      
        ;;
        2)
        install_tomcat_state=1
        tomcat_large_version=$default_tomcat_large_version
        tomcat_version=$default_tomcat_version      
        ;;
        0)
        exit 1    
        ;;
        *)
		read -p "������tomcat��汾��(8,9,10):" tomcat_large_version_in	
		read -p "������tomcat�汾��:" tomcat_version_in
		url=https://mirrors.cnnic.cn/apache/tomcat/tomcat-$tomcat_large_version_in/v$tomcat_version_in/bin/apache-tomcat-$tomcat_version_in.tar.gz
		isExist=$(curl -s -m 5 -IL $url|grep 200)
		if (["$isExist" == ""]);then
			echo "����İ汾������"
			select_tomcat_install_option
		fi
        install_tomcat_state=1
		tomcat_version=$tomcat_version_in
		tomcat_large_version=$tomcat_large_version_in
        ;;
        esac	
}

#��װmysql ѡ��汾
function select_mysql_install_option(){
    green "1. ����װmysql"
    green "2. ��װmysql 5.7"
    red "0. �˳���װ"
    echo
    read -p "��ѡ��mysql��װѡ��:" num
    case "$num" in
        1)
        install_mysql_state=0      
        ;;
        2)
        install_mysql_state=1      
        ;;
        0)
        exit 1
        ;;
        *)
		echo "��ѡ����ȷ��ֵ"
		check_mysql_version
        ;;
        esac	
}
#��װmysql 5.7
function install_mysql(){
	#�鿴���ð汾
	#apt-cache search mysql | grep mysql-server
	# ��װ
	sudo apt-get -y install mysql-server-5.7
}
#ж��mysql
function remove_mysql(){
	sudo apt-get autoremove -y --purge mysql-server
	sudo apt-get autoremove -y --purge mysql-server-*
	sudo apt-get autoremove -y --purge mysql-client
	sudo apt-get autoremove -y --purge mysql-client-*
	sudo apt-get remove -y mysql-common
	dpkg -l |grep ^rc|awk '{print $2}' |sudo xargs dpkg -P
	sudo rm -rf /etc/mysql
	sudo rm -rf /var/lib/mysql
	sudo apt autoremove
	sudo apt autoclean
}

#��װ�����ȶ���redis
function install_redis_online(){
	echo -e "\n" | sudo add-apt-repository ppa:redislabs/redis
	sleep 1
	sudo apt-get update
	sudo apt-get install -y redis
	# Change "supervised no" so "supervised systemd"? Question is unclear
	# If "#bind 127.0.0.1 ::1", change to "bind 127.0.0.1 ::1"
	#sed -e 's/^supervised no/supervised systemd/' -e 's/^# requirepass foobared/requirepass rU9frVwMbLyG/' /etc/redis/redis.conf >/etc/redis/redis.conf.new
	#mv /etc/redis/redis.conf /etc/redis/redis.conf.$(date +%y%b%d-%H%M%S)
	#mv /etc/redis/redis.conf.new /etc/redis/redis.conf
	sudo systemctl restart redis-server
	# give redis-server a second to wake up
	sleep 1
	if [[ "$( echo 'ping' | /usr/bin/redis-cli )" == "PONG" ]] ; then
	    echo "ping worked"
	else
	    echo "ping FAILED"
	fi
	sudo systemctl status redis-server
	sudo systemctl enable redis

	echo "Install redis $redis_version done"
}
#��װredis ѡ��汾
function select_redis_install_option(){
    green "1. ����װredis"
    green "2. ��װ�����ȶ��汾"
    green "3. ��װredis $default_redis_version"
	green "����ֵ��װָ���汾���������ʾ����汾"
    red "0. �˳���װ"
    echo
    read -p "��ѡ��redis��װѡ��:" num
    case "$num" in
        1)
        install_redis_state=0      
        ;;
        2)
        install_redis_state=1      
        ;;
        3)
         install_redis_state=2
         redis_version=$default_redis_version
        ;;
        0)
        exit 1
        ;;
        *)
		read -p "������redis�汾��:" redis_version_in
		url=https://download.redis.io/releases/redis-$redis_version_in.tar.gz
		isExist=$(curl -s -m 5 -IL $url|grep 200)
		if (["$isExist" == ""]);then
			echo "����İ汾������"
			select_redis_install_option
		fi
        install_redis_state=2
		redis_version=$redis_version_in
        ;;
        esac	
}
#���밲װredis 6.2.5
function isntall_redis(){
	sudo apt-get update
	sudo apt-get install -y gcc
	#sudo apt-get install -y pkg-config
	sudo apt-get install -y make
	sudo wget https://download.redis.io/releases/redis-$redis_version.tar.gz
	sudo tar xzf redis-$redis_version.tar.gz
	cd redis-$redis_version/
	sudo make -j
	sudo make install PREFIX=/usr/local/redis
	sudo mv ../redis.conf /usr/local/redis/
	#sudo mv redis.conf /usr/local/redis/
	#�Զ�����־Ŀ¼���ȴ�����Ŀ¼����Ȼ������ʧ��
	sudo mkdir /usr/local/redis/log
	sudo tee /lib/systemd/system/redis.service >/dev/null <<EOF
[Unit]
Description=Advanced key-value store
After=network.target
Documentation=http://redis.io/documentation, man:redis-server(1)

[Service]
Type=forking
ExecStart=/usr/local/redis/bin/redis-server /usr/local/redis/redis.conf
ExecStop=/bin/kill -s TERM $MAINPID
PIDFile=/usr/local/redis/redis-server.pid
TimeoutStopSec=0
Restart=always
#User=redis
#Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=2755

UMask=007
PrivateTmp=yes
LimitNOFILE=65535
PrivateDevices=yes
ProtectHome=yes
ReadOnlyDirectories=/
ReadWriteDirectories=-/usr/local/redis

NoNewPrivileges=true
CapabilityBoundingSet=CAP_SETGID CAP_SETUID CAP_SYS_RESOURCE
MemoryDenyWriteExecute=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictNamespaces=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

# redis-server can write to its own config file when in cluster mode so we
# permit writing there by default. If you are not using this feature, it is
# recommended that you replace the following lines with "ProtectSystem=full".
ProtectSystem=true
ReadWriteDirectories=-/usr/local/redis

[Install]
WantedBy=multi-user.target
Alias=redis.service
EOF
	sudo systemctl daemon-reload
	sudo systemctl start redis
	sudo systemctl enable redis
}


function install_apache_ab(){
	sudo apt-get update
	apt-get install -y apache2-utils
}

function install_iperf3(){
	sudo apt-get update
	sudo apt install -y iperf3
}

function blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
function green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
function red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

function reload_start_menu(){
        sleep 1s
        start_menu
}

function start_menu(){
    clear
    green "==============================================="
    green " ����: һ����װnginx + tomcat + redis + mysql �ȹ��߽ű�"
    green " ϵͳ: Ubuntu18.04"
    green "==============================================="

    green "1. ��װnginx"
    green "2. ��װtomcat"
    green "3. ��װredis"
    green "4. ��װmysql"
    green "5. ��װapche abѹ�⹤��"
    green "6. ��װiperf3������Թ���"
	green "ָ����װ������ʱ���������ÿո����"
	red "0. �˳���װ"
    echo

	read -p "�������Ӧ�ı�ţ��������Կո����:" -a vars
	for var in ${vars[@]};do
	     if [ $var == 0 ];then
    		echo "��ֹ��װ" >&2
	     	exit 1
	     fi 
	done
	for var in ${vars[@]};do
	    case "$var" in
	        1)
			select_nginx_install_option
	        ;;
	        2)
			select_tomcat_install_option
	        ;;
	        3)
			select_redis_install_option
	        ;;
	        4)
			select_mysql_install_option
	        ;;
	        5)
			install_apache_ab_state=1
	        ;;
	        6)
			install_iperf3_state=1
	        ;;
	    esac 
	done
    case "$install_nginx_state" in
        1)
		install_nginx_online
        ;;
        2)
		install_nginx
        ;;
    esac
    case "$install_tomcat_state" in
        1)
		install_tomcat
        ;;
    esac
    case "$install_redis_state" in
        1)
		install_redis_online
        ;;
        2)
		install_redis
        ;;
    esac
    case "$install_mysql_state" in
        1)
		install_mysql
        ;;
    esac    
	if [ $install_apache_ab_state == 1 ];then
		install_apache_ab
	fi  
	if [ $install_iperf3_state == 1 ];then
		install_iperf3
	fi
    green "��װ���"
	if [ $install_nginx_state == 1 ] || [ $install_nginx_state == 2 ];then
		green "--------------nginx verion-------------"
    	nginx -v
	fi
	if [ $install_tomcat_state == 1 ];then
	    green "--------------java verion-------------"
	    java -version
	    green "--------------tomcat verion-------------"
	    echo "tomcat $tomcat_version"
	fi
    case "$install_redis_state" in
        [1-2])
	    green "--------------redis verion-------------"
	    redis-cli -v
        ;;
    esac
	if [ $install_mysql_state == 1 ];then
	    green "--------------mysql verion-------------"
	    mysql -V
	fi
	if [ $install_apache_ab_state == 1 ];then
	    green "--------------apache ab verion-------------"
	    ab -V
	fi  
	if [ $install_iperf3_state == 1 ];then
	    green "--------------iperf3 verion-------------"
	    iperf3 -v
	fi
        
}


if [[ $(id -u) != 0 ]] ; then
    red "Must be run as root,you can be run with:" >&2
    green "sudo $0" >&2
    exit 1
fi

start_menu