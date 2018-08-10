#!/bin/bash
##################################################################################################################################
#                                                                                                                                #
#                                           This script is written by Pierre Gode                                                #
#      This program is open source; you can redistribute it and/or modify it under the terms of the GNU General Public           #
#                     This is an normal bash script and can be executed with sh EX: ( sudo sh ADconnection.sh )                  #
# Generic user setup is: administrator, domain admins, groupnamesudores= groupname=hostname + sudoers on groupname in AD groups  #
#                                                                                                                                #
##################################################################################################################################
#known bugs: Sometimes the script bugs after AD administrator tries to authenticate, temporary solution is running the script again
# a couple of times. if it still is not working see line 24-25
#known bugs: see line 24-25
#
# ~~~~~~~~~~  Environment Setup ~~~~~~~~~~ #
    NORMAL=$(echo "\033[m")
    MENU=$(echo "\033[36m") #Blue
    NUMBER=$(echo "\033[33m") #yellow
    RED_TEXT=$(echo "\033[31m") #Red
    INTRO_TEXT=$(echo "\033[32m") #green and white text
    END=$(echo "\033[0m")
# ~~~~~~~~~~  Environment Setup ~~~~~~~~~~ #
################################ fix errors # funktion not called ################
fixerrors(){
#this funktion is not called in the script : to activate, uncomment line line 31 #fixerrors
#This funktion installs additional pakages due to known issues with Joining and the join hangs after the admin auth
sudo add-apt-repository ppa:xtrusia/packagekit-fix
sudo apt-get update
sudo apt-get install packagekit
MENU_FN
}
#fixerrors
#Realmdupdate11
####################### final auth ##################################################################

fi_auth(){
sudo echo "############################"
sudo echo "Configuratig files.."
sudo echo "Verifying the setup"
sudo systemctl enable sssd
sudo systemctl start sssd
states=$( echo null )
states1=$( echo null )
grouPs=$( echo null )
therealm=$( echo null )
cauth=$( echo null )
clear
read -p "${RED_TEXT}"'Do you wish to enable SSH login.group.allowed'"${END}""${NUMBER}"'(y/n)?'"${END}" yn
   case $yn in
    [Yy]* ) sudo echo "Cheking if there is any previous configuration"
	if [ -f /etc/ssh/login.group.allowed ] < /dev/null > /dev/null 2>&1
then
echo "Files seems already to be modified, skipping..."
else
echo "NOTICE! /etc/ssh/login.group.allowed will be created. make sure yor local user is in it you you could be banned from login"
echo "auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/ssh/login.group.allowed" | sudo tee -a /etc/pam.d/common-auth
sudo touch /etc/ssh/login.group.allowed
admins=$( cat /etc/passwd | grep home | grep bash | cut -d ':' -f1 )
echo ""
echo ""
read -p "Is your current administrator = "$admins" ? (y/n)?" yn
   case $yn in
    [Yy]* ) sudo echo "$admins"  | sudo tee -a /etc/ssh/login.group.allowed;;
    [Nn]* ) echo "please type name of current administrator"
read -p MYADMIN
sudo echo $MYADMIN | sudo tee -a /etc/ssh/login.group.allowed;;
    * ) echo "Please answer yes or no.";;
   esac
sudo echo "$NetBios"'\'"$myhost""sudoers" | sudo tee -a /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"domain^admins" | sudo tee -a /etc/ssh/login.group.allowed
sudo echo "root" | sudo tee -a /etc/ssh/login.group.allowed
echo "enabled SSH-allow"
fi;;
    [Nn]* ) echo "Disabled SSH login.group.allowed"
    states1=$( echo 12 );;
    * ) echo "Please answer yes or no.";;
   esac
echo ""
echo "-------------------------------------------------------------------------------------------"
echo ""
read -p "${RED_TEXT}"'Do you wish to give users on this machine sudo rights?'"${END}""${NUMBER}"'(y/n)?'"${END}" yn
   case $yn in
    [Yy]* ) sudo echo "Cheking if there is any previous configuration"
	if [ -f /etc/sudoers.d/sudoers ] < /dev/null > /dev/null 2>&1
then
echo ""
echo "The Sudoers file seems already to be modified, skipping..."
echo ""
else
read -p "${RED_TEXT}"'Do you wish to DISABLE password promt for users in terminal?'"${END}""${NUMBER}"'(y/n)?'"${END}" yn
   case $yn in
    [Yy]* )
sudo echo "administrator ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%$myhost""sudoers ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%DOMAIN\ admins ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/domain_admins
#sudo realm permit --groups "$myhost""sudoers"
;;

 [Nn]* ) sudo echo "administrator ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%$myhost""sudoers ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%DOMAIN\ admins ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/domain_admins
#sudo realm permit --groups "$myhost""sudoers"
;;
    * ) echo "Please answer yes or no.";;
   esac
fi;;
    [Nn]* ) echo "Disabled sudo rights for users on this machine"
    	    echo ""
	    echo ""
	    states=$( echo 12 );;
    * ) echo 'Please answer yes or no.';;
   esac
homedir=$( cat /etc/pam.d/common-session | grep homedir | grep 0022 | cut -d '=' -f3 )
if [ $homedir = 0022 ]
then
echo "pam_mkhomedir.so configured"
sleep 1
else
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" | sudo tee -a /etc/pam.d/common-session
fi
logintrue=$( cat /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf | grep -i -m1 login )
if [ -f /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf ]
then
if [ "$logintrue" =  "greeter-show-manual-login=true" ]
then
echo "50-ubuntu.conf is already configured.. skipping"
else
sudo sh -c "echo 'greeter-show-manual-login=true' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
sudo sh -c "echo 'allow-guest=false' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
fi
else
echo "No lightdm to configure"
fi
clear
sed -i -e 's/fallback_homedir = \/home\/%u@%d/#fallback_homedir = \/home\/%u@%d/g' /etc/sssd/sssd.conf
sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
sed -i -e 's/access_provider = ad/access_provider = simple/g' /etc/sssd/sssd.conf
sed -i -e 's/sudoers:        files sss/sudoers:        files/g' /etc/nsswitch.conf
echo "override_homedir = /home/%d/%u" | sudo tee -a /etc/sssd/sssd.conf
cat /etc/sssd/sssd.conf | grep -i override
sudo echo "[nss]
filter_groups = root
filter_users = root
reconnection_retries = 3
entry_cache_timeout = 600
#entry_cache_user_timeout = 5400
#entry_cache_group_timeout = 5400
#cache_credentials = TRUE
entry_cache_nowait_percentage = 75" | sudo tee -a /etc/sssd/sssd.conf
sudo service sssd restart
if [ $? = 0 ]
then
echo  "Checking sssd config.. OK"
else
echo "Checking sssd config.. FAIL"
fi
therealm=$(realm discover $DOMAIN | grep -i configured: | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//')
if [ "$therealm" = no ]
then
echo Realm configured?.. "${RED_TEXT}"FAIL"${END}"
else
echo Realm configured?.. "${INTRO_TEXT}"OK"${END}"
fi
if [ $states = 12 ]
then
echo "Sudoers not configured... skipping"
else
if [ -f /etc/sudoers.d/sudoers ] < /dev/null > /dev/null 2>&1
then
echo Checking sudoers file..  "${INTRO_TEXT}"OK"${END}"
else
echo checking sudoers file..  "${RED_TEXT}"FAIL"${END}"
fi
grouPs=$(cat /etc/sudoers.d/sudoers | grep -i "$myhost" | cut -d '%' -f2 | awk '{print $1}')
if [ "$grouPs" = "$myhost""sudoers" ]
then
echo Checking sudoers users.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking sudoers users.. "${RED_TEXT}"FAIL"${END}"
fi
homedir=$(cat /etc/pam.d/common-session | grep homedir | grep 0022 | cut -d '=' -f3)
if [ $homedir = 0022 ] < /dev/null > /dev/null 2>&1
then
echo Checking PAM configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM configuration.. "${RED_TEXT}"FAIL"${END}"
fi
if [ $states1 = 12 ]
then 
echo "Disabled SSH login.group.allowed"
else
cauth=$(cat /etc/pam.d/common-auth | grep required | grep onerr | grep allow | cut -d '=' -f4 | awk '{print $1}')
if [ $cauth = allow ] < /dev/null > /dev/null 2>&1
then
echo Checking PAM auth configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM auth configuration.. "${RED_TEXT}"FAIL"${END}"
fi
fi
#realm discover $DOMAIN
if [ "$therealm" = no ]
then
echo "${RED_TEXT}"Join has Failed"${END}"
else
lastverify=$( realm discover $DOMAIN | grep -m 1 $DOMAIN )
echo ""
echo "${INTRO_TEXT}"joined to $lastverify"${END}"
echo ""
fi
echo "${INTRO_TEXT}Please reboot your machine and wait 3 min for Active Directory to sync before login${INTRO_TEXT}"
exit
fi
}

####################### final auth yum##################################################################

fi_auth_yum(){
sudo echo "############################"
sudo echo "Configuratig files.."
sudo echo "Verifying the setup"
sudo systemctl enable sssd
sudo systemctl start sssd
states=$( echo null )
states1=$( echo null )
grouPs=$( echo null )
therealm=$( echo null )
cauth=$( echo null )
clear
read -p 'Do you wish to enable SSH login.group.allowed (y/n)?' yn
   case $yn in
    [Yy]* ) sudo echo "Cheking if there is any previous configuration"
	if [ -f /etc/ssh/login.group.allowed ] < /dev/null > /dev/null 2>&1
then
echo "Files seems already to be modified, skipping..."
else
echo "NOTICE! /etc/ssh/login.group.allowed will be created. make sure yor local user is in it you you could be banned from login"
echo "auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/ssh/login.group.allowed" | sudo tee -a /etc/pam.d/common-auth
sudo touch /etc/ssh/login.group.allowed
admins=$( cat /etc/passwd | grep home | grep bash | cut -d ':' -f1 )
echo ""
echo ""
read -p "Is your current administrator = "$admins" ? (y/n)?" yn
   case $yn in
    [Yy]* ) sudo echo "$admins"  | sudo tee -a /etc/ssh/login.group.allowed;;
    [Nn]* ) echo "please type name of current administrator"
read -p MYADMIN
sudo echo $MYADMIN | sudo tee -a /etc/ssh/login.group.allowed;;
    * ) echo "Please answer yes or no.";;
   esac
sudo echo "$NetBios"'\'"$myhost""sudoers" | sudo tee -a /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"domain^admins" | sudo tee -a /etc/ssh/login.group.allowed
sudo echo "root" | sudo tee -a /etc/ssh/login.group.allowed
echo "enabled SSH-allow"
fi;;
    [Nn]* ) echo "Disabled SSH login.group.allowed"
    states1=$( echo 12 );;
    * ) echo "Please answer yes or no.";;
   esac
echo ""
echo "-------------------------------------------------------------------------------------------"
echo ""
read -p 'Do you wish to give users on this machine sudo rights?(y/n)?' yn
   case $yn in
    [Yy]* ) sudo echo "Cheking if there is any previous configuration"
	if [ -f /etc/sudoers.d/sudoers ] < /dev/null > /dev/null 2>&1
then
echo ""
echo "The Sudoers file seems already to be modified, skipping..."
echo ""
else
read -p 'Do you wish to DISABLE password promt for users in terminal? (y/n)?' yn
   case $yn in
    [Yy]* )
sudo echo "administrator ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%$myhost""sudoers ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%DOMAIN\ admins ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/domain_admins
#sudo realm permit --groups "$myhost""sudoers"
;;

 [Nn]* ) sudo echo "administrator ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%$myhost""sudoers ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%DOMAIN\ admins ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/domain_admins
#sudo realm permit --groups "$myhost""sudoers"
;;
    * ) echo "Please answer yes or no.";;
   esac
fi;;
    [Nn]* ) echo "Disabled sudo rights for users on this machine"
    	    echo ""
	    echo ""
	    states=$( echo 12 );;
    * ) echo 'Please answer yes or no.';;
   esac
homedir=$( cat /etc/pam.d/common-session | grep homedir | grep 0022 | cut -d '=' -f3 )
if [ $homedir = 0022 ]
then
echo "pam_mkhomedir.so configured"
sleep 1
else
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" | sudo tee -a /etc/pam.d/common-session
fi
logintrue=$( cat /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf | grep -i -m1 login )
if [ -f /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf ]
then
if [ "$logintrue" =  "greeter-show-manual-login=true" ]
then
echo "50-ubuntu.conf is already configured.. skipping"
else
sudo sh -c "echo 'greeter-show-manual-login=true' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
sudo sh -c "echo 'allow-guest=false' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
fi
else
echo "No lightdm to configure"
fi
clear
sed -i -e 's/fallback_homedir = \/home\/%u@%d/#fallback_homedir = \/home\/%u@%d/g' /etc/sssd/sssd.conf
sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
sed -i -e 's/access_provider = ad/access_provider = simple/g' /etc/sssd/sssd.conf
sed -i -e 's/sudoers:        files sss/sudoers:        files/g' /etc/nsswitch.conf
echo "override_homedir = /home/%d/%u" | sudo tee -a /etc/sssd/sssd.conf
cat /etc/sssd/sssd.conf | grep -i override
sudo echo "[nss]
filter_groups = root
filter_users = root
reconnection_retries = 3
entry_cache_timeout = 600
#entry_cache_user_timeout = 5400
#entry_cache_group_timeout = 5400
#cache_credentials = TRUE
entry_cache_nowait_percentage = 75" | sudo tee -a /etc/sssd/sssd.conf
sudo service sssd restart
if [ $? = 0 ]
then
echo  "Checking sssd config.. OK"
else
echo "Checking sssd config.. FAIL"
fi
therealm=$(realm discover $DOMAIN | grep -i configured: | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//')
if [ "$therealm" = no ]
then
echo "Realm configured?.. FAIL"
else
echo "Realm configured?.. OK"
fi
if [ $states = 12 ]
then
echo "Sudoers not configured... skipping"
else
if [ -f /etc/sudoers.d/sudoers ] < /dev/null > /dev/null 2>&1
then
echo "Checking sudoers file.. OK"
else
echo "Checking sudoers file.. FAIL"
fi
grouPs=$(cat /etc/sudoers.d/sudoers | grep -i "$myhost" | cut -d '%' -f2 | awk '{print $1}')
if [ "$grouPs" = "$myhost""sudoers" ]
then
echo "Checking sudoers users.. OK"
else
echo "Checking sudoers users.. FAIL"
fi
homedir=$(cat /etc/pam.d/common-session | grep homedir | grep 0022 | cut -d '=' -f3)
if [ $homedir = 0022 ] < /dev/null > /dev/null 2>&1
then
echo "Checking PAM configuration.. OK"
else
echo "Checking PAM configuration.. FAIL"
fi
if [ $states1 = 12 ]
then 
echo "Disabled SSH login.group.allowed"
else
cauth=$(cat /etc/pam.d/common-auth | grep required | grep onerr | grep allow | cut -d '=' -f4 | awk '{print $1}')
if [ $cauth = allow ] < /dev/null > /dev/null 2>&1
then
echo "Checking PAM auth configuration.. OK"
else
echo "Checking PAM auth configuration.. FAIL"
fi
fi
#realm discover $DOMAIN
if [ "$therealm" = no ]
then
echo "Join has Failed"
else
lastverify=$( realm discover $DOMAIN | grep -m 1 $DOMAIN )
echo ""
echo "joined to $lastverify"
echo ""
fi
echo "Please reboot your machine and wait 3 min for Active Directory to sync before login"
exit
fi
}


####################### Setup for Ubuntu 14,16 and 17 clients #######################################
#Runs ADjoin in debug mode. meaning it opens terminals following logs
linuxclientdebug(){
desktop=$(sudo apt list --installed | grep -i desktop | grep -i ubuntu | cut -d '-' -f1 | grep -i desktop | head -1 | awk '{print$1}')
gnome-terminal --geometry=130x20 -e "bash -c \"journalctl -fxe; exec bash\""
gnome-terminal --geometry=130x20 -e "bash -c \"journalctl -fxe | grep -i -e closed -e Successfully -e 'Preauthentication failed' -e 'authenticate' -e 'Failed to join the domain'; exec bash\""
linuxclient
}

################################## Join for linux clients ##########################################
linuxclient(){
TheOS=$( hostnamectl | grep -i Operating | awk '{print $3}' ) < /dev/null > /dev/null 2>&1
rasp=$( lsb_release -a | grep -i Distributor | awk '{print $3}' ) < /dev/null > /dev/null 2>&1
kalilinux=$( lsb_release -a | grep -i Distributor | awk '{print $3}' ) < /dev/null > /dev/null 2>&1
desktop=$( sudo apt list --installed | grep -i desktop | grep -i ubuntu | cut -d '-' -f1 | grep -i desktop | head -1 | awk '{print$1}' ) < /dev/null > /dev/null 2>&1
#### OS detection ####
if [ "$TheOS" = "Fedora" ] < /dev/null > /dev/null 2>&1
then
echo "Fedora detected"
Fedora_fn
else
if [ "$TheOS" = "CentOS" ] < /dev/null > /dev/null 2>&1
then
echo "Cent OS detected"
CentOS
else
if [ "$TheOS" = "Debian" ] < /dev/null > /dev/null 2>&1
then
echo "Debian detected"
debianclient
else
if [ "$TheOS" = "Ubuntu" ] < /dev/null > /dev/null 2>&1
then
echo "Ubuntu detected"
echo ""
echo "Checking if it is a Desktop or server"
if [ "$desktop" = "desktop" ] < /dev/null > /dev/null 2>&1
then
echo "Ubuntu Desktop detected"
UbuntU
else
echo " this seems to be a server, swithching to server mode"
ubuntuserver14
fi
else
if [ "$rasp" = "Raspbian" ] < /dev/null > /dev/null 2>&1
then
echo "${INTRO_TEXT}"Detecting Raspberry Pi"${END}"
raspberry
else
if [ "$kalilinux" = "Kali" ] < /dev/null > /dev/null 2>&1
then
echo "${INTRO_TEXT}"Detecting Kali linux"${END}"
 kalijoin
else
echo "No compatible System found"
exit
fi
fi
fi
fi
fi
fi
}
UbuntU(){
export HOSTNAME
myhost=$( hostname )
clear
sudo echo "${RED_TEXT}"Installing pakages do no abort!......."${INTRO_TEXT}"
sudo apt-get -qq install realmd adcli sssd -y
sudo apt-get -qq install ntp -y
sudo apt-get -qq install -f -y
clear
sudo dpkg -l | grep realmd
if [ $? = 0 ]
then
clear
sudo echo "${INTRO_TEXT}"Pakages installed"${END}"
else
clear
sudo echo "${RED_TEXT}"Installing pakages failed.. please check connection ,dpkg and apt-get update then try again."${INTRO_TEXT}"
exit
fi
echo "hostname is $myhost"
echo "Looking for Realms.. please wait"
DOMAIN=$(realm discover | grep -i realm.name | awk '{print $2}')
ping -c 2 $DOMAIN  >/dev/null
if [ $? = 0 ]
then
clear
echo "${NUMBER}I searched for an available domain and found ${MENU}>>> $DOMAIN  <<<${END}${END}"
read -p "Do you wish to use it (y/n)?" yn
   case $yn in
    [Yy]* ) echo "";;

    [Nn]* ) echo "Please enter the domain you wish to join:"
	read -r DOMAIN;;
    * ) echo 'Please answer yes or no.';;
   esac
else
clear
echo "${NUMBER}I searched for an available domain and found nothing, please type your domain manually below... ${END}"
echo "Please enter the domain you wish to join:"
read -r DOMAIN
fi
NetBios=$(echo $DOMAIN | cut -d '.' -f1)
clear
var=$(lsb_release -a | grep -i release | awk '{print $2}' | cut -d '.' -f1)
if [ "$var" -eq "14" ]
then
echo "Installing additional dependencies"
sudo apt-get -qq install -y realmd sssd sssd-tools samba-common krb5-user
sudo apt-get -qq install -f -y
clear
echo "${INTRO_TEXT}"Detecting Ubuntu $var"${END}"
sudo echo "${INTRO_TEXT}"Realm=$DOMAIN"${INTRO_TEXT}"
echo "${INTRO_TEXT}"Joining Ubuntu $var"${END}"
echo ""
echo "${INTRO_TEXT}"Please log in with domain admin to $DOMAIN to connect"${END}"
echo "${INTRO_TEXT}"Please type Admin user:"${END}"
read ADMIN
sudo realm join -v -U $ADMIN $DOMAIN --install=/
else
   if [ "$var" -eq "16" ]
   then
   echo "${INTRO_TEXT}"Detecting Ubuntu $var"${END}"
   clear
sudo echo "${INTRO_TEXT}"Realm=$DOMAIN"${INTRO_TEXT}"
echo "${INTRO_TEXT}"Joining Ubuntu $var"${END}"
echo ""
echo "${INTRO_TEXT}"Please log in with domain admin to $DOMAIN to connect"${END}"
echo "${INTRO_TEXT}"Please type Admin user:"${END}"
read ADMIN
   sudo realm join --verbose --user=$ADMIN $DOMAIN
   else
       if [ "$var" -eq "17" ] || [ "$var" -eq "18" ]
       then
       echo "${INTRO_TEXT}"Detecting Ubuntu $var"${END}"
          sleep 1
   clear
sudo echo "${INTRO_TEXT}"Realm=$DOMAIN"${INTRO_TEXT}"
echo "${INTRO_TEXT}"Joining Ubuntu $var"${END}"
echo ""
echo "${INTRO_TEXT}"Please log in with domain admin to $DOMAIN to connect"${END}"
echo "${INTRO_TEXT}"Please type Admin user:"${END}"
read ADMIN
       sudo realm join --verbose --user=$ADMIN $DOMAIN --install=/
       else
       clear
      sudo echo "${RED_TEXT}"I am having issuers to detect your Ubuntu version"${INTRO_TEXT}"
     exit
     fi
  fi
fi
if [ $? -ne 0 ]; then
	echo "${RED_TEXT}"AD join failed.please check that computer object is already created and test again "${END}"
    exit
fi
fi_auth
}

####################### Setup for Ubuntu server #######################################

ubuntuserver14(){
export HOSTNAME
myhost=$( hostname )
clear
sudo echo "${RED_TEXT}"Installing pakages do no abort!......."${INTRO_TEXT}"
sudo apt-get -qq install realmd adcli sssd -y
sudo apt-get -qq install ntp -y
sudo apt-get -qq install -y sssd-tools samba-common krb5-user
sudo apt-get -qq install -f -y
clear
sudo dpkg -l | grep realmd
if [ $? = 0 ]
then
clear
sudo echo "${INTRO_TEXT}"Pakages installed"${END}"
else
clear
sudo echo "${RED_TEXT}"Installing pakages failed.. please check connection and dpkg and try again."${INTRO_TEXT}"
exit
fi
sleep 1
DOMAIN=$( realm discover | grep -i realm-name | awk '{print $2}')
ping -c 1 $DOMAIN
if [ $? = 0 ]
then
clear
echo "${NUMBER}I searched for an available domain and found ${MENU}>>> $DOMAIN  <<<${END}${END}"
read -p "Do you wish to use it (y/n)?" yn
   case $yn in
    [Yy]* ) echo "${INTRO_TEXT}"Please log in with domain admin to $DOMAIN to connect"${END}";;

    [Nn]* ) echo "Please enter the domain you wish to join:"
	read -r DOMAIN;;
    * ) echo 'Please answer yes or no.';;
   esac
else
clear
echo "${NUMBER}I searched for an available domain and found nothing, please type your domain manually below... ${END}"
echo "Please enter the domain you wish to join:"
read -r DOMAIN
fi
echo "${NUMBER}Please type groupname in AD for admins${END}"
read -r Mysrvgroup
sudo echo "${INTRO_TEXT}"Realm= $DOMAIN"${INTRO_TEXT}"
sudo echo "${NORMAL}${NORMAL}"
echo "${INTRO_TEXT}"Please type Admin user:"${END}"
read -r ADMIN
sudo realm join -v -U $ADMIN $DOMAIN --install=/
if [ $? -ne 0 ]; then
	echo "${RED_TEXT}"AD join failed.please check that computer object is already created and test again "${END}"
    exit 1
fi
sudo echo "############################"
sudo echo "Configuratig files.."
sudo echo "Verifying the setup"
sudo systemctl enable sssd
sudo systemctl start sssd
states=$( echo null )
states1=$( echo null )
grouPs=$( echo null )
therealm=$( echo null )
cauth=$( echo null )
clear
read -p "${RED_TEXT}"'Do you wish to enable SSH login.group.allowed'"${END}""${NUMBER}"'(y/n)?'"${END}" yn
   case $yn in
    [Yy]* ) sudo echo "Cheking if there is any previous configuration"
	if [ -f /etc/ssh/login.group.allowed ] < /dev/null > /dev/null 2>&1
then
echo "Files seems already to be modified, skipping..."
else
echo "NOTICE! /etc/ssh/login.group.allowed will be created. make sure yor local user is in it you you could be banned from login"
echo "auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/ssh/login.group.allowed" | sudo tee -a /etc/pam.d/common-auth
sudo touch /etc/ssh/login.group.allowed
admins=$( cat /etc/passwd | grep home | grep bash | cut -d ':' -f1 )
echo ""
echo ""
read -p "Is your current administrator = "$admins" ? (y/n)?" yn
   case $yn in
    [Yy]* ) sudo echo "$admins"  | sudo tee -a /etc/ssh/login.group.allowed;;
    [Nn]* ) echo "please type name of current administrator"
read -p MYADMIN
sudo echo $MYADMIN | sudo tee -a /etc/ssh/login.group.allowed;;
    * ) echo "Please answer yes or no.";;
   esac
sudo echo "$Mysrvgroup" | sudo tee -a /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"$myhost""sudoers" | sudo tee -a /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"domain^admins" | sudo tee -a /etc/ssh/login.group.allowed
sudo echo "root" | sudo tee -a /etc/ssh/login.group.allowed
echo "enabled SSH-allow"
fi;;
    [Nn]* ) echo "Disabled SSH login.group.allowed"
    states1=$( echo 12 );;
    * ) echo "Please answer yes or no.";;
   esac
echo ""
echo "-------------------------------------------------------------------------------------------"
echo ""
read -p "${RED_TEXT}"'Do you wish to give users on this machine sudo rights?'"${END}""${NUMBER}"'(y/n)?'"${END}" yn
   case $yn in
    [Yy]* ) sudo echo "Cheking if there is any previous configuration"
	if [ -f /etc/sudoers.d/sudoers ] < /dev/null > /dev/null 2>&1
then
echo ""
echo "Sudoersfile seems already to be modified, skipping..."
echo ""
else
sudo echo "administrator ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%$Mysrvgroup""sudoers ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%$myhost""sudoers ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%domain\ users ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%DOMAIN\ admins ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/domain_admins
#sudo realm permit --groups "$myhost""sudoers"
fi;;
    [Nn]* ) echo "Disabled sudo rights for users on this machine"
    	    echo ""
	    echo ""
	    states=$( echo 12 );;
    * ) echo 'Please answer yes or no.';;
   esac
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" | sudo tee -a /etc/pam.d/common-session
sudo sh -c "echo 'greeter-show-manual-login=true' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
sudo sh -c "echo 'allow-guest=false' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"

therealm=$( realm discover | grep -i realm-name | awk '{print $2}')
if [ $therealm = no ]
then
echo Realm configured?.. "${RED_TEXT}"FAIL"${END}"
else
echo Realm configured?.. "${INTRO_TEXT}"OK"${END}"
fi
if [ -f /etc/sudoers.d/sudoers ] < /dev/null > /dev/null 2>&1
then
echo Checking sudoers file..  "${INTRO_TEXT}"OK"${END}"
else
echo checking sudoers file..  "${RED_TEXT}"FAIL not configured"${END}"
fi
grouPs=$(cat /etc/sudoers.d/sudoers | grep -i $myhost | cut -d '%' -f2 | cut -d  '=' -f1 | sed -e 's/\<ALL\>//g')
if [ $grouPs = "$myhost""sudoers" ]
then
echo Checking sudoers users.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking sudoers users.. "${RED_TEXT}"FAIL"${END}"
fi
homedir=$(cat /etc/pam.d/common-session | grep homedir | grep 0022 | cut -d '=' -f3)
if [ $homedir = 0022 ] < /dev/null > /dev/null 2>&1
then
echo Checking PAM configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM configuration.. "${RED_TEXT}"FAIL"${END}"
fi
cauth=$(cat /etc/pam.d/common-auth | grep required | grep onerr | grep allow | cut -d '=' -f4 | cut -d 'f' -f1)
if [ $cauth = allow ] < /dev/null > /dev/null 2>&1
then
echo Checking PAM auth configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM auth configuration.. "${RED_TEXT}"SSH security not configured"${END}"
fi
sed -i -e 's/fallback_homedir = \/home\/%u@%d/#fallback_homedir = \/home\/%u@%d/g' /etc/sssd/sssd.conf
sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
sed -i -e 's/access_provider = ad/access_provider = simple/g' /etc/sssd/sssd.conf
sed -i -e 's/sudoers:        files sss/sudoers:        files/g' /etc/nsswitch.conf
echo "override_homedir = /home/%d/%u" | sudo tee -a /etc/sssd/sssd.conf
cat /etc/sssd/sssd.conf | grep -i override
sudo echo "[nss]
filter_groups = root
filter_users = root
reconnection_retries = 3
entry_cache_timeout = 600
#entry_cache_user_timeout = 5400
#entry_cache_group_timeout = 5400
#cache_credentials = TRUE
entry_cache_nowait_percentage = 75" | sudo tee -a /etc/sssd/sssd.conf
sudo service sssd restart
realm discover $DOMAIN
echo "${INTRO_TEXT}Please reboot your machine and wait 3 min for Active Directory to sync before login${INTRO_TEXT}"
exit
}

####################################### Kali ############################################

kalijoin(){
export HOSTNAME
myhost=$( hostname )
export whoami
whoamis=$( whoami )
admins=$( cat /etc/passwd | grep home | grep bash | cut -d ':' -f1 )
sudo echo "${RED_TEXT}"Installing pakages do no abort!......."${INTRO_TEXT}"
sudo apt-get -qq update
sudo apt-get -qq install libsss-sudo -y
sudo apt-get -qq install adcli -y
sudo apt-get -qq install realmd adcli sssd -y
sudo apt-get -qq install ntp -y
sudo apt-get -qq install policykit-1 -y
sudo mkdir -p /var/lib/samba/private
sudo apt-get -qq install realmd adcli sssd -y
sudo apt-get -qq install ntp -y
sudo apt-get -qq install -f -y
clear
sudo dpkg -l | grep realmd
if [ $? = 0 ]
then
clear
sudo echo "${INTRO_TEXT}"Pakages installed"${END}"
else
clear
sudo echo "${RED_TEXT}"Installing pakages failed.. please check connection ,dpkg and apt-get update then try again."${INTRO_TEXT}"
exit
fi
echo "hostname is $myhost"
DOMAIN=$(realm discover | grep -i realm.name | awk '{print $2}')
ping -c 2 $DOMAIN  >/dev/null
if [ $? = 0 ]
then
clear
echo "${NUMBER}I searched for an available domain and found $DOMAIN  ${END}"
read -p "Do you wish to use it (y/n)?" yn
   case $yn in
    [Yy]* ) echo "${INTRO_TEXT}"Please log in with domain admin to $DOMAIN to connect"${END}";;

    [Nn]* ) echo "Please enter the domain you wish to join:"
	read -r DOMAIN;;
    * ) echo 'Please answer yes or no.';;
   esac
else
clear
echo "${NUMBER}I searched for an available domain and found nothing, please type your domain manually below... ${END}"
echo "Please enter the domain you wish to join:"
read -r DOMAIN
fi
NetBios=$(echo $DOMAIN | cut -d '.' -f1)
echo ""
echo "${INTRO_TEXT}"Please type Admin user:"${END}"
read ADMIN
clear
sudo echo "${INTRO_TEXT}"Realm= $DOMAIN"${INTRO_TEXT}"
sudo echo "${NORMAL}${NORMAL}"
sudo realm join --verbose --user=$ADMIN $DOMAIN --install=/
if [ $? -ne 0 ]; then
	echo "${RED_TEXT}"AD join failed.please check that computer object is already created and test again "${END}"
    exit
fi
fi_auth
}

####################################### Debian ##########################################

debianclient(){
export HOSTNAME
myhost=$( hostname )
dkpg -l | grep sudo
if [ $? = 0 ]
then
""
else
apt get install sudo -y
export whoami
whoamis=$( whoami )
echo $whoamis
admins=$( cat /etc/passwd | grep home | grep bash | cut -d ':' -f1 )
echo "$admins ALL=(ALL:ALL) ALL | tee -a /etc/sudoers.d/admin"
fi
clear
sudo echo "${RED_TEXT}"Installing pakages do no abort!......."${INTRO_TEXT}"
sudo apt-get -qq update
sudo apt-get -qq install libsss-sudo -y
sudo apt-get -qq install realmd adcli sssd -y
sudo apt-get -qq install ntp -y
sudo apt-get -qq install policykit-1 -y
sudo mkdir -p /var/lib/samba/private
sudo apt-get -qq install realmd adcli sssd -y
sudo apt-get -qq install ntp -y
sudo apt-get -qq install -f
clear
sudo dpkg -l | grep realmd
if [ $? = 0 ]
then
clear
sudo echo "${INTRO_TEXT}"Pakages installed"${END}"
else
clear
sudo echo "${RED_TEXT}"Installing pakages failed.. please check connection ,dpkg and apt-get update then try again."${INTRO_TEXT}"
exit
fi
echo "hostname is $myhost"
sleep 1
DOMAIN=$(realm discover | grep -i realm.name | awk '{print $2}')
ping -c 2 $DOMAIN  >/dev/null
if [ $? = 0 ]
then
clear
echo "${NUMBER}I searched for an available domain and found $DOMAIN  ${END}"
read -p "Do you wish to use it (y/n)?" yn
   case $yn in
    [Yy]* ) echo "${INTRO_TEXT}"Please log in with domain admin to $DOMAIN to connect"${END}";;

    [Nn]* ) echo "Please enter the domain you wish to join:"
	read -r DOMAIN;;
    * ) echo 'Please answer yes or no.';;
   esac
else
clear
echo "${NUMBER}I searched for an available domain and found nothing, please type your domain manually below... ${END}"
echo "Please enter the domain you wish to join:"
read -r DOMAIN
fi
NetBios=$(echo $DOMAIN | cut -d '.' -f1)
echo ""
echo "${INTRO_TEXT}"Please type Admin user:"${END}"
read ADMIN
clear
sudo echo "${INTRO_TEXT}"Realm= $DOMAIN"${INTRO_TEXT}"
sudo echo "${NORMAL}${NORMAL}"
sudo realm join --verbose --user=$ADMIN $DOMAIN --install=/
if [ $? -ne 0 ]; then
	echo "${RED_TEXT}"AD join failed.please check that computer object is already created and test again "${END}"
    exit
fi
fi_auth
}
####################################### Cent OS #########################################

# Functional but ugly
CentOS(){
#ugly but functional
export HOSTNAME
myhost=$( hostname )
yum -y install realmd sssd oddjob oddjob-mkhomedir adcli samba-common-tools samba-common
DOMAIN=$(realm discover | grep -i realm-name | awk '{print $2}')
ping -c 1 $DOMAIN
if [ $? = 0 ]
then
clear
echo "I searched for an available domain and found >>> $DOMAIN  <<<"
read -p "Do you wish to use it (y/n)?" yn
   case $yn in
    [Yy]* ) echo "Please log in with domain admin to $DOMAIN to connect";;

    [Nn]* ) echo "Please enter the domain you wish to join:"
	read -r DOMAIN;;
    * ) echo 'Please answer yes or no.';;
   esac
else
clear
echo "I searched for an available domain and found nothing, please type your domain manually below... "
echo "Please enter the domain you wish to join:"
read -r DOMAIN
echo "I Please enter AD admin user "
read -r ADMIN
fi
clear
sudo echo "Please enter AD admin user:"
read -r ADMIN
sudo echo "Realm= $DOMAIN"
sudo echo ""
sudo realm join -v -U $ADMIN $DOMAIN --install=/
if [ $? -ne 0 ]; then
	echo "AD join failed.please check that computer object is already created and test again"
    exit 1
fi
fi_auth_yum
exit
}

############################### Raspberry Pi ###################################

raspberry(){
export HOSTNAME
myhost=$( hostname )
sudo aptitude install ntp adcli sssd
sudo mkdir -p /var/lib/samba/private
sudo aptitude install libsss-sudo
sudo systemctl enable sssd
clear
DOMAIN=$( realm discover | grep -i realm-name | awk '{print $2}')
echo ""
echo "please type Domain admin"
read -r ADMIN
sudo realm join -v -U $ADMIN $DOMAIN --install=/
sudo systemctl start sssd
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" | sudo tee -a /etc/pam.d/common-session
sudo echo "pi ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%$myhost""sudoers ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/sudoers
sed -i -e 's/fallback_homedir = \/home\/%u@%d/#fallback_homedir = \/home\/%u@%d/g' /etc/sssd/sssd.conf
sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
sed -i -e 's/access_provider = ad/access_provider = simple/g' /etc/sssd/sssd.conf
sed -i -e 's/sudoers:        files sss/sudoers:        files/g' /etc/nsswitch.conf
echo "override_homedir = /home/%d/%u" | sudo tee -a /etc/sssd/sssd.conf
cat /etc/sssd/sssd.conf | grep -i override
sudo echo "[nss]
filter_groups = root
filter_users = root
reconnection_retries = 3
entry_cache_timeout = 600
#entry_cache_user_timeout = 5400
#entry_cache_group_timeout = 5400
#cache_credentials = TRUE
entry_cache_nowait_percentage = 75" | sudo tee -a /etc/sssd/sssd.conf
sudo service sssd restart
exit
}
############################### Fedora #########################################
Fedora_fn(){
#ugly but functional
export HOSTNAME
myhost=$( hostname )
yum -y install realmd sssd oddjob oddjob-mkhomedir adcli samba-common-tools samba-common
DOMAIN=$(realm discover | grep -i realm-name | awk '{print $2}')
ping -c 1 $DOMAIN
if [ $? = 0 ]
then
clear
echo "I searched for an available domain and found >>> $DOMAIN  <<<"
read -p "Do you wish to use it (y/n)?" yn
   case $yn in
    [Yy]* ) echo "Please log in with domain admin to $DOMAIN to connect";;

    [Nn]* ) echo "Please enter the domain you wish to join:"
	read -r DOMAIN;;
    * ) echo 'Please answer yes or no.';;
   esac
else
clear
echo "I searched for an available domain and found nothing, please type your domain manually below... "
echo "Please enter the domain you wish to join:"
read -r DOMAIN
echo "I Please enter AD admin user "
read -r ADMIN
fi
clear
sudo echo "Please enter AD admin user:"
read -r ADMIN
sudo echo "Realm= $DOMAIN"
sudo echo ""
sudo realm join -v -U $ADMIN $DOMAIN --install=/
if [ $? -ne 0 ]; then
	echo "AD join failed.please check that computer object is already created and test again"
    exit 1
fi
fi_auth_yum
exit
}


############################### Update to Realmd from likewise ##################
Realmdupdate(){
clear
echo ""
echo "this secion has been depricated, If you are still using likewise please see code"
echo ""
exit
}


#this section has been depricated
#If you are still using likewise please uncomment lines below and line 33
#Realmdupdate11(){
#export HOSTNAME
#myhost=$( hostname )
#echo "This will delete your homefolder and replace it. Please do a BACKUP"
#echo "Press ctrl C to cancel skript if you wish to make an backup first"
#sleep 5
#sudo apt-get update
#clear
#echo "Remember to recreate AD computer Object if you have upgraded the OS "versions will now match!"
#sleep 3
#sudo domainjoin-cli leave
#linuxclient
#}

############################### Fail check ####################################

failcheck(){
clear
export HOSTNAME
myhost=$( hostname )
find=$( realm discover )
if [ $? = 1 ]
then
echo "Sorry I am having issues finding your domain.. please type it"
read -r DOMAIN
else
echo ""
fi
therealm=$( realm discover | grep -i realm-name | awk '{print $2}')
if [ $therealm = no ]
then
echo Realm configured?.. "${RED_TEXT}"FAIL"${END}"
else
echo Realm configured?.. "${INTRO_TEXT}"OK"${END}"
fi
if [ -f /etc/sudoers.d/admins ] < /dev/null > /dev/null 2>&1
then
echo Checking sudoers file..  "${INTRO_TEXT}"OK"${END}"
grouPs=$(cat /etc/sudoers.d/admins | grep -i $myhost | cut -d '%' -f2 | cut -d  '=' -f1 | sed -e 's/\<ALL\>//g')
     if [ $grouPs = "$myhost""sudoers" ]
         then
         echo Checking sudoers users.. "${INTRO_TEXT}"OK"${END}"
         else
         echo Checking sudoers users.. "${RED_TEXT}"FAIL"${END}"
         fi
else
if [ -f /etc/sudoers.d/sudoers ] < /dev/null > /dev/null 2>&1
then
echo Checking sudoers file..  "${INTRO_TEXT}"OK"${END}"
grouPs1=$(cat /etc/sudoers.d/sudoers | grep -i $myhost | cut -d '%' -f2 | cut -d  '=' -f1 | sed -e 's/\<ALL\>//g')
     if [ $grouPs1 = "$myhost""sudoers" ]
         then
         echo Checking sudoers users.. "${INTRO_TEXT}"OK"${END}"
         else
         echo Checking sudoers users.. "${RED_TEXT}"FAIL"${END}"
         fi
else
echo Checking sudoers file.. "${RED_TEXT}"FAIL not configured"${END}"
fi
fi
homedir=$(cat /etc/pam.d/common-session | grep homedir | grep 0022 | cut -d '=' -f3)
if [ $homedir = 0022 ] < /dev/null > /dev/null 2>&1
then
echo Checking PAM configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM configuration.. "${RED_TEXT}"FAIL"${END}"
fi
cauth=$(cat /etc/pam.d/common-auth | grep required | grep onerr | grep allow | cut -d '=' -f4 | cut -d 'f' -f1)
if [ $cauth = allow ] < /dev/null > /dev/null 2>&1
then
echo Checking PAM auth configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM auth configuration.. "${RED_TEXT}"SSH security not configured"${END}"
fi
echo ""
echo "-------------------------------------------------------------------------------------"
realm discover
echo "-------------------------------------------------------------------------------------"
exit
}


failcheck_yum(){
clear
export HOSTNAME
myhost=$( hostname )
find=$( realm discover )
if [ $? = 1 ]
then
echo "Sorry I am having issues finding your domain.. please type it"
read -r DOMAIN
else
echo ""
fi
therealm=$( realm discover | grep -i realm-name | awk '{print $2}')
if [ $therealm = no ]
then
echo "Realm configured?.. FAIL"
else
echo "Realm configured?.. OK"
fi
if [ -f /etc/sudoers.d/admins ] < /dev/null > /dev/null 2>&1
then
echo "Checking sudoers file.. OK"
grouPs=$(cat /etc/sudoers.d/admins | grep -i $myhost | cut -d '%' -f2 | cut -d  '=' -f1 | sed -e 's/\<ALL\>//g')
     if [ $grouPs = "$myhost""sudoers" ]
         then
         echo "Checking sudoers users.. OK"
         else
         echo "Checking sudoers users.. FAIL"
         fi
else
if [ -f /etc/sudoers.d/sudoers ] < /dev/null > /dev/null 2>&1
then
echo "Checking sudoers file..  OK"
grouPs1=$(cat /etc/sudoers.d/sudoers | grep -i $myhost | cut -d '%' -f2 | cut -d  '=' -f1 | sed -e 's/\<ALL\>//g')
     if [ $grouPs1 = "$myhost""sudoers" ]
         then
         echo "Checking sudoers users.. OK"
         else
         echo "Checking sudoers users.. FAIL"
         fi
else
echo "Checking sudoers file.. FAIL not configured"
fi
fi
homedir=$(cat /etc/pam.d/common-session | grep homedir | grep 0022 | cut -d '=' -f3)
if [ $homedir = 0022 ] < /dev/null > /dev/null 2>&1
then
echo "Checking PAM configuration.. OK"
else
echo "Checking PAM configuration.. FAIL"
fi
cauth=$(cat /etc/pam.d/common-auth | grep required | grep onerr | grep allow | cut -d '=' -f4 | cut -d 'f' -f1)
if [ $cauth = allow ] < /dev/null > /dev/null 2>&1
then
echo "Checking PAM auth configuration.. OK"
else
echo "Checking PAM auth configuration.. SSH security not configured"
fi
echo ""
echo "-------------------------------------------------------------------------------------"
realm discover
echo "-------------------------------------------------------------------------------------"
exit
}


#################################### ldapsearch #####################################################

ldaplook(){
export HOSTNAME
myhost=$( hostname )
ldaptools=$( sudo dpkg -l | grep -i ldap-utils | cut -d 's' -f1 | cut -d 'l' -f2 )
echo "${NUMBER}Remember!you must be logged in with AD admin on the client/server to use this funktion${END}"
echo "${NUMBER}Remember!please edit in ldap.conf the lines BASE and URI in /etc/ldap/ldap.conf ${END}"
sleep 3
if [ "$ldaptools" = dap-uti ]
then 
echo "ldap tool installed.. trying to find this host"
sudo ldapsearch cn=$myhost'*'
echo "Please type what you are looking for"
read own
sudo ldapsearch | grep -i $own
exit
else
sudo apt-get install ldap-utils -y
echo "${NUMBER}please edit in ldap.conf the lines BASE and URI ${END}"
sleep 3
sudo nano /etc/ldap/ldap.conf
sudo ldapsearch | grep -i $myhost
exit
fi
}

############################### Reauth ##########################################

Reauthenticate(){
whoelse=$( who -ut | grep -v old | awk '{print $1}' )
homes=$( ls /home/tobii.intra/ )
if [ "$homes" = "$whoelse" ]
then
echo ""
echo "you are logged in as an AD user.. canceling request"
echo "only administrator has permissions"
echo ""
exit
else
LEFT=$(sudo realm discover | grep configured | awk '{print $2}')
DOMAIN=$(realm discover | grep -i realm.name | awk '{print $2}')
SSSD=$( sudo cat /etc/sssd/sssd.conf | grep domain | awk '{print $3}' | head -1 )
DOMAINlower=$( echo $DOMAIN | tr '[:upper:]' '[:lower:]' )
if [ "$DOMAINlower" = "$SSSD" ]
then
echo "Detecting realm $SSSD"
else
    if [ "$LEFT" = "no" ]
    then
    echo ""
    echo "$DOMAIN has not been configured"
    echo ""
    linuxclient
    exit
    fi
    fi
read -p "Do you really want to leave the domain: $DOMAIN (y/n)?" yn
   case $yn in
    [Yy]* ) echo "Listing domain"
    sudo realm discover $DOMAIN
    sudo realm leave $DOMAIN
    LEFT=$(sudo realm discover | grep configured | awk '{print $2}')
    if [ "$LEFT" = "no" ]
    then
    echo ""
    sudo echo "" | sudo tee /etc/sssd/sssd.conf
    echo "$DOMAIN has been left"
    linuxclient
    else
    echo "something went wrong, try to leave manually"
    	read -r DOMAIN
	sudo realm leave $DOMAIN
    left=$(sudo realm discover | grep configured | awk '{print $2}')
 
    if [ "$left" = "no" ]
    then
    echo ""
    sudo echo "" | sudo tee /etc/sssd/sssd.conf
    echo "$DOMAIN has been left"
    linuxclient
    else
    echo "something went wrong"
    fi
    fi
    ;;
    [Nn]* ) echo "Bye"
	exit
	;;
    * ) echo 'Please answer yes or no.';;
   esac
exit
fi
}

########################################### Leave Realm ################################

leave(){
whoelse=$( who -ut | grep -v old | awk '{print $1}' )
homes=$( ls /home/tobii.intra/ )
if [ "$homes" = "$whoelse" ]
then
echo ""
echo "you are logged in as an AD user.. canceling request"
echo "only administrator has permissions"
echo ""
exit
else
LEFT=$(sudo realm discover | grep configured | awk '{print $2}')
DOMAIN=$(realm discover | grep -i realm.name | awk '{print $2}')
SSSD=$( sudo cat /etc/sssd/sssd.conf | grep domain | awk '{print $3}' | head -1 )
DOMAINlower=$( echo $DOMAIN | tr '[:upper:]' '[:lower:]' )
if [ "$DOMAINlower" = "$SSSD" ]
then
echo "Detecting realm $SSSD"
else
    if [ "$LEFT" = "no" ]
    then
    echo ""
    echo "$DOMAIN has not been configured"
    echo ""
    exit
    fi
    fi
read -p "Do you really want to leave the domain: $DOMAIN (y/n)?" yn
   case $yn in
    [Yy]* ) echo "Listing domain"
    sudo realm discover $DOMAIN
    sudo realm leave $DOMAIN
    LEFT=$(sudo realm discover | grep configured | awk '{print $2}')
    if [ "$LEFT" = "no" ]
    then
    echo ""
    sudo echo "" | sudo tee /etc/sssd/sssd.conf
    echo "$DOMAIN has been left"
    else
    echo "something went wrong, try to leave manually"
    	read -r DOMAIN
	sudo realm leave $DOMAIN
    left=$(sudo realm discover | grep configured | awk '{print $2}')
    if [ "$left" = "no" ]
    then
    echo ""
    sudo echo "" | sudo tee /etc/sssd/sssd.conf
    echo "$DOMAIN has been left"
    else
    echo "something went wrong"
    fi
    fi
    ;;
    [Nn]* ) echo "Bye"
	exit
	;;
    * ) echo 'Please answer yes or no.';;
   esac
exit
fi
}

########################################### info #######################################

readmes(){
clear
echo "Usage: sh ADconnection.sh [--help] "
echo "                          [-d (ubuntu debug mode)]"
echo "                          [-j admin domain (Simple direct join) ADconnection -j ADadmin domain"
echo "                          [-l (script output to log file)]"
echo "                          [-s (Discover domain)]"
echo "                          [-o (assign OU for computer object (-o OU=Clients,OU=Computers))"
echo ""
echo""
echo "${INTRO_TEXT}           Active directory connection tool                     ${INTRO_TEXT}"
echo "${INTRO_TEXT}                          Examples                                      ${INTRO_TEXT}"
echo "${INTRO_TEXT}     Domain to join:"${RED_TEXT}Example:${RED_TEXT}"" ${NUMBER}mydomain.intra${NUMBER}"${INTRO_TEXT}"
echo "${INTRO_TEXT}                                                            ${INTRO_TEXT}"
echo "${INTRO_TEXT}     Domain’s NetBios name:"${RED_TEXT}Example:${RED_TEXT}"" ${NUMBER}mydomain${NUMBER}"${INTRO_TEXT}"
echo "${INTRO_TEXT}                                                            ${INTRO_TEXT}"
echo "${INTRO_TEXT}     Domain username:"${RED_TEXT}Example:${RED_TEXT}"" ${NUMBER}ADadmin${NUMBER}"${INTRO_TEXT}"
echo "${INTRO_TEXT}                                                            ${INTRO_TEXT}"
echo "${INTRO_TEXT}     AD Group to put users in:"${RED_TEXT}Example:${RED_TEXT}"" ${NUMBER}Sudoers.global${NUMBER}"${INTRO_TEXT}"
echo "${RED_TEXT}       group should be created in AD with the groupname beeing the HOSTNAMEsudores             ${RED_TEXT}"
echo "${INTRO_TEXT}                                                            ${INTRO_TEXT}"
echo "${INTRO_TEXT}     Script will use hostname and add sudoer to it to sudoers "${RED_TEXT}Example:${RED_TEXT}""${NUMBER} myhostsudoer${NUMBER}"${INTRO_TEXT}"
echo "${INTRO_TEXT}     It is important that the computerobject "${RED_TEXT}Ex:${RED_TEXT}" myhost gets created in AD pre or post running the script ( the join will create an computer object by it self ${INTRO_TEXT}"
echo "${INTRO_TEXT}     and that the group "${RED_TEXT}Ex:${RED_TEXT}" myhostsudoes exists, sudoers must be added or edit this script to remove sudoers from name${INTRO_TEXT}"
echo "${INTRO_TEXT}     Script will also add domain admin group to sudoes                     ${INTRO_TEXT}"
echo "${NUMBER}     Remember to Check Hostname and add it to AD${NUMBER}"
echo "${INTRO_TEXT}     Reauthenticate is a fix for Ubuntu 14 likewise issues when client looses user (who am I?)${INTRO_TEXT}"
echo "${INTRO_TEXT}                                                                                                ${INTRO_TEXT}"
echo "${INTRO_TEXT}  Ubuntu 16 and 14 has the setting not to show domain name in name or homefolder due it can give${INTRO_TEXT}"
echo "${INTRO_TEXT} coding issues when building.. to change this configure /et/sssd/sssd.conf                      ${INTRO_TEXt}"
echo ""
exit
}
MENU_FN(){
########################################### Menu #######################################

clear
    echo "${INTRO_TEXT}   Active directory connection tool             ${INTRO_TEXT}"
    echo "${INTRO_TEXT}       Created by Pierre Goude                  ${INTRO_TEXT}"
	echo "${INTRO_TEXT} This script will edit several critical files.. ${INTRO_TEXT}"
	echo "${INTRO_TEXT}  DO NOT attempt this without expert knowledge  ${INTRO_TEXT}"
    echo "${NORMAL}                                                    ${NORMAL}"
    echo "${MENU}*${NUMBER} 1)${MENU} Join to AD on Linux (Ubuntu/Rasbian/Kali/Fedora/Debian)    ${NORMAL}"
    echo "${MENU}*${NUMBER} 2)${MENU} Check for errors    ${NORMAL}"
    echo "${MENU}*${NUMBER} 3)${MENU} Search with ldap              ${NORMAL}"
	echo "${MENU}*${NUMBER} 4)${MENU} Reauthenticate   ${NORMAL}"
	echo "${MENU}*${NUMBER} 5)${MENU} Update from Likewise to Realmd for Ubuntu 14 ${NORMAL}"
	echo "${MENU}*${NUMBER} 6)${MENU} Leave Domain             ${NORMAL}"
    echo "${NORMAL}                                                    ${NORMAL}"
    echo "${ENTER_LINE}Please enter a menu option and enter or ${RED_TEXT}enter to exit. ${NORMAL}"
	read opt
while [ opt != '' ]
    do
    if [ $opt = "" ]; then
            exit;
    else
        case $opt in
    1) clear;
            echo "Installing on Linux Client/Server";
            linuxclient
            ;;

	2) clear;
	    echo "Check for errors"
	     failcheck
             ;;
	3) clear;
	     echo "Check in Ldap"
	     ldaplook
             ;;
	4) clear;
	    echo "Rejoin to AD"
	    Reauthenticate
            ;;
	5) clear;
     	   echo "Update from Likewise to Realmd"
 	   Realmdupdate
           ;;
	6)
	clear;
	echo "Leave domain"
	leave
	;;
        x)exit;
        ;;
       \n)exit;
        ;;
        *)clear;
        opt "Pick an option from the menu";
        MENU_FN;
        ;;
    esac
fi
done
}
YUM_MENU(){
########################################### Menu YUM #######################################

clear
    echo "  Active directory connection tool             "
    echo "      Created by Pierre Goude                 "
	echo " This script will edit several critical files.. "
	echo "  DO NOT attempt this without expert knowledge  "
    echo ""
    echo "1) Join to AD on Linux (Ubuntu/Rasbian/Kali/Fedora)"
    echo "2) Check for errors"
    echo "3) Search with ldap"
	echo "4) Reauthenticate"
	echo "5) Update from Likewise to Realmd for Ubuntu 14"
	echo "6) Leave Domain"
    echo ""
    echo "Please enter a menu option and enter or enter to exit."
	read opt
while [ opt != '' ]
    do
    if [ $opt = "" ]; then
            exit;
    else
        case $opt in
    1) clear;
            echo "Installing on Linux Client/Server";
            linuxclient
            ;;
	2) clear;
	    echo "Check for errors"
	     failcheck_yum
             ;;
	3) clear;
	     echo "Check in Ldap"
	     ldaplook
             ;;
	4) clear;
	    echo "Rejoin to AD"
	    Reauthenticate
            ;;
	5) clear;
     	   echo "Update from Likewise to Realmd"
 	   Realmdupdate
           ;;
	5)
	clear;
	echo "Leave domain"
	leave
	;;
        x)exit;
        ;;
       \n)exit;
        ;;
        *)clear;
        opt "Pick an option from the menu";
        MENU_FN;
        ;;
    esac
fi
done
}




############################## Flags ###############################
clear
#Versi0n=$( echo "7" )
#update=$( curl -s https://github.com/PierreGode/Linux-Active-Directory-join-script/blob/master/ADconnection.sh | grep -i Versi0n | awk '{print $10}' )
#if [ "$update" -gt "$Version" ]
#then
#echo "Updating ADconnection"
#git pull
#else
#echo "ADconnection is up to date"
#fi
while test $# -gt 0; do
        case "$1" in
                -help|--help)
			readmes
                        ;;
                -d)
                        if test $# -gt 0; then
                        linuxclientdebug
                        else
                        echo ""
                        exit 1
                        fi
                         ;;
                -l)
                        if test $? -gt 0; then
                        DATE=`date +%H:%M`
			MENU_FN 2>&1 | sudo tee adconnection.log
                        else
                        echo ""
                        exit 1
                        fi
                        ;;
                -j)
                        if test $# -gt 0; then
			sudo realm join -v -U $2 $3 --install=/
			exit
                        else
                        echo ""
                        exit 1
                        fi
                        ;;
                -s)
                        if test $# -gt 0; then
			sudo realm discover
			exit
                        else
                        echo ""
                        exit 1
                        fi
                        ;;
                -o)
                        if test $# -gt 0; then
desktop=$( sudo apt list --installed | grep -i desktop | grep -i ubuntu | cut -d '-' -f1 | grep -i desktop )
rasp=$( lsb_release -a | grep -i Distributor | awk '{print $3}' )
kalilinux=$( lsb_release -a | grep -i Distributor | awk '{print $3}' )

if [ "$desktop" = "desktop" ]
then
if [ "$rasp" = "Raspbian" ]
then
echo "${INTRO_TEXT}"Detecting Raspberry Pi"${END}"
raspberry
else
if [ "$kalilinux" = "Kali" ]
then
echo "${INTRO_TEXT}"Detecting Kali linux"${END}"
kalijoin
else
echo ""
fi
fi
else
echo "this seems to be a server, swithching to server mode"
ubuntuserver14
fi
export HOSTNAME
myhost=$( hostname )
clear
sudo echo "${RED_TEXT}"Installing pakages do no abort!......."${INTRO_TEXT}"
sudo apt-get -qq install realmd adcli sssd -y
sudo apt-get -qq install ntp -y
sudo apt-get install -f -y
clear
sudo dpkg -l | grep realmd
if [ $? = 0 ]
then
clear
sudo echo "${INTRO_TEXT}"Pakages installed"${END}"
else
clear
sudo echo "${RED_TEXT}"Installing pakages failed.. please check connection ,dpkg and apt-get update then try again."${INTRO_TEXT}"
exit
fi
echo "hostname is $myhost"
echo "Looking for Realms.. please wait"
DOMAIN=$(realm discover | grep -i realm.name | awk '{print $2}')
ping -c 2 $DOMAIN  >/dev/null
if [ $? = 0 ]
then
clear
echo "${NUMBER}I searched for an available domain and found ${MENU}>>> $DOMAIN  <<<${END}${END}"
read -p "Do you wish to use it (y/n)?" yn
   case $yn in
    [Yy]* ) echo "";;

    [Nn]* ) echo "Please enter the domain you wish to join:"
	read -r DOMAIN;;
    * ) echo 'Please answer yes or no.';;
   esac
else
clear
echo "${NUMBER}I searched for an available domain and found nothing, please type your domain manually below... ${END}"
echo "Please enter the domain you wish to join:"
read -r DOMAIN
fi
NetBios=$(echo $DOMAIN | cut -d '.' -f1)
clear
var=$(lsb_release -a | grep -i release | awk '{print $2}' | cut -d '.' -f1)
if [ "$var" -eq "14" ]
then
echo "Installing additional dependencies"
sudo apt-get -qq install -y realmd sssd sssd-tools samba-common krb5-user
sudo apt-get install -f -y
clear
echo "${INTRO_TEXT}"Detecting Ubuntu $var"${END}"
sudo echo "${INTRO_TEXT}"Realm=$DOMAIN"${INTRO_TEXT}"
echo "${INTRO_TEXT}"Joining Ubuntu $var"${END}"
echo ""
echo "${INTRO_TEXT}"Please log in with domain admin to $DOMAIN to connect"${END}"
echo "${INTRO_TEXT}"Please type Admin user:"${END}"
read ADMIN
realm join -v --user="$ADMIN" --computer-ou="$2" $DOMAIN --install=/
else
   if [ "$var" -eq "16" ]
   then
   echo "${INTRO_TEXT}"Detecting Ubuntu $var"${END}"
   clear
sudo echo "${INTRO_TEXT}"Realm=$DOMAIN"${INTRO_TEXT}"
echo "${INTRO_TEXT}"Joining Ubuntu $var"${END}"
echo ""
echo "${INTRO_TEXT}"Please log in with domain admin to $DOMAIN to connect"${END}"
echo "${INTRO_TEXT}"Please type Admin user:"${END}"
read ADMIN
   realm join -v --user="$ADMIN" --computer-ou="$2" $DOMAIN
   else
       if [ "$var" -eq "17" ] || [ "$var" -eq "18" ]
       then
       echo "${INTRO_TEXT}"Detecting Ubuntu $var"${END}"
          sleep 1
   clear
sudo echo "${INTRO_TEXT}"Realm=$DOMAIN"${INTRO_TEXT}"
echo "${INTRO_TEXT}"Joining Ubuntu $var"${END}"
echo ""
echo "${INTRO_TEXT}"Please log in with domain admin to $DOMAIN to connect"${END}"
echo "${INTRO_TEXT}"Please type Admin user:"${END}"
read ADMIN
       realm join -v --user="$ADMIN" --computer-ou="$2" $DOMAIN --install=/
       else
       clear
      sudo echo "${RED_TEXT}"I am having issuers to detect your Ubuntu version"${INTRO_TEXT}"
     exit
     fi
  fi
fi
if [ $? -ne 0 ]; then
	echo "${RED_TEXT}"AD join failed.please check that computer object is already created and test again "${END}"
    exit
fi
fi_auth
                        else
                                echo ""
                                exit 1
                        fi
                        ;;
                *)
                        break
                        ;;
        esac
done
PRECHECK_FN(){
fedoras=$( cat /etc/fedora-release | awk '{print $1}' )
Centoss=$( hostnamectl | grep -i Operating | awk '{print $3}' )
if [ "$fedoras" = "Fedora" ]
then
YUM_MENU
else
if [ "$Centoss" = "CentOS" ]
then
YUM_MENU
else
MENU_FN
fi
fi
}
PRECHECK_FN

