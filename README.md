**Title**: How To Setup Your Own HomeLab 

**Author**: Tarell King

**Tools Used**: [Windows server, AD (Active Directory), xx ]

## Table of Contents
1. [Introduction](#intro)
4. [Conclusion](#conclusion)
5. [References](#references)

## Intro
##  Setting up virtual enviorment  **Prerequsites Virtaul box or another virtualization software, windows server iso**

We begin by installig windows server in a virtual machine. Create a Windows 10 Virtal machine and assign the windows server iso in the storage devices. 

Allow Bidirectional shared clipboard and drag and drop to the VM. Adjust the number of processors used depending on your computer specs. 

In the network tab use adaptor 1 as NAT which is what we will use to connect to the internet and configure adaptor 2 as Internal Network


![image](https://github.com/TarellKing/Home-Lab/assets/121117376/4f3948b9-315c-4803-a6ef-cad8ed72a8cb)



##  Configuring your windows server 

Rename your server to DC and restart vm. 

When selecting your operating system choose the Windows Server 2018 Standard Evaluation (Desktop Experince) if not you will only be able to interact with the server from the CLI. Select custom install and continue 

Once the server has been installed and you create your password verify both network connections are avalible. In your network settings select change adaptor options. Rename each network to easily identify the interal and external network. Assign the ip addresses listed in the table below. 


| Device              | Role           | IP Address      | Subnet Mask     | Default Gateway | Preferred DNS  |
|---------------------|----------------|-----------------|-----------------|-----------------|----------------|
| Domain Controller   | Primary DC     | 192.168.1.10    | 255.255.255.0   | 192.168.1.1     | 192.168.1.10   |
| Internal            | Route Traffic  | 192.168.1.20    | 255.255.255.0   | 192.168.1.1     | 192.168.1.10   |





##  Installing Services 

Open your server manager and add roles. Add Active Directory Domain Services. After installiation promate this server to a domain controller. Create your domain and continue with defualt options. 

![image](https://github.com/user-attachments/assets/14ee349b-5ed0-4dc0-b1f8-006b1c575cdc)



In a real enviorment it is not likley that you will have direct access to the domain controller. We will create a admin account that we will use from this point. 

Open Active Directory Users and Computers. Create a new OU (Organizational Unit) named Admins. Right click your new OU and add your new account. 

Set the password to never expire for this purpose of this lab. Edit the user proprties in the member of tab and add this user to the domain admins group.

![image](https://github.com/user-attachments/assets/69555d3f-40ef-436b-8290-94a71441de89)

You can now sign out of the DC and sign into your newly created admininastror account. 

##  Configuring the network

Open server manger and select add roles and features. Select remote access this will allow pcs added to this domain to communicate with the internet using the domain contronller. Be sure to enable routing when installing remote access. 

Open the routing and remote access interface and start configuring your DC. Use NAT (This is what allows internal devices to connect to the internet) Select your public facing network (The one we renamed as External). 

Now that NAT is configured we need to also configure DHCP which is the protocol which will assign IP addresses to each device on your network.

Open the DHCP menu and select your domain. Create a new scope using the ip address, subnet mask, and default gateway below. the domain name and dns server should be defaulted with your created domain and create. 

| Device              | Role           | IP Address Range | Subnet Mask    | Default Gateway | Preferred DNS  |
|---------------------|----------------|------------------|----------------|-----------------|----------------|
| Windows Client 1    | Workstation    | 192.168.1.100-150| 255.255.255.0  | 192.168.1.1     | 192.168.1.10   |
| Windows Client 2    | Workstation    | 192.168.1.100-150| 255.255.255.0  | 192.168.1.1     | 192.168.1.10   |
| Windows Client 3    | Workstation    | 192.168.1.100-150| 255.255.255.0  | 192.168.1.1     | 192.168.1.10   |
| Windows Client 4    | Workstation    | 192.168.1.100-150| 255.255.255.0  | 192.168.1.1     | 192.168.1.10   |
| Windows Client 5    | Workstation    | 192.168.1.100-150| 255.255.255.0  | 192.168.1.1     | 192.168.1.10   |

## User Creation 

After configureing DHCP we can now start to add users to our orgnization. I will be using powershell to automate this process. 

```console
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
## Testing 

Now that we have users created we can log into one of the created accounts to ensure network connectivity. 
1. Create a new windows 10 machine
2. .

# Conclusion
In the conclusion sections I like to write a little bit about how the box seemed to me overall, where I struggled, and what I learned.

# References
test
