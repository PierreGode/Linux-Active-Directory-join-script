#!/bin/bash
#####################################################################################################################
#                                                                                                                   #
#                              This script is written by Pierre Goude                                               #
#  This program is open source; you can redistribute it and/or modify it under the terms of the GNU General Public  #
#                                                                                                                   #
#                                                                                                                   #
#####################################################################################################################
# ~~~~~~~~~~  Environment Setup ~~~~~~~~~~ #
    NORMAL=`echo "\033[m"`
    MENU=`echo "\033[36m"` #Blue
    NUMBER=`echo "\033[33m"` #yellow
    FGRED=`echo "\033[41m"`
    RED_TEXT=`echo "\033[31m"` #Red
    ENTER_LINE=`echo "\033[33m"`
    INTRO_TEXT=`echo "\033[32m"` #green and white text
    INFOS=`echo "\033[103;30m"` #yellow bg
    SUCCESS=`echo "\033[102;30m"` #green bg
    WARNING=`echo "\033[101;30m"` #red bg
    WARP=`echo "\033[106;30m"` #lightblue bg
    BLACK=`echo "\033[109;30m"` #SPACE bg
    END=`echo "\033[0m"`
# ~~~~~~~~~~  Environment Setup ~~~~~~~~~~ #
sudo 
####################### Setup for Ubuntu16 and Ubuntu 14 clients #######################################
ubuntuclient(){
export HOSTNAME
myhost=$( hostname )
sudo apt-get install realmd adcli sssd -y
sudo apt-get install ntp -y
clear
echo "Please enter the domain you wish to join: "
read DOMAIN
NetBios=$(echo $DOMAIN | cut -d '.' -f1)
echo "Please enter a domain admin login to use: "
read ADMIN
discovery=$(realm discover $DOMAIN | grep domain-name)
clear
sudo echo "${INTRO_TEXT}"Realm= $discovery"${INTRO_TEXT}"
sudo echo "${NORMAL}${NORMAL}"
var=$(lsb_release -a | grep -i release: | cut -d ':' -f2 | cut -d '.' -f1)
if [ "$var" -eq "14" ]
then
echo "Detecting Ubuntu 14"
echo "Installing additional dependencies"
sudo apt-get install -y realmd sssd sssd-tools samba-common krb5-user
clear
sudo echo "${INTRO_TEXT}"Realm= $discovery"${INTRO_TEXT}"
sudo echo "${NORMAL}${NORMAL}"
sleep 1
clear
sudo realm join -v -U $ADMIN $DOMAIN --install=/
else
if [ "$var" -eq "16" ]
then
echo "Detecting Ubuntu 16"
sudo realm join --verbose --user=$ADMIN $DOMAIN
else
echo "Having issuers to detect your Ubuntu version"
exit
fi
fi
if [ $? -ne 0 ]; then
    echo "AD join failed.  Please run 'journalctl -xn' to determine why."
    exit 1
fi
sudo echo "Configuratig files" 
sudo systemctl enable sssd
sudo systemctl start sssd
sudo rm tmp.sh
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" >> /etc/pam.d/common-session
echo "auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/ssh/login.group.allowed" >> /etc/pam.d/common-auth
sudo sh -c "echo 'greeter-show-manual-login=true' >> /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
sudo sh -c "echo 'allow-guest=false' >> /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
sudo touch /etc/ssh/login.group.allowed
sudo echo "administrator" >> /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"$myhost""sudoers" >> /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"$UseR" >> /etc/ssh/login.group.allowed
sudo echo "administrator ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/sudoers
sudo echo "$NetBios"'\'"domain^admins" >> /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"$myhost""sudoers" >> /etc/ssh/login.group.allowed
sudo echo "%domain^admins ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/sudoers
sudo echo "%$myhost""sudoers ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/sudoers
sudo echo "%DOMAIN\ admins@$DOMAIN ALL=(ALL) ALL" >> /etc/sudoers.d/domain_admins
echo "Check that the group is correct"
echo "In Sudoers file..."
sudo cat /etc/sudoers.d/users | grep sudoers
echo "In SSH allow file..."
sudo cat /etc/ssh/login.group.allowed | grep $myhost
echo "If this is wrong DO NOT REBOOT and contact sysadmin"
exec sudo -u root /bin/sh - <<eof
sed -i -e 's/fallback_homedir = \/home\/%u@%d/#fallback_homedir = \/home\/%u@%d/g' /etc/sssd/sssd.conf
sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
echo "override_homedir = /home/%d/%u" >> /etc/sssd/sssd.conf
eof
}
####################### Setup for Ubuntu 14 server #######################################
ubuntuserver14(){
export HOSTNAME
myhost=$( hostname )
sudo apt-get update
sudo apt-get install realmd adcli sssd -y
sudo apt-get install ntp -y
sudo apt-get install realmd sssd sssd-tools samba-common krb5-user
clear
echo "Please enter the domain you wish to join: "
read DOMAIN
NetBios=$(echo $DOMAIN | cut -d '.' -f1)
echo "Please enter a domain admin login to use: "
read ADMIN
discovery=$(realm discover $DOMAIN | grep domain-name)
clear
sudo echo "${INTRO_TEXT}"Realm= $discovery"${INTRO_TEXT}"
sudo echo "${NORMAL}${NORMAL}"
sudo realm join -v -U $ADMIN $DOMAIN --install=/
if [ $? -ne 0 ]; then
    echo "AD join failed.  Please run 'journalctl -xn' to determine why."
    exit 1
fi
sudo echo "Configuratig files" 
sudo systemctl enable sssd
sudo systemctl start sssd
sudo rm tmp.sh
sudo sed -i '30s/.*/session [success=ok default=ignore] pam_lsass.so/' /etc/pam.d/common-session
sudo sh -c "sed -i 's|ChallengeResponseAuthentication yes|ChallengeResponseAuthentication no|' /etc/ssh/sshd_config"
sudo sh -c "echo 'auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/ssh/login.group.allowed' >> /etc/pam.d/common-auth"
sudo touch /etc/ssh/login.group.allowed
sudo echo "administrator" >> /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"$myhost""sudoers" >> /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"$UseR" >> /etc/ssh/login.group.allowed
sudo echo "administrator ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/admins
sudo echo "$NetBios"'\'"domain^admins" >> /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"$myhost""sudoers" >> /etc/ssh/login.group.allowed
sudo echo "%domain^admins ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/admins
sudo echo "%$myhost""sudoers ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/admins
sudo echo "%DOMAIN\ admins@$DOMAIN ALL=(ALL) ALL" >> /etc/sudoers.d/domain_admins
sudo rm -R pbis-open-8.0.1.2029.linux.x86_64*
echo "Check that the group is correct"
echo "In Sudoers file..."
sudo cat /etc/sudoers.d/admins | grep sudoers
echo "In SSH allow file..."
sudo cat /etc/ssh/login.group.allowed | grep sudoers
echo "If this is wrong DO NOT REBOOT and contact sysadmin"
}
####################### Setup for Debian client #######################################
# This script should join Debian Jessie (8) to an Active Directory domain.
debianclient(){
export HOSTNAME
myhost=$( hostname )
sudo apt-get update
sudo apt-get install libsss-sudo -y
sudo apt-get install realmd adcli sssd -y
sudo apt-get install ntp -y
sudo mkdir -p /var/lib/samba/private
clear 
echo "Please enter the domain you wish to join: "
read DOMAIN
echo "Please enter Your domain’s NetBios name"
read NetBios
echo "Please enter a domain admin login to use: "
read ADMIN
sudo realm join --user=$ADMIN $DOMAIN 
if [ $? -ne 0 ]; then
    echo "AD join failed.  Please run 'journalctl -xn' to determine why."
    exit 1
fi
sudo systemctl enable sssd
sudo systemctl start sssd
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" | sudo tee -a /etc/pam.d/common-session
# configure sudo
echo "Please enter new user without @mydomain"
read newuser
echo "%domain\ admins@$DOMAIN ALL=(ALL) ALL" | sudo tee -a /etc/sudoers.d/domain_admins
sudo echo "$newuser"'@'"$DOMAIN"" ALL=(ALL:ALL) ALL" >> /etc/sudoers
while true; do
   read -p 'Do you want to Reboot now? (y/n)?' yn
   case $yn in
    [Yy]* ) sudo reboot
            break;;
    [Nn]* ) echo "plese remember to reboot"
            sleep 1
            exit ;;
    * ) echo 'Please answer yes or no.';;
   esac
done
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
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" >> /etc/pam.d/common-session
echo "auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/ssh/login.group.allowed" >> /etc/pam.d/common-auth
sudo echo "$UseR"" ALL=(ALL:ALL) ALL" >> /etc/sudoers
sudo echo "$NetBios"'\'"$UseR" >> /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"$myhost""sudoers" >> /etc/ssh/login.group.allowed
sudo echo "%DOMAIN\ admins@$DOMAIN ALL=(ALL) ALL" >> /etc/sudoers.d/domain_admins
cho "Check that the group is correct"
echo "In Sudoers file..."
sudo cat /etc/sudoers | grep $myhost
sudo cat /etc/sudoers | grep $UseR
exec sudo -u root /bin/sh - <<eof
sed -i -e 's/fallback_homedir = \/home\/%d\/%u/#fallback_homedir = \/home\/%d\/%u/g' /etc/sssd/sssd.conf
sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
echo "override_homedir = /home/%d/%u" >> /etc/sssd/sssd.conf
eof
}
############################### Reauth ##########################################
Reauthenticate14(){
echo "Reauth for Realmd ubuntu 14 only!"
echo "Type domain"
read DOMAIN
echo "Type Adminuser"
read ADMIN
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
    echo "${MENU}*${NUMBER} 1)${MENU} Setup AD on Ubuntu Client     ${NORMAL}"
    echo "${MENU}*${NUMBER} 2)${MENU} Setup AD on Ubuntu 14 Server     ${NORMAL}"
    echo "${MENU}*${NUMBER} 3)${MENU} Setup AD on Debian Jessie Client ${NORMAL}"
	echo "${MENU}*${NUMBER} 4)${MENU} Reauthenticate (Ubuntu14 only)   ${NORMAL}"
	echo "${MENU}*${NUMBER} 5)${MENU} Update from Likewise to Realmd for Ubuntu 14 ${NORMAL}"
	echo "${MENU}*${NUMBER} 6)${MENU} README with examples             ${NORMAL}"
    echo "${NORMAL}                                                    ${NORMAL}"
    echo "${ENTER_LINE}Please enter a menu option and enter or ${RED_TEXT}enter to exit. ${NORMAL}"
	read opt
while [ opt != '' ]
    do
    if [[ $opt = "" ]]; then 
            exit;
    else
        case $opt in
        1) clear;
        echo "Installing on Ubuntu Client";
        ubuntuclient;
        ;;

        2) clear;
            echo "Installing on Ubuntu 14 Server";
            ubuntuserver14
            ;;
			
		3) clear;
		   echo "Installing on Debian Jessie client"
		   debianclient
         ;;
		4) clear;
		   echo "Reauthenticate realmd for Ubuntu 14"
		   Reauthenticate14
         ;;

     	 5) clear;
     	   echo "Update from Likewise to Realmd"
		   Realmdupdate
         ;;
	 
     	 6) clear;
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
