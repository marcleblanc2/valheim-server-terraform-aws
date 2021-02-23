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


# TODO
# Create Valheim server service account
# Change file paths / ownership / symlinks for service account
# Change service definition to run as service account
# Not sure about assigning a password to a service user account on Amazon Linux 2
# echo_msg "sudo adduser -m svc_valheim to create a new service user"
# sudo adduser -m svc_valheim # -p ${valheim-server-service-account-password}


# Create root directory to install Steam client and Valheim server
sudo mkdir /steam

# Install Steam
echo_msg "wget -P /steam http://media.steampowered.com/installer/steamcmd_linux.tar.gz to download steamcmd"
wget -P /steam http://media.steampowered.com/installer/steamcmd_linux.tar.gz

echo_msg "tar -xvzf steamcmd_linux.tar.gz to unpack steamcmd"
tar -xvzf /steam/steamcmd_linux.tar.gz -C /steam

echo_msg "ls -hAl /steam to show that steamcmd_linux.tar.gz has been downloaded and extracted"
ls -hAl /steam

echo_msg "/steam/steamcmd.sh +quit to install and update steamcmd"
/steam/steamcmd.sh +quit

# Install Valheim server
echo_msg "/steam/steamcmd.sh +login anonymous +force_install_dir ./valheim +app_update 896660 +quit to install the Valheim server"
/steam/steamcmd.sh +login anonymous +force_install_dir /steam/valheim +app_update 896660 validate +quit

# Create service log checking script, so I don't have to remember the command every time
echo_msg "Creating service log checking script"
cat > /steam/valheim/check_log.sh <<EOF
journalctl --unit=valheim  -f
EOF
echo_msg "cat /steam/valheim/check_log.sh to verify service log checking script"
cat /steam/valheim/check_log.sh

# Make the check log script executable
echo_msg "sudo chmod +x /steam/valheim/check_log.sh to make the check log script executable"
sudo chmod +x /steam/valheim/check_log.sh
echo_msg "ls -Al /steam/valheim/ to verify the check log script is executable"
ls -Al /steam/valheim/

# Create startup script
echo_msg "Creating custom server startup script"
cat > /steam/valheim/start_server_custom.sh <<EOF
#!/bin/bash
export templdpath=\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:\$LD_LIBRARY_PATH
export SteamAppId=892970
./valheim_server.x86_64 -name "${valheim-server-display-name}" -port 2456 -nographics -batchmode -world "${valheim-server-world-name}" -password "${valheim-server-world-password}" -public ${valheim-server-public}
export LD_LIBRARY_PATH=\$templdpath
EOF
echo_msg "cat /steam/valheim/start_server_custom.sh to verify server startup script"
cat /steam/valheim/start_server_custom.sh

# Make the startup script executable
echo_msg "sudo chmod +x /steam/valheim/start_server_custom.sh to make the server startup script executable"
sudo chmod +x /steam/valheim/start_server_custom.sh
echo_msg "ls -Al /steam/valheim/ to verify the server startup script is executable"
ls -Al /steam/valheim/

# Install the startup script as a service
cat > /etc/systemd/system/valheim.service <<EOF
[Unit]
Description=Valheim Server
Wants=network-online.target
After=syslog.target network.target nss-lookup.target network-online.target
[Service]
Type=simple
Restart=on-failure
RestartSec=5
StartLimitInterval=60s
StartLimitBurst=3
User=root
Group=root
ExecStartPre=/steam/steamcmd.sh +login anonymous +force_install_dir /steam/valheim +app_update 896660 validate +quit
ExecStart=/steam/valheim/start_server_custom.sh
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGINT
WorkingDirectory=/steam/valheim
LimitNOFILE=100000
[Install]
WantedBy=multi-user.target
EOF

# Reload daemons after creating service
echo_msg "Reloading daemons after creating service"
systemctl daemon-reload

# Enable server to start on boot
echo_msg "Enabling Valheim Server to start on boot"
systemctl enable valheim


# TODO
# Copy Valheim server world files from S3 bucket
# s3 cp

# TODO
# Create a crontab to back up the Valheim server world files to S3

# Reboot to finish installing updates, and service will come online after reboot
echo_msg "sudo needs-restarting -r || sudo shutdown -r now to reboot if needed for patches"
sudo needs-restarting -r || sudo shutdown -r now


# # Start server
# echo_msg "Starting Valheim Server"
# systemctl start valheim

# # Check service status
# echo_msg "systemctl status valheim.service to show the service status"
# systemctl status valheim.service
