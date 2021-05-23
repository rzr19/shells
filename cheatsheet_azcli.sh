## 1. ACI https://hub.docker.com/_/microsoft-azuredocs-aci-helloworld 
az login -u $username -p $password
az group list
$resource_group=<copy/paste>
az container create -g $resource_group --name demoaci01 --image mcr.microsoft.com/azuredocs/aci-helloworld --dns-name-label ACI-demo --ports 80 
az container show -g $resource_group --name demoaci01 | grep fqdn 
az container attach -g $resource_group --name demoaci01 

## 2. App Services https://github.com/Azure-Samples/djangoapp
    ## Start by setting up the db
az postgres server create -g $resource_group --name demo123srv --admin-user demo123admin --admin-password demo123pass! --sku-name GP_Gen5_2 
az postgres server firewall-rule create -g $resource_group --server demo123srv --name AllowAll --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255 
az postgres server list 
az postgres db create -g $resource_group --server demo123srv --name pollsdb 

    ##Next setup the webapp
git clone https://github.com/Azure-Samples/djangoapp  
cd djangoapp
az webapp up -g $resource_group --plan demoplan01 --sku B1 --name demowebapp0101 
az webapp config appsettings set --settings DBHOST="demo123srv" DBNAME="pollsdb" DBUSER="demo123admin" DBPASS="demo123pass"
    ##Next execute from cloudshell inside of the webapp host
    cd $APP_PATH 
    source antenv/bin/activate 
    pip install -r requirements.txt 
    python manage.py migrate 
    python manage.py createsuperuser

## 3. Linux VMs + dockerd https://snipeitapp.com/
az vm image list --offer centos
az vm create -g $resource_group --location centralus --name demovm123 --image UbuntuLTS --admin-username demo123user --generate-ssh-keys
az vm open-port --port 8082 -g $resource_group --name demovm123
az vm list
az vm list-ip-addresses -g $resource_group -n demovm123
    ## Next setup docker and the 2 containers
    ssh demo123user@demovm123
    sudo yum -y install yum-utils
    sudo yum-config-manager –-add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum -y install docker-ce ## it installs also docker-ce-cli and containerd.io
    sudo systemctl start docker && sudo docker run hello-hello_world
    mkdir -p /snipeit/snipe-mysql && mkdir /snipeit/snipe-conf
    sudo docker run --name snipe-mysql -d -e MYSQL_ROOT_PASSWORD="3yyDOLC6VPFG&5gk#yNl" -e MYSQL_DATABASE=snipe \ 
    -e MYSQL_USER=snipe -e MYSQL_PASSWORD="29fMXli8ZRQCXnxnUEG" -e TZ=America/Chicago -p 127.0.0.1:3306:3306 \ 
    -v /snipeit/snipe-mysql:/var/lib/mysql mysql:5.6 --sql-mode=""
    sudo docker create --name=snipe-it --link snipe-mysql:db -e PUID=1000  -e PGID=1000 -e DB_CONNECTION=mysql \ 
    -e DB_HOST=snipe-mysql -e DB_DATABASE=snipe -e DB_USERNAME=snipe -e DB_PASSWORD="29fMXli8ZRQCXnxnUEG" \
    -e APP_KEY=base64:5U/KPKw1GN/Rz0fWYO/4FsSOqjmjvDAQzMCqwcAqstc= -p 8082:80 -v /snipeit/snipe-conf:/config \ 
    --restart unless-stopped snipe/snipe-it
    #Start the app
    sudo docker start snipe-it
