# Linux-Active-Directory-join-script
This is a script for Active Directory join for Ubuntu 14, 16, Debian, CentOS, and Raspberry Pi Raspbian with realmd.

Complete steps


1. remembert to set a good hostname on the computer/server the AD will set computer object itself named after the hostname of the machine = "linuxcomputer" as example
2. At this point you have 2 options. you already have a Group i AD example:"ADMINS" then you need to edit /etc/sudoers.d/sudoers
and add   %ADMINS ALL(ALL:ALL) ALL if you want to give this group sudo rights.

Or if you want to manage sudo users by a new group then create a group name LINUXCOMPUTERsudoers (same as hostname) in AD, the script will allow you to choose if you want users to be sudoers or not.
3. set hostname on you computer to "linuxcomputer" (hostname and hosts files) and reboot
4. git clone this script and run.

execute the script with sudo sh ADconnection.sh, It will detect if it is a client or a server, it will also detect if client is running ubuntu 14,16 or 17
the script will find your domain name if existing, if now a promt will let you type the domain name. "domain.com"
after that authorise with a admin user.
make sure to read the questions carefully and also read built in help in the script.

For security this script creates an ssh allow file so users that are not in the correct AD group can't login,
NOTICE! if your local user is not administrator you MUST edit and add current local user in the ssh-allow section.
If you current local user is not in the SSH-ALLOW file it will be BANNED from the computer!

Updated. :Added the ability to choose if you want to dissable SSH-allow,
note: if ssh is disabled users in other groups will be able to ssh to the client, but will not have sudo rights.

Updated. :
also the ability to choose if clients should have sudo rights or not ( clients will be sudo by default )
if you seclect no on this option there i no need for an AD group "LINUXCOMPUTERsudoers" in active directory, all domain users
will have nonsudo  access. "notice this option can not be combined with the option YES on ssh-allow"

Updates:
added join to ubuntu clients with debug mode. 
debugmode will open 2 terminals and will post information while you run the script.


This will make the cleanest setup possible. no @ in names or in home folder
home folder will be /home/domain.com/you
User name will be only set as "you" without /myad/you or you@domain.com just clean. this is to prevent complications for developers when building code
After reboot just login with you AD account "you" and password... again.. no @ or / is needed, just "user"
to test access of a user execute in terminal from administrator account: id user

For best security. I restricted ssh to domain and administrator users.
also clients will only allow login from assigned group ( "LINUXCOMPUTERsudoers" )


How do i update my password?
( changed password but Linux is still on old password ) 
First time you login your "user" caches on the computer ( means that you can login beeing disconected to "office network"
to update the password. On office network.. open a terminal and execute sudo service sssd restart, this will reload information.

I have issues!

1. After reboot I cant log in at all.  "This is problably caused by failed SSH-allow configuration, make sure to have correct users in the configuration or disable SSH-allow when running the script" 

2. I rebooted the computer but i till can not login with the AD user!   "did you wait 3 to 5 min for AD to sync? 
Login with your local account and execute in terminal " sudo sssd service restart   and the try to see if you can see the user by executing id youADusername, if you can see the user then it works.

3. Damn i got the wrong hostname and its not a computerobject in AD   "Login with local admin and change your hostname to this files so it matches computerobject in AD /etc/sudoers.d/sudoes (if configured)    /etc/ssh/login.group.allowed (if configured)   /etc/hostname  /etc/hosts
then run sudo realm leave domain.domain reboot and rejoin executing realm join -v -U ADdamin domain.com
reboot and wait 5 min before login

If you have issues with slow replies from the domain controller i have added lines to nsswitch an sssd to prevent hangs, slow logins and slow repy from sudo commands in a teminal.

