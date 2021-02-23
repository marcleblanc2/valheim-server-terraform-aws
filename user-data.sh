#!/bin/bash

steamPath="/home/svc_valheim/Steam"


### START BOOTSTRAP ###

# Define echo function to print log lines with date time stamp, and colour
echo_msg () {

    echo ""
    echo -e "\e[92m $(date '+%F %T %z %Z') --- $1 \e[0m"

}

# Configure script to log console output to a log file
# tail -f /var/log/valheim-server-terraform-bootstrap.log to monitor startup progress
exec > >(tee -ia /var/log/valheim-server-terraform-bootstrap.log)
exec 2>&1

# Write start to log
echo_msg "Starting `dirname "$0"`/`basename "$0"` from `pwd`"

# Append command aliases to .bashrc
echo_msg "Append command aliases to .bashrc"
echo_msg "cat /home/ec2-user/.bashrc to show the starting state"
cat /home/ec2-user/.bashrc

cat >> /home/ec2-user/.bashrc <<EOF
alias c='clear'
alias l='ls -hAl'
EOF

echo_msg "cat /home/ec2-user/.bashrc to verify the change"
cat /home/ec2-user/.bashrc

# Update packages
echo_msg "Update packages - sudo yum update -y"
sudo yum update -y

# Ping to validate internet connectivity
echo_msg "Ping to validate internet connectivity - ping -c 3 -W 3 google.com"
ping -c 3 -W 3 google.com


### START APP INSTALLATION AND CONFIGURATION ###

# Install pre-requisites for Steam
echo_msg "Install pre-requisites for Steam - sudo yum install -y glibc.i686 libstdc++.i686"
sudo yum install -y glibc.i686 libstdc++.i686

# Create Valheim service account
# Need to run commands with sudo -u svc_valheim to run them as the service user
echo_msg "Create Valheim service account - sudo useradd --system --user-group --shell /sbin/nologin --create-home svc_valheim"
sudo useradd --system --user-group --shell /sbin/nologin --create-home svc_valheim
echo_msg "Disable the service account from being able to log in - sudo usermod -L svc_valheim"
sudo usermod -L svc_valheim

# Verify the service account is usable
echo_msg "Verify the service account is usable - sudo -u svc_valheim whoami"
sudo -u svc_valheim whoami

# Make the Steam directory
echo_msg "Make the Steam directory - sudo -u svc_valheim mkdir $steamPath"
sudo -u svc_valheim mkdir $steamPath

# Show the Steam directory was made
echo_msg "Show the Steam directory was made - sudo -u svc_valheim ls -al $steamPath"
sudo -u svc_valheim ls -al $steamPath

# Download steamcmd
echo_msg "Download steamcmd - sudo -u svc_valheim wget -P $steamPath http://media.steampowered.com/installer/steamcmd_linux.tar.gz"
sudo -u svc_valheim wget -P $steamPath http://media.steampowered.com/installer/steamcmd_linux.tar.gz

# Untar steamcmd
echo_msg "Untar steamcmd - sudo -u svc_valheim tar -xvzf $steamPath/steamcmd_linux.tar.gz -C $steamPath"
sudo -u svc_valheim tar -xvzf $steamPath/steamcmd_linux.tar.gz -C $steamPath

# Show the untarred files
echo_msg "Show the untarred files - sudo -u svc_valheim ls -hAl $steamPath"
sudo -u svc_valheim ls -hAl $steamPath

# Install and update steamcmd
echo_msg "Install and update steamcmd - sudo -u svc_valheim $steamPath/steamcmd.sh +quit"
sudo -u svc_valheim $steamPath/steamcmd.sh +quit

# Install Valheim server
echo_msg "Install Valheim server - sudo -u svc_valheim $steamPath/steamcmd.sh +login anonymous +force_install_dir $steamPath/valheim +app_update 896660 validate +quit"
sudo -u svc_valheim $steamPath/steamcmd.sh +login anonymous +force_install_dir $steamPath/valheim +app_update 896660 validate +quit

# Create service log checking script
echo_msg "Create service log checking script"
sudo -u svc_valheim tee -a $steamPath/valheim/check_log.sh &>/dev/null <<EOF
#!/bin/bash
journalctl -a -o short-iso --no-pager --unit=valheim -f
EOF

# Show the service log checking script
echo_msg "Show the service log checking script - sudo -u svc_valheim cat $steamPath/valheim/check_log.sh"
sudo -u svc_valheim cat $steamPath/valheim/check_log.sh

# Make the check log script executable
echo_msg "Make the check log script executable - sudo chmod +x $steamPath/valheim/check_log.sh"
sudo chmod +x $steamPath/valheim/check_log.sh

# Show the service log checking script is executable
echo_msg "Show the service log checking script is executable - sudo -u svc_valheim ls -Al $steamPath/valheim/"
sudo -u svc_valheim ls -Al $steamPath/valheim/

# Create start_server_custom.sh
echo_msg "Create start_server_custom.sh - sudo -u svc_valheim tee -a $steamPath/valheim/start_server_custom.sh"
sudo -u svc_valheim tee -a $steamPath/valheim/start_server_custom.sh &>/dev/null <<EOF
#!/bin/bash
export templdpath=\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:\$LD_LIBRARY_PATH
export SteamAppId=892970

./valheim_server.x86_64 -name "\"${valheim-server-display-name}"\" -port 2456 -nographics -batchmode -world "\"${valheim-server-world-name}"\" -password "\"${valheim-server-world-password}"\" -public ${valheim-server-public}

export LD_LIBRARY_PATH=\$templdpath

EOF

# Show start_server_custom.sh
echo_msg "Show start_server_custom.sh - sudo -u svc_valheim cat $steamPath/valheim/start_server_custom.sh"
sudo -u svc_valheim cat $steamPath/valheim/start_server_custom.sh

# Make start_server_custom.sh executable
echo_msg "Make start_server_custom.sh executable - sudo chmod +x $steamPath/valheim/start_server_custom.sh"
sudo chmod +x $steamPath/valheim/start_server_custom.sh

# Show start_server_custom.sh is executable
echo_msg "Show tart_server_custom.sh is executable - sudo -u svc_valheim ls -Al $steamPath/valheim/"
sudo -u svc_valheim ls -Al $steamPath/valheim/

# Create a service to run start_server_custom.sh
echo_msg "Create a service to run start_server_custom.sh - cat > /etc/systemd/system/valheim.service"
cat > /etc/systemd/system/valheim.service <<EOF
[Unit]
Description=Valheim Server
Wants=network-online.target
After=syslog.target network.target nss-lookup.target network-online.target

[Service]
Type=simple
Restart=always
RestartSec=30
StartLimitInterval=0s
StartLimitBurst=10
User=svc_valheim
Group=svc_valheim
ExecStartPre=-$steamPath/steamcmd.sh +login anonymous +force_install_dir $steamPath/valheim +app_update 896660 validate +quit
ExecStart=$steamPath/valheim/start_server_custom.sh
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGINT
WorkingDirectory=$steamPath/valheim
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target

EOF

# Show the service
echo_msg "Show the service - cat /etc/systemd/system/valheim.service"
cat /etc/systemd/system/valheim.service

# Reload daemons after creating service
echo_msg "Reload daemons after creating service - systemctl daemon-reload"
systemctl daemon-reload

# Enable service to start on boot
echo_msg "Enable service to start on boot - systemctl enable valheim"
systemctl enable valheim


# Show service status
echo_msg "Show service status - systemctl status valheim"
systemctl status valheim


# TODO
# Load Valheim server world files from S3 bucket
# s3 cp

# TODO
# Create a crontab to back up the Valheim server world files to S3

# Reboot to finish installing updates, and service will come online after reboot
echo_msg "Reboot to finish installing updates, and service will come online after reboot - sudo shutdown -r now"
sudo shutdown -r now
