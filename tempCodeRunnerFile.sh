echo Checking sudoers file..  "${INTRO_TEXT}OK${END}"
grouPs=$(grep -i "$myhost" /etc/sudoers.d/sudoers | cut -d '%' -f2 | cut -d  '=' -f1 | sed -e 's/\<ALL\>//g')
     if [ $grouPs = "$myhost""sudoers" ]
         then
         echo Checking sudoers users.. "${INTRO_TEXT}OK${END}"
         else
         echo Checking sudoers users.. "${RED_TEXT}FAIL${END}"
         fi