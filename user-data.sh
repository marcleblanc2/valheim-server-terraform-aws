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
echo_msg "$(date -Iseconds) - Starting `dirname "$0"`/`basename "$0"` from `pwd`"

# Update packages
echo_msg "$(date -Iseconds) - sudo yum update -y to update packages in the Amazon Linux 2 image"
sudo yum update -y

# Ping to validate internet connectivity
echo_msg "$(date -Iseconds) - ping -c 3 -W 3 google.com to validate internet connectivity"
ping -c 3 -W 3 google.com


### START APP INSTALLATION AND CONFIGURATION ###

# Install pre-requisites for Steam
echo_msg "$(date -Iseconds) - sudo yum install -y glibc.i686 libstdc++.i686 to install Steam pre-requisites"
sudo yum install -y glibc.i686 libstdc++.i686

# Create Valheim server service account
# Not sure about assigning a password to a service user account on Amazon Linux 2
echo_msg "$(date -Iseconds) - sudo adduser -m svc_valheim to create a new service user"
sudo adduser -m svc_valheim # -p ${valheim-server-service-account-password}

echo_msg "$(date -Iseconds) - cat /etc/passwd | grep svc_valheim to show the new service user was created"
cat /etc/passwd | grep svc_valheim

# Switch to the new user?
# echo_msg "$(date -Iseconds) - sudo su - svc_valheim to switch user contexts to the service account"
# sudo su - svc_valheim
 
# Move to the home directory to keep files clean
echo_msg "$(date -Iseconds) - sudo cd /home/svc_valheim to switch to the service account's home dir"
sudo cd /home/svc_valheim

# Install Steam
echo_msg "$(date -Iseconds) - wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz to download steamcmd"
wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz
echo_msg "$(date -Iseconds) - tar -xvzf steamcmd_linux.tar.gz to unpack steamcmd"
tar -xvzf steamcmd_linux.tar.gz
echo_msg "$(date -Iseconds) - ./steamcmd.sh +quit to install and update steamcmd"
./steamcmd.sh +quit

# Install Valheim server
echo_msg "$(date -Iseconds) - ./steamcmd.sh +login anonymous +force_install_dir ./valheim +app_update 896660 +quit to install the Valheim server"
./steamcmd.sh +login anonymous +force_install_dir ./valheim +app_update 896660 +quit

# Modify the server config file
echo_msg "$(date -Iseconds) - Modify the Valheim server config file"
echo_msg "valheim-server-display-name = ${valheim-server-display-name}"
echo_msg "valheim-server-world-name = ${valheim-server-world-name}"
echo_msg "valheim-server-world-password = ${valheim-server-world-password}"

# Start the Valheim server, in the background
echo_msg "$(date -Iseconds) - bash ./valheim/start_server.sh & to start the Valheim server in the background"
bash ./valheim/start_server.sh &

# Exit the svc_valheim user context
# echo_msg "$(date -Iseconds) - exit to exit the service user context"
# exit

# Copy Valheim server world files?
# s3 cp

# Create a crontab to back up the Valheim server world files to S3

# # Enable service to start after reboots
# echo_msg "$(date -Iseconds) - systemctl enable valheimserver to enable the service to run in the background"
# systemctl enable valheimserver

# # Check service status
# echo_msg "$(date -Iseconds) - systemctl status valheimserver.service to show the service status"
# systemctl status valheimserver.service

# Reboot to finish installing updates
echo_msg "$(date -Iseconds) - sudo needs-restarting -r || sudo shutdown -r to reboot if needed for patches"
sudo needs-restarting -r || sudo shutdown -r
