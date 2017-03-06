 #!/bin/bash
#####################################################################################################################
#                                                                                                                   #
#                              This script is written by Pierre Goude                                               #
#  This program is open source; you can redistribute it and/or modify it under the terms of the GNU General Public  #
#                     This is an normal bash script and can be executed with sh                                     #
# Generic user setup is: administrator, domain admins, groupnamesudores= groupname=hostname + sudoers on groupname  #
#####################################################################################################################

#known bugs: see line 23-24

# ~~~~~~~~~~  Environment Setup ~~~~~~~~~~ #
    NORMAL=`echo "\033[m"`
    MENU=`echo "\033[36m"` #Blue
    NUMBER=`echo "\033[33m"` #yellow
    RED_TEXT=`echo "\033[31m"` #Red
    INTRO_TEXT=`echo "\033[32m"` #green and white text
    END=`echo "\033[0m"`
# ~~~~~~~~~~  Environment Setup ~~~~~~~~~~ #

################################ fix errors # funktion not called ################
fixerrors(){
#this funktion is not called in the script : to activate, uncomment line line 459 #fixerrors
#This funktion installs additional pakages due to known issues with Joining and the join hangs after the admin login
sudo add-apt-repository ppa:xtrusia/packagekit-fix
sudo apt-get update
sudo apt-get install packagekit
}

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
fi
discovery=$(realm discover $DOMAIN | grep domain-name)
NetBios=$(echo $DOMAIN | cut -d '.' -f1)
echo "${INTRO_TEXT}"Please type Admin user"${END}"
read ADMIN
clear
sudo echo "${INTRO_TEXT}"Realm= $discovery"${INTRO_TEXT}"
sudo echo "${NORMAL}${NORMAL}"
var=$(lsb_release -a | grep -i release: | cut -d ':' -f2 | cut -d '.' -f1)
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
clear
echo "Having issuers to detect your Ubuntu version"
exit
fi
fi
if [ $? -ne 0 ]; then
	echo "${RED_TEXT}"AD join failed.please check that computer object is already created and test again "${END}"
    exit 1
fi
sudo echo "############################"
sudo echo "Configuratig files.."
sudo echo "Verifying the setup"
sudo systemctl enable sssd
sudo systemctl start sssd
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" >> /etc/pam.d/common-session
echo "auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/ssh/login.group.allowed" >> /etc/pam.d/common-auth
sudo sh -c "echo 'greeter-show-manual-login=true' >> /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
sudo sh -c "echo 'allow-guest=false' >> /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
sudo touch /etc/ssh/login.group.allowed
sudo echo "administrator" >> /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"$myhost""sudoers" >> /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"domain^admins" >> /etc/ssh/login.group.allowed
sudo echo "administrator ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/sudoers
sudo echo "%domain^admins ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/sudoers
sudo echo "%$myhost""sudoers ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/sudoers
sudo echo "%DOMAIN\ admins@$DOMAIN ALL=(ALL) ALL" >> /etc/sudoers.d/domain_admins
#sudo realm permit --groups "$myhost""sudoers"
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
exec sudo -u root /bin/sh - <<eof
sed -i -e 's/fallback_homedir = \/home\/%u@%d/#fallback_homedir = \/home\/%u@%d/g' /etc/sssd/sssd.conf
sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
echo "override_homedir = /home/%d/%u" >> /etc/sssd/sssd.conf
eof
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
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" >> /etc/pam.d/common-session
sudo echo "administrator ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/sudoers
sudo echo "%domain^admins ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/sudoers
sudo echo "%$myhost""sudoers ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/sudoers
sudo echo "%DOMAIN\ admins@$DOMAIN ALL=(ALL) ALL" >> /etc/sudoers.d/domain_admins
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
echo "${INTRO_TEXT}It can take up to 5 minutes until AD sincronizes and you can log in..${INTRO_TEXT}"
echo "${INTRO_TEXT}If you sudoers group in not hostname but a custom group, pleace replace hostname with correct groupname in /etc/sudoers.d/sudores${INTRO_TEXT}"
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
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" >> /etc/pam.d/common-session
echo "auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/ssh/login.group.allowed" >> /etc/pam.d/common-auth
sudo echo "$UseR"" ALL=(ALL:ALL) ALL" >> /etc/sudoers
sudo echo "$NetBios"'\'"$UseR" >> /etc/ssh/login.group.allowed
sudo echo "$NetBios"'\'"$myhost""sudoers" >> /etc/ssh/login.group.allowed
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
cauth=$(cat /etc/pam.d/common-auth | grep required | grep onerr | grep allow | cut -d '=' -f4 | cut -d 'f' -f1)
if [ $cauth = allow ]
then
echo Checking PAM auth configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM auth configuration.. "${RED_TEXT}"FAIL"${END}"
fi
exit
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

#fixerrors
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
    echo "${MENU}*${NUMBER} 4)${MENU} Check for errors                 ${NORMAL}"
	echo "${MENU}*${NUMBER} 5)${MENU} Reauthenticate (Ubuntu14 only)   ${NORMAL}"
	echo "${MENU}*${NUMBER} 6)${MENU} Update from Likewise to Realmd for Ubuntu 14 ${NORMAL}"
	echo "${MENU}*${NUMBER} 7)${MENU} README with examples             ${NORMAL}"
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
	     echo "Check for errors"
	     failcheck
             ;;
	 
	5) clear;
	    echo "Reauthenticate realmd for Ubuntu 14"
	    Reauthenticate14
            ;;

     	 6) clear;
     	   echo "Update from Likewise to Realmd"
 	   Realmdupdate
           ;;
	 
     	 7) clear;
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
