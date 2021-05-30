#!/bin/#!/usr/bin/env bash

## *** vim ***
b e w ## beginning, end, next word
:n ## move to n-th line
. ## repeat the last cmd
H M L ## BoF, 50% EoF, EoF
u :u :undo, Ctrl + R :redo ## undo and redo ## undo and redo
/string, n, N## find string, next and previous occurrence
?string n, N ## search backwards from cursor
:%s/word/replacement/g ## sed replace
yy & n p ## yank a line and paste it n times
dgg ## delete all above curr line
dG ## delete all below line
1G ## first line
20G ## 20th line
>> ## indent curr
<< ## outdent curr
:se ai / noai ## enable auto indent
:se wm=8 ## enable wrap margin
:se nu ## add line numbers

## *** top ***
-c or c # full paths
-u or u # user
K # kill

## openssl
for f in $(ls *.pem); do openssl x509 -in $f -noout -enddate >> expiration_dates.txt && echo $f >> expiration_dates.txt; done ## get dates from gazillion pem files
cat expiration_dates.txt | sed ':a;N;$!ba;s/GMT\n/GMT /g' ## sort and paginate them

## *** misc commands ***
Ctrl + U # clear line
Ctrl + K # clear line from cursor position
Ctrl + W ## delete last word
find /where -name backups -print # search for a file in a location
python -m SimpleHTTPServer # simple FTP copy tool through http://IP:8000
while true; do echo "<html><body><h1>WWW</h1></body></html>" | ncat -l -p 80; done ## Simple HTTP server
find / -date +5 exec rm -rf {};
pgrep <proc> ## top –p 1
Findmnt ## list all fs
cat /dev/disk/by-uuid ## get UUID
lines=`wc -l < /etc/passwd` ## backticks for vars that hold commands, always
echo "This is the ${n}th version of the file" ## double quotes always
vim /etc/fstab && :r!blkid /dev/sda1 >> insert UUID & type of fs
sed -i.bak '/^#/d;/^$/d' file ## creates bak file before replacing in-place
Sed -I "s#path/path#new/path#g" file ## modify paths containing slashes
Edit /etc/skel/.bash* files for permanents to new users
function cleanfile { sed /^\s*#/d;/^$/d' $1 }
sed '/^[[:blank:]]*#/d;s/#.*//' file
cp file file$(date +%Y%m%d%H%M%S) ## timestamped and rdy to go
echo -e " Enter text: \c" read answer echo " $answer " # how to read user input
source script ## useful for setting env vars on curr shell
bash -x ## prints each executed line in advance
Who -T && Mesg y && echo "1" > /dev/pts/n
mount –o remount,rw / ## useful in case of bootup crashes. Works with ro too
alias psc='ps xawf -eo pid,user,cgroup,args' && psc
/bin/su - root ## better than relying on $PATH
nc -z 10.115.8.134 1-65535 ## telnet through all the TCP ports at once
Tune2fs -e panic /dev/sda1 ## cause a kernel panic
find . -type f -exec grep -nRHI "rdbms" {} \; 1> std 2> /dev/null
hdparm –user-master u –security-set-pass pass /dev/sda && hdparm –user-master u –security-erase pass /dev/sda
Yes ## output y until killed
diff -y <(ssh host1 cat /some/file) <(ssh host2 cat /some/file)
gvfsd ## gnome virt fs automounter
mdadm -Cv /dev/md0 -l0 -n2 /dev/sd[ab]1 ## create RAID0 using sda1. Sdb1
command –v sbin ## substitute for which
Date –d "%d%m%Y"
Strace -p <PID> -ffffffffffffff
curl wttr.in/Cluj?format=3

## *** MAC, ACL, RBAC ***
Stdout of + in ls -Z means ACL is set
Grep ACL /boot/config-$(uname -r) ## y = yes, m = module
getfacl file
## Set default ACL for dir contents
setfacl -m (modifiy) d(default):o:--- dir/
setfacl -dm u:bob:rw dir/
## Remove ACLs
setfacl -x (remove) u:bob dir || setfacl -b (--remove-all) dir
# SELinux booleans(8) selinux(8) getsebool(8)
Every file, dir, port, process has an SE context. The context restricts the entity.
Types of contexts: type,
sestatus, setenforce 1|0, getenforce
ls –Z –-lcontext; ps auxZ # view the nitty gritty
grep -i selinux /boot/config-$(uname -r) ## check if it was compiled in kernel
ls -Z ## check SEcontext
chcon -t admin_home_t /etc/shadow
restorecon /etc/shadow ## restore default SEcontexts
semanage fcontext -a (add) -t (type) httpd_sys_content_type "/web(/.*)?" ## allow http traffic
setsebool -P samba_enable_home_dirs on
restorecon -R /home/share
sealert
# AppArmor
apparmor_status
## audit
Aureport -c -d -m

## *** docker ***
Docker -H <srv_ip>:2375 run hello_world
Docker diff <cont_id> #changed files list
Docker commit <cont_id> container_with_changes #create image
Docker build -t <name> . #build with dockerfile
Docker run -e HOST=az01 hello_world_python
Docker ps -a
docker run -d -t ubuntu:16.04 #run detached as service
docker run -d -p 8080:8080 tomcat #the gist of docker networks. Published ports host:container.
docker inspect <container_id> #get container info in json
docker inspect  --format '{{ .NetworkSettings.IPAddress }}' compassionate_aryabhata #parse the json
docker run -d -P tomcat # with P let docker do port assignment
docker port stevie_wonder # get assigned port
docker rm $(docker ps --no-trunc -aq) # delete all stopped containers
docker rmi $(docker images -f "dangling=true" -q)
docker volume ls -qf dangling=true | xargs -r docker volume rm
docker image ls
docker image pull alpine 
docker container run -it alpine sh
docker container run -d nginx 
docker container ls 
docker container ls -a
docker container exec -it <container_id/name> bash
docker container stop <container id/name> 
docker container rm  <container id/name>

## *** java ***
 /appl/tomcat/java/jdk1.8.0_121/bin/java -cp \ 
 /home/user/jisql/lib/jisql.jar:/home/user/jisql/lib/jopt-simple-3.2.jar:/home/user/ojdbc8-12.2.0.1.jar \
 com.xigole.util.sql.Jisql -driver oracle.jdbc.OracleDriver -cstring jdbc:oracle:thin:@/oracle.server.name:1521/oracle.service.name \
 -user oracle_user -p "p@$$w0rd" -c ";" -formatter default -query "select from user_users;" -trim
