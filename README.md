# Linux-Active-Directory-join-script
This is a script for Active Directory join for Ubuntu 14, 16, Debian, CentOS, and Raspberry Pi Raspbian with realmd.

Complete steps


1. create computer object in AD lets say the name is= linuxcomputer as example
2. create a group name LINUXCOMPUTERsudoers in AD ( if you wish to remove sudoers you must edit script )
3. set hostname on you computer to linuxcomputer (hostname and hosts files) and reboot
4. git clone this script and run.

execute the script with sudo sh ADconnection.sh, It will detect if it is a client or a server.
the script will find your domain name if existing
after that authorise with a admin user.
make sure to read carefully and also read built in help in the script.

For security this script creates an ssh allow file so users that are not in the correct AD group can login,
NOTICE! if your user is not administrator you MUST edit annd add current user in the ssh-allow section.
If you current local user is not in the SSH-ALLOW file it will be BANNED from the computer!

Updated. : I will add the ability to choose if you want to dissable SSH-allow,
note: users in other groups will be able to ssh to the client, but will not have sudo rights.

Updated. :
also the ability to choose if clients should have sudo rights or not ( clients will be sudo by default )

this will make the cleanest setup possible. no @ in names or in home folder
home folder will be /home/myad.intra/you
User name will be only set as "you" without /myad/you or you@myad.intra. just clean. this is to prevent complications for developers when building code
after reboot just login with you AD account "you" and password... again.. no @ or / is needed, just "user"

For best security. I restricted ssh to domain and administrator users.
also clients will only allow login from assigned group ( hostnamesudoers )

How do i update my password?
( changed password but Linux is still on old password ) 
First time you login your "user" caches on the computer ( means that you can login beeing disconected to "office network"
to update the password, on office network.. open a terminal and execute sudo service sssd restart.

I have issues!

1. After reboot I cant log in at all.  "This is problably caused by failed SSH-allow configuration, make sure to have correct users in the configuration or disable SSH-allow when running the script" 

2. I rebooted the computer but i till can not login with the AD user!   "did you wait 3 to 5 min for AD to sync? 
Login with your local account and execute in terminal " sudo sssd service restart   and the try to see if you can see the user by executing id youADusername, if you can see the user then it works.

3. Damn i got the wrong hostname and its not a computerobject in AD   "Login with local admin and change your hostname to this files so it matches computerobject in AD /etc/sudoers.d/sudoes (if configured)    /etc/ssh/login.group.allowed (if configured)   /etc/hostname  /etc/hosts
then run sudo realm leave domain.domain reboot and rejoin executing realm join -v -U ADdamin domain.doamn
reboot and wait 5 min before login


