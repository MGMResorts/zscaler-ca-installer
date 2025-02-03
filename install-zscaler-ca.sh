#!/bin/bash

echo -n "Copying ZScaler certificate..."
# Download from a private gist, as Github requires authentication for private repositories.
cp files/ZScaler-CA-Chain.pem /tmp
echo "done."

echo "Install ZScaler CA Certificate into certificate chain (sudo password may be required)..."
if [ -f /usr/sbin/update-ca-certificates ]; then
    sudo cp /tmp/ZScaler-CA-Chain.pem /usr/local/share/ca-certificates/ZScaler-CA-Chain.crt
    sudo /usr/sbin/update-ca-certificates --fresh
    echo "done!"
else
    echo "update-ca-certificates utility not found. Attempting to install using the system package manager..."
    # Temporarily add the certificate to the chain manually to ensure our package manager works.
    cat /tmp/ZScaler-CA-Chain.pem >> /etc/ssl/certs/ca-certificates.crt
    # Source the os release values to determine if we need any packages
    source <(sed 's/ /_/g' /etc/os-release)
    if [[ $ID == "alpine" ]]; then
        apk --no-cache add ca-certificates sudo && \
        rm -rf /var/cache/apk/*
    elif [[ $ID == "ubuntu" ]]; then
        apt-get update
        apt-get install ca-certificates
        rm -rf /var/lib/apt/lists/*
    fi
    sudo cp /tmp/ZScaler-CA-Chain.pem /usr/local/share/ca-certificates/ZScaler-CA-Chain.crt
    sudo update-ca-certificates --fresh
    echo "done!"
fi

# Restart docker if it is installed and running
if systemctl is-active --quiet docker; then
    echo -n "Restarting docker..."
    sudo systemctl restart docker
    echo "done!"
fi