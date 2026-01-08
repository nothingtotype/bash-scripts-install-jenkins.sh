#! /usr/bin/env bash

# ---------------------------------------------------------
# Jenkins Installation Script for Rocky Linux 9 / RHEL 9
# ---------------------------------------------------------

# 1. Check if Jenkins is already running
if systemctl is-active --quiet jenkins; then
    echo "Jenkins is already running. Skipping installation."
else
    echo "Jenkins not detected or not running. Starting installation..."

    # 2. Add Jenkins Repository if not already present
    if [ ! -f /etc/yum.repos.d/jenkins.repo ]; then
        echo "Adding Jenkins repository..."
        sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
        sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    fi

    # 3. Update system and install dependencies
    echo "Installing Java 21 and Jenkins..."
    sudo dnf upgrade -y
    sudo dnf install fontconfig java-21-openjdk jenkins -y

    # 4. Start and Enable Jenkins
    echo "Starting Jenkins service..."
    sudo systemctl enable --now jenkins
fi

# 5. Firewall Configuration
# Check if the jenkins service is already allowed in the public zone
if sudo firewall-cmd --zone=public --query-service=jenkins >/dev/null 2>&1; then
    echo "Firewall already configured for Jenkins. Skipping."
else
    echo "Configuring firewall..."
    JENKINSPORT=8080
    PERM="--permanent"
    SERV="$PERM --service=jenkins"

    sudo firewall-cmd $PERM --new-service=jenkins 2>/dev/null || echo "Service definition exists."
    sudo firewall-cmd $SERV --set-short="Jenkins ports"
    sudo firewall-cmd $SERV --set-description="Jenkins port exceptions"
    sudo firewall-cmd $SERV --add-port=$JENKINSPORT/tcp
    sudo firewall-cmd $PERM --add-service=jenkins
    sudo firewall-cmd --zone=public --add-service=http --permanent
    sudo firewall-cmd --reload
    echo "Firewall updated."
fi

# 6. Output status and Admin Password
echo "---------------------------------------------------------"
sudo systemctl status jenkins --no-pager
echo "---------------------------------------------------------"
echo "Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword