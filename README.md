# Linux-Active-Directory-join-script
This is a script for Active Directory join for Ubuntu 14, 16 and debian with realmd.

Complete steps


1. create computer object in AD lets say the name is= linuxcomputer as example
2. create a group name LINUXCOMPUTERsudoers ( if you wish to remove sudoers you must edit script )
3. set hostname on you computer to linuxcomputer (hostname and hosts files) and reboot
4. git clone this script and run.

execute the script with sudo sh ADconnection.sh, It will detect if it is a client or a server.
the script will find your domain name if existing
after that authorise with a admin user.
make sure to read carefully and also read built in help in the script.

For security this script creates an ssh allow file so users that are not in the correct AD group can login,
NOTICE! if your user is not administrator you MUST edit annd add current user in the ssh-allow section.
If you current local user is not in the SSH-ALLOW file it will be BANNED from the computer!

WORK IN PROGRESS. : I will add the ability to choose if you want to dissable SSH-allow,
note: users in other groups will be able to ssh to the client, but will not have sudo rights.

WORK IN PROGRESS. :
also the ability to choose if clients should have sudo rights or not ( clients will be sudo by default )

this will make the cleanest setup possible. no @ in names or in home folder
home folder will be /home/myad.intra/you
User name will be only set as "you" without /myad/you or you@myad.intra. just clean. this is to prevent complications for developers when building code
after reboot just login with you AD acoount "you" and password... again.. no @ or / is needed, just "user"

For best security. I restricted ssh to domain and administrator users.
also clients will only allow login from assigned group ( hostnamesudoers )
