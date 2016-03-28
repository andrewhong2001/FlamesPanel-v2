# FlamesPanel v2 Source Code

Installing FlamesPanel is simple - all you have to do id execute the following:

    wget https://github.com/FlamesRunner/FlamesPanel-v2/blob/master/installers/installer.sh
    sh installer.sh

---

#Preliminary notes

Once you've installed FlamesPanel, there are a few things you need to know.
First off, FlamesPanel assumes your main filesystem is located at /dev/sda1.
If you're using OpenVZ, you need to have second-level quotas enabled and then change the files listed below to reflect the root filesystem.

     /sbin/modifyaccount
     /sbin/www-createacct

Open those files and change `/dev/sda1` to your filesystem.

---

#Command-line utilities

FlamesPanel comes with many command-line tools to manage users, along with the administration panel.
This file will only cover a few of the most critical utilities, though.

##/sbin/www-createacct (create an account)

Description: Create an account with the specified username and password.

Syntax:
   
     /sbin/www-createacct username password

##/sbin/changepassword (change the password of an account)

Description: Change the password of the specified user.

Syntax:

     /sbin/changepassword username newpassword

##/sbin/suspenduser (suspend user)

Description: Prevent a user from logging in and disable account.

Syntax:

     /sbin/suspenduser username

##/sbin/unsuspenduser (unsuspend user)

Description: Revoke suspension and grant privileges to login again

Syntax:

     /sbin/unsuspenduser username

##/sbin/killacct (terminate account, use with caution)

Description: Destroy account

Syntax:

     /sbin/killacct username

##/sbin/modifyaccount (modify account quota, etc)

Description: Modify an account's quota, inode limit, etc

Syntax:

     /sbin/modifyaccount action parameters

Actions currently implemented: modifyquota

Usage of action `modifyquota`:

     /sbin/modifyaccount modifyquota username newquota newinodelimit

---

#Bugs & Issues

If there are any problems with FlamesPanel, please submit an issue ticket and I'll get on fixing it.
Know how to fix it yourself? Write a fix for it and push it (I'll leave your name here as a credit for assisting).

#Project website

It's located here: https://andrew-hong.me/welcome/projects.php

#Contributers

Andrew H. (current developer of FlamesPanel)

