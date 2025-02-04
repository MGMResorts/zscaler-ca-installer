# zscaler-ca-installer
A repository containing installation scripts for the ZScaler intermediate CA certificate.

---

- [zscaler-ca-installer](#zscaler-ca-installer)
- [1. Introduction](#1-introduction)
    - [Why is this needed?](#why-is-this-needed)
- [2. Supported Operating Systems](#2-supported-operating-systems)

---

# 1. Introduction

This project is intended to house installation scripts that assist with installing the ZScaler intermediary CA Certificate into virtualized or containerized images. 

### Why is this needed?

ZScaler supports SSL Inspection, which redirects any TLS traffic through its own tunnel in order to decrypt and monitor the traffic for anything malicious. It does this by signing the tunnel with its own certificate, and therefore anything that utilizes the internet connection of a ZScaler managed host needs to trust their CA. This includes containers and VMs used for development, as they use the host OS' internet connection. 

Because of this, we aim to provide easy to use scripts that install the certificate into a systems CA certificate store. For more information on how SSL Inspection works, see [About SSL Inspections](https://help.zscaler.com/zia/about-ssl-inspection) on ZScaler's website. 

--- 

# 2. Supported Operating Systems

Scripts in this repository currently support the following Operating Systems:

* Ubuntu Linux
* Alpine Linux
* Windows 11 (via podman and Windows Subsystem for Linux)

