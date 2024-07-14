# How To Setup Your Own HomeLab

**Author**: Tarell King

**Tools Used**: Windows Server, AD (Active Directory), VirtualBox

## Table of Contents
1. [Introduction](#introduction)
2. [Setting Up Virtual Environment](#setting-up-virtual-environment)
3. [Configuring Your Windows Server](#configuring-your-windows-server)
4. [Installing Services](#installing-services)
5. [Configuring the Network](#configuring-the-network)
6. [User Creation](#user-creation)
7. [Routing Table](#Routing-tables)
8. [Network Testing](#Network-testing)
9. [Conclusion](#conclusion)

    

## Introduction
This guide will walk you through setting up your own HomeLab using a Windows Server and Active Directory.

## Setting Up Virtual Environment
**Prerequisites**: VirtualBox (or another virtualization software), Windows Server ISO, Windows 10 ISO.

We begin by installing Windows Server in a virtual machine. 

1. Create a Windows 10 virtual machine.
2. Assign the Windows Server ISO in the storage devices.
3. Allow bidirectional shared clipboard and drag-and-drop to the VM.
4. Adjust the number of processors based on your computer's specifications.
5. In the network tab, use adapter 1 as NAT to connect to the internet and configure adapter 2 as Internal Network.

![image](https://github.com/TarellKing/Home-Lab/assets/121117376/4f3948b9-315c-4803-a6ef-cad8ed72a8cb)

## Configuring Your Windows Server
1.  When selecting your operating system, choose `Windows Server 2018 Standard Evaluation (Desktop Experience)` to enable GUI interaction. Select custom install and continue.
2. Rename your server to `DC` and restart the VM.
3. Once the server is installed and you create your password, verify both network connections are available. In your network settings, select "Change adapter options." Rename each network to easily identify the internal and external networks. Assign the IP addresses listed in the table below to your internal network 


## Installing Services
Open Server Manager and add roles. Add Active Directory Domain Services. After installation, promote this server to a domain controller. Create your domain and continue with the default options.

![image](https://github.com/user-attachments/assets/14ee349b-5ed0-4dc0-b1f8-006b1c575cdc)

In a real environment, it is not likely that you will have direct access to the domain controller. We will create an admin account that we will use from this point.

Open Active Directory Users and Computers. Create a new OU (Organizational Unit) named `Admins`. Right-click your new OU and add your new account.

Set the password to never expire for this lab. Edit the user properties in the "Member Of" tab and add this user to the `Domain Admins` group.

![image](https://github.com/user-attachments/assets/69555d3f-40ef-436b-8290-94a71441de89)

You can now sign out of the DC and sign into your newly created administrator account.

## Configuring the Network
Open Server Manager and select "Add roles and features." Select "Remote Access" to allow PCs added to this domain to communicate with the internet using the domain controller. Be sure to enable routing when installing remote access.

Open the Routing and Remote Access interface and start configuring your DC. Use NAT (this allows internal devices to connect to the internet). Select your public-facing network (the one renamed as External). view [Routing Table](#Routing-table)

Now that NAT is configured, we need to also configure DHCP, which is the protocol that will assign IP addresses to each device on your network.

Open the DHCP menu and select your domain. Create a new scope using the IP address, subnet mask, and default gateway below. The domain name and DNS server should be defaulted with your created domain. view [Routing Table](#Routing-table)


## User Creation
After configuring DHCP, we can now start to add users to our organization. I will be using PowerShell to automate this process.

```powershell
# ----- Edit these Variables for your own Use Case ----- #
$PASSWORD_FOR_USERS   = "Password1"
$USER_FIRST_LAST_LIST = Get-Content .\names.txt
# ------------------------------------------------------ #

$password = ConvertTo-SecureString $PASSWORD_FOR_USERS -AsPlainText -Force
New-ADOrganizationalUnit -Name _USERS -ProtectedFromAccidentalDeletion $false

foreach ($n in $USER_FIRST_LAST_LIST) {
    $first = $n.Split(" ")[0].ToLower()
    $last = $n.Split(" ")[1].ToLower()
    $username = "$($first.Substring(0,1))$($last)".ToLower()
    Write-Host "Creating user: $($username)" -BackgroundColor Black -ForegroundColor Cyan
    
    New-AdUser -AccountPassword $password `
               -GivenName $first `
               -Surname $last `
               -DisplayName $username `
               -Name $username `
               -EmployeeID $username `
               -PasswordNeverExpires $true `
               -Path "ou=_USERS,$(([ADSI]`"").distinguishedName)" `
               -Enabled $true
}
```
## User Creation

1.Create a new Windows 10 machine and make sure the network option is set to internal network. 
2.Boot using default options be sure to install `windows 10 pro`. you cannot add the home version of windows to a domain. 
2.Open the about my pc menu and join it to the domain and log in with one of the creatcmded accounts.
3.


![image](https://github.com/user-attachments/assets/ae6bced0-0676-41f0-8389-08ed061eee42)


![image](https://github.com/user-attachments/assets/ef942bfd-3632-4d9c-acea-0f8692aaaa5f)


## Routing Tables 


## Domain Controller IP Configuration

| Network          | IP Address   | Subnet Mask     | Default Gateway     | DNS Server             |
|------------------|--------------|-----------------|---------------------|------------------------|
| External Network | 10.0.2.15    | 255.255.255.0   | 10.0.2.2            | 172.16.0.1, 8.8.8.8    |
| Internal Network | 172.16.0.1   | 255.255.255.0   | (blank or 172.16.0.1)| 127.0.0.1              |

## NAT Configuration

| Interface        | Network          | IP Address   | Subnet Mask     | Default Gateway       | Role             |
|------------------|------------------|--------------|-----------------|-----------------------|------------------|
| Internal Network | Internal Network | 172.16.0.1   | 255.255.255.0   | (blank or 172.16.0.1) | NAT (Internal)   |
| External Network | External Network | 10.0.2.15    | 255.255.255.0   | 10.0.2.2              | NAT (External)   |

## DHCP Configuration

| Setting          | Value                      |
|------------------|----------------------------|
| IP Range         | 172.16.0.100 - 172.16.0.200|
| Subnet Mask      | 255.255.255.0              |
| Default Gateway  | 172.16.0.1                 |
| DNS Server       | 172.16.0.1                 |


## Network Testing

Now that we have sucsufully setup our enviorment we can log onto a user account and ensure it is connect to our network. 

```cmd
Ping Google.com

tracert 8.8.8.8

```
![image](https://github.com/user-attachments/assets/b52b9413-8a28-4f3e-86c4-ace6822593b3)

![image](https://github.com/user-attachments/assets/9aab35cc-5002-4cc3-8733-037618b0bc98)

## Conclusion 

Setting up your own HomeLab can be a highly rewarding experience, providing practical, hands-on knowledge that is invaluable for anyone interested in IT and systems administration. This lab involved several key steps: configuring a virtual environment, installing and configuring a Windows Server, setting up Active Directory, and automating user creation with PowerShell.

During the setup, you might have faced challenges such as network configuration issues or Active Directory setup complexities. Overcoming these obstacles enhances your troubleshooting skills and deepens your understanding of how various components of a network interact.
