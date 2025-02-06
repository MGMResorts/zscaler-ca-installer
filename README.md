# zscaler-ca-installer <!-- omit from toc -->
A repository containing installation scripts for the ZScaler intermediate CA certificate.

---

- [1. Introduction](#1-introduction)
    - [Why is this needed?](#why-is-this-needed)
- [2. Supported Operating Systems](#2-supported-operating-systems)
- [3. Usage](#3-usage)
    - [Docker Image Build](#docker-image-build)
    - [Colima on MacOS](#colima-on-macos)
- [4. Using the System CA Store With Node or Python](#4-using-the-system-ca-store-with-node-or-python)
      - [Dockerfile](#dockerfile)

---

# 1. Introduction

This project is intended to house installation scripts that assist with installing the default ZScaler intermediate CA Certificate into virtualized or containerized images. The script is written in
a way that it can be run in any bourne shell (i.e. bsh and its descendants), since some container images do not come with a full bash implementation.

### Why is this needed?

ZScaler supports SSL Inspection, which redirects any TLS traffic through its own tunnel in order to decrypt and monitor the traffic for anything malicious. It does this by signing the tunnel with its own certificate, and therefore anything that utilizes the internet connection of a ZScaler managed host needs to trust their CA. This includes containers and VMs used for development, as they use the host OS' internet connection. 

Because of this, we aim to provide easy to use scripts that install the certificate into a systems CA certificate store. For more information on how SSL Inspection works, see [About SSL Inspections](https://help.zscaler.com/zia/about-ssl-inspection) on ZScaler's website. 

--- 

# 2. Supported Operating Systems

Scripts in this repository currently support the following Operating Systems:

* Ubuntu Linux
* Alpine Linux
* Fedora Linux 
  * Includes support for podman machines
* Windows Subsystem for Linux  should be supported if running one of the above distributions.

---

# 3. Usage

### Docker Image Build

If your base Docker image has curl installed, then the script can be executed easily with the following directives in your Dockerfile:

```dockerfile
RUN curl -k https://raw.githubusercontent.com/MGMResorts/zscaler-ca-installer/refs/heads/main/install-zscaler-ca.sh | bash
```

Change `bash` to `sh` if the image you are using does not have bash installed. Most images do, but some only use busybox which only provides `sh`.

If an image does not have curl installed by default, wget is typically present via either busybox or the wget utility itself. If this is the case, use the following directives instead.

```dockerfile
RUN wget --no-check-certificate -O /tmp/install-zscaler-ca.sh https://raw.githubusercontent.com/MGMResorts/zscaler-ca-installer/refs/heads/main/install-zscaler-ca.sh && \
    bash /tmp/install-zscaler-ca.sh && \
    rm -f /tmp/install-zscaler-ca.sh
```

### Colima on MacOS

[Colima](https://github.com/abiosoft/colima) is an open source project based on [Lima](https://github.com/lima-vm/lima) to provide container runtimes on MacOS. It does this using the vz 
hypervisor built into the operating system, or [qemu](https://www.qemu.org/) to run a linux virtual machine. The default Colima image is based on Ubuntu.

Once you have a system built using colima, you must install the ZScaler certificate chain into the system to ensure that `docker login` commands to external repositories such as `ghcr.io`
work properly.

```shell
# The environment doesn't load properly if you invoke the command directly, which is why we use bash -c.
colima ssh --profile <your__colima_instance_profile_name> -- /bin/bash -c 'curl -k https://raw.githubusercontent.com/MGMResorts/zscaler-ca-installer/refs/heads/main/install-zscaler-ca.sh | bash'
```

Please note that you will still need to install the CA chain in any docker containers you utilize with colima for them to function properly with outgoing TLS connections.

---

# 4. Using the System CA Store With Node or Python

Since both nodejs and python use their own internal CA stores, we must set some environment variables to ensure that they utilize the system CA trust chains. 

Nodejs uses the following variable: 

```shell
export NODE_OPTIONS=--use-openssl-ca
```

And python uses the following:

```shell
# Note the file listed below works for Ubuntu and Alpine based systems.
# Fedora and its derivatives uses a slightly different certificate path which is:
# /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
#
# Be sure to adjust accordingly.
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
```

#### Dockerfile

In your Dockerfile for your nodejs powered application, add the following directive:

```dockerfile
ENV NODE_OPTIONS=--use-openssl-ca
```

or for python:

```dockerfile
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
```

