#!/bin/bash

# Store cert in variable inline to make the script more portable.
ZS_PEM=$(cat <<EOF
-----BEGIN CERTIFICATE-----
MIIE0zCCA7ugAwIBAgIJANu+mC2Jt3uTMA0GCSqGSIb3DQEBCwUAMIGhMQswCQYD
VQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTERMA8GA1UEBxMIU2FuIEpvc2Ux
FTATBgNVBAoTDFpzY2FsZXIgSW5jLjEVMBMGA1UECxMMWnNjYWxlciBJbmMuMRgw
FgYDVQQDEw9ac2NhbGVyIFJvb3QgQ0ExIjAgBgkqhkiG9w0BCQEWE3N1cHBvcnRA
enNjYWxlci5jb20wHhcNMTQxMjE5MDAyNzU1WhcNNDIwNTA2MDAyNzU1WjCBoTEL
MAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExETAPBgNVBAcTCFNhbiBK
b3NlMRUwEwYDVQQKEwxac2NhbGVyIEluYy4xFTATBgNVBAsTDFpzY2FsZXIgSW5j
LjEYMBYGA1UEAxMPWnNjYWxlciBSb290IENBMSIwIAYJKoZIhvcNAQkBFhNzdXBw
b3J0QHpzY2FsZXIuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
qT7STSxZRTgEFFf6doHajSc1vk5jmzmM6BWuOo044EsaTc9eVEV/HjH/1DWzZtcr
fTj+ni205apMTlKBW3UYR+lyLHQ9FoZiDXYXK8poKSV5+Tm0Vls/5Kb8mkhVVqv7
LgYEmvEY7HPY+i1nEGZCa46ZXCOohJ0mBEtB9JVlpDIO+nN0hUMAYYdZ1KZWCMNf
5J/aTZiShsorN2A38iSOhdd+mcRM4iNL3gsLu99XhKnRqKoHeH83lVdfu1XBeoQz
z5V6gA3kbRvhDwoIlTBeMa5l4yRdJAfdpkbFzqiwSgNdhbxTHnYYorDzKfr2rEFM
dsMU0DHdeAZf711+1CunuQIDAQABo4IBCjCCAQYwHQYDVR0OBBYEFLm33UrNww4M
hp1d3+wcBGnFTpjfMIHWBgNVHSMEgc4wgcuAFLm33UrNww4Mhp1d3+wcBGnFTpjf
oYGnpIGkMIGhMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTERMA8G
A1UEBxMIU2FuIEpvc2UxFTATBgNVBAoTDFpzY2FsZXIgSW5jLjEVMBMGA1UECxMM
WnNjYWxlciBJbmMuMRgwFgYDVQQDEw9ac2NhbGVyIFJvb3QgQ0ExIjAgBgkqhkiG
9w0BCQEWE3N1cHBvcnRAenNjYWxlci5jb22CCQDbvpgtibd7kzAMBgNVHRMEBTAD
AQH/MA0GCSqGSIb3DQEBCwUAA4IBAQAw0NdJh8w3NsJu4KHuVZUrmZgIohnTm0j+
RTmYQ9IKA/pvxAcA6K1i/LO+Bt+tCX+C0yxqB8qzuo+4vAzoY5JEBhyhBhf1uK+P
/WVWFZN/+hTgpSbZgzUEnWQG2gOVd24msex+0Sr7hyr9vn6OueH+jj+vCMiAm5+u
kd7lLvJsBu3AO3jGWVLyPkS3i6Gf+rwAp1OsRrv3WnbkYcFf9xjuaf4z0hRCrLN2
xFNjavxrHmsH8jPHVvgc1VD0Opja0l/BRVauTrUaoW6tE+wFG5rEcPGS80jjHK4S
pB5iDj2mUZH1T8lzYtuZy0ZPirxmtsk3135+CKNa2OCAhhFjE0xd
-----END CERTIFICATE-----
EOF
)

sudo() {
  [[ "${EUID}" == 0 ]] || set -- command sudo "${@}"
  # If you're the root user then short circuit out of this OR condition. This
  # is the Docker use case.
  #
  # $EUID is the effective user. Unlike $USER, $EUID should be defined in most
  # Docker images. 
  #
  # Otherwise, take whatever arguments you passed into this function and then
  # run it through the sudo command. This is the personal machine use case and
  # is the other side of the OR condition.
  #
  # `command` is a bash command to execute or display info about a command and
  # we're using `set` to modify the args of ${@}.

  "${@}"
  # Run whatever arguments you passed into this function. This would be whatever
  # the command was but without `sudo`.
}

# Source the os release values to determine if we need any packages
source <(sed 's/ /_/g' /etc/os-release)

# Create the ZScaler pem on disk
echo "${ZS_PEM}" > /tmp/ZScaler-CA-Chain.pem 

echo "Install ZScaler CA Certificate into certificate chain (sudo password may be required)..."
if [ -f "/usr/sbin/update-ca-certificates" ]; then
    sudo mv /tmp/ZScaler-CA-Chain.pem /usr/local/share/ca-certificates/ZScaler-CA-Chain.crt
    sudo /usr/sbin/update-ca-certificates --fresh
    echo "done!"
elif [ -f  "/usr/bin/update-ca-trust" ]; then
    sudo mv /tmp/ZScaler-CA-Chain.pem /etc/pki/ca-trust/source/anchors
    sudo /usr/bin/update-ca-trust
    echo "done!"
else
    echo "Certificate management utility not found. Attempting to install using the system package manager..."

    # Temporarily add the certificate to the chain manually to ensure our package manager works.
    if [ -f "/etc/ssl/certs/ca-certificates.crt" ]; then
        sudo cat /tmp/ZScaler-CA-Chain.pem >> /etc/ssl/certs/ca-certificates.crt
    elif [ -f "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem" ]; then
        sudo cat /tmp/ZScaler-CA-Chain.pem >> /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
    fi

    if [[ $ID == "alpine" ]]; then
        sudo apk --no-cache add ca-certificates sudo && \
        sudo rm -rf /var/cache/apk/*
        sudo mv /tmp/ZScaler-CA-Chain.pem /usr/local/share/ca-certificates/ZScaler-CA-Chain.crt
        sudo update-ca-certificates
    elif [[ $ID == "ubuntu" ]]; then
        sudo apt-get update
        sudo apt-get install ca-certificates
        sudo rm -rf /var/lib/apt/lists/*
        sudo mv /tmp/ZScaler-CA-Chain.pem /usr/local/share/ca-certificates/ZScaler-CA-Chain.crt
        sudo update-ca-certificates --fresh
    elif [[ $ID == "fedora" ]]; then 
        sudo dnf -y install ca-certificates
        sudo rm -rf /var/cache/libdnf5/*
        sudo mv /tmp/ZScaler-CA-Chain.pem /etc/pki/ca-trust/source/anchors
        sudo update-ca-trust
    fi
    echo "done!"
fi

# Restart docker if it is installed and running
if which systemctl &> /dev/null; then 
    if systemctl is-active --quiet docker; then
        echo -n "Restarting docker..."
        sudo systemctl restart docker
        echo "done!"
    fi
fi