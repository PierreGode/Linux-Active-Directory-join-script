# Linux-Active-Directory-join-script By Pierre 2017-2021

New: Added support for readfile for Ubuntu.

   : removed line failing SASL config and blocking user to update password.: investigation started 03/11
   : For users beeing unable to update password please do a git pull and run option 4: Reauthenticate to fix.

Supported OS's: Ubuntu 14-20 + mate, Debian ,Cent OS,Rasbian ,Fedora, Linux Mint, Kali and Elemantary OS

Added support to Perform a SASL (Negotiate/Kerberos/NTLM/Digest) LDAP bind with request signing (integrity verification) on-SSL-encrypted) LDAP connection. see more in wiki.

This is a script for Active Directory join with realmd.
and is a result of a lot of small upgrades according as needs has emerged.

<p>Also see<a href="https://github.com/PierreGode/Linux-Active-Directory-join-script/wiki"> Wiki</a></p>

<p>Future development:</p> 
<p>I will add support for an (answer file) in early 2020 in progress 2020-02-13</p> 

<p>Major rework of the script will be made during 2020 right now it is very messy but working, (a lot of parts that are uneccessary repeated in the script</p>



<H4>But why a script?</H4>
<p>Joining to a domain is fairly easy, but then you have all the configuration around it to get everything to work
as you expect, like: </p>
<p>Getting an "empty login prompt for new ADusers" at the login promt</p>
<p>Setting sudo permissions</p>
<p>Settings for mobile account in sam</p>
<p>Better security with ssh login allowence</p>
<p>Additional configuration to sssd.conf</p>
<p>this script allows you to join a domain very easly just awnsering a couple of questions</p>
<p>. It autodetects 7 different distros</p>
<p>. It autodetects your domain</p>
<p>. It generates and/or edit nessesery files</p>
<p>built in failcheck</p>

<H4>What is the setup then?</H4>
computer objct = HOSTNAME .
sudo group = HOSTNAMEsudoers = ADgroup

update: Added flag options no minimize the menu and add logging: see sudo sh ADconnection.sh --help
Usage: sh ADconnection.sh [--help] [-d (ubuntu debug mode)]
                          [-j admin domain (Simple direct join)
                          [-l (script output to log file)]
                          [-s (Discover domain)]
                          
                          

Usage of the script: sudo sh ADconnection.sh or sudo ./ADconnection.sh
for ./ADconnection.sh do a sudo chmod +x ADconnection.sh first.

Complete steps

1. remember to set a hostname on the client or server, the AD will set computer object itself named after the hostname of the machine = "linuxcomputer" as example

2. At this point you have 2 options. you already have a Group i AD example:"ADMINS" here you have your users with sudo rights. then you need to edit /etc/sudoers.d/sudoers
and add   %ADMINS ALL(ALL:ALL) ALL if you want to give this group sudo rights.
In this script there is a magic word added for groups in AD and it is sudoers, it always adds sudoers after hostname, like linuxcomputersudoers
administrator will always be added to sudoers as a failsafe for sysadmins.

and also /etc/ssh/login.allow if you have selected this option for security.

Or if you want to manage sudo users by a new group then create a group name LINUXCOMPUTERsudoers and LINUXCOMPUTER as hostname, they are not related, but Computer object in AD will be created and named after hostname and naming the ADgroup simmilar makes search easier in the future, therefore the script by defaut will add "LINUXCOMPUTERsudoers" as default in sudoers.d/sudoers, in this step you don't need to edit files, the script will allow you to choose if you want users to be sudoers or not and if yes the script will autogenerate "LINUXCOMPUTERsudoers" in sudoers
.
3. set hostname on you computer to "linuxcomputer" (hostname and hosts files) and reboot 
( in/etc/hosts it should look like 127.0.1.1       LINUXCOMPUTER01       LINUXCOMPUTER01.domain.com also in resolv.conf you should have search domain.com)

4. git clone this script and run

Execute the script with sudo sh ADconnection.sh, It will detect if it is a client or a server, it will also detect if client is running ubuntu 14,16,17, 18, 19,20, mate,Debian ,Cent OS,Rasbian ,Fedora, Linux Mint or Kali
the script will find your domain name if existing, and your networkconfig is correct.. if not a promt will let you type the domain name. "domain.com"
If there are issues finding the domain please dubblecheck your dns configuration on the domain controller.

after that authorise with a admin user.
make sure to read the questions carefully and also read built in help in the script.

For security this script creates an ssh allow file so users that are not in the correct AD group can't login,
this also "blocks" users from creating local accounts ( they can create them if the are sudoers, but will never be able to login)
NOTICE! if your local user is not administrator you MUST edit and add current local user in the  (/etc/ssh/login.group.allowed) file.
If you current local user is not in the SSH-ALLOW file it will be BANNED from the computer!

Updated. :Added the ability to choose if you want to dissable SSH-allow,
note: if ssh is disabled users in other groups will be able to ssh to the client, but will not have sudo rights if they are not members in the group LINUXCOMPUTERsudoers

Updated. :
also the ability to choose if clients should have sudo rights or not.
if you seclect no on this option there is no need for an AD group "LINUXCOMPUTERsudoers" in active directory, all domain users
will have nonsudo access. "notice this option can NOT be combined with the option YES on ssh-allow"

Updates:
added join to ubuntu clients with debug mode. 
debugmode will open 2 terminals and will post information while you run the script.
(does not work over SSH)

Comming updates: the option to paste a path for a correct OU were the machine will me setup. ( the defoult OU is CN=Computers,DC=domain,DC=com ) (still in progress)
Comming updates: Option to rejoin ( leave realm and join realm and keep all configuration )


This will make the cleanest setup possible. no @ in names or in home folder
home folder will be /home/domain.com/user
User name will be only set as "user" without /myad/you or you@domain.com... just clean!. this is to prevent complications for developers when building code
After reboot just login with you AD account "user" and password... again.. no @ or domain.com/user is needed, just "user"
to test access and permissions of a user execute in terminal from administrator account: id user or id user | grep -i groupname (LINUXCOMPUTERsudoers)

For best security. I restricted ssh to only domainadmins and local administrator, also clients will be allowed to login from assigned group ( "LINUXCOMPUTERsudoers" ) (with option YES on SSH-allow) (with option YES on sudo rights )


How do i update my password?
( changed password but Linux is still on old password ) 
This should read new info from AD when you are on "AD" network
First time you login your "user" caches on the computer ( means that you can login beeing disconected to "office network"
If you are having problems with the computer not fetching the new password. On office network.. open a terminal and execute sudo service sssd restart, this will reload information, logout and login with the new password.

##I have issues!

1. After reboot I cant login at all. (local or AD)  
"This is problably caused by failed SSH-allow configuration, make sure to have correct users in the configuration or disable SSH-allow when running the script" 

2. I rebooted the computer but i still can not login with the AD user!   
"did you wait 5 min for AD to sync?
check that the computer object is created in the AD
Login with your local account and execute in terminal " sudo sssd service restart   and the try to see if you can see the user by executing id yourADusername, if you can see the user and all the groups the user is member of in AD then it works. if you have it set up with an ADgroup then you can execute: 
id yourADusername | grep -i LINUXCOMPUTERsudoers (the groupname or hostname depending on you setup)

3. Damn i got the wrong hostname and its not created as a computerobject in AD   
"Login with local admin and change your hostname to this files so it matches groupobject in AD /etc/sudoers.d/sudoes (if configured)    /etc/ssh/login.group.allowed (if configured)   /etc/hostname  and /etc/hosts
then run sudo realm leave domain.com reboot and rejoin running the script again, the script will not override files if they have been configured before.
If the computerobject is existing in AD but you wish to replace it, just delete the computerobject and join/rejoin with computer/server with the same hostname as the computerobject.
reboot and wait 5 min before login

If you have issues with slow replies from the domain controller i have added lines to nsswitch an sssd to prevent hangs, slow logins and slow repy from sudo commands in a teminal. this was added 2017/11 so if you have and older "join" than 2017/11 you should do a rejoin.

4. I am a member of sudores but programs require administrator to login..
you are sudo user if added to sudoes file, but the account is a standard account. to give full administration priviligies
run in terminal: sudo usermod -a -G sudo user


<p>Encrypted Password?:</p>
I have added the option for readfie and also a way to encrypt ADadmin password for those that don´t want to use one-time passwords.
sudo sh ADconnection.sh -p will promt you for a password that will be encrypted. pubic key, privat.key and a encrypted.dat files will be generated. find a way to store a least your private key and only place them in Linux-Active-Directory-join-script folder during join.


Note. make sure dns works so it can properly find ldap server
If you are using multiple domain servers or have a backup domain server, see example below
[sssd]
services = nss, pam
config_file_version = 2
domains = ad.example.com

[domain/ad.example.com]
id_provider = ad
auth_provider = ad
access_provider = ad
chpass_provider = ad
ad_server = dc1.ad.example.com
ad_backup_server = dc2.ad.example.com
filter_users = root at ad.example.com
filter_groups = root at ad.example.com
ldap_id_mapping = false
dyndns_update = true
dyndns_update_ptr = false
enumerate = true
subdomain_enumerate = all
cache_credentials = true

How to change AD password in linux (ubuntu example): open settings, users click on password field, set new password.

How to git?

On linux client install git = sudo apt-get install git -y (or) sudo yum install git

Clone this repo = sudo git clone https://github.com/PierreGode/Linux-Active-Directory-join-script.git

To update repo to latest version = in the folder Linux-Active-Directory-join-script/    run: sudo git pull
