#!/bin/bash

# Configure script to log console output to a log file
exec > >(tee -ia /var/log/valheim.log)
exec 2>&1

# Write start to log
echo "$(date -Iseconds) - Starting $@"

# Update packages
echo "$(date -Iseconds) - Starting sudo yum update -y"
sudo yum update -y

# Ping to validate internet connectivity
echo "$(date -Iseconds) - Pinging Google to validate internet connectivity"
ping -c 3 -W 3 google.com


# Install Valheim server



# Copy Valheim server world files?



# Reboot to finish installing updates
echo "$(date -Iseconds) - Rebooting, if needed"
sudo needs-restarting -r || sudo shutdown -r

