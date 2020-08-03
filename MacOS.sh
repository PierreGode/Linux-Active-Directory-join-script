#this is a very simple scipt to automate MacOS AD join
#Note that Apple is going away from AD
#Recomended solution is Nomad https://nomad.menu/products/#nomad
echo "this script needs to be configured to funktion"
echo "if you already did it then edit this file and uncomment row 6 with a # in the beginning"
exit
# to automate ADjoin check the variables below and find a solution to get from you AD or just type the name of next object in list "next computer object"

DOMAIN=$(test.com)	    		## Domain
admin=$(admin)			      	## AD admin
pass=$(password)		      	## AD admin pass
adgroup=$(whatevergroup)    ## this is to give admin privileges to a group in the active directory ex: MacAdmins
ADcomputer=$(MACagent01 )			      	## desired computer object name ( this will only be the name of the computer object in Active Directory, hostname is still the same as default)
OU=$(OU=Computers Mac,DC=domain,DC=com)					          	## desired OU were the computer object is created

sudo dsconfigad -add $DOMAIN -mobile enable -mobileconfirm disable -localhome enable -protocol smb -shell '/bin/bash' -username $admin -password $pass -groups $adgroup -computer $ADcomputer -ou $OU
sudo dsconfig -show
