# Linux-Active-Directory-join-script
This is a script for Active Directory join for Ubuntu 14, 16 and debian with realmd.

Complete steps
1. create computer object in AD lets say the name is= linuxcomputer as example
2. create a group name LINUXCOMPUTERsudoers ( if you wish to remove sudoers you must edit script )
3. set hostname on you computer to linuxcomputer (hostname and hosts files) and reboot
4. git clone this script and run.

execute the script with sudo sh scriptexmple.sh, then choose if client or server.
then type yot doamin at promt ex: myad.intra, next your netbios at promt ex: myad
after that authorise with a admin user.
make sure to read carefully and also read built in help in the script.

this will make the cleanest setup possible. no @ in names or in home folder
home folder will be /home/myad.intra/you
User name will be only set as "you" without /myad/you or you@myad.intra. just clean. this is to prevent complications for developers when building code
after reboot just login with you AD acoount "you" and password... again.. no @ or / is needed, just "user"
