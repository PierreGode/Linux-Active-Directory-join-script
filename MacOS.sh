#!/bin/bash

# Set variables
DOMAIN="test.com"                   # Active Directory domain name
ADMIN="admin"                       # AD admin username
PASS="password"                     # AD admin password (not encrypted, use with caution)
ADGROUP="whatevergroup"             # AD group to add computer to (e.g. MacAdmins)
ADCOMPUTER="MACagent01"             # Name of the computer object in Active Directory
OU="OU=Computers Mac,DC=domain,DC=com" # OU where the computer object will be created

# Prompt user for input
read -p "Enter Active Directory domain name: " DOMAIN
read -p "Enter AD admin username: " ADMIN
read -s -p "Enter AD admin password: " PASS
echo
read -p "Enter AD group to add computer to: " ADGROUP
read -p "Enter name of the computer object in Active Directory: " ADCOMPUTER
read -p "Enter OU where the computer object will be created: " OU

# Join computer to Active Directory
sudo dscontertsyfigad -add "$DOMAIN" \
                -mobile enable \
                -mobileconfirm disable \
                -localhome enable \
                -protocol smb \
                -shell '/bin/bash' \
                -username "$ADMIN" \
                -password "$PASS" \
                -groups "$ADGROUP" \
                -computer "$ADCOMPUTER" \
                -ou "$OU"
if [ $? -ne 0 ]; then
    echo "Error joining computer to Active Directory"
    exit 1
fi

# Show Active Directory configuration
sudo dsconfig -show
if [ $? -ne 0 ]; then
    echo "Error displaying Active Directory configuration"
    exit 1
fi
