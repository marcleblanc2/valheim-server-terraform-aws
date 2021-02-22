#!/bin/bash


### START BOOTSTRAP ###

# Define echo function to print log lines with date time stamp, and colour
echo_msg () {

    echo ""
    echo -e "\e[92m $(date '+%F %T %z %Z') --- $1 \e[0m"

}

# Configure script to log console output to a log file
exec > >(tee -ia /var/log/valheim-server-terraform-bootstrap.log)
exec 2>&1

# Write start to log
echo_msg "Starting `dirname "$0"`/`basename "$0"` from `pwd`"

# Update packages
echo_msg "sudo yum update -y to update packages in the Amazon Linux 2 image"
sudo yum update -y

# Ping to validate internet connectivity
echo_msg "ping -c 3 -W 3 google.com to validate internet connectivity"
ping -c 3 -W 3 google.com


### START APP INSTALLATION AND CONFIGURATION ###

# Install pre-requisites for Steam
echo_msg "sudo yum install -y glibc.i686 libstdc++.i686 to install Steam pre-requisites"
sudo yum install -y glibc.i686 libstdc++.i686

# # Create Valheim server service account
# # Not sure about assigning a password to a service user account on Amazon Linux 2
# echo_msg "sudo adduser -m svc_valheim to create a new service user"
# sudo adduser -m svc_valheim # -p ${valheim-server-service-account-password}

# echo_msg "cat /etc/passwd | grep svc_valheim to show the new service user was created"
# cat /etc/passwd | grep svc_valheim

# # Switch to the new user
# echo_msg "sudo su - svc_valheim to switch user contexts to the service account"
# sudo -u svc_valheim whoami

# # Verify that we are the new user
# echo_msg "whoami to verify we are the service account"
# whoami
 
# # Move to the home directory to keep files clean
# # echo_msg "sudo cd /home/svc_valheim to switch to the service account's home dir"
# # sudo cd /home/svc_valheim

# echo_msg "pwd and ls -hal to show that we're in /home/svc_valheim"
# pwd
# ls -hal

sudo mkdir /steam

# Install Steam
echo_msg "wget -P /steam http://media.steampowered.com/installer/steamcmd_linux.tar.gz to download steamcmd"
wget -P /steam http://media.steampowered.com/installer/steamcmd_linux.tar.gz

echo_msg "ls -hAl /steam to show that steamcmd_linux.tar.gz has been downloaded"
ls -hAl /steam

echo_msg "tar -xvzf steamcmd_linux.tar.gz to unpack steamcmd"
tar -xvzf /steam/steamcmd_linux.tar.gz -C /steam

echo_msg "ls -hAl /steam to show that steamcmd_linux.tar.gz has been extracted"
ls -hAl /steam

echo_msg "/steam/steamcmd.sh +quit to install and update steamcmd"
/steam/steamcmd.sh +quit
# Exited with main.cpp (316) : Assertion Failed: Couldn't chdir into the install path
# Might need to be run by sudo, or switch user context to the user that owns it

# Install Valheim server
echo_msg "/steam/steamcmd.sh +login anonymous +force_install_dir ./valheim +app_update 896660 +quit to install the Valheim server"
/steam/steamcmd.sh +login anonymous +force_install_dir ./valheim +app_update 896660 +quit

# Start the Valheim server, in the background
echo_msg "bash /steam/valheim/start_server.sh & to start the Valheim server in the background"
cd /steam/valheim
bash start_server.sh -name $valheim-server-display-name -port 2456 -nographics -batchmode -world $valheim-server-world-name -password $valheim-server-world-password -public $valheim-server-public &

# # Exit the svc_valheim user context
# echo_msg "exit to exit the service user context"
# exit

# Copy Valheim server world files?
# s3 cp

# Create a crontab to back up the Valheim server world files to S3

# # Enable service to start after reboots
# echo_msg "systemctl enable valheimserver to enable the service to run in the background"
# systemctl enable valheimserver

# # Check service status
# echo_msg "systemctl status valheimserver.service to show the service status"
# systemctl status valheimserver.service

# Reboot to finish installing updates
# echo_msg "sudo needs-restarting -r || sudo shutdown -r now to reboot if needed for patches"
# sudo needs-restarting -r || sudo shutdown -r now
