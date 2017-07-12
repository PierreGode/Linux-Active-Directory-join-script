#!/bin/bash
##################################################################################################################################
#                                                                                                                                #
#                              This script is written by Pierre Goude                                                            #
#  This program is open source; you can redistribute it and/or modify it under the terms of the GNU General Public               #
#                     This is an normal bash script and can be executed with sh EX: ( sudo sh ADconnection.sh )                  #
# Generic user setup is: administrator, domain admins, groupnamesudores= groupname=hostname + sudoers on groupname in AD groups  #
##################################################################################################################################

#known bugs: see line 23-24

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
#this funktion is not called in the script : to activate, uncomment line line 29 #fixerrors
#This funktion installs additional pakages due to known issues with Joining and the join hangs after the admin auth
sudo add-apt-repository ppa:xtrusia/packagekit-fix
sudo apt-get update
sudo apt-get install packagekit
}
#fixerrors
####################### Setup for Ubuntu16 and Ubuntu 14 clients #######################################
ubuntuclient(){
desktop=$(sudo apt list --installed | grep -i desktop | grep -i ubuntu | cut -d '-' -f1 | grep -i desktop)
if [ $? = 0 ]
then
echo ""
else
echo " this seems to be a server, swithching to server mode"
sleep 2
ubuntuserver14
fi
export HOSTNAME
myhost=$( hostname )
clear
sudo echo "${RED_TEXT}"Installing pakages do no abort!......."${INTRO_TEXT}"
sudo apt-get -qq install realmd adcli sssd -y
sudo apt-get -qq install ntp -y
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
sleep 1
DOMAIN=$(realm discover | grep -i realm.name | awk '{print $2}')
ping -c 2 $DOMAIN
if [ $? = 0 ]
then
clear
echo "${NUMBER}I searched for an available domain and found >>> $DOMAIN  <<< ${END}"
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
discovery=$(realm discover $DOMAIN | grep domain-name)
NetBios=$(echo $DOMAIN | cut -d '.' -f1)
echo "${INTRO_TEXT}"Please type Admin user"${END}"
read ADMIN
clear
sudo echo "${INTRO_TEXT}"Realm= $discovery"${INTRO_TEXT}"
sudo echo "${NORMAL}${NORMAL}"
var=$(lsb_release -a | grep -i release | awk '{print $2}' | cut -d '.' -f1)
if [ "$var" -eq "14" ]
then
echo "${INTRO_TEXT}"Detecting Ubuntu $var"${END}"
echo "Installing additional dependencies"
sudo apt-get -qq install -y realmd sssd sssd-tools samba-common krb5-user
clear
sudo echo "${INTRO_TEXT}"Realm= $discovery"${INTRO_TEXT}"
sudo echo "${NORMAL}${NORMAL}"
sleep 1
clear
sudo realm join -v -U $ADMIN $DOMAIN --install=/
else
   if [ "$var" -eq "16" ]
   then
   echo "${INTRO_TEXT}"Detecting Ubuntu $var"${END}"
   sudo realm join --verbose --user=$ADMIN $DOMAIN
   else
       if [ "$var" -eq "17" ]
       then
       echo "${INTRO_TEXT}"Detecting Ubuntu $var"${END}"
       sudo realm join --verbose --user=$ADMIN $DOMAIN
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
	if [ -f /etc/ssh/login.group.allowed ]
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
	if [ -f /etc/sudoers.d/sudoers ]
then
echo ""
echo "Sudoersfile seems already to be modified, skipping..."
echo ""
else
sudo echo "administrator ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%$myhost""sudoers ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%domain\ users ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%DOMAIN\ admins ALL=(ALL) ALL" | sudo tee -a /etc/sudoers.d/domain_admins
#sudo realm permit --groups "$myhost""sudoers"
fi;;
    [Nn]* ) echo "Disabled sudo rights for users on this machine"
    	    echo ""
	    echo ""
	    states=$( echo 12 );;
    * ) echo 'Please answer yes or no.';;
   esac
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" | sudo tee -a /etc/pam.d/common-session
homedir=$( cat /etc/pam.d/common-session | grep homedir | grep 0022 | cut -d '=' -f3 )
if [ $homedir = 0022 ]
then
echo "pam_mkhomedir.so configured"
else
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" | sudo tee -a /etc/pam.d/common-session
fi
sudo sh -c "echo 'greeter-show-manual-login=true' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
sudo sh -c "echo 'allow-guest=false' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
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
if [ -f /etc/sudoers.d/sudoers ]
then
echo Checking sudoers file..  "${INTRO_TEXT}"OK"${END}"
else
echo checking sudoers file..  "${RED_TEXT}"FAIL"${END}"
fi
grouPs=$(cat /etc/sudoers.d/sudoers | grep -i sewspierre | cut -d '%' -f2 | awk '{print $1}')
if [ $grouPs = "$myhost""sudoers" ]
then 
echo Checking sudoers users.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking sudoers users.. "${RED_TEXT}"FAIL"${END}"
fi
fi
homedir=$(cat /etc/pam.d/common-session | grep homedir | grep 0022 | cut -d '=' -f3)
if [ $homedir = 0022 ]
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
if [ $cauth = allow ]
then
echo Checking PAM auth configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM auth configuration.. "${RED_TEXT}"FAIL"${END}"
fi
fi
exec sudo -u root /bin/sh - <<eof
sed -i -e 's/fallback_homedir = \/home\/%u@%d/#fallback_homedir = \/home\/%u@%d/g' /etc/sssd/sssd.conf
sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
echo "override_homedir = /home/%d/%u" | sudo tee -a /etc/sssd/sssd.conf
cat /etc/sssd/sssd.conf | grep -i override
sudo service sssd restart
if [ $? = 0 ]
then
echo  "Checking sssd config.. OK"
else
echo "Checking sssd config.. FAIL"
fi
realm discover $DOMAIN
echo "${INTRO_TEXT}Please reboot your machine and wait 3 min for Active Directory to sync before login${INTRO_TEXT}"
eof
exit
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
DOMAIN=$(realm discover | grep -i realm.name | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//')
ping -c 1 $DOMAIN
if [ $? = 0 ]
then
clear
echo "${NUMBER}I searched for an available domain and found >>> $DOMAIN  <<< ${END}"
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
echo "${NUMBER}I Please enter AD admin user ${END}"
read -r ADMIN
fi
sudo echo "${INTRO_TEXT}"Realm= $discovery"${INTRO_TEXT}"
sudo echo "${NORMAL}${NORMAL}"
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
clear
read -p "Do you wish to enable SSH allow/disble protection (y/n)?" yn
   case $yn in
    [Yy]* ) sudo echo "Cheking if there is any previous configuration"
	echo "auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/ssh/login.group.allowed" | sudo tee -a /etc/pam.d/common-auth
	if [ -f /etc/ssh/login.group.allowed ]
then
echo "Files seems already to be modified, skipping..."
else
echo "NOTICE! /etc/ssh/login.group.allowed will be created. make sure yor local user is in it you you could be banned from login"
sudo touch /etc/ssh/login.group.allowed
admins=$( cat /etc/passwd | grep home | grep bash | cut -d ':' -f1 )
read -p "Is your current administrator = "$admins" ? (y/n)?" yn
   case $yn in
    [Yy]* ) sudo echo "$admins"  | sudo tee -a /etc/ssh/login.group.allowed;;
    [Nn]* ) echo "please type name of current administrator"
read -p MYADMIN
sudo echo "$MYADMIN"  | sudo tee -a /etc/ssh/login.group.allowed;;
    * ) echo "Please answer yes or no.";;
   esac
sudo echo "$NetBios"'\'"$myhost""sudoers" | sudo tee -a /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"domain^admins" | sudo tee -a /etc/ssh/login.group.allowed
sudo echo "root" | sudo tee -a /etc/ssh/login.group.allowed
echo "enabled SSH-allow"
fi;;
    [Nn]* ) echo "disabled SSH allow";;
    * ) echo "Please answer yes or no.";;
   esac
read -p "Do you wish to give users on this machine sudo rights? (y/n)?" yn
   case $yn in
    [Yy]* ) sudo echo "Cheking if there is any previous configuration"
	if [ -f /etc/sudoers.d/sudoers ]
then
echo "Sudoersfile seems already to be modified, skipping..."
else
sudo echo "administrator ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%$myhost""sudoers ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%domain\ users ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%DOMAIN\ admins ALL=(ALL) ALL" | sudo tee -a /etc/sudoers.d/domain_admins
#sudo realm permit --groups "$myhost""sudoers"
fi;;
    [Nn]* ) echo "disabled sudo rights for users on this machine";;
    * ) echo 'Please answer yes or no.';;
   esac
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" | sudo tee -a /etc/pam.d/common-session
sudo sh -c "echo 'greeter-show-manual-login=true' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
sudo sh -c "echo 'allow-guest=false' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"

therealm=$(realm discover $DOMAIN | grep -i configured: | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//')
if [ $therealm = no ]
then
echo Realm configured?.. "${RED_TEXT}"FAIL"${END}"
else
echo Realm configured?.. "${INTRO_TEXT}"OK"${END}"
fi
if [ -f /etc/sudoers.d/sudoers ]
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
if [ $homedir = 0022 ]
then
echo Checking PAM configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM configuration.. "${RED_TEXT}"FAIL"${END}"
fi
cauth=$(cat /etc/pam.d/common-auth | grep required | grep onerr | grep allow | cut -d '=' -f4 | cut -d 'f' -f1)
if [ $cauth = allow ]
then
echo Checking PAM auth configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM auth configuration.. "${RED_TEXT}"FAIL ssh security not configured"${END}"
fi
exec sudo -u root /bin/sh - <<eof
sed -i -e 's/fallback_homedir = \/home\/%u@%d/#fallback_homedir = \/home\/%u@%d/g' /etc/sssd/sssd.conf
sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
echo "override_homedir = /home/%d/%u" | sudo tee -a /etc/sssd/sssd.conf
cat /etc/sssd/sssd.conf | grep -i override
sudo service sssd restart
if [ $? = 0 ]
then
echo  "Checking sssd config.. OK"
else
echo "Checking sssd config.. FAIL"
fi
realm discover
echo "${INTRO_TEXT}Please reboot your machine and wait 3 min for Active Directory to sync before login${INTRO_TEXT}"
eof
}

####################################### Cent OS #########################################
# Functional but ugly
CentOS(){
export HOSTNAME
myhost=$( hostname )
yum -y install realmd sssd oddjob oddjob-mkhomedir adcli samba-common-tools samba-common
DOMAIN=$(realm discover | grep -i realm.name | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//')
ping -c 1 $DOMAIN
if [ $? = 0 ]
then
clear
echo "${NUMBER}I searched for an available domain and found >>> $DOMAIN  <<< ${END}"
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
echo "${NUMBER}I Please enter AD admin user ${END}"
read -r ADMIN
fi
clear
sudo echo "Please enter AD admin user"
read -r ADMIN
sudo echo "${INTRO_TEXT}"Realm= $discovery"${INTRO_TEXT}"
sudo echo "${NORMAL}${NORMAL}"
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
clear
read -p "Do you wish to enable SSH allow/disble protection (y/n)?" yn
   case $yn in
    [Yy]* ) sudo echo "Cheking if there is any previous configuration"
	echo "auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/ssh/login.group.allowed" | sudo tee -a /etc/pam.d/common-auth
	if [ -f /etc/ssh/login.group.allowed ]
then
echo "Files seems already to be modified, skipping..."
else
echo "NOTICE! /etc/ssh/login.group.allowed will be created. make sure yor local user is in it you you could be banned from login"
sudo touch /etc/ssh/login.group.allowed
admins=$( cat /etc/passwd | grep home | grep bash | cut -d ':' -f1 )
read -p "Is your current administrator = "$admins" ? (y/n)?" yn
   case $yn in
    [Yy]* ) sudo echo "$admins"  | sudo tee -a /etc/ssh/login.group.allowed;;
    [Nn]* ) echo "please type name of current administrator"
read -p MYADMIN
sudo echo "$MYADMIN"  | sudo tee -a /etc/ssh/login.group.allowed;;
    * ) echo "Please answer yes or no.";;
   esac
sudo echo "$NetBios"'\'"$myhost""sudoers" | sudo tee -a /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"domain^admins" | sudo tee -a /etc/ssh/login.group.allowed
sudo echo "root" | sudo tee -a /etc/ssh/login.group.allowed
echo "enabled SSH-allow"
fi;;
    [Nn]* ) echo "disabled SSH allow";;
    * ) echo "Please answer yes or no.";;
   esac
read -p "Do you wish to give users on this machine sudo rights? (y/n)?" yn
   case $yn in
    [Yy]* ) sudo echo "Cheking if there is any previous configuration"
	if [ -f /etc/sudoers.d/sudoers ]
then
echo "Sudoersfile seems already to be modified, skipping..."
else
sudo echo "administrator ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%$myhost""sudoers ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%domain\ users ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
sudo echo "%DOMAIN\ admins ALL=(ALL) ALL" | sudo tee -a /etc/sudoers.d/domain_admins
#sudo realm permit --groups "$myhost""sudoers"
fi;;
    [Nn]* ) echo "disabled sudo rights for users on this machine";;
    * ) echo 'Please answer yes or no.';;
   esac
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" | sudo tee -a /etc/pam.d/common-session
sudo sh -c "echo 'greeter-show-manual-login=true' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
sudo sh -c "echo 'allow-guest=false' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"

therealm=$(realm discover $DOMAIN | grep -i configured: | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//')
if [ $therealm = no ]
then
echo Realm configured?.. "${RED_TEXT}"FAIL"${END}"
else
echo Realm configured?.. "${INTRO_TEXT}"OK"${END}"
fi
if [ -f /etc/sudoers.d/sudoers ]
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
if [ $homedir = 0022 ]
then
echo Checking PAM configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM configuration.. "${RED_TEXT}"FAIL"${END}"
fi
cauth=$(cat /etc/pam.d/common-auth | grep required | grep onerr | grep allow | cut -d '=' -f4 | cut -d 'f' -f1)
if [ $cauth = allow ]
then
echo Checking PAM auth configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM auth configuration.. "${RED_TEXT}"FAIL ssh security not configured"${END}"
fi
exec sudo -u root /bin/sh - <<eof
sed -i -e 's/fallback_homedir = \/home\/%u@%d/#fallback_homedir = \/home\/%u@%d/g' /etc/sssd/sssd.conf
sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
echo "override_homedir = /home/%d/%u" | sudo tee -a /etc/sssd/sssd.conf
cat /etc/sssd/sssd.conf | grep -i override
sudo service sssd restart
if [ $? = 0 ]
then
echo  "Checking sssd config.. OK"
else
echo "Checking sssd config.. FAIL"
fi
realm discover
echo "${INTRO_TEXT}Please reboot your machine and wait 3 min for Active Directory to sync before login${INTRO_TEXT}"
eof
}

############################### Raspberry Pi ###################################
raspberry(){
export HOSTNAME
myhost=$( hostname )
rasp=$(uname -a | grep -i raspberry | cut -d 'x' -f1 | cut -d 'y' -f2)
if [ $rasp -eq raspberr ]
then
echo "OMG do i sense a Raspberry! you sir are awesome" 
sleep 2
echo "Hold on... let me download a picture for you"
wget http://weknowmemes.com/generator/uploads/generated/g1410567650251917439.jpg
sleep 2
echo "Lets get this bad boy Joined!"
else 
echo "Something is wrong.." 
fi
sudo aptitude install realmd
sudo aptitude install ntp adcli sssd
sudo mkdir -p /var/lib/samba/private
sudo aptitude install libsss-sudo
sudo systemctl enable sssd
DOMAIN=$(realm discover | grep -i realm.name | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//')
echo "please type Domain admin"
read -r ADMIN
sudo realm join -v -U $ADMIN $DOMAIN --install=/
sudo systemctl start sssd
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" | sudo tee -a /etc/pam.d/common-session
sudo echo "%$myhost""sudoers ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
exec sudo -u root /bin/sh - <<eof
sed -i -e 's/fallback_homedir = \/home\/%u@%d/#fallback_homedir = \/home\/%u@%d/g' /etc/sssd/sssd.conf
sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
echo "override_homedir = /home/%d/%u" >> /etc/sssd/sssd.conf
eof
}
############################### Update to Realmd from likewise ##################
Realmdupdate(){
export HOSTNAME
myhost=$( hostname )
echo "This will delete your homefolder and replace it. Please do a BACKUP"
sleep 5
sudo apt-get update
clear
echo "Remember to recreate AD computer Object!"
sleep 3
echo "Please enter the domain you wish to join: "
read DOMAIN
echo "Please enter Your domain’s NetBios name"
read NetBios
echo "Please enter a domain admin login to use: "
read ADMIN
sudo domainjoin-cli leave
sleep 2
sudo echo "Installing necessary pakages...."
sudo apt-get install realmd adcli sssd -y
sudo apt-get install ntp -y
sudo apt-get install realmd sssd sssd-tools samba-common krb5-user
discovery=$(realm discover $DOMAIN | grep domain-name)
clear
sudo echo "${INTRO_TEXT}"Realm= $discovery"${INTRO_TEXT}"
sudo echo "${NORMAL}${NORMAL}"
sleep 1
echo "Next step sometime fails due no awnser from AD please reboot and run script again"
sleep 2
sudo realm join -v -U $ADMIN $DOMAIN --install=/
echo "Please enter user to add (user WITHOUT the @server.server)"
read UseR
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" | sudo tee -a /etc/pam.d/common-session
echo "auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/ssh/login.group.allowed" | sudo tee -a /etc/pam.d/common-auth
sudo echo "$UseR"" ALL=(ALL:ALL) ALL" >> /etc/sudoers
sudo echo "$NetBios"'\'"$UseR" >> /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"$myhost""sudoers" | sudo tee -a /etc/ssh/login.group.allowed
sudo echo "%DOMAIN\ admins@$DOMAIN ALL=(ALL) ALL" >> /etc/sudoers.d/domain_admins
therealm=$(realm discover | grep -i configured: | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//')
if [ $therealm = no ]
then
echo Realm configured?.. "${RED_TEXT}"FAIL"${END}"
else
echo Realm configured?.. "${INTRO_TEXT}"OK"${END}"
fi
if [ -f /etc/sudoers.d/sudoers ]
then
echo Checking sudoers file..  "${INTRO_TEXT}"OK"${END}"
else
echo checking sudoers file..  "${RED_TEXT}"FAIL"${END}"
fi
grouPs=$(cat /etc/sudoers.d/sudoers | grep -i $myhost | cut -d '%' -f2 | cut -d  '=' -f1 | sed -e 's/\<ALL\>//g')
if [ $grouPs = "$myhost""sudoers" ]
then 
echo Checking sudoers users.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking sudoers users.. "${RED_TEXT}"FAIL"${END}"
fi
homedir=$(cat /etc/pam.d/common-session | grep homedir | grep 0022 | cut -d '=' -f3)
if [ $homedir = 0022 ]
then
echo Checking PAM configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM configuration.. "${RED_TEXT}"FAIL"${END}"
fi
cauth=$(cat /etc/pam.d/common-auth | grep required | grep onerr | grep allow | cut -d '=' -f4 | cut -d 'f' -f1)
if [ $cauth = allow ]
then
echo Checking PAM auth configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM auth configuration.. "${RED_TEXT}"FAIL"${END}"
fi
guest=$(cat /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf | grep -i allow-guest | grep -i false | cut -d '=' -f2)
if [ "$guest" = false ]
then
echo Checking login configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking login configuration.. "${RED_TEXT}"FAIL"${END}"
fi
exec sudo -u root /bin/sh - <<eof
sed -i -e 's/fallback_homedir = \/home\/%d\/%u/#fallback_homedir = \/home\/%d\/%u/g' /etc/sssd/sssd.conf
sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
echo "override_homedir = /home/%d/%u" >> /etc/sssd/sssd.conf
eof
}

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
therealm=$(realm discover $DOMAIN | grep -i configured: | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//')
if [ $therealm = no ]
then
echo Realm configured?.. "${RED_TEXT}"FAIL"${END}"
else
echo Realm configured?.. "${INTRO_TEXT}"OK"${END}"
fi
if [ -f /etc/sudoers.d/admins ]
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
if [ -f /etc/sudoers.d/sudoers ]
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
if [ $homedir = 0022 ]
then
echo Checking PAM configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM configuration.. "${RED_TEXT}"FAIL"${END}"
fi
cauth=$(cat /etc/pam.d/common-auth | grep required | grep onerr | grep allow | cut -d '=' -f4 | cut -d 'f' -f1)
if [ $cauth = allow ]
then
echo Checking PAM auth configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM auth configuration.. "${RED_TEXT}"FAIL ssh security not configured"${END}"
fi
echo ""
echo "-------------------------------------------------------------------------------------"
realm discover
echo "-------------------------------------------------------------------------------------"
realm list
exit
}


#################################### ldapsearch #####################################################
ldaplook(){
export HOSTNAME
myhost=$( hostname )
ldaptools=$( sudo dpkg -l | grep -i ldap-utils | cut -d 's' -f1 | cut -d 'l' -f2 )
echo "${NUMBER}Remember!you must be logged in with AD admin on the client/server to use this funktion${END}"
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
Reauthenticate14(){
DOMAIN=$(realm discover | grep -i realm.name | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//')
read -p "Do you wish to use it (y/n)?" yn
   case $yn in
    [Yy]* ) echo "${INTRO_TEXT}"Please log in with domain admin to $DOMAIN to connect"${END}";;

    [Nn]* ) echo "Please enter the domain you wish to join:"
	read -r DOMAIN;;
    * ) echo 'Please answer yes or no.';;
   esac
echo "Type Adminuser"
read -r ADMIN
discover=$(realm discover | grep domain-name: | cut -d ':' -f2)
realm leave $discover
sudo realm join -v -U $ADMIN $DOMAIN --install=/
exit
}

########################################### info #######################################
readmes(){
clear
echo "${INTRO_TEXT}              Active directory connection tool   Realmd                     ${INTRO_TEXT}"
echo "${INTRO_TEXT}                          Examples                                      ${INTRO_TEXT}"
echo "${INTRO_TEXT}     Domain to join:"${RED_TEXT}Example:${RED_TEXT}"" ${NUMBER}mydomain.intra${NUMBER}"${INTRO_TEXT}"
echo "${INTRO_TEXT}                                                            ${INTRO_TEXT}"
echo "${INTRO_TEXT}     Domain’s NetBios name:"${RED_TEXT}Example:${RED_TEXT}"" ${NUMBER}mydomain${NUMBER}"${INTRO_TEXT}"
echo "${INTRO_TEXT}                                                            ${INTRO_TEXT}"
echo "${INTRO_TEXT}     Domain username:"${RED_TEXT}Example:${RED_TEXT}"" ${NUMBER}ADadmin${NUMBER}"${INTRO_TEXT}"
echo "${INTRO_TEXT}                                                            ${INTRO_TEXT}"
echo "${INTRO_TEXT}     AD Group to join:"${RED_TEXT}Example:${RED_TEXT}"" ${NUMBER}Sudoers.global${NUMBER}"${INTRO_TEXT}"
echo "${RED_TEXT}     User and computer must Exist in AD before Join             ${RED_TEXT}"
echo "${INTRO_TEXT}                                                            ${INTRO_TEXT}"
echo "${INTRO_TEXT}     Script will use hostname and add sudoer to it to sudoers "${RED_TEXT}Example:${RED_TEXT}""${NUMBER} myhostsudoer${NUMBER}"${INTRO_TEXT}"
echo "${INTRO_TEXT}     It is important that the computerobject "${RED_TEXT}Ex:${RED_TEXT}" myhost exists in AD ${INTRO_TEXT}"
echo "${INTRO_TEXT}     and that the group "${RED_TEXT}Ex:${RED_TEXT}" myhostsudoes exists, sudoers must be added or edit this script to remove sudoers from name${INTRO_TEXT}"
echo "${INTRO_TEXT}     Script will also add domain admin group to sudoes                     ${INTRO_TEXT}"
echo "${NUMBER}     Remember to Check Hostname and add it to AD before running the ADjoin${NUMBER}"
echo "${INTRO_TEXT}     Reauthenticate is a fix for Ubuntu 14 likewise issues when client looses user (who am I?)${INTRO_TEXT}"
echo "${INTRO_TEXT}                                                                                                ${INTRO_TEXT}"
echo "${INTRO_TEXT}  Ubuntu 16 and 14 has the setting not to show domain name in name or homefolder due it can give${INTRO_TEXT}"
echo "${INTRO_TEXT} coding issues when building.. to change this configure /et/sssd/sssd.conf                      ${INTRO_TEXT}"
exit
}
########################################### Menu #######################################
clear
    echo "${INTRO_TEXT}   Active directory connection tool             ${INTRO_TEXT}"
    echo "${INTRO_TEXT}       Created by Pierre Goude                  ${INTRO_TEXT}"
	echo "${INTRO_TEXT} This script will edit several critical files.. ${INTRO_TEXT}"
	echo "${INTRO_TEXT}  DO NOT attempt this without expert knowledge  ${INTRO_TEXT}"
    echo "${NORMAL}                                                    ${NORMAL}"
    echo "${MENU}*${NUMBER} 1)${MENU} Join to AD on Ubuntu Client or Server    ${NORMAL}"
    echo "${MENU}*${NUMBER} 2)${MENU} Join to AD on Debian Jessie Client    ${NORMAL}"
    echo "${MENU}*${NUMBER} 3)${MENU} Join to AD on CentOS  ${NORMAL}"
    echo "${MENU}*${NUMBER} 4)${MENU} Check for errors    ${NORMAL}"
    echo "${MENU}*${NUMBER} 5)${MENU} Search with ldap              ${NORMAL}"
	echo "${MENU}*${NUMBER} 6)${MENU} Reauthenticate (Ubuntu14 only)   ${NORMAL}"
	echo "${MENU}*${NUMBER} 7)${MENU} Update from Likewise to Realmd for Ubuntu 14 ${NORMAL}"
	echo "${MENU}*${NUMBER} 8)${MENU} README with examples             ${NORMAL}"
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
            echo "Installing on Ubuntu Client/Server";
            ubuntuclient;
            ;;

        2) clear;
            echo "Installing on Debian Jessie client";
            debianclient
            ;;
			
	3) clear;
	    echo "Installing on Debian Cent OS"
	    CentOS
            ;;
	    
	4) clear;
	    echo "Check for errors"
	     failcheck
            ;;
	    
	 5) clear;
	     echo "Check in Ldap"
	     ldaplook
             ;;
	 
	6) clear;
	    echo "Reauthenticate realmd for Ubuntu 14"
	    Reauthenticate14
            ;;

     	 7) clear;
     	   echo "Update from Likewise to Realmd"
 	   Realmdupdate
           ;;
	 
     	 8) clear;
     	   echo "READ ME"
	   readmes
           ;;
		 
        x)exit;
        ;;

        \n)exit;
        ;;

        *)clear;
        opt "Pick an option from the menu";
        show_etcmenu;
        ;;
    esac
fi
done
