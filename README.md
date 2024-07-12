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
| SQL Server          | Database Server| 192.168.1.20    | 255.255.255.0   | 192.168.1.1     | 192.168.1.10   |

| Device              | Role           | IP Address Range | Subnet Mask    | Default Gateway | Preferred DNS  |
|---------------------|----------------|------------------|----------------|-----------------|----------------|
| Windows Client 1    | Workstation    | 192.168.1.100-150| 255.255.255.0  | 192.168.1.1     | 192.168.1.10   |
| Windows Client 2    | Workstation    | 192.168.1.100-150| 255.255.255.0  | 192.168.1.1     | 192.168.1.10   |
| Windows Client 3    | Workstation    | 192.168.1.100-150| 255.255.255.0  | 192.168.1.1     | 192.168.1.10   |
| Windows Client 4    | Workstation    | 192.168.1.100-150| 255.255.255.0  | 192.168.1.1     | 192.168.1.10   |
| Windows Client 5    | Workstation    | 192.168.1.100-150| 255.255.255.0  | 192.168.1.1     | 192.168.1.10   |



##  Installing Services 

Open your server manager and add roles. Add Active Directory Domain Services. After installiation promate this server to a domain controller. Create your domain and continue with defualt options. 

![image](https://github.com/user-attachments/assets/14ee349b-5ed0-4dc0-b1f8-006b1c575cdc)



In a real enviorment it is not likley that you will have direct access to the domain controller. We will create a admin account that we will use from this point. 

Open Active Directory Users and Computers. Create a new OU (Organizational Unit) named Admins. Right click your new OU and add your new account. 

Set the password to never expire for this purpose of this lab. Edit the user proprties in the member of tab and add this user to the domain admins group.

![image](https://github.com/user-attachments/assets/69555d3f-40ef-436b-8290-94a71441de89)

You can now sign out of the DC and sign into your newly created admininastror account. 
```console

┌──(tarell㉿kali)-[~]
└─$ sudo nmap -sV 10.10.11.11
Starting Nmap 7.94 ( https://nmap.org ) at 2024-06-22 22:42 EDT
}
```


# Conclusion
In the conclusion sections I like to write a little bit about how the box seemed to me overall, where I struggled, and what I learned.

# References
test
