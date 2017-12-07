# Linux-Active-Directory-join-script
This is a script for Active Directory join for Ubuntu 14, 16,17, Debian, CentOS, and Raspberry Pi Raspbian with realmd.
and is a result of al lot of small upgrades according as needs emerged.

Complete steps

1. remember to set a hostname on the client or server, the AD will set computer object itself named after the hostname of the machine = "linuxcomputer" as example
2. At this point you have 2 options. you already have a Group i AD example:"ADMINS" here you have your users with sudo rights. then you need to edit /etc/sudoers.d/sudoers
and add   %ADMINS ALL(ALL:ALL) ALL if you want to give this group sudo rights.
and also /etc/ssh/login.allow if you have selected this option for security.

Or if you want to manage sudo users by a new group then create a group name LINUXCOMPUTERsudoers (same as hostname) in AD, in this step you dont need to edit files, the script will allow you to choose if you want users to be sudoers or not.
3. set hostname on you computer to "linuxcomputer" (hostname and hosts files) and reboot
4. git clone this script and run.

execute the script with sudo sh ADconnection.sh, It will detect if it is a client or a server, it will also detect if client is running ubuntu 14,16 or 17
the script will find your domain name if existing, and your networkconfig is correct.. if not a promt will let you type the domain name. "domain.com"
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

I have issues!

1. After reboot I cant login at all. (local or AD)  "This is problably caused by failed SSH-allow configuration, make sure to have correct users in the configuration or disable SSH-allow when running the script" 

2. I rebooted the computer but i till can not login with the AD user!   "did you wait 3 to 5 min for AD to sync?
check that the computer object is created in the AD
Login with your local account and execute in terminal " sudo sssd service restart   and the try to see if you can see the user by executing id yourADusername, if you can see the user then it works. if you have it set up with an ADgroup then you can execute: 
id yourADusername | grep -i LINUXCOMPUTERsudoers (the groupname or hostname depending on you setup)

3. Damn i got the wrong hostname and its not a computerobject in AD   "Login with local admin and change your hostname to this files so it matches computerobject in AD /etc/sudoers.d/sudoes (if configured)    /etc/ssh/login.group.allowed (if configured)   /etc/hostname  and /etc/hosts
then run sudo realm leave domain.com reboot and rejoin running the script again, the script will not override files if they have been configured before.
reboot and wait 5 min before login

If you have issues with slow replies from the domain controller i have added lines to nsswitch an sssd to prevent hangs, slow logins and slow repy from sudo commands in a teminal. this was added 2017/11 so if you have and older "join" than 2017/11 you should do a rejoin.

